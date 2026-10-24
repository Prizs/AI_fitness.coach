import os
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse, RedirectResponse

router = APIRouter()

GITHUB_RELEASE_APK_URL = "https://github.com/Prizs/AI_fitness.coach/releases/download/v1.0.61/app-release.apk"
GITHUB_LATEST_RELEASE_URL = "https://github.com/Prizs/AI_fitness.coach/releases/latest"

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
        "version_name": "1.0.61",
        "version_code": 101,
        "size_bytes": size,
        "released_at": datetime.now(timezone.utc).isoformat(),
        "notes": (
            "Actualización oficial de AI Fitness Coach v1.0.61:\n"
            "1. Nuevo selector de Sexo Biológico (Masculino / Femenino) en registro y perfil.\n"
            "2. Calibración metabólica precisa (TMB / Harris-Benedict) y adaptación del Coach IA.\n"
            "3. Test Biopsicosocial & Adherencia estilo FitCraft obligatorio al registrarse.\n"
            "4. Registro 100% fluido con auto-login, prevención de duplicados y timeout extendido.\n"
            "5. Los 3 Modos Definitivos (Técnica Real, Atlas Muscular 2D y Biomecánica 3D)."
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
            filename="AI_Fitness_Coach_v1.0.61.apk",
        )
    return RedirectResponse(url=GITHUB_RELEASE_APK_URL, status_code=302)

