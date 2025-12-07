from fastapi import APIRouter
from app.logger import get_logger
from app.schemas import LogsQuery
from elasticsearch import Elasticsearch
import os

router = APIRouter()
logger = get_logger()

ES_URL = os.getenv("ELASTIC_URL", "http://localhost:9200")

@router.post("/logs/search")
def search_logs(q: LogsQuery):
    es = Elasticsearch(ES_URL, verify_certs=False)
    index = "bank-logs-*"
    must = []
    if q.q:
        must.append({"query_string": {"query": q.q}})
    if q.level:
        must.append({"term": {"level": q.level}})
    body = {
        "size": q.size,
        "sort": [{"@timestamp": {"order": "desc"}}],
        "query": {"bool": {"must": must}} if must else {"match_all": {}}
    }
    r = es.search(index=index, body=body)
    hits = [
        {
            "timestamp": h["_source"].get("@timestamp") or h["_source"].get("asctime"),
            "level": h["_source"].get("levelname") or h["_source"].get("level"),
            "message": h["_source"].get("message"),
            "extra": h["_source"].get("extra", {}),
        }
        for h in r["hits"]["hits"]
    ]
    return {"hits": hits}