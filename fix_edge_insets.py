import os

path = 'mobile_app/lib/screens/trainer/trainer_messages_tab.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("EdgeInsets.top(4)", "EdgeInsets.only(top: 4)")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
