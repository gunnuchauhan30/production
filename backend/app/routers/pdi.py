"""
PDI — FR-5.1a (in-process), FR-5.1b (final), FR-5.2 (block FG on fail).

The database trigger trg_pdi_to_fg automatically creates a finished_goods
row when a 'final' stage check is inserted with result='pass'. This
router does not need to duplicate that logic -- it only needs to insert
the check and let the trigger do its job (FR-6.1).
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user, require_role
from .. import models, schemas

router = APIRouter(prefix="/pdi-checks", tags=["pdi"])


@router.post("", response_model=schemas.PdiCheckOut, status_code=status.HTTP_201_CREATED)
def create_pdi_check(
    payload: schemas.PdiCheckCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    # FR-5.1b: only a QA/admin role can record a 'final' stage result.
    if payload.stage == models.PdiStage.final and current_user.role.value not in ("qa", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only QA can record a final-stage PDI result",
        )

    route_card = db.query(models.RouteCard).get(payload.route_card_id)
    if not route_card:
        raise HTTPException(status_code=404, detail="route_card_id does not exist")

    check = models.PdiCheck(
        route_card_id=payload.route_card_id,
        stage=payload.stage,
        result=payload.result,
        remarks=payload.remarks,
        inspector_id=current_user.id,
    )
    db.add(check)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A '{payload.stage.value}' PDI check already exists for this route card",
        )
    db.refresh(check)
    return check


@router.get("", response_model=List[schemas.PdiCheckOut])
def list_pdi_checks(route_card_id: int = None, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    query = db.query(models.PdiCheck)
    if route_card_id:
        query = query.filter(models.PdiCheck.route_card_id == route_card_id)
    return query.order_by(models.PdiCheck.checked_at.desc()).all()
