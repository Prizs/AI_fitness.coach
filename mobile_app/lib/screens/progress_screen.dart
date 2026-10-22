import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:mobile_app/services/auth_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  List<dynamic> _photos = [];
  List<Map<String, dynamic>> _evolutionChart = [];
  bool _isLoading = true;
  int _activeChartMetric = 0; // 0: Definición Muscular, 1: % Grasa Corporal

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  double _safeDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    final s = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s) ?? fallback;
  }

  Future<void> _fetchPhotos() async {
    final user = AuthService.instance.loggedInUser;
    final uid = user?.cedula ?? '';
    if (uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final url = Uri.parse('${AuthService.apiBaseUrl}/api/progress/$uid');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          setState(() {
            _photos = decoded['photos'] ?? [];
            final rawChart = decoded['evolution_chart'] as List?;
            _evolutionChart = rawChart != null
                ? rawChart.map((e) => Map<String, dynamic>.from(e as Map)).toList()
                : [];
            _isLoading = false;
          });
        } else if (decoded is List) {
          setState(() {
            _photos = decoded;
            _evolutionChart = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null) return;

      setState(() => _isUploading = true);

      final user = AuthService.instance.loggedInUser;
      final uid = user?.cedula ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.apiBaseUrl}/api/progress/upload'),
      );
      request.fields['user_id'] = uid;

      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final mimeSubtype = (ext == 'png') ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name.isNotEmpty ? image.name : 'progress.jpg',
          contentType: MediaType('image', mimeSubtype),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF1FAE87)),
                  SizedBox(width: 10),
                  Expanded(child: Text('¡Foto analizada con éxito por IA Vision!')),
                ],
              ),
              backgroundColor: Color(0xFF0F192B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await _fetchPhotos();
      } else {
        String detailMsg = 'Error en el servidor al analizar imagen.';
        try {
          final errJson = jsonDecode(response.body);
          if (errJson is Map && errJson['detail'] != null) {
            detailMsg = errJson['detail'].toString();
          }
        } catch (_) {
          if (response.body.isNotEmpty) detailMsg = response.body;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo procesar: $detailMsg'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showUploadSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1FAE87).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_enhance_rounded, color: Color(0xFF8BE0C0), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva Foto de Progreso',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Análisis Fisiológico con IA Vision',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF8BE0C0)),
                ),
                title: const Text('Tomar Foto con Cámara', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Captura tu compostura frontal con buena luz', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF38BDF8)),
                ),
                title: const Text('Elegir de Galería', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Selecciona una imagen de cuerpo completo', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _parseStructuredAnalysis(dynamic item) {
    Map<String, dynamic> data = {};
    if (item is Map && item['structured_analysis'] is Map) {
      data = Map<String, dynamic>.from(item['structured_analysis']);
    } else {
      final raw = item is Map ? item['ai_analysis'] : null;
      if (raw is String && raw.trim().startsWith('{')) {
        try {
          final parsed = jsonDecode(raw);
          if (parsed is Map) data = Map<String, dynamic>.from(parsed);
        } catch (_) {}
      }
    }

    if (data.isEmpty) {
      final rawStr = (item is Map ? item['ai_analysis'] : null) ?? '';
      data = {
        'headline': rawStr is String && rawStr.isNotEmpty ? rawStr : 'Análisis Fisiológico de Progreso',
        'photo_stage': 'Foto de Seguimiento',
        'photo_number': 1,
        'estimated_body_fat': 22.0,
        'muscle_definition_score': 6.0,
        'posture_score': 7.5,
        'biotype': 'Mesomorfo',
        'positive_changes': [
          'Alineación y compostura corporal estable',
          'Buena base para sobrecarga progresiva',
        ],
        'areas_to_improve': [
          'Enfocar el trabajo de core y deltoides en tus rutinas',
          'Mantener cadencia controlada en las repeticiones',
        ],
        'physiological_composition': rawStr is String ? rawStr : 'Compostura física en proceso activo de recomposición.',
        'training_plan_feedback': 'Cumple con los días programados y consulta a tu Coach cualquier duda.',
        'motivational_quote': 'La constancia en este mes de entrenamiento revelará los mejores resultados.',
      };
    } else {
      data['estimated_body_fat'] = _safeDouble(data['estimated_body_fat'], 22.0);
      data['muscle_definition_score'] = _safeDouble(data['muscle_definition_score'], 6.0);
      data['posture_score'] = _safeDouble(data['posture_score'], 7.5);
    }
    return data;
  }

  void _showImageZoom(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.92),
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 3.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.broken_image, color: Colors.white38, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pellizca con dos dedos para hacer zoom y evaluar definición muscular',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi Progreso (IA Vision)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Recomposición Corporal a 30 Días',
              style: TextStyle(fontSize: 11, color: Color(0xFF8BE0C0), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8BE0C0)),
            tooltip: 'Actualizar',
            onPressed: _fetchPhotos,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8BE0C0),
        foregroundColor: const Color(0xFF0A0F1D),
        onPressed: _isUploading ? null : _showUploadSourceSheet,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Color(0xFF0A0F1D), strokeWidth: 2.5),
              )
            : const Icon(Icons.add_a_photo_rounded, size: 20),
        label: Text(
          _isUploading ? 'Analizando con IA...' : 'Subir Foto',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8BE0C0)))
          : RefreshIndicator(
              color: const Color(0xFF8BE0C0),
              backgroundColor: const Color(0xFF0F192B),
              onRefresh: _fetchPhotos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 85),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mini Gráfico Superior de Evolución
                    _buildCompactEvolutionCard(),
                    const SizedBox(height: 16),

                    // Empty state vs Cards
                    if (_photos.isEmpty)
                      _buildDayOneGuidanceEmptyState()
                    else ...[
                      // Comparador Antes y Ahora si hay 2 o más fotos
                      if (_photos.length >= 2) ...[
                        _buildBeforeAfterCard(),
                        const SizedBox(height: 16),
                      ],

                      // Lista de fotos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Historial de Registros Visuales',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1FAE87).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_photos.length} fotos',
                              style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._photos.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return _buildPhotoCard(item, idx);
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // -------------------------------------------------------------
  // MINI GRÁFICO COMPACTO DE RECOMPOSICIÓN
  // -------------------------------------------------------------
  Widget _buildCompactEvolutionCard() {
    final hasData = _evolutionChart.length >= 2;
    final totalPoints = _evolutionChart.length;

    // Calcular deltas si hay al menos 2 puntos
    double defDelta = 0.0;
    double fatDelta = 0.0;
    if (hasData) {
      final firstP = _evolutionChart.first;
      final lastP = _evolutionChart.last;
      final firstDef = _safeDouble(firstP['definition_score'], 6.0);
      final lastDef = _safeDouble(lastP['definition_score'], 6.0);
      defDelta = lastDef - firstDef;

      final firstFat = _safeDouble(firstP['body_fat'], 22.0);
      final lastFat = _safeDouble(lastP['body_fat'], 22.0);
      fatDelta = lastFat - firstFat;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F192B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1FAE87).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF8BE0C0), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tendencia de Recomposición',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Selector de métrica para el mini-gráfico
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildChartMetricToggle(0, '⚡ Definición'),
                    _buildChartMetricToggle(1, '📉 % Grasa'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (!hasData) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF162338),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF8BE0C0), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      totalPoints == 1
                          ? 'Tienes 1 foto de punto de partida (Día 1). Al subir tu próxima foto en unos días, verás la curva de tu progreso aquí.'
                          : 'Sube tu foto de inicio del Día 1 para activar el trazado inteligente de definición muscular y grasa corporal.',
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            )
          ] else ...[
            // KPI resumen rápido de cambio
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162338),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFF8BE0C0), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Definición Muscular', style: TextStyle(color: Colors.white54, fontSize: 10)),
                              Text(
                                '${defDelta >= 0 ? "+" : ""}${defDelta.toStringAsFixed(1)} pts',
                                style: TextStyle(
                                  color: defDelta >= 0 ? const Color(0xFF8BE0C0) : Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162338),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_down, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Grasa Estimada', style: TextStyle(color: Colors.white54, fontSize: 10)),
                              Text(
                                '${fatDelta <= 0 ? "" : "+"}${fatDelta.toStringAsFixed(1)} %',
                                style: TextStyle(
                                  color: fatDelta <= 0 ? const Color(0xFF8BE0C0) : Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mini Custom Painter Graph
            SizedBox(
              height: 110,
              width: double.infinity,
              child: CustomPaint(
                painter: _MiniProgressChartPainter(
                  data: _evolutionChart,
                  metricIndex: _activeChartMetric,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartMetricToggle(int index, String label) {
    final isSelected = _activeChartMetric == index;
    return GestureDetector(
      onTap: () => setState(() => _activeChartMetric = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1FAE87) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // EMPTY STATE DIDÁCTICO Y MOTIVADOR (DÍA 1)
  // -------------------------------------------------------------
  Widget _buildDayOneGuidanceEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F192B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1FAE87).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Icon(Icons.camera_enhance_rounded, color: Color(0xFF8BE0C0), size: 54),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu Transformación de 30 Días',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Estás a punto de iniciar tu plan de entrenamiento. La IA Vision analizará tu compostura física actual para servir de punto de partida o "baseline" anatómico.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // 3 Pilares didácticos
          _buildPillarStep(
            icon: Icons.accessibility_new_rounded,
            color: const Color(0xFF8BE0C0),
            title: '1. Fotografía Inicial (Día 1)',
            desc: 'Toma una foto de cuerpo completo erguido con iluminación frontal adecuada.',
          ),
          const SizedBox(height: 12),
          _buildPillarStep(
            icon: Icons.psychology_rounded,
            color: const Color(0xFF38BDF8),
            title: '2. Análisis Fisiológico IA',
            desc: 'Estimación de biotipo, % grasa visible, tono muscular y alineación postural.',
          ),
          const SizedBox(height: 12),
          _buildPillarStep(
            icon: Icons.timeline_rounded,
            color: const Color(0xFFF59E0B),
            title: '3. Evolución en Gráficos',
            desc: 'Compara tus cambios cada semana con retroalimentación para tus rutinas.',
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _showUploadSourceSheet,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Comenzar con Foto Día 1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BE0C0),
                foregroundColor: const Color(0xFF0A0F1D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarStep({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162338),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // COMPARADOR ANTES / DESPUÉS
  // -------------------------------------------------------------
  Widget _buildBeforeAfterCard() {
    final oldest = _photos.last;
    final latest = _photos.first;
    final oldestAnalysis = _parseStructuredAnalysis(oldest);
    final latestAnalysis = _parseStructuredAnalysis(latest);

    final fat1 = _safeDouble(oldestAnalysis['estimated_body_fat'], 25.0);
    final fat2 = _safeDouble(latestAnalysis['estimated_body_fat'], 22.0);
    final def1 = _safeDouble(oldestAnalysis['muscle_definition_score'], 5.0);
    final def2 = _safeDouble(latestAnalysis['muscle_definition_score'], 6.5);

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
          const Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: Color(0xFF8BE0C0), size: 18),
              SizedBox(width: 8),
              Text(
                'Comparativa: Punto de Inicio vs Actualidad',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Foto Inicial
              Expanded(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
                            onTap: () => _showImageZoom(oldest['photo_url'] ?? '', 'Foto Inicial (Día 1)'),
                            child: Image.network(
                              oldest['photo_url'] ?? '',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: const Color(0xFF1E293B),
                                child: const Icon(Icons.image, color: Colors.white24),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Inicio (Día 1)', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${fat1.toStringAsFixed(1)}% Grasa · ${def1.toStringAsFixed(1)} Def', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Foto Actual
              Expanded(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
                            onTap: () => _showImageZoom(latest['photo_url'] ?? '', 'Foto Reciente'),
                            child: Image.network(
                              latest['photo_url'] ?? '',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: const Color(0xFF1E293B),
                                child: const Icon(Icons.image, color: Colors.white24),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1FAE87),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Actual', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${fat2.toStringAsFixed(1)}% Grasa · ${def2.toStringAsFixed(1)} Def', style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TARJETA DE FOTO INDIVIDUAL CON ANÁLISIS ESTRUCTURADO
  // -------------------------------------------------------------
  Widget _buildPhotoCard(dynamic item, int index) {
    final analysis = _parseStructuredAnalysis(item);
    final photoUrl = item['photo_url'] ?? '';
    final createdAt = item['created_at'] != null ? item['created_at'].toString().substring(0, 10) : '';

    final stage = analysis['photo_stage'] ?? (index == _photos.length - 1 ? 'Foto Inicial (Día 1)' : 'Foto de Seguimiento');
    final isBaseline = index == _photos.length - 1;
    final headline = analysis['headline'] ?? 'Evaluación de condición física';
    final estFat = _safeDouble(analysis['estimated_body_fat'], 22.0);
    final muscleDef = _safeDouble(analysis['muscle_definition_score'], 6.0);
    final posture = _safeDouble(analysis['posture_score'], 7.5);
    final biotype = analysis['biotype'] ?? 'Mesomorfo';

    final positiveChanges = (analysis['positive_changes'] as List?)?.cast<String>() ?? [];
    final areasToImprove = (analysis['areas_to_improve'] as List?)?.cast<String>() ?? [];
    final composition = analysis['physiological_composition'] ?? '';
    final trainingFeedback = analysis['training_plan_feedback'] ?? '';
    final quote = analysis['motivational_quote'] ?? '';

    return Card(
      color: const Color(0xFF101B2D),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isBaseline ? const Color(0xFF8BE0C0).withOpacity(0.4) : Colors.white10,
          width: isBaseline ? 1.5 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la tarjeta: Etapa + Fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBaseline ? const Color(0xFF8BE0C0).withOpacity(0.2) : const Color(0xFF38BDF8).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBaseline ? const Color(0xFF8BE0C0) : const Color(0xFF38BDF8),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isBaseline ? Icons.flag_rounded : Icons.trending_up_rounded,
                            size: 14,
                            color: isBaseline ? const Color(0xFF8BE0C0) : const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            stage,
                            style: TextStyle(
                              color: isBaseline ? const Color(0xFF8BE0C0) : const Color(0xFF38BDF8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (createdAt.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(createdAt, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Imagen con overlay de toque para zoom
            if (photoUrl.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showImageZoom(photoUrl, stage),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        photoUrl,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.white24, size: 40),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Zoom', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Headline de la IA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF162338),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF8BE0C0), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      headline,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3 KPIs en grid / badges
            Row(
              children: [
                Expanded(
                  child: _buildMetricBadge(
                    label: 'Definición',
                    value: '${muscleDef.toStringAsFixed(1)}/10',
                    icon: Icons.flash_on_rounded,
                    color: const Color(0xFF8BE0C0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricBadge(
                    label: 'Grasa Est.',
                    value: '${estFat.toStringAsFixed(1)}%',
                    icon: Icons.pie_chart_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricBadge(
                    label: 'Postura',
                    value: '${posture.toStringAsFixed(1)}/10',
                    icon: Icons.accessibility_rounded,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Biotipo Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  const Text('Biotipo detectado: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Expanded(
                    child: Text(
                      biotype.toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bloque Verde: Fortalezas y Cambios Positivos
            if (positiveChanges.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2E24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF8BE0C0), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Cambios Positivos & Fortalezas Visibles',
                          style: TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...positiveChanges.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Bloque Ámbar: Áreas de Enfoque y Oportunidad
            if (areasToImprove.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E220D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.track_changes_rounded, color: Color(0xFFF59E0B), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Áreas de Enfoque para el Próximo Mes',
                          style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...areasToImprove.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Acordeón Desplegable: Análisis Fisiológico Profundo
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: const Row(
                  children: [
                    Icon(Icons.biotech_rounded, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Análisis Fisiológico & Recomendación de Rutina',
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                children: [
                  if (composition.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162338),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Compostura Fisiológica & Biomecánica:',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11.5),
                          ),
                          const SizedBox(height: 4),
                          Text(composition, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (trainingFeedback.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162338),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ajuste para tu Plan de Entrenamiento:',
                            style: TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold, fontSize: 11.5),
                          ),
                          const SizedBox(height: 4),
                          Text(trainingFeedback, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (quote.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.format_quote_rounded, color: Colors.white38, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              quote,
                              style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF162338),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// PAINTER PARA EL MINI-GRÁFICO COMPACTO DE EVOLUCIÓN
// -------------------------------------------------------------
class _MiniProgressChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int metricIndex; // 0: Definición Muscular, 1: % Grasa

  _MiniProgressChartPainter({required this.data, required this.metricIndex});

  double _safeDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    final s = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s) ?? fallback;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final isDef = metricIndex == 0;
    final primaryColor = isDef ? const Color(0xFF8BE0C0) : const Color(0xFFF59E0B);

    final values = data.map((d) {
      if (isDef) {
        return _safeDouble(d['definition_score'], 6.0);
      } else {
        return _safeDouble(d['body_fat'], 20.0);
      }
    }).toList();

    double minVal = values.reduce((a, b) => a < b ? a : b);
    double maxVal = values.reduce((a, b) => a > b ? a : b);

    // Padding vertical para evitar que los puntos toquen los bordes
    if ((maxVal - minVal) < 1.0) {
      minVal -= 1.0;
      maxVal += 1.0;
    } else {
      final pad = (maxVal - minVal) * 0.2;
      minVal -= pad;
      maxVal += pad;
    }
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final stepX = data.length > 1 ? size.width / (data.length - 1) : size.width / 2;

    // Pintar líneas horizontales guía sutiles
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), gridPaint);

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = data.length > 1 ? i * stepX : size.width / 2;
      final normalizedY = (values[i] - minVal) / range;
      // Invertir Y porque en canvas 0 es arriba
      final y = size.height - (normalizedY * (size.height - 24)) - 12;
      points.add(Offset(x, y));
    }

    // Dibujar área con gradiente bajo la línea si hay 2+ puntos
    if (points.length > 1) {
      final pathArea = Path();
      pathArea.moveTo(points.first.dx, size.height);
      for (final p in points) {
        pathArea.lineTo(p.dx, p.dy);
      }
      pathArea.lineTo(points.last.dx, size.height);
      pathArea.close();

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(0.25),
            primaryColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(pathArea, gradientPaint);

      // Dibujar línea principal
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      final linePaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Dibujar puntos y etiquetas de valor
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final val = values[i];

      // Sombra del punto
      final shadowPaint = Paint()
        ..color = primaryColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(p, 6, shadowPaint);

      // Borde del punto
      final dotPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 4.5, dotPaint);

      // Centro blanco
      final innerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 2.5, innerDot);

      // Texto de valor encima del punto
      final textSpan = TextSpan(
        text: isDef ? val.toStringAsFixed(1) : '${val.toStringAsFixed(1)}%',
        style: TextStyle(
          color: primaryColor,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        (p.dx - textPainter.width / 2).clamp(0.0, size.width - textPainter.width),
        (p.dy - textPainter.height - 4).clamp(0.0, size.height - textPainter.height),
      );
      textPainter.paint(canvas, textOffset);

      // Etiqueta Foto #X debajo
      final labelSpan = TextSpan(
        text: i == 0 ? 'Día 1' : 'F${i + 1}',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 8.5,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelOffset = Offset(
        (p.dx - labelPainter.width / 2).clamp(0.0, size.width - labelPainter.width),
        size.height - labelPainter.height,
      );
      labelPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniProgressChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.metricIndex != metricIndex;
  }
}
