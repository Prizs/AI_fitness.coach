import time
import urllib.request
from datetime import datetime

URL = 'https://ai-fitness-coach-818a.onrender.com/docs'

while True:
    try:
        response = urllib.request.urlopen(URL)
        print(f"[{datetime.now()}] Ping exitoso. Status: {response.status}")
    except Exception as e:
        print(f"[{datetime.now()}] Error en ping: {e}")
    
    # Render se apaga a los 15 minutos. Pingueamos cada 10 minutos (600 segundos).
    time.sleep(600)
