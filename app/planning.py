"""Racunanje plana: zeleno/crveno prema kapacitetu (norma je u minutama)."""
import math

EPS = 1e-6


def compute_plan(items, capacity_h):
    """items: lista po prioritetu, svaki dict sa: qty (kom koje ostaju), norm_per_unit (min/kom),
    norm_left (min), split_qty (None ili prihvacena podjela).
    Vraca listu redova sa 'status': green | partial | red | none.
    - partial: linija ne ulazi cijela, 'fit_qty' je koliko komada ulazi (predlog podjele)
    - prihvacena podjela daje dva reda: dio A ('part':'A') i ostatak ('part':'B')."""
    cap = (capacity_h or 0) * 60.0
    rows, used, closed = [], 0.0, False

    def unit_norm(it):
        if it["norm_per_unit"]:
            return it["norm_per_unit"]
        return it["norm_left"] / it["qty"] if it["qty"] else 0.0

    for it in items:
        qty, npu = it["qty"], unit_norm(it)
        split = it.get("split_qty")
        parts = [(qty, None)]
        if split and 0 < split < qty - EPS:
            parts = [(split, "A"), (qty - split, "B")]
        for pqty, part in parts:
            norm = pqty * npu
            row = dict(it, part=part, part_qty=pqty, part_norm=norm, fit_qty=None)
            if cap <= 0:
                row["status"] = "none"
            elif not closed and used + norm <= cap + EPS:
                row["status"] = "green"
                used += norm
            elif not closed and part is None and npu > 0 and cap - used >= npu - EPS and pqty > 1:
                fit = min(math.floor((cap - used) / npu + EPS), int(pqty) - 1)
                row["status"] = "partial" if fit >= 1 else "red"
                row["fit_qty"] = fit if fit >= 1 else None
                closed = True
            else:
                row["status"] = "red"
                closed = True
            rows.append(row)
    green_norm = sum(r["part_norm"] for r in rows if r["status"] == "green")
    total_norm = sum(r["part_norm"] for r in rows)
    return rows, {"capacity_min": cap, "green_min": green_norm, "total_min": total_norm}
