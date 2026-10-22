import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class BodyMetricsScreen extends StatefulWidget {
  final String? clientCedula;
  final String? clientName;

  const BodyMetricsScreen({super.key, this.clientCedula, this.clientName});

  @override
  State<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends State<BodyMetricsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _metrics = [];
  Map<String, dynamic> _summary = {};
  int _selectedTab = 0; // 0: Peso, 1: % Grasa, 2: Medidas (Cintura/Pecho/Brazo/Muslo)

  String get _targetUserCedula =>
      widget.clientCedula ?? AuthService.instance.loggedInUser?.cedula ?? '';

  bool get _isTrainerViewing => widget.clientCedula != null;

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    setState(() => _isLoading = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/progress/metrics/$_targetUserCedula'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is Map && mounted) {
          final rawList = data['metrics'] as List<dynamic>? ?? [];
          setState(() {
            _metrics = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _summary = data['summary'] as Map<String, dynamic>? ?? {};
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando métricas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddMetricModal() {
    final weightCtrl = TextEditingController(text: _summary['current_weight']?.toString() ?? '70.0');
    final fatCtrl = TextEditingController(text: _summary['current_body_fat']?.toString() ?? '');
    final waistCtrl = TextEditingController();
    final chestCtrl = TextEditingController();
    final armCtrl = TextEditingController();
    final thighCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.monitor_weight_rounded, color: Color(0xFF1FAE87), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Registrar Nueva Medición',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => Navigator.pop(modalCtx),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registra tu peso y circunferencias para evaluar tu recomposición corporal.',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Fecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fecha de medición:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF1FAE87)),
                        label: Text(
                          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: pickedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (d != null) {
                            setModalState(() => pickedDate = d);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Peso & Grasa
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Peso (kg) *',
                            labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                            prefixIcon: const Icon(Icons.scale, color: Color(0xFF1FAE87), size: 18),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: fatCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: '% Grasa (Opcional)',
                            labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                            prefixIcon: const Icon(Icons.pie_chart_outline, color: Colors.orangeAccent, size: 18),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Perímetros Corporales (Cintura, Pecho, Brazo, Muslo)
                  const Text(
                    'Circunferencias Corporales (cm, opcionales):',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: waistCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Cintura (cm)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: chestCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Pecho (cm)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: armCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Brazo (cm)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: thighCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Muslo / Pierna (cm)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: notesCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Notas (ej. en ayunas)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1FAE87),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check, size: 20),
                      label: Text(
                        isSaving ? 'Guardando medición...' : 'Guardar Medición',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final w = double.tryParse(weightCtrl.text.trim());
                              if (w == null || w <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Por favor introduce un peso válido.')),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              final baseUrl = AuthService.apiBaseUrl;
                              final dateStr =
                                  '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

                              try {
                                final res = await http.post(
                                  Uri.parse('$baseUrl/api/progress/metrics'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: json.encode({
                                    'user_id': _targetUserCedula,
                                    'weight': w,
                                    'body_fat': double.tryParse(fatCtrl.text.trim()),
                                    'waist': double.tryParse(waistCtrl.text.trim()),
                                    'chest': double.tryParse(chestCtrl.text.trim()),
                                    'arm': double.tryParse(armCtrl.text.trim()),
                                    'thigh': double.tryParse(thighCtrl.text.trim()),
                                    'notes': notesCtrl.text.trim(),
                                    'measured_at': dateStr,
                                  }),
                                );

                                if (res.statusCode == 200) {
                                  Navigator.of(modalCtx).pop();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFF1FAE87),
                                      content: Text('✅ ¡Medición guardada y peso actualizado!'),
                                    ),
                                  );
                                  await _fetchMetrics();
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error guardando medición: $e')),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isTrainerViewing
        ? 'Evolución: ${widget.clientName ?? "Alumno"}'
        : 'Evolución Corporal & Métricas';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1FAE87)),
            tooltip: 'Actualizar',
            onPressed: _fetchMetrics,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1FAE87),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Medición', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddMetricModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87)))
          : RefreshIndicator(
              color: const Color(0xFF1FAE87),
              onRefresh: _fetchMetrics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Banner KPIs
                    _buildSummaryKPIs(),
                    const SizedBox(height: 16),

                    // Tab selector (Peso / % Grasa / Medidas)
                    _buildTabSelector(),
                    const SizedBox(height: 16),

                    // Visual Chart Card
                    _buildVisualChartCard(),
                    const SizedBox(height: 20),

                    // Historial cronológico de registros
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Historial de Registros',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_metrics.length} mediciones',
                          style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildMetricsHistoryList(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryKPIs() {
    final curWeight = _summary['current_weight'] ?? 70.0;
    final weightDelta = (_summary['weight_delta'] as num?)?.toDouble() ?? 0.0;
    final curFat = _summary['current_body_fat'];
    final fatDelta = (_summary['body_fat_delta'] as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F192B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildKPITile(
                  title: 'Peso Actual',
                  value: '$curWeight kg',
                  delta: weightDelta,
                  unit: 'kg',
                  icon: Icons.scale_rounded,
                  color: const Color(0xFF1FAE87),
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white12),
              Expanded(
                child: _buildKPITile(
                  title: '% Grasa Corporal',
                  value: curFat != null ? '$curFat%' : '--',
                  delta: fatDelta,
                  unit: '%',
                  icon: Icons.pie_chart_rounded,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total mediciones: ${_summary['total_measurements'] ?? _metrics.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Text(
                'Última actualización: ${_summary['latest_date'] ?? ""}',
                style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKPITile({
    required String title,
    required String value,
    required double? delta,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (delta != null && delta != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (delta < 0 ? Colors.greenAccent : Colors.amberAccent).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${delta > 0 ? "+" : ""}$delta $unit',
                    style: TextStyle(
                      color: delta < 0 ? Colors.greenAccent : Colors.amberAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ['⚖️ Peso (kg)', '📉 % Grasa', '📏 Perímetros'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSel = _selectedTab == idx;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = idx),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF1FAE87) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[idx],
                  style: TextStyle(
                    color: isSel ? Colors.white : Colors.white60,
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVisualChartCard() {
    if (_metrics.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F192B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text('Sin suficientes datos para graficar evolución.', style: TextStyle(color: Colors.white54)),
      );
    }

    // Extract series according to selected tab
    List<double> values = [];
    String unit = 'kg';
    String label = 'Peso';
    Color lineColor = const Color(0xFF1FAE87);

    if (_selectedTab == 0) {
      values = _metrics.map((m) => (m['weight'] as num?)?.toDouble() ?? 70.0).toList();
      unit = 'kg';
      label = 'Evolución de Peso Corporal';
      lineColor = const Color(0xFF1FAE87);
    } else if (_selectedTab == 1) {
      values = _metrics
          .where((m) => m['body_fat'] != null)
          .map((m) => (m['body_fat'] as num).toDouble())
          .toList();
      if (values.isEmpty) values = [18.0];
      unit = '%';
      label = 'Evolución de Porcentaje de Grasa';
      lineColor = Colors.orangeAccent;
    } else {
      values = _metrics
          .where((m) => m['waist'] != null)
          .map((m) => (m['waist'] as num).toDouble())
          .toList();
      if (values.isEmpty) values = [80.0];
      unit = 'cm';
      label = 'Evolución de Cintura';
      lineColor = const Color(0xFF38BDF8);
    }

    final double minVal = values.reduce((a, b) => a < b ? a : b);
    final double maxVal = values.reduce((a, b) => a > b ? a : b);
    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F192B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lineColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${values.last.toStringAsFixed(1)} $unit',
                  style: TextStyle(color: lineColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom visual line / bar progression graph
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (idx) {
                final val = values[idx];
                final normalizedHeight = ((val - minVal) / range) * 100 + 30; // 30 to 130 px
                final dateStr = (_metrics[idx]['measured_at'] as String? ?? '').length >= 5
                    ? (_metrics[idx]['measured_at'] as String).substring(5)
                    : '';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          val.toStringAsFixed(1),
                          style: TextStyle(color: lineColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: normalizedHeight.clamp(20, 120),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [lineColor, lineColor.withOpacity(0.3)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateStr,
                          style: const TextStyle(color: Colors.white38, fontSize: 9),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsHistoryList() {
    if (_metrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('Aún no has registrado mediciones.', style: TextStyle(color: Colors.white54)),
      );
    }

    final reversed = _metrics.reversed.toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reversed.length,
      itemBuilder: (ctx, i) {
        final m = reversed[i];
        final w = m['weight'] ?? 70.0;
        final f = m['body_fat'];
        final waist = m['waist'];
        final chest = m['chest'];
        final arm = m['arm'];
        final thigh = m['thigh'];
        final notes = m['notes'] as String? ?? '';
        final date = m['measured_at'] ?? '';

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
                      const Icon(Icons.event, color: Color(0xFF1FAE87), size: 15),
                      const SizedBox(width: 6),
                      Text(date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1FAE87).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$w kg', style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (f != null)
                    Text('Grasa: $f%', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (waist != null)
                    Text('Cintura: $waist cm', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  if (chest != null)
                    Text('Pecho: $chest cm', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  if (arm != null)
                    Text('Brazo: $arm cm', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  if (thigh != null)
                    Text('Muslo: $thigh cm', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Nota: "$notes"', style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
              ]
            ],
          ),
        );
      },
    );
  }
}
