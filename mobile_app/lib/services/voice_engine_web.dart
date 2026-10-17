import 'dart:async';
import 'dart:js' as js;
import 'auth_service.dart';
import 'voice_engine.dart';

class VoiceEngineImpl implements VoiceEngine {
  bool _listening = false;
  String _lastText = '';

  @override
  bool get isListening => _listening;

  @override
  Future<bool> start({
    required void Function(String text) onResult,
    required void Function(String status) onStatus,
    required void Function(String error) onError,
  }) async {
    final dynamic aiVoice = js.context['AIFitnessVoice'];
    if (aiVoice == null) {
      onError('Motor de voz Web no disponible en la página.');
      return false;
    }

    _lastText = '';
    _listening = true;

    final onResultJs = (dynamic text) {
      _lastText = text?.toString() ?? '';
      onResult(_lastText);
    };

    final onStatusJs = (dynamic status) {
      final st = status?.toString() ?? '';
      if (st == 'notListening') _listening = false;
      onStatus(st);
    };

    final onErrorJs = (dynamic err) {
      _listening = false;
      onError(err?.toString() ?? 'Error de micrófono');
    };

    final String baseUrl = AuthService.apiBaseUrl;
    final dynamic res = aiVoice.callMethod('start', [onResultJs, onStatusJs, onErrorJs, baseUrl]);
    final bool started = res == true;
    _listening = started;
    return started;
  }

  @override
  Future<String> stop() async {
    _listening = false;
    final dynamic aiVoice = js.context['AIFitnessVoice'];
    if (aiVoice == null) return _lastText.trim();

    final completer = Completer<String>();

    final onDoneJs = (dynamic result) {
      final res = result?.toString() ?? '';
      if (res.isNotEmpty) {
        _lastText = res;
      }
      if (!completer.isCompleted) {
        completer.complete(_lastText.trim());
      }
    };

    try {
      final dynamic syncResult = aiVoice.callMethod('stop', [onDoneJs]);
      if (syncResult != null && syncResult.toString().isNotEmpty) {
        _lastText = syncResult.toString();
        if (!completer.isCompleted) {
          completer.complete(_lastText.trim());
        }
      }
    } catch (_) {
      if (!completer.isCompleted) {
        completer.complete(_lastText.trim());
      }
    }

    // Esperar respuesta (con salvaguarda de 15 segundos)
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => _lastText.trim(),
    );
  }

  @override
  Future<void> cancel() async {
    await stop();
    _lastText = '';
  }
}

VoiceEngine getVoiceEngine() => VoiceEngineImpl();
