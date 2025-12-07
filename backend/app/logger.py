import logging
import os
from typing import Any, Optional, cast
from types import ModuleType

_jsonlogger: Optional[ModuleType]
try:
    from pythonjsonlogger import jsonlogger as _jsonlogger  # type: ignore[assignment]
except Exception:
    _jsonlogger = None  # type: ignore[assignment]

try:
    from logstash_async.handler import AsynchronousLogstashHandler as _AsyncHandler  # type: ignore
    from logstash_async.formatter import LogstashFormatter as _LogstashFormatter  # type: ignore
except Exception:
    _AsyncHandler = None  # type: ignore[assignment]
    _LogstashFormatter = None  # type: ignore[assignment]


class SimpleJsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        import json
        log_record = {
            "asctime": self.formatTime(record, self.datefmt),
            "name": record.name,
            "levelname": record.levelname,
            "message": record.getMessage(),
        }
        if record.exc_info:
            log_record["exc_info"] = self.formatException(record.exc_info)
        return json.dumps(log_record, ensure_ascii=False)


def get_logger():
    logger = logging.getLogger("app")
    if logger.handlers:
        return logger
    logger.setLevel(logging.INFO)

    # Console JSON
    console_handler = logging.StreamHandler()
    JsonFormatterCls: Any = getattr(_jsonlogger, "JsonFormatter", None) if _jsonlogger else None
    console_formatter = JsonFormatterCls("%(asctime)s %(name)s %(levelname)s %(message)s") if JsonFormatterCls else SimpleJsonFormatter()
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)

    # Logstash async TCP
    host = os.getenv("LOGSTASH_HOST", "localhost")
    port = int(os.getenv("LOGSTASH_PORT", "5000"))
    if _AsyncHandler and _LogstashFormatter:
        ls_handler = cast(logging.Handler, _AsyncHandler(
            host, port, database_path="logstash.db"
        ))
        formatter: logging.Formatter = cast(logging.Formatter, _LogstashFormatter(message_type="python-logstash", extra_prefix="extra", extra=dict(
            app="bank-api",
            env=os.getenv("ENV", "dev"),
        )))
        ls_handler.setFormatter(formatter)
        logger.addHandler(ls_handler)
    else:
        logger.debug("logstash_async not available; skipping Logstash handler setup")

    return logger
