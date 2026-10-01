import asyncio
import json
import os
import secrets
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from . import config, db as dbm
from .planning import compute_plan
from .sources import get_source
from .sync import now, run_sync

STATIC = os.path.join(os.path.dirname(__file__), "static")
_sync_lock = asyncio.Lock()


async def do_sync(force=False):
    def work():
        with dbm.session() as db:
            return run_sync(db, get_source(), force)
    async with _sync_lock:
        return await asyncio.to_thread(work)


async def sync_loop():
    while True:
        try:
            await do_sync()
        except Exception as e:  # greska je zapisana u meta, petlja nastavlja
            print("sync greska:", e)
        await asyncio.sleep(config.SYNC_INTERVAL_SEC)


@asynccontextmanager
async def lifespan(app):
    os.makedirs(os.path.dirname(config.DB_PATH) or ".", exist_ok=True)
    dbm.init_db()
    task = asyncio.create_task(sync_loop())
    yield
    task.cancel()


app = FastAPI(title="MO planiranje", lifespan=lifespan)


def get_db():
    with dbm.session() as db:
        yield db


def current_user(authorization: str = Header(default=""), db=Depends(get_db)):
    token = authorization.removeprefix("Bearer ").strip()
    u = db.execute("SELECT u.* FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token=?", (token,)).fetchone()
    if not u:
        raise HTTPException(401, "Prijavite se")
    return dict(u)


def boss(u=Depends(current_user)):
    if u["role"] != "boss":
        raise HTTPException(403, "Samo poslovođa")
    return u


# ---------- prijava ----------
class Login(BaseModel):
    pin: str


@app.post("/api/login")
def login(body: Login, db=Depends(get_db)):
    u = db.execute("SELECT * FROM users WHERE pin=?", (body.pin.strip(),)).fetchone()
    if not u:
        raise HTTPException(401, "Pogrešan PIN")
    token = secrets.token_hex(16)
    db.execute("INSERT INTO sessions(token,user_id) VALUES(?,?)", (token, u["id"]))
    return {"token": token, "user": {k: u[k] for k in ("id", "name", "role", "machine_id")}}


@app.get("/api/me")
def me(u=Depends(current_user)):
    return {k: u[k] for k in ("id", "name", "role", "machine_id")}


# ---------- masine ----------
@app.get("/api/machines")
def machines(u=Depends(current_user), db=Depends(get_db)):
    q = "SELECT * FROM machines WHERE enabled=1"
    args = ()
    if u["role"] != "boss":
        q += " AND id=?"
        args = (u["machine_id"],)
    out = []
    for m in db.execute(q + " ORDER BY sort", args):
        d = dict(m)
        d["published_at"] = (db.execute("SELECT published_at FROM publications WHERE machine_id=?", (m["id"],)).fetchone() or [None])[0]
        d["pending"] = db.execute("SELECT COUNT(*) FROM reports WHERE machine_id=? AND status='pending'", (m["id"],)).fetchone()[0]
        out.append(d)
    return out


class MachinePatch(BaseModel):
    capacity_h: float | None = None
    label: str | None = None
    enabled: bool | None = None


@app.patch("/api/machines/{mid}")
def patch_machine(mid: int, body: MachinePatch, _=Depends(boss), db=Depends(get_db)):
    if body.capacity_h is not None:
        db.execute("UPDATE machines SET capacity_h=? WHERE id=?", (max(body.capacity_h, 0), mid))
    if body.label:
        db.execute("UPDATE machines SET label=? WHERE id=?", (body.label, mid))
    if body.enabled is not None:
        db.execute("UPDATE machines SET enabled=? WHERE id=?", (int(body.enabled), mid))
    return {"ok": True}


class NewMachine(BaseModel):
    sap_name: str
    label: str | None = None


@app.post("/api/machines")
def new_machine(body: NewMachine, _=Depends(boss), db=Depends(get_db)):
    ex = db.execute("SELECT id FROM machines WHERE sap_name=?", (body.sap_name,)).fetchone()
    if ex:
        db.execute("UPDATE machines SET enabled=1 WHERE id=?", (ex["id"],))
        return {"id": ex["id"]}
    return {"id": dbm.add_machine(db, body.sap_name, body.label)}


@app.get("/api/sap-machines")
def sap_machines(_=Depends(boss), db=Depends(get_db)):
    return json.loads(dbm.get_meta(db, "sap_machines", "[]"))


@app.get("/api/users")
def users(_=Depends(boss), db=Depends(get_db)):
    return [dict(r) for r in db.execute(
        "SELECT u.id,u.name,u.pin,u.role,u.machine_id,m.label machine FROM users u LEFT JOIN machines m ON m.id=u.machine_id")]


class PinBody(BaseModel):
    pin: str
    name: str | None = None


@app.patch("/api/users/{uid}")
def set_pin(uid: int, body: PinBody, _=Depends(boss), db=Depends(get_db)):
    if len(body.pin.strip()) < 3 or db.execute("SELECT 1 FROM users WHERE pin=? AND id<>?", (body.pin, uid)).fetchone():
        raise HTTPException(400, "PIN je prekratak ili već postoji")
    db.execute("UPDATE users SET pin=?, name=COALESCE(?,name) WHERE id=?", (body.pin.strip(), body.name, uid))
    return {"ok": True}


# ---------- plan poslovodje ----------
def machine_items(db, mid):
    pend = {(r["rn"], r["linija"]): r["q"] for r in db.execute(
        "SELECT rn,linija,SUM(qty) q FROM reports WHERE status='pending' GROUP BY rn,linija")}
    items = []
    for r in db.execute("""SELECT l.*, p.split_qty, p.position FROM plan p JOIN lines l ON l.rn=p.rn AND l.linija=p.linija
                           WHERE p.machine_id=? AND l.active=1 ORDER BY p.position""", (mid,)):
        d = dict(r)
        d["qty_sap"] = d["qty_left"]
        d["qty_pending"] = pend.get((d["rn"], d["linija"]), 0)
        qty = d["qty_left"] - d["qty_pending"]
        if qty <= 1e-6:
            continue  # sve je vec prijavljeno, ceka SAP
        d["norm_left"] = d["norm_left"] * qty / d["qty_left"] if d["qty_left"] else 0
        d["qty"] = qty
        items.append(d)
    return items


@app.get("/api/plan/{mid}")
def get_plan(mid: int, _=Depends(boss), db=Depends(get_db)):
    m = db.execute("SELECT * FROM machines WHERE id=?", (mid,)).fetchone()
    if not m:
        raise HTTPException(404)
    rows, summary = compute_plan(machine_items(db, mid), m["capacity_h"])
    pub = db.execute("SELECT published_at FROM publications WHERE machine_id=?", (mid,)).fetchone()
    return {"machine": dict(m), "rows": rows, "summary": summary, "published_at": pub[0] if pub else None}


class Order(BaseModel):
    keys: list[list[int]]


@app.post("/api/plan/{mid}/order")
def reorder(mid: int, body: Order, _=Depends(boss), db=Depends(get_db)):
    for i, (rn, lin) in enumerate(body.keys, 1):
        db.execute("UPDATE plan SET position=? WHERE rn=? AND linija=? AND machine_id=?", (i, rn, lin, mid))
    return {"ok": True}


class Move(BaseModel):
    rn: int
    linija: int
    machine_id: int


@app.post("/api/plan/move")
def move(body: Move, _=Depends(boss), db=Depends(get_db)):
    if not db.execute("SELECT 1 FROM machines WHERE id=? AND enabled=1", (body.machine_id,)).fetchone():
        raise HTTPException(404, "Mašina ne postoji")
    pos = db.execute("SELECT COALESCE(MAX(position),0)+1 FROM plan WHERE machine_id=?", (body.machine_id,)).fetchone()[0]
    db.execute("UPDATE plan SET machine_id=?, position=?, split_qty=NULL WHERE rn=? AND linija=?",
               (body.machine_id, pos, body.rn, body.linija))
    return {"ok": True}


class Split(BaseModel):
    rn: int
    linija: int
    qty: float | None = None  # None = vrati u jednu liniju


@app.post("/api/plan/split")
def split(body: Split, _=Depends(boss), db=Depends(get_db)):
    if body.qty is not None:
        l = db.execute("SELECT qty_left FROM lines WHERE rn=? AND linija=?", (body.rn, body.linija)).fetchone()
        if not l or not 0 < body.qty < l["qty_left"]:
            raise HTTPException(400, "Neispravna količina za podjelu")
    db.execute("UPDATE plan SET split_qty=? WHERE rn=? AND linija=?", (body.qty, body.rn, body.linija))
    return {"ok": True}


@app.post("/api/plan/{mid}/publish")
def publish(mid: int, _=Depends(boss), db=Depends(get_db)):
    m = db.execute("SELECT * FROM machines WHERE id=?", (mid,)).fetchone()
    rows, _s = compute_plan(machine_items(db, mid), m["capacity_h"])
    green = [r for r in rows if r["status"] in ("green", "none")]
    db.execute("DELETE FROM published WHERE machine_id=?", (mid,))
    for i, r in enumerate(green, 1):
        db.execute("INSERT INTO published VALUES(?,?,?,?,?)", (mid, i, r["rn"], r["linija"], r["part_qty"]))
    t = now()
    db.execute("INSERT INTO publications VALUES(?,?) ON CONFLICT(machine_id) DO UPDATE SET published_at=excluded.published_at", (mid, t))
    return {"published": len(green), "published_at": t}


# ---------- operater ----------
def operator_machine(u, machine_id):
    if u["role"] == "boss":
        if not machine_id:
            raise HTTPException(400, "machine_id")
        return machine_id
    return u["machine_id"]


def operator_rows(db, mid):
    pub = db.execute("SELECT published_at FROM publications WHERE machine_id=?", (mid,)).fetchone()
    if not pub:
        return None, []
    out = []
    for p in db.execute("""SELECT p.seq, p.qty, l.* FROM published p JOIN lines l ON l.rn=p.rn AND l.linija=p.linija
                           WHERE p.machine_id=? ORDER BY p.seq""", (mid,)):
        d = dict(p)
        rep = db.execute("""SELECT COALESCE(SUM(qty),0), SUM(status='pending') FROM reports
                            WHERE rn=? AND linija=? AND machine_id=? AND ts>=?""",
                         (d["rn"], d["linija"], mid, pub[0])).fetchone()
        d["done"] = rep[0]
        d["pending"] = rep[1] or 0
        d["left"] = max(d["qty"] - rep[0], 0)
        d["qty_planned"] = d.pop("qty")
        out.append(d)
    return pub[0], out


@app.get("/api/operator/plan")
def operator_plan(machine_id: int | None = None, u=Depends(current_user), db=Depends(get_db)):
    mid = operator_machine(u, machine_id)
    m = db.execute("SELECT id,label FROM machines WHERE id=?", (mid,)).fetchone()
    at, rows = operator_rows(db, mid)
    hist = [dict(r) for r in db.execute("""SELECT r.*, us.name operator, l.naziv FROM reports r
        JOIN users us ON us.id=r.user_id LEFT JOIN lines l ON l.rn=r.rn AND l.linija=r.linija
        WHERE r.machine_id=? ORDER BY r.id DESC LIMIT 15""", (mid,))]
    return {"machine": dict(m), "published_at": at, "rows": rows, "history": hist}


class Report(BaseModel):
    rn: int
    linija: int
    qty: float
    machine_id: int | None = None


@app.post("/api/operator/report")
def report(body: Report, u=Depends(current_user), db=Depends(get_db)):
    mid = operator_machine(u, body.machine_id)
    _at, rows = operator_rows(db, mid)
    row = next((r for r in rows if r["rn"] == body.rn and r["linija"] == body.linija), None)
    if not row:
        raise HTTPException(404, "Linija nije u planu")
    if not 0 < body.qty <= row["left"] + 1e-6:
        raise HTTPException(400, f"Količina mora biti između 0 i {row['left']:g}")
    line = db.execute("SELECT qty_left FROM lines WHERE rn=? AND linija=?", (body.rn, body.linija)).fetchone()
    pend = db.execute("SELECT COALESCE(SUM(qty),0) FROM reports WHERE rn=? AND linija=? AND status='pending'",
                      (body.rn, body.linija)).fetchone()[0]
    target = line["qty_left"] - pend - body.qty
    db.execute("INSERT INTO reports(rn,linija,machine_id,user_id,qty,ts,target_left) VALUES(?,?,?,?,?,?,?)",
               (body.rn, body.linija, mid, u["id"], body.qty, now(), target))
    return {"ok": True, "left": row["left"] - body.qty}


@app.get("/api/alerts")
def alerts(_=Depends(boss), db=Depends(get_db)):
    """Operater je cekirao, a SAP (query preostala norma) to jos ne pokazuje."""
    out = []
    for r in db.execute("""SELECT r.*, us.name operator, m.label machine, l.naziv, l.qty_left FROM reports r
        JOIN users us ON us.id=r.user_id JOIN machines m ON m.id=r.machine_id
        LEFT JOIN lines l ON l.rn=r.rn AND l.linija=r.linija
        WHERE r.status='pending' ORDER BY r.id"""):
        d = dict(r)
        age = (datetime.now(timezone.utc) - datetime.fromisoformat(d["ts"])).total_seconds() / 60
        d["age_min"] = round(age)
        d["overdue"] = age >= config.ALERT_AFTER_MIN
        out.append(d)
    return out


# ---------- sinhronizacija ----------
@app.get("/api/status")
def status(_=Depends(current_user), db=Depends(get_db)):
    return {"last_sync": dbm.get_meta(db, "last_sync"), "last_error": dbm.get_meta(db, "last_error"),
            "source": get_source().name, "interval_sec": config.SYNC_INTERVAL_SEC}


@app.post("/api/sync")
async def sync_now(_=Depends(boss)):
    try:
        return await do_sync(force=True)
    except Exception as e:
        raise HTTPException(500, f"Sinhronizacija nije uspjela: {e}")


@app.post("/api/upload/{kind}")
async def upload(kind: str, request: Request, _=Depends(boss)):
    """Rucni upload Excel exporta (privremeno / fallback dok nije spojen SAP)."""
    path = {"orders": config.ORDERS_XLSX, "norms": config.NORMS_XLSX}.get(kind)
    if not path:
        raise HTTPException(404)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "wb") as f:
        f.write(await request.body())
    return {"ok": True}


@app.get("/")
def index():
    return FileResponse(os.path.join(STATIC, "index.html"))


app.mount("/static", StaticFiles(directory=STATIC), name="static")
