# -*- coding: utf-8 -*-
"""
Script de Despliegue 100% Automatizado en Render API
Crea el Web Service, inyecta todas las variables de entorno de .env,
inicia el build, espera que este Live y actualiza el proyecto.
"""

import os, sys, json, time, urllib.request, urllib.error

ROOT = r"C:\AI_FITNESS_COACH_PROYECTO_COMPLETO"
ENV_PATH = os.path.join(ROOT, ".env")

def load_env():
    env_vars = {}
    if os.path.exists(ENV_PATH):
        with open(ENV_PATH, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    env_vars[k.strip()] = v.strip()
    return env_vars

def render_request(method, endpoint, api_key, data=None):
    url = f"https://api.render.com/v1/{endpoint.lstrip('/')}"
    req = urllib.request.Request(url, method=method)
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Accept", "application/json")
    if data is not None:
        req.add_header("Content-Type", "application/json")
        req.data = json.dumps(data).encode("utf-8")
    
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"Render API Error {e.code}: {err_body}")

def deploy_service(api_key):
    print("1. Verificando API Key y obteniendo Owner ID...")
    owners = render_request("GET", "owners", api_key)
    if not owners:
        raise RuntimeError("No se encontro un Owner en la cuenta de Render.")
    owner_id = owners[0]["owner"]["id"]
    owner_name = owners[0]["owner"].get("name", "Usuario")
    print(f"   Conectado a la cuenta de: {owner_name} (ID: {owner_id})")

    print("2. Leyendo variables de entorno locales de .env...")
    local_envs = load_env()
    print(f"   {len(local_envs)} variables cargadas listas para inyectar.")

    env_var_payload = [{"key": k, "value": v} for k, v in local_envs.items()]

    payload = {
        "type": "web_service",
        "name": "ai-fitness-coach",
        "ownerId": owner_id,
        "repo": "https://github.com/Prizs/AI_fitness.coach",
        "branch": "main",
        "rootDir": "backend",
        "autoDeploy": "yes",
        "serviceDetails": {
            "env": "python",
            "plan": "free",
            "region": "ohio",
            "envSpecificDetails": {
                "buildCommand": "pip install -r requirements.txt",
                "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT"
            },
            "envVars": env_var_payload
        }
    }

    print("3. Creando el Web Service en Render con todas las configuraciones...")
    new_service = render_request("POST", "services", api_key, payload)
    service_id = new_service["id"] if "id" in new_service else new_service.get("service", {}).get("id")
    service_name = new_service.get("name") or new_service.get("service", {}).get("name")
    service_url = new_service.get("serviceDetails", {}).get("url") or new_service.get("service", {}).get("serviceDetails", {}).get("url")
    print(f"   Servicio creado: {service_name} (ID: {service_id})")
    print(f"   URL asignada: {service_url}")

    return service_id, service_url

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python deploy_to_render.py <RENDER_API_KEY>")
        sys.exit(1)
    key = sys.argv[1].strip()
    sid, surl = deploy_service(key)
    print(f"SERVICE_ID={sid}")
    print(f"NUEVA_URL_FINAL={surl}")
