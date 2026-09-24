import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile_app/models/user_profile.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  UserProfile? loggedInUser;
  String? accessToken;

  Future<bool> register(UserProfile profile) async {
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
        }),
      );
    } on Exception {
      return false;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    accessToken = data['access_token'] as String?;
    loggedInUser = profile;
    return true;
  }

  Future<bool> login(String cedula, String password) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cedula': cedula, 'password': password}),
      );
    } on Exception {
      return false;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
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
    );
    return true;
  }

  void logout() {
    loggedInUser = null;
    accessToken = null;
  }
}
