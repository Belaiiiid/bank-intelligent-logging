from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from app.routers import transactions, logs
from app.routers import llm as llm_router
from app.logger import get_logger
from app.database import init_db
import os
from typing import Any

logger = get_logger()

app = FastAPI(title="Bank Intelligent Logging API", version="0.1.0")

origins = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
if origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Basic in-memory websocket connections store
class ConnectionManager:
    def __init__(self):
        self.active: set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active.add(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active.discard(websocket)
    async def broadcast(self, message: dict[str, Any]) -> None:
        to_remove: list[WebSocket] = []
        for connection in self.active:
            try:
                await connection.send_json(message)
            except Exception:
                to_remove.append(connection)
        for c in to_remove:
            self.disconnect(c)

ws_manager = ConnectionManager()

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    logger.info("app_started", extra={"service": "api", "env": os.getenv("ENV", "dev")})
    yield

app.router.lifespan_context = lifespan

@app.websocket("/ws/logs")
async def websocket_logs(websocket: WebSocket):
    await ws_manager.connect(websocket)
    try:
        while True:
            # Client can send pings or filters; we ignore for now
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
        
def push_live_log(record: dict[str, Any]) -> None:
    import anyio
    anyio.run(ws_manager.broadcast, record)
# Register routers
app.include_router(transactions.router, prefix="/api", tags=["transactions"])
app.include_router(logs.router, prefix="/api", tags=["logs"])
app.include_router(llm_router.router, prefix="/api", tags=["llm"])

# Attach live push hook to logger
import logging
# Precompute built-in LogRecord attribute keys to filter extras
_LOGRECORD_BUILTIN_KEYS = set(logging.LogRecord("app", logging.INFO, "", 0, "", (), None).__dict__.keys())

class LiveLogHandler(logging.Handler):
    def emit(self, record: logging.LogRecord):
        try:
            push_live_log({
                "timestamp": getattr(record, "asctime", None),
                "level": record.levelname,
                "message": record.getMessage(),
                "extra": {k: v for k, v in record.__dict__.items() if k not in _LOGRECORD_BUILTIN_KEYS},
            })
        except Exception:
            pass

logging.getLogger("app").addHandler(LiveLogHandler())