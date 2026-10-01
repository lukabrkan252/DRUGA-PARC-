import os

# Sve putanje su relativne u odnosu na folder aplikacije, pa zip radi s bilo koje lokacije/racunara.
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.getenv("MO_DB", os.path.join(BASE, "data", "mo.db"))
ORDERS_XLSX = os.getenv("ORDERS_XLSX", os.path.join(BASE, "data", "nalozi.xlsx"))
NORMS_XLSX = os.getenv("NORMS_XLSX", os.path.join(BASE, "data", "preostala_norma.xlsx"))
# Excel (Windows + instaliran Excel): prije svakog citanja osvjezi Power Query veze u fajlovima
EXCEL_REFRESH = os.getenv("EXCEL_REFRESH", "1") == "1"
SYNC_INTERVAL_SEC = int(os.getenv("SYNC_INTERVAL_SEC", "300"))
# Radni nalog je aktivan ako ima jedan od ovih statusa u Query 1
ACTIVE_STATUSES = {s.strip() for s in os.getenv("ACTIVE_STATUSES", "Otvoren").split(",")}
# Nakon koliko minuta se neproknjizen unos operatera javlja poslovodji
ALERT_AFTER_MIN = int(os.getenv("ALERT_AFTER_MIN", "30"))
BOSS_PIN = os.getenv("BOSS_PIN", "1234")

# SAP B1 (MS SQL Server). Ako je SQL_USER postavljen, aplikacija vuce direktno iz baze umjesto iz Excela.
SQL_HOST = os.getenv("SQL_HOST", "192.168.0.45")
SQL_PORT = int(os.getenv("SQL_PORT", "1433"))
SQL_DB = os.getenv("SQL_DB", "SBO_GS-TMT_PROD")
SQL_USER = os.getenv("SQL_USER", "")
SQL_PASSWORD = os.getenv("SQL_PASSWORD", "")  # samo preko env varijable, nikad u kodu
ORDERS_SQL = os.getenv("ORDERS_SQL", os.path.join(BASE, "queries", "nalozi.sql"))
NORMS_SQL = os.getenv("NORMS_SQL", os.path.join(BASE, "queries", "preostala_norma.sql"))

# Pocetne masine: (naziv u SAP queryju, naziv u aplikaciji)
DEFAULT_MACHINES = [
    ('Abkant presa "HACO"', "HACO presa"),
    ('Strug "Böhringer" D-530/2000', "Strug Böhringer"),
    ("CNC Glodalica Kekeisen 2500", "Kekeisen 2500"),
    ('CNC Glodalica  "MAHO" MH1200S', "MAHO 1200"),
    ('Koordinatka "TOS" WKV 100 (v.koordinatka)', "TOS WKV 100"),
    ("Sekator", "Sekator"),
]
