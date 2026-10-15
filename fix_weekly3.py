import os
import re

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r"lastError = 'Error local: \$\{error.runtimeType\}\.';", "lastError = 'Hubo un error local cargando la rutina (Caché). Intenta crear una nueva.';", text)
text = re.sub(r"lastError = 'No se pudo conectar: \$\{error.runtimeType\}\.';", "lastError = 'Aviso: La generación tomó mucho tiempo o falló. Vuelve a intentarlo.';", text)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
