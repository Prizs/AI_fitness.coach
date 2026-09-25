import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/services/auth_service.dart';

class PlanService {
  static String get apiBaseUrl => AuthService.apiBaseUrl;

  String? lastError;

  /// Genera el plan para un perfil real. Devuelve null si no hay perfil,
  /// si la red falla o si el backend no responde con un plan válido.
  Future<Map<String, dynamic>?> generate(UserProfile? profile) async {
    lastError = null;
    if (profile == null) {
      lastError = 'Necesitas un perfil para generar tu plan.';
      return null;
    }
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/plans/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'goal': 'mejorar condición física',
              'level': 'principiante',
              'days_per_week': 3,
              'age': profile.age,
              'weight': profile.weight,
              'health_notes': profile.pathologyOrAllergies,
              'food_allergies': profile.foodAllergies,
              'current_injuries': profile.currentInjuries,
              'motor_disability': profile.motorDisability,
              'areas_to_avoid': profile.areasToAvoid,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        lastError =
            'El servidor respondió con un error (${response.statusCode}).';
        return null;
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        lastError = 'Formato de plan inesperado.';
        return null;
      }
      return data;
    } on Exception catch (error) {
      lastError = 'No se pudo conectar con el servidor: ${error.runtimeType}.';
      return null;
    }
  }
}