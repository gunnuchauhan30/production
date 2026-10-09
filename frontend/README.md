# Chanda PPE — Frontend (v2.1)

React 18 + Vite + Tailwind CSS + Framer Motion (page/element animation)
+ Three.js (login screen background). Matches the Chanda Enterprises
brand colors extracted from the live Store frontend, but is a fully
separate app with its own login screen — no shared session with Store.

**Running the whole project?** See the top-level `README.md` one folder
up. The instructions below are for running the frontend **on its own**,
against a backend you already have running somewhere.

## Local development

```bash
cp .env.example .env
# edit .env if your backend isn't at http://localhost:8010
npm install
npm run dev
```

Open http://localhost:5173

## Production build

```bash
npm run build
npm run preview   # serve the build locally to sanity-check it
```

Outputs static files to `dist/` — deploy behind any static file server
or nginx (see `Dockerfile` / `nginx.conf` for the reference setup used
by `docker compose`).

## Structure

```
src/
├── api/client.js         ← axios instance, attaches the JWT, handles 401 → redirect to /login
├── context/AuthContext.jsx
├── components/
│   ├── Layout.jsx         ← sidebar + topbar shell used by every page
│   ├── ThreeBackground.jsx ← the login screen's animated particle field
│   ├── StatCard.jsx, Badge.jsx, ProtectedRoute.jsx
└── pages/
    ├── Login.jsx
    ├── Dashboard.jsx
    ├── RouteCards.jsx      ← manual Route Card entry (replaces old Store search)
    ├── ProductionEntry.jsx ← operation entries, FR-3.3 auto-fill
    ├── OeeLog.jsx
    ├── PdiChecklist.jsx    ← two tabs: in-process / final
    ├── FinishedGoodsDispatch.jsx
    ├── CustomerSchedule.jsx
    ├── Stock.jsx           ← manual stock movements + shortage highlight
    └── MasterData.jsx      ← admin-only
```

## Design tokens (`tailwind.config.js`)

Copied from the live Store's `main.css`, not reinvented:

| Token | Value |
|---|---|
| Primary / brand red | `#c1121f` |
| Primary light / orange | `#e8590c` |
| Accent | `#d7263d` |
| Success / Warning / Danger / Info | `#10b981` / `#f59e0b` / `#ef4444` / `#3b82f6` |
| Font | `'Segoe UI', Tahoma, Geneva, Verdana, sans-serif` |

## Notes for anyone extending this

- **JSX text vs. JS strings**: escape sequences like `\u2026` only work
  inside an actual JS string (`{"Saving\u2026"}` or an attribute in
  quotes evaluated as JS). Written as bare JSX children
  (`<div>Loading\u2026</div>`) they render literally — use the real
  character (`…`) or wrap in `{}` instead. (This bit us once already;
  fixed throughout the current pages.)
- **Three.js cleanup**: `ThreeBackground.jsx` disposes its geometry,
  material, and renderer in a `useEffect` cleanup function — don't drop
  that if you copy the pattern elsewhere, or you'll leak WebGL contexts
  on route changes.
- **Auth**: token lives in `localStorage` under `ppe_token`; a 401 from
  any API call clears it and redirects to `/login` (see
  `api/client.js`'s response interceptor).
