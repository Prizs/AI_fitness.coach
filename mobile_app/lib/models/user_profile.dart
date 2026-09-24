class UserProfile {
  UserProfile({
    required this.cedula,
    required this.password,
    required this.name,
    required this.lastName,
    required this.age,
    required this.weight,
    this.pathologyOrAllergies,
  });

  final String cedula;
  final String password;
  final String name;
  final String lastName;
  final int age;
  final double weight;
  final String? pathologyOrAllergies;
}
