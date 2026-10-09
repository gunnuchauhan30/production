"""
Operation-wise production entry — FR-3.1 to FR-3.5.

FR-3.3 (pre-fill next operation's qty_planned) is implemented HERE, in
the application layer, by reading the v_operation_progress view for the
previous operation_seq — not by a fragile insert-cascading trigger (see
SRS v2.0 / schema comments for why).
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session
from decimal import Decimal

from ..database import get_db
from ..auth import get_current_user
from .. import models, schemas

router = APIRouter(prefix="/production-entries", tags=["production"])


def _get_previous_operation_total(db: Session, route_card_id: int, operation_seq: int) -> Decimal:
    """FR-3.3: previous operation's total produced becomes this operation's default qty_planned."""
    if operation_seq <= 1:
        return Decimal("0")
    row = db.execute(
        text(
            "SELECT total_produced FROM v_operation_progress "
            "WHERE route_card_id = :rid AND operation_seq = :seq"
        ),
        {"rid": route_card_id, "seq": operation_seq - 1},
    ).fetchone()
    return Decimal(str(row.total_produced)) if row and row.total_produced is not None else Decimal("0")


@router.post("", response_model=schemas.ProductionEntryOut, status_code=status.HTTP_201_CREATED)
def create_production_entry(
    payload: schemas.ProductionEntryCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    route_card = db.query(models.RouteCard).get(payload.route_card_id)
    if not route_card:
        raise HTTPException(status_code=404, detail="route_card_id does not exist")

    # FR-3.3a: validate part_routing has this operation_seq for this part
    routing_row = db.query(models.PartRouting).filter(
        models.PartRouting.part_number == route_card.part_number,
        models.PartRouting.operation_seq == payload.operation_seq,
    ).first()
    if not routing_row:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Part routing not set up for part '{route_card.part_number}', "
                f"operation_seq {payload.operation_seq}. Ask admin to add it in Master Data."
            ),
        )

    qty_planned = payload.qty_planned
    if qty_planned is None:
        qty_planned = _get_previous_operation_total(db, payload.route_card_id, payload.operation_seq)

    entry = models.ProductionEntry(
        route_card_id=payload.route_card_id,
        operation_name=payload.operation_name,
        operation_seq=payload.operation_seq,
        shift=payload.shift,
        operator_name=payload.operator_name,
        machine_no=payload.machine_no,
        qty_planned=qty_planned,
        qty_produced=payload.qty_produced,
        ok_qty=payload.ok_qty,
        rejected_qty=payload.rejected_qty,
        rework_qty=payload.rework_qty,
        hold_qty=payload.hold_qty,
        down_time_min=payload.down_time_min,
        down_time_reason=payload.down_time_reason,
        remarks=payload.remarks,
        entry_by=current_user.id,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("", response_model=List[schemas.ProductionEntryOut])
def list_production_entries(
    route_card_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    query = db.query(models.ProductionEntry)
    if route_card_id:
        query = query.filter(models.ProductionEntry.route_card_id == route_card_id)
    return query.order_by(
        models.ProductionEntry.route_card_id, models.ProductionEntry.operation_seq, models.ProductionEntry.entry_date
    ).all()


@router.get("/next-operation-default")
def get_next_operation_default(
    route_card_id: int,
    operation_seq: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Convenience endpoint the frontend calls when opening the entry form for
    `operation_seq`, to pre-fill qty_planned in the UI before the user even
    submits anything (FR-3.3).
    """
    return {"suggested_qty_planned": _get_previous_operation_total(db, route_card_id, operation_seq)}
