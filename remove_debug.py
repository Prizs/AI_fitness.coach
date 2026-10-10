import sys

path = 'mobile_app/lib/screens/auth/login_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re
text = re.sub(r'// DEBUG ALERT.*?widget\.onLoginSuccess\(\);', 'widget.onLoginSuccess();', text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
