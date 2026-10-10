import sys
path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re
text = re.sub(r"'goal': profile\?.userGoal \?\? .*?,", "'goal': 'mejorar condicion fisica',", text)
text = re.sub(r"'level': profile\?.userLevel \?\? .*?,", "'level': 'principiante',", text)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
