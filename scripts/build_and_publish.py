"""Compila el APK release apuntando al backend local y regenera la pagina.

Siempre hay que pasar `--dart-define=API_BASE_URL=...`. Si se olvida, el APK
queda con `http://127.0.0.1:8000`, que en un telefono significa "este mismo
telefono" y falla con ClientSocketException al buscar actualizaciones
(error cometido el 2026-09-26).

La IP se puede forzar con la variable de entorno AIFITNESS_HOST:

    AIFITNESS_HOST=192.168.31.50 python scripts/build_and_publish.py
"""

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "mobile_app"
PUBSPEC = MOBILE / "pubspec.yaml"
BUILD_LOG = MOBILE / "build_release.log"


def current_version() -> tuple[str, int]:
    content = PUBSPEC.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([0-9A-Za-z.]+)\+(\d+)", content, re.MULTILINE)
    if not match:
        raise SystemExit("No se encontro 'version:' en pubspec.yaml")
    return match.group(1), int(match.group(2))


def bump_version() -> None:
    """Sube el codigo de version para que Android acepte la instalacion."""
    name, code = current_version()
    content = PUBSPEC.read_text(encoding="utf-8")
    new_content = re.sub(
        r"^version:.*$",
        f"version: {name}+{code + 1}",
        content,
        count=1,
        flags=re.MULTILINE,
    )
    PUBSPEC.write_text(new_content, encoding="utf-8")
    print(f"  version: {name}+{code} -> {name}+{code + 1}")


def main() -> int:
    host = os.environ.get("AIFITNESS_HOST", "192.168.31.94")
    api_url = f"http://{host}:8000"
    skip_bump = "--no-bump" in sys.argv

    if not skip_bump:
        print("Subiendo version...")
        bump_version()

    print(f"Compilando con API_BASE_URL={api_url} ...")
    with BUILD_LOG.open("w", encoding="utf-8") as log:
        result = subprocess.run(
            [
                "flutter", "build", "apk", "--release",
                f"--dart-define=API_BASE_URL={api_url}",
            ],
            cwd=MOBILE,
            stdout=log,
            stderr=subprocess.STDOUT,
        )
    if result.returncode != 0:
        print("La compilacion fallo. Ultimas lineas del log:")
        print(BUILD_LOG.read_text(encoding="utf-8", errors="replace")[-1500:])
        return result.returncode

    print("Regenerando la pagina de descarga...")
    env = {**os.environ, "AIFITNESS_HOST": host}
    page = subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "update_download_page.py")],
        env=env,
    )
    return page.returncode


if __name__ == "__main__":
    sys.exit(main())