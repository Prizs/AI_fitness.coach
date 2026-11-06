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
                return raw_ver, 106
    return "1.0.76", 116

def _find_apk_file() -> Path | None:
    candidates = [
        Path(__file__).resolve().parents[3] / "releases" / "app-release.apk",
        Path(__file__).resolve().parents[3] / "releases" / "app-release-v1076.apk",
        Path(__file__).resolve().parents[3] / "mobile_app" / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk",
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
    size = apk.stat().st_size if apk else 63225169
    ver_name, ver_code = _read_pubspec_version()
    return {
        "available": True,
        "version_name": ver_name,
        "version_code": ver_code,
        "size_bytes": size,
        "released_at": datetime.now(timezone.utc).isoformat(),
        "notes": (
            f"Actualización oficial de AI Fitness Coach v{ver_name}:\n"
            "1. Corrección visual en respuestas rápidas del Coach IA: eliminación del formato de diccionario crudo {content_type: text, title: ...}.\n"
            "2. Validación estricta en registro: cédula y edad numéricas, nombres y apellidos solo alfabéticos, contraseñas con caracteres especiales.\n"
            "3. Filtro Clínico & Seguridad en segundo plano: personalización automática de planes de nutrición y ejercicio según patologías (asma, hipertensión, diabetes) y alergias alimentarias."
        ),
        "download_url": "/api/app/download",
    }

@router.get("/download")
def download_apk():
    """Descarga directamente el APK oficial desde el servidor o redirige al APK en GitHub."""
    apk = _find_apk_file()
    if apk and apk.exists():
        return FileResponse(
            path=str(apk),
            media_type="application/vnd.android.package-archive",
            filename="AI_Fitness_Coach.apk",
        )
    return RedirectResponse(
        url="https://github.com/Prizs/AI_fitness.coach/raw/main/releases/app-release.apk",
        status_code=302,
    )

