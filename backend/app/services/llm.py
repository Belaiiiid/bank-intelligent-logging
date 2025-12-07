"""
LLM-powered utilities for log analysis and fraud explanation.

This module attempts to use a configured LLM provider when available, and
falls back to fast heuristic summaries when not. This keeps the API usable
in dev/test without secrets.

Env vars (optional):
- LLM_PROVIDER: one of [openai, azure, ollama]. Default: empty (fallback mode).
- OPENAI_API_KEY: API key for OpenAI/Azure OpenAI.
- OPENAI_BASE_URL: Custom base URL (optional, e.g., Azure AOAI endpoint).
- OPENAI_MODEL: Model name. Default: gpt-4o-mini.
- OLLAMA_HOST: e.g., http://localhost:11434
- OLLAMA_MODEL: e.g., llama3.1:8b
"""

from __future__ import annotations

from typing import Any, Dict, Iterable, List, Mapping, Optional, Tuple
import json
import os
from collections import Counter


def _truncate(s: str, max_len: int = 300) -> str:
	if len(s) <= max_len:
		return s
	return s[: max_len - 1] + "…"


class _LLMClient:
	"""Tiny wrapper around one of several providers. Optional at runtime."""

	def __init__(self) -> None:
		self.provider = (os.getenv("LLM_PROVIDER") or "").lower()
		self.model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
		self.ollama_model = os.getenv("OLLAMA_MODEL", "llama3.1:8b")
		self.available = False
		self._client = None
		self._openai = None
		self._requests = None

		if self.provider == "ollama":
			try:
				import requests  # type: ignore

				self._requests = requests
				self.available = True
			except Exception:
				self.available = False

	def complete(self, prompt: str, system_prompt: Optional[str] = None, *, max_tokens: int = 400) -> str:
		"""Return a completion string. Fall back to echo-ish heuristic if unavailable."""
		if not self.available:
			# Heuristic fallback: return a concise extracted summary
			return _heuristic_completion(prompt)

		try:
			if self.provider == "ollama" and self._requests is not None:
				url = (os.getenv("OLLAMA_HOST") or "http://localhost:11434").rstrip("/") + "/api/generate"
				payload: Dict[str, Any] = {
					"model": self.ollama_model,
					"prompt": (f"{system_prompt}\n\n" if system_prompt else "") + str(prompt),
					"options": {"temperature": 0.2},
					"stream": False,
				}
				resp = self._requests.post(url, json=payload, timeout=60)
				resp.raise_for_status()
				data: Any = resp.json()
				return str(data.get("response") or "").strip()
		except Exception:
			# If provider fails at runtime, degrade gracefully
			pass

		return _heuristic_completion(prompt)


def _heuristic_completion(prompt: str) -> str:
	# Very small deterministic summary: pick key sentences and compress numbers
	lines = [ln.strip() for ln in prompt.splitlines() if ln.strip()]
	if not lines:
		return "No content to analyze."
	top = lines[:8]
	# Remove overly long JSON blocks
	top = [_truncate(x, 220) for x in top]
	return "\n".join(top)


def summarize_logs(logs: Iterable[Mapping[str, Any]], *, max_items: int = 50) -> Dict[str, Any]:
	"""
	Summarize recent logs. Optionally calls an LLM; always returns a stable structure.

	Returns: {
	  summary: str,
	  key_events: list[str],
	  levels: {level: count}
	}
	"""
	items: List[Dict[str, Any]] = []
	for i, log in enumerate(logs):
		if i >= max_items:
			break
		items.append({
			"timestamp": log.get("timestamp") or log.get("@timestamp") or log.get("asctime"),
			"level": (log.get("level") or log.get("levelname") or "INFO").upper(),
			"message": str(log.get("message") or ""),
			"extra": log.get("extra") or {},
		})

	level_counts: Counter[str] = Counter([str(x.get("level", "INFO")) for x in items])
	# Extract key events by simple scoring: warnings/errors and items with 'event' or 'anomaly'
	scored: List[Tuple[int, str]] = []
	for it in items:
		msg = it["message"]
		bonus = 0
		lvl = it["level"]
		if lvl in ("WARNING", "ERROR", "CRITICAL"):
			bonus += {"WARNING": 2, "ERROR": 3, "CRITICAL": 4}[lvl]
		extra_obj: Any = it.get("extra")
		if isinstance(extra_obj, dict):
			extra: Dict[str, Any] = extra_obj  # type: ignore[assignment]
		else:
			extra = {}
			if extra.get("is_anomaly"):
				bonus += 3
			if extra.get("event"):
				bonus += 1
		# prefer shorter but informative messages
		base = max(1, 120 - len(msg) // 10)
		score = bonus * 100 + base
		scored.append((score, _truncate(msg, 160)))
	scored.sort(reverse=True)
	key_events = [m for _, m in scored[: min(8, len(scored))]]

	# LLM summary prompt
	client = _LLMClient()
	system = (
		"You are a senior SRE and fraud analyst. Summarize logs for a banking app. "
		"Be precise and concise. Identify incidents, anomalies, and user impact."
	)
	compact: List[Dict[str, Any]] = [
		{
			"t": it["timestamp"],
			"lvl": it["level"],
			"msg": _truncate(it["message"], 180),
			"x": ({k: it["extra"].get(k) for k in ("event", "transaction_id", "is_anomaly", "anomaly_score")} if isinstance(it.get("extra"), dict) else {}),
		}
		for it in items
	]
	prompt = (
		"Context logs (most recent first):\n" + json.dumps(compact, ensure_ascii=False, indent=2) +
		"\n\nPlease provide: 1) a 3-6 line summary, 2) bullets of top events, 3) any fraud signals."
	)
	summary = client.complete(prompt, system_prompt=system, max_tokens=350)

	return {
		"summary": summary,
		"key_events": key_events,
		"levels": dict(level_counts),
	}


def explain_transaction(tx: Mapping[str, Any]) -> Dict[str, Any]:
	"""
	Explain potential fraud/anomaly for a transaction dict.

	Expected keys: amount, currency, merchant, anomaly_score, is_anomaly, created_at, account_id, user_name
	Returns: { explanation: str, risk_factors: list[str], recommended_actions: list[str] }
	"""
	amount = float(tx.get("amount") or 0.0)
	currency = (tx.get("currency") or "").upper()
	merchant = tx.get("merchant") or "unknown"
	score = float(tx.get("anomaly_score") or 0.0)
	is_anom = bool(tx.get("is_anomaly") or score > 0.6)
	hour = None
	try:
		created_at = tx.get("created_at")
		if created_at is not None:
			if isinstance(created_at, str):
				from datetime import datetime
				s = created_at.replace("Z", "+00:00")
				dt = None
				try:
					dt = datetime.fromisoformat(s)
				except Exception:
					dt = None
				if dt is not None:
					hour = int(dt.hour)
			else:
				hour = int(getattr(created_at, "hour", None) or 0)
	except Exception:
		hour = None

	risk_factors: List[str] = []
	if amount >= 2000:
		risk_factors.append("high_amount>=2000")
	elif amount >= 1000:
		risk_factors.append("elevated_amount>=1000")
	if hour is not None and (hour < 6 or hour >= 22):
		risk_factors.append("off_hours_activity")
	if score >= 0.9:
		risk_factors.append("very_high_model_score")
	elif score >= 0.7:
		risk_factors.append("high_model_score")
	elif score >= 0.6:
		risk_factors.append("moderate_model_score")
	if not merchant or merchant.lower() in {"unknown", "misc", "cash"}:
		risk_factors.append("low_context_merchant")

	# Prepare concise fact block for LLM
	facts: Dict[str, Any] = {
		"amount": amount,
		"currency": currency,
		"merchant": merchant,
		"anomaly_score": score,
		"is_anomaly": is_anom,
		"hour": hour,
		"account_id": tx.get("account_id"),
		"transaction_id": tx.get("id"),
	}

	client = _LLMClient()
	system = (
		"You are a bank fraud analyst. Explain in plain language why a transaction was flagged. "
		"Avoid speculation; cite concrete signals. Provide clear next steps."
	)
	prompt = (
		"Transaction facts:\n" + json.dumps(facts, ensure_ascii=False, indent=2) +
		"\nRisk factors (heuristic): " + ", ".join(risk_factors or ["none"]) +
		"\n\nWrite: 1) A brief explanation (<=6 lines). 2) 2-4 recommended actions (bullets)."
	)
	explanation = client.complete(prompt, system_prompt=system, max_tokens=280)

	# If LLM unavailable, produce deterministic recommendations
	recommended_actions: List[str] = []
	if amount >= 2000 or score >= 0.7:
		recommended_actions.append("temporarily_hold_and_manual_review")
	recommended_actions.append("notify_user_and_step_up_auth")
	recommended_actions.append("verify_merchant_and_geo_velocity")
	if is_anom:
		recommended_actions.append("tighten_limits_for_24h_if_unconfirmed")

	return {
		"explanation": explanation,
		"risk_factors": risk_factors,
		"recommended_actions": recommended_actions,
	}

