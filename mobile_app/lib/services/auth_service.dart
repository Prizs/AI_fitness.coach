import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_app/models/user_profile.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  UserProfile? loggedInUser;
  String? accessToken;
  String? lastError;
  final _storage = const FlutterSecureStorage();

  Future<bool> restoreSession() async {
    final cedula = await _storage.read(key: 'cedula');
    final token = await _storage.read(key: 'access_token');
    final name = await _storage.read(key: 'name');
    final lastName = await _storage.read(key: 'last_name');
    final age = int.tryParse(await _storage.read(key: 'age') ?? '');
    final weight = double.tryParse(await _storage.read(key: 'weight') ?? '');
    if (cedula == null ||
        token == null ||
        name == null ||
        lastName == null ||
        age == null ||
        weight == null) {
      return false;
    }
    accessToken = token;
    loggedInUser = UserProfile(
      cedula: cedula,
      name: name,
      lastName: lastName,
      age: age,
      weight: weight,
      pathologyOrAllergies: await _storage.read(key: 'health_notes'),
      foodAllergies: await _storage.read(key: 'food_allergies'),
      currentInjuries: await _storage.read(key: 'current_injuries'),
      motorDisability: await _storage.read(key: 'motor_disability'),
      areasToAvoid: await _storage.read(key: 'areas_to_avoid'),
    );
    return true;
  }

  Future<bool> register(UserProfile profile) async {
    lastError = null;
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cedula': profile.cedula,
          'password': profile.password,
          'nombre': profile.name,
          'apellido': profile.lastName,
          'edad': profile.age,
          'peso': profile.weight,
          'patologia_o_alergias': profile.pathologyOrAllergies,
          'alergias_alimentarias': profile.foodAllergies,
          'lesiones_actuales': profile.currentInjuries,
          'discapacidad_motora': profile.motorDisability,
          'zonas_a_evitar': profile.areasToAvoid,
        }),
      );
    } on Exception {
      lastError = 'No se pudo conectar con el servidor.';
      return false;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        lastError =
            data['detail'] as String? ?? 'No se pudo completar el registro.';
      } on Exception {
        lastError = 'No se pudo completar el registro.';
      }
      return false;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    accessToken = data['access_token'] as String?;
    loggedInUser = profile;
    await _saveSession(profile.cedula, accessToken);
    return true;
  }

  Future<bool> login(String cedula, String password) async {
    lastError = null;
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cedula': cedula, 'password': password}),
      );
    } on Exception {
      lastError = 'No se pudo conectar con el servidor.';
      return false;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        lastError =
            data['detail'] as String? ?? 'Cédula o contraseña incorrectos.';
      } on Exception {
        lastError = 'Cédula o contraseña incorrectos.';
      }
      return false;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    accessToken = data['access_token'] as String?;
    loggedInUser = UserProfile(
      cedula: user['cedula'] as String? ?? cedula,
      password: password,
      name: user['nombre'] as String? ?? '',
      lastName: user['apellido'] as String? ?? '',
      age: user['edad'] as int? ?? 0,
      weight: (user['peso'] as num?)?.toDouble() ?? 0,
      pathologyOrAllergies: user['patologia_o_alergias'] as String?,
      foodAllergies: user['alergias_alimentarias'] as String?,
      currentInjuries: user['lesiones_actuales'] as String?,
      motorDisability: user['discapacidad_motora'] as String?,
      areasToAvoid: user['zonas_a_evitar'] as String?,
    );
    await _saveSession(loggedInUser!.cedula, accessToken);
    return true;
  }

  Future<void> _saveSession(String cedula, String? token) async {
    if (token == null) return;
    await _storage.write(key: 'cedula', value: cedula);
    await _storage.write(key: 'access_token', value: token);
    final profile = loggedInUser;
    if (profile != null) {
      await _storage.write(key: 'name', value: profile.name);
      await _storage.write(key: 'last_name', value: profile.lastName);
      await _storage.write(key: 'age', value: profile.age.toString());
      await _storage.write(key: 'weight', value: profile.weight.toString());
      await _storage.write(
        key: 'health_notes',
        value: profile.pathologyOrAllergies,
      );
      await _storage.write(key: 'food_allergies', value: profile.foodAllergies);
      await _storage.write(
        key: 'current_injuries',
        value: profile.currentInjuries,
      );
      await _storage.write(
        key: 'motor_disability',
        value: profile.motorDisability,
      );
      await _storage.write(key: 'areas_to_avoid', value: profile.areasToAvoid);
    }
  }

  void logout() {
    loggedInUser = null;
    accessToken = null;
    _storage.deleteAll();
  }
}
