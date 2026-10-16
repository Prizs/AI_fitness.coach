from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter()


class WorkoutRequest(BaseModel):
    goal: str = Field(default="mejorar condicion fisica", max_length=5000)
    level: str = Field(default="intermedio", max_length=500)
    days_per_week: int = Field(default=4)


@router.post("/routine")
def generate_workout(payload: WorkoutRequest):
    return {
        "goal": payload.goal,
        "level": payload.level,
        "days_per_week": payload.days_per_week,
        "routine": [
            "Warm-up: 10 minutes",
            "Strength block: 3 sets x 8-12 reps",
            "Mobility cooldown: 5 minutes",
        ],
    }
