"""
Comprehensive test — everything built so far, in one run:
  - auth (3 roles)
  - stock checking + shortage highlight (v2.1)
  - route card manual entry
  - 4-operation production flow with FR-3.3 auto-fill
  - PDI two-stage (in-process + final) -> auto Finished Goods trigger
  - dispatch with auto on_time/delayed status
  - customer schedule
  - master data (part routing, machines, reasons)
"""
import sys
import uuid
import requests

BASE = "http://localhost:8010"
PASS_COUNT = 0
FAIL_COUNT = 0


def check(label, condition):
    global PASS_COUNT, FAIL_COUNT
    if condition:
        PASS_COUNT += 1
        print(f"  ✅ {label}")
    else:
        FAIL_COUNT += 1
        print(f"  ❌ {label}")


def login(username, password):
    r = requests.post(f"{BASE}/auth/login", data={"username": username, "password": password})
    r.raise_for_status()
    return r.json()["access_token"]


def h(token):
    return {"Authorization": f"Bearer {token}"}


print("=" * 60)
print("1. HEALTH + AUTH")
print("=" * 60)
r = requests.get(f"{BASE}/health")
check("Health endpoint returns 200", r.status_code == 200)
check("connected_to_store is False", r.json().get("connected_to_store") is False)

admin_token = login("admin", "admin123")
op_token = login("operator1", "operator123")
qa_token = login("qa1", "qa123")
check("admin login works", bool(admin_token))
check("operator1 login works", bool(op_token))
check("qa1 login works", bool(qa_token))

r = requests.get(f"{BASE}/auth/me", headers=h(admin_token))
check("/auth/me returns correct role", r.json()["role"] == "admin")

print("\n" + "=" * 60)
print("2. MASTER DATA (already seeded)")
print("=" * 60)
r = requests.get(f"{BASE}/master-data/part-routing", params={"part_number": "HB-349C"}, headers=h(op_token))
routing = r.json()
check("HB-349C has 4 operations in routing", len(routing) == 4)
check("Routing is in correct sequence", [x["operation_seq"] for x in routing] == [1, 2, 3, 4])

r = requests.get(f"{BASE}/master-data/machines", headers=h(op_token))
check("Machines list non-empty", len(r.json()) > 0)

print("\n" + "=" * 60)
print("3. STOCK CHECKING + SHORTAGE HIGHLIGHT (v2.1)")
print("=" * 60)
material = f"Test Steel Rod {uuid.uuid4().hex[:6]}"

r = requests.post(f"{BASE}/stock/movements", json={
    "material_name": material, "movement_type": "in", "qty": 100, "reason": "test receipt"
}, headers=h(op_token))
check("Stock IN movement recorded", r.status_code == 201)

r = requests.post(f"{BASE}/stock/movements", json={
    "material_name": material, "movement_type": "out", "qty": 90, "reason": "test issue"
}, headers=h(op_token))
check("Stock OUT movement recorded", r.status_code == 201)

r = requests.get(f"{BASE}/stock/items", headers=h(op_token))
item = next((x for x in r.json() if x["material_name"] == material), None)
check("current_qty auto-computed correctly (100-90=10)", item is not None and float(item["current_qty"]) == 10.0)

r = requests.put(f"{BASE}/stock/items/reorder-level", json={"material_name": material, "reorder_level": 50}, headers=h(op_token))
check("Reorder level set", r.status_code == 200)

r = requests.get(f"{BASE}/stock/shortage", headers=h(op_token))
shortage_names = [x["material_name"] for x in r.json()]
check("Material appears in shortage list (10 < 50)", material in shortage_names)

print("\n" + "=" * 60)
print("4. CUSTOMER SCHEDULE (Planning)")
print("=" * 60)
r = requests.post(f"{BASE}/customer-schedule", json={
    "customer": "Test Motors", "part_number": "HB-349C", "qty": 500, "required_date": "2026-09-15"
}, headers=h(admin_token))
check("Customer schedule created", r.status_code == 201)
check("Default status is 'pending'", r.json()["status"] == "pending")

print("\n" + "=" * 60)
print("5. ROUTE CARD — MANUAL ENTRY")
print("=" * 60)
job_card_no = f"JC-TEST-{uuid.uuid4().hex[:8]}"
r = requests.post(f"{BASE}/route-cards", json={
    "job_card_no": job_card_no, "part_number": "HB-349C", "material_name": "MS Rod 12mm",
    "issued_qty": 100, "department": "Production", "customer": "Test Motors",
}, headers=h(op_token))
check("Route card created", r.status_code == 201)
route_card_id = r.json()["id"]

r = requests.post(f"{BASE}/route-cards", json={
    "job_card_no": job_card_no, "part_number": "HB-349C", "issued_qty": 100,
}, headers=h(op_token))
check("Duplicate job_card_no rejected (409)", r.status_code == 409)

print("\n" + "=" * 60)
print("6. PRODUCTION ENTRIES — FR-3.3 AUTO-FILL CHAIN")
print("=" * 60)
r = requests.post(f"{BASE}/production-entries", json={
    "route_card_id": route_card_id, "operation_name": "Knurling + Stamping", "operation_seq": 1,
    "machine_no": "KM01", "qty_planned": 100, "qty_produced": 100, "ok_qty": 95, "rejected_qty": 5,
}, headers=h(op_token))
check("Operation 1 entry created", r.status_code == 201)
check("Balance qty correct (100-100=0)", float(r.json()["balance_qty"]) == 0.0)

r = requests.get(f"{BASE}/production-entries/next-operation-default",
                  params={"route_card_id": route_card_id, "operation_seq": 2}, headers=h(op_token))
check("Auto-fill suggests 100 for operation 2", float(r.json()["suggested_qty_planned"]) == 100.0)

r = requests.post(f"{BASE}/production-entries", json={
    "route_card_id": route_card_id, "operation_name": "Bending", "operation_seq": 2,
    "machine_no": "BM01", "qty_produced": 100, "ok_qty": 100,
}, headers=h(op_token))
check("Operation 2 auto-filled qty_planned (not passed explicitly)", float(r.json()["qty_planned"]) == 100.0)

for seq, name, machine in [(3, "Drilling", "DM01"), (4, "Welding", "M-05")]:
    r = requests.post(f"{BASE}/production-entries", json={
        "route_card_id": route_card_id, "operation_name": name, "operation_seq": seq,
        "machine_no": machine, "qty_produced": 100, "ok_qty": 100,
    }, headers=h(op_token))
    check(f"Operation {seq} ({name}) created", r.status_code == 201)

r = requests.post(f"{BASE}/production-entries", json={
    "route_card_id": route_card_id, "operation_name": "Bad Operation", "operation_seq": 99,
    "qty_produced": 10,
}, headers=h(op_token))
check("FR-3.3a: unrouted operation_seq rejected (400)", r.status_code == 400)

r = requests.get(f"{BASE}/route-cards/{route_card_id}/progress", headers=h(op_token))
check("Route card shows production_complete = True", r.json()["production_complete"] is True)

print("\n" + "=" * 60)
print("7. PDI — TWO STAGES")
print("=" * 60)
r = requests.post(f"{BASE}/pdi-checks", json={
    "route_card_id": route_card_id, "stage": "in_process", "result": "pass"
}, headers=h(op_token))
check("In-process PDI recorded by operator", r.status_code == 201)

r = requests.post(f"{BASE}/pdi-checks", json={
    "route_card_id": route_card_id, "stage": "final", "result": "pass"
}, headers=h(op_token))
check("Operator BLOCKED from recording final PDI (403)", r.status_code == 403)

r = requests.post(f"{BASE}/pdi-checks", json={
    "route_card_id": route_card_id, "stage": "final", "result": "pass"
}, headers=h(qa_token))
check("QA can record final PDI", r.status_code == 201)

r = requests.post(f"{BASE}/pdi-checks", json={
    "route_card_id": route_card_id, "stage": "final", "result": "pass"
}, headers=h(qa_token))
check("Duplicate final-stage PDI rejected (409)", r.status_code == 409)

print("\n" + "=" * 60)
print("8. FINISHED GOODS — auto-created by DB trigger")
print("=" * 60)
r = requests.get(f"{BASE}/finished-goods", params={"route_card_id": route_card_id}, headers=h(qa_token))
check("Finished Goods row auto-created on final PDI pass", len(r.json()) == 1)
check("FG qty matches last operation total (100)", float(r.json()[0]["fg_qty"]) == 100.0)

print("\n" + "=" * 60)
print("9. DISPATCH")
print("=" * 60)
r = requests.post(f"{BASE}/dispatch", json={
    "route_card_id": route_card_id, "order_no": "SO-TEST-1",
    "schedule_date": "2026-08-25", "actual_dispatch_date": "2026-08-24", "qty_dispatched": 100,
}, headers=h(qa_token))
check("Dispatch created", r.status_code == 201)
check("Status auto-computed as on_time (dispatched early)", r.json()["status"] == "on_time")
check("delay_days auto-computed as -1", r.json()["delay_days"] == -1)

# A second route card with a LATE dispatch, to verify the 'delayed' branch too
job_card_no_2 = f"JC-TEST-{uuid.uuid4().hex[:8]}"
r = requests.post(f"{BASE}/route-cards", json={"job_card_no": job_card_no_2, "part_number": "HB-349C", "issued_qty": 10}, headers=h(op_token))
rc2 = r.json()["id"]
for seq, name in [(1, "Knurling + Stamping"), (2, "Bending"), (3, "Drilling"), (4, "Welding")]:
    requests.post(f"{BASE}/production-entries", json={
        "route_card_id": rc2, "operation_name": name, "operation_seq": seq, "qty_produced": 10, "ok_qty": 10,
    }, headers=h(op_token))
requests.post(f"{BASE}/pdi-checks", json={"route_card_id": rc2, "stage": "final", "result": "pass"}, headers=h(qa_token))
r = requests.post(f"{BASE}/dispatch", json={
    "route_card_id": rc2, "order_no": "SO-TEST-2",
    "schedule_date": "2026-08-20", "actual_dispatch_date": "2026-08-25", "qty_dispatched": 10,
}, headers=h(qa_token))
check("Late dispatch status auto-computed as delayed", r.json()["status"] == "delayed")
check("Late dispatch delay_days = 5", r.json()["delay_days"] == 5)

print("\n" + "=" * 60)
print(f"RESULT: {PASS_COUNT} passed, {FAIL_COUNT} failed")
print("=" * 60)

if FAIL_COUNT > 0:
    sys.exit(1)
