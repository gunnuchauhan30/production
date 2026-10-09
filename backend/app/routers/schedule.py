"""Planning module — FR-1.1, FR-1.2."""
from typing import List, Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user
from .. import models, schemas

router = APIRouter(prefix="/customer-schedule", tags=["planning"])


@router.post("", response_model=schemas.ScheduleOut, status_code=201)
def create_schedule(payload: schemas.ScheduleCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    row = models.CustomerSchedule(**payload.model_dump(), created_by=current_user.id)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.get("", response_model=List[schemas.ScheduleOut])
def list_schedules(status_filter: Optional[str] = None, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    query = db.query(models.CustomerSchedule)
    if status_filter:
        query = query.filter(models.CustomerSchedule.status == status_filter)
    return query.order_by(models.CustomerSchedule.required_date).all()
