import os
from pathlib import Path

import httpx
from dotenv import load_dotenv
from supabase import create_client


PROJECT_ROOT = Path(__file__).resolve().parents[3]
load_dotenv(PROJECT_ROOT / ".env")

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")
SUPABASE_SECRET_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

if SUPABASE_URL and SUPABASE_KEY:
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
else:
    supabase = None

if SUPABASE_URL and SUPABASE_SECRET_KEY:
    supabase_admin = create_client(SUPABASE_URL, SUPABASE_SECRET_KEY)
else:
    supabase_admin = None


def get_supabase_client():
    if supabase is None:
        raise RuntimeError(
            "Faltan variables de entorno de Supabase. Configura SUPABASE_URL y SUPABASE_KEY."
        )
    return supabase


def get_supabase_admin_client():
    if supabase_admin is None:
        raise RuntimeError(
            "Falta SUPABASE_SERVICE_ROLE_KEY para operaciones administrativas."
        )
    return supabase_admin


def check_supabase_connection() -> dict[str, str | int]:
    db_url = os.getenv("DATABASE_URL")
    if db_url:
        try:
            import psycopg2
            with psycopg2.connect(db_url, connect_timeout=5) as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT 1;")
                    return {"status": "ok", "backend": "postgresql"}
        except Exception:
            pass

    if not SUPABASE_URL or not SUPABASE_KEY:
        return {"status": "not_configured", "message": "Supabase no está configurado."}

    try:
        response = httpx.get(
            f"{SUPABASE_URL}/auth/v1/settings",
            headers={"apikey": SUPABASE_KEY},
            timeout=10,
        )
        if response.is_success:
            return {"status": "ok", "http_status": response.status_code, "backend": "rest"}
        return {"status": "error", "http_status": response.status_code}
    except Exception as error:
        return {"status": "error", "message": str(error)}
