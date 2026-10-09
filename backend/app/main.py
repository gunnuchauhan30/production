"""
Chanda PPE — standalone backend entrypoint.

Run with:  uvicorn app.main:app --reload --port 8010
(Store's backend, if also running locally, is on its own port — the two
processes never talk to each other.)
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import auth, route_cards, production, production_log, oee, pdi, dispatch, schedule, master_data, stock, press_stock, reports

app = FastAPI(
    title="Chanda PPC — Production Planning & Control",
    description="Standalone backend. Zero connection to the Store Management System.",
    version="2.2.0",
)

# Adjust allow_origins to the PPE frontend's actual URL before going to production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(route_cards.router)
app.include_router(production.router)
app.include_router(production_log.router)
app.include_router(oee.router)
app.include_router(pdi.router)
app.include_router(dispatch.fg_router)
app.include_router(dispatch.dispatch_router)
app.include_router(schedule.router)
app.include_router(master_data.router)
app.include_router(stock.router)
app.include_router(press_stock.router)
app.include_router(reports.router)


@app.get("/health")
def health():
    return {"status": "ok", "service": "chanda-ppc-backend", "connected_to_store": False}
