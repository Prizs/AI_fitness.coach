import re

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace refresh method
old_refresh = r'  Future<void> refresh\(\s*UserProfile\? profile,\s*\{\s*String experienceLevel.*?equipmentAvailable:\s*equipmentAvailable,\s*\);\s*\}'
new_refresh = '''  Future<void> refresh(
    UserProfile? profile, {
    String goal = 'Mejorar condición física general',
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {
    await DBHelper.instance.clearWeeklyPlan();
    await _fetchAndSave(
      profile,
      goal: goal,
      experienceLevel: experienceLevel,
      intensityPreference: intensityPreference,
      equipmentAvailable: equipmentAvailable,
    );
  }'''

text = re.sub(old_refresh, new_refresh, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
