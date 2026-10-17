import 'dart:js' as js;
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

    final dynamic res = aiVoice.callMethod('start', [onResultJs, onStatusJs, onErrorJs]);
    final bool started = res == true;
    _listening = started;
    return started;
  }

  @override
  Future<String> stop() async {
    _listening = false;
    final dynamic aiVoice = js.context['AIFitnessVoice'];
    if (aiVoice != null) {
      final dynamic result = aiVoice.callMethod('stop', []);
      if (result != null && result.toString().isNotEmpty) {
        _lastText = result.toString();
      }
    }
    return _lastText.trim();
  }

  @override
  Future<void> cancel() async {
    await stop();
    _lastText = '';
  }
}

VoiceEngine getVoiceEngine() => VoiceEngineImpl();
