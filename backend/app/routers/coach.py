from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter()


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    user_goal: str | None = None
    user_level: str | None = None


@router.post("/chat")
def chat_with_coach(payload: ChatMessage):
    return {
        "response": (
            f"Coach response to: '{payload.message}'. "
            "I can help you adapt your training plan, review your goal and current level."
        ),
        "goal": payload.user_goal,
        "level": payload.user_level,
    }
