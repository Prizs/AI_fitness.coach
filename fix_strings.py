import os

path = 'mobile_app/lib/widgets/plan_options_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the broken lines
old1 = "Text('Herramientas\n" + "en Casa', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))"
new1 = r"Text('Herramientas\nen Casa', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))"
text = text.replace(old1, new1)

old2 = "Text('Sin\n" + "Herramientas', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))"
new2 = r"Text('Sin\nHerramientas', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))"
text = text.replace(old2, new2)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
