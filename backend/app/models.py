from dataclasses import dataclass
from datetime import datetime

@dataclass
class Transaction:
    id: int
    account_id: str
    user_name: str
    amount: float
    currency: str
    merchant: str | None
    created_at: datetime
    anomaly_score: float | None
    is_anomaly: bool