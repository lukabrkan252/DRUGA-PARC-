import sqlite3
from contextlib import contextmanager

from . import config

SCHEMA = """
CREATE TABLE IF NOT EXISTS machines(
  id INTEGER PRIMARY KEY, sap_name TEXT UNIQUE, label TEXT,
  capacity_h REAL DEFAULT 0, enabled INTEGER DEFAULT 1, sort INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS lines(
  rn INTEGER, linija INTEGER, sap_machine TEXT, kpl TEXT, projekt TEXT, naziv TEXT,
  item_code TEXT, datum_isporuke TEXT, datum_heftanja TEXT,
  qty_total REAL, qty_left REAL, norm_per_unit REAL, norm_left REAL,
  active INTEGER DEFAULT 1, updated TEXT, PRIMARY KEY(rn, linija));
CREATE TABLE IF NOT EXISTS plan(
  rn INTEGER, linija INTEGER, machine_id INTEGER, position REAL, split_qty REAL,
  PRIMARY KEY(rn, linija));
CREATE TABLE IF NOT EXISTS publications(machine_id INTEGER PRIMARY KEY, published_at TEXT, week TEXT);
CREATE TABLE IF NOT EXISTS capacity(machine_id INTEGER, week TEXT, hours REAL, PRIMARY KEY(machine_id, week));
CREATE TABLE IF NOT EXISTS published(
  machine_id INTEGER, seq INTEGER, rn INTEGER, linija INTEGER, qty REAL);
CREATE TABLE IF NOT EXISTS reports(
  id INTEGER PRIMARY KEY AUTOINCREMENT, rn INTEGER, linija INTEGER, machine_id INTEGER,
  user_id INTEGER, qty REAL, ts TEXT, target_left REAL,
  status TEXT DEFAULT 'pending', confirmed_at TEXT);
CREATE TABLE IF NOT EXISTS users(
  id INTEGER PRIMARY KEY, name TEXT, pin TEXT UNIQUE, role TEXT, machine_id INTEGER);
CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY, user_id INTEGER);
CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT);
"""


def connect(path=None):
    conn = sqlite3.connect(path or config.DB_PATH, timeout=30, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


@contextmanager
def session(path=None):
    conn = connect(path)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def get_meta(db, key, default=None):
    r = db.execute("SELECT value FROM meta WHERE key=?", (key,)).fetchone()
    return r["value"] if r else default


def set_meta(db, key, value):
    db.execute("INSERT INTO meta(key,value) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
               (key, value))


def add_machine(db, sap_name, label=None):
    """Dodaje masinu i njenog operatera (PIN se dodjeljuje automatski)."""
    n = db.execute("SELECT COALESCE(MAX(sort),0)+1 FROM machines").fetchone()[0]
    label = label or sap_name
    cur = db.execute("INSERT INTO machines(sap_name,label,sort) VALUES(?,?,?)", (sap_name, label, n))
    mid = cur.lastrowid
    pin = 1000 + n
    while db.execute("SELECT 1 FROM users WHERE pin=?", (str(pin),)).fetchone():
        pin += 1
    db.execute("INSERT INTO users(name,pin,role,machine_id) VALUES(?,?,?,?)",
               (f"Operater {label}", str(pin), "operator", mid))
    return mid


def init_db(path=None):
    with session(path) as db:
        db.executescript(SCHEMA)
        try:
            db.execute("ALTER TABLE publications ADD COLUMN week TEXT")
        except Exception:
            pass  # kolona vec postoji
        if not db.execute("SELECT 1 FROM users WHERE role='boss'").fetchone():
            db.execute("INSERT INTO users(name,pin,role) VALUES('Poslovođa MO',?, 'boss')", (config.BOSS_PIN,))
        if not db.execute("SELECT 1 FROM machines").fetchone():
            for sap, label in config.DEFAULT_MACHINES:
                add_machine(db, sap, label)
