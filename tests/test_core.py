import os
import tempfile

import pytest

from app import config, db as dbm
from app.planning import compute_plan
from app.sync import sync_data, verify_reports


def item(qty, npu, split=None):
    return dict(qty=qty, norm_per_unit=npu, norm_left=qty * npu, split_qty=split)


def test_green_red_cut():
    rows, s = compute_plan([item(1, 60), item(1, 60), item(1, 60)], 2)  # 2h = 120 min
    assert [r["status"] for r in rows] == ["green", "green", "red"]
    assert s["green_min"] == 120


def test_partial_and_accepted_split():
    rows, _ = compute_plan([item(1, 60), item(10, 30)], 2)  # ostaje 60 min -> 2 kom stanu
    assert rows[1]["status"] == "partial" and rows[1]["fit_qty"] == 2
    rows, _ = compute_plan([item(1, 60), item(10, 30, split=2)], 2)
    assert [(r["part"], r["status"], r["part_qty"]) for r in rows[1:]] == [("A", "green", 2), ("B", "red", 8)]


def test_after_cut_everything_red():
    rows, _ = compute_plan([item(1, 100), item(1, 10)], 1)
    assert [r["status"] for r in rows] == ["red", "red"]


def test_no_capacity():
    rows, _ = compute_plan([item(1, 10)], 0)
    assert rows[0]["status"] == "none"


@pytest.fixture
def db():
    d = tempfile.mkdtemp()
    config.DB_PATH = os.path.join(d, "t.db")
    dbm.init_db()
    with dbm.session() as c:
        yield c


def norm(rn, lin, left, machine="Sekator"):
    return {"Naziv Masine": machine, "RN": rn, "Linija": lin, "Ostalo Komada": left, "Norma/kom": 10,
            "Preostalo norme": left * 10, "Planiranokomadaponalogu": 20, "Glavni nalog KPL": "1",
            "NazivProizvoda": "x", "ItemCode": "1", "Datum Isporuke": "2026-12-31"}


def test_only_active_orders_and_machines(db):
    orders = [{"RN": 1, "Status": "Otvoren"}, {"RN": 2, "Status": "Zatvoren"}]
    sync_data(db, orders, [norm(1, 1, 5), norm(2, 1, 5), norm(1, 2, 5, machine="Pakovanje")])
    assert [r["rn"] for r in db.execute("SELECT rn FROM lines WHERE active=1")] == [1]


def test_sap_verification(db):
    orders = [{"RN": 1, "Status": "Otvoren"}]
    sync_data(db, orders, [norm(1, 1, 20)])
    mid = db.execute("SELECT machine_id FROM plan").fetchone()[0]
    db.execute("INSERT INTO reports(rn,linija,machine_id,user_id,qty,ts,target_left) VALUES(1,1,?,1,5,'2026-01-01T00:00:00+00:00',15)", (mid,))
    sync_data(db, orders, [norm(1, 1, 20)])  # SAP jos nije proknjizen
    assert db.execute("SELECT status FROM reports").fetchone()[0] == "pending"
    sync_data(db, orders, [norm(1, 1, 15)])  # SAP proknjizen
    assert db.execute("SELECT status FROM reports").fetchone()[0] == "confirmed"
