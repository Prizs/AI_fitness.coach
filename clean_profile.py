import os

path = 'mobile_app/lib/screens/trainer/trainer_profile_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

replacements = {
    'PÃ©rdida': 'Pérdida',
    'RehabilitaciÃ³n': 'Rehabilitación',
    'CertificaciÃ³n': 'Certificación',
    'SesiÃ³n': 'Sesión',
}

for k, v in replacements.items():
    text = text.replace(k, v)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

shell_path = 'mobile_app/lib/screens/trainer/trainer_shell.dart'
with open(shell_path, 'r', encoding='utf-8') as f:
    text = f.read()

for k, v in replacements.items():
    text = text.replace(k, v)

with open(shell_path, 'w', encoding='utf-8') as f:
    f.write(text)
