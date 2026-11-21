import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class TrainerAnnouncementsTab extends StatefulWidget {
  const TrainerAnnouncementsTab({super.key});

  @override
  State<TrainerAnnouncementsTab> createState() => _TrainerAnnouncementsTabState();
}

class _TrainerAnnouncementsTabState extends State<TrainerAnnouncementsTab> {
  final TextEditingController _announcementController = TextEditingController();
  bool _isLoading = true;
  bool _isPublishing = false;
  List<dynamic> _announcements = [];
  String _selectedTag = 'attendance_call'; // 'attendance_call', 'coach_absence', 'tip_advice'
  final Set<String> _expandedAnnouncements = {};

  String get _trainerCedula {
    final u = AuthService.instance.loggedInUser;
    if (u != null && u.cedula.isNotEmpty && u.cedula != 'Desconocido') {
      return u.cedula;
    }
    return '29977666';
  }

  final Map<String, Map<String, dynamic>> _tagConfigs = {
    'attendance_call': {
      'label': 'Convocatoria Gimnasio',
      'fullTitle': '🏋️ Convocatoria / Asistencia al Gimnasio',
      'icon': Icons.how_to_reg_rounded,
      'color': const Color(0xFF1FAE87),
      'bg': const Color(0xFF133E35),
      'placeholder': '¡Los espero hoy en el gimnasio para la sesión de entrenamiento! Por favor confirmen su asistencia puntual.',
    },
    'coach_absence': {
      'label': 'Inasistencia del Coach',
      'fullTitle': '🚫 Inasistencia del Entrenador (Rutina en Casa)',
      'icon': Icons.home_repair_service_rounded,
      'color': const Color(0xFFA855F7),
      'bg': const Color(0xFF381A54),
      'placeholder': 'Hoy no podré estar presencialmente en el gimnasio. He dejado planificada la rutina adaptada en casa para que no pierdan el progreso.',
    },
    'tip_advice': {
      'label': 'Consejo / Aviso',
      'fullTitle': '💡 Consejo Técnico o Comunicado General',
      'icon': Icons.tips_and_updates_rounded,
      'color': const Color(0xFF38BDF8),
      'bg': const Color(0xFF132F4C),
      'placeholder': 'Recordatorio importante: mantengan una correcta hidratación previa y cuiden la técnica y el control excéntrico en cada serie.',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _announcementController.dispose();
    super.dispose();
  }

  void _selectTag(String tagKey) {
    setState(() {
      _selectedTag = tagKey;
      // Si el campo está vacío o contiene la plantilla de otro tag, actualizar al nuevo placeholder
      final currentText = _announcementController.text.trim();
      final isTemplate = _tagConfigs.values.any((c) => c['placeholder'] == currentText);
      if (currentText.isEmpty || isTemplate) {
        _announcementController.text = _tagConfigs[tagKey]?['placeholder'] ?? '';
      }
    });
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/announcements/$_trainerCedula'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List && mounted) {
          setState(() {
            _announcements = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando anuncios: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _publishAnnouncement() async {
    final text = _announcementController.text.trim();
    if (text.isEmpty || _isPublishing) return;

    setState(() => _isPublishing = true);
    final baseUrl = AuthService.apiBaseUrl;

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/announcements'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': _trainerCedula,
          'message': text,
          'tag': _selectedTag,
        }),
      );

      if (res.statusCode == 200) {
        _announcementController.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _tagConfigs[_selectedTag]?['color'] ?? const Color(0xFF1FAE87),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('¡Anuncio publicado con etiqueta "${_tagConfigs[_selectedTag]?['label']}"!'),
                ),
              ],
            ),
          ),
        );
        await _loadAnnouncements();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error publicando anuncio: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.delete(Uri.parse('$baseUrl/api/trainer/announcements/$id'));
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1FAE87),
            content: Text('Anuncio eliminado.'),
          ),
        );
        await _loadAnnouncements();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando anuncio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF1FAE87),
        onRefresh: _loadAnnouncements,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Muro de Anuncios', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Comunica avisos oficiales y recibe feedback de tus alumnos.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF1FAE87)),
                    tooltip: 'Actualizar respuestas',
                    onPressed: _loadAnnouncements,
                  )
                ],
              ),
              const SizedBox(height: 16),

              // Composer Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Selecciona el motivo del anuncio:',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Selector de etiquetas / motivos
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tagConfigs.entries.map((entry) {
                        final key = entry.key;
                        final conf = entry.value;
                        final isSelected = _selectedTag == key;
                        final color = conf['color'] as Color;

                        return ChoiceChip(
                          avatar: Icon(
                            conf['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : color,
                          ),
                          label: Text(
                            conf['label'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: color,
                          backgroundColor: const Color(0xFF0F172A),
                          side: BorderSide(
                            color: isSelected ? color : Colors.white24,
                            width: isSelected ? 1.5 : 1,
                          ),
                          onSelected: (val) {
                            if (val) _selectTag(key);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      '2. Mensaje o detalles para los alumnos:',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (_tagConfigs[_selectedTag]?['color'] as Color).withOpacity(0.4)),
                      ),
                      child: TextField(
                        controller: _announcementController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _tagConfigs[_selectedTag]?['placeholder'] ?? 'Escribe tu anuncio aquí...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📢 Se notificará en tiempo real',
                          style: TextStyle(color: (_tagConfigs[_selectedTag]?['color'] as Color), fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isPublishing ? null : _publishAnnouncement,
                          icon: _isPublishing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                          label: const Text('Publicar Anuncio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tagConfigs[_selectedTag]?['color'] ?? const Color(0xFF1FAE87),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // List of announcements
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Historial y Feedback de Alumnos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${_announcements.length} publicados',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF1FAE87))))
              else if (_announcements.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.campaign_outlined, size: 40, color: Colors.white24),
                      SizedBox(height: 10),
                      Text('No has publicado ningún anuncio aún.', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              else
                ..._announcements.map((ann) {
                  final id = (ann['id'] ?? '').toString();
                  final msg = (ann['clean_message'] ?? ann['message'] ?? '').toString();
                  final tag = (ann['tag'] ?? 'tip_advice').toString();
                  final tagConf = _tagConfigs[tag] ?? _tagConfigs['tip_advice']!;
                  final tagColor = tagConf['color'] as Color;
                  final tagBg = tagConf['bg'] as Color;
                  final createdAt = ann['created_at'] as String? ?? '';

                  String timeLabel = 'Reciente';
                  if (createdAt.isNotEmpty) {
                    try {
                      final dt = DateTime.parse(createdAt).toLocal();
                      final hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                      final minStr = dt.minute.toString().padLeft(2, '0');
                      timeLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} · $hour12:$minStr $ampm';
                    } catch (_) {}
                  }

                  final summary = (ann['feedback_summary'] as Map<String, dynamic>?) ?? {};
                  final totalFeedback = summary['total'] as int? ?? 0;
                  final attending = (summary['attending'] as List<dynamic>?) ?? [];
                  final declined = (summary['declined'] as List<dynamic>?) ?? [];
                  final homeWorkouts = (summary['home_workouts'] as List<dynamic>?) ?? [];
                  final postponed = (summary['postponed'] as List<dynamic>?) ?? [];
                  final acknowledged = (summary['acknowledged'] as List<dynamic>?) ?? [];
                  final allFeedbacks = (summary['all'] as List<dynamic>?) ?? [];
                  final isExpanded = _expandedAnnouncements.contains(id);

                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: tagColor.withOpacity(0.5), width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con etiqueta y fecha
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: tagBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: tagColor.withOpacity(0.6)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(tagConf['icon'] as IconData, color: tagColor, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      tagConf['label'] as String,
                                      style: TextStyle(
                                        color: tagColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(timeLabel, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                                  if (id.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      tooltip: 'Eliminar anuncio',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _deleteAnnouncement(id),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Contenido del mensaje
                          Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                          const SizedBox(height: 14),

                          // Panel de Feedback de Alumnos
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF38BDF8)),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Feedback de Alumnos: $totalFeedback respuestas',
                                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    if (totalFeedback > 0)
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isExpanded) {
                                              _expandedAnnouncements.remove(id);
                                            } else {
                                              _expandedAnnouncements.add(id);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Row(
                                            children: [
                                              Text(
                                                isExpanded ? 'Ocultar' : 'Ver detalle',
                                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold),
                                              ),
                                              Icon(
                                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                color: const Color(0xFF38BDF8),
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Badges de desglose de respuestas
                                if (tag == 'attendance_call') ...[
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF133E35),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF1FAE87)),
                                        ),
                                        child: Text(
                                          '🙋‍♂️ ${attending.length} Asistirán al Gym',
                                          style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B1818),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.redAccent),
                                        ),
                                        child: Text(
                                          '❌ ${declined.length} No podrán asistir',
                                          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (tag == 'coach_absence') ...[
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF381A54),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFA855F7)),
                                        ),
                                        child: Text(
                                          '🏠 ${homeWorkouts.length} Harán rutina en casa',
                                          style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF232B3E),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.white30),
                                        ),
                                        child: Text(
                                          '⏭️ ${postponed.length} Posponen sesión',
                                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF132F4C),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF38BDF8)),
                                    ),
                                    child: Text(
                                      '👍 ${acknowledged.length} Alumnos confirmaron lectura',
                                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],

                                // Lista desplegable con detalles de cada alumno
                                if (isExpanded && allFeedbacks.isNotEmpty) ...[
                                  const Divider(color: Colors.white12, height: 16),
                                  const Text(
                                    'Respuestas individuales recibidas:',
                                    style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  ...allFeedbacks.map((fb) {
                                    final name = fb['client_name'] ?? 'Alumno';
                                    final type = fb['type'] ?? '';
                                    final reason = fb['reason'] ?? '';
                                    final fbTime = fb['created_at']?.toString() ?? '';
                                    String shortTime = '';
                                    if (fbTime.length >= 16) {
                                      try {
                                        final dt = DateTime.parse(fbTime).toLocal();
                                        final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                                        final ap = dt.hour >= 12 ? 'PM' : 'AM';
                                        shortTime = '$h:${dt.minute.toString().padLeft(2, '0')} $ap';
                                      } catch (_) {}
                                    }

                                    IconData fbIcon = Icons.check_circle_outline;
                                    Color fbColor = const Color(0xFF1FAE87);
                                    String fbLabel = 'Respondió';

                                    if (type == 'attendance_confirmed') {
                                      fbIcon = Icons.check_circle_rounded;
                                      fbColor = const Color(0xFF1FAE87);
                                      fbLabel = 'Confirmó que asistirá puntual al gimnasio';
                                    } else if (type == 'attendance_declined') {
                                      fbIcon = Icons.cancel_rounded;
                                      fbColor = Colors.redAccent;
                                      fbLabel = 'No podrá asistir hoy ${reason.isNotEmpty ? "• Motivo: $reason" : ""}';
                                    } else if (type == 'home_workout') {
                                      fbIcon = Icons.home_rounded;
                                      fbColor = const Color(0xFFA855F7);
                                      fbLabel = 'Activó rutina adaptada en casa';
                                    } else if (type == 'postponed') {
                                      fbIcon = Icons.pause_circle_filled_rounded;
                                      fbColor = Colors.amberAccent;
                                      fbLabel = 'Tomará descanso y pospone para mañana';
                                    } else if (type == 'acknowledged') {
                                      fbIcon = Icons.thumb_up_rounded;
                                      fbColor = const Color(0xFF38BDF8);
                                      fbLabel = 'Confirmó lectura y comprensión del aviso';
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(fbIcon, size: 15, color: fbColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                                children: [
                                                  TextSpan(
                                                    text: '$name: ',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                  TextSpan(
                                                    text: fbLabel,
                                                    style: TextStyle(color: fbColor),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (shortTime.isNotEmpty)
                                            Text(
                                              shortTime,
                                              style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ] else if (totalFeedback == 0) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    '⏳ Aún no hay respuestas de los alumnos a este aviso.',
                                    style: TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
