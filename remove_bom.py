path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'rb') as f:
    content = f.read()

# Strip UTF-8 BOM if present
if content.startswith(b'\xef\xbb\xbf'):
    content = content[3:]
    with open(path, 'wb') as f:
        f.write(content)
    print("Stripped BOM")
else:
    print("No BOM found at start")

# Also check for embedded BOM bytes
cleaned = content.replace(b'\xef\xbb\xbf', b'')
if cleaned != content:
    with open(path, 'wb') as f:
        f.write(cleaned)
    print("Cleaned embedded BOM")
