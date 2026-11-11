"""
Store -> PPC link, and the auto-filled Route Card.

What it does
  1. Pulls the Store's issues (a Store "Route Card" is an issue with a Job Card No) into a
     small local table, store_issues. Nothing in the Store is changed - read only.
     Accounts approval is NOT waited for; only issues the Store marked 'rejected' are left out.
  2. Production Logs entries that carry a Job Card No fill that card's operation table
     automatically (date, planned, produced, OK, rejected, operator).

Settings (Railway -> PPC backend service -> Variables)
  STORE_USERNAME   login of a Store user made only for this link (e.g. ppc_sync)
  STORE_PASSWORD   its password
  STORE_API_URL    optional, default https://store.chandaenterprises.in/api/v1

The Store login is rate limited (10 per minute), so a sync logs in once and syncs are at
most one every 15 seconds.
"""
import json
import os
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, text
from sqlalchemy.orm import Session

from ..database import engine, get_db
from ..auth import get_current_user
from .. import models

DEFAULT_STORE_API = "https://store.chandaenterprises.in/api/v1"
STALE_AFTER_SECONDS = 120      # a card list request re-syncs if the data is older than this
MIN_GAP_SECONDS = 15           # never hit the Store more often than this


def ensure_store_tables() -> None:
    """Creates the local copy of Store issues on first start. Safe to run every time."""
    if engine.dialect.name != "postgresql":
        return
    try:
        with engine.begin() as conn:
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS store_issues (
                    store_issue_id  INTEGER PRIMARY KEY,
                    job_card_no     VARCHAR(50),
                    issue_no        VARCHAR(50),
                    material_code   VARCHAR(50),
                    material_name   VARCHAR(255),
                    uom             VARCHAR(20),
                    lot_no          VARCHAR(100),
                    part_number     VARCHAR(100),
                    department      VARCHAR(100),
                    shift           VARCHAR(20),
                    issue_qty       NUMERIC(14,3),
                    consumed_qty    NUMERIC(14,3),
                    issue_date      DATE,
                    approval_status VARCHAR(20),
                    synced_at       TIMESTAMP DEFAULT now()
                )
            """))
            conn.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_store_issues_jc ON store_issues (upper(trim(job_card_no)))"
            ))
    except Exception as exc:  # never stop the app from starting
        print(f"[store_sync] could not create store_issues: {exc}")


router = APIRouter(prefix="/store", tags=["store"], on_startup=[ensure_store_tables])

_lock = threading.Lock()
_last_attempt = 0.0


# ---------------------------------------------------------------------------
# Talking to the Store
# ---------------------------------------------------------------------------
def _config():
    base = (os.getenv("STORE_API_URL") or DEFAULT_STORE_API).rstrip("/")
    return base, os.getenv("STORE_USERNAME"), os.getenv("STORE_PASSWORD")


def is_configured() -> bool:
    _, user, pwd = _config()
    return bool(user and pwd)


def _call(method: str, url: str, token: Optional[str] = None, form: Optional[dict] = None):
    data = urllib.parse.urlencode(form).encode() if form else None
    headers = {"Accept": "application/json", "User-Agent": "chanda-ppc-sync/1.0"}
    if form:
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    where = url.split("/api/v1")[-1] or url
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        if exc.code == 401 and where.endswith("/auth/login"):
            raise RuntimeError("Store login failed: check STORE_USERNAME and STORE_PASSWORD") from None
        raise RuntimeError(f"Store answered {exc.code} for {where}") from None
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Could not reach the Store: {exc.reason}") from None
    except (ValueError, json.JSONDecodeError):
        raise RuntimeError(f"Store sent something unreadable for {where}") from None


def _paged(base: str, path: str, token: str):
    rows = []
    for page in range(1, 41):
        chunk = _call("GET", f"{base}{path}?page={page}&page_size=500", token)
        if not isinstance(chunk, list):
            break
        rows.extend(chunk)
        if len(chunk) < 500:
            break
    return rows


_UPSERT = text("""
    INSERT INTO store_issues
        (store_issue_id, job_card_no, issue_no, material_code, material_name, uom, lot_no, part_number,
         department, shift, issue_qty, consumed_qty, issue_date, approval_status, synced_at)
    VALUES
        (:store_issue_id, :job_card_no, :issue_no, :material_code, :material_name, :uom, :lot_no, :part_number,
         :department, :shift, :issue_qty, :consumed_qty, :issue_date, :approval_status, now())
    ON CONFLICT (store_issue_id) DO UPDATE SET
        job_card_no = EXCLUDED.job_card_no, issue_no = EXCLUDED.issue_no,
        material_code = EXCLUDED.material_code, material_name = EXCLUDED.material_name,
        uom = EXCLUDED.uom, lot_no = EXCLUDED.lot_no, part_number = EXCLUDED.part_number,
        department = EXCLUDED.department, shift = EXCLUDED.shift, issue_qty = EXCLUDED.issue_qty,
        consumed_qty = EXCLUDED.consumed_qty, issue_date = EXCLUDED.issue_date,
        approval_status = EXCLUDED.approval_status, synced_at = now()
""")


def sync_from_store() -> int:
    """Reads every issue from the Store and saves/updates it here. Returns how many."""
    base, user, pwd = _config()
    if not (user and pwd):
        raise RuntimeError("Store connection is not set up (STORE_USERNAME / STORE_PASSWORD missing)")
    token = _call("POST", f"{base}/auth/login", form={"username": user, "password": pwd})["access_token"]
    try:  # the unit (KG / NOS) lives on the material; best effort
        uom = {m["material_code"]: m.get("uom") for m in _paged(base, "/materials", token)}
    except RuntimeError:
        uom = {}
    issues = _paged(base, "/issues", token)
    rows = []
    for i in issues:
        jc = (i.get("job_card_no") or "").strip() or None
        part = (i.get("part_number") or "").strip()
        rows.append({
            "store_issue_id": i["id"],
            "job_card_no": jc,
            "issue_no": i.get("issue_no"),
            "material_code": i.get("material_code"),
            "material_name": i.get("material_name"),
            "uom": uom.get(i.get("material_code")),
            "lot_no": i.get("lot_no"),
            "part_number": part if part and part != "-" else None,
            "department": i.get("department"),
            "shift": i.get("shift"),
            "issue_qty": i.get("issue_qty"),
            "consumed_qty": i.get("consumed_qty"),
            "issue_date": i.get("issue_date"),
            "approval_status": i.get("accounts_approval_status") or "pending",
        })
    if rows:
        with engine.begin() as conn:
            conn.execute(_UPSERT, rows)
    return len(rows)


def _seconds_since_sync(db: Session) -> float:
    return float(db.execute(text(
        "SELECT COALESCE(EXTRACT(EPOCH FROM (now() - max(synced_at))), 1000000000) FROM store_issues"
    )).scalar())


def _sync_if_stale(db: Session, force: bool = False) -> Optional[str]:
    """Returns an error message, or None when fine / nothing to do."""
    global _last_attempt
    if not is_configured():
        return None
    if not force and _seconds_since_sync(db) < STALE_AFTER_SECONDS:
        return None
    if time.time() - _last_attempt < MIN_GAP_SECONDS:
        return None
    if not _lock.acquire(blocking=False):
        return None
    try:
        _last_attempt = time.time()
        sync_from_store()
        return None
    except Exception as exc:
        return str(exc)
    finally:
        _lock.release()


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@router.post("/sync")
def sync_now(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if not is_configured():
        raise HTTPException(status_code=400, detail="Store connection is not set up yet. Add STORE_USERNAME and STORE_PASSWORD in Railway.")
    global _last_attempt
    if time.time() - _last_attempt < MIN_GAP_SECONDS:
        raise HTTPException(status_code=429, detail="Synced a moment ago. Try again in a few seconds.")
    if not _lock.acquire(blocking=False):
        raise HTTPException(status_code=429, detail="A sync is already running.")
    try:
        _last_attempt = time.time()
        count = sync_from_store()
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))
    finally:
        _lock.release()
    return {"synced_issues": count}


@router.get("/job-cards")
def list_job_cards(
    q: Optional[str] = None,
    limit: int = Query(300, ge=1, le=1000),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """One row per Job Card No (a card can have several Store issues), newest first."""
    sync_error = _sync_if_stale(db)
    last = db.execute(text("SELECT max(synced_at) FROM store_issues")).scalar()
    rows = db.execute(text("""
        SELECT max(s.job_card_no)                               AS job_card_no,
               sum(s.issue_qty)                                 AS issued_qty,
               max(s.uom)                                       AS uom,
               string_agg(DISTINCT s.material_name, ' / ')      AS material,
               string_agg(DISTINCT s.lot_no, ', ')              AS lots,
               max(s.part_number)                               AS store_part,
               max(s.department)                                AS department,
               min(s.issue_date)                                AS issue_date,
               (SELECT count(*) FROM production_log_entries p
                 WHERE upper(trim(p.job_card_no)) = upper(trim(max(s.job_card_no)))) AS entries
        FROM store_issues s
        WHERE s.job_card_no IS NOT NULL AND trim(s.job_card_no) <> '' AND s.approval_status <> 'rejected'
          AND (CAST(:q AS TEXT) IS NULL OR s.job_card_no ILIKE '%' || CAST(:q AS TEXT) || '%'
               OR s.material_name ILIKE '%' || CAST(:q AS TEXT) || '%' OR s.lot_no ILIKE '%' || CAST(:q AS TEXT) || '%')
        GROUP BY upper(trim(s.job_card_no))
        ORDER BY max(s.issue_date) DESC NULLS LAST, max(s.store_issue_id) DESC
        LIMIT :limit
    """), {"q": (q or "").strip() or None, "limit": limit}).mappings().all()
    return {
        "configured": is_configured(),
        "last_synced": last,
        "sync_error": sync_error,
        "cards": [dict(r) for r in rows],
    }


def _ci(v: Optional[str]) -> str:
    return (v or "").strip().lower()


def _num(v):
    return float(v) if v is not None else 0.0


@router.get("/job-cards/{job_card_no}")
def get_job_card(job_card_no: str, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    """The Route Card: Store header + operation table filled from Production Logs entries."""
    jc = job_card_no.strip()
    head = db.execute(text("""
        SELECT count(*) AS n, sum(issue_qty) AS issued_qty, max(uom) AS uom,
               string_agg(DISTINCT material_name, ' / ') AS material,
               string_agg(DISTINCT lot_no, ', ') AS lots,
               max(part_number) AS store_part, max(department) AS department,
               min(issue_date) AS issue_date, sum(consumed_qty) AS consumed_qty,
               string_agg(DISTINCT approval_status, ', ') AS approval
        FROM store_issues
        WHERE upper(trim(job_card_no)) = upper(trim(:jc))
    """), {"jc": jc}).mappings().one()

    entries = (
        db.query(models.ProductionLogEntry)
        .filter(func.upper(func.trim(models.ProductionLogEntry.job_card_no)) == jc.upper())
        .order_by(models.ProductionLogEntry.entry_date, models.ProductionLogEntry.id)
        .all()
    )
    if head["n"] == 0 and not entries:
        raise HTTPException(status_code=404, detail="Job Card not found in the Store or in Production Logs")

    # Operation order: the BOM order of the part these entries belong to.
    parts = Counter(e.part_number for e in entries if e.part_number)
    main_part = parts.most_common(1)[0][0] if parts else None
    by_item_op, by_op = {}, {}
    if main_part:
        bom = (
            db.query(models.BomItem.item_name, models.BomOperation.operation_name)
            .join(models.BomOperation, models.BomOperation.bom_item_id == models.BomItem.id)
            .filter(func.lower(models.BomItem.part_number) == main_part.strip().lower())
            .order_by(models.BomItem.item_seq, models.BomItem.id, models.BomOperation.operation_seq, models.BomOperation.id)
            .all()
        )
        for idx, (item, op) in enumerate(bom):
            by_item_op.setdefault((_ci(item), _ci(op)), idx)
            by_op.setdefault(_ci(op), idx)

    groups = {}
    for e in entries:
        groups.setdefault((e.bom_item_name or "", e.operation_name), []).append(e)

    steps = []
    for (item, op), rows in groups.items():
        produced = sum(_num(r.produced_qty) for r in rows)
        ng = sum(_num(r.ng_qty) for r in rows)
        ok = sum(_num(r.ok_qty) if r.ok_qty is not None else _num(r.produced_qty) - _num(r.ng_qty) for r in rows)
        order = by_item_op.get((_ci(item), _ci(op)), by_op.get(_ci(op), 100000))
        steps.append({
            "_order": order,
            "item_name": item or None,
            "operation_name": op,
            "part_number": rows[0].part_number,
            "first_date": min(r.entry_date for r in rows),
            "last_date": max(r.entry_date for r in rows),
            "planned": sum(_num(r.planned_qty) for r in rows),
            "produced": produced, "ok": ok, "ng": ng,
            "operators": sorted({r.operator_name for r in rows if r.operator_name}),
            "machines": sorted({r.machine_no for r in rows if r.machine_no}),
            "reasons": sorted({r.rejection_reason for r in rows if r.rejection_reason}),
            "entries": [{
                "id": r.id, "entry_date": r.entry_date, "shift": r.shift, "machine_no": r.machine_no,
                "operator_name": r.operator_name, "planned": _num(r.planned_qty), "produced": _num(r.produced_qty),
                "ok": _num(r.ok_qty) if r.ok_qty is not None else _num(r.produced_qty) - _num(r.ng_qty),
                "ng": _num(r.ng_qty), "rejection_reason": r.rejection_reason,
            } for r in rows],
        })
    steps.sort(key=lambda s: (s["_order"], s["first_date"]))
    for s in steps:
        s.pop("_order")

    return {
        "job_card_no": jc,
        "in_store": head["n"] > 0,
        "issued_qty": head["issued_qty"],
        "uom": head["uom"],
        "material": head["material"],
        "lots": head["lots"],
        "store_part": head["store_part"],
        "department": head["department"],
        "issue_date": head["issue_date"],
        "consumed_qty": head["consumed_qty"],
        "issues_count": head["n"],
        "parts_in_entries": sorted(parts),
        "steps": steps,
        "entry_count": len(entries),
        "total_ng": sum(s["ng"] for s in steps),
        "last_step_name": steps[-1]["operation_name"] if steps else None,
        "last_step_ok": steps[-1]["ok"] if steps else 0,
    }
