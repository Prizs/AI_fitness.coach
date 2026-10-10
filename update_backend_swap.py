import sys

# 1. Update plans.py
path1 = 'backend/app/routers/plans.py'
with open(path1, 'r', encoding='utf-8') as f:
    text1 = f.read()

new_models = '''
class AlternativeRequest(BaseModel):
    current_exercise: str
    target_muscle: str
    goal: str = "mejorar condicion fisica"
    equipment_available: bool = True
'''
if "class AlternativeRequest" not in text1:
    text1 = text1.replace("class PlanFeedback(BaseModel):", new_models + "\\nclass PlanFeedback(BaseModel):")

new_route = '''
@router.post("/alternative")
def alternative_exercise(payload: AlternativeRequest):
    from app.services.weekly_plan import get_alternative_exercise
    alt = get_alternative_exercise(payload)
    if alt:
        return alt
    raise HTTPException(status_code=500, detail="No se pudo encontrar una alternativa.")
'''
if "/alternative" not in text1:
    text1 += new_route

with open(path1, 'w', encoding='utf-8') as f:
    f.write(text1)

# 2. Update weekly_plan.py
path2 = 'backend/app/services/weekly_plan.py'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()

new_service = '''
def get_alternative_exercise(payload) -> dict | None:
    if not configured_providers():
        return None
    try:
        equip_rule = "" if payload.equipment_available else "CRITICO: El usuario NO TIENE EQUIPO. Debe ser peso corporal (calistenia)."
        prompt = f"""
        El usuario necesita un ejercicio alternativo para '{payload.current_exercise}' que trabaja el musculo '{payload.target_muscle}'.
        Motivo: Maquina ocupada o no disponible.
        Reglas: {equip_rule}
        Debes devolver UNICAMENTE un objeto JSON valido con la estructura exacta:
        {{
            "name": "Nombre del nuevo ejercicio",
            "sets": 3,
            "reps": "10-12",
            "animation_key": "animation-key",
            "primary_muscle": "{payload.target_muscle}",
            "secondary_muscle": "Secundario"
        }}
        """
        result = generate_json_text(prompt, timeout=15)
        alt = json.loads(result.text)
        return alt
    except Exception:
        return None
'''
if "def get_alternative_exercise" not in text2:
    text2 += new_service

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)
