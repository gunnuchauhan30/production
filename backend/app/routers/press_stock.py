"""Press Shop — daily strokes / stock log (v2.2 addition)."""
from typing import List, Optional
from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user
from .. import models, schemas

router = APIRouter(prefix="/press-stock", tags=["press-stock"])


@router.post("", response_model=schemas.PressStockEntryOut, status_code=201)
def create_press_stock_entry(
    payload: schemas.PressStockEntryCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    entry = models.PressStockEntry(**payload.model_dump(), entry_by=current_user.id)
    db.add(entry)
    db.commit()
    db.refresh(entry)   # "calculation" is a DB-generated column, refresh pulls it back
    return entry


@router.get("", response_model=List[schemas.PressStockEntryOut])
def list_press_stock_entries(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    machine_no: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    query = db.query(models.PressStockEntry)
    if date_from:
        query = query.filter(models.PressStockEntry.entry_date >= date_from)
    if date_to:
        query = query.filter(models.PressStockEntry.entry_date <= date_to)
    if machine_no:
        query = query.filter(models.PressStockEntry.machine_no == machine_no)
    return query.order_by(models.PressStockEntry.entry_date.desc()).limit(500).all()
