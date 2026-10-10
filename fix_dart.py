import sys

path = 'mobile_app/lib/screens/trainer_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re
text = re.sub(r'\"Tu Código de Entrenador es:\\n\\\',\s*textAlign', '\"Tu Código de Entrenador es:\\n\\",\n              textAlign', text)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
