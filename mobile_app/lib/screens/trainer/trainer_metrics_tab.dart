import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class TrainerMetricsTab extends StatefulWidget {
  const TrainerMetricsTab({super.key});

  @override
  State<TrainerMetricsTab> createState() => _TrainerMetricsTabState();
}

class _TrainerMetricsTabState extends State<TrainerMetricsTab> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};
  String get _trainerCedula => AuthService.instance.loggedInUser?.cedula ?? '';

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/metrics-dashboard/$_trainerCedula'));
      if (res.statusCode == 200) {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        if (decoded is Map && mounted) {
          setState(() {
            _data = Map<String, dynamic>.from(decoded);
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando métricas de coach: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReportExportDialog() {
    final reportText = _data['report_export_text'] as String? ?? 'Sin datos de reporte disponibles.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F192B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF1FAE87)),
            SizedBox(width: 10),
            Text('Reporte Ejecutivo de Bitácoras', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: SelectableText(
                reportText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1FAE87)),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar Texto'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF1FAE87),
                  content: Text('📋 Reporte copiado al portapapeles. Listo para exportar a PDF o enviar.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _data['metrics'] as Map<String, dynamic>? ?? {};
    final recentLogs = _data['recent_logs'] as List<dynamic>? ?? [];
    final rpeDist = metrics['rpe_distribution'] as Map<String, dynamic>? ?? {};

    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87)))
          : RefreshIndicator(
              color: const Color(0xFF1FAE87),
              onRefresh: _fetchDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard de Rendimiento',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Coach: ${_data['trainer_name'] ?? "Entrenador"}',
                              style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF1FAE87)),
                          onPressed: _fetchDashboard,
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Top KPIs Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Semana Actual',
                            value: '${metrics['week_completed_sessions'] ?? 0}',
                            subtitle: 'Sesiones completadas',
                            icon: Icons.date_range_rounded,
                            color: const Color(0xFF1FAE87),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Total Histórico',
                            value: '${metrics['total_completed_sessions'] ?? 0}',
                            subtitle: 'Sesiones evaluadas',
                            icon: Icons.military_tech_rounded,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: 'RPE Promedio',
                            value: '${metrics['avg_rpe'] ?? 7.0} / 10',
                            subtitle: 'Esfuerzo de alumnos',
                            icon: Icons.bolt_rounded,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Alumnos Activos',
                            value: '${metrics['total_clients'] ?? 0}',
                            subtitle: 'Vinculados a ti',
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFFA855F7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botón para Exportar / Generar PDF
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1FAE87), Color(0xFF115E59)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1FAE87).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showReportExportDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Exportar Reporte de Bitácoras (PDF)',
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Genera un consolidado descargable con las notas técnicas',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Distribución de RPE
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F192B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distribución de Intensidad (RPE de Alumnos)',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildRPEBar('RPE 1-4 (Recuperación / Ligero)', rpeDist['1-4 (Ligero)'] ?? 0, Colors.tealAccent),
                          const SizedBox(height: 8),
                          _buildRPEBar('RPE 5-6 (Moderado)', rpeDist['5-6 (Moderado)'] ?? 0, const Color(0xFF38BDF8)),
                          const SizedBox(height: 8),
                          _buildRPEBar('RPE 7-8 (Óptimo / Hipertrofia)', rpeDist['7-8 (Óptimo)'] ?? 0, const Color(0xFF1FAE87)),
                          const SizedBox(height: 8),
                          _buildRPEBar('RPE 9-10 (Exigencia Máxima)', rpeDist['9-10 (Máximo)'] ?? 0, Colors.redAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bitácoras Técnicas Recientes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bitácoras Registradas Recientemente',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${recentLogs.length} registradas',
                          style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (recentLogs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Aún no hay bitácoras completadas. Al finalizar una sesión en tu agenda, pulsa "Completar & Llenar Bitácora".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentLogs.length,
                        itemBuilder: (ctx, i) {
                          final log = recentLogs[i];
                          final cName = log['client_name'] ?? 'Alumno';
                          final date = log['schedule_date'] ?? '';
                          final rpe = log['rpe'] ?? 7;
                          final notes = log['notes'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: const Color(0xFF1FAE87),
                                          child: Text(
                                            cName.isNotEmpty ? cName[0].toUpperCase() : 'A',
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          cName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1FAE87).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'RPE $rpe/10',
                                        style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  date,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notes,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F192B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRPEBar(String label, dynamic countVal, Color color) {
    final int count = countVal is int ? countVal : int.tryParse(countVal.toString()) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('$count sesiones', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: count > 0 ? (count / 10).clamp(0.1, 1.0) : 0.0,
            backgroundColor: Colors.white10,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
