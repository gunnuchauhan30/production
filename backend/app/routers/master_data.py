"""Master data — part_routing, machines, rejection/down-time reasons. Admin-managed dropdowns."""
from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user, require_role
from .. import models, schemas

router = APIRouter(prefix="/master-data", tags=["master-data"])


@router.post("/part-routing", response_model=schemas.PartRoutingOut, status_code=201)
def add_part_routing(
    payload: schemas.PartRoutingCreate,
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin", "planning")),
):
    row = models.PartRouting(**payload.model_dump())
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.get("/part-routing", response_model=List[schemas.PartRoutingOut])
def list_part_routing(part_number: str = None, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    query = db.query(models.PartRouting)
    if part_number:
        query = query.filter(models.PartRouting.part_number == part_number)
    return query.order_by(models.PartRouting.part_number, models.PartRouting.operation_seq).all()


@router.post("/machines", response_model=schemas.MachineOut, status_code=201)
def add_machine(payload: schemas.MachineCreate, db: Session = Depends(get_db), current_user=Depends(require_role("admin"))):
    row = models.Machine(**payload.model_dump())
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.get("/machines", response_model=List[schemas.MachineOut])
def list_machines(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    return db.query(models.Machine).filter(models.Machine.is_active == True).all()  # noqa: E712


@router.post("/rejection-reasons", response_model=schemas.ReasonOut, status_code=201)
def add_rejection_reason(payload: schemas.ReasonCreate, db: Session = Depends(get_db), current_user=Depends(require_role("admin"))):
    row = models.RejectionReason(**payload.model_dump())
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.get("/rejection-reasons", response_model=List[schemas.ReasonOut])
def list_rejection_reasons(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    return db.query(models.RejectionReason).all()


@router.post("/down-time-reasons", response_model=schemas.ReasonOut, status_code=201)
def add_down_time_reason(payload: schemas.ReasonCreate, db: Session = Depends(get_db), current_user=Depends(require_role("admin"))):
    row = models.DownTimeReason(reason=payload.reason)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.get("/down-time-reasons", response_model=List[schemas.ReasonOut])
def list_down_time_reasons(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    return db.query(models.DownTimeReason).all()


# ---------- v2.6: Parts (friendly display name for a part number, e.g. J1A -> "Handle Bar") ----------
@router.get("/parts", response_model=List[schemas.PartOut])
def list_parts(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    return db.query(models.Part).all()


@router.post("/parts", response_model=schemas.PartOut, status_code=201)
def upsert_part(payload: schemas.PartCreate, db: Session = Depends(get_db), current_user=Depends(require_role("admin", "planning"))):
    row = db.query(models.Part).filter(models.Part.part_number == payload.part_number).first()
    data = payload.model_dump(exclude_unset=True, exclude={"part_number"})
    if row:
        for field, value in data.items():
            setattr(row, field, value)
    else:
        row = models.Part(**payload.model_dump())
        db.add(row)
    db.commit()
    db.refresh(row)
    return row


# ---------- v2.5: BOM Items + per-item Operations ----------
@router.get("/bom-items", response_model=List[schemas.BomItemOut])
def list_bom_items(part_number: str = None, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    query = db.query(models.BomItem)
    if part_number:
        query = query.filter(models.BomItem.part_number == part_number)
    return query.order_by(models.BomItem.part_number, models.BomItem.item_seq).all()


@router.post("/bom-items", response_model=schemas.BomItemOut, status_code=201)
def add_bom_item(payload: schemas.BomItemCreate, db: Session = Depends(get_db), current_user=Depends(require_role("admin", "planning"))):
    row = models.BomItem(**payload.model_dump())
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.patch("/bom-items/{bom_item_id}", response_model=schemas.BomItemOut)
def update_bom_item(
    bom_item_id: int,
    payload: schemas.BomItemUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin", "planning")),
):
    row = db.query(models.BomItem).filter(models.BomItem.id == bom_item_id).first()
    if not row:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="BOM item not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(row, field, value)
    db.commit()
    db.refresh(row)
    return row


@router.get("/bom-items/{bom_item_id}/operations", response_model=List[schemas.BomOperationOut])
def list_bom_operations(bom_item_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    return (
        db.query(models.BomOperation)
        .filter(models.BomOperation.bom_item_id == bom_item_id)
        .order_by(models.BomOperation.operation_seq)
        .all()
    )


@router.post("/bom-items/{bom_item_id}/operations", response_model=schemas.BomOperationOut, status_code=201)
def add_bom_operation(
    bom_item_id: int,
    payload: schemas.BomOperationCreate,
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin", "planning")),
):
    row = models.BomOperation(bom_item_id=bom_item_id, **payload.model_dump())
    db.add(row)
    db.commit()
    db.refresh(row)
    return row
