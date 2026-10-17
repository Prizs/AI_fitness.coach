import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_engine.dart';

class VoiceEngineImpl implements VoiceEngine {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInit = false;
  bool _listening = false;
  String _currentWords = '';

  @override
  bool get isListening => _listening;

  @override
  Future<bool> start({
    required void Function(String text) onResult,
    required void Function(String status) onStatus,
    required void Function(String error) onError,
  }) async {
    if (!_isInit) {
      _isInit = await _speech.initialize(
        onStatus: onStatus,
        onError: (err) => onError(err.errorMsg),
      );
    }
    if (!_isInit) return false;

    _currentWords = '';
    _listening = true;

    final options = stt.SpeechListenOptions(
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );

    await _speech.listen(
      onResult: (res) {
        _currentWords = res.recognizedWords;
        onResult(_currentWords);
      },
      localeId: 'es_ES',
      listenOptions: options,
    );
    return true;
  }

  @override
  Future<String> stop() async {
    _listening = false;
    try {
      await _speech.stop();
    } catch (_) {}
    return _currentWords.trim();
  }

  @override
  Future<void> cancel() async {
    _listening = false;
    try {
      await _speech.cancel();
    } catch (_) {}
    _currentWords = '';
  }
}

VoiceEngine getVoiceEngine() => VoiceEngineImpl();
