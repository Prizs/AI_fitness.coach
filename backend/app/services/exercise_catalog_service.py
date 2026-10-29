import json
import re
from pathlib import Path

GIFS_DB_PATH = Path(__file__).resolve().parent.parent / "gifs_db.json"

FOLDER_TO_ZONE = {
    "abs": ("core", "Abdomen y Core"),
    "spine": ("core", "Zona Lumbar y Espina"),
    "pectorals": ("tren_superior", "Pectorales"),
    "serratus-anterior": ("tren_superior", "Serrato"),
    "lats": ("tren_superior", "Dorsales"),
    "upper-back": ("tren_superior", "Espalda Alta"),
    "traps": ("tren_superior", "Trapecios"),
    "delts": ("tren_superior", "Hombros / Deltoides"),
    "levator-scapulae": ("tren_superior", "Cuello y Escápula"),
    "biceps": ("tren_superior", "Bíceps"),
    "triceps": ("tren_superior", "Tríceps"),
    "forearms": ("tren_superior", "Antebrazos"),
    "quads": ("tren_inferior", "Cuádriceps"),
    "hamstrings": ("tren_inferior", "Isquiotibiales"),
    "glutes": ("tren_inferior", "Glúteos"),
    "calves": ("tren_inferior", "Pantorrillas y Sóleo"),
    "abductors": ("tren_inferior", "Abductores"),
    "adductors": ("tren_inferior", "Aductores"),
    "cardio": ("cardio", "Cardio y Funcional"),
}

def classify_equipment(name: str) -> str:
    n = name.lower()
    if "dumbbell" in n:
        return "mancuernas"
    if "barbell" in n or "ez-bar" in n:
        return "barra"
    if "cable" in n:
        return "polea"
    if any(k in n for k in ("lever", "smith", "sled", "machine", "hack")):
        return "maquina"
    if "kettlebell" in n:
        return "kettlebell"
    if "band" in n or "resistance-band" in n:
        return "bandas"
    if "ball" in n or "bosu" in n:
        return "pelota"
    return "sin_equipo"

def classify_intensity(name: str, equipment: str) -> str:
    n = name.lower()
    if any(k in n for k in ("assisted", "stretch", "kneeling", "seated-stretch", "ankle-circles", "walk", "foam")):
        return "baja"
    if any(k in n for k in ("jump", "plyo", "drop", "snatch", "clean-and-jerk", "weighted", "barbell-full-squat", "full-planche", "decline-push-up")):
        return "alta"
    if equipment in ("barra", "kettlebell"):
        return "alta"
    if equipment in ("mancuernas", "polea", "maquina"):
        return "media"
    if equipment == "bandas":
        return "baja" if any(k in n for k in ("stretch", "seated", "assisted")) else "media"
    # Sin equipo:
    if any(k in n for k in ("floor", "seated", "prone", "kneeling", "low-glute", "dead-bug")):
        return "baja"
    return "media"

def classify_clinical_profile(name: str, folder: str, equipment: str, intensity: str) -> dict:
    n = name.lower()
    
    # 1. Knee Friendly (Sin flexión aguda de rodilla, sin impacto)
    knee_friendly = True
    if folder in ("quads", "glutes", "hamstrings", "cardio"):
        if any(k in n for k in ("jump", "plyo", "deep-squat", "pistol", "drop", "lunge-jump", "sissy")):
            knee_friendly = False
    
    # 2. Lumbar Friendly (Espalda soportada, en suelo o sin carga axial vertical)
    lumbar_friendly = True
    if any(k in n for k in ("barbell-deadlift", "barbell-full-squat", "good-morning", "overhead-press", "bent-over-row")):
        lumbar_friendly = False
    if any(k in n for k in ("lying", "seated", "floor", "bench", "chest-supported", "dead-bug", "lever", "wall")):
        lumbar_friendly = True
        
    # 3. Shoulder Friendly (Sin press tras nuca, abducción forzada o rotación extrema)
    shoulder_friendly = True
    if any(k in n for k in ("behind-neck", "upright-row", "deep-dip", "clean", "snatch")):
        shoulder_friendly = False
        
    # 4. Movilidad Reducida / Adulto Mayor / Discapacidad
    reduced_mobility = False
    if any(k in n for k in ("seated", "chair", "lying", "bed", "assisted", "stretch", "wall-supported")):
        reduced_mobility = True
    if equipment == "sin_equipo" and intensity == "baja":
        reduced_mobility = True

    return {
        "knee_friendly": knee_friendly,
        "lumbar_friendly": lumbar_friendly,
        "shoulder_friendly": shoulder_friendly,
        "reduced_mobility_friendly": reduced_mobility,
    }

class ExerciseCatalogService:
    def __init__(self):
        self._catalog = []
        self._by_path = {}
        self._by_equipment = {}
        self._load()

    def _load(self):
        if not GIFS_DB_PATH.exists():
            return
        with open(GIFS_DB_PATH, "r", encoding="utf-8") as f:
            raw_paths = json.load(f)

        for path in raw_paths:
            parts = path.split("/")
            if len(parts) != 2:
                continue
            folder, fname = parts
            slug = fname.replace(".gif", "")
            equip = classify_equipment(slug)
            intensity = classify_intensity(slug, equip)
            zone, muscle = FOLDER_TO_ZONE.get(folder, ("general", folder.capitalize()))
            clinical = classify_clinical_profile(slug, folder, equip, intensity)

            # Tokens for fast search
            tokens = set(slug.split("-"))

            entry = {
                "gif_path": path,
                "folder": folder,
                "slug": slug,
                "body_zone": zone,
                "primary_muscle": muscle,
                "equipment": equip,
                "intensity": intensity,
                "clinical": clinical,
                "tokens": tokens,
            }
            self._catalog.append(entry)
            self._by_path[path] = entry
            self._by_equipment.setdefault(equip, []).append(entry)

    def stats(self):
        eq_counts = {k: len(v) for k, v in self._by_equipment.items()}
        int_counts = {"baja": 0, "media": 0, "alta": 0}
        clin_counts = {"knee_friendly": 0, "lumbar_friendly": 0, "shoulder_friendly": 0, "reduced_mobility_friendly": 0}
        
        for e in self._catalog:
            int_counts[e["intensity"]] = int_counts.get(e["intensity"], 0) + 1
            for k in clin_counts:
                if e["clinical"][k]:
                    clin_counts[k] += 1

        return {
            "total_gifs": len(self._catalog),
            "by_equipment": eq_counts,
            "by_intensity": int_counts,
            "clinical_suitability": clin_counts,
        }

    def search(
        self,
        query: str = "",
        equipment: str | None = None,
        intensity: str | None = None,
        is_no_equipment: bool = False,
        knee_safe: bool = False,
        lumbar_safe: bool = False,
        shoulder_safe: bool = False,
        reduced_mobility: bool = False,
        limit: int = 10,
    ) -> list[dict]:
        q_tokens = set(re.findall(r"\w+", query.lower())) if query else set()
        results = []

        for e in self._catalog:
            # Filter equipment
            if is_no_equipment and e["equipment"] not in ("sin_equipo", "bandas"):
                continue
            if equipment and e["equipment"] != equipment:
                continue
                
            # Filter intensity
            if intensity and e["intensity"] != intensity:
                continue

            # Filter clinical flags
            if knee_safe and not e["clinical"]["knee_friendly"]:
                continue
            if lumbar_safe and not e["clinical"]["lumbar_friendly"]:
                continue
            if shoulder_safe and not e["clinical"]["shoulder_friendly"]:
                continue
            if reduced_mobility and not e["clinical"]["reduced_mobility_friendly"]:
                continue

            # Score matching
            score = 0
            if q_tokens:
                overlap = len(q_tokens.intersection(e["tokens"]))
                if overlap == 0:
                    continue
                score += overlap * 3
            else:
                score = 1

            results.append((score, e))

        results.sort(key=lambda x: x[0], reverse=True)
        return [r[1] for r in results[:limit]]

catalog_service = ExerciseCatalogService()
