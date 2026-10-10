import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv(".env")
url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

supabase = create_client(url, key)
res = supabase.table("usuarios").select("cedula, nombre, apellido").execute()
print("Usuarios registrados:")
for u in res.data:
    print(f"- {u['cedula']}: {u['nombre']} {u['apellido']}")

auth_res = supabase.auth.admin.list_users()
for u in auth_res:
    if "cedula.29977661@" in u.email:
        supabase.auth.admin.update_user_by_id(u.id, {"password": "Password123"})
        print("¡Contraseña de 29977661 cambiada a: Password123 !")
