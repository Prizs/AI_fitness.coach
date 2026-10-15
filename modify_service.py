import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Update _fetchAndSave
old_fetch_sig = '''  Future<void> _fetchAndSave(
    UserProfile? profile, {
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {'''

new_fetch_sig = '''  Future<void> _fetchAndSave(
    UserProfile? profile, {
    String goal = 'Mejorar condición física general',
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {'''

text = text.replace(old_fetch_sig, new_fetch_sig)

old_body = '''            body: jsonEncode({
              'goal': 'mejorar condicion fisica',
              'level': 'principiante',
              'age': profile?.age ?? 25,'''

new_body = '''            body: jsonEncode({
              'goal': goal,
              'level': experienceLevel.toLowerCase(),
              'age': profile?.age ?? 25,'''

text = text.replace(old_body, new_body)


# Update refresh
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

text = text.replace(old_refresh, new_refresh)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
