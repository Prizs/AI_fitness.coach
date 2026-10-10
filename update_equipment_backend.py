import sys
import re

# 1. Update WeeklyRequest in plans.py
path_plans = 'backend/app/routers/plans.py'
with open(path_plans, 'r', encoding='utf-8') as f:
    text_plans = f.read()

old_req = '''class WeeklyRequest(BaseModel):
    goal: str = Field(default="mejorar condicion fisica", max_length=120)
    level: str = Field(default="intermedio", max_length=40)
    experience_level: str = Field(default="Intermedio", max_length=40)
    intensity_preference: str = Field(default="Medio", max_length=40)
    age: int = Field(default=25, ge=12, le=100)
    weight: float = Field(default=70, gt=0, le=300)
    food_allergies: str | None = Field(default=None, max_length=1000)
    current_injuries: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)'''

new_req = '''class WeeklyRequest(BaseModel):
    goal: str = Field(default="mejorar condicion fisica", max_length=120)
    level: str = Field(default="intermedio", max_length=40)
    experience_level: str = Field(default="Intermedio", max_length=40)
    intensity_preference: str = Field(default="Medio", max_length=40)
    equipment_available: bool = Field(default=True)
    age: int = Field(default=25, ge=12, le=100)
    weight: float = Field(default=70, gt=0, le=300)
    food_allergies: str | None = Field(default=None, max_length=1000)
    current_injuries: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)'''

text_plans = text_plans.replace(old_req, new_req)

with open(path_plans, 'w', encoding='utf-8') as f:
    f.write(text_plans)

# 2. Update weekly_plan.py
path_wp = 'backend/app/services/weekly_plan.py'
with open(path_wp, 'r', encoding='utf-8') as f:
    text_wp = f.read()

old_prompt_vars = '''      exp = profile.get("experience_level", "Intermedio")
      intensity = profile.get("intensity_preference", "Medio")
      prompt = ('''

new_prompt_vars = '''      exp = profile.get("experience_level", "Intermedio")
      intensity = profile.get("intensity_preference", "Medio")
      has_equipment = profile.get("equipment_available", True)
      equip_rule = "" if has_equipment else "CRITICO: El usuario NO TIENE EQUIPO. Debes usar EXCLUSIVAMENTE ejercicios de peso corporal (calistenia/bodyweight) sin usar herramientas.\\n"
      prompt = ('''

text_wp = text_wp.replace(old_prompt_vars, new_prompt_vars)

old_critico = '''          "CRITICO: Si el nivel es 'Principiante', escoge ejercicios ultra-basicos, de intensidad " + str(intensity) + ".\\n"'''
new_critico = '''          "CRITICO: Si el nivel es 'Principiante', escoge ejercicios ultra-basicos, de intensidad " + str(intensity) + ".\\n"
          + equip_rule +'''

text_wp = text_wp.replace(old_critico, new_critico)

with open(path_wp, 'w', encoding='utf-8') as f:
    f.write(text_wp)
