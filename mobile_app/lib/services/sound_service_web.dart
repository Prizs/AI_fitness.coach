import 'dart:js' as js;

class SoundServicePlatform {
  static void playChime() {
    try {
      if (js.context.hasProperty('playNotificationChime')) {
        js.context.callMethod('playNotificationChime');
      }
    } catch (e) {
      // Ignore if audio context not available
    }
  }

  static void showSystemNotification(String title, String body) {
    try {
      if (js.context.hasProperty('showBrowserNotification')) {
        js.context.callMethod('showBrowserNotification', [title, body]);
      }
    } catch (_) {}
  }
}
