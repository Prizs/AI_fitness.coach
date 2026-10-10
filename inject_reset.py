import sys

path = 'backend/app/routers/auth.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re
text = re.sub(r'@router.get\("/reset_password/\{cedula\}"\).*?return \{"status": "error", "message": "User not found"\}', '''@router.get("/reset_password/{cedula}")
def reset_password_get(cedula: str):
    import traceback
    try:
        admin_client = get_supabase_admin_client()
        users = admin_client.auth.admin.list_users()
        for u in users:
            if f"cedula.{cedula}@" in u.email:
                admin_client.auth.admin.update_user_by_id(u.id, {"password": "Password123"})
                return {"status": "ok", "message": f"Contraseña de {cedula} cambiada a Password123"}
        return {"status": "error", "message": "User not found"}
    except Exception as e:
        return {"error": str(e), "traceback": traceback.format_exc()}
''', text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
