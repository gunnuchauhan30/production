"""
Route Card entry — FR-2.1 to FR-2.3.

This is the manual entry point (v2.0 architecture): a user reads the
printed Route Card that Store already generates, and types its header
fields in here ONCE. There is no call out to Store from this router.
"""
from datetime import date
from decimal import Decimal
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import func, text
from sqlalchemy.orm import Session

from ..database import get_db, engine
from ..auth import get_current_user
from .. import models, schemas


def ensure_route_card_link() -> None:
    """Adds production_log_entries.route_card_id (the Job Card link) if the database
    does not have it yet. Runs at every start and does nothing once the column exists,
    so the same code works on a local database and on Railway with no manual SQL."""
    if engine.dialect.name != "postgresql":
        return
    try:
        with engine.begin() as conn:
            conn.execute(text(
                "ALTER TABLE production_log_entries "
                "ADD COLUMN IF NOT EXISTS route_card_id INTEGER REFERENCES route_cards(id)"
            ))
            conn.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_prod_log_route_card ON production_log_entries(route_card_id)"
            ))
    except Exception as exc:  # never stop the app from starting because of this
        print(f"[route_cards] could not add the Job Card link column: {exc}")


router = APIRouter(prefix="/route-cards", tags=["route-cards"], on_startup=[ensure_route_card_link])


@router.post("", response_model=schemas.RouteCardOut, status_code=status.HTTP_201_CREATED)
def create_route_card(
    payload: schemas.RouteCardCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    existing = db.query(models.RouteCard).filter(
        models.RouteCard.job_card_no == payload.job_card_no
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Job Card No. '{payload.job_card_no}' is already entered (route_card_id={existing.id})",
        )

    route_card = models.RouteCard(**payload.model_dump(), entered_by=current_user.id)
    db.add(route_card)
    db.commit()
    db.refresh(route_card)
    return route_card


@router.get("", response_model=List[schemas.RouteCardOut])
def list_route_cards(
    search: Optional[str] = None,
    part_number: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    query = db.query(models.RouteCard)
    if part_number:
        query = query.filter(func.lower(models.RouteCard.part_number) == part_number.strip().lower())
    if search:
        like = f"%{search}%"
        query = query.filter(
            (models.RouteCard.job_card_no.ilike(like)) | (models.RouteCard.part_number.ilike(like))
        )
    return query.order_by(models.RouteCard.entered_at.desc()).limit(200).all()


@router.get("/{route_card_id}", response_model=schemas.RouteCardOut)
def get_route_card(route_card_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    rc = db.query(models.RouteCard).get(route_card_id)
    if not rc:
        raise HTTPException(status_code=404, detail="Route card not found")
    return rc


@router.get("/{route_card_id}/progress", response_model=schemas.RouteCardProgress)
def get_route_card_progress(route_card_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    """
    FR-2.2 / FR-2.3: issued vs produced. Reads the v_route_card_last_operation
    view (created in the schema) to find the last operation's total produced
    and compare it against route_cards.issued_qty (FR-3.5 completion check).
    """
    rc = db.query(models.RouteCard).get(route_card_id)
    if not rc:
        raise HTTPException(status_code=404, detail="Route card not found")

    row = db.execute(
        text(
            "SELECT operation_name, total_produced_last_op FROM v_route_card_last_operation "
            "WHERE route_card_id = :rid"
        ),
        {"rid": route_card_id},
    ).fetchone()

    total_produced = row.total_produced_last_op if row else 0
    last_op_name = row.operation_name if row else None
    complete = bool(row) and total_produced is not None and total_produced >= rc.issued_qty

    return schemas.RouteCardProgress(
        route_card=rc,
        total_produced_last_op=total_produced or 0,
        last_operation_name=last_op_name,
        production_complete=complete,
    )


# ---------------------------------------------------------------------------
# Flow: what happened to the issued quantity, operation by operation.
# Built from the Production Log entries that were attached to this Job Card.
# ---------------------------------------------------------------------------
class FlowEntry(BaseModel):
    id: int
    entry_date: date
    shift: Optional[str] = None
    machine_no: Optional[str] = None
    operator_name: Optional[str] = None
    produced: Decimal = Decimal("0")
    ok: Decimal = Decimal("0")
    ng: Decimal = Decimal("0")
    rejection_reason: Optional[str] = None


class FlowStep(BaseModel):
    item_name: Optional[str] = None
    operation_name: str
    in_master_data: bool = True       # False = logged against the card but not in this part's BOM
    status: str                       # pending | in_progress | done
    came: Decimal = Decimal("0")      # quantity that reached this step (previous step's OK; issued qty for the first)
    planned: Decimal = Decimal("0")
    produced: Decimal = Decimal("0")
    ok: Decimal = Decimal("0")
    ng: Decimal = Decimal("0")
    wip: Decimal = Decimal("0")       # came - produced (never below 0)
    over: bool = False                # produced more than came
    first_date: Optional[date] = None
    last_date: Optional[date] = None
    entries: List[FlowEntry] = []


class FlowDispatch(BaseModel):
    order_no: Optional[str] = None
    actual_dispatch_date: Optional[date] = None
    qty_dispatched: Decimal = Decimal("0")


class FlowOut(BaseModel):
    route_card: schemas.RouteCardOut
    steps: List[FlowStep]
    issued: Decimal
    total_ng: Decimal
    last_step_name: Optional[str] = None
    last_step_ok: Decimal = Decimal("0")
    dispatched: Decimal = Decimal("0")
    balance: Decimal = Decimal("0")   # issued - rejected - dispatched
    dispatches: List[FlowDispatch] = []
    entry_count: int = 0


def _d(v) -> Decimal:
    return Decimal(str(v)) if v is not None else Decimal("0")


def _ci(v: Optional[str]) -> str:
    return (v or "").strip().lower()


@router.get("/{route_card_id}/flow", response_model=FlowOut)
def get_route_card_flow(route_card_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    rc = db.query(models.RouteCard).get(route_card_id)
    if not rc:
        raise HTTPException(status_code=404, detail="Route card not found")

    # The part's operations in the order they happen: BOM item order, then operation order.
    bom_rows = (
        db.query(models.BomItem.item_name, models.BomOperation.operation_name)
        .join(models.BomOperation, models.BomOperation.bom_item_id == models.BomItem.id)
        .filter(func.lower(models.BomItem.part_number) == rc.part_number.strip().lower())
        .order_by(models.BomItem.item_seq, models.BomItem.id, models.BomOperation.operation_seq, models.BomOperation.id)
        .all()
    )
    entries = (
        db.query(models.ProductionLogEntry)
        .filter(models.ProductionLogEntry.route_card_id == rc.id)
        .order_by(models.ProductionLogEntry.entry_date, models.ProductionLogEntry.id)
        .all()
    )

    used = set()

    def collect(item_name: Optional[str], op_name: str, strict_item: bool):
        found = []
        for e in entries:
            if e.id in used or _ci(e.operation_name) != _ci(op_name):
                continue
            # An entry with no item chosen matches the operation by name alone.
            if strict_item and _ci(e.bom_item_name) and _ci(e.bom_item_name) != _ci(item_name):
                continue
            found.append(e)
        for e in found:
            used.add(e.id)
        return found

    plan = [(item, op, True, True) for item, op in bom_rows]
    # Entries logged against this card for an operation that is not in the BOM: keep them visible.
    for e in entries:
        if not any(_ci(op) == _ci(e.operation_name) for _, op, _, _ in plan):
            plan.append((e.bom_item_name, e.operation_name, False, False))

    issued = _d(rc.issued_qty)
    prev_ok = issued
    steps: List[FlowStep] = []
    total_ng = Decimal("0")
    last_name, last_ok = None, Decimal("0")

    for item, op, in_bom, strict in plan:
        rows = collect(item, op, strict)
        if not rows and not in_bom:
            continue
        produced = sum((_d(e.produced_qty) for e in rows), Decimal("0"))
        ng = sum((_d(e.ng_qty) for e in rows), Decimal("0"))
        ok = sum((_d(e.ok_qty) if e.ok_qty is not None else _d(e.produced_qty) - _d(e.ng_qty) for e in rows), Decimal("0"))
        planned = sum((_d(e.planned_qty) for e in rows), Decimal("0"))
        came = prev_ok
        if not rows:
            status_ = "pending"
        elif produced >= came and came > 0:
            status_ = "done"
        else:
            status_ = "in_progress"
        dates = [e.entry_date for e in rows]
        steps.append(FlowStep(
            item_name=item, operation_name=op, in_master_data=in_bom, status=status_,
            came=came, planned=planned, produced=produced, ok=ok, ng=ng,
            wip=max(came - produced, Decimal("0")) if rows else Decimal("0"),
            over=bool(rows) and produced > came,
            first_date=min(dates) if dates else None, last_date=max(dates) if dates else None,
            entries=[FlowEntry(
                id=e.id, entry_date=e.entry_date, shift=e.shift, machine_no=e.machine_no,
                operator_name=e.operator_name, produced=_d(e.produced_qty),
                ok=_d(e.ok_qty) if e.ok_qty is not None else _d(e.produced_qty) - _d(e.ng_qty),
                ng=_d(e.ng_qty), rejection_reason=e.rejection_reason,
            ) for e in rows],
        ))
        if rows:
            prev_ok = ok
            total_ng += ng
            last_name, last_ok = op, ok

    dispatches = (
        db.query(models.Dispatch).filter(models.Dispatch.route_card_id == rc.id)
        .order_by(models.Dispatch.actual_dispatch_date, models.Dispatch.id).all()
    )
    dispatched = sum((_d(d.qty_dispatched) for d in dispatches), Decimal("0"))

    return FlowOut(
        route_card=rc, steps=steps, issued=issued, total_ng=total_ng,
        last_step_name=last_name, last_step_ok=last_ok,
        dispatched=dispatched, balance=issued - total_ng - dispatched,
        dispatches=[FlowDispatch(order_no=d.order_no, actual_dispatch_date=d.actual_dispatch_date,
                                 qty_dispatched=_d(d.qty_dispatched)) for d in dispatches],
        entry_count=len(entries),
    )
