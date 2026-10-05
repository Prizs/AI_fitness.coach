import re
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import RedirectResponse

router = APIRouter()

@router.get("/latest")
def latest_version() -> dict:
    return {
        "available": True,
        "version_name": "1.0.39",
        "version_code": 40,
        "size_bytes": 54000000,
        "released_at": datetime.now(timezone.utc).isoformat(),
        "notes": "1. ACTUALIZACIONES DENTRO DE LA APP ACTIVADAS.\\n2. Textos didácticos para ejercicios sin GIF.\\n3. IA solicita tu nivel de experiencia e intensidad antes de rutinas.",
        "download_url": "/api/app/download",
    }

@router.get("/download")
def download_apk():
    """Redirige directamente al APK alojado en GitHub para descarga ultra-rapida."""
    return RedirectResponse(
        url="https://raw.githubusercontent.com/Prizs/AI_fitness.coach/main/releases/app-release.apk"
    )
