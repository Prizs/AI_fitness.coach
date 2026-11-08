import json
import os
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, List, Dict, Any

LOG_FILE = Path(__file__).resolve().parent.parent / "data" / "system_audit_logs.json"
_lock = threading.Lock()

def _ensure_dir():
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not LOG_FILE.exists():
        LOG_FILE.write_text("[]", encoding="utf-8")

def log_event(
    event_type: str,
    cedula: Optional[str] = None,
    user_name: Optional[str] = None,
    detail: Optional[str] = None,
    status: str = "ok",
    ip: Optional[str] = None,
    extra: Optional[Dict[str, Any]] = None,
):
    """
    Registra un evento de auditora en el sistema.
    Tipos comunes:
    - LOGIN_SUCCESS: Inicio de sesin exitoso
    - LOGIN_FAILED: Intento de inicio de sesin fallido
    - COACH_QUERY: Consulta realizada al Coach IA
    - PASSWORD_RESET: Restablecimiento o recuperacin de clave
    - QUIZ_COMPLETED: Test Biopsicosocial completado
    - PROGRESS_UPLOAD: Foto o medicin de progreso registrada
    - GEMINI_ERROR: Falla de conexin o cuota en Gemini API
    - SYSTEM_ERROR: Error general del servidor
    """
    _ensure_dir()
    entry = {
        "id": f"LOG-{int(datetime.now(timezone.utc).timestamp() * 1000)}",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "event_type": event_type,
        "cedula": str(cedula or "anon").strip(),
        "user_name": user_name or "Desconocido",
        "detail": detail or "",
        "status": status,
        "ip": ip or "app-client",
        "extra": extra or {},
    }

    with _lock:
        try:
            records = []
            if LOG_FILE.exists() and LOG_FILE.stat().st_size > 0:
                try:
                    records = json.loads(LOG_FILE.read_text(encoding="utf-8"))
                except Exception:
                    records = []
            records.insert(0, entry)
            # Conservar los ǧltimos 1500 logs para rendimiento ptimo
            if len(records) > 1500:
                records = records[:1500]
            LOG_FILE.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
        except Exception as e:
            print("Error escribiendo audit log:", e)

    # Intentar tambin guardar asncronamente en Supabase si es crtico
    if event_type in ("LOGIN_SUCCESS", "LOGIN_FAILED", "PASSWORD_RESET", "GEMINI_ERROR"):
        try:
            from app.services.supabase_service import get_supabase_admin_client
            admin = get_supabase_admin_client()
            admin.table("coach_mensajes").insert({
                "cedula": str(cedula or "system"),
                "role": "system",
                "category": "audit_log",
                "content": f"[{event_type}] {detail or ''}",
                "plan": entry,
                "created_at": datetime.now(timezone.utc).isoformat()
            }).execute()
        except Exception:
            pass

def get_audit_logs(
    limit: int = 100,
    event_type: Optional[str] = None,
    cedula: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Obtiene los registros de auditora filtrados."""
    _ensure_dir()
    with _lock:
        try:
            if not LOG_FILE.exists():
                return []
            records = json.loads(LOG_FILE.read_text(encoding="utf-8"))
            if event_type:
                records = [r for r in records if r.get("event_type") == event_type]
            if cedula:
                records = [r for r in records if r.get("cedula") == str(cedula).strip()]
            return records[:limit]
        except Exception as e:
            print("Error leyendo audit logs:", e)
            return []
