import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

/// Versión de la app instalada en el dispositivo.
class InstalledVersion {
  const InstalledVersion(this.versionName, this.versionCode);

  final String versionName;
  final int versionCode;
}

/// Versión publicada por el servidor.
class RemoteVersion {
  const RemoteVersion({
    required this.versionName,
    required this.versionCode,
    required this.sizeBytes,
    required this.notes,
    this.downloadUrl = '/api/app/download',
  });

  final String versionName;
  final int versionCode;
  final int sizeBytes;
  final String notes;
  final String downloadUrl;

  String get sizeLabel {
    if (sizeBytes <= 0) return '63.2 MB';
    final mb = sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Consulta al backend y descarga/instalación del APK oficial.
class AppUpdateService {
  AppUpdateService();

  static const MethodChannel _channel =
      MethodChannel('com.example.mobile_app/app_update');

  String? lastError;

  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Una versión remota sirve si su código es mayor al instalado o en web.
  static bool isNewer({required int installed, required int remote}) =>
      kIsWeb || remote > installed;

  Future<InstalledVersion> installedVersion() async {
    if (kIsWeb) {
      return const InstalledVersion('1.0.77 (Web)', 117);
    }
    if (!isAndroid) {
      return const InstalledVersion('1.0.77', 117);
    }
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('getAppInfo');
      if (info == null) return const InstalledVersion('1.0.77', 117);
      return InstalledVersion(
        info['versionName'] as String? ?? '1.0.77',
        (info['versionCode'] as num?)?.toInt() ?? 117,
      );
    } catch (_) {
      return const InstalledVersion('1.0.77', 117);
    }
  }

  /// Obtiene siempre la información de la última versión en el servidor.
  Future<RemoteVersion?> getLatestInfo() async {
    lastError = null;
    try {
      final response = await http
          .get(Uri.parse('${AuthService.apiBaseUrl}/api/app/latest'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        lastError = 'No se pudo consultar la versión (${response.statusCode}).';
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['available'] != true) {
        lastError = data['reason'] as String?;
        return null;
      }
      return RemoteVersion(
        versionName: data['version_name'] as String? ?? '1.0.77',
        versionCode: (data['version_code'] as num?)?.toInt() ?? 117,
        sizeBytes: (data['size_bytes'] as num?)?.toInt() ?? 63225169,
        notes: data['notes'] as String? ?? '',
        downloadUrl: data['download_url'] as String? ?? '/api/app/download',
      );
    } catch (error) {
      lastError = 'Error conectando con el servidor de actualizaciones: $error';
      return null;
    }
  }

  /// Consulta `/api/app/latest`. Devuelve null si no hay versión más nueva.
  Future<RemoteVersion?> checkForUpdate() async {
    final remote = await getLatestInfo();
    if (remote == null) return null;
    final installed = await installedVersion();
    if (!isNewer(installed: installed.versionCode, remote: remote.versionCode)) {
      return null;
    }
    return remote;
  }

  /// Descarga el APK nativo en Android y devuelve la ruta.
  Future<File?> download(
    void Function(int received, int total) onProgress,
  ) async {
    if (!isAndroid) {
      return null;
    }
    final cacheDir = await _channel.invokeMethod<String>('getCacheDir');
    if (cacheDir == null || cacheDir.isEmpty) {
      throw Exception('No se pudo acceder a la carpeta de descargas del dispositivo.');
    }
    final directory = Directory('$cacheDir/updates');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File('${directory.path}/AI_Fitness_Coach.apk');

    final request = http.Request(
      'GET',
      Uri.parse('${AuthService.apiBaseUrl}/api/app/download'),
    );
    final response = await request.send().timeout(const Duration(seconds: 300));
    if (response.statusCode != 200) {
      throw Exception('La descarga falló con código ${response.statusCode}.');
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
  Future<bool> install(File? file) async {
    if (!isAndroid || file == null) return false;
    try {
      if (!await file.exists()) return false;
      final ok = await _channel.invokeMethod<bool>(
        'installApk',
        {'path': file.path},
      );
      return ok ?? false;
    } catch (_) {}
    return false;
  }
}
