import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/sound_service.dart';
import 'package:mobile_app/widgets/top_notification_banner.dart';
import 'package:mobile_app/screens/trainer/trainer_messages_tab.dart';

class ChatNotificationService {
  ChatNotificationService._internal();
  static final ChatNotificationService instance = ChatNotificationService._internal();

  Timer? _pollingTimer;
  String? _lastSeenMessageId;
  bool _isFirstCheck = true;
  bool _isChecking = false;

  final Set<String> _activeChatIdentifiers = {};

  void pushActiveChat({String? userId, String? userCedula, String? userName}) {
    if (userId != null && userId.trim().isNotEmpty) {
      _activeChatIdentifiers.add(userId.trim().toLowerCase());
    }
    if (userCedula != null && userCedula.trim().isNotEmpty) {
      _activeChatIdentifiers.add(userCedula.trim().toLowerCase());
    }
    if (userName != null && userName.trim().isNotEmpty) {
      _activeChatIdentifiers.add(userName.trim().toLowerCase());
    }
  }

  void popActiveChat({String? userId, String? userCedula, String? userName}) {
    if (userId != null) _activeChatIdentifiers.remove(userId.trim().toLowerCase());
    if (userCedula != null) _activeChatIdentifiers.remove(userCedula.trim().toLowerCase());
    if (userName != null) _activeChatIdentifiers.remove(userName.trim().toLowerCase());
  }

  void clearAllActiveChats() {
    _activeChatIdentifiers.clear();
  }

  bool isChatOpenWith({
    String? senderId,
    String? senderCedula,
    String? senderName,
    String? clientId,
    String? trainerId,
  }) {
    if (_activeChatIdentifiers.isEmpty) return false;

    final candidates = [
      senderId?.trim().toLowerCase(),
      senderCedula?.trim().toLowerCase(),
      senderName?.trim().toLowerCase(),
      clientId?.trim().toLowerCase(),
      trainerId?.trim().toLowerCase(),
    ].where((c) => c != null && c.isNotEmpty).cast<String>();

    for (final candidate in candidates) {
      if (_activeChatIdentifiers.contains(candidate)) {
        return true;
      }
      for (final active in _activeChatIdentifiers) {
        if (active.length >= 3 && (active == candidate || candidate.contains(active) || active.contains(candidate))) {
          return true;
        }
      }
    }
    return false;
  }

  void startPolling(GlobalKey<NavigatorState> navigatorKey, {void Function(int tabIndex)? onNavigateTab}) {
    if (_pollingTimer != null) return;
    _isFirstCheck = true;

    // Ejecutar chequeo inmediato y luego cada 3 segundos
    _checkNewMessages(navigatorKey, onNavigateTab: onNavigateTab);
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      _checkNewMessages(navigatorKey, onNavigateTab: onNavigateTab);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _lastSeenMessageId = null;
    _isFirstCheck = true;
    _activeChatIdentifiers.clear();
  }

  Future<void> _checkNewMessages(
    GlobalKey<NavigatorState> navigatorKey, {
    void Function(int tabIndex)? onNavigateTab,
  }) async {
    final user = AuthService.instance.loggedInUser;
    if (user == null || _isChecking) return;

    final cedula = user.cedula.trim();
    if (cedula.isEmpty) return;

    _isChecking = true;
    final baseUrl = AuthService.apiBaseUrl;

    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/trainer/latest-chat-message/$cedula'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is Map && data['has_message'] == true) {
          final messageId = data['message_id']?.toString();
          final messageText = data['message']?.toString() ?? '';
          final senderName = data['sender_name']?.toString() ?? 'Entrenador';
          final senderRole = data['sender_role']?.toString() ?? 'trainer';
          final senderId = data['sender_id']?.toString() ?? '';
          final senderCedula = data['sender_cedula']?.toString() ?? '';
          final clientId = data['client_id']?.toString() ?? '';
          final trainerId = data['trainer_id']?.toString() ?? '';
          final createdAt = data['created_at']?.toString() ?? '';

          if (messageId != null) {
            // Si es la primera verificación al abrir la app:
            if (_isFirstCheck) {
              _isFirstCheck = false;
              _lastSeenMessageId = messageId;
              // Si el mensaje se creó hace menos de 20 segundos, notificarlo
              bool isRecent = false;
              try {
                final msgTime = DateTime.parse(createdAt);
                if (DateTime.now().toUtc().difference(msgTime).inSeconds < 25) {
                  isRecent = true;
                }
              } catch (_) {}

              if (!isRecent) return;
            }

            // Si es un nuevo mensaje diferente al último procesado
            if (messageId != _lastSeenMessageId) {
              _lastSeenMessageId = messageId;

              // CONDICIÓN: Si el usuario ya tiene abierto el chat con esta persona, no emitir sonido ni banner flotante
              if (isChatOpenWith(
                senderId: senderId,
                senderCedula: senderCedula,
                senderName: senderName,
                clientId: clientId,
                trainerId: trainerId,
              )) {
                return;
              }

              // 1. Sonido de notificación
              SoundService.playChime();

              // 2. Notificación del sistema navegador/Android
              final bannerTitle = senderRole == 'trainer' ? 'Coach $senderName' : senderName;
              SoundService.showSystemNotification(bannerTitle, messageText);

              // 3. Notificación flotante animada en la parte superior de la app
              TopNotificationBanner.show(
                title: bannerTitle,
                message: messageText,
                senderRole: senderRole,
                onTap: () {
                  final navContext = navigatorKey.currentContext;
                  if (navContext == null) return;

                  final myRole = user.role;
                  if (myRole == 'trainer') {
                    // Abrir pantalla de chat con este alumno
                    Navigator.of(navContext).push(
                      MaterialPageRoute(
                        builder: (_) => TrainerClientChatScreen(
                          clientId: senderId,
                          clientName: senderName,
                        ),
                      ),
                    );
                  } else {
                    // Si es alumno, navegar a la pestaña 1 (Coach / Mi Entrenador)
                    if (onNavigateTab != null) {
                      onNavigateTab(1);
                    }
                  }
                },
              );
            }
          }
        }
      }
    } catch (_) {
      // Ignorar errores de conexión transitorios en polling
    } finally {
      _isChecking = false;
    }
  }
}
