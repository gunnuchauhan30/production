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
  STORE_SYNC_MINUTES  optional, default 5. How often PPC asks the Store for new Job Cards by
                      itself, even when nobody has a page open. 0 turns the timer off.

The Store login is rate limited (10 per minute), so a sync logs in once and syncs are at
most one every 15 seconds.
"""
import functools
import json
import os
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from datetime import date
from decimal import Decimal
from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
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
            for col in ("required_qty NUMERIC(14,3)", "issued_by_name VARCHAR(100)", "supplier_name VARCHAR(255)",
                        "tc_no VARCHAR(255)", "batch_no VARCHAR(255)", "supplier_checked_at TIMESTAMP"):
                conn.execute(text(f"ALTER TABLE store_issues ADD COLUMN IF NOT EXISTS {col}"))
            # Handover / Store Receiving / Despatch rows of the paper Route Card, kept per Job Card No.
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS job_card_lines (
                    id          SERIAL PRIMARY KEY,
                    job_card_no VARCHAR(50) NOT NULL,
                    section     VARCHAR(20) NOT NULL,
                    line_date   DATE,
                    name        VARCHAR(255),
                    qty         NUMERIC(14,3),
                    remarks     VARCHAR(255),
                    extra       VARCHAR(255),
                    created_by  VARCHAR(100),
                    created_at  TIMESTAMP DEFAULT now()
                )
            """))
            conn.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_job_card_lines_jc ON job_card_lines (upper(trim(job_card_no)), section)"
            ))
            # The Job Card No typed/picked on a Production Log entry. Created here too so the Route Card
            # page works even if the column has not been added yet by another part of the app.
            conn.execute(text(
                "ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS job_card_no VARCHAR(50)"
            ))
    except Exception as exc:  # never stop the app from starting
        print(f"[store_sync] could not create store_issues: {exc}")


def _json_errors(fn):
    """Turns an unexpected crash into a readable message the page can show, instead of a bare 500."""
    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        try:
            return fn(*args, **kwargs)
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"{fn.__name__} failed: {type(exc).__name__}: {str(exc)[:200]}")
    return wrapper


_lock = threading.Lock()
_last_attempt = 0.0
_last_error: Optional[str] = None    # message of the latest failed sync, None after a good one


def start_background_sync() -> None:
    """Asks the Store for new Job Cards every few minutes, by itself."""
    try:
        minutes = float(os.getenv("STORE_SYNC_MINUTES", "5"))
    except ValueError:
        minutes = 5.0
    if minutes <= 0:
        return

    def loop():
        time.sleep(20)  # let the app finish starting first
        while True:
            try:
                if is_configured():
                    _attempt_sync()
            except Exception as exc:  # the timer must never die
                print(f"[store_sync] background sync error: {exc}")
            time.sleep(max(60.0, minutes * 60.0))

    threading.Thread(target=loop, daemon=True, name="store-sync").start()


router = APIRouter(prefix="/store", tags=["store"], on_startup=[ensure_store_tables, start_background_sync])


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
         department, shift, issue_qty, consumed_qty, issue_date, approval_status, required_qty, issued_by_name, synced_at)
    VALUES
        (:store_issue_id, :job_card_no, :issue_no, :material_code, :material_name, :uom, :lot_no, :part_number,
         :department, :shift, :issue_qty, :consumed_qty, :issue_date, :approval_status, :required_qty, :issued_by_name, now())
    ON CONFLICT (store_issue_id) DO UPDATE SET
        job_card_no = EXCLUDED.job_card_no, issue_no = EXCLUDED.issue_no,
        material_code = EXCLUDED.material_code, material_name = EXCLUDED.material_name,
        uom = EXCLUDED.uom, lot_no = EXCLUDED.lot_no, part_number = EXCLUDED.part_number,
        department = EXCLUDED.department, shift = EXCLUDED.shift, issue_qty = EXCLUDED.issue_qty,
        consumed_qty = EXCLUDED.consumed_qty, issue_date = EXCLUDED.issue_date,
        approval_status = EXCLUDED.approval_status, required_qty = EXCLUDED.required_qty,
        issued_by_name = EXCLUDED.issued_by_name, synced_at = now()
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
    complete = len(issues) < 40 * 500       # False only if we stopped at the page limit
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
            "required_qty": i.get("required_qty"),
            "issued_by_name": i.get("issued_by_name"),
        })
    if rows:
        with engine.begin() as conn:
            conn.execute(_UPSERT, rows)
            if complete:
                # Issues removed in the Store disappear here too. The Store sent us everything,
                # so anything we hold that it did not send no longer exists there.
                conn.execute(text("DELETE FROM store_issues WHERE NOT (store_issue_id = ANY(:ids))"),
                             {"ids": [r["store_issue_id"] for r in rows]})
    return len(rows)


def _seconds_since_sync(db: Session) -> float:
    return float(db.execute(text(
        "SELECT COALESCE(EXTRACT(EPOCH FROM (now() - max(synced_at))), 1000000000) FROM store_issues"
    )).scalar())


def _attempt_sync() -> Optional[str]:
    """One guarded sync (never two at once, never more often than MIN_GAP_SECONDS).
    Returns an error message, or None when it worked / was skipped."""
    global _last_attempt, _last_error
    if time.time() - _last_attempt < MIN_GAP_SECONDS:
        return None
    if not _lock.acquire(blocking=False):
        return None
    try:
        _last_attempt = time.time()
        sync_from_store()
        _last_error = None
        return None
    except Exception as exc:
        _last_error = str(exc)
        return _last_error
    finally:
        _lock.release()


def _sync_if_stale(db: Session) -> Optional[str]:
    """Used when a page asks for the list. Returns an error message or None."""
    if not is_configured():
        return None
    if _seconds_since_sync(db) < STALE_AFTER_SECONDS:
        return _last_error
    return _attempt_sync() or _last_error


_token = {"value": None, "at": 0.0}


def _store_get(path: str):
    """GET on the Store API with a cached login token (renewed when it expires)."""
    base, user, pwd = _config()
    if not (user and pwd):
        raise RuntimeError("Store connection is not set up")

    def login():
        _token["value"] = _call("POST", f"{base}/auth/login", form={"username": user, "password": pwd})["access_token"]
        _token["at"] = time.time()

    if not _token["value"] or time.time() - _token["at"] > 20 * 60:
        login()
    try:
        return _call("GET", f"{base}{path}", _token["value"])
    except RuntimeError as exc:
        if "answered 401" not in str(exc):
            raise
        login()
        return _call("GET", f"{base}{path}", _token["value"])


def _fill_supplier_details(db: Session, jc: str) -> None:
    """Supplier / TC No / batch for a card come from the Store per issue (only known once the
    Store has drawn the stock). Fetched when a card is opened, a few at a time, then kept."""
    if not is_configured():
        return
    ids = [r[0] for r in db.execute(text("""
        SELECT store_issue_id FROM store_issues
        WHERE upper(trim(job_card_no)) = upper(trim(:jc)) AND supplier_name IS NULL
          AND (supplier_checked_at IS NULL OR supplier_checked_at < now() - interval '10 minutes')
        ORDER BY store_issue_id LIMIT 5
    """), {"jc": jc})]
    for issue_id in ids:
        try:
            data = _store_get(f"/issues/{issue_id}/fifo-source")
        except Exception:
            return  # Store not reachable right now; try again next time the card is opened
        alloc = data.get("allocation") or [] if isinstance(data, dict) else []
        suppliers = [a.get("supplier_name") for a in alloc if a.get("supplier_name")]
        tcs = [a.get("tc_no") for a in alloc if a.get("tc_no")]
        batches = [a.get("batch_no") for a in alloc if a.get("batch_no")]
        uniq = lambda xs: ", ".join(dict.fromkeys(xs)) or None
        db.execute(text("""
            UPDATE store_issues SET supplier_name = :s, tc_no = :t, batch_no = :b, supplier_checked_at = now()
            WHERE store_issue_id = :id
        """), {"s": uniq(suppliers), "t": uniq(tcs), "b": uniq(batches), "id": issue_id})
        db.commit()


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@router.post("/sync")
def sync_now(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if not is_configured():
        raise HTTPException(status_code=400, detail="Store connection is not set up yet. Add STORE_USERNAME and STORE_PASSWORD in Railway.")
    global _last_attempt, _last_error
    if time.time() - _last_attempt < MIN_GAP_SECONDS:
        raise HTTPException(status_code=429, detail="Synced a moment ago. Try again in a few seconds.")
    if not _lock.acquire(blocking=False):
        raise HTTPException(status_code=429, detail="A sync is already running.")
    try:
        _last_attempt = time.time()
        count = sync_from_store()
        _last_error = None
    except Exception as exc:
        _last_error = str(exc)
        raise HTTPException(status_code=502, detail=str(exc))
    finally:
        _lock.release()
    return {"synced_issues": count}


@router.get("/job-cards")
@_json_errors
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
@_json_errors
def get_job_card(job_card_no: str, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    """The Route Card: Store header + operation table filled from Production Logs entries."""
    jc = job_card_no.strip()
    _fill_supplier_details(db, jc)
    head = db.execute(text("""
        SELECT count(*) AS n, sum(issue_qty) AS issued_qty, max(uom) AS uom,
               sum(required_qty) AS required_qty, max(issued_by_name) AS issued_by,
               string_agg(DISTINCT supplier_name, ' / ') AS supplier,
               string_agg(DISTINCT tc_no, ', ') AS tc_no,
               string_agg(DISTINCT batch_no, ', ') AS batch_no,
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
        .filter(text("upper(trim(production_log_entries.job_card_no)) = :jc").bindparams(jc=jc.upper()))
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
        "required_qty": head["required_qty"],
        "issued_by": head["issued_by"],
        "supplier": head["supplier"],
        "tc_no": head["tc_no"],
        "batch_no": head["batch_no"],
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
        "lines": _load_lines(db, jc),
        "can_delete_lines": _role_name(current_user) in LINE_DELETE_ROLES,
    }


# ---------------------------------------------------------------------------
# Handover / Store Receiving / Despatch rows of the Route Card
# ---------------------------------------------------------------------------
LINE_DELETE_ROLES = {"admin", "production", "planning", "dispatch"}


def _role_name(user) -> str:
    return str(getattr(user.role, "value", user.role))


def _load_lines(db: Session, jc: str) -> dict:
    rows = db.execute(text("""
        SELECT id, section, line_date, name, qty, remarks, extra, created_by
        FROM job_card_lines WHERE upper(trim(job_card_no)) = upper(trim(:jc)) ORDER BY id
    """), {"jc": jc}).mappings().all()
    out = {"handover": [], "receiving": [], "dispatch": []}
    running = 0.0
    for r in rows:
        item = dict(r)
        if item["section"] == "dispatch":
            running += _num(item["qty"])
            item["cumm_total"] = running      # running total of Bill Qty, as on the paper card
        if item["section"] in out:
            out[item["section"]].append(item)
    return out


class LineIn(BaseModel):
    section: Literal["handover", "receiving", "dispatch"]
    name: Optional[str] = None
    line_date: Optional[date] = None
    qty: Optional[Decimal] = None
    remarks: Optional[str] = None
    extra: Optional[str] = None


def _clean(v: Optional[str], n: int = 255) -> Optional[str]:
    return (v or "").strip()[:n] or None


@router.post("/job-cards/{job_card_no}/lines", status_code=201)
@_json_errors
def add_line(job_card_no: str, payload: LineIn, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    jc = job_card_no.strip()
    if not jc:
        raise HTTPException(status_code=400, detail="Job Card No is missing")
    name, remarks, extra = _clean(payload.name), _clean(payload.remarks), _clean(payload.extra)
    if payload.qty is not None and payload.qty < 0:
        raise HTTPException(status_code=400, detail="Quantity cannot be negative")
    if payload.section == "dispatch" and not extra:
        raise HTTPException(status_code=400, detail="Invoice No is required")
    if payload.section != "dispatch" and not name:
        raise HTTPException(status_code=400, detail="Name is required")
    who = getattr(current_user, "full_name", None) or current_user.username
    new_id = db.execute(text("""
        INSERT INTO job_card_lines (job_card_no, section, line_date, name, qty, remarks, extra, created_by)
        VALUES (:jc, :section, :d, :name, :qty, :remarks, :extra, :who) RETURNING id
    """), {"jc": jc, "section": payload.section, "d": payload.line_date, "name": name, "qty": payload.qty,
           "remarks": remarks, "extra": extra, "who": who}).scalar()
    db.commit()
    return {"id": new_id}


@router.delete("/job-cards/{job_card_no}/lines/{line_id}")
@_json_errors
def delete_line(job_card_no: str, line_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if _role_name(current_user) not in LINE_DELETE_ROLES:
        raise HTTPException(status_code=403, detail="Your role cannot delete these rows")
    res = db.execute(text("""
        DELETE FROM job_card_lines WHERE id = :id AND upper(trim(job_card_no)) = upper(trim(:jc))
    """), {"id": line_id, "jc": job_card_no.strip()})
    db.commit()
    if res.rowcount == 0:
        raise HTTPException(status_code=404, detail="Row not found")
    return {"deleted": line_id}
