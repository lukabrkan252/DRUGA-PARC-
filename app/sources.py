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


class ExcelSource:
    name = "excel"

    def signature(self):
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
        return self._read(config.ORDERS_XLSX, ORDER_COLS), self._read(config.NORMS_XLSX, NORM_COLS)


class SqlSource:
    """Query-ji se citaju iz .sql fajlova; nazivi kolona moraju biti isti kao u Excel exportima."""
    name = "sql"

    def signature(self):
        return None  # uvijek povuci svjeze

    def _query(self, sql_path):
        if config.SAP_DRIVER == "hdbcli":
            from hdbcli import dbapi  # type: ignore
            conn = dbapi.connect(**dict(p.split("=", 1) for p in config.SAP_CONN.split(";") if p))
        else:
            import pyodbc  # type: ignore
            conn = pyodbc.connect(config.SAP_CONN)
        try:
            cur = conn.cursor()
            cur.execute(open(sql_path, encoding="utf-8").read())
            cols = [d[0] for d in cur.description]
            return [{c: _clean(v) for c, v in zip(cols, row)} for row in cur.fetchall()]
        finally:
            conn.close()

    def fetch(self):
        return self._query(config.ORDERS_SQL), self._query(config.NORMS_SQL)


def get_source():
    return SqlSource() if config.SAP_CONN else ExcelSource()
