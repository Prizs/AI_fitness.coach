import os
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse, RedirectResponse

router = APIRouter()

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
                return raw_ver, 119
    return "1.0.79", 119

def _find_apk_file() -> Path | None:
    ver_name, _ = _read_pubspec_version()
    candidates = [
        Path(__file__).resolve().parent.parent / "web_dist" / f"AI_Fitness_Coach_v{ver_name}.apk",
        Path(__file__).resolve().parent.parent / "web_dist" / "AI_Fitness_Coach.apk",
        Path(__file__).resolve().parents[3] / "releases" / f"AI_Fitness_Coach_Oficial_v{ver_name}.apk",
        Path(__file__).resolve().parents[3] / "releases" / "AI_Fitness_Coach_Oficial_v1.0.79.apk",
        Path(__file__).resolve().parents[3] / "releases" / "app-release.apk",
        Path(__file__).resolve().parents[2] / "releases" / f"AI_Fitness_Coach_Oficial_v{ver_name}.apk",
        Path(f"releases/AI_Fitness_Coach_Oficial_v{ver_name}.apk").resolve(),
        Path(f"backend/app/web_dist/AI_Fitness_Coach_v{ver_name}.apk").resolve(),
        Path("backend/app/web_dist/AI_Fitness_Coach.apk").resolve(),
        Path("releases/app-release.apk").resolve(),
    ]
    for p in candidates:
        if p.exists() and p.stat().st_size > 1000000:
            return p
    return None

@router.get("/latest")
def latest_version() -> dict:
    apk = _find_apk_file()
    size = apk.stat().st_size if apk else 63156898
    ver_name, ver_code = _read_pubspec_version()
    return {
        "available": True,
        "version_name": ver_name,
        "version_code": ver_code,
        "size_bytes": size,
        "released_at": datetime.now(timezone.utc).isoformat(),
        "notes": (
            f"AI Fitness Coach v{ver_name} (Compilación Oficial Android):\n"
            "• Prescripción Biomecánica Preventiva 100% Adaptada: Ante molestias en tobillo o rodilla, rutinas 100% en sedestación y decúbito (cero impacto, cero bipedestación).\n"
            "• Mapeo Anatómico de GIFs 100% Exacto: Sincronización estricta de remos bajo mesa, deltoides posterior, superman y extensiones.\n"
            "• Filtro Dinámico de Alergias & Patologías: Menús y rutinas personalizadas que respetan alergias registradas.\n"
            "• Auto-actualización y Descarga Instantánea: Actualización directa con un clic desde el móvil."
        ),
        "download_url": "/api/app/download",
        "direct_download_url": "https://ai-fitness-coach-wlg3.onrender.com/download",
    }

@router.get("/download")
def download_apk():
    """Descarga directamente el APK oficial desde el servidor o redirige al APK en GitHub."""
    apk = _find_apk_file()
    ver_name, _ = _read_pubspec_version()
    if apk and apk.exists():
        return FileResponse(
            path=str(apk),
            media_type="application/vnd.android.package-archive",
            filename=f"AI_Fitness_Coach_v{ver_name}.apk",
        )
    return RedirectResponse(
        url=f"https://github.com/Prizs/AI_fitness.coach/raw/main/releases/AI_Fitness_Coach_Oficial_v{ver_name}.apk",
        status_code=302,
    )

