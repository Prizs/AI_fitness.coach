path = 'backend/app/routers/coach.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update ChatMessage model to include active_plan_start, active_plan_end, equipment_details
old_model = """class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    history: list[ChatTurn] = Field(default_factory=list, max_length=MAX_HISTORY_TURNS)
    user_goal: str | None = Field(default=None, max_length=120)
    user_level: str | None = Field(default=None, max_length=40)
    allergies: str | None = Field(default=None, max_length=1000)
    injuries: str | None = Field(default=None, max_length=1000)
    motor_disability: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)
    rpe_feedback: int | None = Field(default=None, ge=1, le=10)
    age: int | None = Field(default=None, ge=12, le=100)
    weight: float | None = Field(default=None, gt=0, le=300)"""

new_model = """class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    history: list[ChatTurn] = Field(default_factory=list, max_length=MAX_HISTORY_TURNS)
    user_goal: str | None = Field(default=None, max_length=120)
    user_level: str | None = Field(default=None, max_length=40)
    allergies: str | None = Field(default=None, max_length=1000)
    injuries: str | None = Field(default=None, max_length=1000)
    motor_disability: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)
    rpe_feedback: int | None = Field(default=None, ge=1, le=10)
    age: int | None = Field(default=None, ge=12, le=100)
    weight: float | None = Field(default=None, gt=0, le=300)
    active_plan_start: str | None = Field(default=None, max_length=50)
    active_plan_end: str | None = Field(default=None, max_length=50)
    equipment_details: str | None = Field(default=None, max_length=200)"""

text = text.replace(old_model, new_model)

# 2. Update _profile_context
old_profile = """def _profile_context(payload: ChatMessage) -> str:
    return (
        f"Edad: {payload.age if payload.age is not None else 'No indicada'}. "
        f"Peso: {payload.weight if payload.weight is not None else 'No indicado'} kg. "
        f"Meta: {payload.user_goal or 'Rendimiento general'}. "
        f"Nivel: {payload.user_level or 'Intermedio'}. "
        f"Alergias: {payload.allergies or 'Ninguna'}. "
        f"Lesiones: {payload.injuries or 'Ninguna'}. "
        f"Discapacidad motora: {payload.motor_disability or 'Ninguna'}. "
        f"Zonas a evitar: {payload.areas_to_avoid or 'Ninguna'}. "
        f"RPE reportado: {payload.rpe_feedback if payload.rpe_feedback is not None else 'no indicado'}."
    )"""

new_profile = """def _profile_context(payload: ChatMessage) -> str:
    plan_info = ""
    if payload.active_plan_start and payload.active_plan_end:
        plan_info = f" Plan actual vigente desde {payload.active_plan_start} hasta {payload.active_plan_end}."
    equip_info = f" Equipamiento reportado: {payload.equipment_details}." if payload.equipment_details else ""
    return (
        f"Edad: {payload.age if payload.age is not None else 'No indicada'}. "
        f"Peso: {payload.weight if payload.weight is not None else 'No indicado'} kg. "
        f"Meta: {payload.user_goal or 'Rendimiento general'}. "
        f"Nivel: {payload.user_level or 'Intermedio'}. "
        f"Alergias: {payload.allergies or 'Ninguna'}. "
        f"Lesiones: {payload.injuries or 'Ninguna'}. "
        f"Discapacidad motora: {payload.motor_disability or 'Ninguna'}. "
        f"Zonas a evitar: {payload.areas_to_avoid or 'Ninguna'}. "
        f"RPE reportado: {payload.rpe_feedback if payload.rpe_feedback is not None else 'no indicado'}."
        f"{plan_info}{equip_info}"
    )"""

text = text.replace(old_profile, new_profile)

# 3. Update AI prompt with strict equipment, multi-week progression, and nutrition intensity modulation
import re
prompt_pattern = r'    prompt = \(\s*"Eres un Coach de Fitness y Nutricion.*?Devuelve SOLO JSON\."\s*\)'

new_prompt = '''    prompt = (
        "Eres un Coach de Fitness y Nutricion altamente interactivo, empatico, cientifico y analitico. Responde en espanol con tono motivador pero riguroso.\\n"
        "REGLAS OBLIGATORIAS DE DISENO Y ADAPTACION:\\n"
        "1. REGLA ESTRICTA DE EQUIPAMIENTO Y HERRAMIENTAS EN CASA:\\n"
        "   - Si el usuario entrena en casa o menciona herramientas especificas (ej. 'solo mancuernas', 'bandas elasticas', 'sin equipo', 'peso corporal'):\\n"
        "   - NUNCA recomiendes maquinas de gimnasio comercial (caminadora, prensa de piernas, maquina Smith, poleas o barras olimpicas) si el usuario entrena en casa.\\n"
        "   - Si el usuario tiene mancuernas, recomienda UNICAMENTE ejercicios con mancuernas o peso corporal (ej: Sentadilla Goblet con mancuerna, Press banca con mancuernas, Zancadas con mancuernas, Peso muerto rumano con mancuernas).\\n"
        "   - Si no tiene herramientas, recomienda 100% peso corporal y calistenia (Sentadillas bulgaras, Flexiones, Plancha, Puente de gluteos, Fondos en silla).\\n"
        "   - Si el usuario dice que tiene herramientas en casa pero no especifica cuales, preguntale de inmediato: '¿Con que herramientas exactas cuentas en casa (ej. mancuernas, bandas, barra, o solo peso corporal)?' y adapta al 100% los ejercicios a esa respuesta.\\n"
        "2. REGLA DE MULTI-SEMANA Y VIGENCIA DE CRONOGRAMA:\\n"
        "   - Si el usuario ya tiene un plan activo vigente (leelo en los Datos del usuario abajo):\\n"
        "     Hazle saber con claridad: 'Tienes un plan de entrenamiento vigente desde {payload.active_plan_start} hasta {payload.active_plan_end}. Diseñaremos esta nueva fase para la proxima semana que inicia despues de esa fecha.'\\n"
        "     Esto le permite programar su siguiente ciclo con anticipacion sin pisar el entrenamiento que esta ejecutando hoy.\\n"
        "3. REGLA DE NUTRICION SINERGICA CON LA INTENSIDAD:\\n"
        "   - Adapta el plan alimenticio a la intensidad de la sesion:\\n"
        "     * Si la sesion es de ALTA INTENSIDAD: Aumenta carbohidratos complejos (avena, arroz, patata) y proteina magra post-entrenamiento para reponer glucogeno y favorecer la sintesis proteica.\\n"
        "     * Si es de INTENSIDAD MEDIA/BAJA o descanso: Plantea un menu mas ligero, rico en vegetales, fibra, grasas saludables y proteina moderada.\\n"
        "4. REGLA DE EXPERIENCIA Y MOLESTIAS/DOLOR:\\n"
        "   - Si reporta MOLESTIA/DOLOR: Abordalo de inmediato; jamas ignores un dolor. Preguntale que movimiento especifico le causa dolor y excluye cualquier ejercicio que comprometa esa articulacion o musculo, o indica descanso si es agudo.\\n"
        "   - Si es principiante/novato: Explicale amablemente la razon de los ejercicios y por que empezamos con tecnica controlada.\\n"
        "5. EJERCICIOS CON GIFS:\\n"
        "   - Cuando emitas el plan estructurado (has_plan=true), usa animation_key validas (squat, pushup, pullup, lunge, plank, bicep-curl, tricep-extension, crunch, deadlift, shoulder-press, bench-press) para que la app muestre sus animaciones correspondientes.\\n"
        "IMPORTANTE: No preguntes edad ni peso en cada mensaje (ya estan en su perfil).\\n"
        "Retorna EXCLUSIVAMENTE un objeto JSON valido:\\n"
        "{\\n"
        '  "reply": "Respuesta conversacional detallada en texto",\\n'
        '  "category": "Categoria de la fase",\\n'
        '  "duration_weeks": 4,\\n'
        '  "rest_between_sets_sec": 60,\\n'
        '  "progression_rule": "Regla de progresion concreta",\\n'
        '  "has_plan": true,\\n'
        '  "structured_plan": {\\n'
        '     "day": "Lunes",\\n'
        '     "title": "Nombre de la sesion",\\n'
        '     "exercises": [{"name": "...", "sets": 3, "reps": "12", "animation_key": "squat", "primary_muscle": "...", "secondary_muscle": "..."}],\\n'
        '     "nutrition": {"desayuno": "...", "almuerzo": "...", "cena": "..."}\\n'
        '  }\\n'
        "}\\n"
        "Si aun estan dialogando para afinar el equipo exacto o evaluar una molestia, usa has_plan=false y structured_plan=null.\\n"
        f"Datos del usuario: {_profile_context(payload)}\\n"
        f"Historial de la conversacion:\\n{_conversation_history(payload.history)}\\n"
        f"Mensaje actual del usuario: {payload.message}\\n"
        "Devuelve SOLO JSON."
    )'''

text, count = re.subn(prompt_pattern, new_prompt, text, flags=re.DOTALL)
print(f"Updated prompt occurrences: {count}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Backend coach.py successfully updated with multi-week, equipment, and nutrition synergy rules!")
