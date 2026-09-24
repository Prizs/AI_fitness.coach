from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter()


class RecalibrationRequest(BaseModel):
    current_weight: float = Field(..., gt=0)
    target_weight: float = Field(..., gt=0)
    weekly_progress: float = Field(..., ge=-100, le=100)


@router.post("/evaluate")
def evaluate_progress(payload: RecalibrationRequest):
    return {
        "status": "review_needed",
        "message": "Your current progression is being evaluated. Adjustments to calories and workload may be recommended.",
        "current_weight": payload.current_weight,
        "target_weight": payload.target_weight,
        "weekly_progress": payload.weekly_progress,
    }
