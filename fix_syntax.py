import sys
import re

path = 'mobile_app/lib/screens/trainer_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the broken interpolation
text = text.replace("Text('Meta: \', style:", "Text('Meta: ' + client['goal'], style:")
text = text.replace("Text('Foto (\', style:", "Text('Foto (' + client['last_photo'] + ')', style:")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
