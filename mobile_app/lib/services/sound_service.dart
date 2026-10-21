import 'sound_service_stub.dart'
    if (dart.library.html) 'sound_service_web.dart'
    if (dart.library.io) 'sound_service_mobile.dart';

class SoundService {
  static void playChime() {
    SoundServicePlatform.playChime();
  }

  static void showSystemNotification(String title, String body) {
    SoundServicePlatform.showSystemNotification(title, body);
  }
}
