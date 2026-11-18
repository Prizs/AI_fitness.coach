# -*- coding: utf-8 -*-
"""
Script de Keep-Alive para AI Fitness Coach.
Mantiene el servidor de Render activo de 7:00 AM a 7:00 PM (Hora de Venezuela, UTC-4).
A partir de las 7:00 PM, reposa automáticamente para que Render duerma y no consuma horas.
"""

import time
import urllib.request
from datetime import datetime, timezone, timedelta

URL = "https://ai-fitness-coach-wlg3.onrender.com/health"


def is_within_business_hours_vet() -> bool:
    """Verifica si la hora actual en Venezuela (UTC-4) está entre 7:00 AM y 7:00 PM."""
    vet = timezone(timedelta(hours=-4))
    now_vet = datetime.now(vet)
    return 7 <= now_vet.hour < 19


def main():
    print(f"[{datetime.now()}] Iniciando monitor inteligente de Keep-Alive...")
    print(f"Horario despierto (0 delay): 7:00 AM a 7:00 PM VET")
    print(f"Horario reposo (ahorro Render): 7:00 PM a 7:00 AM VET")

    while True:
        if is_within_business_hours_vet():
            try:
                with urllib.request.urlopen(URL, timeout=15) as resp:
                    print(f"[{datetime.now()}] Ping diurno exitoso. Status: {resp.status}")
            except Exception as e:
                print(f"[{datetime.now()}] Error en ping: {e}")
        else:
            print(f"[{datetime.now()}] Fuera de horario (7:00 PM - 7:00 AM VET). Reposando para ahorrar horas.")

        # Ping cada 10 minutos (600 segundos)
        time.sleep(600)


if __name__ == "__main__":
    main()
