import sys

path = 'mobile_app/lib/models/user_profile.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_constructor = '''class UserProfile {
  UserProfile({
    required this.cedula,
    this.password = '',
    required this.name,
    required this.lastName,
    required this.age,
    required this.weight,
    this.pathologyOrAllergies,
    this.foodAllergies,
    this.currentInjuries,
    this.motorDisability,
    this.areasToAvoid,
  });'''

new_constructor = '''class UserProfile {
  UserProfile({
    required this.cedula,
    this.password = '',
    required this.name,
    required this.lastName,
    required this.age,
    required this.weight,
    this.pathologyOrAllergies,
    this.foodAllergies,
    this.currentInjuries,
    this.motorDisability,
    this.areasToAvoid,
    this.role = 'client',
    this.specialty,
    this.experienceYears,
    this.certifications,
  });'''

text = text.replace(old_constructor, new_constructor)

old_fields = '''  final String? motorDisability;
  final String? areasToAvoid;
}'''

new_fields = '''  final String? motorDisability;
  final String? areasToAvoid;
  final String role;
  final String? specialty;
  final int? experienceYears;
  final String? certifications;
}'''

text = text.replace(old_fields, new_fields)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
