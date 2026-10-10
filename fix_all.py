# -*- coding: utf-8 -*-
import os

replacements = {
    'Ã³': 'ó',
    'Ã±': 'ñ',
    'Ã­': 'í',
    'Ã©': 'é',
    'Ã¡': 'á',
    'Â¡': '¡',
    'Â¿': '¿',
    'Ã“': 'Ó',
    'Ãš': 'Ú',
    'Ãº': 'ú'
}

for root, dirs, files in os.walk('mobile_app/lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            modified = False
            for bad, good in replacements.items():
                if bad in content:
                    content = content.replace(bad, good)
                    modified = True
            
            if modified:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
