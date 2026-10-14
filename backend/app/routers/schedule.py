"""Planning module - FR-1.1, FR-1.2.

Customer schedules are planned per MONTH: `required_date` always holds the 1st
of the planned month (whatever day the client sends).

Holidays: every Sunday is a holiday automatically (the frontend works that
out). This module stores only the EXTRA holidays an admin / planner marks on
the calendar, e.g. 2 Oct. The `holidays` table is created on first use, so no
manual SQL is needed on any deployment.
"""
from datetime import date
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict
from sqlalchemy import Column, Date, DateTime, Integer, String, func, inspect
from sqlalchemy.orm import Session

from ..database import Base, get_db
from ..auth import get_current_user, require_role
from .. import models, schemas

router = APIRouter(prefix="/customer-schedule", tags=["planning"])


class Holiday(Base):
    __tablename__ = "holidays"

    id = Column(Integer, primary_key=True)
    holiday_date = Column(Date, nullable=False, unique=True)
    name = Column(String(120))
    created_by = Column(Integer)  # plain id, no FK, so this table stays independent
    created_at = Column(DateTime, server_default=func.now())


_holidays_ready = False


def _ensure_holidays_table(db: Session) -> None:
    """Create the holidays table the first time it is needed."""
    global _holidays_ready
    if _holidays_ready:
        return
    bind = db.get_bind()
    try:
        Holiday.__table__.create(bind=bind, checkfirst=True)
    except Exception:
        # Two first requests at once can race; fine as long as the table now exists.
        if not inspect(bind).has_table("holidays"):
            raise
    _holidays_ready = True


class HolidayIn(BaseModel):
    holiday_date: date
    name: Optional[str] = None


class HolidayOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    holiday_date: date
    name: Optional[str] = None


def _month_range(month: str):
    try:
        year, mon = (int(x) for x in month.split("-"))
        start = date(year, mon, 1)
    except (ValueError, TypeError):
        raise HTTPException(422, "month must look like 2026-10")
    end = date(year + 1, 1, 1) if mon == 12 else date(year, mon + 1, 1)
    return start, end


# ---------------------------------------------------------------- schedules
@router.post("", response_model=schemas.ScheduleOut, status_code=201)
def create_schedule(payload: schemas.ScheduleCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    data = payload.model_dump()
    data["customer"] = data["customer"].strip()
    data["part_number"] = data["part_number"].strip()
    if not data["customer"] or not data["part_number"]:
        raise HTTPException(400, "Customer and part are required")
    if data["qty"] <= 0:
        raise HTTPException(400, "Qty must be more than 0")
    data["required_date"] = data["required_date"].replace(day=1)  # planned per month
    row = models.CustomerSchedule(**data, created_by=current_user.id)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.get("", response_model=List[schemas.ScheduleOut])
def list_schedules(status_filter: Optional[str] = None, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    query = db.query(models.CustomerSchedule)
    if status_filter:
        query = query.filter(models.CustomerSchedule.status == status_filter)
    return query.order_by(models.CustomerSchedule.required_date, models.CustomerSchedule.id).all()


# ----------------------------------------------------------------- holidays
@router.get("/holidays", response_model=List[HolidayOut])
def list_holidays(month: Optional[str] = None, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    _ensure_holidays_table(db)
    query = db.query(Holiday)
    if month:
        start, end = _month_range(month)
        query = query.filter(Holiday.holiday_date >= start, Holiday.holiday_date < end)
    return query.order_by(Holiday.holiday_date).all()


@router.post("/holidays", response_model=HolidayOut)
def add_holiday(payload: HolidayIn, db: Session = Depends(get_db), user=Depends(require_role("admin", "planning"))):
    _ensure_holidays_table(db)
    if payload.holiday_date.weekday() == 6:
        raise HTTPException(400, "Sunday is already a holiday")
    name = (payload.name or "").strip() or None
    row = db.query(Holiday).filter(Holiday.holiday_date == payload.holiday_date).first()
    if row:
        row.name = name
    else:
        row = Holiday(holiday_date=payload.holiday_date, name=name, created_by=user.id)
        db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.delete("/holidays/{holiday_date}", status_code=204)
def remove_holiday(holiday_date: date, db: Session = Depends(get_db), user=Depends(require_role("admin", "planning"))):
    _ensure_holidays_table(db)
    row = db.query(Holiday).filter(Holiday.holiday_date == holiday_date).first()
    if not row:
        raise HTTPException(404, "That date is not marked as a holiday")
    db.delete(row)
    db.commit()
    return None
