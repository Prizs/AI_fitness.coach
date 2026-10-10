import os
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

load_dotenv('.env')

url = os.environ.get('SUPABASE_URL')
key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')

supabase = create_client(url, key)

apk_path = 'mobile_app/build/app/outputs/flutter-apk/app-v1.0.30.apk'
with open(apk_path, 'rb') as f:
    supabase.storage.from_('app_releases').upload(
        path='app-v1.0.30.apk',
        file=f,
        file_options={'content-type': 'application/vnd.android.package-archive', 'upsert': 'true'}
    )
print('APK uploaded successfully!')
print(supabase.storage.from_('app_releases').get_public_url('app-v1.0.30.apk'))
