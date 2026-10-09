# Chanda PPE — Production Planning & Execution

A standalone production-tracking system for Chanda Enterprises Pvt Ltd —
Route Card entry, operation-wise production with FIFO-aware balance
tracking, daily OEE logging, two-stage PDI, Finished Goods, Dispatch,
Customer Schedule, and Stock/Shortage tracking.

**Zero connection to the Store Management System.** This is a fully
separate application — own database, own backend, own frontend, own
login. Store is never touched: no shared database, no API call into
Store, no shared login. The only link between the two systems is a
person reading a printed Route Card from Store and typing its header
into this app once.

```
chanda_ppe/
├── docker-compose.yml     ← run this, once, from this folder
├── backend/               ← FastAPI + PostgreSQL
│   ├── app/
│   ├── ppe_module_schema_v2.0.sql
│   ├── ppe_schema_addon_v2.1_stock.sql
│   ├── seed.py
│   ├── comprehensive_test.py
│   └── README.md          ← backend-specific details
└── frontend/               ← React + Tailwind + Framer Motion + Three.js
    ├── src/
    └── README.md           ← frontend-specific details
```

## Run everything — one command

Requires [Docker Desktop](https://www.docker.com/products/docker-desktop).        

```bash

docker compose up --build

*  http://localhost:8080   *
```

This brings up three containers:

| Service | What it is | URL |
|---|---|---|
| `ppe_db` | PostgreSQL 16, schema + stock addon applied automatically | internal only (port 5433 on host) |
| `ppe_backend` | FastAPI, seeded with test users on first start | http://localhost:8010/docs |
| `ppe_frontend` | The web app | **** |

Wait for `chanda_ppe_backend | [seed] Done.` in the logs, then open
** ** in your browser.

### Test logins (created automatically)

| Username | Password | Role |
|---|---|---|
| admin | admin123 | admin |
| operator1 | operator123 | operator |
| qa1 | qa123 | qa |

**Change these before using real data.**

### Stop / reset

```bash
docker compose down        # stop, keep data
docker compose down -v     # stop and wipe the database — start completely fresh
```

## Verifying it actually works

Two automated checks are included:

```bash
cd backend
pip install requests
python comprehensive_test.py
```

Runs 37 checks across every module (auth, stock, route cards,
production entries with FR-3.3 auto-fill, PDI role security, the
Finished-Goods auto-trigger, dispatch status) directly against the API.
Expect `RESULT: 37 passed, 0 failed`.

## What's inside, module by module

1. **Customer Schedule** — Planning entries (customer, part, qty, date).
2. **Stock & Shortage** — Manual receipts/issues; current quantity is
   derived automatically; a shortage view flags anything below its
   reorder level.
3. **Route Cards** — Manual entry of a Store-printed Route Card's header
   (job card no, part, issued qty). This is the anchor every other
   record links to with a real foreign key.
4. **Operation Entry** — One row per operation per shift. Balance is
   calculated automatically; the next operation's planned quantity is
   pre-filled from the previous one's output.
5. **OEE Log** — Independent daily log matching the paper OEE sheet
   column-for-column; Availability/Performance/Quality/OEE calculated
   automatically.
6. **PDI** — Two gates: in-process (operator) and final (QA/admin only).
   A passed final check automatically creates the Finished Goods row.
7. **Finished Goods & Dispatch** — Dispatch is only possible once
   Finished Goods exists; on-time/delayed status is computed
   automatically from the schedule vs. actual date.

## Design notes worth knowing

- **Generated database columns** (`balance_qty`, `oee`, `delay_days`,
  etc.) are computed by PostgreSQL, never by the backend — the ORM is
  configured to fetch them back after every insert rather than try to
  set them.
- **PDI result values**: `'pass'` isn't a valid Python identifier, so
  the enum member is named `pass_`; the models map its *value* (not its
  name) to the database via `values_callable`, otherwise Postgres would
  reject the literal string `"pass_"`.
- **Role security**: an `operator` account is blocked (403) from
  recording a final-stage PDI result — only `qa` or `admin` can.
- **Frontend build**: `VITE_API_URL` is baked in at Docker build time
  (see `docker-compose.yml`'s `args:`). If you deploy the frontend
  somewhere other than the same machine as the backend, rebuild with
  `--build-arg VITE_API_URL=https://your-backend-host:8010`.

## Local development (without Docker)

See `backend/README.md` and `frontend/README.md` for running each side
individually with hot-reload (`uvicorn --reload` / `npm run dev`).
