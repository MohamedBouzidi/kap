from contextlib import asynccontextmanager

import uvicorn
from fastapi import Depends, FastAPI
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

from src.dependencies import get_query_token, get_token_header
from src.internal import admin, telemetry
from src.routers import items, users


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Activate telemetry
    telemetry.init_tracer()
    telemetry.init_meter()
    yield
    # Shutdown telemetry
    telemetry.shutdown_tracer()
    telemetry.shutdown_meter()


# app = FastAPI(dependencies=[Depends(get_query_token)], lifespan=lifespan)
app = FastAPI(lifespan=lifespan)

app.include_router(users.router)
app.include_router(items.router)
app.include_router(
    admin.router,
    prefix="/admin",
    tags=["admin"],
    dependencies=[Depends(get_token_header)],
    responses={418: {"description": "I'm a teapot"}},
)


@app.get("/")
async def root():
    return {"message": "Hello Bigger Applications!"}

FastAPIInstrumentor.instrument_app(
    app=app,
    tracer_provider=telemetry.get_tracer_provider(),
    meter_provider=telemetry.get_meter_provider(),
)

def start_local():
    uvicorn.run("src.main:app", host="127.0.0.1", port=8090, reload=True)