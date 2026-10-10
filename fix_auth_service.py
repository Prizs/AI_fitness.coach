import sys

path = 'mobile_app/lib/services/auth_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_register = '''  Future<void> register(UserProfile user, String? sq, String? sa) async {
    final response = await http.post(
      Uri.parse('\/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cedula': user.cedula,
        'password': user.password,
        'name': user.name,
        'last_name': user.lastName,
        'age': user.age,
        'weight': user.weight,
        'pathology_or_allergies': user.pathologyOrAllergies,
        'food_allergies': user.foodAllergies,
        'current_injuries': user.currentInjuries,
        'motor_disability': user.motorDisability,
        'areas_to_avoid': user.areasToAvoid,
        'security_question': sq,
        'security_answer': sa,
      }),
    );'''

new_register = '''  Future<void> register(UserProfile user, String? sq, String? sa) async {
    final response = await http.post(
      Uri.parse('\/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cedula': user.cedula,
        'password': user.password,
        'name': user.name,
        'last_name': user.lastName,
        'age': user.age,
        'weight': user.weight,
        'pathology_or_allergies': user.pathologyOrAllergies,
        'food_allergies': user.foodAllergies,
        'current_injuries': user.currentInjuries,
        'motor_disability': user.motorDisability,
        'areas_to_avoid': user.areasToAvoid,
        'security_question': sq,
        'security_answer': sa,
        'role': user.role,
        'specialty': user.specialty,
        'experience_years': user.experienceYears,
        'certifications': user.certifications,
      }),
    );'''

text = text.replace(old_register, new_register)

old_login = '''          age: userData['age'] ?? 25,
          weight: (userData['weight'] ?? 70).toDouble(),
          pathologyOrAllergies: userData['pathology_or_allergies'],
          foodAllergies: userData['food_allergies'],
          currentInjuries: userData['current_injuries'],
          motorDisability: userData['motor_disability'],
          areasToAvoid: userData['areas_to_avoid'],
        );
        notifyListeners();'''

new_login = '''          age: userData['age'] ?? 25,
          weight: (userData['weight'] ?? 70).toDouble(),
          pathologyOrAllergies: userData['pathology_or_allergies'],
          foodAllergies: userData['food_allergies'],
          currentInjuries: userData['current_injuries'],
          motorDisability: userData['motor_disability'],
          areasToAvoid: userData['areas_to_avoid'],
          role: userData['role'] ?? 'client',
          specialty: userData['specialty'],
          experienceYears: userData['experience_years'],
          certifications: userData['certifications'],
        );
        notifyListeners();'''

text = text.replace(old_login, new_login)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
