
from fastapi import APIRouter
from pydantic import BaseModel
import json
import os
import difflib
from typing import Optional

router = APIRouter()

# Load DB
db_path = os.path.join(os.path.dirname(__file__), '..', 'gifs_db.json')
with open(db_path, 'r', encoding='utf-8') as f:
    gif_paths = json.load(f)

# Basic translation dictionary for common keywords
SPANISH_TO_ENGLISH = {
    'sentadilla': 'squat',
    'profunda': '',
    'barra': 'barbell',
    'mancuerna': 'dumbbell',
    'press': 'press',
    'militar': 'military',
    'pecho': 'chest',
    'banco': 'bench',
    'plano': 'flat',
    'inclinado': 'incline',
    'declinado': 'decline',
    'peso': 'dead',
    'muerto': 'lift',
    'dominadas': 'pull up',
    'remo': 'row',
    'biceps': 'biceps',
    'triceps': 'triceps',
    'curl': 'curl',
    'extension': 'extension',
    'elevacion': 'raise',
    'lateral': 'lateral',
    'frontal': 'front',
    'pantorrilla': 'calf',
    'gemelos': 'calf',
    'zancada': 'lunge',
    'desplante': 'lunge',
    'polea': 'cable',
    'cruzado': 'crossover',
    'copa': 'goblet',
    'bici': 'bike',
    'bicicleta': 'bike',
    'estacionaria': 'stationary',
    'suave': '',
    'maquina': 'machine',
    'fondos': 'dip',
    'plancha': 'plank'
}

def translate_query(query: str) -> str:
    query = query.lower()
    for esp, eng in SPANISH_TO_ENGLISH.items():
        if esp in query:
            query = query.replace(esp, eng)
    return query.strip().replace('  ', ' ')

@router.get('/gif')
def get_exercise_gif(query: str):
    eng_query = translate_query(query).replace(' ', '-')
    eng_query_parts = eng_query.split('-')
    
    best_match = None
    best_score = 0
    
    for path in gif_paths:
        filename = path.split('/')[-1].replace('.gif', '')
        # Simple scoring
        score = sum(1 for p in eng_query_parts if len(p) > 2 and p in filename)
        if score > best_score:
            best_score = score
            best_match = path
            
    if best_match and best_score > 0:
        return {'url': f'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/{best_match}', 'query': query, 'translated': eng_query}
    return {'url': None, 'query': query}

