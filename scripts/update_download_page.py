"""Regenera la pagina de descarga con la version real recien compilada.

Se ejecuta despues de `flutter build apk` porque el APK cambia de nombre y de
version en cada compilacion. Sin esto la pagina puede quedarse apuntando a un
APK viejo (error cometido el 2026-09-26).

Uso:
    python scripts/update_download_page.py
"""

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBSPEC = ROOT / "mobile_app" / "pubspec.yaml"
APK_DIR = ROOT / "mobile_app" / "build" / "app" / "outputs" / "flutter-apk"
APK = APK_DIR / "app-release.apk"
PAGE = APK_DIR / "index.html"

TEMPLATE = """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AI Fitness Coach - Descarga Android</title>
<style>
  body {{ margin:0; padding:24px; background:#0B1220; color:#E6EDF5;
         font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }}
  .card {{ max-width:520px; margin:0 auto; background:#101B2D; border:1px solid #173B45;
          border-radius:20px; padding:24px; }}
  h1 {{ font-size:22px; margin:0 0 6px; }}
  h2 {{ font-size:16px; margin-top:24px; }}
  p  {{ color:#9FB0C4; font-size:14px; line-height:1.5; }}
  .btn {{ display:block; text-align:center; background:#8BE0C0; color:#0B1220;
         font-weight:700; text-decoration:none; padding:16px; border-radius:14px;
         margin:18px 0 8px; font-size:16px; }}
  .meta {{ font-size:12px; color:#7C8DA3; }}
  code {{ background:#173B45; padding:2px 6px; border-radius:6px; color:#8BE0C0; }}
  ol {{ padding-left:20px; color:#9FB0C4; font-size:14px; line-height:1.7; }}
  .warn {{ border-left:3px solid #FF9500; padding-left:12px; margin-top:18px; }}
</style>
</head>
<body>
<div class="card">
  <h1>AI Fitness Coach</h1>
  <p>Instalador para Android. Descarga el archivo, abrilo y acepta los permisos.</p>

  <a class="btn" href="/app-release.apk" download>Instalar AI Fitness Coach</a>
  <p class="meta">Version {version} (codigo {code}) · {size} MB · Android 7.0 o superior.</p>

  <ol>
    <li>Toca el boton de arriba y espera la descarga.</li>
    <li>Abre la notification de descarga o la carpeta <code>Descargas</code>.</li>
    <li>Toca <code>app-release.apk</code>.</li>
    <li>Si Chrome pide permiso, activa <strong>"Instalar apps de origenes
        desconocidos"</strong>.</li>
    <li>Confirma <strong>Instalar</strong>. Android avisara que la app no es de
        Play Store: es normal.</li>
  </ol>

  <h2>Actualizar la app</h2>
  <p>Una vez instalada, la propia app se actualiza sola. Entra a
  <strong>Mi Perfil y Salud</strong> desde Inicio y baja hasta
  <strong>Actualizaciones de la app</strong>: te dice si hay version nueva y
  la instala sin salir de la app. Tambien se comprueba automaticamente al abrir.</p>
  <p class="meta">La PC debe seguir encendida y en la misma red WiFi.</p>

  <div class="warn">
    <p><strong>Importante:</strong> la computadora debe seguir encendida y
    conectada a la misma red WiFi. El servidor corre en
    <code>http://{host}:8000</code>.</p>
    <p>Si la app no conecta, en el login toca <strong>"Servidor: ..."</strong>
    y escribe esa misma direccion.</p>
  </div>
</div>
</body>
</html>
"""


def read_version() -> tuple[str, int]:
    content = PUBSPEC.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([0-9A-Za-z.]+)\+(\d+)", content, re.MULTILINE)
    if not match:
        raise SystemExit("No se encontro 'version:' en pubspec.yaml")
    return match.group(1), int(match.group(2))


def main() -> int:
    if not APK.exists():
        print("El APK no existe. Compila primero con: flutter build apk --release")
        return 1

    version, code = read_version()
    size_mb = round(APK.stat().st_size / (1024 * 1024), 1)
    host = os.environ.get("AIFITNESS_HOST", "192.168.31.94")

    # Elimina APK viejos que ya no corresponden a la version publicada.
    for stale in APK_DIR.glob("ai-fitness-coach-instalador*.apk"):
        stale.unlink()
        print(f"  APK obsoleto eliminado: {stale.name}")

    PAGE.write_text(
        TEMPLATE.format(version=version, code=code, size=size_mb, host=host),
        encoding="utf-8",
    )
    print(f"Pagina de descarga actualizada -> version {version} (codigo {code})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
