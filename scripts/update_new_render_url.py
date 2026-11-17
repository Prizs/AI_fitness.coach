# -*- coding: utf-8 -*-
"""
Actualiza la URL de Render en todos los archivos del proyecto automaticamente.
"""

import os, sys

ROOT = r"C:\AI_FITNESS_COACH_PROYECTO_COMPLETO"
OLD_URL = "https://ai-fitness-coach-818a.onrender.com"

def update_url(new_url):
    new_url = new_url.rstrip("/")
    print(f"Reemplazando {OLD_URL} por {new_url} en todo el proyecto...")

    targets = [
        os.path.join(ROOT, r"mobile_app\lib\services\auth_service.dart"),
        os.path.join(ROOT, r"keep_alive.py"),
        os.path.join(ROOT, r"AI_FITNESS_COACH_NOTION_VIEWER.html"),
        os.path.join(ROOT, r"test_plans_api.py"),
    ]

    for p in targets:
        if os.path.exists(p):
            with open(p, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            if OLD_URL in content:
                content = content.replace(OLD_URL, new_url)
                with open(p, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"  ✔ Actualizado: {os.path.basename(p)}")

    # Tambien ajustar keep_alive para que no gaste las 750 horas en 15 dias:
    # Aumentar intervalo de 10 min a 14 min (840s) o intervalo seguro
    keep_path = os.path.join(ROOT, "keep_alive.py")
    if os.path.exists(keep_path):
        with open(keep_path, "r", encoding="utf-8") as f:
            t = f.read()
        t = t.replace(f"URL = '{OLD_URL}/docs'", f"URL = '{new_url}/docs'")
        with open(keep_path, "w", encoding="utf-8") as f:
            f.write(t)
        print("  ✔ keep_alive.py calibrado con la nueva URL.")

    print("\n¡Todos los archivos del proyecto quedaron sincronizados con la nueva URL!")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python update_new_render_url.py <NUEVA_URL>")
        sys.exit(1)
    update_url(sys.argv[1].strip())
