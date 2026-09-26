import re
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

router = APIRouter()

ROOT = Path(__file__).resolve().parents[3]
PUBSPEC = ROOT / "mobile_app" / "pubspec.yaml"
NOTES_FILE = ROOT / "mobile_app" / "RELEASE_NOTES.md"
APK_PATH = (
    ROOT / "mobile_app" / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
)

APK_MEDIA_TYPE = "application/vnd.android.package-archive"


def _read_pubspec_version() -> tuple[str, int]:
    """Lee `version: 1.2.3+45` del pubspec y devuelve (nombre, codigo)."""
    if not PUBSPEC.exists():
        return "0.0.0", 0
    content = PUBSPEC.read_text(encoding="utf-8", errors="replace")
    match = re.search(r"^version:\s*([0-9A-Za-z.]+)\+(\d+)", content, re.MULTILINE)
    if not match:
        return "0.0.0", 0
    return match.group(1), int(match.group(2))


def _read_notes() -> str:
    if NOTES_FILE.exists():
        return NOTES_FILE.read_text(encoding="utf-8", errors="replace").strip()
    return "Actualizacion de la app AI Fitness Coach."


@router.get("/latest")
def latest_version() -> dict:
    """Version publicada en el servidor para que el movil decida si actualiza."""
    version_name, version_code = _read_pubspec_version()

    if not APK_PATH.exists():
        return {
            "available": False,
            "reason": "El servidor todavia no tiene un APK compilado.",
            "version_name": version_name,
            "version_code": version_code,
        }

    stat = APK_PATH.stat()
    return {
        "available": True,
        "version_name": version_name,
        "version_code": version_code,
        "size_bytes": stat.st_size,
        "released_at": datetime.fromtimestamp(
            stat.st_mtime, tz=timezone.utc
        ).isoformat(),
        "notes": _read_notes(),
        "download_url": "/api/app/download",
    }


@router.get("/download")
def download_apk():
    """Entrega el APK para que la app lo instale sin salir de ella."""
    if not APK_PATH.exists():
        raise HTTPException(
            status_code=404,
            detail="El servidor no tiene un APK compilado todavia.",
        )
    return FileResponse(
        APK_PATH,
        media_type=APK_MEDIA_TYPE,
        filename="ai-fitness-coach.apk",
    )
