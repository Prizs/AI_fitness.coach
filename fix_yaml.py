import sys

path = 'mobile_app/pubspec.yaml'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("\\n", "\n")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

path2 = 'mobile_app/lib/screens/coach_screen.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()

text2 = text2.replace("\\n", "\n")

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)
