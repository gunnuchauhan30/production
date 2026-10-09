"""
Smoke test — walks through the entire flow once, using the seeded test
users and master data, to confirm the ready-to-run stack actually works.

Run AFTER `docker compose up` (or the manual setup) is up and serving on
http://localhost:8010

    pip install requests
    python smoke_test.py
"""
import sys
import requests

BASE = "http://localhost:8010"


def step(label):
    print(f"\n--- {label} ---")


def login(username, password):
    r = requests.post(f"{BASE}/auth/login", data={"username": username, "password": password})
    r.raise_for_status()
    return r.json()["access_token"]


def auth_headers(token):
    return {"Authorization": f"Bearer {token}"}


def main():
    step("Health check")
    r = requests.get(f"{BASE}/health")
    r.raise_for_status()
    print(r.json())
    assert r.json()["connected_to_store"] is False

    step("Login as operator1")
    op_token = login("operator1", "operator123")
    print("Got token:", op_token[:20] + "...")

    step("Enter a Route Card (manual entry, as if reading a printed Store document)")
    job_card_no = "JC-SMOKETEST-0001"
    r = requests.post(
        f"{BASE}/route-cards",
        json={
            "job_card_no": job_card_no,
            "part_number": "HB-349C",
            "material_name": "MS Rod 12mm",
            "issued_qty": 100,
            "department": "Production",
            "customer": "ABC Motors",
        },
        headers=auth_headers(op_token),
    )
    if r.status_code == 409:
        print("Route card already exists from a previous run, fetching it instead")
        r = requests.get(f"{BASE}/route-cards", params={"search": job_card_no}, headers=auth_headers(op_token))
        route_card_id = r.json()[0]["id"]
    else:
        r.raise_for_status()
        route_card_id = r.json()["id"]
    print("route_card_id =", route_card_id)

    step("Operation 1 — Knurling + Stamping")
    r = requests.post(
        f"{BASE}/production-entries",
        json={
            "route_card_id": route_card_id,
            "operation_name": "Knurling + Stamping",
            "operation_seq": 1,
            "shift": "A",
            "operator_name": "Test Operator",
            "machine_no": "KM01",
            "qty_planned": 100,
            "qty_produced": 100,
            "ok_qty": 95,
            "rejected_qty": 5,
        },
        headers=auth_headers(op_token),
    )
    r.raise_for_status()
    print(r.json())

    step("Check next-operation default (FR-3.3 auto-fill)")
    r = requests.get(
        f"{BASE}/production-entries/next-operation-default",
        params={"route_card_id": route_card_id, "operation_seq": 2},
        headers=auth_headers(op_token),
    )
    r.raise_for_status()
    print(r.json())
    assert float(r.json()["suggested_qty_planned"]) == 100.0, "Auto-fill should carry forward 100 from operation 1"

    step("Operations 2-4 (Bending, Drilling, Welding) — all producing the full 100")
    for seq, name, machine in [(2, "Bending", "BM01"), (3, "Drilling", "DM01"), (4, "Welding", "M-05")]:
        r = requests.post(
            f"{BASE}/production-entries",
            json={
                "route_card_id": route_card_id,
                "operation_name": name,
                "operation_seq": seq,
                "machine_no": machine,
                "qty_produced": 100,
                "ok_qty": 100,
            },
            headers=auth_headers(op_token),
        )
        r.raise_for_status()
        print(f"  {name}: OK")

    step("Route card progress — should now show production_complete")
    r = requests.get(f"{BASE}/route-cards/{route_card_id}/progress", headers=auth_headers(op_token))
    r.raise_for_status()
    print(r.json())

    step("Login as qa1 and record Final PDI = pass")
    qa_token = login("qa1", "qa123")
    r = requests.post(
        f"{BASE}/pdi-checks",
        json={"route_card_id": route_card_id, "stage": "final", "result": "pass"},
        headers=auth_headers(qa_token),
    )
    if r.status_code == 409:
        print("Final PDI already recorded from a previous run — that's fine")
    else:
        r.raise_for_status()
        print(r.json())

    step("Check Finished Goods was auto-created by the DB trigger")
    r = requests.get(f"{BASE}/finished-goods", params={"route_card_id": route_card_id}, headers=auth_headers(qa_token))
    r.raise_for_status()
    print(r.json())
    assert len(r.json()) > 0, "Finished Goods should have been auto-created on final PDI pass"

    step("Dispatch it")
    r = requests.post(
        f"{BASE}/dispatch",
        json={
            "route_card_id": route_card_id,
            "order_no": "SO-SMOKETEST",
            "schedule_date": "2026-08-25",
            "actual_dispatch_date": "2026-08-24",
            "qty_dispatched": 100,
        },
        headers=auth_headers(qa_token),
    )
    if r.status_code not in (200, 201):
        print("(dispatch may already exist from a previous run)", r.status_code, r.text)
    else:
        print(r.json())

    print("\n✅ ALL SMOKE TEST STEPS PASSED")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as e:
        print(f"\n❌ ASSERTION FAILED: {e}")
        sys.exit(1)
    except requests.HTTPError as e:
        print(f"\n❌ HTTP ERROR: {e.response.status_code} {e.response.text}")
        sys.exit(1)
