import sys
import re

path = 'backend/app/routers/auth.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Update RegisterRequest
old_req = '''class RegisterRequest(BaseModel):
    cedula: str
    password: str
    name: str
    last_name: str
    age: int
    weight: float
    pathology_or_allergies: Optional[str] = None
    food_allergies: Optional[str] = None
    current_injuries: Optional[str] = None
    motor_disability: Optional[str] = None
    areas_to_avoid: Optional[str] = None
    security_question: Optional[str] = None
    security_answer: Optional[str] = None'''

new_req = '''class RegisterRequest(BaseModel):
    cedula: str
    password: str
    name: str
    last_name: str
    age: int = 25
    weight: float = 70.0
    pathology_or_allergies: Optional[str] = None
    food_allergies: Optional[str] = None
    current_injuries: Optional[str] = None
    motor_disability: Optional[str] = None
    areas_to_avoid: Optional[str] = None
    security_question: Optional[str] = None
    security_answer: Optional[str] = None
    role: str = "client"
    specialty: Optional[str] = None
    experience_years: Optional[int] = None
    certifications: Optional[str] = None'''

text = text.replace(old_req, new_req)

# Update the metadata building inside register_user
old_meta = '''        user_metadata = {
            "name": req.name,
            "last_name": req.last_name,
            "age": req.age,
            "weight": req.weight,
            "pathology_or_allergies": req.pathology_or_allergies,
            "food_allergies": req.food_allergies,
            "current_injuries": req.current_injuries,
            "motor_disability": req.motor_disability,
            "areas_to_avoid": req.areas_to_avoid,
            "security_question": req.security_question,
            "security_answer": req.security_answer
        }'''

new_meta = '''        user_metadata = {
            "name": req.name,
            "last_name": req.last_name,
            "age": req.age,
            "weight": req.weight,
            "pathology_or_allergies": req.pathology_or_allergies,
            "food_allergies": req.food_allergies,
            "current_injuries": req.current_injuries,
            "motor_disability": req.motor_disability,
            "areas_to_avoid": req.areas_to_avoid,
            "security_question": req.security_question,
            "security_answer": req.security_answer,
            "role": req.role,
            "specialty": req.specialty,
            "experience_years": req.experience_years,
            "certifications": req.certifications
        }'''

text = text.replace(old_meta, new_meta)

# Update the SQL insertion inside register_user (tabla usuarios)
# We might be calling user_res = admin_client.table("usuarios").insert({...}).execute()
old_insert = '''        user_res = admin_client.table("usuarios").insert({
            "id": req.cedula,
            "name": req.name,
            "last_name": req.last_name,
            "age": req.age,
            "weight": req.weight,
            "pathology_or_allergies": req.pathology_or_allergies,
            "food_allergies": req.food_allergies,
            "current_injuries": req.current_injuries,
            "motor_disability": req.motor_disability,
            "areas_to_avoid": req.areas_to_avoid
        }).execute()'''

new_insert = '''        user_res = admin_client.table("usuarios").insert({
            "id": req.cedula,
            "name": req.name,
            "last_name": req.last_name,
            "age": req.age,
            "weight": req.weight,
            "pathology_or_allergies": req.pathology_or_allergies,
            "food_allergies": req.food_allergies,
            "current_injuries": req.current_injuries,
            "motor_disability": req.motor_disability,
            "areas_to_avoid": req.areas_to_avoid,
            "role": req.role,
            "specialty": req.specialty,
            "experience_years": req.experience_years,
            "certifications": req.certifications
        }).execute()'''

text = text.replace(old_insert, new_insert)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
