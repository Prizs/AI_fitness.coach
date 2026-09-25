from fastapi.testclient import TestClient
from app.main import app
from app.routers.plans import _normalize_meals, _normalize_sessions

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

    # Contrato estable que consume Flutter.
    assert isinstance(data["sessions"], list) and data["sessions"]
    for session in data["sessions"]:
        assert isinstance(session, dict)
        assert isinstance(session.get("day"), str)
        assert isinstance(session.get("title"), str)
        assert isinstance(session.get("exercises"), list)
        for exercise in session["exercises"]:
            assert isinstance(exercise.get("name"), str)
            assert "sets" in exercise
            assert isinstance(exercise.get("reps"), str)
            assert isinstance(exercise.get("animation_key"), str)

    assert isinstance(data["nutrition"], list) and data["nutrition"]
    for meal in data["nutrition"]:
        assert isinstance(meal, dict)
        assert isinstance(meal.get("title"), str)
        assert isinstance(meal.get("items"), list)
        for item in meal["items"]:
            assert isinstance(item, str)


def test_normalize_sessions_handles_alternative_keys():
    raw = [
        {
            "day": "Lunes",
            "focus": "Empuje",
            "exercises": [
                {"exercise": "Press banca", "series": 4, "repetitions": "8"},
                "texto invalido",
            ],
        },
        "entrada invalida",
    ]
    sessions = _normalize_sessions(raw)
    assert len(sessions) == 1
    session = sessions[0]
    assert session["day"] == "Lunes"
    assert session["title"] == "Empuje"
    exercise = session["exercises"][0]
    assert exercise["name"] == "Press banca"
    assert exercise["sets"] == 4
    assert exercise["reps"] == "8"
    assert exercise["animation_key"] == "generic-exercise"


def test_normalize_meals_accepts_dict_and_list_forms():
    from_dict = _normalize_meals({"Desayuno": ["Avena", "Fruta"]})
    assert from_dict == [{"title": "Desayuno", "items": ["Avena", "Fruta"]}]

    from_list = _normalize_meals(
        [
            {"meal": "Almuerzo", "description": "Pollo con arroz"},
            {"title": "Cena", "items": "Sopa"},
        ]
    )
    assert from_list[0] == {"title": "Almuerzo", "items": ["Pollo con arroz"]}
    assert from_list[1] == {"title": "Cena", "items": ["Sopa"]}
