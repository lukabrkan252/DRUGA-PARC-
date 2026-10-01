"""Izvori podataka: Excel exporti (fallback/upload) ili direktno SAP/SQL."""
import os

from . import config

ORDER_COLS = ["RN", "Status"]
NORM_COLS = ["PROJEKT", "Glavni nalog KPL", "RN", "Linija", "ItemCode", "NazivProizvoda",
             "Planiranokomadaponalogu", "Ostalo Komada", "Datum Isporuke", "DatumSastavljanja",
             "Norma/kom", "Preostalo norme", "Naziv Masine"]


def _clean(v):
    import pandas as pd
    if v is None or (not hasattr(v, "__len__") and pd.isna(v)):
        return None
    if hasattr(v, "isoformat"):
        return v.isoformat()[:10]
    return v


def refresh_workbook(path):
    """Otvori Excel u pozadini, osvjezi sve veze (Power Query -> SAP, tvojim Windows pristupom), sacuvaj i zatvori."""
    import pythoncom  # type: ignore
    import win32com.client  # type: ignore
    pythoncom.CoInitialize()
    xl = win32com.client.DispatchEx("Excel.Application")
    try:
        xl.Visible = False
        xl.DisplayAlerts = False
        wb = xl.Workbooks.Open(os.path.abspath(path), UpdateLinks=0)
        for c in wb.Connections:  # osvjezavanje mora biti sinhrono
            try:
                c.OLEDBConnection.BackgroundQuery = False
            except Exception:
                pass
        for ws in wb.Worksheets:
            for lo in ws.ListObjects:
                try:
                    lo.QueryTable.BackgroundQuery = False
                except Exception:
                    pass
        wb.RefreshAll()
        xl.CalculateUntilAsyncQueriesDone()
        wb.Save()
        wb.Close(False)
    finally:
        xl.Quit()
        pythoncom.CoUninitialize()


def can_refresh():
    if not config.EXCEL_REFRESH or os.name != "nt":
        return False
    try:
        import win32com.client  # noqa: F401
        return True
    except ImportError:
        return False


class ExcelSource:
    name = "excel"

    def signature(self):
        if can_refresh():
            return None  # svaki ciklus osvjezi iz SAP-a
        return tuple(os.path.getmtime(p) if os.path.exists(p) else 0
                     for p in (config.ORDERS_XLSX, config.NORMS_XLSX))

    @staticmethod
    def _read(path, cols):
        import pandas as pd
        xl = pd.ExcelFile(path)
        sheets = ["Query_novo"] + [s for s in xl.sheet_names if s != "Query_novo"]
        for s in sheets:
            if s in xl.sheet_names:
                head = xl.parse(s, nrows=0)
                if all(c in head.columns for c in cols):
                    df = xl.parse(s, usecols=cols)
                    return [{k: _clean(v) for k, v in r.items()} for r in df.to_dict("records")]
        raise ValueError(f"{os.path.basename(path)}: nije nadjen sheet sa kolonama {cols}")

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
