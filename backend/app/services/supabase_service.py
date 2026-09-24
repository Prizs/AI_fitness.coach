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
    if not SUPABASE_URL or not SUPABASE_KEY:
        return {"status": "not_configured", "message": "Supabase no está configurado."}

    response = httpx.get(
        f"{SUPABASE_URL}/auth/v1/settings",
        headers={"apikey": SUPABASE_KEY},
        timeout=10,
    )
    if not response.is_success:
        return {"status": "error", "http_status": response.status_code}

    if supabase_admin is None:
        return {"status": "error", "message": "Falta la clave secreta."}

    try:
        supabase_admin.table("usuarios").select(
            "id, cedula, nombre, apellido, edad, peso, patologia_o_alergias, "
            "alergias_alimentarias, lesiones_actuales, discapacidad_motora, zonas_a_evitar"
        ).limit(1).execute()
    except Exception as error:
        if "does not exist" in str(error):
            return {"status": "error", "message": "Faltan columnas nuevas en public.usuarios. Ejecuta la migracion de Supabase."}
        return {"status": "error", "message": "La tabla usuarios no responde."}

    return {"status": "ok", "http_status": response.status_code}
