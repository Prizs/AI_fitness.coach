import sys

# 1. Fix workouts_screen.dart
path1 = 'mobile_app/lib/screens/workouts_screen.dart'
with open(path1, 'r', encoding='utf-8') as f:
    t1 = f.read()

t1 = t1.replace("\\n", "\n")
t1 = t1.replace("\\'", "'")
with open(path1, 'w', encoding='utf-8') as f:
    f.write(t1)

# 2. Fix weekly_plan_service.dart
path2 = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path2, 'r', encoding='utf-8') as f:
    t2 = f.read()

import re
# check _fetchAndSave signature
print('Checking signature...')
print(re.search(r'_fetchAndSave\(.*?\)', t2, re.DOTALL))

# Let's completely rewrite the refresh and _fetchAndSave to be 100% sure.
# Wait, I can just find where it's failing.
