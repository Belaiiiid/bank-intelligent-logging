from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from sqlalchemy import text

DATABASE_URL = os.getenv("DATABASE_URL")
# Use async engine by converting psycopg2 URL to asyncpg if needed
if DATABASE_URL and DATABASE_URL.startswith("postgresql+psycopg2"):
    DATABASE_URL_ASYNC = DATABASE_URL.replace("+psycopg2", "+asyncpg")
else:
    DATABASE_URL_ASYNC = DATABASE_URL

engine = create_async_engine(DATABASE_URL_ASYNC, echo=False, future=True)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
Base = declarative_base()

async def init_db():
    # Basic connectivity check
    async with engine.begin() as conn:
        await conn.execute(text("CREATE TABLE IF NOT EXISTS transactions ( \
            id SERIAL PRIMARY KEY, \
            account_id VARCHAR(64) NOT NULL, \
            user_name VARCHAR(128) NOT NULL, \
            amount NUMERIC(18,2) NOT NULL, \
            currency VARCHAR(8) NOT NULL, \
            merchant VARCHAR(128), \
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), \
            anomaly_score DOUBLE PRECISION, \
            is_anomaly BOOLEAN DEFAULT FALSE \
        )"))