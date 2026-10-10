import sys
import re

path = 'backend/app/main.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Make sure trainer is imported
if 'from app.routers import' in text and 'trainer' not in text:
    text = text.replace('from app.routers import app_updates, auth, coach, plans, workouts, recalibration, exercises',
                        'from app.routers import app_updates, auth, coach, plans, workouts, recalibration, exercises, trainer')

if 'app.include_router(trainer.router)' not in text:
    text = text.replace('app.include_router(workouts.router)', 'app.include_router(workouts.router)\\napp.include_router(trainer.router)')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
