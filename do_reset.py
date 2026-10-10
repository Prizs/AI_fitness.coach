import httpx
print('Reset:', httpx.get('http://127.0.0.1:8000/api/auth/reset_password/29977661').text)
print('Users:', httpx.get('http://127.0.0.1:8000/api/auth/list_users').text)
