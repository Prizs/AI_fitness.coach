import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_app/services/app_update_service.dart';

/// Revisa el backend y, si hay una version mas nueva, ofrece instalarla.
///
/// Con [silent] en true (usado al abrir la app) no avisa cuando ya estas al
/// dia: solo aparece el dialogo si hay algo nuevo.
Future<void> checkForAppUpdate(
  BuildContext context, {
  bool silent = false,
}) async {
  final service = AppUpdateService();
  final remote = await service.checkForUpdate();

  if (!context.mounted) return;

  if (remote == null) {
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.lastError ?? 'Tu app ya esta actualizada.'),
        ),
      );
    }
    return;
  }

  await _promptUpdate(context, remote);
}

/// Comprobacion silenciosa al arrancar la app.
Future<void> checkForUpdatesOnStart(BuildContext context) =>
    checkForAppUpdate(context, silent: true);

Future<void> _promptUpdate(BuildContext context, RemoteVersion remote) async {
  final shouldInstall = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Actualizacion disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${remote.versionName}  ·  ${remote.sizeLabel}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Text(
                remote.notes,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Despues'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Actualizar ahora'),
        ),
      ],
    ),
  );

  if (shouldInstall != true || !context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DownloadDialog(),
  );
}

class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog();

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  final AppUpdateService _service = AppUpdateService();
  double _progress = 0;
  String _status = 'Descargando actualizacion...';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final file = await _service.download((received, total) {
        if (!mounted) return;
        setState(() {
          if (total > 0) {
            _progress = received / total;
          }
          _status = 'Descargando... '
              '${(received / (1024 * 1024)).toStringAsFixed(1)} MB'
              '${total > 0 ? ' de ${(total / (1024 * 1024)).toStringAsFixed(1)} MB' : ''}';
        });
      });
      if (!mounted) return;
      setState(() {
        _progress = 1;
        _status = 'Abriendo el instalador...';
      });
      final launched = await _service.install(file);
      if (!mounted) return;
      if (launched) {
        Navigator.pop(context);
      } else {
        setState(() {
          _failed = true;
          _status = 'No se pudo abrir el instalador.\n'
              'Permite instalar apps en Ajustes > Aplicaciones.';
        });
      }
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _status = 'Error al descargar: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_failed ? 'No se pudo actualizar' : 'Actualizando'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_status, style: const TextStyle(fontSize: 13)),
          if (!_failed) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(value: _progress.clamp(0.0, 1.0)),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ],
      ),
      actions: [
        if (_failed)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
      ],
    );
  }
}

/// Ruta del APK ya descargado, util para depurar desde la consola.
String describeApk(File file) => '${file.path} (${file.lengthSync()} bytes)';
