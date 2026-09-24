import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/services/auth_service.dart';

class PlanService {
  static const apiBaseUrl = AuthService.apiBaseUrl;

  Future<Map<String, dynamic>?> generate(UserProfile profile) async {
    try {
      final response = await http.post(
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
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on Exception {
      return null;
    }
  }
}