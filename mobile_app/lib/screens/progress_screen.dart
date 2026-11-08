import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:mobile_app/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/widgets/performance_report_modal.dart';
import 'package:mobile_app/screens/auth/onboarding_quiz_screen.dart';
import 'package:mobile_app/screens/adaptive_workout_screen.dart';
import 'package:mobile_app/screens/body_metrics_screen.dart';
import 'package:mobile_app/models/user_profile.dart';


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
  int _galleryIndex = 0;
  final PageController _galleryPageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  @override
  void dispose() {
    _galleryPageController.dispose();
    super.dispose();
  }

  List<dynamic> get _chronologicalPhotos {
    if (_photos.isEmpty) return [];
    final list = List<dynamic>.from(_photos);
    list.sort((a, b) {
      if (a is! Map || b is! Map) return 0;
      final aBase = a['is_baseline'] == true ? 1 : 0;
      final bBase = b['is_baseline'] == true ? 1 : 0;
      if (aBase != bBase) return bBase.compareTo(aBase); // baseline (Día 1) primero
      final aDate = a['created_at']?.toString() ?? '';
      final bDate = b['created_at']?.toString() ?? '';
      if (aDate.isNotEmpty && bDate.isNotEmpty) {
        return aDate.compareTo(bDate);
      }
      final aId = a['id'] is num ? a['id'] as num : 0;
      final bId = b['id'] is num ? b['id'] as num : 0;
      return aId.compareTo(bId);
    });
    return list;
  }

  void _goToGalleryPage(int index) {
    final list = _chronologicalPhotos;
    if (index >= 0 && index < list.length) {
      setState(() => _galleryIndex = index);
      if (_galleryPageController.hasClients) {
        _galleryPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        );
      }
    }
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

  bool get _hasDemoFlash {
    return _photos.any((p) {
      final raw = p is Map ? (p['ai_analysis'] ?? '') : '';
      return raw.contains('is_demo_flash') || raw.contains('Prueba Flash') || raw.contains('unsplash.com');
    });
  }

  Future<void> _triggerDemoFlash() async {
    final user = AuthService.instance.loggedInUser;
    final uid = user?.cedula ?? '';
    if (uid.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final res = await http.post(
        Uri.parse('${AuthService.apiBaseUrl}/api/progress/demo-flash/$uid'),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.flash_on_rounded, color: Color(0xFF8BE0C0)),
                  SizedBox(width: 10),
                  Expanded(child: Text('¡Prueba Flash generada! Revisa el gráfico y la comparativa de 1 Mes.')),
                ],
              ),
              backgroundColor: Color(0xFF0F192B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await _fetchPhotos();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo generar la prueba flash.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _clearDemoFlash() async {
    final user = AuthService.instance.loggedInUser;
    final uid = user?.cedula ?? '';
    if (uid.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final res = await http.delete(
        Uri.parse('${AuthService.apiBaseUrl}/api/progress/demo-flash/$uid'),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Simulación de Prueba Flash eliminada. Historial limpio.'),
              backgroundColor: Color(0xFF0F192B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await _fetchPhotos();
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source, {String photoType = 'body'}) async {
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
      request.fields['photo_type'] = photoType;

      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final mimeSubtype = (ext == 'png') ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');

      final fieldName = (photoType == 'scale') ? 'scale_file' : 'file';
      final defaultFileName = (photoType == 'scale') ? 'scale.jpg' : 'progress.jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: image.name.isNotEmpty ? image.name : defaultFileName,
          contentType: MediaType('image', mimeSubtype),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {}
        final detectedW = decoded is Map ? decoded['detected_weight_kg'] : null;

        if (mounted) {
          final isScale = photoType == 'scale' || detectedW != null;
          final msg = isScale
              ? '⚖️ ¡Peso de $detectedW kg identificado en balanza y registrado con éxito!'
              : '¡Foto analizada con éxito por IA Vision!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(isScale ? Icons.scale_rounded : Icons.check_circle, color: const Color(0xFF1FAE87)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(msg)),
                ],
              ),
              backgroundColor: const Color(0xFF0F192B),
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

  Future<void> _pickAndUploadDualPhotos() async {
    try {
      // 1. Elegir Foto Corporal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paso 1: Selecciona tu Foto Corporal (Frontal/Torso)'),
            backgroundColor: Color(0xFF173B45),
            duration: Duration(seconds: 3),
          ),
        );
      }
      final XFile? bodyImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (bodyImage == null) return;

      // 2. Elegir Foto de Balanza
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paso 2: Selecciona la foto de tu Balanza / Báscula'),
            backgroundColor: Color(0xFF173B45),
            duration: Duration(seconds: 3),
          ),
        );
      }
      final XFile? scaleImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (scaleImage == null) return;

      setState(() => _isUploading = true);

      final user = AuthService.instance.loggedInUser;
      final uid = user?.cedula ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.apiBaseUrl}/api/progress/upload'),
      );
      request.fields['user_id'] = uid;
      request.fields['photo_type'] = 'both';

      final bodyBytes = await bodyImage.readAsBytes();
      final bodyExt = bodyImage.name.split('.').last.toLowerCase();
      final bodyMime = (bodyExt == 'png') ? 'png' : (bodyExt == 'webp' ? 'webp' : 'jpeg');

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bodyBytes,
          filename: bodyImage.name.isNotEmpty ? bodyImage.name : 'body.jpg',
          contentType: MediaType('image', bodyMime),
        ),
      );

      final scaleBytes = await scaleImage.readAsBytes();
      final scaleExt = scaleImage.name.split('.').last.toLowerCase();
      final scaleMime = (scaleExt == 'png') ? 'png' : (scaleExt == 'webp' ? 'webp' : 'jpeg');

      request.files.add(
        http.MultipartFile.fromBytes(
          'scale_file',
          scaleBytes,
          filename: scaleImage.name.isNotEmpty ? scaleImage.name : 'scale.jpg',
          contentType: MediaType('image', scaleMime),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {}
        final detectedW = decoded is Map ? decoded['detected_weight_kg'] : null;

        if (mounted) {
          final msg = (detectedW != null)
              ? '⚖️ ¡Peso de $detectedW kg detectado en balanza y cuerpo analizado con éxito!'
              : '¡Progreso y balanza sincronizados con éxito!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF1FAE87)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(msg)),
                ],
              ),
              backgroundColor: const Color(0xFF0F192B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await _fetchPhotos();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al procesar: ${response.body}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registrar Progreso con IA',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Sube foto corporal o báscula para identificar tu peso',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // OPCIÓN 1: Foto Corporal
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF162338),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: Color(0xFF8BE0C0), size: 20),
                        ),
                        title: const Text('Foto Corporal (Cámara o Galería)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                        subtitle: const Text('Analiza grasa, simetría y definición muscular', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF8BE0C0), size: 20),
                              tooltip: 'Cámara',
                              onPressed: () {
                                Navigator.pop(ctx);
                                _pickAndUploadPhoto(ImageSource.camera, photoType: 'body');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF38BDF8), size: 20),
                              tooltip: 'Galería',
                              onPressed: () {
                                Navigator.pop(ctx);
                                _pickAndUploadPhoto(ImageSource.gallery, photoType: 'body');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // OPCIÓN 2: Foto de Balanza / Báscula
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF162338),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.scale_rounded, color: Color(0xFF38BDF8), size: 20),
                    ),
                    title: const Row(
                      children: [
                        Text('Foto de Balanza / Báscula', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                        SizedBox(width: 6),
                        Text('IA OCR', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    subtitle: const Text('Identifica automáticamente tu peso en kg', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF38BDF8), size: 20),
                          tooltip: 'Cámara Balanza',
                          onPressed: () {
                            Navigator.pop(ctx);
                            _pickAndUploadPhoto(ImageSource.camera, photoType: 'scale');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF8BE0C0), size: 20),
                          tooltip: 'Galería Balanza',
                          onPressed: () {
                            Navigator.pop(ctx);
                            _pickAndUploadPhoto(ImageSource.gallery, photoType: 'scale');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // OPCIÓN 3: Subir Ambas (Corporal + Balanza)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF162338),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.collections_rounded, color: Color(0xFFF59E0B), size: 20),
                    ),
                    title: const Text('Subir Ambas (Cuerpo + Balanza)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('1 foto de tu cuerpo + 1 foto de tu báscula a la vez', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUploadDualPhotos();
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // OPCIÓN 4: Encuesta y Medición Corporal (Sin Fotos - U.S. Navy Formula)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF162338),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.35)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.straighten_rounded, color: Color(0xFF8BE0C0), size: 20),
                    ),
                    title: const Row(
                      children: [
                        Text('Encuesta y Cinta Métrica (Sin Fotos)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                        SizedBox(width: 6),
                        Text('U.S. Navy', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    subtitle: const Text('Registro periódico sin cámara. Estimación de % grasa y masa muscular magra', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF8BE0C0)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showMeasurementsSurveySheet();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
  void _showMeasurementsSurveySheet() {
    final user = AuthService.instance.loggedInUser;
    final bool isFemale = (user?.gender ?? '').toLowerCase().contains('fem');
    final double defaultWeight = user?.weight ?? 75.0;

    final weightCtrl = TextEditingController(text: defaultWeight.toStringAsFixed(1));
    final heightCtrl = TextEditingController(text: '175.0');
    final waistCtrl = TextEditingController(text: '85.0');
    final neckCtrl = TextEditingController(text: '38.0');
    final hipCtrl = TextEditingController(text: isFemale ? '95.0' : '');
    final chestCtrl = TextEditingController(text: '');
    final armCtrl = TextEditingController(text: '');

    String selectedPeriod = 'Quincenal (Recomendado)';
    bool isSavingMetric = false;
    bool showGuide = false;

    double calcBodyFat(double w, double h, double waist, double neck, double hip, bool female) {
      try {
        if (h <= 50 || waist <= 30 || neck <= 15) return 0.0;
        final log10 = (num v) => math.log(v) / math.ln10;
        if (!female) {
          final diff = waist - neck;
          if (diff <= 0) return 0.0;
          final denom = 1.0324 - (0.19077 * log10(diff)) + (0.15456 * log10(h));
          final bf = (495.0 / denom) - 450.0;
          return bf.clamp(3.0, 55.0);
        } else {
          final sum = waist + hip - neck;
          if (sum <= 0) return 0.0;
          final denom = 1.29579 - (0.35004 * log10(sum)) + (0.22100 * log10(h));
          final bf = (495.0 / denom) - 450.0;
          return bf.clamp(8.0, 60.0);
        }
      } catch (_) {
        return 0.0;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentWeight = double.tryParse(weightCtrl.text.trim()) ?? defaultWeight;
          final currentHeight = double.tryParse(heightCtrl.text.trim()) ?? 175.0;
          final currentWaist = double.tryParse(waistCtrl.text.trim()) ?? 85.0;
          final currentNeck = double.tryParse(neckCtrl.text.trim()) ?? 38.0;
          final currentHip = double.tryParse(hipCtrl.text.trim()) ?? (isFemale ? 95.0 : 0.0);

          final calculatedFat = calcBodyFat(currentWeight, currentHeight, currentWaist, currentNeck, currentHip, isFemale);
          final calculatedLean = calculatedFat > 0 ? (currentWeight * (1.0 - (calculatedFat / 100.0))) : 0.0;
          final calculatedFatKg = calculatedFat > 0 ? (currentWeight * (calculatedFat / 100.0)) : 0.0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 20,
              right: 20,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8BE0C0).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.straighten_rounded, color: Color(0xFF8BE0C0), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Encuesta de Medición Corporal',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Cálculo clínico oficial de % grasa (Fórmula U.S. Navy)',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Selector de Frecuencia
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162338),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Frecuencia del Registro:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          DropdownButton<String>(
                            value: selectedPeriod,
                            dropdownColor: const Color(0xFF162338),
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8BE0C0)),
                            items: const [
                              DropdownMenuItem(value: 'Semanal', child: Text('Semanal', style: TextStyle(color: Colors.white, fontSize: 12))),
                              DropdownMenuItem(value: 'Quincenal (Recomendado)', child: Text('Quincenal (Recomendado)', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 12, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'Mensual', child: Text('Mensual', style: TextStyle(color: Colors.white, fontSize: 12))),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedPeriod = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tarjeta de Cálculo En Vivo
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF162A38), Color(0xFF101E2E)]),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.insights_rounded, color: Color(0xFF8BE0C0), size: 16),
                              SizedBox(width: 6),
                              Text('Resultados Calculados por U.S. Navy:', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    calculatedFat > 0 ? '${calculatedFat.toStringAsFixed(1)}%' : '--%',
                                    style: const TextStyle(color: Color(0xFFFFB340), fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                  const Text('Grasa Corporal', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                ],
                              ),
                              Container(width: 1, height: 32, color: Colors.white12),
                              Column(
                                children: [
                                  Text(
                                    calculatedLean > 0 ? '${calculatedLean.toStringAsFixed(1)} kg' : '-- kg',
                                    style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                  const Text('Masa Muscular Magra', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                ],
                              ),
                              Container(width: 1, height: 32, color: Colors.white12),
                              Column(
                                children: [
                                  Text(
                                    calculatedFatKg > 0 ? '${calculatedFatKg.toStringAsFixed(1)} kg' : '-- kg',
                                    style: const TextStyle(color: Color(0xFF64D2FF), fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                  const Text('Grasa en Peso', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botón para desplegar Guía de Cómo Medirse
                    InkWell(
                      onTap: () => setModalState(() => showGuide = !showGuide),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132033),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.help_outline_rounded, color: Color(0xFF38BDF8), size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('¿Cómo tomar tus medidas correctamente? (Guía)', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ),
                            Icon(showGuide ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF38BDF8), size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (showGuide) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📏 Cuello: Mide horizontalmente justo debajo de la nuez de Adán (o parte media del cuello), con la cinta firme pero sin apretar.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            SizedBox(height: 4),
                            Text('📏 Cintura: En hombres al nivel del ombligo; en mujeres en la parte más estrecha del torso (relajado, sin meter el abdomen).', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            SizedBox(height: 4),
                            Text('📏 Cadera (Mujeres): Mide en el punto de mayor circunferencia de los glúteos de pie con pies juntos.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            SizedBox(height: 4),
                            Text('⚖️ Peso: Pésate en ayunas por la mañana tras ir al baño para máxima precisión.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Campos de Entrada Numéricos
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Peso (kg) *',
                              labelStyle: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 12),
                              prefixIcon: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF8BE0C0), size: 18),
                              filled: true,
                              fillColor: const Color(0xFF162338),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: heightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Altura (cm) *',
                              labelStyle: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 12),
                              prefixIcon: const Icon(Icons.height_rounded, color: Color(0xFF8BE0C0), size: 18),
                              filled: true,
                              fillColor: const Color(0xFF162338),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: waistCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Cintura (cm) *',
                              labelStyle: const TextStyle(color: Color(0xFFFFB340), fontSize: 12),
                              prefixIcon: const Icon(Icons.fitness_center_rounded, color: Color(0xFFFFB340), size: 18),
                              filled: true,
                              fillColor: const Color(0xFF162338),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: neckCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Cuello (cm) *',
                              labelStyle: const TextStyle(color: Color(0xFF64D2FF), fontSize: 12),
                              prefixIcon: const Icon(Icons.accessibility_rounded, color: Color(0xFF64D2FF), size: 18),
                              filled: true,
                              fillColor: const Color(0xFF162338),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (isFemale) ...[
                      TextFormField(
                        controller: hipCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Cadera (cm) * (requerido para mujeres)',
                          labelStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                          prefixIcon: const Icon(Icons.female_rounded, color: Color(0xFFFF6B6B), size: 18),
                          filled: true,
                          fillColor: const Color(0xFF162338),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: chestCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Pecho (cm) (opcional)',
                              labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                              filled: true,
                              fillColor: const Color(0xFF162338),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: armCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Brazo (cm) (opcional)',
                              labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                              filled: true,
                              fillColor: const Color(0xFF162338),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Botón de Enviar Encuesta
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: isSavingMetric
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.check_circle_rounded, color: Color(0xFF0A0F1D)),
                        label: Text(
                          isSavingMetric ? 'Guardando Registro...' : 'Guardar Encuesta de Progreso',
                          style: const TextStyle(color: Color(0xFF0A0F1D), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BE0C0),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSavingMetric ? null : () async {
                          final w = double.tryParse(weightCtrl.text.trim()) ?? 0.0;
                          final h = double.tryParse(heightCtrl.text.trim()) ?? 0.0;
                          final waist = double.tryParse(waistCtrl.text.trim()) ?? 0.0;
                          final neck = double.tryParse(neckCtrl.text.trim()) ?? 0.0;
                          final hip = double.tryParse(hipCtrl.text.trim());
                          final chest = double.tryParse(chestCtrl.text.trim());
                          final arm = double.tryParse(armCtrl.text.trim());

                          if (w <= 30 || h <= 50 || waist <= 30 || neck <= 15) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor completa peso, altura, cintura y cuello válidos.')),
                            );
                            return;
                          }

                          setModalState(() => isSavingMetric = true);
                          try {
                            final uid = user?.cedula ?? AuthService.instance.loggedInUser?.cedula ?? '';
                            final payload = {
                              'user_id': uid,
                              'weight': w,
                              'body_fat': calculatedFat > 0 ? double.parse(calculatedFat.toStringAsFixed(1)) : null,
                              'muscle_mass': calculatedLean > 0 ? double.parse(calculatedLean.toStringAsFixed(1)) : null,
                              'waist': waist,
                              'neck': neck,
                              'hip': hip,
                              'height': h,
                              'chest': chest,
                              'arm': arm,
                              'notes': 'Encuesta periódica ($selectedPeriod) - Fórmula U.S. Navy',
                            };

                            final res = await http.post(
                              Uri.parse('${AuthService.apiBaseUrl}/api/progress/metrics'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode(payload),
                            ).timeout(const Duration(seconds: 10));

                            if (res.statusCode == 200 || res.statusCode == 201) {
// weight updated on backend
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF132B36),
                                  content: Text(
                                    '✅ Encuesta guardada: ${w}kg · ${calculatedFat > 0 ? "${calculatedFat.toStringAsFixed(1)}% grasa" : ""}',
                                    style: const TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                              _fetchPhotos();
                            } else {
                              throw Exception('Servidor respondió con código ${res.statusCode}');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error guardando encuesta: $e')),
                            );
                          } finally {
                            if (mounted) setModalState(() => isSavingMetric = false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
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
          TextButton.icon(
            onPressed: _showMeasurementsSurveySheet,
            icon: const Icon(Icons.straighten_rounded, color: Color(0xFF8BE0C0), size: 16),
            label: const Text('Encuesta Medidas', style: TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold, fontSize: 11.5)),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0).withOpacity(0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Actualizar',
            onPressed: _isUploading ? null : _fetchPhotos,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF0F192B),
            onSelected: (val) {
              if (val == 'test_flash') {
                _triggerDemoFlash();
              } else if (val == 'clear_flash') {
                _clearDemoFlash();
              } else if (val == 'refresh') {
                _fetchPhotos();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'test_flash',
                child: Row(
                  children: [
                    Icon(Icons.flash_on_rounded, color: Color(0xFF8BE0C0), size: 18),
                    SizedBox(width: 8),
                    Text('Generar Test Mes 1', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              if (_hasDemoFlash)
                const PopupMenuItem(
                  value: 'clear_flash',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Limpiar Test Mes 1', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text('Actualizar Fotos', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
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
          _isUploading ? 'Analizando...' : 'Registrar Progreso',
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
                    // Banner si hay simulación de prueba flash activa
                    if (_hasDemoFlash)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132238),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Mostrando simulación de Prueba Flash (Mes 1).',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                            ),
                            TextButton(
                              onPressed: _clearDemoFlash,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Quitar Test', style: TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    // Mini Gráfico Superior de Evolución
                    _buildCompactEvolutionCard(),
                    const SizedBox(height: 16),

                    // Suite Completa de Informes & Evaluación de Progreso
                    _buildProgressSuiteCards(),

                    // Empty state vs Cards
                    if (_photos.isEmpty)
                      _buildDayOneGuidanceEmptyState()
                    else ...[
                      // Comparador Antes y Ahora si hay 2 o más fotos
                      if (_photos.length >= 2) ...[
                        _buildBeforeAfterCard(),
                        const SizedBox(height: 16),
                      ],

                      // Galería de Evolución Cronológica (Día 1 en adelante con swipe lateral táctil)
                      _buildPhotoEvolutionGallery(_chronologicalPhotos),
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

  Future<void> _downloadBitacoraPdf() async {
    final user = AuthService.instance.loggedInUser;
    final cedula = user?.cedula ?? 'default';
    final baseUrl = AuthService.apiBaseUrl;
    final url = '$baseUrl/api/coach/bitacora/export?cedula=$cedula&print_auto=true';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir la bitácora: $e')),
        );
      }
    }
  }

  Widget _buildProgressSuiteCards() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BE0C0).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assessment_rounded, color: Color(0xFF8BE0C0), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informes & Evaluación de Progreso',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Reportes de rendimiento, bitácora descargable y métricas',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Ver Reporte Detallado de Rendimiento
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF173B45),
              foregroundColor: const Color(0xFF8BE0C0),
              side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.assessment_rounded, size: 20),
            label: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ver Reporte Detallado de Rendimiento', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                Icon(Icons.arrow_forward_ios_rounded, size: 13),
              ],
            ),
            onPressed: () => PerformanceReportModal.show(context),
          ),
          const SizedBox(height: 8),

          // 2. Descargar Bitácora Oficial (PDF)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF102820),
              foregroundColor: const Color(0xFF8BE0C0),
              side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 20, color: Color(0xFF8BE0C0)),
            label: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Descargar Bitácora Oficial (PDF)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                Icon(Icons.open_in_new_rounded, size: 13),
              ],
            ),
            onPressed: _downloadBitacoraPdf,
          ),
          const SizedBox(height: 8),

          // 3. Evolución Corporal, Peso & Medidas
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F192B),
              foregroundColor: const Color(0xFF1FAE87),
              side: const BorderSide(color: Color(0xFF1FAE87), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.show_chart_rounded, size: 20),
            label: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Evolución Corporal, Peso & Medidas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                Icon(Icons.arrow_forward_ios_rounded, size: 13),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BodyMetricsScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // 4. Test Biopsicosocial & Adherencia (FitCraft)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142436),
              foregroundColor: const Color(0xFF8BE0C0),
              side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.1),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.psychology_rounded, size: 20, color: Color(0xFF8BE0C0)),
            label: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Test Biopsicosocial & Adherencia (FitCraft)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                Icon(Icons.arrow_forward_ios_rounded, size: 13),
              ],
            ),
            onPressed: () {
              final u = AuthService.instance.loggedInUser ??
                  UserProfile(
                    cedula: '0000000',
                    name: 'Usuario',
                    lastName: '',
                    age: 25,
                    weight: 70,
                  );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OnboardingQuizScreen(
                    userProfile: u,
                    onComplete: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // 5. Test Módulo Adaptado (Torso Sentado & Inclusivo)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF132034),
              foregroundColor: const Color(0xFF8BE0C0),
              side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.1),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.accessible_forward_rounded, size: 20, color: Color(0xFF8BE0C0)),
            label: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Test Módulo Adaptado (Torso Sentado)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                Icon(Icons.arrow_forward_ios_rounded, size: 13),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdaptiveWorkoutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEvolutionCard() {
    final hasData = _evolutionChart.length >= 2;
    final totalPoints = _evolutionChart.length;

    // Calcular deltas si hay al menos 2 puntos
    double defDelta = 0.0;
    double fatDelta = 0.0;
    double weightDelta = 0.0;
    if (hasData) {
      final firstP = _evolutionChart.first;
      final lastP = _evolutionChart.last;
      final firstDef = _safeDouble(firstP['definition_score'], 6.0);
      final lastDef = _safeDouble(lastP['definition_score'], 6.0);
      defDelta = lastDef - firstDef;

      final firstFat = _safeDouble(firstP['body_fat'], 22.0);
      final lastFat = _safeDouble(lastP['body_fat'], 22.0);
      fatDelta = lastFat - firstFat;

      final firstW = _safeDouble(firstP['weight'], 70.0);
      final lastW = _safeDouble(lastP['weight'], 70.0);
      weightDelta = lastW - firstW;
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
              // Selector de 3 métricas para el mini-gráfico
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
                    _buildChartMetricToggle(2, '⚖️ Peso'),
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
                          ? 'Tienes 1 foto de punto de partida (Día 1). Al subir tu próxima foto o foto de balanza, verás la curva de tu progreso aquí.'
                          : 'Sube tu foto corporal o foto de balanza para activar el trazado inteligente de peso, definición muscular y grasa corporal.',
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            )
          ] else ...[
            // KPI resumen rápido de cambio (3 columnas: Definición, Grasa, Peso)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162338),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFF8BE0C0), size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Definición', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
                              Text(
                                '${defDelta >= 0 ? "+" : ""}${defDelta.toStringAsFixed(1)} pts',
                                style: TextStyle(
                                  color: defDelta >= 0 ? const Color(0xFF8BE0C0) : Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162338),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_down, color: Color(0xFFF59E0B), size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Grasa', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
                              Text(
                                '${fatDelta <= 0 ? "" : "+"}${fatDelta.toStringAsFixed(1)} %',
                                style: TextStyle(
                                  color: fatDelta <= 0 ? const Color(0xFF8BE0C0) : Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162338),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.scale_rounded, color: Color(0xFF38BDF8), size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Peso', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
                              Text(
                                '${weightDelta <= 0 ? "" : "+"}${weightDelta.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  color: weightDelta <= 0 ? const Color(0xFF38BDF8) : Colors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showMeasurementsSurveySheet,
              icon: const Icon(Icons.straighten_rounded, color: Color(0xFF8BE0C0), size: 20),
              label: const Text('O Iniciar con Encuesta y Cinta Métrica (Sin Fotos)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF8BE0C0))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  // COMPARADOR ANTES / DESPUÉS (LÍNEA BASE VS ACTUALIDAD)
  // -------------------------------------------------------------
  Widget _buildBeforeAfterCard() {
    final chrono = _chronologicalPhotos;
    final oldest = chrono.first;
    final latest = chrono.last;
    final oldestAnalysis = _parseStructuredAnalysis(oldest);
    final latestAnalysis = _parseStructuredAnalysis(latest);

    final fat1 = _safeDouble(oldestAnalysis['estimated_body_fat'], 26.0);
    final fat2 = _safeDouble(latestAnalysis['estimated_body_fat'], 24.0);
    final fatDelta = fat2 - fat1;

    final def1 = _safeDouble(oldestAnalysis['muscle_definition_score'], 3.5);
    final def2 = _safeDouble(latestAnalysis['muscle_definition_score'], 4.5);
    final defDelta = def2 - def1;

    final posture1 = _safeDouble(oldestAnalysis['posture_score'], 6.5);
    final posture2 = _safeDouble(latestAnalysis['posture_score'], 7.0);
    final postureDelta = posture2 - posture1;

    final comp = latestAnalysis['comparison_with_previous'] is Map
        ? Map<String, dynamic>.from(latestAnalysis['comparison_with_previous'])
        : null;
    final clinicalNotes = comp?['clinical_comparison']?.toString() ?? '';
    final anatomicalChanges = (comp?['specific_anatomical_changes'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F192B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
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
                    child: const Icon(Icons.compare_arrows_rounded, color: Color(0xFF8BE0C0), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Comparativa de Recomposición (Línea Base vs Actual)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF162338),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_photos.length} Jornadas',
                  style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fotos lado a lado
          Row(
            children: [
              // Foto Inicial
              Expanded(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: () => _showImageZoom(oldest['photo_url'] ?? '', 'Línea Base · Día 1'),
                            child: Image.network(
                              oldest['photo_url'] ?? '',
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 140,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Línea Base (Día 1)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 12),
                                SizedBox(width: 2),
                                Text('Zoom', style: TextStyle(color: Colors.white, fontSize: 9.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${fat1.toStringAsFixed(1)}% Grasa · ${def1.toStringAsFixed(1)} Def',
                      style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
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
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: () => _showImageZoom(latest['photo_url'] ?? '', 'Jornada Actual'),
                            child: Image.network(
                              latest['photo_url'] ?? '',
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 140,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1FAE87),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Jornada Actual', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 12),
                                SizedBox(width: 2),
                                Text('Zoom', style: TextStyle(color: Colors.white, fontSize: 9.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${fat2.toStringAsFixed(1)}% Grasa · ${def2.toStringAsFixed(1)} Def',
                      style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scoreboard de variación métrica
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF162338),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreboardItem(
                  label: '% Grasa Corporal',
                  fromVal: '${fat1.toStringAsFixed(1)}%',
                  toVal: '${fat2.toStringAsFixed(1)}%',
                  delta: '${fatDelta <= 0 ? "" : "+"}${fatDelta.toStringAsFixed(1)}%',
                  isPositive: fatDelta <= 0,
                  icon: Icons.pie_chart_rounded,
                ),
                Container(width: 1, height: 35, color: Colors.white12),
                _buildScoreboardItem(
                  label: 'Definición Muscular',
                  fromVal: def1.toStringAsFixed(1),
                  toVal: def2.toStringAsFixed(1),
                  delta: '${defDelta >= 0 ? "+" : ""}${defDelta.toStringAsFixed(1)} pts',
                  isPositive: defDelta >= 0,
                  icon: Icons.bolt_rounded,
                ),
                Container(width: 1, height: 35, color: Colors.white12),
                _buildScoreboardItem(
                  label: 'Postura & Simetría',
                  fromVal: posture1.toStringAsFixed(1),
                  toVal: posture2.toStringAsFixed(1),
                  delta: '${postureDelta >= 0 ? "+" : ""}${postureDelta.toStringAsFixed(1)} pts',
                  isPositive: postureDelta >= 0,
                  icon: Icons.accessibility_rounded,
                ),
              ],
            ),
          ),

          if (clinicalNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF132238),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.biotech_rounded, color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Evaluación Anatómica Contrastada (IA Vision):',
                        style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(clinicalNotes, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.35)),
                  if (anatomicalChanges.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: anatomicalChanges.map((change) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D2E24),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.4)),
                        ),
                        child: Text('✓ $change', style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 10.5, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreboardItem({
    required String label,
    required String fromVal,
    required String toVal,
    required String delta,
    required bool isPositive,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white54),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '$fromVal ➔ $toVal',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: (isPositive ? const Color(0xFF1FAE87) : Colors.orangeAccent).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            delta,
            style: TextStyle(
              color: isPositive ? const Color(0xFF8BE0C0) : Colors.orangeAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // GALERÍA HORIZONTAL DE EVOLUCIÓN (SWIPE DÍA 1 -> DÍA 30)
  // -------------------------------------------------------------
  Widget _buildPhotoEvolutionGallery(List<dynamic> photos) {
    if (photos.isEmpty) return const SizedBox.shrink();

    final safeIdx = _galleryIndex.clamp(0, photos.length - 1);
    final activeItem = photos[safeIdx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de la galería con contador
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_motion_rounded, color: Color(0xFF8BE0C0), size: 18),
                SizedBox(width: 8),
                Text(
                  'Galería de Evolución',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1FAE87).withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.4)),
              ),
              child: Text(
                'Foto ${safeIdx + 1} de ${photos.length}',
                style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Desliza horizontalmente (o usa las flechas) para recorrer cronológicamente tu transformación desde el Día 1.',
          style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.3),
        ),
        const SizedBox(height: 12),

        // Chips interactivos para saltar a cualquier día/foto directamente
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(photos.length, (i) {
              final isSel = i == safeIdx;
              final p = photos[i];
              final isBase = i == 0 || (p is Map && p['is_baseline'] == true);
              final pAnalysis = _parseStructuredAnalysis(p);
              final rawStage = (p is Map ? p['stage'] : null) ?? pAnalysis['photo_stage'];
              final label = isBase
                  ? '🌱 Día 1 (Inicial)'
                  : (rawStage != null && rawStage.toString().isNotEmpty
                      ? rawStage.toString()
                      : 'Foto #${i + 1}');

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _goToGalleryPage(i),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (isBase ? const Color(0xFF1FAE87) : const Color(0xFF38BDF8))
                          : const Color(0xFF162338),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel
                            ? Colors.transparent
                            : (isBase
                                ? const Color(0xFF8BE0C0).withOpacity(0.35)
                                : const Color(0xFF38BDF8).withOpacity(0.35)),
                        width: isSel ? 1.5 : 1,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: (isBase ? const Color(0xFF1FAE87) : const Color(0xFF38BDF8)).withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSel ? Colors.black : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // Carrusel visual de fotos con swipe horizontal y flechas de navegación
        Container(
          height: 330,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A2B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // PageView deslizable horizontalmente (Día 1 -> Final)
                PageView.builder(
                  controller: _galleryPageController,
                  itemCount: photos.length,
                  onPageChanged: (idx) {
                    setState(() => _galleryIndex = idx);
                  },
                  itemBuilder: (context, idx) {
                    final item = photos[idx];
                    final photoUrl = item is Map ? (item['photo_url'] ?? '') : '';
                    final createdAt = item is Map && item['created_at'] != null
                        ? item['created_at'].toString().substring(0, 10)
                        : '';
                    final isBase = idx == 0 || (item is Map && item['is_baseline'] == true);
                    final analysis = _parseStructuredAnalysis(item);
                    final stage = (item is Map ? item['stage'] : null) ??
                        analysis['photo_stage'] ??
                        (isBase ? 'Fotografía Inicial (Día 1)' : 'Foto #${idx + 1}');

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Imagen con soporte de red y fallback de carga
                        if (photoUrl.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showImageZoom(photoUrl, stage),
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF162338),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image_rounded, color: Colors.white24, size: 48),
                                      SizedBox(height: 8),
                                      Text('Error cargando fotografía', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: const Color(0xFF162338),
                            child: const Center(
                              child: Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 48),
                            ),
                          ),

                        // Gradiente superior para visibilidad de badges
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // Gradiente inferior para controles
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // Overlay Superior Izquierdo: Etapa
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isBase
                                  ? const Color(0xFF1FAE87).withOpacity(0.9)
                                  : const Color(0xFF0284C7).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isBase ? Icons.flag_rounded : Icons.trending_up_rounded, size: 13, color: Colors.white),
                                const SizedBox(width: 5),
                                Text(
                                  stage,
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Overlay Superior Derecho: Fecha
                        if (createdAt.isNotEmpty)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(createdAt, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),

                        // Overlay Inferior Izquierdo: Guía de gesto
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swipe_rounded, size: 12, color: Colors.white70),
                                SizedBox(width: 4),
                                Text('Desliza ◄ ►', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                              ],
                            ),
                          ),
                        ),

                        // Overlay Inferior Derecho: Botón Zoom
                        if (photoUrl.isNotEmpty)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showImageZoom(photoUrl, stage),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Zoom', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                // Flecha Izquierda de Navegación
                if (safeIdx > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _goToGalleryPage(safeIdx - 1),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Flecha Derecha de Navegación
                if (safeIdx < photos.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _goToGalleryPage(safeIdx + 1),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Indicador de Paginación (Dots)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(photos.length, (i) {
            final isSel = i == safeIdx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSel ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF8BE0C0) : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Tarjeta con TODAS las Descripciones Fisiológicas y Clínicas Correspondientes a la Foto Activa
        _buildActivePhotoDetails(activeItem, safeIdx, photos.length),
      ],
    );
  }

  // -------------------------------------------------------------
  // DESCRIPCIONES CLÍNICAS Y FISIOLÓGICAS DE LA FOTO SELECCIONADA
  // -------------------------------------------------------------
  Widget _buildActivePhotoDetails(dynamic item, int index, int totalPhotos) {
    final analysis = _parseStructuredAnalysis(item);
    final createdAt = item is Map && item['created_at'] != null
        ? item['created_at'].toString().substring(0, 10)
        : '';
    final isBaseline = index == 0 || (item is Map && item['is_baseline'] == true);
    final stage = (item is Map ? item['stage'] : null) ??
        analysis['photo_stage'] ??
        (isBaseline ? 'Fotografía Inicial (Día 1)' : 'Foto #${index + 1}');

    final headline = analysis['headline'] ??
        (isBaseline ? 'Fase Inicial: Baseline anatómico y punto de partida' : 'Evaluación de condición física');
    final estFat = _safeDouble(analysis['estimated_body_fat'], 22.0);
    final muscleDef = _safeDouble(analysis['muscle_definition_score'], 6.0);
    final posture = _safeDouble(analysis['posture_score'], 7.5);
    final biotype = analysis['biotype'] ?? 'Mesomorfo';

    final positiveChanges = (analysis['positive_changes'] as List?)?.cast<String>() ?? [];
    final areasToImprove = (analysis['areas_to_improve'] as List?)?.cast<String>() ?? [];
    final composition = analysis['physiological_composition'] ?? '';
    final trainingFeedback = analysis['training_plan_feedback'] ?? '';
    final quote = analysis['motivational_quote'] ?? '';

    final comp = analysis['comparison_with_previous'] is Map
        ? Map<String, dynamic>.from(analysis['comparison_with_previous'])
        : null;
    final compNotes = comp?['clinical_comparison']?.toString() ?? '';
    final compChanges = (comp?['specific_anatomical_changes'] as List?)?.cast<String>() ?? [];
    final prevDateStr = comp?['previous_date']?.toString() ?? '';
    final bfDelta = comp != null ? _safeDouble(comp['body_fat_delta']) : 0.0;
    final defDelta = comp != null ? _safeDouble(comp['muscle_definition_delta']) : 0.0;

    return Card(
      color: const Color(0xFF101B2D),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isBaseline ? const Color(0xFF8BE0C0).withOpacity(0.4) : Colors.white12,
          width: isBaseline ? 1.5 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la etapa activa y fecha
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

            // Bloque Comparativo con Registro Anterior (si existe y no es baseline)
            if (comp != null && !isBaseline) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF132238),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.insights_rounded, color: Color(0xFF38BDF8), size: 15),
                            const SizedBox(width: 6),
                            Text(
                              'Evolución vs Jornada Previa ${prevDateStr.isNotEmpty ? "($prevDateStr)" : ""}',
                              style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (bfDelta <= 0 ? const Color(0xFF1FAE87) : Colors.orangeAccent).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Grasa: ${bfDelta <= 0 ? "" : "+"}${bfDelta.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: bfDelta <= 0 ? const Color(0xFF8BE0C0) : Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (defDelta >= 0 ? const Color(0xFF1FAE87) : Colors.orangeAccent).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Def: ${defDelta >= 0 ? "+" : ""}${defDelta.toStringAsFixed(1)} pts',
                                style: TextStyle(
                                  color: defDelta >= 0 ? const Color(0xFF8BE0C0) : Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (compNotes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(compNotes, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.35)),
                    ],
                    if (compChanges.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...compChanges.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✓ ', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11)),
                            Expanded(child: Text(c, style: const TextStyle(color: Colors.white70, fontSize: 10.5))),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

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
                      (it) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(it, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3)),
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
                      (it) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(it, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3)),
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
    final isFat = metricIndex == 1;
    final isWeight = metricIndex == 2;

    final primaryColor = isDef
        ? const Color(0xFF8BE0C0)
        : (isFat ? const Color(0xFFF59E0B) : (isWeight ? const Color(0xFF38BDF8) : const Color(0xFF8BE0C0)));

    final values = data.map((d) {
      if (isDef) {
        return _safeDouble(d['definition_score'], 6.0);
      } else if (isFat) {
        return _safeDouble(d['body_fat'], 20.0);
      } else {
        return _safeDouble(d['weight'], 70.0);
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
        text: isDef
            ? val.toStringAsFixed(1)
            : (isFat ? '${val.toStringAsFixed(1)}%' : '${val.toStringAsFixed(1)} kg'),
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
