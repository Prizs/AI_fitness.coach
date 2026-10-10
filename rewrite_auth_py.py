import sys
import re

path = 'backend/app/routers/auth.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update RegisterRequest
old_fields = '''    zonas_a_evitar: str | None = Field(default=None, max_length=500)'''
new_fields = '''    zonas_a_evitar: str | None = Field(default=None, max_length=500)
    role: str = Field(default="client")
    specialty: str | None = Field(default=None)
    experience_years: int | None = Field(default=None)
    certifications: str | None = Field(default=None)'''
text = text.replace(old_fields, new_fields)

# 2. Update user_metadata inside register endpoint
old_meta = '''        user_metadata = {
            "name": req.nombre,
            "last_name": req.apellido,
            "age": req.edad,
            "weight": req.peso,
            "pathology_or_allergies": req.patologia_o_alergias,
            "security_question": req.security_question,
            "security_answer": req.security_answer,
            "food_allergies": req.alergias_alimentarias,
            "current_injuries": req.lesiones_actuales,
            "motor_disability": req.discapacidad_motora,
            "areas_to_avoid": req.zonas_a_evitar
        }'''
new_meta = '''        user_metadata = {
            "name": req.nombre,
            "last_name": req.apellido,
            "age": req.edad,
            "weight": req.peso,
            "pathology_or_allergies": req.patologia_o_alergias,
            "security_question": req.security_question,
            "security_answer": req.security_answer,
            "food_allergies": req.alergias_alimentarias,
            "current_injuries": req.lesiones_actuales,
            "motor_disability": req.discapacidad_motora,
            "areas_to_avoid": req.zonas_a_evitar,
            "role": req.role,
            "specialty": req.specialty,
            "experience_years": req.experience_years,
            "certifications": req.certifications
        }'''
text = text.replace(old_meta, new_meta)

# 3. Update insert into usuarios
old_insert = '''        user_res = admin_client.table("usuarios").insert({
            "id": req.cedula,
            "nombre": req.nombre,
            "apellido": req.apellido,
            "edad": req.edad,
            "peso": req.peso,
            "patologia_o_alergias": req.patologia_o_alergias,
            "alergias_alimentarias": req.alergias_alimentarias,
            "lesiones_actuales": req.lesiones_actuales,
            "discapacidad_motora": req.discapacidad_motora,
            "zonas_a_evitar": req.zonas_a_evitar
        }).execute()'''

new_insert = '''        user_res = admin_client.table("usuarios").insert({
            "id": req.cedula,
            "nombre": req.nombre,
            "apellido": req.apellido,
            "edad": req.edad,
            "peso": req.peso,
            "patologia_o_alergias": req.patologia_o_alergias,
            "alergias_alimentarias": req.alergias_alimentarias,
            "lesiones_actuales": req.lesiones_actuales,
            "discapacidad_motora": req.discapacidad_motora,
            "zonas_a_evitar": req.zonas_a_evitar,
            "role": req.role,
            "specialty": req.specialty,
            "experience_years": req.experience_years,
            "certifications": req.certifications
        }).execute()'''
text = text.replace(old_insert, new_insert)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
