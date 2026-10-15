import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from app.routers import app_updates, auth, coach, plans, workouts, recalibration, exercises, trainer, progress
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

app.include_router(coach.router, prefix="/api/coach", tags=["coach"])
app.include_router(app_updates.router, prefix="/api/app", tags=["app"])
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(plans.router, prefix="/api/plans", tags=["plans"])
app.include_router(workouts.router, prefix="/api/workout", tags=["workout"])
app.include_router(recalibration.router, prefix="/api/recalibration", tags=["recalibration"])
app.include_router(exercises.router, prefix="/api/exercises", tags=["exercises"])


@app.get("/health")
def health_check() -> dict:
    return {"status": "ok", "service": "ai_fitness_coach_backend"}


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


# Montar la aplicacion web de Flutter en la raiz
web_dist = os.path.join(os.path.dirname(__file__), "web_dist")
if os.path.exists(web_dist):
    app.mount("/", StaticFiles(directory=web_dist, html=True), name="frontend")
else:
    @app.get("/")
    def root():
        from fastapi.responses import RedirectResponse
        return RedirectResponse(url="/docs")

