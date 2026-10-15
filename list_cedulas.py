import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv(os.path.join(os.getcwd(), '.env'))
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

supabase: Client = create_client(url, key)
users = supabase.auth.admin.list_users()
for u in users:
    if 'cedula.2997' in u.email:
        print(u.email)
