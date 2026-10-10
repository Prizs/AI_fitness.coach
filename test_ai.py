import os
import asyncio
from dotenv import load_dotenv
load_dotenv('.env')

from backend.app.services.ai_providers import configured_providers, generate_json_text

print(f"Configured Providers: {configured_providers()}")
print(f"GEMINI_API_KEY snippet: {os.getenv('GEMINI_API_KEY', '')[:5]}...")
print(f"OPENROUTER_API_KEY snippet: {os.getenv('OPENROUTER_API_KEY', '')[:5]}...")

prompt = '{"test": "Devuelve un JSON vacio de prueba {}. Solo el JSON."}'
try:
    res = generate_json_text(prompt)
    print(f"SUCCESS! Using provider: {res.provider}")
    print(f"Text returned: {res.text}")
except Exception as e:
    print(f"FAILED: {e}")

