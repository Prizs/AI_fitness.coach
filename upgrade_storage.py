import sys

path = 'mobile_app/pubspec.yaml'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('flutter_secure_storage: ^9.2.2', 'flutter_secure_storage: ^11.2.0')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
