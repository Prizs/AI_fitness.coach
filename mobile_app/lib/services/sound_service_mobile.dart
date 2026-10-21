import 'package:flutter/services.dart';

class SoundServicePlatform {
  static void playChime() {
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static void showSystemNotification(String title, String body) {
    // Android in-app handling is handled by the Flutter TopNotificationBanner
  }
}
