import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_refresh = '''  Future<void> refresh(
    UserProfile? profile, {
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {
    await DBHelper.instance.clearWeeklyPlan();
    await _fetchAndSave(
      profile,
      experienceLevel: experienceLevel,
      intensityPreference: intensityPreference,
      equipmentAvailable: equipmentAvailable,
    );
  }'''

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

text = text.replace(old_refresh.replace('\n', '\r\n'), new_refresh.replace('\n', '\r\n'))
text = text.replace(old_refresh, new_refresh)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
