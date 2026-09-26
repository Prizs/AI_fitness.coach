import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

/// Version de la app instalada en el dispositivo.
class InstalledVersion {
  const InstalledVersion(this.versionName, this.versionCode);

  final String versionName;
  final int versionCode;
}

/// Version publicada por el servidor.
class RemoteVersion {
  const RemoteVersion({
    required this.versionName,
    required this.versionCode,
    required this.sizeBytes,
    required this.notes,
  });

  final String versionName;
  final int versionCode;
  final int sizeBytes;
  final String notes;

  String get sizeLabel {
    if (sizeBytes <= 0) return '';
    final mb = sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Consulta al backend y descarga/instalacion del APK, sin salir de la app.
class AppUpdateService {
  AppUpdateService();

  static const MethodChannel _channel =
      MethodChannel('com.example.mobile_app/app_update');

  String? lastError;

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// Una version remota sirve solo si su codigo es mayor al instalado.
  static bool isNewer({required int installed, required int remote}) =>
      remote > installed;

  Future<InstalledVersion> installedVersion() async {
    if (!_isAndroid) {
      return const InstalledVersion('web', 0);
    }
    final info = await _channel
        .invokeMapMethod<String, dynamic>('getAppInfo');
    if (info == null) return const InstalledVersion('desconocida', 0);
    return InstalledVersion(
      info['versionName'] as String? ?? 'desconocida',
      (info['versionCode'] as num?)?.toInt() ?? 0,
    );
  }

  /// Consulta `/api/app/latest`. Devuelve null si no hay nada nuevo.
  Future<RemoteVersion?> checkForUpdate() async {
    lastError = null;
    try {
      final response = await http
          .get(Uri.parse('${AuthService.apiBaseUrl}/api/app/latest'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        lastError = 'No se pudo consultar la version (${response.statusCode}).';
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['available'] != true) {
        lastError = data['reason'] as String?;
        return null;
      }
      final remote = RemoteVersion(
        versionName: data['version_name'] as String? ?? '0.0.0',
        versionCode: (data['version_code'] as num?)?.toInt() ?? 0,
        sizeBytes: (data['size_bytes'] as num?)?.toInt() ?? 0,
        notes: data['notes'] as String? ?? '',
      );
      final installed = await installedVersion();
      if (!isNewer(installed: installed.versionCode, remote: remote.versionCode)) {
        return null;
      }
      return remote;
    } on Exception catch (error) {
      lastError = 'No se pudo consultar la version: ${error.runtimeType}.';
      return null;
    }
  }

  /// Descarga el APK y devuelve el archivo listo para instalar.
  Future<File> download(
    void Function(int received, int total) onProgress,
  ) async {
    final cacheDir = await _channel.invokeMethod<String>('getCacheDir');
    if (cacheDir == null || cacheDir.isEmpty) {
      throw Exception('No se pudo obtener la carpeta de Descargas.');
    }
    final directory = Directory('$cacheDir/updates');
    await directory.create(recursive: true);
    final file = File('${directory.path}/ai-fitness-coach.apk');

    final request = http.Request(
      'GET',
      Uri.parse('${AuthService.apiBaseUrl}/api/app/download'),
    );
    final response = await request.send().timeout(
          const Duration(seconds: 300),
        );
    if (response.statusCode != 200) {
      throw Exception('La descarga fallo (${response.statusCode}).');
    }
    final total = response.contentLength ?? 0;
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
    } finally {
      await sink.close();
    }
    return file;
  }

  /// Abre el instalador de Android con el APK descargado.
  Future<bool> install(File file) async {
    if (!_isAndroid) return false;
    if (!await file.exists()) return false;
    final ok = await _channel.invokeMethod<bool>(
      'installApk',
      {'path': file.path},
    );
    return ok ?? false;
  }
}
