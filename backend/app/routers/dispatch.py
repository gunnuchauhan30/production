"""Finished Goods (read-only, auto-created by DB trigger) and Dispatch — FR-6.1 to FR-6.3."""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user
from .. import models, schemas

fg_router = APIRouter(prefix="/finished-goods", tags=["finished-goods"])
dispatch_router = APIRouter(prefix="/dispatch", tags=["dispatch"])


@fg_router.get("", response_model=List[schemas.FinishedGoodOut])
def list_finished_goods(route_card_id: Optional[int] = None, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    query = db.query(models.FinishedGood)
    if route_card_id:
        query = query.filter(models.FinishedGood.route_card_id == route_card_id)
    return query.order_by(models.FinishedGood.fg_date.desc()).all()


@dispatch_router.post("", response_model=schemas.DispatchOut, status_code=201)
def create_dispatch(payload: schemas.DispatchCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    route_card = db.query(models.RouteCard).get(payload.route_card_id)
    if not route_card:
        raise HTTPException(status_code=404, detail="route_card_id does not exist")

    # A route card can only be dispatched once it has a Finished Goods entry (final PDI passed).
    fg_exists = db.query(models.FinishedGood).filter(models.FinishedGood.route_card_id == payload.route_card_id).first()
    if not fg_exists:
        raise HTTPException(
            status_code=400,
            detail="This route card has no Finished Goods entry yet — final PDI must pass first",
        )

    dispatch = models.Dispatch(**payload.model_dump())
    db.add(dispatch)
    db.commit()
    db.refresh(dispatch)   # status/delay_days are DB-computed; refresh pulls them back
    return dispatch


@dispatch_router.get("", response_model=List[schemas.DispatchOut])
def list_dispatch(
    route_card_id: Optional[int] = None,
    status_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    query = db.query(models.Dispatch)
    if route_card_id:
        query = query.filter(models.Dispatch.route_card_id == route_card_id)
    if status_filter:
        query = query.filter(models.Dispatch.status == status_filter)
    return query.order_by(models.Dispatch.created_at.desc()).all()
