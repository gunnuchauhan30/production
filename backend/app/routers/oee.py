"""Daily OEE log — FR-4.1 to FR-4.3. Independent of route_card by design."""
from typing import List, Optional
from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user
from .. import models, schemas

router = APIRouter(prefix="/oee-entries", tags=["oee"])


@router.post("", response_model=schemas.OeeEntryOut, status_code=201)
def create_oee_entry(payload: schemas.OeeEntryCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    entry = models.ProductionOeeEntry(**payload.model_dump(), entry_by=current_user.id)
    db.add(entry)
    db.commit()
    db.refresh(entry)   # availability/performance/quality/oee are trigger-computed; refresh pulls them back
    return entry


@router.get("", response_model=List[schemas.OeeEntryOut])
def list_oee_entries(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    machine_no: Optional[str] = None,
    line: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    query = db.query(models.ProductionOeeEntry)
    if date_from:
        query = query.filter(models.ProductionOeeEntry.entry_date >= date_from)
    if date_to:
        query = query.filter(models.ProductionOeeEntry.entry_date <= date_to)
    if machine_no:
        query = query.filter(models.ProductionOeeEntry.machine_no == machine_no)
    if line:
        query = query.filter(models.ProductionOeeEntry.line == line)
    return query.order_by(models.ProductionOeeEntry.entry_date.desc()).limit(500).all()
