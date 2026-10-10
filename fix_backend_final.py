import sys

path = 'backend/app/routers/auth.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix register profile dictionary
old_profile = '''        profile = {
            "id": auth_response.user.id,
            "cedula": payload.cedula,
            "nombre": payload.nombre,
            "apellido": payload.apellido,
            "edad": payload.edad,
            "peso": payload.peso,
            "patologia_o_alergias": payload.patologia_o_alergias,
            "alergias_alimentarias": payload.alergias_alimentarias,
            "lesiones_actuales": payload.lesiones_actuales,
            "discapacidad_motora": payload.discapacidad_motora,
            "zonas_a_evitar": payload.zonas_a_evitar,
        }'''

new_profile = '''        profile = {
            "id": auth_response.user.id,
            "cedula": payload.cedula,
            "nombre": payload.nombre,
            "apellido": payload.apellido,
            "edad": payload.edad,
            "peso": payload.peso,
            "patologia_o_alergias": payload.patologia_o_alergias,
            "alergias_alimentarias": payload.alergias_alimentarias,
            "lesiones_actuales": payload.lesiones_actuales,
            "discapacidad_motora": payload.discapacidad_motora,
            "zonas_a_evitar": payload.zonas_a_evitar,
            "role": payload.role,
            "specialty": payload.specialty,
            "experience_years": payload.experience_years,
            "certifications": payload.certifications,
        }'''
text = text.replace(old_profile, new_profile)

# 2. Fix login select statement
old_select = '''            admin_client.table("usuarios")
            .select("id, cedula, nombre, apellido, edad, peso, patologia_o_alergias, alergias_alimentarias, lesiones_actuales, discapacidad_motora, zonas_a_evitar")'''

new_select = '''            admin_client.table("usuarios")
            .select("id, cedula, nombre, apellido, edad, peso, patologia_o_alergias, alergias_alimentarias, lesiones_actuales, discapacidad_motora, zonas_a_evitar, role, specialty, experience_years, certifications")'''

text = text.replace(old_select, new_select)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
