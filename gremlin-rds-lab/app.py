import json
import os
import time
from typing import Any, Dict, Optional

from fastapi import FastAPI, Request
from psycopg_pool import ConnectionPool

# ---- DB connection details (all provided at runtime) ----
DB_HOST = os.environ.get("DB_HOST")  # REQUIRED
DB_PORT = int(os.environ.get("DB_PORT", "5432"))

DB_NAME = os.environ.get("DB_NAME", "postgres")
DB_USER = os.environ.get("DB_USER")  # REQUIRED
DB_PASSWORD = os.environ.get("DB_PASSWORD")  # REQUIRED

if not DB_HOST:
    raise RuntimeError("DB_HOST env var is required.")
if not DB_USER or not DB_PASSWORD:
    raise RuntimeError("DB_USER and DB_PASSWORD env vars are required.")

DB_DSN = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

pool = ConnectionPool(conninfo=DB_DSN, min_size=1, max_size=5)

app = FastAPI(title="Gremlin RDS Timing Demo", version="1.0.0")


def now_ns() -> int:
    return time.perf_counter_ns()


def ns_to_ms(ns: int) -> float:
    return ns / 1_000_000.0


def parse_client_timings_header(request: Request) -> Optional[Dict[str, Any]]:
    raw = request.headers.get("x-client-timings")
    if not raw:
        return None
    try:
        data = json.loads(raw)
        if isinstance(data, dict):
            return data
    except Exception:
        pass
    return {"error": "Invalid X-Client-Timings JSON"}


def fetch_all(table: str) -> Dict[str, Any]:
    t_handler_start = now_ns()

    with pool.connection() as conn:
        with conn.cursor() as cur:
            t_db_start = now_ns()
            cur.execute(f"SELECT id, name FROM {table} ORDER BY name ASC")
            rows = cur.fetchall()
            t_db_ns = now_ns() - t_db_start

    t_handler_ns = now_ns() - t_handler_start

    data = [{"id": r[0], "name": r[1]} for r in rows]
    return {
        "items": data,
        "db_query_execution_time_ms": ns_to_ms(t_db_ns),
        "server_processing_time_ms": ns_to_ms(t_handler_ns),
    }


@app.get("/fruits")
def list_fruits(request: Request):
    t0 = now_ns()
    result = fetch_all("fruit")
    t1 = now_ns()

    return {
        "items": result["items"],
        "timings_ms": {
            "server_handler_time_ms": ns_to_ms(t1 - t0),
            "server_processing_time_ms": result["server_processing_time_ms"],
            "db_query_execution_time_ms": result["db_query_execution_time_ms"],
            "client_reported": parse_client_timings_header(request),
        },
        "connection": {
            "db_host": DB_HOST,
            "db_port": DB_PORT,
            "db_name": DB_NAME,
        },
    }


@app.get("/vegetables")
def list_vegetables(request: Request):
    t0 = now_ns()
    result = fetch_all("vegetables")
    t1 = now_ns()

    return {
        "items": result["items"],
        "timings_ms": {
            "server_handler_time_ms": ns_to_ms(t1 - t0),
            "server_processing_time_ms": result["server_processing_time_ms"],
            "db_query_execution_time_ms": result["db_query_execution_time_ms"],
            "client_reported": parse_client_timings_header(request),
        },
        "connection": {
            "db_host": DB_HOST,
            "db_port": DB_PORT,
            "db_name": DB_NAME,
        },
    }
