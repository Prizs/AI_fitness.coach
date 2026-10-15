import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv(os.path.join(os.getcwd(), '.env'))

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not key:
    print("No service role key")
    exit()

supabase: Client = create_client(url, key)

cedula = '29977666'
email_to_find = f"cedula.{cedula}@"

users = supabase.auth.admin.list_users()
for u in users:
    if email_to_find in u.email:
        supabase.auth.admin.update_user_by_id(u.id, {"password": "Password123"})
        print(f"Password reset to Password123 for {cedula}")
        break
else:
    print("User not found.")
