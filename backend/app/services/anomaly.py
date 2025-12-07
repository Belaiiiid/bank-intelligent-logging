from sklearn.ensemble import IsolationForest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import numpy as np
import joblib
import os

MODEL_PATH = "/app/app/models/anomaly_iforest.joblib"

def _featurize(rows):
    # rows: list of dicts from DB
    # Features: amount, hour_of_day, merchant hash bucket (very simplistic)
    feats = []
    for r in rows:
        amt = float(r["amount"])
        hour = int(r["created_at"].hour) if r["created_at"] else 0
        merch = r["merchant"] or "unknown"
        merch_bucket = hash(merch) % 50
        feats.append([amt, hour, merch_bucket])
    return np.array(feats, dtype=float)

async def train_model(session: AsyncSession, limit: int = 5000):
    res = await session.execute(text("SELECT amount, merchant, created_at FROM transactions ORDER BY created_at DESC LIMIT :lim"), {"lim": limit})
    rows = [dict(r) for r in res.mappings()]
    if len(rows) < 100:
        return False
    X = _featurize(rows)
    model = IsolationForest(n_estimators=200, contamination=0.01, random_state=42)
    model.fit(X)
    os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
    joblib.dump(model, MODEL_PATH)
    return True

def score_one(amount: float, merchant: str | None, created_at):
    from datetime import datetime
    hour = int((created_at or datetime.utcnow()).hour)
    merch_bucket = hash(merchant or "unknown") % 50
    x = np.array([[float(amount), hour, merch_bucket]], dtype=float)
    if not os.path.exists(MODEL_PATH):
        return 0.0, False
    model: IsolationForest = joblib.load(MODEL_PATH)
    score = -float(model.score_samples(x)[0])  # higher means more anomalous
    return score, bool(score > 0.6)  # threshold tweak