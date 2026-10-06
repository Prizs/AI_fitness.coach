import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.routers.plans import _normalize_meals, _normalize_sessions
from app.services.weekly_plan import WEEKDAY_NAMES, _fallback_week

client = TestClient(app)


def test_weekly_plan_returns_seven_days():
    """La semana siempre trae los 7 dias, con rutina y nutricion en cada uno."""
    week = _fallback_week({"age": 30, "weight": 70})
    assert len(week["days"]) == 7
    for index, day in enumerate(week["days"]):
        assert day["weekday"] == index
        assert day["weekday_name"] == WEEKDAY_NAMES[index]
        assert day["exercises"], f"el dia {index} no tiene ejercicios"
        assert day["nutrition"], f"el dia {index} no tiene nutricion"
        assert day["synergy"], f"el dia {index} no explica la sinergia"


def test_weekly_nutrition_varia_por_dia():
    """La comida cambia cada dia: no se repite el mismo menu."""
    week = _fallback_week({"age": 30, "weight": 70})
    menus = {json_key(day["nutrition"]) for day in week["days"]}
    assert len(menus) > 1, "todos los dias traen el mismo menu"


def json_key(nutrition):
    """Huella simple del menu, para comparar dias distintos."""
    return "|".join(
        meal["title"] + ":" + ",".join(meal["items"])
        for meal in nutrition
    )


def test_weekly_respects_lower_body_restriction():
    """Si se evita la pierna o la rodilla, no llegan ejercicios de tren inferior."""
    week = _fallback_week({
        "age": 60,
        "weight": 80,
        "areas_to_avoid": "rodilla",
    })
    prohibidos = ("Cuadriceps", "Gluteos", "Gemelos")
    for day in week["days"]:
        for exercise in day["exercises"]:
            assert exercise["primary_muscle"] not in prohibidos


def test_weekly_training_days_marked():
    """Los dias de recuperacion no se marcan como entrenamiento."""
    week = _fallback_week({"age": 30, "weight": 70})
    flags = {day["weekday"]: day["is_training"] for day in week["days"]}
    assert flags[0] is True
    assert flags[5] is False
    assert flags[6] is False


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
    assert data.get("provider") in (
        "gemini",
        "fallback",
        "openrouter",
        "mistral",
        "groq",
    )

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


AI_KEY_ENVS = (
    "GEMINI_API_KEY",
    "GROQ_API_KEY",
    "OPENROUTER_API_KEY",
    "MISTRAL_API_KEY",
)


def _clear_ai_keys(monkeypatch):
    for name in AI_KEY_ENVS:
        monkeypatch.delenv(name, raising=False)


def test_ai_health_reports_provider_order():
    response = client.get("/health/ai")
    assert response.status_code == 200
    data = response.json()
    assert data["attempt_order"] == ["gemini", "openrouter", "mistral", "groq"]
    assert isinstance(data["configured_providers"], list)
    assert data["available"] == bool(data["configured_providers"])


def test_configured_providers_follows_env(monkeypatch):
    from app.services import ai_providers

    _clear_ai_keys(monkeypatch)
    assert ai_providers.configured_providers() == []

    monkeypatch.setenv("GROQ_API_KEY", "clave-de-prueba")
    monkeypatch.setenv("GEMINI_API_KEY", "clave-de-prueba")
    assert ai_providers.configured_providers() == ["gemini", "groq"]


def test_generate_json_text_without_providers_fails(monkeypatch):
    from app.services import ai_providers

    _clear_ai_keys(monkeypatch)
    with pytest.raises(ai_providers.AllProvidersFailed):
        ai_providers.generate_json_text("hola")


def test_coach_returns_503_when_no_providers(monkeypatch):
    _clear_ai_keys(monkeypatch)
    response = client.post("/api/coach/chat", json={"message": "hola"})
    assert response.status_code == 503
    assert "proveedor" in response.json()["detail"].lower()


def test_coach_accepts_history_and_health_profile():
    """El contrato de entrada debe validar historial y restricciones."""
    payload = {
        "message": "Ajusta la rutina",
        "history": [
            {"role": "user", "content": "Quiero resistencia"},
            {"role": "assistant", "content": "Propongo intervalos"},
        ],
        "injuries": "rodilla derecha",
        "motor_disability": "ninguna",
        "areas_to_avoid": "hombro",
        "rpe_feedback": 7,
    }
    _clear_ai_keys(_FakeEnv())
    response = client.post("/api/coach/chat", json=payload)
    # Sin proveedores configurados falla con 503, pero nunca con 422 de validacion.
    assert response.status_code == 503


class _FakeEnv:
    def delenv(self, name, raising=True):
        import os

        os.environ.pop(name, None)


def test_latest_version_endpoint_shape():
    response = client.get("/api/app/latest")
    assert response.status_code == 200
    data = response.json()
    assert "available" in data
    assert "version_name" in data
    assert "version_code" in data
    if data["available"]:
        assert data["version_code"] > 0
        assert data["size_bytes"] > 0
        assert data["download_url"] == "/api/app/download"
        assert data["notes"]


def test_download_returns_apk_or_404():
    from app.routers.app_updates import APK_PATH

    response = client.get("/api/app/download")
    if APK_PATH.exists():
        assert response.status_code == 200
        assert (
            response.headers["content-type"]
            == "application/vnd.android.package-archive"
        )
    else:
        assert response.status_code == 404


def test_pubspec_version_is_parsed(monkeypatch):
    from app.routers import app_updates

    version_name, version_code = app_updates._read_pubspec_version()
    assert version_code > 0
    assert version_name.count(".") >= 1
