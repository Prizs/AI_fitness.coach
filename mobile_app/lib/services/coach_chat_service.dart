import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_app/services/auth_service.dart';

/// Servicio Singleton que preserva la conversación del Coach IA en memoria RAM
/// y en almacenamiento seguro local para evitar que se borren los mensajes al
/// navegar entre pestañas, módulos o salir y volver al Coach.
class CoachChatService extends ChangeNotifier {
  static final CoachChatService instance = CoachChatService._internal();
  CoachChatService._internal();

  final List<Map<String, dynamic>> _messages = [];
  bool _isInitialized = false;
  String _activeCedula = '';

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  bool get hasMessages => _messages.isNotEmpty;
  int get count => _messages.length;

  /// Obtiene el plan estructurado más reciente generado por el Coach IA en la conversación.
  Map<String, dynamic>? get latestRecommendedPlan {
    for (final m in _messages.reversed) {
      if (m['isUser'] == false && m['plan'] is Map) {
        final p = Map<String, dynamic>.from(m['plan'] as Map);
        if (p['days_schedule'] is Map || (p['exercises'] is List && (p['exercises'] as List).isNotEmpty)) {
          return p;
        }
      }
    }
    return null;
  }

  /// Limpia la memoria RAM para aislamiento de usuario
  void reset() {
    _messages.clear();
    _isInitialized = false;
    _activeCedula = '';
    notifyListeners();
  }

  /// Inicializa o carga el historial existente desde memoria o almacenamiento local.
  Future<void> init({String? cedula}) async {
    final targetCedula = (cedula != null && cedula.isNotEmpty)
        ? cedula
        : (AuthService.instance.loggedInUser?.cedula ?? 'default');

    // Si ya tenemos mensajes en memoria RAM para este usuario exacto, los conservamos
    if (_isInitialized && _activeCedula == targetCedula && _messages.isNotEmpty) {
      return;
    }

    _activeCedula = targetCedula;
    _isInitialized = true;
    _messages.clear(); // Limpiar siempre mensajes de usuarios previos

    try {
      const storage = FlutterSecureStorage();
      final localKey = 'coach_chat_history_$targetCedula';
      String? cachedStr = await storage.read(key: localKey);
      if ((cachedStr == null || cachedStr.trim().isEmpty) && targetCedula == 'default') {
        cachedStr = await storage.read(key: 'coach_chat_history_active');
      }

      if (cachedStr != null && cachedStr.trim().isNotEmpty) {
        final decoded = jsonDecode(cachedStr);
        if (decoded is List && decoded.isNotEmpty) {
          for (final item in decoded) {
            if (item is Map) {
              _messages.add(Map<String, dynamic>.from(item));
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error cargando historial de CoachChatService: $e');
    }
  }

  /// Añade un nuevo mensaje al chat y lo persiste de inmediato.
  void addMessage(Map<String, dynamic> msg, {bool shouldPersist = true}) {
    _messages.add(Map<String, dynamic>.from(msg));
    notifyListeners();
    if (shouldPersist) {
      saveToStorage();
    }
  }

  /// Reemplaza todos los mensajes en memoria y persiste.
  void setMessages(List<Map<String, dynamic>> newMessages, {bool shouldPersist = true}) {
    _messages.clear();
    for (final item in newMessages) {
      _messages.add(Map<String, dynamic>.from(item));
    }
    notifyListeners();
    if (shouldPersist) {
      saveToStorage();
    }
  }

  /// Persiste los mensajes actuales en almacenamiento seguro.
  Future<void> saveToStorage() async {
    if (_messages.isEmpty) return;
    try {
      final cedula = _activeCedula.isNotEmpty
          ? _activeCedula
          : (AuthService.instance.loggedInUser?.cedula ?? 'default');
      const storage = FlutterSecureStorage();
      final localKey = 'coach_chat_history_$cedula';
      const genericKey = 'coach_chat_history_active';

      // Guardar últimos 60 mensajes
      final toSave = _messages.length > 60
          ? _messages.sublist(_messages.length - 60)
          : _messages;
      final encoded = jsonEncode(toSave);

      await storage.write(key: localKey, value: encoded);
      await storage.write(key: genericKey, value: encoded);
    } catch (e) {
      debugPrint('Error guardando en CoachChatService: $e');
    }
  }

  /// Limpia tanto la memoria RAM como el almacenamiento seguro local.
  Future<void> clearHistory() async {
    _messages.clear();
    notifyListeners();
    try {
      final cedula = _activeCedula.isNotEmpty
          ? _activeCedula
          : (AuthService.instance.loggedInUser?.cedula ?? 'default');
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'coach_chat_history_$cedula');
      await storage.delete(key: 'coach_chat_history_active');
    } catch (_) {}
  }
}
