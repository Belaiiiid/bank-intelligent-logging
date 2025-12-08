# Bank Intelligent Logging

An end‑to‑end sample stack for structured, real‑time logging and anomaly detection on banking transactions.

- Backend: FastAPI (Python) + PostgreSQL + Redis
- Ingest & Search: Logstash → Elasticsearch → Kibana
- Frontend: Angular (served by Nginx in Docker)
- Realtime: WebSocket stream from backend to UI
- Anomaly detection: Isolation Forest (scikit‑learn)

## At a glance

```
[FastAPI] --(JSON logs over TCP)--> [Logstash] --(index)--> [Elasticsearch] <-- [Kibana]
    |                                             ^
    +--(WebSocket / REST)--> [Angular UI via Nginx]|
```

Ports (default):
- API: 8000
- Frontend (Nginx): 8080
- Elasticsearch: 9200
- Kibana: 5601
- Logstash TCP input: 5000
- Postgres: 5432
- Redis: 6379

## Project structure (essentials)

```
bank-intelligent-logging/
├─ docker-compose.yml
│
├─ logstash/
│  └─ pipeline/
│     └─ logstash.conf
│
├─ backend/
│  ├─ Dockerfile
│  ├─ requirements.txt
│  └─ app/
│     ├─ __init__.py
│     ├─ main.py
│     ├─ logger.py
│     ├─ database.py
│     ├─ models.py
│     ├─ schemas.py
│     ├─ routers/
│     │  ├─ __init__.py
│     │  ├─ transactions.py
│     │  └─ logs.py
│     └─ services/
│        ├─ __init__.py
│        └─ anomaly.py
│
└─ frontend/
   ├─ Dockerfile
   ├─ nginx.conf
   ├─ package.json
   ├─ angular.json
   ├─ tsconfig*.json
   └─ src/
```

## Prerequisites

- Docker Desktop running in Linux containers mode
  - Recommended: WSL2 engine enabled (Docker Desktop → Settings → General → “Use the WSL 2 based engine”)
  - Resources: ≥ 4 CPUs and 6–8 GB RAM (Elasticsearch + Kibana)
- Open ports: 8000, 8080, 5601, 9200, 5000, 5432, 6379
- Optional (for local frontend dev): Node.js LTS (npm)

> Windows tip: Avoid project paths with special characters or OneDrive sync folders. Prefer something like C:\dev\bank-intelligent-logging or a WSL path (\\wsl$\Ubuntu\home\you\bank-intelligent-logging).

## Quick start (Docker)

From the project root:

```bash
docker compose up -d --build
```

Give Elasticsearch/Kibana ~60–90 seconds to initialize on first run.

Open:
- Frontend (Nginx): http://localhost:8080
- API docs (FastAPI): http://localhost:8000/docs
- Kibana: http://localhost:5601

## Generate sample data

Create a transaction (this logs to Logstash → Elasticsearch and streams via WebSocket to the UI):

```bash
curl -X POST http://localhost:8000/api/transactions \
  -H "Content-Type: application/json" \
  -d '{"account_id":"ACCT-001","user_name":"Alice Johnson","amount":123.45,"currency":"USD","merchant":"Amazon"}'
```

Check Elasticsearch directly:

```bash
curl "http://localhost:9200/bank-logs-*/_search?q=transaction_created&size=1&pretty"
```

In Kibana:
1) Go to Discover.
2) Create a Data View:
   - Name: bank-logs-*
   - Time field: @timestamp
3) You should see the structured logs.

## API highlights

- POST /api/transactions — create a transaction (emits structured log + realtime event)
- GET /api/transactions — list transactions
- POST /api/anomalies/train — train/update Isolation Forest on recent data
- GET /api/logs — search logs in Elasticsearch (basic query)
- WebSocket (path as implemented in backend/app/main.py) — realtime stream to UI

Explore all routes in Swagger UI: http://localhost:8000/docs

## Environment variables (service: api)

Configured in docker-compose.yml; override as needed.

- DATABASE_URL: postgresql+psycopg2://app:app@db:5432/bank
- REDIS_URL: redis://redis:6379/0
- LOGSTASH_HOST: logstash
- LOGSTASH_PORT: 5000
- ELASTIC_URL: http://elasticsearch:9200
- ENV: dev
- CORS_ORIGINS: http://localhost:8080,http://localhost:4200

Elasticsearch (for dev):
- discovery.type=single-node
- xpack.security.enabled=false
- ES_JAVA_OPTS: adjust heap e.g., -Xms512m -Xmx512m

## Frontend development (optional)

Use the Angular dev server with hot reload:

```bash
# install Node.js LTS first (npm included)
cd frontend
npm install
npm start
```

Open http://localhost:4200

The Dockerized Nginx build is still available at http://localhost:8080 for production‑like testing.

## Logs, health, and lifecycle

Show container status:

```bash
docker compose ps
```

Tail logs (examples):

```bash
docker compose logs -f api
docker compose logs -f logstash
docker compose logs -f elasticsearch
```

Cluster health:

```bash
curl -s http://localhost:9200/_cluster/health?pretty
```

Stop:

```bash
docker compose down
```

Stop and wipe data volumes (Postgres/Elasticsearch):

```bash
docker compose down -v
```

## Troubleshooting

- Docker engine not reachable on Windows (named pipe error open //./pipe/dockerDesktopLinuxEngine):
  - Ensure Docker Desktop is running and in Linux containers mode (tray menu).
  - Docker Desktop → Troubleshoot → Restart Docker.
  - Use WSL2 engine (Settings → General) and enable WSL integration.
  - Move the project to a simple path (e.g., C:\dev\bank-intelligent-logging) or a WSL path.
  - Check context: `docker context ls` then `docker context use desktop-linux`.

- Kibana shows no data:
  - Create the Data View bank-logs-* with @timestamp.
  - Confirm Logstash is running: `docker compose logs -f logstash`.
  - Generate a transaction via the API to push a log.

- Elasticsearch memory / red status:
  - Increase Docker memory.
  - Ensure ES_JAVA_OPTS matches available memory; wait 60–90s after startup.

- Frontend cannot reach API:
  - Ensure API is up on 8000.
  - The Nginx config proxies /api and /ws to the backend; verify nginx.conf.

- npm not found (local dev):
  - Install Node.js LTS (Windows: `winget install OpenJS.NodeJS.LTS`, macOS: `brew install node`, Ubuntu: NodeSource or nvm).
  - Restart terminal; verify `node -v` and `npm -v`.

- Compose warning “version is obsolete”:
  - Safe to ignore; remove the `version:` key from docker-compose.yml if present.

- See Logstash in Kibana Stack Monitoring (optional):
  - Enable xpack monitoring in Logstash (logstash.yml) and point to Elasticsearch.

## Security note

For local development, Elasticsearch security is disabled. Do not use these settings in production. If enabling security:
- Turn on xpack.security in ES and Kibana, set passwords, configure Logstash output with credentials, and configure the backend’s ELASTIC_URL with auth.

## Tech stack

- Python 3.11, FastAPI, SQLAlchemy, Pydantic, scikit‑learn
- PostgreSQL, Redis
- Logstash, Elasticsearch, Kibana (Elastic Stack)
- Angular 18, Nginx
