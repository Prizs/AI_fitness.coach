import sys

path = 'backend/requirements.txt'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

if 'python-multipart' not in text:
    text += '\npython-multipart\n'

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
