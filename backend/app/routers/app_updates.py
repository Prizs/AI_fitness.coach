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
                return raw_ver, 117
    return "1.0.77", 117

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
            f"AI Fitness Coach v{ver_name} (Compilación Oficial):\n"
            "• Nueva Galería Horizontal de Evolución Corporal: Desplazamiento táctil (swipe) cronológico desde el Día 1 con comparativa visual inmediata.\n"
            "• Ficha Clínica & Fisiológica IA Dinámica: Actualización en vivo de KPIs (definición, grasa estimada, postura), biotipo y recomendaciones anatómicas bajo cada foto.\n"
            "• Suite de Bitácora Oficial (PDF) & Rendimiento: Exportación directa y test biomecánicos adaptados.\n"
            "• Actualización y Descarga Instantánea: Nuevo centro de sincronización directa desde el Perfil y Pantalla Principal."
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

