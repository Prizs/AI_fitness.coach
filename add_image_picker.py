import sys

path = 'mobile_app/pubspec.yaml'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('speech_to_text: ^6.6.1', 'speech_to_text: ^6.6.1\n  image_picker: ^1.1.2\n  image_picker_web: ^3.1.1\n  http_parser: ^4.0.2')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
