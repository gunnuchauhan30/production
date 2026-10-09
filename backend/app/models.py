"""
SQLAlchemy models — mirror ppe_module_schema_v2.0.sql exactly.
Generated columns (balance_qty, total_qty_produced, run_time_sec, oee,
delay_days) are declared server_default/computed via the DB itself; the
ORM only needs to read them back, never set them directly.
"""
from sqlalchemy import (
    Column, Integer, String, Numeric, Date, DateTime, Boolean, Text, Time,
    ForeignKey, UniqueConstraint, Enum, func, FetchedValue
)
from sqlalchemy.orm import relationship
from .database import Base
import enum

# All Python enums below map their DB value with values_callable, since
# SQLAlchemy's Enum() otherwise sends the member NAME to Postgres, not
# the member VALUE. This matters here specifically because PdiResult's
# 'pass' value can't be a Python identifier, so the member is named
# pass_ -- without values_callable, SQLAlchemy would insert the literal
# string "pass_" into the pdi_result_enum column and Postgres would
# reject it.
def _enum_values(enum_cls):
    return [e.value for e in enum_cls]


class PpeRole(str, enum.Enum):
    planning = "planning"
    operator = "operator"
    qa = "qa"
    dispatch = "dispatch"
    admin = "admin"


class ScheduleStatus(str, enum.Enum):
    pending = "pending"
    planned = "planned"
    issued = "issued"


class PdiStage(str, enum.Enum):
    in_process = "in_process"
    final = "final"


class PdiResult(str, enum.Enum):
    pass_ = "pass"
    fail = "fail"


class DispatchStatus(str, enum.Enum):
    pending = "pending"
    on_time = "on_time"
    delayed = "delayed"


class PpeUser(Base):
    __tablename__ = "ppe_users"

    id = Column(Integer, primary_key=True)
    username = Column(String(80), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(150))
    role = Column(Enum(PpeRole, name="ppe_role_enum", values_callable=_enum_values), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())


class RouteCard(Base):
    __tablename__ = "route_cards"

    id = Column(Integer, primary_key=True)
    job_card_no = Column(String(50), unique=True, nullable=False)
    part_number = Column(String(80), nullable=False)
    material_name = Column(String(120))
    issued_qty = Column(Numeric(12, 2), nullable=False)
    department = Column(String(80))
    customer = Column(String(120))
    entered_by = Column(Integer, ForeignKey("ppe_users.id"))
    entered_at = Column(DateTime, server_default=func.now())

    production_entries = relationship("ProductionEntry", back_populates="route_card")
    pdi_checks = relationship("PdiCheck", back_populates="route_card")
    finished_goods = relationship("FinishedGood", back_populates="route_card")
    dispatches = relationship("Dispatch", back_populates="route_card")


class CustomerSchedule(Base):
    __tablename__ = "customer_schedule"

    id = Column(Integer, primary_key=True)
    customer = Column(String(120), nullable=False)
    part_number = Column(String(80), nullable=False)
    qty = Column(Numeric(12, 2), nullable=False)
    required_date = Column(Date, nullable=False)
    status = Column(Enum(ScheduleStatus, name="schedule_status_enum", values_callable=_enum_values), default=ScheduleStatus.pending)
    created_by = Column(Integer, ForeignKey("ppe_users.id"))
    created_at = Column(DateTime, server_default=func.now())


class ProductionOeeEntry(Base):
    __tablename__ = "production_oee_entries"

    id = Column(Integer, primary_key=True)
    sr_no = Column(Integer)
    entry_date = Column(Date, nullable=False)
    line = Column(String(30), nullable=False, default="Fabrication Line")   # "Tube Line" or "Fabrication Line"
    shift = Column(String(10))
    operator_name = Column(String(150))
    machine_no = Column(String(30))
    operation_name = Column(String(100))
    part_name = Column(String(100))
    standard_cycle_time_sec = Column(Numeric(10, 2))
    ok_qty = Column(Numeric(12, 2), default=0)
    rejected_qty = Column(Numeric(12, 2), default=0)
    rejection_reason = Column(String(150))
    total_qty_produced = Column(Numeric(12, 2), server_default=FetchedValue())   # generated column, DB-computed
    total_time_min = Column(Numeric(10, 2))
    run_time_min = Column(Numeric(10, 2))
    run_time_sec = Column(Numeric(10, 2), server_default=FetchedValue())         # generated column, DB-computed
    down_time_min = Column(Numeric(10, 2), default=0)
    down_time_reason = Column(String(150))
    availability = Column(Numeric(6, 5))                  # trigger-computed
    performance = Column(Numeric(6, 5))                   # trigger-computed
    quality = Column(Numeric(6, 5))                        # trigger-computed
    oee = Column(Numeric(6, 5), server_default=FetchedValue())                     # generated column, DB-computed
    entry_by = Column(Integer, ForeignKey("ppe_users.id"))
    created_at = Column(DateTime, server_default=func.now())


class ProductionEntry(Base):
    __tablename__ = "production_entries"

    id = Column(Integer, primary_key=True)
    route_card_id = Column(Integer, ForeignKey("route_cards.id"), nullable=False)
    operation_name = Column(String(100), nullable=False)
    operation_seq = Column(Integer, nullable=False)
    entry_date = Column(Date, server_default=func.current_date())
    shift = Column(String(10))
    operator_name = Column(String(150))
    machine_no = Column(String(30))
    qty_planned = Column(Numeric(12, 2), nullable=False, default=0)
    qty_produced = Column(Numeric(12, 2), nullable=False, default=0)
    ok_qty = Column(Numeric(12, 2), nullable=False, default=0)
    rejected_qty = Column(Numeric(12, 2), nullable=False, default=0)
    rework_qty = Column(Numeric(12, 2), nullable=False, default=0)
    hold_qty = Column(Numeric(12, 2), nullable=False, default=0)
    balance_qty = Column(Numeric(12, 2), server_default=FetchedValue())   # generated column, DB-computed
    down_time_min = Column(Numeric(10, 2), default=0)
    down_time_reason = Column(String(150))
    remarks = Column(Text)
    entry_by = Column(Integer, ForeignKey("ppe_users.id"))
    created_at = Column(DateTime, server_default=func.now())

    route_card = relationship("RouteCard", back_populates="production_entries")


class PdiCheck(Base):
    __tablename__ = "pdi_checks"
    __table_args__ = (UniqueConstraint("route_card_id", "stage", name="uq_pdi_route_stage"),)

    id = Column(Integer, primary_key=True)
    route_card_id = Column(Integer, ForeignKey("route_cards.id"), nullable=False)
    stage = Column(Enum(PdiStage, name="pdi_stage_enum", values_callable=_enum_values), nullable=False)
    inspector_id = Column(Integer, ForeignKey("ppe_users.id"))
    result = Column(Enum(PdiResult, name="pdi_result_enum", values_callable=_enum_values), nullable=False)
    remarks = Column(Text)
    checked_at = Column(DateTime, server_default=func.now())

    route_card = relationship("RouteCard", back_populates="pdi_checks")


class FinishedGood(Base):
    __tablename__ = "finished_goods"

    id = Column(Integer, primary_key=True)
    route_card_id = Column(Integer, ForeignKey("route_cards.id"), nullable=False)
    fg_qty = Column(Numeric(12, 2), nullable=False)
    fg_date = Column(Date, server_default=func.current_date())
    warehouse = Column(String(50))
    created_at = Column(DateTime, server_default=func.now())

    route_card = relationship("RouteCard", back_populates="finished_goods")


class Dispatch(Base):
    __tablename__ = "dispatch"

    id = Column(Integer, primary_key=True)
    route_card_id = Column(Integer, ForeignKey("route_cards.id"), nullable=False)
    order_no = Column(String(50))
    schedule_date = Column(Date)
    actual_dispatch_date = Column(Date)
    qty_dispatched = Column(Numeric(12, 2))
    delay_days = Column(Integer, server_default=FetchedValue())                            # generated column, DB-computed
    status = Column(Enum(DispatchStatus, name="dispatch_status_enum", values_callable=_enum_values), default=DispatchStatus.pending)
    created_at = Column(DateTime, server_default=func.now())

    route_card = relationship("RouteCard", back_populates="dispatches")


class PartRouting(Base):
    __tablename__ = "part_routing"
    __table_args__ = (UniqueConstraint("part_number", "operation_seq", name="uq_part_seq"),)

    id = Column(Integer, primary_key=True)
    part_number = Column(String(80), nullable=False)
    operation_name = Column(String(100), nullable=False)
    operation_seq = Column(Integer, nullable=False)
    cycle_time_sec = Column(Numeric(10, 2))   # standard cycle time from department cycle-time sheet
    machine_no = Column(String(80))            # machine code(s) from cycle-time sheet, e.g. "DM-01,02,03"


class Machine(Base):
    __tablename__ = "machines"

    machine_no = Column(String(30), primary_key=True)
    machine_name = Column(String(100))
    department = Column(String(80))
    is_active = Column(Boolean, default=True)


class RejectionReason(Base):
    __tablename__ = "rejection_reasons"

    id = Column(Integer, primary_key=True)
    reason = Column(String(150), unique=True, nullable=False)
    category = Column(String(50))


class DownTimeReason(Base):
    __tablename__ = "down_time_reasons"

    id = Column(Integer, primary_key=True)
    reason = Column(String(150), unique=True, nullable=False)


# ---------- v2.1: Stock Checking + Shortage Highlight (manual) ----------
class StockMovementType(str, enum.Enum):
    in_ = "in"
    out = "out"


class StockItem(Base):
    __tablename__ = "stock_items"

    id = Column(Integer, primary_key=True)
    material_name = Column(String(120), unique=True, nullable=False)
    current_qty = Column(Numeric(12, 2), nullable=False, default=0)   # maintained by trigger, never set directly
    reorder_level = Column(Numeric(12, 2), nullable=False, default=0)
    updated_at = Column(DateTime, server_default=func.now())


class StockMovement(Base):
    __tablename__ = "stock_movements"

    id = Column(Integer, primary_key=True)
    material_name = Column(String(120), nullable=False)
    movement_type = Column(Enum(StockMovementType, name="stock_movement_type", values_callable=_enum_values), nullable=False)
    qty = Column(Numeric(12, 2), nullable=False)
    reason = Column(String(150))
    entry_by = Column(Integer, ForeignKey("ppe_users.id"))
    entry_date = Column(Date, server_default=func.current_date())
    created_at = Column(DateTime, server_default=func.now())


# ---------- v2.2: Press Shop daily strokes / reports ----------
class PressStockEntry(Base):
    __tablename__ = "press_stock_entries"

    id = Column(Integer, primary_key=True)
    entry_date = Column(Date, nullable=False)
    shift = Column(String(10))
    operator_name = Column(String(150))
    machine_no = Column(String(30))          # e.g. PP-03
    tonnage = Column(Numeric(10, 2))
    strokes = Column(Numeric(12, 2), default=0)
    strokes_rate = Column(Numeric(10, 4))
    calculation = Column(Numeric(12, 2), server_default=FetchedValue())   # generated column, DB-computed
    remarks = Column(String(200))
    entry_by = Column(Integer, ForeignKey("ppe_users.id"))
    created_at = Column(DateTime, server_default=func.now())


# ---------- v2.6: Parts (friendly display name for a part number) ----------
class Part(Base):
    __tablename__ = "parts"

    part_number = Column(String(80), primary_key=True)
    part_name = Column(String(150))                      # e.g. "Handle Bar" -> shown as "Handle Bar J1A"
    customer_name = Column(String(200))                   # e.g. "UNO MINDA, VARROC"


# ---------- v2.5: BOM Items + per-item Operations (reference/browse structure) ----------
class BomItem(Base):
    __tablename__ = "bom_items"

    id = Column(Integer, primary_key=True)
    part_number = Column(String(80), nullable=False)
    item_name = Column(String(100), nullable=False)     # e.g. "RM", "Long Bush"
    spec = Column(String(150))                            # e.g. "22.2 X 2.0 X 891 MM"
    item_seq = Column(Integer, nullable=False, default=1)


class BomOperation(Base):
    __tablename__ = "bom_operations"

    id = Column(Integer, primary_key=True)
    bom_item_id = Column(Integer, ForeignKey("bom_items.id", ondelete="CASCADE"), nullable=False)
    operation_seq = Column(Integer, nullable=False)
    operation_name = Column(String(100), nullable=False)
    cycle_time_sec = Column(Numeric(10, 2))
    machine_no = Column(String(80))


# ---------- v2.7: Production Log (simple shop-floor entry, no route card) ----------
class ProductionLogEntry(Base):
    __tablename__ = "production_log_entries"

    id              = Column(Integer, primary_key=True)
    line            = Column(String(30), nullable=False)     # "Tube" | "Fabrication" | "Press Shop"
    part_number     = Column(String(80), nullable=False)
    bom_item_name   = Column(String(100))   # which BOM item (e.g. "Tube", "Housing Pipe") -- disambiguates
                                             # operation names that repeat across a part's items
    entry_date      = Column(Date, nullable=False)
    shift           = Column(String(10))
    machine_no      = Column(String(30))
    machine_name    = Column(String(100))
    operation_name  = Column(String(100), nullable=False)
    operator_name   = Column(String(150))
    start_time      = Column(Time)
    end_time        = Column(Time)
    planned_qty     = Column(Numeric(12, 2))
    produced_qty    = Column(Numeric(12, 2))
    ok_qty          = Column(Numeric(12, 2))
    ng_qty          = Column(Numeric(12, 2))
    rejection_reason = Column(String(150))

    # ---- OEE inputs/outputs ----
    # standard_cycle_time_sec: looked up from Master Data BOM.
    # total_time_min / down_time_min: entered directly (same as the paper/Excel
    # OEE sheet) -- start_time/end_time above are no longer used for this.
    # run_time_min / availability / performance / quality / oee: computed from
    # the above at save time.
    standard_cycle_time_sec = Column(Numeric(10, 2))
    extra_down_time_min     = Column(Numeric(10, 2))   # manual "Unplanned Breakdown" minutes, entered on the form
    down_time_reason        = Column(String(150))
    total_time_min          = Column(Numeric(10, 2))
    planned_down_time_min   = Column(Numeric(10, 2))   # auto: overlap with the fixed daily breaks
    down_time_min           = Column(Numeric(10, 2))
    run_time_min            = Column(Numeric(10, 2))   # total - down
    availability            = Column(Numeric(6, 5))
    performance             = Column(Numeric(6, 5))
    quality                 = Column(Numeric(6, 5))
    oee                     = Column(Numeric(6, 5))

    entry_by        = Column(Integer, ForeignKey("ppe_users.id"))
    created_at      = Column(DateTime, server_default=func.now())

