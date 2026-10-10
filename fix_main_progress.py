import sys

path = 'backend/app/main.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

if 'progress' not in text:
    text = text.replace('from app.routers import app_updates, auth, coach, plans, workouts, recalibration, exercises, trainer',
                        'from app.routers import app_updates, auth, coach, plans, workouts, recalibration, exercises, trainer, progress')
    text = text.replace('app.include_router(trainer.router)', 'app.include_router(trainer.router)\\napp.include_router(progress.router)')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
