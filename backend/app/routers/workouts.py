from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter()


class WorkoutRequest(BaseModel):
    goal: str = Field(..., min_length=2)
    level: str = Field(..., min_length=2)
    days_per_week: int = Field(..., ge=1, le=7)


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
