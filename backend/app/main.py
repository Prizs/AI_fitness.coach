import os
import threading
import time
from datetime import datetime, timezone, timedelta
import requests
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from app.routers import app_updates, auth, coach, plans, workouts, recalibration, exercises, trainer, progress, voice, admin_portal
from app.services.ai_providers import PROVIDER_ORDER, configured_providers
from app.services.supabase_service import check_supabase_connection

app = FastAPI(
    title="AI Fitness Coach API",
    description="API para rutinas, coaching y recalibración del entrenador personal IA",
    version="0.1.0",
)

static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def disable_web_cache(request, call_next):
    response = await call_next(request)
    path = request.url.path
    if (
        path == "/"
        or path.endswith(".html")
        or path.endswith(".js")
        or path.endswith(".json")
    ):
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"
    return response

app.include_router(coach.router, prefix="/api/coach", tags=["coach"])
app.include_router(app_updates.router, prefix="/api/app", tags=["app"])
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(plans.router, prefix="/api/plans", tags=["plans"])
app.include_router(workouts.router, prefix="/api/workout", tags=["workout"])
app.include_router(recalibration.router, prefix="/api/recalibration", tags=["recalibration"])
app.include_router(exercises.router, prefix="/api/exercises", tags=["exercises"])
app.include_router(trainer.router)
app.include_router(progress.router)
app.include_router(voice.router, prefix="/api/voice", tags=["voice"])
app.include_router(admin_portal.router, tags=["admin_portal"])


def is_within_business_hours_vet() -> bool:
    """Checks if current time in Venezuela (UTC-4) is between 07:00 and 19:00 (7:00 AM to 7:00 PM)."""
    vet = timezone(timedelta(hours=-4))
    now_vet = datetime.now(vet)
    return 7 <= now_vet.hour < 19


def keep_alive_worker():
    """
    Background worker that pings this service every 9 minutes during operating hours
    (7:00 AM - 7:00 PM Venezuela time) to prevent Render from sleeping.
    At 7:00 PM VET, it stops pinging, allowing Render to sleep peacefully during the night
    (saving free tier hours) with standard 30s cold start when accessed outside hours.
    """
    time.sleep(20)
    while True:
        try:
            if is_within_business_hours_vet():
                url = os.environ.get("RENDER_EXTERNAL_URL", "https://ai-fitness-coach-wlg3.onrender.com")
                if url:
                    target = f"{url.rstrip('/')}/health"
                    r = requests.get(target, timeout=10)
                    print(f"[KeepAlive] Self ping exitoso ({datetime.now().strftime('%H:%M:%S')}): {target} -> {r.status_code}")
            else:
                print("[KeepAlive] Modo nocturno activo (7:00 PM a 7:00 AM VET). Reposando para ahorrar horas Render...")
        except Exception as e:
            print(f"[KeepAlive] Aviso autoping: {e}")

        time.sleep(540)  # Cada 9 minutos


@app.on_event("startup")
def start_keep_alive():
    t = threading.Thread(target=keep_alive_worker, daemon=True)
    t.start()


@app.get("/health")
def health_check() -> dict:
    return {
        "status": "ok",
        "service": "ai_fitness_coach_backend",
        "business_hours_active": is_within_business_hours_vet(),
    }


@app.get("/health/supabase")
def supabase_health_check() -> dict:
    return check_supabase_connection()


@app.get("/health/ai")
def ai_health_check() -> dict:
    providers = configured_providers()
    return {
        "available": bool(providers),
        "configured_providers": providers,
        "attempt_order": list(PROVIDER_ORDER),
        "note": (
            "Solo se intentan los proveedores con clave configurada. "
            "Si el primero agota su cuota, se pasa automaticamente al siguiente."
        ),
    }

@app.get("/api/health")
def health_check():
    """Endpoint para mantener activos a Render y Supabase (Keep-Alive)"""
    try:
        from app.services.supabase_service import get_supabase_admin_client
        admin = get_supabase_admin_client()
        admin.table("usuarios").select("id").limit(1).execute()
        return {"status": "ok", "message": "Render and Supabase are alive"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@app.get("/api/admin/diagnostics")
def admin_diagnostics(pin: str | None = None) -> dict:
    """Endpoint protegido de diagnóstico para la consola técnica móvil."""
    if pin not in ("2026", "admin818"):
        return {"authorized": False, "error": "PIN de soporte inválido"}

    import sys
    import platform
    import time

    t0 = time.time()
    supabase_ok = False
    users_count = 0
    trainers_count = 0
    supabase_error = None
    try:
        from app.services.supabase_service import get_supabase_admin_client
        admin = get_supabase_admin_client()
        res = admin.table("usuarios").select("id", count="exact").execute()
        users_count = res.count if hasattr(res, "count") and res.count is not None else len(res.data or [])
        res_t = admin.table("usuarios").select("id", count="exact").eq("role", "trainer").execute()
        trainers_count = res_t.count if hasattr(res_t, "count") and res_t.count is not None else len(res_t.data or [])
        supabase_ok = True
    except Exception as e:
        supabase_error = str(e)
    lat_ms = round((time.time() - t0) * 1000, 1)

    return {
        "authorized": True,
        "status": "healthy",
        "supabase": {
            "connected": supabase_ok,
            "latency_ms": lat_ms,
            "total_users": users_count,
            "trainers_count": trainers_count,
            "error": supabase_error,
        },
        "system": {
            "python_version": sys.version.split()[0],
            "platform": platform.platform(),
            "environment": os.getenv("ENVIRONMENT", "production"),
            "ai_providers": configured_providers(),
        },
    }



# Montar la aplicacion web de Flutter en la raiz
web_dist = os.path.join(os.path.dirname(__file__), "web_dist")
if os.path.exists(web_dist):
    app.mount("/", StaticFiles(directory=web_dist, html=True), name="frontend")
else:
    @app.get("/")
    def root():
        from fastapi.responses import RedirectResponse
        return RedirectResponse(url="/docs")

