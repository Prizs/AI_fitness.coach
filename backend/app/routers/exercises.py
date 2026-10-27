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
    combined = f"{_normalize(query)} {_normalize(muscle or '')}"

    # 1. Reglas específicas de Tren Inferior (Piernas y Glúteos)
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

    # 2. Reglas de Tren Superior y Core
    if any(w in combined for w in ("pectoral", "pecho", "bench press", "press de banca", "flexion", "push up", "pushup", "aperturas", "fly")):
        return ["pectorals", "serratus-anterior"]
    if any(w in combined for w in ("dorsal", "dominada", "pull up", "pullup", "jalon", "pulldown", "remo", "row", "espalda", "back")):
        return ["lats", "upper-back", "traps", "spine"]
    if any(w in combined for w in ("deltoides", "hombro", "shoulder", "press militar", "military press", "elevacion lateral", "lateral raise", "elevacion frontal", "pajaro", "arnold")):
        return ["delts", "traps"]
    if any(w in combined for w in ("biceps", "bicep", "martillo", "hammer curl", "predicador", "preacher")):
        return ["biceps", "forearms"]
    if any(w in combined for w in ("triceps", "tricep", "rompecraneos", "skull", "extension de codo", "patada de triceps", "pushdown")):
        return ["triceps"]
    if any(w in combined for w in ("antebrazo", "muneca", "forearm", "wrist")):
        return ["forearms"]
    if any(w in combined for w in ("abdomen", "abdominal", "core", "plancha", "plank", "crunch", "oblicuo", "russian twist", "dead bug", "lumbar")):
        return ["abs", "spine"]
    if any(w in combined for w in ("cardio", "burpee", "jumping jack", "trote", "correr", "bicicleta", "caminata", "marcha", "mountain climber", "escalador")):
        return ["cardio", "quads", "glutes"]

    return []


# Mapeo curado de ejercicios arquetípicos por patrón de movimiento e intensidad (baja, media, alta)
CURATED_BY_INTENSITY = [
    # 1. Sentadillas (Squats)
    {
        "match_any": ("sentadilla", "squat"),
        "exclude_any": ("bulgara", "split", "salto", "jump", "pistol", "hack", "sissy"),
        "gifs": {
            "baja": "glutes/potty-squat-with-support.gif",
            "media": "quads/dumbbell-goblet-squat.gif",
            "alta": "glutes/barbell-full-squat.gif",
        },
        "biomechanics": "Flexión controlada de rodillas y cadera manteniendo la columna neutra y el peso distribuido en toda la planta del pie.",
        "posture": "Pecho erguido, mirada al frente y rodillas alineadas con la punta de los pies sin colapsar hacia adentro.",
        "warning": "Detén el descenso si sientes pellizco en la cadera o dolor rotuliano; prioriza el control antes que la profundidad.",
    },
    # 2. Sentadilla Búlgara / Split Squat
    {
        "match_any": ("bulgara", "split squat", "sentadilla dividida"),
        "exclude_any": (),
        "gifs": {
            "baja": "quads/split-squats.gif",
            "media": "quads/dumbbell-single-leg-split-squat.gif",
            "alta": "quads/barbell-single-leg-split-squat.gif",
        },
        "biomechanics": "Trabajo unilateral enfocado en el cuádriceps y glúteo de la pierna adelantada con descenso vertical controlado.",
        "posture": "Torso ligeramente inclinado hacia adelante (~15°) para alinear la cadera y proteger la zona lumbar.",
        "warning": "Mantén la rodilla delantera estable sin oscilar lateralmente.",
    },
    # 3. Sentadilla con salto / Pliométrica
    {
        "match_any": ("sentadilla con salto", "jump squat", "pliometric"),
        "exclude_any": (),
        "gifs": {
            "baja": "quads/split-squats.gif",
            "media": "glutes/jump-squat.gif",
            "alta": "glutes/bodyweight-drop-jump-squat.gif",
        },
        "biomechanics": "Triple extensión explosiva de tobillo, rodilla y cadera seguida de recepción amortiguada.",
        "posture": "Aterriza suavemente apoyando primero metatarso y flexionando las rodillas para absorber el impacto.",
        "warning": "Evitar en caso de molestia articular en rodillas, tobillos o columna lumbar.",
    },
    # 4. Zancadas / Desplantes (Lunges)
    {
        "match_any": ("zancada", "desplante", "lunge"),
        "exclude_any": (),
        "gifs": {
            "baja": "glutes/forward-lunge-male.gif",
            "media": "glutes/dumbbell-lunge.gif",
            "alta": "glutes/barbell-lunge.gif",
        },
        "biomechanics": "Paso controlado formando ángulos cercanos a 90° en ambas rodillas, activando cuádriceps y glúteo mayor.",
        "posture": "Tronco recto, pelvis neutra y empuje firme con el talón del pie delantero al regresar.",
        "warning": "No golpees la rodilla trasera contra el suelo; frena el movimiento a 2-3 cm del piso.",
    },
    # 5. Prensa de Piernas (Leg Press)
    {
        "match_any": ("prensa", "leg press"),
        "exclude_any": ("gemelo", "pantorrilla", "calf"),
        "gifs": {
            "baja": "quads/lever-alternate-leg-press.gif",
            "media": "glutes/sled-45-leg-press.gif",
            "alta": "glutes/sled-45-leg-wide-press.gif",
        },
        "biomechanics": "Empuje de cadena cerrada con espalda soportada, reduciendo la carga axial sobre la columna vertebral.",
        "posture": "Mantén el sacro y la espalda baja pegados al respaldo en todo momento; pies al ancho de los hombros.",
        "warning": "NUNCA bloquees las rodillas por completo al extender las piernas.",
    },
    # 6. Curl de Isquiotibiales / Femoral (Hamstring Curl)
    {
        "match_any": ("isquiotibial", "femoral", "hamstring", "leg curl", "curl de pierna"),
        "exclude_any": ("estiramiento", "stretch"),
        "gifs": {
            "baja": "hamstrings/standing-single-leg-curl.gif",
            "media": "hamstrings/lever-seated-leg-curl.gif",
            "alta": "hamstrings/lever-lying-leg-curl.gif",
        },
        "biomechanics": "Flexión aislada de la articulación de la rodilla reclutando el bíceps femoral, semitendinoso y semimembranoso.",
        "posture": "Alinea el eje de la rodilla con el pivote de soporte y mantén la pelvis fija sin arquear la espalda baja.",
        "warning": "Controla la fase excéntrica (bajada lenta de 3 segundos) para prevenir tirones en el tendón distal.",
    },
    # 7. Extensión de Cuádriceps (Leg Extension)
    {
        "match_any": ("extension de cuadriceps", "extension de pierna", "leg extension", "cuadriceps en maquina"),
        "exclude_any": (),
        "gifs": {
            "baja": "quads/resistance-band-leg-extension.gif",
            "media": "quads/lever-leg-extension.gif",
            "alta": "quads/lever-leg-extension.gif",
        },
        "biomechanics": "Extensión de cadena cinética abierta enfocada en las cuatro cabezas del cuádriceps (recto femoral y vastos).",
        "posture": "Espalda totalmente apoyada en el respaldo y rodillas alineadas con el eje de giro.",
        "warning": "Evita usar impulso brusco; haz una pausa de 1 segundo arriba para máxima activación muscular con menor peso.",
    },
    # 8. Puente de Glúteos / Hip Thrust
    {
        "match_any": ("puente de gluteo", "puente de cadera", "glute bridge", "hip thrust", "elevacion de cadera", "elevacion pelvica"),
        "exclude_any": (),
        "gifs": {
            "baja": "glutes/low-glute-bridge-on-floor.gif",
            "media": "glutes/glute-bridge-two-legs-on-bench-male.gif",
            "alta": "glutes/barbell-glute-bridge.gif",
        },
        "biomechanics": "Extensión de cadera en rango horizontal con máxima contracción del glúteo mayor en el punto superior.",
        "posture": "Empuja desde los talones, mantén las costillas bajas y el mentón ligeramente recogido.",
        "warning": "No hiperextiendas la columna lumbar arriba; el movimiento debe nacer de la cadera y los glúteos.",
    },
    # 9. Peso Muerto / Bisagra de Cadera (Deadlift / RDL)
    {
        "match_any": ("peso muerto", "deadlift", "bisagra de cadera", "buenos dias", "good morning"),
        "exclude_any": (),
        "gifs": {
            "baja": "glutes/band-stiff-leg-deadlift.gif",
            "media": "glutes/dumbbell-romanian-deadlift.gif",
            "alta": "glutes/barbell-romanian-deadlift.gif",
        },
        "biomechanics": "Patrón de bisagra de cadera llevando los glúteos hacia atrás mientras el torso desciende con espalda neutra.",
        "posture": "Escápulas retraídas, abdomen firme y carga pegada a los muslos durante todo el recorrido.",
        "warning": "Jamás redondees la zona lumbar; desciende solo hasta donde tu flexibilidad de isquiotibiales lo permita.",
    },
    # 10. Elevación de Talones / Gemelos y Pantorrillas (Variaciones Anatómicas Precisas)
    # 10a. Elevación de Talones Sentado en Máquina o con Mancuerna / Sóleo
    {
        "match_any": ("talones en maquina sentado", "talon sentado", "talones sentado", "seated calf", "soleo sentado", "batata sentado", "batatas sentado", "pantorrilla sentado"),
        "exclude_any": (),
        "gifs": {
            "baja": "calves/seated-calf-stretch-male.gif",
            "media": "calves/lever-seated-calf-raise.gif",
            "alta": "calves/barbell-seated-calf-raise.gif",
        },
        "biomechanics": "Flexión plantar con rodillas flexionadas a 90° para aislar selectivamente el músculo sóleo eliminando la acción del gastrocnemio.",
        "posture": "Espalda recta, almohadillas firmemente fijadas sobre los muslos y pausa de 1 segundo en la contracción alta.",
        "warning": "No permitas que las almohadillas reboten contra los muslos en la parte baja para proteger el tendón.",
    },
    # 10b. Elevación de Talones Unipodal / a Una Pierna en Escalón
    {
        "match_any": ("unipodal", "a una pierna", "unilateral", "single leg calf", "unipodal en escalon", "talones a una pierna"),
        "exclude_any": (),
        "gifs": {
            "baja": "calves/band-single-leg-calf-raise.gif",
            "media": "calves/dumbbell-single-leg-calf-raise.gif",
            "alta": "calves/single-leg-calf-raise-on-a-dumbbell.gif",
        },
        "biomechanics": "Trabajo unilateral de fuerza y propiocepción estimulando el tríceps sural y los estabilizadores del pie y tobillo.",
        "posture": "Apoyo metatarsiano en el borde del escalón con talón suspendido; desciende lentamente sintiendo el estiramiento profundo.",
        "warning": "Mantén el equilibrio sujetándote con una mano si es necesario; no aceleres la fase de bajada.",
    },
    # 10c. Elevación de Talones en Prensa de Piernas
    {
        "match_any": ("talones en prensa", "pantorrilla en prensa", "sled calf", "calf press"),
        "exclude_any": (),
        "gifs": {
            "baja": "calves/lever-seated-calf-press.gif",
            "media": "calves/sled-calf-press-on-leg-press.gif",
            "alta": "calves/sled-45-calf-press.gif",
        },
        "biomechanics": "Empuje de flexión plantar en prensa con rodillas casi extendidas reclutando la cabeza medial y lateral del gastrocnemio.",
        "posture": "Solo las puntas de los pies apoyadas en la parte inferior de la plataforma; bloquea la seguridad de la prensa.",
        "warning": "NUNCA flexiones las rodillas bruscamente durante el ejercicio para evitar atrapamiento articular.",
    },
    # 10d. Donkey Calf Raise / Tipo Burro
    {
        "match_any": ("donkey", "burro"),
        "exclude_any": (),
        "gifs": {
            "baja": "calves/one-leg-donkey-calf-raise.gif",
            "media": "calves/donkey-calf-raise.gif",
            "alta": "calves/weighted-donkey-calf-raise.gif",
        },
        "biomechanics": "Flexión plantar con torso flexionado a 90°, maximizando el pre-estiramiento del gastrocnemio por la posición de cadera.",
        "posture": "Espalda plana apoyada y rodillas extendidas sin bloqueo rígido.",
        "warning": "Evita redondear la zona lumbar.",
    },
    # 10e. Tibial Anterior, Dorsiflexión y Movilidad de Pies
    {
        "match_any": ("dorsiflexion", "tibial anterior", "dorsiflexion tibial", "tobillo", "arco plantar", "pies"),
        "exclude_any": ("sentadilla", "squat", "prensa", "lunge"),
        "gifs": {
            "baja": "calves/ankle-circles.gif",
            "media": "calves/posterior-tibialis-stretch.gif",
            "alta": "calves/box-jump-down-with-one-leg-stabilization.gif",
        },
        "biomechanics": "Dorsiflexión activa del tobillo para equilibrar el compartimento anterior de la pierna y prevenir periostitis tibial.",
        "posture": "Sentado con pierna extendida o de pie con talones firmes, eleva las puntas de los pies hacia las espinillas.",
        "warning": "Realiza movimientos controlados sin tirones bruscos.",
    },
    # 10f. Elevación de Talones de Pie (General / Con Mancuernas / Con Barra)
    {
        "match_any": ("gemelo", "pantorrilla", "talon", "calf", "calves", "soleo", "batata", "triceps sural"),
        "exclude_any": ("sentado", "unipodal", "a una pierna", "prensa", "donkey", "tibial"),
        "gifs": {
            "baja": "calves/bodyweight-standing-calf-raise.gif",
            "media": "calves/dumbbell-standing-calf-raise.gif",
            "alta": "calves/lever-standing-calf-raise.gif",
        },
        "biomechanics": "Flexión plantar completa del tobillo estimulando el gastrocnemio y el sóleo.",
        "posture": "Rodillas extendidas pero sin bloqueo rígido; pausa de 1 segundo en la máxima contracción superior.",
        "warning": "Evita rebotar en la parte baja para no sobrecargar el tendón de Aquiles.",
    },
    # 11. Abducción / Aducción de Cadera
    {
        "match_any": ("abduccion", "abductor", "apertura de cadera"),
        "exclude_any": (),
        "gifs": {
            "baja": "abductors/side-hip-abduction.gif",
            "media": "abductors/resistance-band-seated-hip-abduction.gif",
            "alta": "abductors/lever-seated-hip-abduction.gif",
        },
        "biomechanics": "Separación lateral del fémur enfocada en el glúteo medio y glúteo menor para estabilizar la pelvis.",
        "posture": "Pelvis alineada sin rotar hacia atrás durante la elevación o apertura.",
        "warning": "Controla el retorno sin dejar caer las piernas de golpe.",
    },
    {
        "match_any": ("aduccion", "aductor"),
        "exclude_any": (),
        "gifs": {
            "baja": "adductors/side-lying-hip-adduction-male.gif",
            "media": "adductors/cable-hip-adduction.gif",
            "alta": "adductors/lever-seated-hip-adduction.gif",
        },
        "biomechanics": "Aproximación medial del muslo activando la musculatura aductora interna.",
        "posture": "Mantén el tronco estable y evita abrir en exceso más allá de tu rango cómodo.",
        "warning": "Realiza movimientos fluidos para proteger la inserción inguinal.",
    },
    # 12. Subida al cajón / Step-up
    {
        "match_any": ("step up", "subida al cajon", "escalon", "banco"),
        "exclude_any": ("pecho", "banca", "bench press", "triceps", "biceps"),
        "gifs": {
            "baja": "glutes/band-step-up.gif",
            "media": "glutes/dumbbell-step-up.gif",
            "alta": "glutes/barbell-step-up.gif",
        },
        "biomechanics": "Ascenso unilateral impulsando con toda la planta del pie apoyado en la plataforma.",
        "posture": "Evita impulsarte con el pie de abajo; el trabajo debe hacerlo la pierna elevada.",
        "warning": "Usa una altura de escalón que permita mantener la cadera nivelada.",
    },
    # 13. Pecho / Empuje
    {
        "match_any": ("flexion", "push up", "pushup", "lagartija", "press de pecho en pared"),
        "exclude_any": (),
        "gifs": {
            "baja": "pectorals/incline-push-up.gif",
            "media": "pectorals/push-up.gif",
            "alta": "pectorals/decline-push-up.gif",
        },
        "biomechanics": "Empuje horizontal en cadena cerrada activando pectoral mayor, deltoides anterior y tríceps.",
        "posture": "Cuerpo alineado en plancha desde los tobillos hasta la cabeza y codos a 45° del torso.",
        "warning": "No dejes caer la cadera hacia el suelo para proteger la columna lumbar.",
    },
    {
        "match_any": ("press de banca", "bench press", "press de pecho"),
        "exclude_any": ("pared",),
        "gifs": {
            "baja": "pectorals/resistance-band-seated-chest-press.gif",
            "media": "pectorals/dumbbell-bench-press.gif",
            "alta": "pectorals/barbell-bench-press.gif",
        },
        "biomechanics": "Empuje horizontal con retracción escapular para maximizar el reclutamiento pectoral.",
        "posture": "Escápulas juntas contra el banco, pies firmes en el suelo y muñecas rectas.",
        "warning": "No bajes con los codos abiertos a 90°; mantenlos a unos 45-60° para cuidar el manguito rotador.",
    },
    # 14. Espalda / Tracción
    {
        "match_any": ("remo", "row"),
        "exclude_any": ("al menton", "upright"),
        "gifs": {
            "baja": "upper-back/band-one-arm-twisting-seated-row.gif",
            "media": "upper-back/cable-low-seated-row.gif",
            "alta": "upper-back/barbell-bent-over-row.gif",
        },
        "biomechanics": "Tracción horizontal iniciando con retracción escapular y llevando los codos hacia la cadera.",
        "posture": "Pecho proyectado al frente, espalda neutra y hombros lejos de las orejas.",
        "warning": "Evita balancear el torso para mover el peso.",
    },
    {
        "match_any": ("dominada", "pull up", "pullup", "jalon", "pulldown"),
        "exclude_any": (),
        "gifs": {
            "baja": "lats/band-close-grip-pulldown.gif",
            "media": "lats/cable-pulldown.gif",
            "alta": "lats/pull-up.gif",
        },
        "biomechanics": "Tracción vertical enfocada en el dorsal ancho y redondo mayor.",
        "posture": "Deprime los hombros antes de flexionar los codos y lleva la barra hacia la parte alta del pecho.",
        "warning": "Nunca tires por detrás de la nuca para evitar pinzamiento subacromial.",
    },
    # 15. Hombros
    {
        "match_any": ("press militar", "press de hombro", "shoulder press", "military press"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/band-shoulder-press.gif",
            "media": "delts/dumbbell-seated-shoulder-press.gif",
            "alta": "delts/barbell-seated-overhead-press.gif",
        },
        "biomechanics": "Empuje vertical sobre la cabeza en el plano escapular trabajando el deltoides anterior y lateral.",
        "posture": "Glúteos y abdomen contraídos para estabilizar el tronco sin arquear la espalda baja.",
        "warning": "Baja de forma controlada hasta la altura del mentón.",
    },
    {
        "match_any": ("elevacion lateral", "elevaciones laterales", "lateral raise"),
        "exclude_any": (),
        "gifs": {
            "baja": "delts/band-front-lateral-raise.gif",
            "media": "delts/dumbbell-lateral-raise.gif",
            "alta": "delts/cable-lateral-raise.gif",
        },
        "biomechanics": "Abducción de hombro hasta los 90° aislando la porción lateral del deltoides.",
        "posture": "Codos ligeramente flexionados y subida guiada por los codos, no por las muñecas.",
        "warning": "Usa pesos moderados para no compensar con el trapecio superior.",
    },
    # 16. Core / Abdomen
    {
        "match_any": ("plancha", "plank"),
        "exclude_any": (),
        "gifs": {
            "baja": "abs/kneeling-plank-tap-shoulder-male.gif",
            "media": "abs/front-plank-with-twist.gif",
            "alta": "abs/weighted-front-plank.gif",
        },
        "biomechanics": "Contracción isométrica anti-extensión del transverso abdominal, recto abdominal y glúteos.",
        "posture": "Codos bajo los hombros, pelvis en ligera retroversión y respiración fluida.",
        "warning": "Si sientes tensión en la espalda baja, detén la serie o apoya las rodillas.",
    },
    {
        "match_any": ("dead bug", "bicho muerto"),
        "exclude_any": (),
        "gifs": {
            "baja": "abs/dead-bug.gif",
            "media": "abs/dead-bug.gif",
            "alta": "abs/dead-bug.gif",
        },
        "biomechanics": "Estabilización lumbopélvica dinámica extendiendo brazo y pierna contraria sin despegar la zona lumbar.",
        "posture": "Zona lumbar completamente sellada contra el suelo en todo momento.",
        "warning": "Exhala lentamente al extender las extremidades.",
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


@router.get("/gif")
def get_exercise_gif(
    query: str,
    muscle: Optional[str] = None,
    intensity: Optional[str] = None,
):
    norm_q = _normalize(query)
    norm_m = _normalize(muscle or "")
    combined = f"{norm_q} {norm_m}".strip()

    intensity_info = classify_intensity(query, intensity)
    level_code = intensity_info["code"]  # "baja" | "media" | "alta"

    # 1. Revisar catálogo curado por patrón biomecánico e intensidad
    for entry in CURATED_BY_INTENSITY:
        if any(m in combined for m in entry["match_any"]):
            if not any(ex in combined for ex in entry["exclude_any"]):
                chosen_gif = entry["gifs"].get(level_code) or entry["gifs"]["media"]
                return {
                    "url": f"{BASE_GIF_URL}{chosen_gif}",
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

    return {
        "url": f"{BASE_GIF_URL}{best_match}",
        "query": query,
        "intensity_level": intensity_info["label"],
        "intensity_code": level_code,
        "tempo": intensity_info["tempo"],
        "biomechanics": "Movimiento controlado respetando el rango articular seguro de la zona objetivo.",
        "posture": "Mantén el core activo, columna neutra y respiración acompasada en cada repetición.",
        "warning": "Si percibes molestia articular aguda, reduce el rango de movimiento o detén la serie.",
    }
