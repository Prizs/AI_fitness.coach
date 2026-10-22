import os
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

router = APIRouter()

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
    size = apk.stat().st_size if apk else 54792490
    return {
        "available": True,
        "version_name": "1.0.40",
        "version_code": 41,
        "size_bytes": size,
        "released_at": datetime.now(timezone.utc).isoformat(),
        "notes": (
            "Actualización oficial de AI Fitness Coach v1.0.40:\n"
            "1. Los 3 Modos Definitivos (Técnica Real, Atlas Muscular 2D y Modelo 3D Muscular 360).\n"
            "2. Adaptación biomecánica completa para discapacidades motoras y lesiones.\n"
            "3. Nutrición 100% mercado local venezolano.\n"
            "4. Diagnóstico y asistente clínico para entrenadores personales."
        ),
        "download_url": "/api/app/download",
    }

@router.get("/download")
def download_apk():
    """Descarga directamente el APK oficial desde el servidor."""
    apk = _find_apk_file()
    if apk and apk.exists():
        return FileResponse(
            path=str(apk),
            media_type="application/vnd.android.package-archive",
            filename="AI_Fitness_Coach_v1.0.40.apk",
        )
    raise HTTPException(status_code=404, detail="Archivo APK no disponible en el servidor.")

