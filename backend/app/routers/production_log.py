"""Production Log — simple shop-floor entry log, independent of Route Cards.

Unlike routers/production.py (which is tied to route_cards and still powers
Finished Goods / Dispatch auto-creation elsewhere), this is a flat log: pick
a line (Tube / Fabrication / Press Shop), a part, and log what happened.

OEE (Availability x Performance x Quality) is computed automatically here at
save time:
  - Standard Cycle Time is looked up from the part's Master Data BOM, not typed.
  - Total Time is Start Time to End Time.
  - Planned Down Time is worked out automatically: however much of the
    entry's Start-End window overlaps the fixed daily breaks below.
  - Unplanned Down Time (breakdown, power cut, etc.) is entered by hand,
    in minutes, on top of that.
  - Down Time = Planned + Unplanned. Run Time = Total Time - Down Time.
  - Availability = Run Time / Planned Production Time, where Planned Production
                   Time = Total Time - Planned Down Time (the fixed breaks). So only
                   an Unplanned Breakdown lowers Availability; no breakdown = 100%.
  - Performance  = (Standard Cycle Time(sec) x Produced Qty) / Run Time(sec)
                   -- if Standard Cycle Time isn't set in Master Data (e.g.
                   Power Press operations, which aren't cycle-time tracked
                   on the shop's own paper OEE sheet), Performance is shown
                   as 0% rather than left blank, matching that sheet.
  - Quality      = OK Qty / Produced Qty
  - OEE          = Availability x Performance x Quality

Deleting: an admin can delete entries from the Press Strokes page. Every deleted entry is
first copied (as JSON) into the `production_log_deleted` table, so nothing is lost for good.
"""
from datetime import date, time
from decimal import Decimal, InvalidOperation
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user, require_role
from .. import models, schemas

router = APIRouter(prefix="/production-log", tags=["production-log"])

# Fixed daily breaks -- for a full 9:00 AM to 8:00/8:30 PM shift this totals
# 60 min (10 + 30 + 10 + 10), matching the shop's own numbers.
PLANNED_BREAKS = [
    (time(9, 0), time(9, 10)),    # Morning Setup
    (time(13, 0), time(13, 30)),  # Lunch
    (time(15, 30), time(15, 40)), # Tea Break
    (time(18, 30), time(18, 40)), # Tea Break
]


def _to_minutes(t: time) -> int:
    return t.hour * 60 + t.minute


def _overlap_minutes(start: time, end: time, win_start: time, win_end: time) -> float:
    s, e = _to_minutes(start), _to_minutes(end)
    ws, we = _to_minutes(win_start), _to_minutes(win_end)
    if e <= s:  # shift crossing midnight isn't handled -- treat as 0 overlap
        return 0
    return max(0, min(e, we) - max(s, ws))


def _f(x) -> Optional[float]:
    if x is None or x == "":
        return None
    try:
        return float(x)
    except (TypeError, ValueError, InvalidOperation):
        return None


def _compute_oee_fields(payload: schemas.ProductionLogEntryCreate, db: Session) -> dict:
    """Everything derivable from the raw entry. Never raises -- leaves a
    field as None if its inputs aren't there yet, rather than guessing."""
    out = {
        "standard_cycle_time_sec": None,
        "total_time_min": None,
        "planned_down_time_min": None,
        "down_time_min": None,
        "run_time_min": None,
        "availability": None,
        "performance": None,
        "quality": None,
        "oee": None,
    }

    # Standard cycle time: looked up from this part's BOM operations (Master
    # Data) -- scoped to the chosen BOM item when given, since operation
    # names like "Flaring" or "Punching" can repeat across a part's items
    # with different cycle times each.
    if payload.part_number and payload.operation_name:
        q = (
            db.query(models.BomOperation.cycle_time_sec)
            .join(models.BomItem, models.BomItem.id == models.BomOperation.bom_item_id)
            .filter(
                models.BomItem.part_number == payload.part_number,
                models.BomOperation.operation_name == payload.operation_name,
            )
        )
        if payload.bom_item_name:
            q = q.filter(models.BomItem.item_name == payload.bom_item_name)
        row = q.first()
        if row and row[0] is not None:
            out["standard_cycle_time_sec"] = row[0]

    # Total time + automatic planned down time, from Start/End Time.
    total_min = None
    planned_down = None
    if payload.start_time and payload.end_time and _to_minutes(payload.end_time) > _to_minutes(payload.start_time):
        s, e = payload.start_time, payload.end_time
        total_min = _to_minutes(e) - _to_minutes(s)
        planned_down = sum(_overlap_minutes(s, e, ws, we) for ws, we in PLANNED_BREAKS)
    out["total_time_min"] = total_min
    out["planned_down_time_min"] = planned_down

    unplanned = _f(payload.unplanned_down_time_min) or 0
    down_min = None
    run_min = None
    if total_min is not None:
        down_min = (planned_down or 0) + unplanned
        run_min = max(0, total_min - down_min)
    out["down_time_min"] = down_min
    out["run_time_min"] = run_min

    produced = _f(payload.produced_qty)
    ok = _f(payload.ok_qty)
    cycle_sec = _f(out["standard_cycle_time_sec"])

    # Availability = Run Time / Planned Production Time, where Planned
    # Production Time = Total Time - Planned Down Time (fixed breaks).
    # Only an Unplanned Breakdown lowers it -- with none, it's 100%.
    if run_min is not None and total_min:
        planned_production = total_min - (planned_down or 0)
        if planned_production > 0:
            out["availability"] = round(run_min / planned_production, 5)

    # Quality = OK Qty / Produced Qty
    if produced and produced > 0 and ok is not None:
        out["quality"] = round(ok / produced, 5)

    # Performance = (Standard Cycle Time(sec) x Produced Qty) / Run Time(sec),
    # saved as-is (real value, not capped -- above 100% is a signal to
    # re-check the cycle time or the entry). With no Standard Cycle Time for
    # this operation (e.g. Power Press steps), Performance is 0% rather than
    # blank, as long as Run Time + Produced Qty are there.
    if run_min and run_min > 0 and produced:
        if cycle_sec:
            run_sec = run_min * 60
            out["performance"] = round((cycle_sec * produced) / run_sec, 5)
        else:
            out["performance"] = 0.0

    # OEE = Availability x Performance x Quality
    if out["availability"] is not None and out["performance"] is not None and out["quality"] is not None:
        out["oee"] = round(out["availability"] * out["performance"] * out["quality"], 5)

    return out


@router.get("/entries", response_model=List[schemas.ProductionLogEntryOut])
def list_entries(
    line: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    query = db.query(models.ProductionLogEntry)
    if line and line.lower() != "all":
        query = query.filter(models.ProductionLogEntry.line == line)
    if date_from:
        query = query.filter(models.ProductionLogEntry.entry_date >= date_from)
    if date_to:
        query = query.filter(models.ProductionLogEntry.entry_date <= date_to)
    return (
        query.order_by(
            models.ProductionLogEntry.entry_date.desc(),
            models.ProductionLogEntry.id.desc(),
        )
        .limit(500)
        .all()
    )


@router.post("/entries", response_model=schemas.ProductionLogEntryOut, status_code=201)
def add_entry(
    payload: schemas.ProductionLogEntryCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    data = payload.model_dump(exclude={"unplanned_down_time_min"})
    computed = _compute_oee_fields(payload, db)
    row = models.ProductionLogEntry(
        **data,
        extra_down_time_min=payload.unplanned_down_time_min,
        **computed,
        entry_by=current_user.id,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.get("/parts/{part_number}/items", response_model=List[str])
def list_part_items(
    part_number: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """This part's BOM items (e.g. "Tube", "Housing Pipe", "Assembly") from
    Master Data, for the Item dropdown — picking the item first means the
    Operation dropdown (and the cycle-time lookup) can't get confused when
    two items share an operation name."""
    rows = (
        db.query(models.BomItem.item_name)
        .filter(models.BomItem.part_number == part_number)
        .order_by(models.BomItem.item_seq)
        .all()
    )
    return [r[0] for r in rows]


@router.get("/parts/{part_number}/operations", response_model=List[str])
def list_part_operations(
    part_number: str,
    item_name: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Distinct operation names from this part's BOM (Master Data), for the
    Operation dropdown — so the list is always in sync with Master Data
    rather than duplicated/typed by hand. Pass item_name to scope to just
    that BOM item's operations (recommended, once an item is picked)."""
    q = (
        db.query(models.BomOperation.operation_name)
        .join(models.BomItem, models.BomItem.id == models.BomOperation.bom_item_id)
        .filter(models.BomItem.part_number == part_number)
    )
    if item_name:
        q = q.filter(models.BomItem.item_name == item_name)
    rows = q.distinct().order_by(models.BomOperation.operation_name).all()
    return [r[0] for r in rows]


@router.get("/operator-summary")
def operator_summary(
    line: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Per-operator averages (Availability/Performance/Quality/OEE) for the
    OEE Report page's operator breakdown."""
    query = db.query(models.ProductionLogEntry).filter(models.ProductionLogEntry.oee.isnot(None))
    if line and line.lower() != "all":
        query = query.filter(models.ProductionLogEntry.line == line)
    if date_from:
        query = query.filter(models.ProductionLogEntry.entry_date >= date_from)
    if date_to:
        query = query.filter(models.ProductionLogEntry.entry_date <= date_to)

    by_operator: dict = {}
    for row in query.all():
        name = row.operator_name or "—"
        bucket = by_operator.setdefault(name, {"n": 0, "avail": 0.0, "perf": 0.0, "qual": 0.0, "oee": 0.0})
        bucket["n"] += 1
        bucket["avail"] += float(row.availability or 0)
        bucket["perf"] += float(row.performance or 0)
        bucket["qual"] += float(row.quality or 0)
        bucket["oee"] += float(row.oee or 0)

    out = []
    for name, b in by_operator.items():
        n = b["n"]
        out.append({
            "operator_name": name,
            "entries": n,
            "avg_availability": round(b["avail"] / n, 5) if n else None,
            "avg_performance": round(b["perf"] / n, 5) if n else None,
            "avg_quality": round(b["qual"] / n, 5) if n else None,
            "avg_oee": round(b["oee"] / n, 5) if n else None,
        })
    out.sort(key=lambda r: (r["avg_oee"] or 0), reverse=True)
    return out


# ------------------------------------------------------------------ delete (admin only)
class EntryIds(BaseModel):
    ids: List[int]


_ARCHIVE_DDL = """
CREATE TABLE IF NOT EXISTS production_log_deleted (
    id          SERIAL PRIMARY KEY,
    original_id INTEGER,
    deleted_at  TIMESTAMPTZ DEFAULT now(),
    deleted_by  INTEGER,
    row_data    JSONB
)
"""


@router.post("/entries/bulk-delete")
def bulk_delete_entries(
    payload: EntryIds,
    db: Session = Depends(get_db),
    admin=Depends(require_role("admin")),
):
    """Delete production-log entries by id (admin only). The rows are copied into
    `production_log_deleted` first, in the same transaction."""
    ids = sorted(set(payload.ids))
    if not ids:
        raise HTTPException(400, "No entries selected")
    if len(ids) > 500:
        raise HTTPException(400, "Too many entries at once (max 500)")

    found = [
        row[0]
        for row in db.query(models.ProductionLogEntry.id).filter(models.ProductionLogEntry.id.in_(ids)).all()
    ]
    if not found:
        raise HTTPException(404, "Those entries no longer exist")

    if db.get_bind().dialect.name == "postgresql":
        table = models.ProductionLogEntry.__tablename__
        db.execute(text(_ARCHIVE_DDL))
        db.execute(
            text(
                "INSERT INTO production_log_deleted (original_id, deleted_by, row_data) "
                f"SELECT e.id, :uid, to_jsonb(e) FROM {table} e WHERE e.id = ANY(:ids)"
            ),
            {"uid": admin.id, "ids": found},
        )
    db.query(models.ProductionLogEntry).filter(models.ProductionLogEntry.id.in_(found)).delete(synchronize_session=False)
    db.commit()
    return {"deleted": len(found)}

