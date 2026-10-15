import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
lines = []
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip = False
for i, line in enumerate(lines):
    if skip:
        if '}) async {' in line:
            skip = False
            new_lines.append(line)
        continue
        
    if 'Future<void> refresh(' in line:
        new_lines.append(line)
        new_lines.append("    UserProfile? profile, {\n")
        new_lines.append("    String goal = 'Mejorar condición física general',\n")
        new_lines.append("    String experienceLevel = 'Intermedio',\n")
        new_lines.append("    String intensityPreference = 'Medio',\n")
        new_lines.append("    bool equipmentAvailable = true,\n")
        skip = True
    else:
        new_lines.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
