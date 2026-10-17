import 'voice_engine_stub.dart'
    if (dart.library.html) 'voice_engine_web.dart'
    if (dart.library.io) 'voice_engine_mobile.dart';

abstract class VoiceEngine {
  bool get isListening;
  Future<bool> start({
    required void Function(String text) onResult,
    required void Function(String status) onStatus,
    required void Function(String error) onError,
  });
  Future<String> stop();
  Future<void> cancel();

  factory VoiceEngine() => getVoiceEngine();
}
