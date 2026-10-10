import sys

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re

# We need to make sure ALL _fetchAndSave calls have no required named parameters, or provide defaults in the method definition.
# Wait, if they are named parameters, experienceLevel: experienceLevel works. But the definition of _fetchAndSave didn't get updated properly.

text = re.sub(
    r'Future<void> _fetchAndSave\(UserProfile\? profile\) async \{',
    r'''Future<void> _fetchAndSave(
    UserProfile? profile, {
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {''',
    text
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
