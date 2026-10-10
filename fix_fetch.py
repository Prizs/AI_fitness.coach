import sys
import re

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_fetch = '''  Future<void> _fetchAndSave(UserProfile? profile) async {
    try {
      final response = await http
          .post(
            Uri.parse('\/api/plans/weekly'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'goal': 'mejorar condicion fisica',
              'level': 'principiante',
              'age': profile?.age ?? 25,
              'weight': profile?.weight ?? 70,
              'food_allergies': profile?.foodAllergies,
              'current_injuries': profile?.currentInjuries,
              'areas_to_avoid': profile?.areasToAvoid,
            }),'''

new_fetch = '''  Future<void> _fetchAndSave(
    UserProfile? profile, {
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('\/api/plans/weekly'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'goal': 'mejorar condicion fisica',
              'level': experienceLevel.toLowerCase(),
              'experience_level': experienceLevel,
              'intensity_preference': intensityPreference,
              'equipment_available': equipmentAvailable,
              'age': profile?.age ?? 25,
              'weight': profile?.weight ?? 70,
              'food_allergies': profile?.foodAllergies,
              'current_injuries': profile?.currentInjuries,
              'areas_to_avoid': profile?.areasToAvoid,
            }),'''

text = text.replace(old_fetch, new_fetch)

old_refresh = '''  Future<void> refresh(UserProfile? profile) async {
    isLoading = true;
    notifyListeners();
    await _fetchAndSave(profile);
  }'''

new_refresh = '''  Future<void> refresh(
    UserProfile? profile, {
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {
    isLoading = true;
    notifyListeners();
    await _fetchAndSave(
      profile,
      experienceLevel: experienceLevel,
      intensityPreference: intensityPreference,
      equipmentAvailable: equipmentAvailable,
    );
  }'''

text = text.replace(old_refresh, new_refresh)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
