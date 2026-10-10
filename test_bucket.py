import os
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

load_dotenv('.env')

url = os.environ.get('SUPABASE_URL')
key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')

supabase = create_client(url, key)

try:
    print(supabase.storage.create_bucket('app_releases', options={'public': True}))
    print('Bucket created!')
except Exception as e:
    print('Error:', e)
