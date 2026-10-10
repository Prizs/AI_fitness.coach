import sys
import re

path = 'mobile_app/lib/screens/progress_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the mangled URLs
text = re.sub(r"Uri\.parse\('.*?api/progress/.*?'\)", "Uri.parse('\/api/progress/\')", text, count=1)
text = re.sub(r"Uri\.parse\('.*?api/progress/upload.*?'\)", "Uri.parse('\/api/progress/upload')", text, count=1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
