import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/database/db_helper.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/screens/adaptive_workout_screen.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  bool _isLoading = true;
  String _pingResult = 'Comprobando...';
  int _pingMs = 0;
  Map<String, dynamic> _diagData = {};
  int _localSessionsCount = 0;
  String _dbPath = 'Iniciando...';
  final List<String> _consoleLogs = [];

  @override
  void initState() {
    super.initState();
    _log('Consola de administración inicializada.');
    _runFullDiagnostics();
  }

  void _log(String msg) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _consoleLogs.insert(0, '[$timeStr] $msg');
      if (_consoleLogs.length > 50) _consoleLogs.removeLast();
    });
  }

  Future<void> _runFullDiagnostics() async {
    setState(() => _isLoading = true);
    _log('Iniciando diagnóstico integral de sistema...');

    final baseUrl = AuthService.apiBaseUrl;
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Ping Backend
      final res = await http
          .get(Uri.parse('$baseUrl/api/admin/diagnostics?pin=2026'))
          .timeout(const Duration(seconds: 8));
      stopwatch.stop();
      _pingMs = stopwatch.elapsedMilliseconds;

      if (res.statusCode == 200) {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          _diagData = decoded;
          _pingResult = '200 OK (${_pingMs}ms)';
          _log('Backend online. Supabase: ${_diagData['supabase']?['connected'] == true ? "CONECTADO" : "DESCONECTADO"}');
        }
      } else {
        _pingResult = 'HTTP ${res.statusCode} (${_pingMs}ms)';
        _log('Backend respondió con código ${res.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();
      _pingMs = stopwatch.elapsedMilliseconds;
      _pingResult = 'Error de conexión (${_pingMs}ms)';
      _log('Error ping backend: $e');
    }

    // 2. Diagnóstico Local
    try {
      final sessions = await DBHelper.instance.getSessionHistory();
      _localSessionsCount = sessions.length;
      _dbPath = kIsWeb ? 'IndexedDB (Navegador Web)' : 'SQLite Local Storage';
      _log('Base de datos local verificada: $_localSessionsCount sesiones históricas.');
    } catch (e) {
      _dbPath = 'Error DB: $e';
      _log('Error leyendo DB local: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAiPing() async {
    _log('Probando inferencia de IA Coach...');
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/coach/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': 'ping_test_diagnostico',
          'is_initial_greeting': false,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        _log('IA Respondió con éxito: 200 OK');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Motor IA respondiendo correctamente.'),
              backgroundColor: Color(0xFF1FAE87),
            ),
          );
        }
      } else {
        _log('IA Error: HTTP ${res.statusCode}');
      }
    } catch (e) {
      _log('IA Error de conexión: $e');
    }
  }

  Future<void> _clearTemporaryCache() async {
    _log('Limpiando cachés temporales y sincronizando planes...');
    try {
      await DBHelper.instance.clearWeeklyPlanCache();
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'cached_weekly_plan_v1');
      await WeeklyPlanService.instance.ensureLoaded(AuthService.instance.loggedInUser);
      _log('Caché de planes reiniciada con éxito.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧹 Caché temporal limpiada y sincronizada.'),
            backgroundColor: Color(0xFF1FAE87),
          ),
        );
      }
    } catch (e) {
      _log('Error limpiando caché: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = _diagData['supabase'] as Map<String, dynamic>?;
    final system = _diagData['system'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101C2F),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, color: Color(0xFF8BE0C0), size: 22),
            SizedBox(width: 10),
            Text(
              'Consola de Diagnóstico Dev',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8BE0C0)),
            tooltip: 'Actualizar Diagnóstico',
            onPressed: _runFullDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8BE0C0)),
                  SizedBox(height: 16),
                  Text('Ejecutando pruebas de red y base de datos...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner de estado
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16253B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1FAE87).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF1FAE87), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Modo Soporte Técnico Activo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                              const SizedBox(height: 2),
                              Text(
                                'API: ${AuthService.apiBaseUrl}',
                                style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Métricas Técnicas
                  const Text('INFRAESTRUCTURA Y BASE DE DATOS', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          'Backend Ping',
                          _pingResult,
                          _pingMs < 400 ? const Color(0xFF1FAE87) : const Color(0xFFFFB340),
                          Icons.speed_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricCard(
                          'Supabase Status',
                          supabase?['connected'] == true ? 'Conectado' : 'Sin conexión',
                          supabase?['connected'] == true ? const Color(0xFF1FAE87) : const Color(0xFFFF6B6B),
                          Icons.storage_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          'Usuarios Totales',
                          '${supabase?['total_users'] ?? 'N/A'} (Trainers: ${supabase?['trainers_count'] ?? '0'})',
                          const Color(0xFF64B5F6),
                          Icons.people_alt_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricCard(
                          'Historial Local',
                          '$_localSessionsCount sesiones',
                          const Color(0xFFFFB340),
                          Icons.bookmark_added_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detalle de Ambiente
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101C2F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detalles de Ejecución', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        _infoRow('Plataforma', system?['platform'] ?? 'Desconocida'),
                        _infoRow('Python Server', system?['python_version'] ?? '3.11+'),
                        _infoRow('Storage Local', _dbPath),
                        _infoRow('Proveedores IA', (system?['ai_providers'] as List?)?.join(', ') ?? 'Gemini'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Acciones Rápidas
                  const Text('ACCIONES DE HERRAMIENTA', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8BE0C0),
                            side: const BorderSide(color: Color(0xFF8BE0C0)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('Test IA Coach', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: _testAiPing,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFB340),
                            side: const BorderSide(color: Color(0xFFFFB340)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                          label: const Text('Limpiar Caché', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: _clearTemporaryCache,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8BE0C0),
                        side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.accessible_forward_rounded, size: 18),
                      label: const Text('Test Módulo Adaptado (Torso Sentado & 3D)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        _log('Abriendo módulo de prueba de ejercicios adaptados (torso sentado)...');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdaptiveWorkoutScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Consola de Logs en vivo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('REGISTRO DE EVENTOS (LOGS)', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 18),
                        tooltip: 'Copiar Logs',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _consoleLogs.join('\n')));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📋 Logs copiados al portapapeles.')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF060A12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListView.builder(
                      itemCount: _consoleLogs.length,
                      itemBuilder: (ctx, idx) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _consoleLogs[idx],
                          style: const TextStyle(
                            color: Color(0xFF8BE0C0),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _metricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
