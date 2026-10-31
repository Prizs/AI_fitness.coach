class UserProfile {
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
    this.gender = 'masculino',
    this.specialty,
    this.experienceYears,
    this.certifications,
    this.archetype,
  });

  final String cedula;
  final String password;
  final String name;
  final String lastName;
  final int age;
  final double weight;
  final String gender;
  final String? pathologyOrAllergies;
  final String? foodAllergies;
  final String? currentInjuries;
  final String? motorDisability;
  final String? areasToAvoid;
  final String role;
  final String? specialty;
  final int? experienceYears;
  final String? certifications;
  String? archetype;
}
