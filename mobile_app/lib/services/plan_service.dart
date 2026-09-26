import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/services/auth_service.dart';

class PlanService {
  PlanService();

  static String get apiBaseUrl => AuthService.apiBaseUrl;

  /// El plan guardado en el dispositivo se considera vigente durante 6 horas.
  static const Duration cacheTtl = Duration(hours: 6);
  static const String _cacheKey = 'cached_plan_v1';

  final _storage = const FlutterSecureStorage();

  String? lastError;
  bool lastFromCache = false;

  /// Firma del perfil: si cambia, la cache deja de servir.
  String _signature(UserProfile profile) => jsonEncode([
        profile.age,
        profile.weight,
        profile.pathologyOrAllergies,
        profile.foodAllergies,
        profile.currentInjuries,
        profile.motorDisability,
        profile.areasToAvoid,
      ]);

  /// Devuelve el plan guardando en cache. Prioriza la copia local para que
  /// las pestanas Rutinas y Nutricion abran al instante.
  Future<Map<String, dynamic>?> generate(
    UserProfile? profile, {
    bool forceRefresh = false,
  }) async {
    lastError = null;
    lastFromCache = false;
    if (profile == null) {
      lastError = 'Necesitas un perfil para generar tu plan.';
      return null;
    }

    if (!forceRefresh) {
      final cached = await _readCache(profile);
      if (cached != null) {
        lastFromCache = true;
        return cached;
      }
    }

    final plan = await _fetchFromServer(profile);
    if (plan != null) {
      await _writeCache(profile, plan);
    }
    return plan;
  }

  /// Borra el plan guardado (por ejemplo al cambiar de usuario).
  Future<void> clearCache() async {
    try {
      await _storage.delete(key: _cacheKey);
    } on Exception {
      // Sin cache que limpiar.
    }
  }

  Future<Map<String, dynamic>?> _readCache(UserProfile profile) async {
    try {
      final raw = await _storage.read(key: _cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['signature'] != _signature(profile)) return null;

      final savedAt = DateTime.tryParse('${decoded['saved_at']}');
      if (savedAt == null) return null;
      if (DateTime.now().difference(savedAt) > cacheTtl) return null;

      final plan = decoded['plan'];
      return plan is Map<String, dynamic> ? plan : null;
    } on Exception {
      return null;
    }
  }

  Future<void> _writeCache(
    UserProfile profile,
    Map<String, dynamic> plan,
  ) async {
    try {
      await _storage.write(
        key: _cacheKey,
        value: jsonEncode({
          'saved_at': DateTime.now().toIso8601String(),
          'signature': _signature(profile),
          'plan': plan,
        }),
      );
    } on Exception {
      // Si no se puede guardar, la app sigue funcionando igual.
    }
  }

  Future<Map<String, dynamic>?> _fetchFromServer(UserProfile profile) async {
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
          .timeout(const Duration(seconds: 45));

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