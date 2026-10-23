import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/app_update_service.dart';
import 'package:flutter/material.dart';

/// Panel de actualizaciones para la pantalla de perfil.
///
/// Muestra la version instalada, consulta la publicada en el servidor y
/// permite instalar la nueva sin salir de la app.
class AppUpdatePanel extends StatefulWidget {
  const AppUpdatePanel({super.key});

  @override
  State<AppUpdatePanel> createState() => _AppUpdatePanelState();
}

class _AppUpdatePanelState extends State<AppUpdatePanel> {
  final AppUpdateService _service = AppUpdateService();

  late Future<InstalledVersion> _installed;
  bool _checking = false;
  RemoteVersion? _remote;
  String? _message;

  @override
  void initState() {
    super.initState();
    _installed = _service.installedVersion();
    _loadRemote(silent: true);
  }

  Future<void> _loadRemote({bool silent = false}) async {
    setState(() => _checking = true);
    final remote = await _service.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _remote = remote;
      if (!silent) {
        _message = remote == null
            ? (_service.lastError ?? 'Tu app ya esta actualizada.')
            : 'Hay una version mas nueva disponible.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasUpdate = _remote != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F192B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasUpdate ? const Color(0xFF8BE0C0) : Colors.white10,
          width: hasUpdate ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasUpdate
                    ? Icons.system_update_alt_rounded
                    : Icons.verified_rounded,
                color: const Color(0xFF8BE0C0),
              ),
              const SizedBox(width: 8),
              const Text(
                'Actualizaciones de la app',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<InstalledVersion>(
            future: _installed,
            builder: (context, snapshot) {
              final version = snapshot.data;
              return Row(
                children: [
                  const Text(
                    'Version instalada:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    version == null
                        ? '...'
                        : '${version.versionName} (${version.versionCode})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
          if (_remote != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  'Ultima publicada:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_remote!.versionName} (${_remote!.versionCode})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8BE0C0),
                  ),
                ),
              ],
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: hasUpdate
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8BE0C0),
                      foregroundColor: const Color(0xFF0B1220),
                    ),
                    onPressed: () => checkForAppUpdate(context),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Descargar e instalar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                : OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8BE0C0),
                      side: const BorderSide(color: Color(0xFF173B45)),
                    ),
                    onPressed: _checking
                        ? null
                        : () => _loadRemote(silent: false),
                    icon: _checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      _checking ? 'Verificando...' : 'Buscar actualizaciones',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8BE0C0),
              ),
              onPressed: () async {
                final url = Uri.parse('${AuthService.apiBaseUrl}/api/app/download');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.download_for_offline_rounded, size: 18),
              label: const Text(
                'Descargar archivo APK directamente',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


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
