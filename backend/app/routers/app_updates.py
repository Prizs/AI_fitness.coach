import os
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse, RedirectResponse

router = APIRouter()

APK_PATH = Path(__file__).resolve().parents[3] / "releases" / "app-release.apk"

def _read_pubspec_version() -> tuple[str, int]:
    pubspec_path = Path(__file__).resolve().parents[3] / "mobile_app" / "pubspec.yaml"
    if not pubspec_path.exists():
        pubspec_path = Path("mobile_app/pubspec.yaml").resolve()
    if pubspec_path.exists():
        for line in pubspec_path.read_text(encoding="utf-8").splitlines():
            if line.startswith("version:"):
                raw_ver = line.split(":", 1)[1].strip()
                if "+" in raw_ver:
                    name, code = raw_ver.split("+", 1)
                    return name.strip(), int(code.strip())
                return raw_ver, 103
    return "1.0.63", 103

def _find_apk_file() -> Path | None:
    candidates = [
        Path(__file__).resolve().parents[3] / "releases" / "app-release.apk",
        Path(__file__).resolve().parents[2] / "releases" / "app-release.apk",
        Path(__file__).resolve().parent.parent / "web_dist" / "AI_Fitness_Coach.apk",
        Path("releases/app-release.apk").resolve(),
    ]
    for p in candidates:
        if p.exists() and p.stat().st_size > 1000000:
            return p
    return None

@router.get("/latest")
def latest_version() -> dict:
    apk = _find_apk_file()
    size = apk.stat().st_size if apk else 63995129
    return {
        "available": True,
        "version_name": "1.0.63",
        "version_code": 103,
        "size_bytes": size,
        "released_at": datetime.now(timezone.utc).isoformat(),
        "notes": (
            "Actualización oficial de AI Fitness Coach v1.0.63:\n"
            "1. Persistencia total de conversación en Coach IA: nunca se borran los mensajes al navegar entre módulos.\n"
            "2. Selector interactivo de días (< LUNES >) con flechas y acceso rápido a toda la semana.\n"
            "3. Visualización destacada de Días de Descanso con mensajes y 4 consejos clave (hidratación, nutrición criolla, sueño y recuperación activa).\n"
            "4. Meta mensual editable en 1 toque en Inicio, Registro, Onboarding y Coach IA, sin asumir hipertrofia por defecto.\n"
            "5. Eliminación de ejercicios repetidos y correcta combinación de zonas musculares sin duplicaciones."
        ),
        "download_url": "/api/app/download",
    }

@router.get("/download")
def download_apk():
    """Descarga directamente el APK oficial desde el servidor o redirige a la release de GitHub."""
    apk = _find_apk_file()
    if apk and apk.exists():
        return FileResponse(
            path=str(apk),
            media_type="application/vnd.android.package-archive",
            filename="AI_Fitness_Coach_v1.0.63.apk",
        )
    return RedirectResponse(url="https://github.com/miope-hub/AI_FITNESS_COACH_PROYECTO_COMPLETO/releases/download/v1.0.63/app-release.apk", status_code=302)

