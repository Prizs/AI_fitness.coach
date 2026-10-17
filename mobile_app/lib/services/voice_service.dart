import 'dart:async';
import 'package:flutter/foundation.dart';
import 'voice_engine.dart';

/// Servicio centralizado de voz que delega al motor nativo según la plataforma (Web o Móvil).
class VoiceService with ChangeNotifier {
  static final VoiceService instance = VoiceService._internal();
  VoiceService._internal();

  final VoiceEngine _engine = VoiceEngine();
  String _currentWords = '';
  String? _lastError;

  bool get isListening => _engine.isListening;
  String get currentWords => _currentWords;
  String? get lastError => _lastError;

  /// Inicia la escucha continua de voz.
  Future<bool> startListening({
    required void Function(String text) onResult,
    void Function(bool listening)? onListeningChanged,
    void Function(String error)? onError,
  }) async {
    _currentWords = '';
    _lastError = null;

    final started = await _engine.start(
      onResult: (text) {
        _currentWords = text;
        onResult(text);
        notifyListeners();
      },
      onStatus: (status) {
        final listening = status == 'listening';
        onListeningChanged?.call(listening);
        notifyListeners();
      },
      onError: (errMsg) {
        _lastError = errMsg;
        onListeningChanged?.call(false);
        onError?.call(errMsg);
        notifyListeners();
      },
    );

    if (started) {
      onListeningChanged?.call(true);
      notifyListeners();
    }
    return started;
  }

  /// Detiene la escucha y retorna el texto final capturado.
  Future<String> stopListening() async {
    final text = await _engine.stop();
    notifyListeners();
    return text.isNotEmpty ? text : _currentWords.trim();
  }

  /// Cancela la escucha sin guardar texto.
  Future<void> cancelListening() async {
    await _engine.cancel();
    _currentWords = '';
    notifyListeners();
  }
}
