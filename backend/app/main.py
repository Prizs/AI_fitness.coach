from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth, coach, workouts, recalibration
from app.services.supabase_service import check_supabase_connection

app = FastAPI(
    title="AI Fitness Coach API",
    description="API para rutinas, coaching y recalibración del entrenador personal IA",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(coach.router, prefix="/api/coach", tags=["coach"])
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(workouts.router, prefix="/api/workout", tags=["workout"])
app.include_router(recalibration.router, prefix="/api/recalibration", tags=["recalibration"])


@app.get("/health")
def health_check() -> dict:
    return {"status": "ok", "service": "ai_fitness_coach_backend"}


@app.get("/health/supabase")
def supabase_health_check() -> dict:
    return check_supabase_connection()
