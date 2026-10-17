import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Servicio centralizado de reconocimiento de voz para Web, Móvil y Escritorio.
/// Resuelve el problema del singleton de speech_to_text y asegura que un segundo
/// clic detenga la grabación y envíe el mensaje de forma inmediata y confiable.
class VoiceService with ChangeNotifier {
  static final VoiceService instance = VoiceService._internal();
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentWords = '';
  String? _lastError;

  void Function(String text)? _activeResultCallback;
  void Function(bool listening)? _activeListeningCallback;
  void Function(String error)? _activeErrorCallback;

  bool get isListening => _isListening;
  String get currentWords => _currentWords;
  String? get lastError => _lastError;

  /// Inicializa el motor de reconocimiento si aún no está listo.
  Future<bool> initIfNeeded() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: kDebugMode,
      );
      return _isInitialized;
    } catch (e) {
      _isInitialized = false;
      _lastError = e.toString();
      return false;
    }
  }

  void _handleStatus(String status) {
    if (status == 'listening') {
      _isListening = true;
      _activeListeningCallback?.call(true);
      notifyListeners();
    } else if (status == 'notListening' || status == 'done') {
      _isListening = false;
      _activeListeningCallback?.call(false);
      notifyListeners();
    }
  }

  void _handleError(dynamic errorNotification) {
    _isListening = false;
    final String errorMsg = errorNotification?.errorMsg?.toString() ?? 'Error de micrófono';
    _lastError = errorMsg;
    _activeListeningCallback?.call(false);
    _activeErrorCallback?.call(errorMsg);
    notifyListeners();
  }

  /// Inicia la escucha con un callback para recibir las palabras en tiempo real.
  Future<bool> startListening({
    required void Function(String text) onResult,
    void Function(bool listening)? onListeningChanged,
    void Function(String error)? onError,
  }) async {
    // Si ya estaba escuchando, detener limpiamente
    if (_isListening) {
      await stopListening();
    }

    _activeResultCallback = onResult;
    _activeListeningCallback = onListeningChanged;
    _activeErrorCallback = onError;
    _currentWords = '';
    _lastError = null;

    final bool available = await initIfNeeded();
    if (!available) {
      _isListening = false;
      _activeListeningCallback?.call(false);
      _activeErrorCallback?.call(
        'El micrófono no está habilitado en este navegador. Revisa los permisos en la barra de direcciones (ícono de candado 🔒).',
      );
      notifyListeners();
      return false;
    }

    try {
      _isListening = true;
      _activeListeningCallback?.call(true);
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          _currentWords = result.recognizedWords;
          _activeResultCallback?.call(_currentWords);
          notifyListeners();
        },
        localeId: 'es_ES',
        cancelOnError: false,
        partialResults: true,
      );
      return true;
    } catch (e) {
      _isListening = false;
      _lastError = e.toString();
      _activeListeningCallback?.call(false);
      _activeErrorCallback?.call('No se pudo activar el micrófono: $e');
      notifyListeners();
      return false;
    }
  }

  /// Detiene la escucha y devuelve el texto reconocido final.
  Future<String> stopListening() async {
    final text = _currentWords;
    _isListening = false;
    _activeListeningCallback?.call(false);

    try {
      await _speech.stop();
    } catch (_) {}

    notifyListeners();
    return text.trim();
  }

  /// Cancela la sesión sin guardar
  Future<void> cancelListening() async {
    _isListening = false;
    _currentWords = '';
    _activeListeningCallback?.call(false);

    try {
      await _speech.cancel();
    } catch (_) {}

    notifyListeners();
  }
}
