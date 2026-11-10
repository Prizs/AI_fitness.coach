import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/app_update_service.dart';

/// Panel de actualizaciones y descarga de APK oficial para la pantalla de perfil.
class AppUpdatePanel extends StatefulWidget {
  const AppUpdatePanel({super.key});

  @override
  State<AppUpdatePanel> createState() => _AppUpdatePanelState();
}

class _AppUpdatePanelState extends State<AppUpdatePanel> {
  final AppUpdateService _service = AppUpdateService();

  late Future<InstalledVersion> _installedFuture;
  bool _checking = false;
  RemoteVersion? _remote;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _installedFuture = _service.installedVersion();
    _loadLatest(silent: true);
  }

  Future<void> _loadLatest({bool silent = false}) async {
    setState(() => _checking = true);
    final remote = await _service.getLatestInfo();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _remote = remote;
      if (!silent) {
        if (remote != null) {
          _statusMessage = '¡Información de la versión v${remote.versionName} actualizada desde el servidor!';
        } else {
          _statusMessage = _service.lastError ?? 'No se pudo contactar el servidor.';
        }
      }
    });
  }

  Future<void> _triggerApkDownload() async {
    final apkUrl = Uri.parse('${AuthService.apiBaseUrl}/api/app/download');
    try {
      final launched = await launchUrl(apkUrl, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el navegador para descargar el APK.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF1FAE87).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1FAE87).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con icono destacado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1FAE87).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.4)),
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  color: Color(0xFF8BE0C0),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Centro de Actualizaciones & APK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Descarga directa de la última versión oficial',
                      style: TextStyle(fontSize: 11.5, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Badges de versión actual vs servidor
          FutureBuilder<InstalledVersion>(
            future: _installedFuture,
            builder: (context, snapshot) {
              final inst = snapshot.data;
              final instText = inst != null ? '${inst.versionName} (${inst.versionCode})' : '1.0.77 (Oficial)';
              final remText = _remote != null ? 'v${_remote!.versionName} (${_remote!.versionCode})' : 'v1.0.77 (Build 117)';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16253B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tu Versión Instalada', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
                          const SizedBox(height: 3),
                          Text(
                            instText,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 24, width: 1, color: Colors.white12),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Última en Servidor', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
                          const SizedBox(height: 3),
                          Text(
                            remText,
                            style: const TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Mensaje de estado
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _statusMessage!,
                style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 11.5),
              ),
            ),

          // Resumen de mejoras de la última versión
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1220),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF8BE0C0), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Novedades Principales v1.0.77:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '• Nueva Galería Horizontal de Evolución en Progreso (deslizable desde el Día 1 con swipe táctil).\n'
                  '• Ficha clínica y biomecánica IA con biotipo y métricas dinámicas.\n'
                  '• Exportación oficial de Bitácora de Entrenamiento (PDF) y test físicos adaptados.\n'
                  '• Actualización móvil directa con 1 toque.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BOTÓN PRINCIPAL: DESCARGAR E INSTALAR APK (OFICIAL)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1FAE87),
                foregroundColor: const Color(0xFF0A0F1D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () {
                if (AppUpdateService.isAndroid) {
                  checkForAppUpdate(context, force: true);
                } else {
                  _triggerApkDownload();
                }
              },
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text(
                AppUpdateService.isAndroid
                    ? 'Actualizar e Instalar Última Versión'
                    : 'Descargar Última Versión (APK Móvil)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Botones secundarios
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8BE0C0),
                    side: BorderSide(color: const Color(0xFF8BE0C0).withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: _checking ? null : () => _loadLatest(silent: false),
                  icon: _checking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8BE0C0)),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    _checking ? 'Comprobando...' : 'Buscar Actualización',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: BorderSide(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: _triggerApkDownload,
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text(
                    'Enlace Directo APK',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Revisa el backend y ofrece descargar e instalar la versión oficial.
Future<void> checkForAppUpdate(
  BuildContext context, {
  bool silent = false,
  bool force = false,
}) async {
  final service = AppUpdateService();
  final remote = force ? await service.getLatestInfo() : await service.checkForUpdate();

  if (!context.mounted) return;

  if (remote == null) {
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.lastError ?? 'Tu app ya cuenta con la versión oficial más reciente.'),
          backgroundColor: const Color(0xFF16253B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  await _promptUpdate(context, remote);
}

/// Comprobación silenciosa al arrancar la app.
Future<void> checkForUpdatesOnStart(BuildContext context) =>
    checkForAppUpdate(context, silent: true);

Future<void> _promptUpdate(BuildContext context, RemoteVersion remote) async {
  final shouldInstall = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF101C2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.system_update_rounded, color: Color(0xFF8BE0C0), size: 22),
          SizedBox(width: 10),
          Text('Actualización Oficial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1FAE87).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Versión ${remote.versionName}  ·  ${remote.sizeLabel}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8BE0C0), fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Text(
                remote.notes,
                style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Más tarde', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1FAE87),
            foregroundColor: const Color(0xFF0A0F1D),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Actualizar Ahora', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (shouldInstall != true || !context.mounted) return;

  if (AppUpdateService.isAndroid) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DownloadDialog(),
    );
  } else {
    // En Web o fallback, descarga directa del APK al dispositivo
    final url = Uri.parse('${AuthService.apiBaseUrl}/api/app/download');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog();

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  final AppUpdateService _service = AppUpdateService();
  double _progress = 0;
  String _status = 'Descargando actualización...';
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
        _status = 'Abriendo el instalador del APK...';
      });
      final launched = await _service.install(file);
      if (!mounted) return;
      if (launched) {
        Navigator.pop(context);
      } else {
        // Fallback a descarga por navegador
        setState(() {
          _failed = true;
          _status = 'Se descargó el APK. Si no se abrió el instalador, puedes descargarlo directamente en tu navegador.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _status = 'Error al descargar APK: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF101C2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _failed ? 'Descarga de Actualización' : 'Descargando APK Oficial',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_status, style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
          if (!_failed) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: _progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8BE0C0)),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ],
      ),
      actions: [
        if (_failed) ...[
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse('${AuthService.apiBaseUrl}/api/app/download');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            child: const Text('Descargar en Navegador', style: TextStyle(color: Color(0xFF8BE0C0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ],
    );
  }
}
