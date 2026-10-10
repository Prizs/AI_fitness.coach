import sys
import re

path = 'mobile_app/lib/screens/auth/login_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_stmt = "import 'package:mobile_app/screens/auth/forgot_password_screen.dart';"
if import_stmt not in text:
    text = text.replace("import 'package:mobile_app/screens/auth/register_screen.dart';", "import 'package:mobile_app/screens/auth/register_screen.dart';\\n" + import_stmt)

old_btn = "child: const Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(color: Colors.white70)),"
new_btn = "child: const Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(color: Colors.white70)),\\n                      ),\\n                      TextButton(\\n                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),\\n                        child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.white54)),"
text = text.replace(old_btn, new_btn)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
