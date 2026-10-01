"""Sinhronizacija sa SAP-om + provjera da li je operaterov unos proknjizen u SAP-u."""
import json
from datetime import datetime, timezone

from . import config
from .db import get_meta, set_meta

EPS = 1e-6


def now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _num(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0.0


def sync_data(db, orders, norms):
    """Aktivna linija = RN je aktivan u Query 1 I linija postoji u Query 2 sa preostalom normom,
    na jednoj od ukljucenih masina."""
    active_rn = {int(o["RN"]) for o in orders if o.get("RN") is not None
                 and (o.get("Status") or "") in config.ACTIVE_STATUSES}
    machines = {r["sap_name"]: r["id"] for r in db.execute("SELECT id, sap_name FROM machines WHERE enabled=1")}
    set_meta(db, "sap_machines", json.dumps(sorted({r["Naziv Masine"] for r in norms if r.get("Naziv Masine")})))
    ts, seen = now(), set()
    for r in norms:
        if r.get("Naziv Masine") not in machines or r.get("RN") is None:
            continue
        rn, lin = int(r["RN"]), int(r["Linija"])
        if rn not in active_rn or _num(r.get("Ostalo Komada")) <= EPS:
            continue
        seen.add((rn, lin))
        db.execute("""INSERT INTO lines(rn,linija,sap_machine,kpl,projekt,naziv,item_code,datum_isporuke,
            datum_heftanja,qty_total,qty_left,norm_per_unit,norm_left,active,updated)
            VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,1,?)
            ON CONFLICT(rn,linija) DO UPDATE SET sap_machine=excluded.sap_machine, kpl=excluded.kpl,
              projekt=excluded.projekt, naziv=excluded.naziv, item_code=excluded.item_code,
              datum_isporuke=excluded.datum_isporuke, datum_heftanja=excluded.datum_heftanja,
              qty_total=excluded.qty_total, qty_left=excluded.qty_left,
              norm_per_unit=excluded.norm_per_unit, norm_left=excluded.norm_left, active=1,
              updated=excluded.updated""",
                   (rn, lin, r["Naziv Masine"], str(r.get("Glavni nalog KPL") or ""), r.get("PROJEKT"),
                    r.get("NazivProizvoda"), str(r.get("ItemCode") or ""), r.get("Datum Isporuke"),
                    r.get("DatumSastavljanja"), _num(r.get("Planiranokomadaponalogu")),
                    _num(r.get("Ostalo Komada")), _num(r.get("Norma/kom")), _num(r.get("Preostalo norme")), ts))
    # linije koje vise nisu aktivne
    for row in db.execute("SELECT rn, linija FROM lines WHERE active=1").fetchall():
        if (row["rn"], row["linija"]) not in seen:
            db.execute("UPDATE lines SET active=0, qty_left=0, norm_left=0, updated=? WHERE rn=? AND linija=?",
                       (ts, row["rn"], row["linija"]))
    # nove linije -> plan, po datumu isporuke
    new = db.execute("""SELECT l.rn, l.linija, l.sap_machine, l.datum_isporuke FROM lines l
        LEFT JOIN plan p ON p.rn=l.rn AND p.linija=l.linija WHERE p.rn IS NULL AND l.active=1
        ORDER BY l.datum_isporuke IS NULL, l.datum_isporuke, l.rn, l.linija""").fetchall()
    for n in new:
        mid = machines[n["sap_machine"]]
        pos = db.execute("SELECT COALESCE(MAX(position),0)+1 FROM plan WHERE machine_id=?", (mid,)).fetchone()[0]
        db.execute("INSERT INTO plan(rn,linija,machine_id,position) VALUES(?,?,?,?)", (n["rn"], n["linija"], mid, pos))
    verify_reports(db)
    return {"linija": len(seen), "novih": len(new)}


def verify_reports(db):
    """Unos operatera je 'confirmed' kad je SAP preostala kolicina pala na ocekivanu vrijednost
    (ili se linija zatvorila u SAP-u). Inace ostaje 'pending' i nakon ALERT_AFTER_MIN ide u upozorenja."""
    ts = now()
    for r in db.execute("SELECT * FROM reports WHERE status='pending' ORDER BY id").fetchall():
        line = db.execute("SELECT qty_left, active FROM lines WHERE rn=? AND linija=?",
                          (r["rn"], r["linija"])).fetchone()
        if line is None or not line["active"] or line["qty_left"] <= r["target_left"] + EPS:
            db.execute("UPDATE reports SET status='confirmed', confirmed_at=? WHERE id=?", (ts, r["id"]))


def run_sync(db, source, force=False):
    sig = json.dumps(source.signature())
    if not force and source.signature() is not None and sig == get_meta(db, "source_sig"):
        return {"skipped": True}
    try:
        orders, norms = source.fetch()
        res = sync_data(db, orders, norms)
        set_meta(db, "source_sig", sig)
        set_meta(db, "last_sync", now())
        set_meta(db, "last_error", "")
        res["source"] = source.name
        return res
    except Exception as e:  # prikazi poslovodji, ne rusi aplikaciju
        set_meta(db, "last_error", f"{now()} {type(e).__name__}: {e}")
        raise
