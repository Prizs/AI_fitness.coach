import sys

path = 'backend/app/routers/plans.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_req1 = '''class WeeklyRequest(BaseModel):
    goal: str = Field(default="mejorar condicion fisica", max_length=120)
    level: str = Field(default="intermedio", max_length=40)
    age: int = Field(default=25, ge=12, le=100)
    weight: float = Field(default=70, gt=0, le=300)
    food_allergies: str | None = Field(default=None, max_length=1000)
    current_injuries: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)'''

new_req1 = '''class WeeklyRequest(BaseModel):
    goal: str = Field(default="mejorar condicion fisica", max_length=120)
    level: str = Field(default="intermedio", max_length=40)
    experience_level: str = Field(default="Intermedio", max_length=40)
    intensity_preference: str = Field(default="Medio", max_length=40)
    age: int = Field(default=25, ge=12, le=100)
    weight: float = Field(default=70, gt=0, le=300)
    food_allergies: str | None = Field(default=None, max_length=1000)
    current_injuries: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)'''

text = text.replace(old_req1, new_req1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
