from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.database import AsyncSessionLocal
from app.schemas import TransactionCreate, TransactionRead
from app.logger import get_logger
from app.services import anomaly
from typing import List
from datetime import datetime

router = APIRouter()
logger = get_logger()

async def get_session():
    async with AsyncSessionLocal() as session:
        yield session

@router.post("/transactions", response_model=TransactionRead)
async def create_transaction(payload: TransactionCreate, session: AsyncSession = Depends(get_session)):
    # Compute anomaly
    score, is_anom = anomaly.score_one(payload.amount, payload.merchant, datetime.utcnow())

    q = text("INSERT INTO transactions (account_id, user_name, amount, currency, merchant, anomaly_score, is_anomaly) \
              VALUES (:account_id, :user_name, :amount, :currency, :merchant, :score, :is_anomaly) \
              RETURNING id, account_id, user_name, amount, currency, merchant, created_at, anomaly_score, is_anomaly")
    res = await session.execute(q, {
        "account_id": payload.account_id,
        "user_name": payload.user_name,
        "amount": payload.amount,
        "currency": payload.currency,
        "merchant": payload.merchant,
        "score": score,
        "is_anomaly": is_anom
    })
    await session.commit()
    row = res.mappings().first()
    data = dict(row)

    # Log event
    log_extra = {
        "event": "transaction_created",
        "transaction_id": data["id"],
        "account_id": data["account_id"],
        "user_name": mask_user(data["user_name"]),
        "amount": data["amount"],
        "currency": data["currency"],
        "merchant": data["merchant"],
        "is_anomaly": data["is_anomaly"],
        "anomaly_score": data["anomaly_score"],
    }
    if is_anom:
        logger.warning("Anomalous transaction detected", extra=log_extra)
    else:
        logger.info("Transaction created", extra=log_extra)
    return data

def mask_user(name: str) -> str:
    # Simple PII masking: keep first and last char
    if not name:
        return name
    if len(name) <= 2:
        return name[0] + "*"
    return name[0] + "*"*(len(name)-2) + name[-1]

@router.get("/transactions", response_model=List[TransactionRead])
async def list_transactions(limit: int = 100, session: AsyncSession = Depends(get_session)):
    res = await session.execute(text(
        "SELECT id, account_id, user_name, amount, currency, merchant, created_at, anomaly_score, is_anomaly \
         FROM transactions ORDER BY created_at DESC LIMIT :lim"
    ), {"lim": limit})
    rows = [dict(r) for r in res.mappings().all()]
    return rows

@router.post("/anomalies/train")
async def train_anomaly(session: AsyncSession = Depends(get_session)):
    ok = await anomaly.train_model(session)
    if ok:
        logger.info("Anomaly model trained", extra={"event":"anomaly_train"})
    else:
        logger.warning("Insufficient data to train model", extra={"event":"anomaly_train_skipped"})
    return {"trained": ok}