import os

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.supabase_service import (
    get_supabase_admin_client,
    get_supabase_client,
)

router = APIRouter()
AUTH_EMAIL_DOMAIN = os.getenv("SUPABASE_AUTH_EMAIL_DOMAIN", "aifitnesscoach.app")


class RegisterRequest(BaseModel):
    cedula: str = Field(..., pattern=r"^\d{6,9}$")
    password: str = Field(..., min_length=8)
    nombre: str = Field(..., min_length=2, max_length=100)
    apellido: str = Field(..., min_length=2, max_length=100)
    edad: int = Field(..., ge=12, le=100)
    peso: float = Field(..., gt=0, le=300)
    patologia_o_alergias: str | None = Field(default=None, max_length=1000)
    alergias_alimentarias: str | None = Field(default=None, max_length=1000)
    lesiones_actuales: str | None = Field(default=None, max_length=1000)
    discapacidad_motora: str | None = Field(default=None, max_length=1000)
    zonas_a_evitar: str | None = Field(default=None, max_length=500)


class LoginRequest(BaseModel):
    cedula: str = Field(..., pattern=r"^\d{6,9}$")
    password: str = Field(..., min_length=8)


def _auth_email(cedula: str) -> str:
    return f"cedula.{cedula}@{AUTH_EMAIL_DOMAIN}"


def _session_response(auth_response, profile: dict | None = None) -> dict:
    session = getattr(auth_response, "session", None)
    user = auth_response.user
    return {
        "access_token": session.access_token if session else None,
        "refresh_token": session.refresh_token if session else None,
        "requires_confirmation": session is None,
        "user": {
            "id": user.id,
            "cedula": user.user_metadata.get("cedula"),
            **(profile or {}),
        },
    }


@router.post("/register")
def register(payload: RegisterRequest):
    client = get_supabase_client()
    admin_client = get_supabase_admin_client()
    user_id = None
    try:
        auth_response = admin_client.auth.admin.create_user(
            {
                "email": _auth_email(payload.cedula),
                "password": payload.password,
                "email_confirm": True,
                "user_metadata": {"cedula": payload.cedula},
            }
        )
        if not auth_response.user:
            raise HTTPException(status_code=400, detail="No se pudo crear el usuario.")
        user_id = auth_response.user.id

        profile = {
            "id": auth_response.user.id,
            "cedula": payload.cedula,
            "nombre": payload.nombre,
            "apellido": payload.apellido,
            "edad": payload.edad,
            "peso": payload.peso,
            "patologia_o_alergias": payload.patologia_o_alergias,
            "alergias_alimentarias": payload.alergias_alimentarias,
            "lesiones_actuales": payload.lesiones_actuales,
            "discapacidad_motora": payload.discapacidad_motora,
            "zonas_a_evitar": payload.zonas_a_evitar,
        }
        admin_client.table("usuarios").insert(profile).execute()
        return _session_response(auth_response, profile)
    except HTTPException:
        raise
    except Exception as error:
        error_text = str(error).lower()
        if user_id:
            try:
                admin_client.auth.admin.delete_user(user_id)
            except Exception:
                pass
        if "already registered" in error_text or "already exists" in error_text or "duplicate" in error_text:
            raise HTTPException(status_code=409, detail="Esta cédula ya está registrada.") from error
        raise HTTPException(status_code=500, detail="No se pudo guardar el perfil. Verifica el esquema de Supabase.") from error


@router.post("/login")
def login(payload: LoginRequest):
    client = get_supabase_client()
    admin_client = get_supabase_admin_client()
    try:
        auth_response = client.auth.sign_in_with_password(
            {"email": _auth_email(payload.cedula), "password": payload.password}
        )
        profile_result = (
            admin_client.table("usuarios")
            .select("id, cedula, nombre, apellido, edad, peso, patologia_o_alergias, alergias_alimentarias, lesiones_actuales, discapacidad_motora, zonas_a_evitar")
            .eq("id", auth_response.user.id)
            .single()
            .execute()
        )
        return _session_response(auth_response, profile_result.data)
    except Exception as error:
        raise HTTPException(status_code=401, detail="Cédula o contraseña incorrectos.") from error