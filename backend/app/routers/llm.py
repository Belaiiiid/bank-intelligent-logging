from fastapi import APIRouter
from typing import Any, Dict, List, Optional
from pydantic import BaseModel
from app.services import llm as llm_service

router = APIRouter()


class LogItem(BaseModel):
	timestamp: Optional[str] = None
	level: Optional[str] = None
	message: Optional[str] = None
	extra: Optional[Dict[str, Any]] = None
	# Additional optional fields sometimes present in ES/LogRecord
	asctime: Optional[str] = None
	levelname: Optional[str] = None


class LogsSummarizePayload(BaseModel):
	logs: List[LogItem]
	max_items: int = 50


@router.post("/llm/logs/summarize")
def summarize_logs(payload: LogsSummarizePayload):
	"""
	Summarize recent logs using an LLM when available.
	Expected payload: { "logs": [ {timestamp, level, message, extra?}, ... ], "max_items"?: int }
	Returns: { summary: str, key_events: string[], levels: {level: count} }
	"""
	logs: List[Dict[str, Any]] = [li.model_dump() for li in payload.logs]
	max_items = int(payload.max_items)
	return llm_service.summarize_logs(logs, max_items=max_items)


class TransactionPayload(BaseModel):
	id: Optional[int] = None
	account_id: Optional[str] = None
	user_name: Optional[str] = None
	amount: float
	currency: Optional[str] = None
	merchant: Optional[str] = None
	anomaly_score: Optional[float] = None
	is_anomaly: Optional[bool] = None
	created_at: Optional[str] = None


class ExplainPayload(BaseModel):
	transaction: TransactionPayload


@router.post("/llm/transactions/explain")
def explain_transaction(payload: ExplainPayload):
	"""
	Explain a single transaction's risk factors.
	Expected payload: transaction object with fields: amount, currency, merchant, anomaly_score, is_anomaly, created_at, account_id, id
	Returns: { explanation, risk_factors, recommended_actions }
	"""
	tx = payload.transaction.model_dump()
	return llm_service.explain_transaction(tx)

