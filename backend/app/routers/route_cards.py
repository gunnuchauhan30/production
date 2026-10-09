"""
Route Card entry — FR-2.1 to FR-2.3.

This is the manual entry point (v2.0 architecture): a user reads the
printed Route Card that Store already generates, and types its header
fields in here ONCE. There is no call out to Store from this router.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user
from .. import models, schemas

router = APIRouter(prefix="/route-cards", tags=["route-cards"])


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
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    query = db.query(models.RouteCard)
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
