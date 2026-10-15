import os

path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Intercept "_sendMessage" if text == 'Crear nueva rutina de entrenamiento'
old_send = '''  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;'''

new_send = '''  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (text == 'Crear nueva rutina de entrenamiento') {
      showPlanOptionsSheet(context);
      return;
    }'''

text = text.replace(old_send, new_send)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
