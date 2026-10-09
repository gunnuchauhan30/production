# Chanda PPE — Backend (v2.1)

Zero connection to the Store Management System. Completely separate
database and login.

**Running the whole project (backend + frontend + database together)?**
See the top-level `README.md` one folder up — `docker compose up --build`
from the `chanda_ppe/` root handles everything, including this backend
and its database. The instructions below are for running the backend
**on its own**, without Docker.

## 1. Create the database (once)

```bash
createdb chanda_ppe
psql -d chanda_ppe -f ppe_module_schema_v2.0.sql
psql -d chanda_ppe -f ppe_schema_addon_v2.1_stock.sql
```

## 2. Configure

```bash
cp .env.example .env
# edit .env: PPE_DATABASE_URL, PPE_JWT_SECRET
```

## 3. Install and run

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8010
```

Open http://localhost:8010/docs for the interactive API explorer.

## 4. Create test users

```bash
python seed.py
```

Creates `admin`/`admin123`, `operator1`/`operator123`, `qa1`/`qa123`,
plus sample master data (machines, part routing, rejection/down-time
reasons) so you can actually exercise the whole flow immediately.
**Change these passwords before using real data.**

## Verifying it works

```bash
pip install requests
python comprehensive_test.py
```

37 checks across every module. Expect `RESULT: 37 passed, 0 failed`.

## Notes

- `PPE_DATABASE_URL` must point at `chanda_ppe` (or whatever you name
  it) — never at `chanda_store`. There is no code path in this backend
  that reaches into Store's database.
- Generated / trigger-computed columns (`balance_qty`, `oee`, `delay_days`,
  `total_qty_produced`, `run_time_sec`, `availability`, `performance`,
  `quality`, dispatch `status`) are never set by the ORM — they are
  always read back with `db.refresh()` after an insert.
- `production-entries` `POST`: if `qty_planned` is omitted, the backend
  auto-fills it from the previous operation's total produced (FR-3.3),
  via `v_operation_progress`.
- `pdi-checks` `POST` with `stage=final` and `result=pass` triggers the
  database (`trg_pdi_to_fg`) to auto-create a `finished_goods` row —
  the backend does not duplicate that logic.
- `stock/movements` `POST` triggers the database (`trg_stock_movement`)
  to keep `stock_items.current_qty` in sync — never edit it directly.
