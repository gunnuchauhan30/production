"""
Seed script — runs automatically on container start (see docker-compose.yml).
Idempotent: safe to run every time the container restarts, it only creates
rows that don't already exist. Gives you a working login and enough master
data to actually test Route Card entry -> production entry end to end.
"""
import time
from sqlalchemy.exc import OperationalError

from app.database import SessionLocal, engine
from app.models import PpeUser, PpeRole, Machine, PartRouting, RejectionReason, DownTimeReason
from app.auth import hash_password


def wait_for_db(retries: int = 20, delay: float = 1.5):
    for attempt in range(retries):
        try:
            with engine.connect():
                return
        except OperationalError:
            print(f"[seed] Waiting for database... ({attempt + 1}/{retries})")
            time.sleep(delay)
    raise RuntimeError("Database never became available")


def seed():
    wait_for_db()
    db = SessionLocal()
    try:
        first_boot = db.query(PpeUser).count() == 0
        if not db.query(PpeUser).filter(PpeUser.username == "admin").first():
            db.add(PpeUser(
                username="admin",
                password_hash=hash_password("admin123"),
                full_name="Administrator",
                role=PpeRole.admin,
            ))
            print("[seed] Created user: admin / admin123  (CHANGE THIS PASSWORD)")

        if not db.query(PpeUser).filter(PpeUser.username == "operator1").first():
            db.add(PpeUser(
                username="operator1",
                password_hash=hash_password("operator123"),
                full_name="Shop Floor Operator",
                role=PpeRole.operation,
            ))
            print("[seed] Created user: operator1 / operator123")

        if not db.query(PpeUser).filter(PpeUser.username == "qa1").first():
            db.add(PpeUser(
                username="qa1",
                password_hash=hash_password("qa123"),
                full_name="QA Inspector",
                role=PpeRole.qa,
            ))
            print("[seed] Created user: qa1 / qa123")

        db.commit()

        # Sample master data for the Handle Bar part used throughout the SRS/OEE sheet.
        if not db.query(Machine).filter(Machine.machine_no == "M-05").first():
            db.add_all([
                Machine(machine_no="KM01", machine_name="Knurling Machine 1", department="Knurling"),
                Machine(machine_no="BM01", machine_name="Bending Machine 1", department="Bending"),
                Machine(machine_no="DM01", machine_name="Drilling Machine 1", department="Drilling"),
                Machine(machine_no="M-05", machine_name="Welding Machine 5", department="Welding"),
            ])
            print("[seed] Created sample machines")

        if not db.query(PartRouting).filter(PartRouting.part_number == "HB-349C").first():
            db.add_all([
                PartRouting(part_number="HB-349C", operation_name="Knurling + Stamping", operation_seq=1),
                PartRouting(part_number="HB-349C", operation_name="Bending", operation_seq=2),
                PartRouting(part_number="HB-349C", operation_name="Drilling", operation_seq=3),
                PartRouting(part_number="HB-349C", operation_name="Welding", operation_seq=4),
            ])
            print("[seed] Created sample part routing for HB-349C")

        if not db.query(RejectionReason).first():
            db.add_all([
                RejectionReason(reason="Dimensional out of tolerance", category="Dimensional"),
                RejectionReason(reason="Surface scratch", category="Surface"),
                RejectionReason(reason="Material defect", category="Material"),
            ])
            print("[seed] Created sample rejection reasons")

        if not db.query(DownTimeReason).first():
            db.add_all([
                DownTimeReason(reason="Machine breakdown"),
                DownTimeReason(reason="Material shortage"),
                DownTimeReason(reason="Shift changeover"),
            ])
            print("[seed] Created sample down-time reasons")

        db.commit()
        print("[seed] Done.")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
