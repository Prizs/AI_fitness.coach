from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "ai_fitness_coach_backend"

def test_plan_generation():
    payload = {
        "goal": "Hipertrofia",
        "level": "Intermedio",
        "days_per_week": 3,
        "age": 25,
        "weight": 70.5,
        "food_allergies": "maní",
        "areas_to_avoid": "hombro derecho",
        "learning_consent": True
    }
    response = client.post("/api/plans/generate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "sessions" in data
    assert "nutrition" in data
    assert data.get("provider") in ("gemini", "fallback")
