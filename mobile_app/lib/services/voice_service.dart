import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Servicio centralizado y robusto de reconocimiento de voz para Web, Móvil y PC.
/// Mantiene la sesión activa en PC durante pausas naturales (ignora 'no-speech')
/// y garantiza que el segundo toque detenga la grabación y envíe el mensaje.
class VoiceService with ChangeNotifier {
  static final VoiceService instance = VoiceService._internal();
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _userExplicitlyStopped = true;
  String _currentWords = '';
  String? _lastError;
  String? _selectedLocale;

  void Function(String text)? _activeResultCallback;
  void Function(bool listening)? _activeListeningCallback;
  void Function(String error)? _activeErrorCallback;

  bool get isListening => _isListening;
  String get currentWords => _currentWords;
  String? get lastError => _lastError;

  /// Inicializa el motor de voz y resuelve el dialecto adecuado para la PC.
  Future<bool> initIfNeeded() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: kDebugMode,
      );

      if (_isInitialized) {
        // Encontrar mejor dialecto español compatible en este navegador
        try {
          final locales = await _speech.locales();
          for (var l in locales) {
            final id = l.localeId.toLowerCase();
            if (id == 'es-419' || id == 'es_419' || id == 'es-ve' || id == 'es_ve' || id == 'es-la' || id == 'es-es' || id == 'es_es' || id.startsWith('es')) {
              _selectedLocale = l.localeId;
              break;
            }
          }
        } catch (_) {}
      }

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
      // En PC / Web el navegador envía notListening ante una pausa breve.
      // Si el usuario no ha tocado detener, rearmamos la escucha para que
      // no se corte mientras habla.
      if (!_userExplicitlyStopped && _isListening) {
        _rearmListening();
      } else {
        _isListening = false;
        _activeListeningCallback?.call(false);
        notifyListeners();
      }
    }
  }

  void _handleError(dynamic errorNotification) {
    final String errorMsg = errorNotification?.errorMsg?.toString() ?? 'Error de micrófono';

    // 'no-speech' no es un error fatal: solo indica silencio temporal en la PC.
    if (errorMsg.contains('no-speech')) {
      if (!_userExplicitlyStopped && _isListening) {
        _rearmListening();
      }
      return;
    }

    _lastError = errorMsg;
    _isListening = false;
    _activeListeningCallback?.call(false);
    _activeErrorCallback?.call(errorMsg);
    notifyListeners();
  }

  void _rearmListening() {
    if (_userExplicitlyStopped) return;
    Future.delayed(const Duration(milliseconds: 250), () async {
      if (!_userExplicitlyStopped && _isListening) {
        try {
          await _listenInternal();
        } catch (_) {}
      }
    });
  }

  Future<void> _listenInternal() async {
    final options = stt.SpeechListenOptions(
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
      onDevice: false,
    );

    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.trim().isNotEmpty) {
          _currentWords = result.recognizedWords;
          _activeResultCallback?.call(_currentWords);
          notifyListeners();
        }
      },
      localeId: _selectedLocale ?? 'es_ES',
      listenOptions: options,
      pauseFor: const Duration(seconds: 15),
      listenFor: const Duration(minutes: 5),
    );
  }

  /// Inicia la captura continua de voz.
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
    _userExplicitlyStopped = false;

    final bool available = await initIfNeeded();
    if (!available) {
      _isListening = false;
      _activeListeningCallback?.call(false);
      _activeErrorCallback?.call(
        'El micrófono no está habilitado o bloqueado. En PC, haz clic en el candado 🔒 en la barra de direcciones y selecciona "Permitir micrófono".',
      );
      notifyListeners();
      return false;
    }

    try {
      _isListening = true;
      _activeListeningCallback?.call(true);
      notifyListeners();

      await _listenInternal();
      return true;
    } catch (e) {
      _isListening = false;
      _lastError = e.toString();
      _activeListeningCallback?.call(false);
      _activeErrorCallback?.call('No se pudo activar el micrófono en tu navegador: $e');
      notifyListeners();
      return false;
    }
  }

  /// Segundo clic: Detiene la escucha de forma definitiva y devuelve el texto transcrito.
  Future<String> stopListening() async {
    _userExplicitlyStopped = true;
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
    _userExplicitlyStopped = true;
    _isListening = false;
    _currentWords = '';
    _activeListeningCallback?.call(false);

    try {
      await _speech.cancel();
    } catch (_) {}

    notifyListeners();
  }
}
