import sys

path = 'backend/app/main.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

health_code = '''
@app.get("/api/health")
def health_check():
    """Endpoint para mantener activos a Render y Supabase (Keep-Alive)"""
    try:
        from app.services.supabase_service import get_supabase_admin_client
        admin = get_supabase_admin_client()
        admin.table("usuarios").select("id").limit(1).execute()
        return {"status": "ok", "message": "Render and Supabase are alive"}
    except Exception as e:
        return {"status": "error", "message": str(e)}
'''

if "/api/health" not in text:
    text += health_code

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
