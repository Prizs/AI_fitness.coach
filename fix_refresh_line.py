import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
lines = []
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'Future<void> refresh(' in line:
        # replace the signature
        lines.insert(i+1, "    String goal = 'Mejorar condición física general',\n")
        break

for i, line in enumerate(lines):
    if 'experienceLevel: experienceLevel,' in line and 'intensityPreference' in lines[i+1]:
        # we are inside _fetchAndSave call of refresh
        lines.insert(i, "      goal: goal,\n")
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
