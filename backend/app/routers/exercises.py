from fastapi import APIRouter
import json
import os
import re
import unicodedata
from typing import Optional

router = APIRouter()

# Load DB
db_path = os.path.join(os.path.dirname(__file__), '..', 'gifs_db.json')
with open(db_path, 'r', encoding='utf-8') as f:
    gif_paths: list[str] = json.load(f)

BASE_GIF_URL = "https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/"

STOPWORDS = {
    "con", "sin", "para", "por", "del", "las", "los", "una", "uno", "unos", "unas",
    "sobre", "hacia", "desde", "entre", "hasta", "como", "mas", "pero", "sus",
    "nivel", "intensidad", "ejercicio", "ejercicios", "rutina", "sesion", "dia",
}


def _strip_accents(text: str) -> str:
    return "".join(
        c for c in unicodedata.normalize("NFD", text)
        if unicodedata.category(c) != "Mn"
    )


def _normalize(text: str) -> str:
    cleaned = _strip_accents((text or "").lower())
    cleaned = re.sub(r"[^a-z0-9\s]", " ", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned


def classify_intensity(query: str, intensity_hint: Optional[str] = None) -> dict:
    """Analiza el nombre del ejercicio y la preferencia del usuario para clasificar la intensidad."""
    q = _normalize(query)
    hint = _normalize(intensity_hint or "")

    high_keywords = (
        "barra olimpica", "sentadilla profunda con barra", "barbell full squat",
        "peso muerto con barra", "barbell deadlift", "pliometric", "plyo",
        "salto", "jump", "pistol", "bulgara", "zercher", "snatch", "clean",
        "jerk", "muscle up", "lastrad", "weighted", "pesad", "explosiv",
        "alta intensidad", "avanzad",
    )
    low_keywords = (
        "peso corporal", "bodyweight", "sin peso", "silla", "chair", "asistid",
        "assisted", "suave", "liger", "basico", "principiante", "novato",
        "banda", "elastica", "band", "puente", "bridge", "suelo", "floor",
        "pared", "wall", "estiramiento", "stretch", "movilidad", "isometric",
        "elevacion de talones de pie", "marcha", "caminata", "estatica",
        "baja intensidad",
    )
    mid_keywords = (
        "mancuerna", "dumbbell", "goblet", "copa", "maquina", "machine",
        "lever", "prensa", "leg press", "sled", "polea", "cable", "smith",
        "peso muerto rumano", "romanian", "step up", "cajon", "barra vacia",
        "intermedi", "media",
    )

    # Prioridad a indicadores explícitos del nombre del ejercicio si son muy claros
    if any(k in q for k in ("peso corporal", "bodyweight", "silla", "asistid", "suave", "banda", "puente de gluteo", "puente de cadera", "sin peso", "estatica")):
        if "barra" not in q and "salto" not in q and "jump" not in q:
            return {
                "code": "baja",
                "label": "Básico (Intensidad Baja)",
                "tempo": "3s bajada controlada · 1s pausa · 2s subida suave",
            }

    if any(k in q for k in ("salto", "jump", "pliometric", "pistol", "zercher", "muscle up", "profunda con barra")):
        return {
            "code": "alta",
            "label": "Avanzado (Intensidad Alta)",
            "tempo": "2s excéntrico · 0s pausa · 1s concéntrico explosivo",
        }

    if any(k in q for k in mid_keywords):
        if "baja" in hint or "principiante" in hint or "novato" in hint:
            # Si el usuario pidió baja pero el ejercicio dice barra vacía o máquina suave
            if "barra vacia" in q or "peso corporal" in q:
                return {
                    "code": "baja",
                    "label": "Básico (Intensidad Baja)",
                    "tempo": "3s bajada controlada · 1s pausa · 2s subida suave",
                }
        return {
            "code": "media",
            "label": "Intermedio (Intensidad Media)",
            "tempo": "3s excéntrico · 1s pausa isométrica · 1s concéntrico",
        }

    # Si el hint del usuario lo define
    if any(k in hint for k in ("baja", "basico", "principiante", "novato", "low")):
        return {
            "code": "baja",
            "label": "Básico (Intensidad Baja)",
            "tempo": "3s bajada controlada · 1s pausa · 2s subida suave",
        }
    if any(k in hint for k in ("alta", "avanzad", "high", "intenso")):
        return {
            "code": "alta",
            "label": "Avanzado (Intensidad Alta)",
            "tempo": "2s excéntrico · 1s pausa · 1s concéntrico potente",
        }

    if any(k in q for k in low_keywords):
        return {
            "code": "baja",
            "label": "Básico (Intensidad Baja)",
            "tempo": "3s bajada controlada · 1s pausa · 2s subida suave",
        }
    if any(k in q for k in high_keywords):
        return {
            "code": "alta",
            "label": "Avanzado (Intensidad Alta)",
            "tempo": "2s excéntrico · 1s pausa · 1s concéntrico potente",
        }

    return {
        "code": "media",
        "label": "Intermedio (Intensidad Media)",
        "tempo": "3s excéntrico · 1s pausa · 1s concéntrico",
    }


def _detect_target_folders(query: str, muscle: Optional[str] = None) -> list[str]:
    """Determina estrictamente las carpetas anatómicas permitidas para evitar mezclar piernas con tórax/brazos."""
    norm_q = _normalize(query)
    norm_m = _normalize(muscle or "")
    combined = f"{norm_q} {norm_m}".strip()

    # 0. Reglas prioritarias que contienen palabras de piernas o flexiones pero pertenecen a Core, Brazos o Cardio
    if any(w in combined for w in ("elevacion de pierna", "elevacion de piernas", "elevaciones de piernas", "leg raise", "piernas en suelo", "piernas en banco", "piernas al pecho")):
        return ["abs"]
    if any(w in combined for w in ("giro ruso", "giros rusos", "russian twist", "rotacion rusa")):
        return ["abs"]
    if any(w in combined for w in ("flexion diamante", "flexiones diamante", "diamond push")):
        return ["triceps"]
    if any(w in combined for w in ("flexion en pica", "flexiones en pica", "pike push")):
        return ["delts", "pectorals"]
    if any(w in combined for w in ("jumping jack", "jumping jacks", "salto en tijera", "saltos en tijera")):
        return ["cardio"]
    if any(w in combined for w in ("escalador", "escaladores", "mountain climber", "mountain climbers")):
        return ["cardio", "abs"]
    if any(w in combined for w in ("patada de gluteo", "patada de gluteos", "glute kickback", "patada en cuadrupedia")):
        return ["glutes"]
    if any(w in combined for w in ("wall sit", "sentadilla en pared", "sentadilla isometrica en pared")):
        return ["glutes", "quads"]

    # 1. Reglas prioritarias de Brazos (Tríceps y Bíceps) para evitar colisión con 'flexión'
    if any(w in combined for w in ("triceps", "tricep", "fondo", "dips", "dip", "copa", "press frances", "rompecraneos", "skull", "pushdown", "patada de triceps")):
        return ["triceps"]
    if any(w in combined for w in ("biceps", "bicep", "martillo", "hammer curl", "predicador", "preacher", "curl con barra")):
        return ["biceps", "forearms"]
    if any(w in combined for w in ("antebrazo", "muneca", "forearm", "wrist")):
        return ["forearms"]

    # 2. Reglas específicas de Tren Inferior (Piernas y Glúteos)
    if any(w in combined for w in ("isquio", "femoral", "hamstring", "curl de pierna", "leg curl", "buenos dias", "good morning")):
        return ["hamstrings", "glutes"]
    if any(w in combined for w in ("gemelo", "pantorrilla", "talon", "calf", "calves", "soleo", "tibial")):
        return ["calves"]
    if any(w in combined for w in ("abductor", "abduccion", "abduct")):
        return ["abductors", "glutes"]
    if any(w in combined for w in ("aductor", "aduccion", "adduct")):
        return ["adductors", "quads"]
    if any(w in combined for w in ("puente", "bridge", "hip thrust", "gluteo", "glute", "patada")):
        if not any(w in combined for w in ("sentadilla", "squat", "prensa", "zancada", "lunge", "extension")):
            return ["glutes", "hamstrings"]
    if any(w in combined for w in (
        "sentadilla", "squat", "zancada", "desplante", "lunge", "prensa", "leg press",
        "cuadriceps", "quad", "extension de pierna", "extension de cuadriceps",
        "leg extension", "step up", "subida al cajon", "pierna", "tren inferior",
        "peso muerto", "deadlift", "bulgara", "hack", "sissy"
    )):
        return ["quads", "glutes", "hamstrings", "calves", "abductors", "adductors"]

    # 3. Reglas de Tren Superior y Core
    if any(w in combined for w in ("pectoral", "pecho", "bench press", "press de banca", "flexion de pecho", "flexiones de pecho", "flexiones", "push up", "pushup", "aperturas", "fly")):
        return ["pectorals", "serratus-anterior"]
    if any(w in combined for w in ("dorsal", "dominada", "pull up", "pullup", "jalon", "pulldown", "remo", "row", "espalda", "back")):
        return ["lats", "upper-back", "traps", "spine"]
    if any(w in combined for w in ("deltoides", "hombro", "shoulder", "press militar", "military press", "elevacion lateral", "lateral raise", "elevacion frontal", "pajaro", "arnold")):
        return ["delts", "traps"]
    if any(w in combined for w in ("abdomen", "abdominal", "core", "plancha", "plank", "crunch", "oblicuo", "russian twist", "dead bug", "lumbar", "superman")):
        return ["abs", "spine"]
    if any(w in combined for w in ("cardio", "burpee", "jumping jack", "trote", "correr", "bicicleta", "caminata", "marcha", "mountain climber", "escalador")):
        return ["cardio", "quads", "glutes"]

    return []


# Mapeo curado de ejercicios arquetípicos por patrón de movimiento e intensidad (baja, media, alta)
CURATED_BY_INTENSITY = [
    # 1. Puentes de Glúteo e Isquios / Hip Thrust
    {
        "match_any": ("puente de gluteo", "puente de gluteos", "puente de cadera", "puente de isquio", "glute bridge", "hip thrust", "elevacion pelvica"),
        "exclude_any": (),
        "gifs": {
            "baja": "glutes/low-glute-bridge-on-floor.gif",
            "media": "glutes/glute-bridge-two-legs-on-bench-male.gif",
            "alta": "glutes/barbell-glute-bridge.gif",
        },
        "biomechanics": "Extensión de cadera activando glúteo mayor e isquiotibiales en rango horizontal seguro.",
        "posture": "Empuje desde los talones, costillas bajas y pausa de 2 segundos en contracción máxima.",
        "warning": "No hiperextiendas la columna lumbar arriba; el movimiento debe nacer de la cadera.",
    },
    # 2. Buenos Días (Good Morning / Hip Hinge)
    {
        "match_any": ("buenos dias", "good morning", "buenos d"),
        "exclude_any": (),
        "gifs": {
            "baja": "glutes/band-straight-back-stiff-leg-deadlift.gif",
            "media": "hamstrings/barbell-good-morning.gif",
            "alta": "hamstrings/barbell-good-morning.gif",
        },
        "biomechanics": "Bisagra de cadera flexionando el torso hacia adelante con columna neutra y manos tras nuca o carga dorsal.",
        "posture": "Espalda recta, flexión mínima de rodillas y desplazamiento de cadera hacia atrás.",
        "warning": "Detén el descenso si se redondea la zona lumbar.",
    },
    # 3. Fondos de Tríceps (Chair Dips / Bench Dips)
    {
        "match_any": ("fondo de triceps", "fondos de triceps", "fondos en silla", "fondo en silla", "fondos entre bancos", "bench dip", "chair dip", "triceps dip", "fondos de pecho y triceps"),
        "exclude_any": ("paralelas con lastre",),
        "gifs": {
            "baja": "triceps/bench-dip-knees-bent.gif",
            "media": "triceps/bench-dip-on-floor.gif",
            "alta": "triceps/triceps-dip.gif",
        },
        "biomechanics": "Flexión y extensión de codos con apoyo posterior en silla o banco activando las tres cabezas del tríceps.",
        "posture": "Hombros deprimidos hacia abajo y lejos de las orejas; espalda pegada al borde de apoyo.",
        "warning": "No desciendas más allá de 90° de flexión en el codo para no sobrecargar el hombro anterior.",
    },
    # 4a. Curl Femoral en Suelo con Deslizador / Toalla (Hamstring Slide)
    {
        "match_any": ("deslizador", "toalla en piso", "toalla en suelo", "piso liso", "curl femoral en suelo", "femoral en suelo", "slide curl", "deslizante", "curl de piernas deslizante"),
        "exclude_any": ("maquina", "máquina", "lever"),
        "gifs": {
            "baja": "https://ai-fitness-coach-wlg3.onrender.com/static/sliding-leg-curl-on-floor-with-towel.gif",
            "media": "https://ai-fitness-coach-wlg3.onrender.com/static/sliding-leg-curl-on-floor-with-towel.gif",
            "alta": "https://ai-fitness-coach-wlg3.onrender.com/static/sliding-leg-curl-on-floor-with-towel.gif",
        },
        "biomechanics": "Flexión activa de rodillas en decúbito supino elevando la cadera en puente y deslizando los talones sobre la toalla hacia los glúteos.",
        "posture": "Pelvis en retroversión manteniendo el puente glúteo elevado sin arquear la zona lumbar, glúteos e isquiotibiales contraídos en el punto máximo.",
        "warning": "Evita dejar caer la pelvis al suelo durante la flexión; el movimiento debe ser fluido y continuo desde los isquiotibiales.",
    },
    # 4. Curl Femoral / Isquiotibiales (Hamstring Curls)
    {
        "match_any": ("curl femoral", "curl de isquiotibial", "curl de isquiotibiales", "curl de pierna", "leg curl", "curl nordico", "nordic curl"),
        "exclude_any": (),
        "gifs": {
            "baja": "hamstrings/standing-single-leg-curl.gif",
            "media": "hamstrings/lever-seated-leg-curl.gif",
            "alta": "hamstrings/lever-lying-leg-curl.gif",
        },
        "biomechanics": "Flexión aislada de la rodilla reclutando bíceps femoral, semitendinoso y semimembranoso.",
        "posture": "Pelvis fija contra el suelo o asiento sin arquear la zona lumbar.",
        "warning": "Controla la fase excéntrica con bajada lenta de 3 segundos.",
    },
    # 5. Peso Muerto (Deadlift / RDL)
    {
        "match_any": ("peso muerto", "deadlift", "romanian deadlift", "rdl"),
        "exclude_any": ("buenos dias",),
        "gifs": {
            "baja": "glutes/band-stiff-leg-deadlift.gif",
            "media": "glutes/dumbbell-romanian-deadlift.gif",
            "alta": "glutes/barbell-deadlift.gif",
        },
        "biomechanics": "Patrón de bisagra de cadera con activación de la cadena posterior completa.",
        "posture": "Escápulas retraídas, abdomen firme y columna completamente neutra.",
        "warning": "Jamás redondees la zona lumbar al descender.",
    },
    # 6. Sentadilla Búlgara / Split Squat
    {
        "match_any": ("bulgara", "split squat", "sentadilla dividida"),
        "exclude_any": (),
        "gifs": {
            "baja": "quads/split-squats.gif",
            "media": "quads/dumbbell-single-leg-split-squat.gif",
            "alta": "quads/barbell-single-leg-split-squat.gif",
        },
        "biomechanics": "Trabajo unilateral enfocado en cuádriceps y glúteo con pie trasero elevado en silla o banco.",
        "posture": "Torso ligeramente inclinado hacia adelante (~15°) para alinear la cadera.",
        "warning": "Mantén la rodilla delantera estable sin oscilar lateralmente.",
    },
    # 7. Sentadillas con salto / Pliométrico
    {
        "match_any": ("sentadilla con salto", "jump squat", "salto controlado", "sentadillas con salto"),
        "exclude_any": (),
        "gifs": {
            "baja": "quads/split-squats.gif",
            "media": "glutes/jump-squat.gif",
            "alta": "glutes/bodyweight-drop-jump-squat.gif",
        },
        "biomechanics": "Triple extensión explosiva de tobillos, rodillas y cadera con aterrizaje suave.",
        "posture": "Aterriza primero sobre metatarsos amortiguando con flexión fluida.",
        "warning": "Evitar en caso de dolor articular en rodillas o tobillos.",
    },
    # 7b. Sentadilla Isométrica en Pared (Wall Sit)
    {
        "match_any": ("wall sit", "sentadilla en pared", "sentadilla isometrica en pared", "isometria en pared", "silla en pared"),
        "exclude_any": (),
        "gifs": {
            "baja": "glutes/march-sit-wall.gif",
            "media": "glutes/march-sit-wall.gif",
            "alta": "glutes/march-sit-wall.gif",
        },
        "biomechanics": "Sujeción isométrica con muslos paralelos al suelo y espalda apoyada en pared reclutando cuádriceps sin impacto.",
        "posture": "Ángulo de 90° en caderas y rodillas; espalda completa pegada a la pared.",
        "warning": "No apoyes las manos sobre los muslos ni permitas que las rodillas sobrepasen las puntas de los pies.",
    },
    # 8. Sentadillas Libres / Goblet / Profundas (Squats)
    {
        "match_any": ("sentadilla", "squat"),
        "exclude_any": ("bulgara", "split", "salto", "jump", "hack", "sissy", "pared", "wall"),
        "gifs": {
            "baja": "glutes/potty-squat-with-support.gif",
            "media": "quads/dumbbell-goblet-squat.gif",
            "alta": "glutes/barbell-full-squat.gif",
        },
        "biomechanics": "Flexión controlada de rodillas y cadera manteniendo columna neutra.",
        "posture": "Pecho erguido, mirada al frente y rodillas alineadas con las puntas de los pies.",
        "warning": "Prioriza el control y la alineación antes que la profundidad.",
    },
    # 8B. Zancadas con Salto (Jumping Lunges / Split Jumps)
    {
        "match_any": ("zancada con salto", "zancadas con salto", "zancadas dinamicas con salto", "zancadas dinámicas con salto", "jumping lunge", "split jump"),
        "exclude_any": (),
        "gifs": {
            "baja": "cardio/jack-jump-male.gif",
            "media": "cardio/jack-jump-male.gif",
            "alta": "cardio/burpee.gif",
        },
        "biomechanics": "Salto pliométrico alternando piernas en el aire para recepción elástica en zancada, elevando la frecuencia cardíaca.",
        "posture": "Aterrizaje suave sobre antepié y talón con absorción muscular de rodillas flexionadas.",
        "warning": "Evita el impacto si tienes antecedentes de dolor de rodilla o ligamentos.",
    },
    # 9. Zancadas / Lunges
    {
        "match_any": ("zancada", "desplante", "lunge", "estocada"),
        "exclude_any": (),
        "gifs": {
            "baja": "glutes/forward-lunge-male.gif",
            "media": "glutes/dumbbell-lunge.gif",
            "alta": "glutes/barbell-lunge.gif",
        },
        "biomechanics": "Paso controlado formando ángulos de 90° en ambas rodillas.",
        "posture": "Tronco recto, pelvis neutra y empuje con el talón delantero.",
        "warning": "Frena la rodilla trasera a 2-3 cm del suelo sin golpearla.",
    },
    # 10. Prensa de Piernas (Leg Press)
    {
        "match_any": ("prensa", "leg press"),
        "exclude_any": ("gemelo", "pantorrilla", "talon", "calf"),
        "gifs": {
            "baja": "quads/lever-alternate-leg-press.gif",
            "media": "glutes/sled-45-leg-press.gif",
            "alta": "glutes/sled-45-leg-wide-press.gif",
        },
        "biomechanics": "Empuje de cadena cerrada con espalda soportada reduciendo carga axial.",
        "posture": "Sacro pegado al respaldo; pies al ancho de hombros.",
        "warning": "NUNCA bloquees las rodillas por completo en la extensión.",
    },
    # 11. Extensión de Cuádriceps (Leg Extension)
    {
        "match_any": ("extension de cuadriceps", "extension de pierna", "leg extension", "cuadriceps en maquina", "extension de rodilla"),
        "exclude_any": (),
        "gifs": {
            "baja": "quads/resistance-band-leg-extension.gif",
            "media": "quads/lever-leg-extension.gif",
            "alta": "quads/lever-leg-extension.gif",
        },
        "biomechanics": "Extensión de rodilla en cadena abierta estimulando el recto femoral y vastos.",
        "posture": "Espalda firme contra el respaldo y rodillas alineadas con el eje de rotación.",
        "warning": "Evita movimientos bruscos; haz pausa arriba de 1 segundo.",
    },
    # 12. Elevación de Talones Unipodal (Single Leg Calf Raise)
    {
        "match_any": ("talon unipodal", "talones unipodal", "pantorrilla unipodal", "gemelo unipodal", "unipodal en escalon", "talones a una pierna", "talon a una pierna", "unipodales lentas"),
        "exclude_any": (),
        "gifs": {
            "baja": "calves/band-single-leg-calf-raise.gif",
            "media": "calves/dumbbell-single-leg-calf-raise.gif",
            "alta": "calves/single-leg-calf-raise-on-a-dumbbell.gif",
        },
        "biomechanics": "Flexión plantar unilateral estimulando gastrocnemio y estabilizadores del tobillo.",
        "posture": "Apoyo metatarsiano en el borde del escalón y descenso lento sintiendo estiramiento.",
        "warning": "No aceleres la bajada excéntrica.",
    },
    # 13. Elevación de Talones Sentado / Sóleo (Seated Calf / Soleus)
    {
        "match_any": ("talon sentado", "talones sentado", "soleo sentado", "soleo en silla", "talones en silla", "seated calf", "batatas sentado", "batata sentado", "en cuclillas asistido"),
        "exclude_any": (),
        "gifs": {
            "baja": "calves/seated-calf-stretch-male.gif",
            "media": "calves/lever-seated-calf-raise.gif",
            "alta": "calves/barbell-seated-calf-raise.gif",
        },
        "biomechanics": "Flexión plantar con rodillas flexionadas aislando el músculo sóleo profundo.",
        "posture": "Pausa de 1 segundo arriba y bajada controlada sin rebotar.",
        "warning": "Evita el rebote elástico; controla el movimiento muscularmente.",
    },
    # 14. Elevación de Talones de Pie / Gemelos General
    {
        "match_any": ("elevacion de talones", "elevaciones de talones", "talon de pie", "talones de pie", "gemelo", "gemelos", "pantorrilla", "pantorrillas", "calf raise", "batata", "soleo"),
        "exclude_any": ("sentadilla", "squat", "prensa", "lunge", "remo", "invertido", "mesa", "toalla", "deslizador", "curl", "banca", "pushup"),
        "gifs": {
            "baja": "calves/bodyweight-standing-calf-raise.gif",
            "media": "calves/dumbbell-standing-calf-raise.gif",
            "alta": "calves/lever-standing-calf-raise.gif",
        },
        "biomechanics": "Flexión plantar de pie reclutando ambas cabezas del gastrocnemio.",
        "posture": "Cuerpo alineado, empuje sobre el primer y segundo metatarso.",
        "warning": "Rango de recorrido completo sin balanceo de cadera.",
    },
    # 15. Flexiones en Pica (Pike Push-ups)
    {
        "match_any": ("flexiones en pica", "flexion en pica", "pike push", "pike-push", "pino asistidas", "handstand"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/band-shoulder-press.gif",
            "media": "delts/band-shoulder-press.gif",
            "alta": "triceps/handstand-push-up.gif",
        },
        "biomechanics": "Empuje vertical en inversión con peso corporal estimulando deltoides anterior, superior y tríceps.",
        "posture": "Cadera elevada formando una V invertida; cabeza desciende suavemente por delante de las manos.",
        "warning": "Mantén los codos en ángulo de 45° sin abrirlos excesivamente hacia afuera.",
    },
    # 16. Flexiones Diamante (Diamond Push-ups)
    {
        "match_any": ("flexiones diamante", "flexion diamante", "diamond push", "flexion manos juntas"),
        "exclude_any": (),
        "gifs": {
            "baja": "triceps/close-grip-push-up-on-knees.gif",
            "media": "triceps/diamond-push-up.gif",
            "alta": "triceps/diamond-push-up.gif",
        },
        "biomechanics": "Flexión de pecho con manos juntas formando un diamante bajo el esternón, maximizando la carga sobre las tres cabezas del tríceps.",
        "posture": "Manos juntas en el centro del pecho, codos rozando las costillas y abdomen activo.",
        "warning": "Si sientes molestia en muñecas, separa ligeramente los dedos o apóyate en rodillas.",
    },
    # 16b. Flexiones Declinadas con Pies Elevados (Decline Push-ups)
    {
        "match_any": ("flexiones declinadas", "flexion declinada", "decline push up", "decline push-up", "decline pushup", "pies en cama o sofa", "pies elevados en cama"),
        "exclude_any": ("pica", "pike", "diamante"),
        "gifs": {
            "baja": "pectorals/incline-push-up.gif",
            "media": "pectorals/decline-push-up.gif",
            "alta": "pectorals/decline-push-up.gif",
        },
        "biomechanics": "Empuje declinado con pies elevados enfocando el estímulo en el haz clavicular del pectoral mayor y deltoides anterior.",
        "posture": "Pies sobre superficie elevada firme, cuerpo alineado en plancha y core contraído.",
        "warning": "No permitas que la cadera se hunda durante el descenso.",
    },
    # 17. Flexiones de Pecho Estándar (Push-ups)
    {
        "match_any": ("flexiones de pecho", "flexion de pecho", "push up", "push-up", "pushup", "lagartija", "flexiones en suelo", "flexiones inclinadas"),
        "exclude_any": ("pica", "pike", "diamante", "declinada", "declinadas", "decline", "pies en"),
        "gifs": {
            "baja": "pectorals/incline-push-up.gif",
            "media": "pectorals/push-up.gif",
            "alta": "pectorals/barbell-bench-press.gif",
        },
        "biomechanics": "Empuje horizontal de cadena cerrada activando pectoral mayor, deltoides anterior y tríceps.",
        "posture": "Cuerpo en línea recta desde los talones hasta la coronilla, abdomen y glúteos activos.",
        "warning": "No dejes caer la pelvis ni arquees la columna lumbar.",
    },
    # 18. Press de Banca / Pecho con Mancuernas o Barra
    {
        "match_any": ("press de banca", "bench press", "press de pecho", "press plano", "press inclinado", "press declinado"),
        "exclude_any": ("flexion", "push up"),
        "gifs": {
            "baja": "pectorals/incline-push-up.gif",
            "media": "pectorals/dumbbell-bench-press.gif",
            "alta": "pectorals/barbell-bench-press.gif",
        },
        "biomechanics": "Empuje horizontal reclutando pectoral mayor y tríceps con soporte dorsal.",
        "posture": "Retracción escapular activa y pies firmes contra el suelo.",
        "warning": "No rebotes la barra contra el pecho ni hiperextiendas muñecas.",
    },
    # 19. Extensiones de Tríceps (Tricep Extensions / Pushdown / Press Francés)
    {
        "match_any": ("extension de triceps", "extensiones de triceps", "press frances", "patada de triceps", "triceps tras nuca", "tricep extension"),
        "exclude_any": ("fondo", "dip"),
        "gifs": {
            "baja": "triceps/bench-dip-knees-bent.gif",
            "media": "triceps/cable-alternate-triceps-extension.gif",
            "alta": "triceps/barbell-lying-triceps-extension.gif",
        },
        "biomechanics": "Extensión aislada del codo reclutando la cabeza larga, lateral y medial del tríceps.",
        "posture": "Codos fijos a los lados del torso sin balanceo de hombros.",
        "warning": "Controla el retorno excéntrico sin abrir los codos hacia afuera.",
    },
    # 20. Curl de Bíceps (Biceps Curl / Martillo / Barra)
    {
        "match_any": ("curl de biceps", "curl de bicep", "curl alterno", "curl martillo", "curl concentrado", "bicep curl", "biceps curl", "curl con barra"),
        "exclude_any": ("femoral", "isquio", "pierna", "nordic"),
        "gifs": {
            "baja": "biceps/band-alternating-biceps-curl.gif",
            "media": "biceps/dumbbell-biceps-curl.gif",
            "alta": "biceps/barbell-curl.gif",
        },
        "biomechanics": "Flexión de codo en supinación o agarre neutro estimulando bíceps braquial y braquiorradial.",
        "posture": "Codos pegados a los costados del torso, sin balancear la espalda.",
        "warning": "Evita impulsarte con la cadera; mantén el torso vertical.",
    },
    # 21. Elevaciones Laterales (Lateral Raises)
    {
        "match_any": ("elevacion lateral", "elevaciones laterales", "lateral raise"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/band-front-lateral-raise.gif",
            "media": "delts/dumbbell-lateral-raise.gif",
            "alta": "delts/dumbbell-lateral-raise.gif",
        },
        "biomechanics": "Abducción de hombros en el plano escapular enfocada en el deltoides lateral.",
        "posture": "Codos ligeramente flexionados, elevación hasta la altura de los hombros.",
        "warning": "No encojas los hombros hacia las orejas durante la subida.",
    },
    # 22. Press Militar / Hombros (Shoulder Press)
    {
        "match_any": ("press militar", "press de hombro", "shoulder press", "press arnold"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/band-shoulder-press.gif",
            "media": "delts/dumbbell-seated-shoulder-press.gif",
            "alta": "delts/barbell-seated-overhead-press.gif",
        },
        "biomechanics": "Empuje vertical por encima de la cabeza reclutando deltoides y tríceps.",
        "posture": "Core comprimido y glúteos firmes para evitar arquear la columna lumbar.",
        "warning": "Evita hiperextender el cuello o arquear excesivamente la espalda.",
    },
    # 23a. Pájaros Posteriores / Reverse Fly / Rear Delt
    {
        "match_any": ("pajaro", "pajaros", "reverse fly", "rear delt", "deltoides posterior", "pajaro posterior", "pajaros posteriores"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/band-reverse-fly.gif",
            "media": "delts/dumbbell-rear-delt-raise.gif",
            "alta": "delts/dumbbell-rear-fly.gif",
        },
        "biomechanics": "Abducción horizontal del hombro focalizada en deltoides posterior, romboides y trapecio medio.",
        "posture": "Torso inclinado en bisagra con columna neutra; codos con ligera flexión fija guiando el ascenso.",
        "warning": "No encojas los hombros hacia el cuello ni uses balanceo del torso.",
    },
    # 23b. Retracción Escapular / Prone Y-T-W / Elevaciones en Y
    {
        "match_any": ("retraccion escapular", "prone y-t-w", "y-t-w", "y raise", "elevaciones en y", "prone w", "prone y"),
        "exclude_any": ("elevacion en t", "elevaciones en t"),
        "gifs": {
            "baja": "delts/band-y-raise.gif",
            "media": "delts/band-y-raise.gif",
            "alta": "delts/band-y-raise.gif",
        },
        "biomechanics": "Rotación externa y depresión escapular en el plano escapular estimulando deltoides posterior y trapecio inferior.",
        "posture": "Boca abajo o de pie con tronco erguido, pulgares apuntando hacia arriba al elevar los brazos.",
        "warning": "Mantén el mentón retraído y el cuello relajado sin hiperextensión cervical.",
    },
    # 23b2. Elevaciones en T (T-Raises / Tensión Isométrica)
    {
        "match_any": ("elevacion en t", "elevaciones en t", "t raise", "t-raise", "t con toalla"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/dumbbell-incline-t-raise.gif",
            "media": "delts/dumbbell-incline-t-raise.gif",
            "alta": "delts/dumbbell-incline-t-raise.gif",
        },
        "biomechanics": "Abducción horizontal isométrica en línea T estimulando deltoides lateral, deltoides posterior y romboides.",
        "posture": "Brazos alineados a la horizontal perpendicular al torso, escápulas conectadas y cuello neutro.",
        "warning": "No arquees la espalda baja al mantener la tensión.",
    },
    # 23c. Círculos de Brazos / Rotaciones de Hombros (Arm Circles)
    {
        "match_any": ("circulo de brazo", "circulos de brazos", "arm circle", "arm circles", "rotacion de hombro", "rotaciones de hombros", "circulos controlados"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/weighted-round-arm.gif",
            "media": "delts/weighted-round-arm.gif",
            "alta": "delts/weighted-round-arm.gif",
        },
        "biomechanics": "Circunducción continua de la articulación glenohumeral activando las tres cabezas del deltoides y manguito rotador sin sobrecarga articular.",
        "posture": "Brazos estirados a la altura de los hombros formando pequeños círculos controlados con escápulas estables.",
        "warning": "Evita balancear el torso o arquear la zona lumbar; mantén el abdomen activo.",
    },
    # 23d. Deslizamientos en Pared / Wall Slides / Movilidad de Hombro
    {
        "match_any": ("deslizamiento en pared", "deslizamientos en pared", "wall slide", "wall slides", "movilidad de hombro", "movilidad de hombros", "estiramiento de hombro", "deslizamiento de brazos"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/rear-deltoid-stretch.gif",
            "media": "delts/rear-deltoid-stretch.gif",
            "alta": "delts/rear-deltoid-stretch.gif",
        },
        "biomechanics": "Deslizamiento ascendente en pared desde posición W a Y reclutando deltoides y serrato anterior, optimizando el ritmo escapulohumeral.",
        "posture": "Espalda y antebrazos en contacto firme contra la pared, manteniendo la pelvis neutra.",
        "warning": "Detén la subida si los antebrazos se despegan de la pared o si sientes pellizco en el hombro.",
    },
    # 23e. Elevaciones Frontales (Front Raise)
    {
        "match_any": ("elevacion frontal", "elevaciones frontales", "front raise", "elevaciones frontales suaves"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/band-front-raise.gif",
            "media": "delts/dumbbell-front-raise.gif",
            "alta": "delts/barbell-front-raise.gif",
        },
        "biomechanics": "Flexión anterior del hombro reclutando directamente el fascículo clavicular del deltoides.",
        "posture": "Tronco vertical, ascenso controlado hasta la horizontal visual y descenso en 3 segundos.",
        "warning": "No arquees la zona lumbar al elevar los brazos.",
    },
    # 24a. Tracción Dorsal / Remo con Toalla en Marco de Puerta (Towel Door Row)
    {
        "match_any": ("toalla en marco", "remo con toalla", "traccion dorsal con toalla", "traccion con toalla", "towel row", "bodyweight row with towel", "toalla en puerta", "con toalla"),
        "exclude_any": ("polea", "cable", "maquina"),
        "gifs": {
            "baja": "upper-back/bodyweight-standing-row-with-towel.gif",
            "media": "upper-back/bodyweight-standing-one-arm-row-with-towel.gif",
            "alta": "upper-back/one-arm-towel-row.gif",
        },
        "biomechanics": "Tracción horizontal con peso corporal usando una toalla anclada al marco de puerta, activando dorsal ancho y romboides sin herramientas de gimnasio.",
        "posture": "Torso inclinado en línea recta, empuje firme de talones contra el suelo y retracción escapular activa.",
        "warning": "Asegúrate de que la toalla o anclaje esté firme y la puerta asegurada para evitar deslizamientos.",
    },
    # 24_inv. Remo Invertido (Inverted Row bajo mesa o barra)
    {
        "match_any": ("remo invertido", "inverted row", "bajo mesa"),
        "exclude_any": (),
        "gifs": {
            "baja": "upper-back/inverted-row-bent-knees.gif",
            "media": "upper-back/inverted-row.gif",
            "alta": "upper-back/front-lever-reps.gif",
        },
        "biomechanics": "Tracción horizontal de cadena cerrada activando dorsal ancho, romboides, trapecio medio y bíceps.",
        "posture": "Cuerpo en plancha firme, core activo y retracción escapular al subir el pecho hacia la superficie.",
        "warning": "Asegura la firmeza del apoyo o agarre y mantén columna neutra.",
    },
    # 24_swim. Natación Estática en Suelo / Swimmers
    {
        "match_any": ("swimmers", "swimmer", "natacion estatica", "natacion en suelo", "nadador en suelo"),
        "exclude_any": (),
        "gifs": {
            "baja": "lats/band-close-grip-pulldown.gif",
            "media": "upper-back/band-one-arm-twisting-seated-row.gif",
            "alta": "lats/pull-up.gif",
        },
        "biomechanics": "Extensión torácica en decúbito prono activando erectores espinales, dorsal ancho y cadena posterior.",
        "posture": "Mirada hacia el suelo, cuello neutro, movimiento alternado de brazos y piernas sin arquear la zona lumbar.",
        "warning": "No hiperextiendas el cuello; la contracción proviene de la musculatura dorsal.",
    },
    # 24_paj. Pájaros Escapulares en Decúbito Prono
    {
        "match_any": ("pajaro escapular", "pajaros escapulares", "pajaro en decubito", "pajaros en decubito"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/band-reverse-fly.gif",
            "media": "delts/dumbbell-rear-delt-raise.gif",
            "alta": "delts/dumbbell-rear-fly.gif",
        },
        "biomechanics": "Abducción horizontal focalizada en deltoides posterior, romboides y trapecio medio.",
        "posture": "Torso estable en suelo boca abajo, elevación controlada juntando escápulas sin tensión cervical.",
        "warning": "Evita elevar los hombros hacia las orejas; enfoca el esfuerzo en la retracción escapular.",
    },
    # 24_slide. Back Slides / Deslizamiento Dorsal Escapular
    {
        "match_any": ("back slide", "back slides", "deslizamiento dorsal"),
        "exclude_any": (),
        "gifs": {
            "baja": "upper-back/band-one-arm-twisting-seated-row.gif",
            "media": "upper-back/cable-low-seated-row.gif",
            "alta": "upper-back/inverted-row.gif",
        },
        "biomechanics": "Aducción y depresión escapular en suelo reclutando dorsal ancho y serrato.",
        "posture": "Espalda plana contra el suelo, codos flexionados deslizándose controladamente.",
        "warning": "Mantén la zona lumbar en contacto con el suelo sin arquearte.",
    },
    # 24. Remos / Jalón Dorsal (Rows / Pulls)
    {
        "match_any": ("remo", "row", "jalon", "jalón", "pulldown", "dominada", "pull up", "pull-up", "traccion dorsal"),
        "exclude_any": ("toalla", "towel"),
        "gifs": {
            "baja": "upper-back/band-one-arm-twisting-seated-row.gif",
            "media": "upper-back/cable-low-seated-row.gif",
            "alta": "upper-back/barbell-bent-over-row.gif",
        },
        "biomechanics": "Tracción horizontal o vertical activando dorsal ancho, romboides y bíceps.",
        "posture": "Tracción liderada por los codos, pecho abierto y escápulas conectadas.",
        "warning": "No impulses el torso hacia atrás para mover la carga.",
    },
    # 25. Dead Bug (Bicho Muerto)
    {
        "match_any": ("dead bug", "dead-bug", "bicho muerto"),
        "exclude_any": (),
        "gifs": {
            "baja": "abs/dead-bug.gif",
            "media": "abs/dead-bug.gif",
            "alta": "abs/dead-bug.gif",
        },
        "biomechanics": "Anti-extensión del core extendiendo brazo y pierna contraria con control lumbopélvico.",
        "posture": "Zona lumbar 100% pegada contra el suelo en todo momento.",
        "warning": "Si la espalda baja se despega del suelo, reduce el rango de extensión.",
    },
    # 25B. Paso del Oso / Bear Crawl
    {
        "match_any": ("paso del oso", "bear crawl", "caminata de oso"),
        "exclude_any": (),
        "gifs": {
            "baja": "abs/dead-bug.gif",
            "media": "cardio/jack-jump-male.gif",
            "alta": "cardio/burpee.gif",
        },
        "biomechanics": "Desplazamiento dinámico en cuadrupedia activando core lumbopélvico y estabilidad escapular.",
        "posture": "Espalda plana como una mesa, rodillas a 2cm del suelo y cuello neutro.",
        "warning": "No eleves la cadera en exceso ni balancees el torso.",
    },
    # 26. Plancha Lateral (Side Plank)
    {
        "match_any": ("plancha lateral", "side plank"),
        "exclude_any": (),
        "gifs": {
            "baja": "abs/side-bridge-v-2.gif",
            "media": "abs/side-bridge-v-2.gif",
            "alta": "abs/side-bridge-v-2.gif",
        },
        "biomechanics": "Anti-flexión lateral estabilizando oblicuos, cuadrado lumbar y glúteo medio.",
        "posture": "Hombro alineado sobre el codo, cuerpo recto desde pies hasta la cabeza.",
        "warning": "No permitas que la cadera caiga hacia el suelo.",
    },
    # 27a. Plancha con Rodillas Apoyadas / Suave (Kneeling Plank)
    {
        "match_any": ("rodillas apoyadas", "plancha con rodillas", "plancha suave", "plancha abdominal suave", "kneeling plank"),
        "exclude_any": (),
        "gifs": {
            "baja": "abs/kneeling-plank-tap-shoulder-male.gif",
            "media": "abs/kneeling-plank-tap-shoulder-male.gif",
            "alta": "abs/kneeling-plank-tap-shoulder-male.gif",
        },
        "biomechanics": "Regresión de plancha isométrica con apoyo en rodillas para disminuir el brazo de palanca y proteger la columna lumbar.",
        "posture": "Codos bajo hombros, pelvis neutra y activación voluntaria del transverso abdominal.",
        "warning": "No permitas que la espalda baja se arquee hacia el suelo.",
    },
    # 27b. Plancha Frontal Estándar en Antebrazos (Front Plank)
    {
        "match_any": ("plancha", "plank", "plancha frontal", "plancha en antebrazos", "plancha isometrica"),
        "exclude_any": ("lateral", "side", "rodillas"),
        "gifs": {
            "baja": "abs/front-plank-with-twist.gif",
            "media": "abs/front-plank-with-twist.gif",
            "alta": "abs/front-plank-with-twist.gif",
        },
        "biomechanics": "Contracción isométrica anti-extensión de toda la pared abdominal y transverso.",
        "posture": "Codos bajo hombros, pelvis retrovertida y glúteos apretados.",
        "warning": "Evita hundir la cadera para no comprimir las vértebras lumbares.",
    },
    # 28a. Giros Rusos (Russian Twists)
    {
        "match_any": ("giro ruso", "giros rusos", "russian twist", "rotacion rusa", "twists"),
        "exclude_any": (),
        "gifs": {
            "baja": "abs/band-seated-twist.gif",
            "media": "abs/assisted-motion-russian-twist.gif",
            "alta": "abs/weighted-russian-twist-legs-up.gif",
        },
        "biomechanics": "Rotación torácica dinámica en posición de V-sit reclutando oblicuos y transverso abdominal.",
        "posture": "Espalda recta inclinada a 45°, pecho abierto y rotación desde el torso.",
        "warning": "Evita rotaciones descontroladas de la pelvis; el movimiento es torácico.",
    },
    # 28b. Elevación de Piernas en Suelo o Banco (Leg Raises)
    {
        "match_any": ("elevacion de pierna", "elevacion de piernas", "elevaciones de piernas", "leg raise", "piernas al pecho", "piernas en suelo", "piernas en banco"),
        "exclude_any": ("talon", "talones", "gemelo", "calf"),
        "gifs": {
            "baja": "abs/lying-leg-raise-flat-bench.gif",
            "media": "abs/lying-leg-raise-flat-bench.gif",
            "alta": "abs/hanging-leg-raise.gif",
        },
        "biomechanics": "Flexión lumbopélvica de cadera activando el recto abdominal inferior y transverso sin impacto.",
        "posture": "Zona lumbar permanentemente adherida al suelo o banco, descenso lento de piernas.",
        "warning": "Detén el descenso si sientes que la espalda baja se despega de la colchoneta.",
    },
    # 28c. Crunches / Abdomen Clásico / Bicicleta
    {
        "match_any": ("crunch", "crunches", "abdominal clasico", "bicicleta abdominal", "abdominales"),
        "exclude_any": ("giro ruso", "russian twist", "elevacion de pierna", "leg raise"),
        "gifs": {
            "baja": "abs/oblique-crunches-floor.gif",
            "media": "abs/crunch-floor.gif",
            "alta": "abs/hanging-leg-raise.gif",
        },
        "biomechanics": "Flexión toracolumbar acortando la distancia entre esternón y pubis.",
        "posture": "Cuello relajado con mentón despegado del pecho; exhalar arriba.",
        "warning": "No jales de la cabeza con las manos.",
    },
    # 29. Superman / Extensiones Lumbares
    {
        "match_any": ("superman", "extensiones lumbares", "lumbares en suelo", "extension lumbar"),
        "exclude_any": ("deadlift", "peso muerto"),
        "gifs": {
            "baja": "spine/hyperextension.gif",
            "media": "spine/hyperextension.gif",
            "alta": "spine/hyperextension-on-bench.gif",
        },
        "biomechanics": "Extensión de columna activando erectores espinales, glúteos y cadena posterior.",
        "posture": "Elevación sutil y controlada de pecho y muslos sin hiperextensión forzada.",
        "warning": "Mantén la mirada al suelo para alinear las vértebras cervicales.",
    },
    # 30. Patada de Glúteos en Cuadrupedia (Glute Kickback)
    {
        "match_any": ("patada de gluteo", "patada de gluteos", "glute kickback", "patada en cuadrupedia", "patada cuadrupedia"),
        "exclude_any": ("barra", "bench press"),
        "gifs": {
            "baja": "glutes/low-glute-bridge-on-floor.gif",
            "media": "glutes/bench-hip-extension.gif",
            "alta": "glutes/twist-hip-lift.gif",
        },
        "biomechanics": "Extensión aislada de cadera en 4 apoyos activando las fibras del glúteo mayor.",
        "posture": "Espalda neutra, abdomen contraído y empuje del talón hacia arriba y atrás.",
        "warning": "No arquees la zona lumbar al patear.",
    },
    # 31. Jumping Jacks (Saltos en Tijera)
    {
        "match_any": ("jumping jack", "jumping jacks", "salto en tijera", "saltos en tijera"),
        "exclude_any": (),
        "gifs": {
            "baja": "cardio/jack-jump-male.gif",
            "media": "cardio/jack-jump-male.gif",
            "alta": "cardio/star-jump-male.gif",
        },
        "biomechanics": "Saltos coordinados abriendo y cerrando extremidades para acondicionamiento cardiovascular.",
        "posture": "Aterrizaje suave en puntas de pies con rodillas ligeramente flexionadas.",
        "warning": "Disipa el impacto amortiguando con los tobillos y rodillas.",
    },
    # 32. Escaladores de Montaña (Mountain Climbers)
    {
        "match_any": ("escalador", "escaladores", "mountain climber", "mountain climbers"),
        "exclude_any": (),
        "gifs": {
            "baja": "cardio/mountain-climber.gif",
            "media": "cardio/mountain-climber.gif",
            "alta": "cardio/mountain-climber.gif",
        },
        "biomechanics": "Flexión alternada rápida de rodillas al pecho desde plancha alta estabilizando core y tren superior.",
        "posture": "Manos bajo hombros y cadera baja en línea con los hombros.",
        "warning": "No rebotes la pelvis arriba y abajo.",
    },
    # 33. Dominadas / Pull-ups
    {
        "match_any": ("dominada", "dominadas", "pull up", "pull-up", "pullups"),
        "exclude_any": ("toalla",),
        "gifs": {
            "baja": "lats/band-close-grip-pulldown.gif",
            "media": "lats/pull-up.gif",
            "alta": "lats/pull-up.gif",
        },
        "biomechanics": "Tracción vertical de cadena cerrada con agarre pronado activando dorsal ancho y bíceps.",
        "posture": "Pecho proyectado hacia la barra, escápulas deprimidas y tracción desde los codos.",
        "warning": "Evita el balanceo o kipping descontrolado.",
    },
    # 21. Step-ups / Subidas al escalón o cajón
    {
        "match_any": ("step-up", "step up", "step-ups", "subida al escalon", "subida al cajon", "escalon bajo", "escalón bajo"),
        "exclude_any": ("bicep", "curl", "overhead"),
        "gifs": {
            "baja": "quads/split-squats.gif",
            "media": "glutes/dumbbell-step-up.gif",
            "alta": "glutes/barbell-step-up.gif",
        },
        "biomechanics": "Subida unilateral controlada sobre escalón o banco empujando desde el talón activando cuádriceps y glúteos.",
        "posture": "Torso erguido con ligera inclinación, rodilla alineada con el empeine y empuje desde el talón.",
        "warning": "No permitas que la rodilla colapse hacia adentro (valgo) ni te dejes caer sin control excéntrico.",
    },
]

# Fallbacks garantizados por carpeta muscular e intensidad (CERO guías textuales)
FOLDER_DEFAULT_GIFS = {
    "quads": {
        "baja": "quads/split-squats.gif",
        "media": "quads/dumbbell-goblet-squat.gif",
        "alta": "glutes/barbell-full-squat.gif",
    },
    "glutes": {
        "baja": "glutes/low-glute-bridge-on-floor.gif",
        "media": "glutes/dumbbell-lunge.gif",
        "alta": "glutes/barbell-glute-bridge.gif",
    },
    "hamstrings": {
        "baja": "hamstrings/standing-single-leg-curl.gif",
        "media": "hamstrings/lever-seated-leg-curl.gif",
        "alta": "hamstrings/lever-lying-leg-curl.gif",
    },
    "calves": {
        "baja": "calves/bodyweight-standing-calf-raise.gif",
        "media": "calves/dumbbell-standing-calf-raise.gif",
        "alta": "calves/lever-standing-calf-raise.gif",
    },
    "abductors": {
        "baja": "abductors/side-hip-abduction.gif",
        "media": "abductors/resistance-band-seated-hip-abduction.gif",
        "alta": "abductors/lever-seated-hip-abduction.gif",
    },
    "adductors": {
        "baja": "adductors/side-lying-hip-adduction-male.gif",
        "media": "adductors/cable-hip-adduction.gif",
        "alta": "adductors/lever-seated-hip-adduction.gif",
    },
    "pectorals": {
        "baja": "pectorals/incline-push-up.gif",
        "media": "pectorals/push-up.gif",
        "alta": "pectorals/barbell-bench-press.gif",
    },
    "lats": {
        "baja": "lats/band-close-grip-pulldown.gif",
        "media": "lats/cable-pulldown.gif",
        "alta": "lats/pull-up.gif",
    },
    "upper-back": {
        "baja": "upper-back/band-one-arm-twisting-seated-row.gif",
        "media": "upper-back/cable-low-seated-row.gif",
        "alta": "upper-back/barbell-bent-over-row.gif",
    },
    "delts": {
        "baja": "delts/band-shoulder-press.gif",
        "media": "delts/dumbbell-seated-shoulder-press.gif",
        "alta": "delts/barbell-seated-overhead-press.gif",
    },
    "biceps": {
        "baja": "biceps/resistance-band-seated-biceps-curl.gif",
        "media": "biceps/dumbbell-biceps-curl.gif",
        "alta": "biceps/barbell-curl.gif",
    },
    "triceps": {
        "baja": "triceps/bench-dip-knees-bent.gif",
        "media": "triceps/cable-one-arm-tricep-pushdown.gif",
        "alta": "triceps/barbell-lying-triceps-extension.gif",
    },
    "abs": {
        "baja": "abs/dead-bug.gif",
        "media": "abs/crunch-floor.gif",
        "alta": "abs/hanging-leg-raise.gif",
    },
    "cardio": {
        "baja": "cardio/stationary-bike-walk.gif",
        "media": "cardio/jack-jump-male.gif",
        "alta": "cardio/burpee.gif",
    },
}

SPANISH_TO_ENGLISH_TOKENS = {
    "sentadilla": "squat",
    "sentadillas": "squat",
    "zancada": "lunge",
    "zancadas": "lunge",
    "desplante": "lunge",
    "desplantes": "lunge",
    "prensa": "leg press",
    "isquiotibiales": "leg curl hamstring",
    "isquiotibial": "leg curl hamstring",
    "femoral": "leg curl",
    "cuadriceps": "quad leg extension squat",
    "gluteo": "glute bridge",
    "gluteos": "glute bridge",
    "puente": "glute bridge",
    "pantorrilla": "calf raise",
    "pantorrillas": "calf raise",
    "gemelo": "calf raise",
    "gemelos": "calf raise",
    "talones": "calf raise",
    "talon": "calf raise",
    "abductor": "hip abduction",
    "abduccion": "hip abduction",
    "aductor": "hip adduction",
    "aduccion": "hip adduction",
    "mancuerna": "dumbbell",
    "mancuernas": "dumbbell",
    "barra": "barbell",
    "banda": "band",
    "elastica": "band",
    "polea": "cable",
    "maquina": "lever",
    "copa": "goblet",
    "pecho": "chest",
    "banca": "bench",
    "inclinado": "incline",
    "inclinada": "incline",
    "declinado": "decline",
    "dominadas": "pull up",
    "dominada": "pull up",
    "remo": "row",
    "hombro": "shoulder",
    "hombros": "shoulder",
    "militar": "military",
    "elevacion": "raise",
    "elevaciones": "raise",
    "lateral": "lateral",
    "laterales": "lateral",
    "frontal": "front",
    "plancha": "plank",
    "flexiones": "push up",
    "flexion": "push up",
    "estiramiento": "stretch",
    "bicicleta": "bike",
    "sentado": "seated",
    "acostado": "lying",
    "tumbado": "lying",
}


def _translate_tokens(query: str) -> list[str]:
    norm = _normalize(query)
    # Multi-word replacements first
    phrase_map = {
        "peso corporal": "bodyweight",
        "peso muerto rumano": "romanian deadlift",
        "peso muerto": "deadlift",
        "prensa de piernas": "sled 45 leg press",
        "curl de isquiotibiales": "lever lying leg curl",
        "curl femoral": "lever lying leg curl",
        "extension de cuadriceps": "lever leg extension",
        "puente de gluteos": "low glute bridge",
        "puente de cadera": "low glute bridge",
        "elevacion de talones": "standing calf raise",
        "elevacion de piernas": "lying leg raise flat bench",
        "elevacion de pierna": "lying leg raise flat bench",
        "giros rusos": "assisted motion russian twist",
        "giro ruso": "assisted motion russian twist",
        "flexiones diamante": "diamond push up",
        "flexion diamante": "diamond push up",
        "flexiones en pica": "band shoulder press",
        "sentadilla en pared": "march sit wall",
        "wall sit": "march sit wall",
        "jumping jacks": "jack jump",
        "saltos en tijera": "jack jump",
        "patada de gluteos": "bench hip extension",
        "patada de gluteo": "bench hip extension",
        "fondos de triceps": "bench dip",
        "press de banca con barra": "barbell bench press",
        "press de banca con mancuernas": "dumbbell bench press",
        "remo con barra": "barbell bent over row",
        "remo con mancuerna": "dumbbell one arm bent over row",
        "remo en polea": "cable low seated row",
        "sentadilla profunda con barra": "barbell full squat",
        "sentadilla con barra": "barbell full squat",
        "sentadilla goblet": "dumbbell goblet squat",
        "curl de biceps con mancuernas": "dumbbell biceps curl",
        "curl de biceps con barra": "barbell curl",
        "curl martillo": "dumbbell hammer curl",
    }
    for esp_phrase, eng_phrase in phrase_map.items():
        if esp_phrase in norm:
            norm = norm.replace(esp_phrase, eng_phrase)

    tokens: list[str] = []
    for word in norm.split():
        if word in STOPWORDS or len(word) <= 2:
            continue
        mapped = SPANISH_TO_ENGLISH_TOKENS.get(word, word)
        for sub in mapped.split():
            if len(sub) > 2 and sub not in STOPWORDS:
                tokens.append(sub)
    return tokens


GYM_EQUIPMENT_KEYWORDS = {"dumbbell", "barbell", "cable", "lever", "smith", "machine", "sled", "kettlebell"}


def _is_gym_gif(path: str) -> bool:
    slug = path.split("/")[1].lower() if "/" in path else path.lower()
    return any(w in slug for w in GYM_EQUIPMENT_KEYWORDS)


def _to_gif_url(path: str) -> str:
    if path.startswith("http://") or path.startswith("https://"):
        return path
    return f"{BASE_GIF_URL}{path}"


@router.get("/gif")
def get_exercise_gif(
    query: str,
    muscle: Optional[str] = None,
    intensity: Optional[str] = None,
    equipment: Optional[str] = None,
    is_no_equipment: Optional[bool] = None,
):
    norm_q = _normalize(query)
    norm_m = _normalize(muscle or "")
    combined = f"{norm_q} {norm_m}".strip()

    # Detectar automáticamente si se solicita sin herramientas
    if is_no_equipment is None:
        is_no_equipment = any(w in norm_q for w in (
            "sin equipo", "sin herramientas", "peso corporal", "en casa", "calistenia",
            "en suelo", "con toalla", "en pared", "en silla", "deslizador", "toalla", "suelo"
        )) or (equipment in ("sin_equipo", "casa", "bodyweight", "calistenia"))

    intensity_info = classify_intensity(query, intensity)
    level_code = intensity_info["code"]  # "baja" | "media" | "alta"

    # 1A. Revisar catálogo curado por patrón exacto del nombre del ejercicio (norm_q)
    for entry in CURATED_BY_INTENSITY:
        if any(m in norm_q for m in entry["match_any"]):
            if not any(ex in norm_q for ex in entry["exclude_any"]):
                chosen_gif = entry["gifs"].get(level_code) or entry["gifs"]["media"]
                if is_no_equipment and _is_gym_gif(chosen_gif):
                    baja_gif = entry["gifs"].get("baja")
                    if baja_gif and not _is_gym_gif(baja_gif):
                        chosen_gif = baja_gif
                gif_url = _to_gif_url(chosen_gif)
                return {
                    "url": gif_url,
                    "gif_url": gif_url,
                    "query": query,
                    "intensity_level": intensity_info["label"],
                    "intensity_code": level_code,
                    "tempo": intensity_info["tempo"],
                    "biomechanics": entry["biomechanics"],
                    "posture": entry["posture"],
                    "warning": entry["warning"],
                }

    # 1B. Si no coincidió en norm_q, intentar con la combinación (norm_q + norm_m)
    for entry in CURATED_BY_INTENSITY:
        if any(m in combined for m in entry["match_any"]):
            if not any(ex in combined for ex in entry["exclude_any"]):
                chosen_gif = entry["gifs"].get(level_code) or entry["gifs"]["media"]
                if is_no_equipment and _is_gym_gif(chosen_gif):
                    baja_gif = entry["gifs"].get("baja")
                    if baja_gif and not _is_gym_gif(baja_gif):
                        chosen_gif = baja_gif
                gif_url = _to_gif_url(chosen_gif)
                return {
                    "url": gif_url,
                    "gif_url": gif_url,
                    "query": query,
                    "intensity_level": intensity_info["label"],
                    "intensity_code": level_code,
                    "tempo": intensity_info["tempo"],
                    "biomechanics": entry["biomechanics"],
                    "posture": entry["posture"],
                    "warning": entry["warning"],
                }

    # 2. Búsqueda filtrada estrictamente por carpeta muscular
    allowed_folders = _detect_target_folders(query, muscle)
    eng_tokens = _translate_tokens(query)

    candidates = [
        p for p in gif_paths
        if not allowed_folders or p.split("/")[0] in allowed_folders
    ]
    if not candidates:
        candidates = gif_paths

    # HARD FILTER: Si es sin equipo, excluir rotundamente máquinas, barras y mancuernas
    if is_no_equipment:
        candidates_no_eq = [p for p in candidates if not _is_gym_gif(p)]
        if candidates_no_eq:
            candidates = candidates_no_eq

    best_match = None
    best_score = -999

    for path in candidates:
        folder, file_part = path.split("/", 1)
        filename = file_part.replace(".gif", "")
        file_words = set(filename.split("-"))

        # Coincidencia por palabras completas o prefijos relevantes (>3 chars)
        score = 0
        for tok in eng_tokens:
            if tok in file_words:
                score += 4
            elif len(tok) >= 4 and tok in filename:
                score += 2

        if score == 0:
            continue

        # Bonificación según coherencia con el nivel de intensidad solicitado
        if level_code == "baja":
            if any(w in file_words for w in ("bodyweight", "band", "assisted", "floor", "standing", "seated", "stretch")):
                score += 2
            if any(w in file_words for w in ("barbell", "plyo", "jump", "snatch", "clean", "jerk", "weighted")):
                score -= 3
        elif level_code == "media":
            if any(w in file_words for w in ("dumbbell", "lever", "cable", "sled", "goblet", "seated")):
                score += 2
        elif level_code == "alta":
            if any(w in file_words for w in ("barbell", "jump", "plyo", "weighted", "full", "pistol")):
                score += 2

        if score > best_score:
            best_score = score
            best_match = path

    # 3. Fallback garantizado dentro de la carpeta anatómica correcta (NUNCA devuelve url: None)
    if not best_match or best_score <= 0:
        primary_folder = allowed_folders[0] if allowed_folders else "quads"
        folder_map = FOLDER_DEFAULT_GIFS.get(primary_folder, FOLDER_DEFAULT_GIFS["quads"])
        best_match = folder_map.get(level_code, folder_map["media"])
        if is_no_equipment and _is_gym_gif(best_match):
            best_match = folder_map.get("baja", best_match)
            if _is_gym_gif(best_match):
                bw_in_folder = [p for p in gif_paths if p.startswith(f"{primary_folder}/") and not _is_gym_gif(p)]
                if bw_in_folder:
                    best_match = bw_in_folder[0]

    gif_url = _to_gif_url(best_match)
    return {
        "url": gif_url,
        "gif_url": gif_url,
        "query": query,
        "intensity_level": intensity_info["label"],
        "intensity_code": level_code,
        "tempo": intensity_info["tempo"],
        "biomechanics": "Movimiento controlado respetando el rango articular seguro de la zona objetivo.",
        "posture": "Mantén el core activo, columna neutra y respiración acompasada en cada repetición.",
        "warning": "Si percibes molestia articular aguda, reduce el rango de movimiento o detén la serie.",
    }


@router.get("/catalog/stats")
def get_catalog_stats():
    """Retorna las estadísticas del catálogo completo de 1.323 GIFs indexados por equipamiento, intensidad y seguridad clínica."""
    from app.services.exercise_catalog_service import catalog_service
    return catalog_service.stats()

