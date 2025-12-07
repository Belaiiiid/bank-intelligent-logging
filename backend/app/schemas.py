from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class TransactionCreate(BaseModel):
    account_id: str = Field(min_length=3, max_length=64)
    user_name: str = Field(min_length=1, max_length=128)
    amount: float
    currency: str = Field(min_length=3, max_length=8)
    merchant: Optional[str] = None

class TransactionRead(BaseModel):
    id: int
    account_id: str
    user_name: str
    amount: float
    currency: str
    merchant: Optional[str]
    created_at: datetime
    anomaly_score: Optional[float]
    is_anomaly: bool

class LogsQuery(BaseModel):
    q: Optional[str] = None
    level: Optional[str] = None
    size: int = 100