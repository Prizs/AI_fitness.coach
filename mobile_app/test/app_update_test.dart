import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/app_update_service.dart';

void main() {
  group('comparacion de versiones', () {
    test('una version mayor ofrece actualizacion', () {
      expect(
        AppUpdateService.isNewer(installed: 1, remote: 2),
        isTrue,
      );
    });

    test('la misma version no ofrece actualizacion', () {
      expect(AppUpdateService.isNewer(installed: 3, remote: 3), isFalse);
    });

    test('una version menor no ofrece actualizacion', () {
      expect(AppUpdateService.isNewer(installed: 5, remote: 4), isFalse);
    });
  });

  group('etiqueta de tamano', () {
    test('muestra MB con un decimal', () {
      const info = RemoteVersion(
        versionName: '1.0.1',
        versionCode: 2,
        sizeBytes: 15728640,
        notes: '',
      );
      expect(info.sizeLabel, '15.0 MB');
    });

    test('devuelve vacio si no se conoce el tamano', () {
      const info = RemoteVersion(
        versionName: '1.0.1',
        versionCode: 2,
        sizeBytes: 0,
        notes: '',
      );
      expect(info.sizeLabel, '');
    });
  });
}
