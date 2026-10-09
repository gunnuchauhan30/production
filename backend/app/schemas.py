"""Pydantic schemas — request/response shapes for the API."""
from datetime import date, datetime, time
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, ConfigDict
from .models import PpeRole, ScheduleStatus, PdiStage, PdiResult, DispatchStatus


# ---------- Auth ----------
class LoginRequest(BaseModel):
    username: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    username: str
    full_name: Optional[str] = None
    role: PpeRole
    is_active: bool


class UserCreate(BaseModel):
    username: str
    password: str
    full_name: Optional[str] = None
    role: PpeRole


# ---------- Route Card ----------
class RouteCardCreate(BaseModel):
    job_card_no: str
    part_number: str
    material_name: Optional[str] = None
    issued_qty: Decimal
    department: Optional[str] = None
    customer: Optional[str] = None


class RouteCardOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    job_card_no: str
    part_number: str
    material_name: Optional[str]
    issued_qty: Decimal
    department: Optional[str]
    customer: Optional[str]
    entered_at: datetime


class RouteCardProgress(BaseModel):
    route_card: RouteCardOut
    total_produced_last_op: Decimal = Decimal("0")
    last_operation_name: Optional[str] = None
    production_complete: bool = False


# ---------- Customer schedule ----------
class ScheduleCreate(BaseModel):
    customer: str
    part_number: str
    qty: Decimal
    required_date: date


class ScheduleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    customer: str
    part_number: str
    qty: Decimal
    required_date: date
    status: ScheduleStatus


# ---------- Daily OEE entry ----------
class OeeEntryCreate(BaseModel):
    sr_no: Optional[int] = None
    entry_date: date
    line: str = "Fabrication Line"   # "Tube Line" or "Fabrication Line"
    shift: Optional[str] = None
    operator_name: Optional[str] = None
    machine_no: Optional[str] = None
    operation_name: Optional[str] = None
    part_name: Optional[str] = None
    standard_cycle_time_sec: Optional[Decimal] = None
    ok_qty: Decimal = Decimal("0")
    rejected_qty: Decimal = Decimal("0")
    rejection_reason: Optional[str] = None
    total_time_min: Optional[Decimal] = None
    run_time_min: Optional[Decimal] = None
    down_time_min: Decimal = Decimal("0")
    down_time_reason: Optional[str] = None


class OeeEntryOut(OeeEntryCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int
    total_qty_produced: Optional[Decimal] = None
    availability: Optional[Decimal] = None
    performance: Optional[Decimal] = None
    quality: Optional[Decimal] = None
    oee: Optional[Decimal] = None


# ---------- Production entry ----------
class ProductionEntryCreate(BaseModel):
    route_card_id: int
    operation_name: str
    operation_seq: int
    shift: Optional[str] = None
    operator_name: Optional[str] = None
    machine_no: Optional[str] = None
    qty_planned: Optional[Decimal] = None   # if omitted, auto-filled from previous operation (FR-3.3)
    qty_produced: Decimal = Decimal("0")
    ok_qty: Decimal = Decimal("0")
    rejected_qty: Decimal = Decimal("0")
    rework_qty: Decimal = Decimal("0")
    hold_qty: Decimal = Decimal("0")
    down_time_min: Decimal = Decimal("0")
    down_time_reason: Optional[str] = None
    remarks: Optional[str] = None


class ProductionEntryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    route_card_id: int
    operation_name: str
    operation_seq: int
    entry_date: date
    shift: Optional[str]
    operator_name: Optional[str]
    machine_no: Optional[str]
    qty_planned: Decimal
    qty_produced: Decimal
    ok_qty: Decimal
    rejected_qty: Decimal
    rework_qty: Decimal
    hold_qty: Decimal
    balance_qty: Optional[Decimal]


# ---------- PDI ----------
class PdiCheckCreate(BaseModel):
    route_card_id: int
    stage: PdiStage
    result: PdiResult
    remarks: Optional[str] = None


class PdiCheckOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    route_card_id: int
    stage: PdiStage
    result: PdiResult
    remarks: Optional[str]
    checked_at: datetime


# ---------- Finished goods ----------
class FinishedGoodOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    route_card_id: int
    fg_qty: Decimal
    fg_date: date
    warehouse: Optional[str]


# ---------- Dispatch ----------
class DispatchCreate(BaseModel):
    route_card_id: int
    order_no: Optional[str] = None
    schedule_date: Optional[date] = None
    actual_dispatch_date: Optional[date] = None
    qty_dispatched: Optional[Decimal] = None


class DispatchOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    route_card_id: int
    order_no: Optional[str]
    schedule_date: Optional[date]
    actual_dispatch_date: Optional[date]
    qty_dispatched: Optional[Decimal]
    delay_days: Optional[int]
    status: DispatchStatus


# ---------- Master data ----------
class PartRoutingCreate(BaseModel):
    part_number: str
    operation_name: str
    operation_seq: int
    cycle_time_sec: Optional[Decimal] = None
    machine_no: Optional[str] = None


class PartRoutingOut(PartRoutingCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int


class MachineCreate(BaseModel):
    machine_no: str
    machine_name: Optional[str] = None
    department: Optional[str] = None


class MachineOut(MachineCreate):
    model_config = ConfigDict(from_attributes=True)
    is_active: bool


class ReasonCreate(BaseModel):
    reason: str
    category: Optional[str] = None


class ReasonOut(ReasonCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int


# ---------- v2.1: Stock Checking + Shortage Highlight ----------
class StockMovementCreate(BaseModel):
    material_name: str
    movement_type: str  # "in" or "out"
    qty: Decimal
    reason: Optional[str] = None


class StockMovementOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    material_name: str
    movement_type: str
    qty: Decimal
    reason: Optional[str]
    entry_date: date
    created_at: datetime


class StockItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    material_name: str
    current_qty: Decimal
    reorder_level: Decimal
    updated_at: datetime


class StockReorderLevelSet(BaseModel):
    material_name: str
    reorder_level: Decimal


class StockShortageOut(BaseModel):
    material_name: str
    current_qty: Decimal
    reorder_level: Decimal
    short_by: Decimal


# ---------- v2.2: Press Shop daily strokes ----------
class PressStockEntryCreate(BaseModel):
    entry_date: date
    shift: Optional[str] = None
    operator_name: Optional[str] = None
    machine_no: Optional[str] = None
    tonnage: Optional[Decimal] = None
    strokes: Decimal = Decimal("0")
    strokes_rate: Optional[Decimal] = None
    remarks: Optional[str] = None


class PressStockEntryOut(PressStockEntryCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int
    calculation: Optional[Decimal] = None
    created_at: datetime


# ---------- Reports (v2.2) ----------
class OeeLineSummaryRow(BaseModel):
    operator_name: Optional[str] = None
    machine_no: Optional[str] = None
    entries_count: int = 0
    total_ok_qty: Decimal = Decimal("0")
    total_rejected_qty: Decimal = Decimal("0")
    avg_availability: Optional[Decimal] = None
    avg_performance: Optional[Decimal] = None
    avg_quality: Optional[Decimal] = None
    avg_oee: Optional[Decimal] = None


class ProductionSummaryRow(BaseModel):
    entry_date: date
    part_number: Optional[str] = None
    operation_name: Optional[str] = None
    qty_produced: Decimal = Decimal("0")
    ok_qty: Decimal = Decimal("0")
    rejected_qty: Decimal = Decimal("0")
    rework_qty: Decimal = Decimal("0")


class PressStockSummaryRow(BaseModel):
    machine_no: Optional[str] = None
    operator_name: Optional[str] = None
    entries_count: int = 0
    total_strokes: Decimal = Decimal("0")
    total_calculation: Decimal = Decimal("0")


class ReportsSummary(BaseModel):
    date_from: Optional[date] = None
    date_to: Optional[date] = None
    oee_tube_line: list[OeeLineSummaryRow] = []
    oee_fabrication_line: list[OeeLineSummaryRow] = []
    production: list[ProductionSummaryRow] = []
    press_stock: list[PressStockSummaryRow] = []


# ---------- v2.6: Parts (friendly display name for a part number) ----------
class PartCreate(BaseModel):
    part_number: str
    part_name: Optional[str] = None
    customer_name: Optional[str] = None


class PartOut(PartCreate):
    model_config = ConfigDict(from_attributes=True)


# ---------- v2.5: BOM Items + per-item Operations ----------
class BomOperationCreate(BaseModel):
    operation_seq: int
    operation_name: str
    cycle_time_sec: Optional[Decimal] = None
    machine_no: Optional[str] = None


class BomOperationOut(BomOperationCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int
    bom_item_id: int


class BomItemCreate(BaseModel):
    part_number: str
    item_name: str
    spec: Optional[str] = None
    item_seq: int = 1


class BomItemUpdate(BaseModel):
    item_name: Optional[str] = None
    spec: Optional[str] = None
    item_seq: Optional[int] = None


class BomItemOut(BomItemCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int


# ---------- v2.7: Production Log (simple shop-floor entry, no route card) ----------
class ProductionLogEntryCreate(BaseModel):
    line: str                       # "Tube" | "Fabrication" | "Press Shop"
    part_number: str
    bom_item_name: Optional[str] = None   # which BOM item (Tube, Housing Pipe, etc.)
    entry_date: date
    shift: Optional[str] = None
    machine_no: Optional[str] = None
    operation_name: str
    operator_name: Optional[str] = None
    start_time: Optional[time] = None    # drives Total Time + automatic Down Time
    end_time: Optional[time] = None
    planned_qty: Optional[Decimal] = None
    produced_qty: Optional[Decimal] = None
    ok_qty: Optional[Decimal] = None
    ng_qty: Optional[Decimal] = None
    rejection_reason: Optional[str] = None
    unplanned_down_time_min: Optional[Decimal] = None  # extra, on top of the automatic fixed breaks
    down_time_reason: Optional[str] = None


class ProductionLogEntryOut(ProductionLogEntryCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime
    standard_cycle_time_sec: Optional[Decimal] = None
    total_time_min: Optional[Decimal] = None
    planned_down_time_min: Optional[Decimal] = None
    down_time_min: Optional[Decimal] = None
    run_time_min: Optional[Decimal] = None
    availability: Optional[Decimal] = None
    performance: Optional[Decimal] = None
    quality: Optional[Decimal] = None
    oee: Optional[Decimal] = None
