"""
Stock Checking + Shortage Highlight — manual entry (v2.1 addition).

Restores the original process-flow steps "Stock Checking" and "Shortage
Highlight" that were dropped in v2.0 when PPE stopped reading Store's
live stock. Here, stock is kept up to date by a person logging receipts
and issues in PPE itself -- current_qty is never edited directly, it is
always derived from the stock_movements log (see the DB trigger).
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user
from .. import models, schemas

router = APIRouter(prefix="/stock", tags=["stock"])


@router.post("/movements", response_model=schemas.StockMovementOut, status_code=201)
def log_stock_movement(
    payload: schemas.StockMovementCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if payload.movement_type not in ("in", "out"):
        raise HTTPException(status_code=400, detail="movement_type must be 'in' or 'out'")

    movement = models.StockMovement(
        material_name=payload.material_name,
        movement_type=payload.movement_type,
        qty=payload.qty,
        reason=payload.reason,
        entry_by=current_user.id,
    )
    db.add(movement)
    db.commit()
    db.refresh(movement)   # the DB trigger updates stock_items in the same transaction
    return movement


@router.get("/movements", response_model=List[schemas.StockMovementOut])
def list_stock_movements(material_name: str = None, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    query = db.query(models.StockMovement)
    if material_name:
        query = query.filter(models.StockMovement.material_name == material_name)
    return query.order_by(models.StockMovement.created_at.desc()).limit(200).all()


@router.get("/items", response_model=List[schemas.StockItemOut])
def list_stock_items(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    """Current on-hand quantity for every material — the 'Stock Checking' view."""
    return db.query(models.StockItem).order_by(models.StockItem.material_name).all()


@router.put("/items/reorder-level", response_model=schemas.StockItemOut)
def set_reorder_level(
    payload: schemas.StockReorderLevelSet,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Set (or create) the reorder level for a material — drives the shortage view."""
    item = db.query(models.StockItem).filter(models.StockItem.material_name == payload.material_name).first()
    if item:
        item.reorder_level = payload.reorder_level
    else:
        item = models.StockItem(material_name=payload.material_name, reorder_level=payload.reorder_level, current_qty=0)
        db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/shortage", response_model=List[schemas.StockShortageOut])
def get_shortage_list(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    """
    The 'Shortage Highlight' step: every material currently below its
    reorder level. The Planning page checks this before finalizing a
    production plan against a customer_schedule row.
    """
    rows = db.execute(
        text("SELECT material_name, current_qty, reorder_level, short_by FROM v_stock_shortage ORDER BY short_by DESC")
    ).fetchall()
    return [
        schemas.StockShortageOut(
            material_name=r.material_name,
            current_qty=r.current_qty,
            reorder_level=r.reorder_level,
            short_by=r.short_by,
        )
        for r in rows
    ]
