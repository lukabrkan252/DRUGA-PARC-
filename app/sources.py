"""Izvori podataka: Excel exporti (fallback/upload) ili direktno SAP/SQL."""
import os

from . import config

ORDER_COLS = ["RN", "Status"]
NORM_COLS = ["PROJEKT", "Glavni nalog KPL", "RN", "Linija", "ItemCode", "NazivProizvoda",
             "Planiranokomadaponalogu", "Ostalo Komada", "Datum Isporuke", "DatumSastavljanja",
             "Norma/kom", "Preostalo norme", "Naziv Masine"]


def _clean(v):
    if hasattr(v, "isoformat"):
        return v.isoformat()[:10]
    return v


REFRESH_PS1 = os.path.join(config.BASE, "windows", "osvjezi_excel.ps1")


def refresh_workbook(path):
    """Excel se u pozadini otvori preko PowerShella, osvjezi sve veze (Power Query -> SAP, Windows pristupom
    korisnika), sacuva i zatvori. Ne treba nikakav dodatni program osim Excela."""
    import subprocess
    r = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", REFRESH_PS1, path],
                       capture_output=True, text=True, timeout=900)
    if r.returncode != 0:
        raise RuntimeError(f"Excel osvjezavanje nije uspjelo ({os.path.basename(path)}): {(r.stdout + r.stderr).strip()[-300:]}")


def can_refresh():
    return config.EXCEL_REFRESH and os.name == "nt" and os.path.exists(REFRESH_PS1)


class ExcelSource:
    name = "excel"

    def signature(self):
        if can_refresh():
            return None  # svaki ciklus osvjezi iz SAP-a
        return tuple(os.path.getmtime(p) if os.path.exists(p) else 0
                     for p in (config.ORDERS_XLSX, config.NORMS_XLSX))

    @staticmethod
    def _read(path, cols):
        from openpyxl import load_workbook
        wb = load_workbook(path, read_only=True, data_only=True)
        try:
            names = ["Query_novo"] + [n for n in wb.sheetnames if n != "Query_novo"]
            for n in names:
                if n not in wb.sheetnames:
                    continue
                rows = wb[n].iter_rows(values_only=True)
                head = next(rows, None) or ()
                if all(c in head for c in cols):
                    idx = {c: head.index(c) for c in cols}
                    return [{c: _clean(r[i]) for c, i in idx.items()} for r in rows if any(v is not None for v in r)]
            raise ValueError(f"{os.path.basename(path)}: nije nadjen sheet sa kolonama {cols}")
        finally:
            wb.close()

    def fetch(self):
        if can_refresh():
            for p in (config.ORDERS_XLSX, config.NORMS_XLSX):
                refresh_workbook(p)
        return self._read(config.ORDERS_XLSX, ORDER_COLS), self._read(config.NORMS_XLSX, NORM_COLS)


class SqlSource:
    """Direktno iz SAP B1 baze (MS SQL). SQL je isti kao u Power Query-ju iz Excela (queries/*.sql)."""
    name = "sql"

    def signature(self):
        return None  # uvijek povuci svjeze

    def _query(self, sql_path):
        import pymssql  # type: ignore
        conn = pymssql.connect(server=config.SQL_HOST, port=config.SQL_PORT, user=config.SQL_USER,
                               password=config.SQL_PASSWORD, database=config.SQL_DB, login_timeout=15, timeout=120)
        try:
            cur = conn.cursor()
            cur.execute("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")  # samo citanje, ne smetamo SAP-u
            cur.execute("SET NOCOUNT ON")
            cur.execute(open(sql_path, encoding="utf-8").read())
            while cur.description is None and cur.nextset():  # preskoci CREATE/INSERT #temp dijelove
                pass
            cols = [d[0] for d in cur.description]
            return [{c: _clean(v) for c, v in zip(cols, row)} for row in cur.fetchall()]
        finally:
            conn.close()

    def fetch(self):
        return self._query(config.ORDERS_SQL), self._query(config.NORMS_SQL)


def get_source():
    return SqlSource() if config.SQL_USER else ExcelSource()
