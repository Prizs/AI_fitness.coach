import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/chat_notification_service.dart';
import 'package:mobile_app/services/daily_notification_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';

class ClientTrainerTab extends StatefulWidget {
  const ClientTrainerTab({super.key});

  @override
  State<ClientTrainerTab> createState() => _ClientTrainerTabState();
}

class _ClientTrainerTabState extends State<ClientTrainerTab> {
  bool _isLoading = true;
  bool _hasTrainer = false;
  Map<String, dynamic>? _trainerInfo;
  List<dynamic> _availableTrainers = [];
  List<dynamic> _messages = [];
  List<dynamic> _trainerAnnouncements = [];
  Timer? _pollTimer;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  // Hub Sub-Tabs: 0 = Chat, 1 = Horarios, 2 = Avisos, 3 = Otros Coaches
  int _activeHubTab = 0;
  Map<String, dynamic>? _pendingSession;
  List<dynamic> _agendaBlocks = [];
  bool _isLoadingAgenda = false;

  final Set<String> _confirmedAnnouncements = {};
  final Map<String, String> _declinedAnnouncements = {};
  final Set<String> _postponedAnnouncements = {};
  final DailyNotificationService _notifService = DailyNotificationService.instance;

  @override
  void initState() {
    super.initState();
    _loadTrainerStatus();
  }

  @override
  void dispose() {
    ChatNotificationService.instance.clearAllActiveChats();
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _myCedula => AuthService.instance.loggedInUser?.cedula ?? '';

  Future<void> _loadTrainerStatus() async {
    setState(() => _isLoading = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/my-trainer/$_myCedula'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data['assigned'] == true && data['trainer'] != null) {
          setState(() {
            _hasTrainer = true;
            _trainerInfo = data['trainer'];
          });

          // Registrar chat activo con el coach si está en la pestaña de chat
          if (_activeHubTab == 0) {
            _registerActiveChatWithCoach();
          }

          await _loadChatMessages();
          await _loadTrainerAnnouncements();
          await _loadPendingSession();
          await _loadAgendaSlots();
          await _loadAvailableTrainers();
          _startPolling();
        } else {
          _pollTimer?.cancel();
          ChatNotificationService.instance.clearAllActiveChats();
          setState(() {
            _hasTrainer = false;
            _trainerInfo = null;
          });
          await _loadAvailableTrainers();
        }
      } else {
        await _loadAvailableTrainers();
      }
    } catch (e) {
      debugPrint('Error cargando estado de entrenador: $e');
      await _loadAvailableTrainers();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _registerActiveChatWithCoach() {
    if (_trainerInfo == null) return;
    final trainerId = (_trainerInfo!['id'] ?? _trainerInfo!['cedula'] ?? '').toString();
    final trainerName = _trainerInfo!['name'] ?? '${_trainerInfo!['nombre'] ?? ''} ${_trainerInfo!['apellido'] ?? ''}'.trim();
    ChatNotificationService.instance.pushActiveChat(
      userId: trainerId,
      userCedula: _trainerInfo!['cedula']?.toString(),
      userName: trainerName,
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _loadChatMessagesSilently();
    });
  }

  Future<void> _loadPendingSession() async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/client-pending-session/$_myCedula'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is Map && data['has_session'] == true && mounted) {
          setState(() {
            _pendingSession = data['session'];
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _pendingSession = null);
  }

  Future<void> _loadAgendaSlots() async {
    if (_trainerInfo == null) return;
    setState(() => _isLoadingAgenda = true);
    final baseUrl = AuthService.apiBaseUrl;
    final trainerId = _trainerInfo!['id'] ?? _trainerInfo!['cedula'];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/agenda/$trainerId?target_date=$today'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is Map && mounted) {
          setState(() {
            _agendaBlocks = data['blocks'] ?? [];
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingAgenda = false);
    }
  }

  Future<void> _loadTrainerAnnouncements() async {
    if (_trainerInfo == null) return;
    final baseUrl = AuthService.apiBaseUrl;
    final trainerId = _trainerInfo!['id'] ?? _trainerInfo!['cedula'];
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/announcements/$trainerId'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List && mounted) {
          setState(() {
            _trainerAnnouncements = list;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadChatMessagesSilently() async {
    if (_trainerInfo == null) return;
    final baseUrl = AuthService.apiBaseUrl;
    final trainerId = _trainerInfo!['id'] ?? _trainerInfo!['cedula'];
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/messages/$trainerId/$_myCedula'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List && mounted && list.length != _messages.length) {
          setState(() {
            _messages = list;
          });
          _scrollToBottom();
          // Actualizar sesión pendiente por si el coach propuso una nueva
          _loadPendingSession();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadChatMessages() async {
    if (_trainerInfo == null) return;
    final baseUrl = AuthService.apiBaseUrl;
    final trainerId = _trainerInfo!['id'] ?? _trainerInfo!['cedula'];
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/messages/$trainerId/$_myCedula'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List && mounted) {
          setState(() {
            _messages = list;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error cargando mensajes: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadAvailableTrainers() async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/trainers'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List && mounted) {
          setState(() {
            _availableTrainers = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando entrenadores disponibles: $e');
    }
  }

  Future<void> _assignTrainer(Map<String, dynamic> trainer) async {
    final baseUrl = AuthService.apiBaseUrl;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/assign'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': _myCedula,
          'trainer_id': trainer['id'] ?? trainer['cedula'],
        }),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1FAE87),
            content: Text('¡Entrenador ${trainer['nombre']} asignado con éxito!'),
          ),
        );
        setState(() => _activeHubTab = 0);
        await _loadTrainerStatus();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo asignar el entrenador.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con el servidor: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _trainerInfo == null || _isSending) return;

    _msgController.clear();
    setState(() => _isSending = true);

    final baseUrl = AuthService.apiBaseUrl;
    final trainerId = _trainerInfo!['id'] ?? _trainerInfo!['cedula'];

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': trainerId,
          'client_id': _myCedula,
          'sender_id': _myCedula,
          'message': text,
        }),
      );
      if (res.statusCode == 200) {
        await _loadChatMessages();
      }
    } catch (e) {
      debugPrint('Error enviando mensaje: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendQuickResponseToTrainer(String text, {String? successNotification}) async {
    if (_trainerInfo == null) return;
    final baseUrl = AuthService.apiBaseUrl;
    final trainerId = _trainerInfo!['id'] ?? _trainerInfo!['cedula'];

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': trainerId,
          'client_id': _myCedula,
          'sender_id': _myCedula,
          'message': text,
        }),
      );
      if (res.statusCode == 200) {
        await _loadChatMessages();
        if (mounted && successNotification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1FAE87),
              content: Text(successNotification),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error enviando respuesta al coach: $e');
    }
  }

  Future<void> _sendAnnouncementFeedback({
    required String announcementId,
    required String responseType,
    String? reason,
    String? successNotification,
  }) async {
    if (_trainerInfo == null) return;
    final baseUrl = AuthService.apiBaseUrl;
    final trainerId = _trainerInfo!['id'] ?? _trainerInfo!['cedula'];
    final user = AuthService.instance.loggedInUser;
    final clientName = '${user?.name ?? ""} ${user?.lastName ?? ""}'.trim();

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/announcements/respond'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'announcement_id': announcementId,
          'trainer_id': trainerId,
          'client_id': _myCedula,
          'response_type': responseType,
          'reason': reason ?? '',
          'client_name': clientName.isNotEmpty ? clientName : 'Alumno',
        }),
      );
      if (res.statusCode == 200) {
        await _loadChatMessages();
        if (mounted && successNotification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1FAE87),
              content: Text(successNotification),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error enviando feedback de anuncio: $e');
    }
  }

  void _showDeclineAttendanceSheet(String announcementId) {
    String selectedReason = '💼 Motivos laborales / trabajo';
    final customCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final reasons = [
            '💼 Motivos laborales / trabajo',
            '🚗 Problemas de transporte o tiempo',
            '🤒 Malestar físico / fatiga muscular',
            '🌧️ Imprevisto personal de fuerza mayor',
            '✏️ Otro motivo personal',
          ];

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: const [
                    Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Aviso de Inasistencia al Gimnasio',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Indica el motivo para que tu entrenador lo verifique y planifique el seguimiento de tus cargas:',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 14),
                ...reasons.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: selectedReason == r ? const Color(0xFF3B1818) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selectedReason == r ? Colors.redAccent : Colors.white10),
                  ),
                  child: RadioListTile<String>(
                    dense: true,
                    title: Text(
                      r,
                      style: TextStyle(
                        color: selectedReason == r ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: selectedReason == r ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    value: r,
                    groupValue: selectedReason,
                    activeColor: Colors.redAccent,
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedReason = val);
                    },
                  ),
                )),
                if (selectedReason.contains('Otro')) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: customCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Describe brevemente el motivo...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF16233A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white60,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final finalReason = selectedReason.contains('Otro') && customCtrl.text.trim().isNotEmpty
                              ? customCtrl.text.trim()
                              : selectedReason;
                          Navigator.pop(ctx);
                          setState(() {
                            _declinedAnnouncements[announcementId] = finalReason;
                          });
                          _sendAnnouncementFeedback(
                            announcementId: announcementId,
                            responseType: 'attendance_declined',
                            reason: finalReason,
                            successNotification: '❌ Aviso enviado al Coach: No asistirás hoy ($finalReason)',
                          );
                        },
                        child: const Text('Confirmar Aviso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSession(String sessionId, String startTime) async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/session-response'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'client_id': _myCedula,
          'action': 'accept',
        }),
      );
      if (res.statusCode == 200) {
        // Actualizar bloque diario automáticamente a la hora confirmada
        try {
          final parts = startTime.split(':');
          if (parts.length >= 2) {
            final h = int.tryParse(parts[0]) ?? 8;
            final m = int.tryParse(parts[1]) ?? 0;
            await _notifService.setWorkoutBlockTime(TimeOfDay(hour: h, minute: m));
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1FAE87),
              content: Text('✅ ¡Sesión confirmada para las $startTime hrs! Tu bloque de entrenamiento y avisos fueron actualizados.'),
            ),
          );
        }
        await _loadPendingSession();
        await _loadChatMessages();
        await _loadAgendaSlots();
      }
    } catch (e) {
      debugPrint('Error confirmando sesión: $e');
    }
  }

  void _showRejectOrCounterModal(Map<String, dynamic> session) {
    final sessionId = session['id']?.toString() ?? '';
    final sessionStartTime = (session['start_time']?.toString() ?? '').split(':').take(2).join(':');

    // 1. Obtener la lista de bloques de trabajo reales del entrenador
    final List<Map<String, String>> blockOptions = [];

    if (_agendaBlocks.isNotEmpty) {
      for (final b in _agendaBlocks) {
        final rawSt = b['start_time']?.toString() ?? '';
        final rawEt = b['end_time']?.toString() ?? '';
        final st = rawSt.length >= 5 ? rawSt.substring(0, 5) : rawSt;
        final et = rawEt.length >= 5 ? rawEt.substring(0, 5) : rawEt;
        if (st.isNotEmpty && st != sessionStartTime) {
          blockOptions.add({
            'time': st,
            'label': '$st - $et',
          });
        }
      }
    }

    // 2. Si no hay bloques cargados en memoria, usar los bloques estándar oficiales:
    // 2 horas de sesión + 30 minutos de descanso entre bloques
    if (blockOptions.isEmpty) {
      final defaultStandard = [
        {'time': '08:00', 'label': '08:00 - 10:00'},
        {'time': '10:30', 'label': '10:30 - 12:30'},
        {'time': '13:00', 'label': '13:00 - 15:00'},
        {'time': '15:30', 'label': '15:30 - 17:30'},
        {'time': '18:00', 'label': '18:00 - 20:00'},
        {'time': '20:30', 'label': '20:30 - 22:30'},
      ];
      for (final d in defaultStandard) {
        if (d['time'] != sessionStartTime) {
          blockOptions.add(d);
        }
      }
    }

    String selectedTime = blockOptions.isNotEmpty ? blockOptions.first['time']! : '10:30';
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Proponer otro Horario al Coach', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No puedes asistir de ${session['start_time']} a ${session['end_time']}. Selecciona el bloque del entrenador que prefieres:',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bloques de atención (2h de sesión con 30 min de descanso):',
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: blockOptions.map((opt) {
                      final h = opt['time']!;
                      final lbl = opt['label']!;
                      final isSel = selectedTime == h;
                      return ChoiceChip(
                        label: Text(lbl, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        selected: isSel,
                        selectedColor: const Color(0xFF38BDF8),
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSel ? const Color(0xFF38BDF8) : Colors.white24),
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedTime = h);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nota para el coach (opcional)',
                      labelStyle: TextStyle(color: Colors.white60),
                      hintText: 'Ej: Salgo tarde del trabajo hoy',
                      hintStyle: TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFA855F7),
                            side: const BorderSide(color: Color(0xFFA855F7)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(modalCtx);
                            _showHomeWorkoutDialog();
                          },
                          child: const Text('Entrenar en casa', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            Navigator.pop(modalCtx);
                            await _sendCounterProposal(sessionId, selectedTime, noteController.text.trim());
                          },
                          child: const Text('Enviar Propuesta', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendCounterProposal(String sessionId, String counterTime, String note) async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/session-response'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'client_id': _myCedula,
          'action': 'counter',
          'counter_time': counterTime,
          'counter_note': note,
        }),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF38BDF8),
              content: Text('🔄 Propuesta de horario ($counterTime hrs) enviada a tu coach.'),
            ),
          );
        }
        await _loadPendingSession();
        await _loadChatMessages();
        await _loadAgendaSlots();
      }
    } catch (e) {
      debugPrint('Error enviando contrapropuesta: $e');
    }
  }

  Future<void> _showHomeWorkoutDialog() async {
    final shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F192B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.home_rounded, color: Color(0xFFA855F7)),
            SizedBox(width: 8),
            Text('Entrenamiento en Casa', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          '¿Quieres que te asignemos una rutina adaptada para el día de hoy en casa?\n\n'
          'Sustituimos máquinas de gimnasio por ejercicios validados de peso corporal / calistenia con la misma intensidad y grupo muscular.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('¡Sí, asignar en casa!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldSwitch != true) return;

    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/assign-home-workout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': _myCedula,
          'intensity': 'Media',
        }),
      );

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        final title = data['routine_title'] ?? 'Entrenamiento en Casa';
        final exercises = data['exercises'] as List<dynamic>? ?? [];

        await WeeklyPlanService.instance.substituteTodayWithHomeWorkout(title: title, exercises: exercises);

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFA855F7),
              content: Text('🏠 ¡Rutina de casa activada! $title (${exercises.length} ejercicios).'),
              duration: const Duration(seconds: 3),
            ),
          );
          _showHomeWorkoutDetailsSheet(title: title, exercises: exercises);
        }
        await _loadPendingSession();
        await _loadAgendaSlots();
      }
    } catch (e) {
      debugPrint('Error asignando rutina en casa: $e');
    }
  }

  void _showHomeWorkoutDetailsSheet({String? title, List<dynamic>? exercises}) {
    final today = WeeklyPlanService.instance.today;
    final rTitle = title ?? today?['title'] ?? 'Entrenamiento en Casa';
    final exList = exercises ?? (today?['exercises'] as List<dynamic>? ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home_rounded, color: Color(0xFFA855F7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rutina Sustituta en Casa Activa',
                          style: TextStyle(color: Color(0xFFA855F7), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          rTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16233A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF8BE0C0), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Los ejercicios fueron adaptados para ejecutarse con peso corporal y calistenia sin requerir máquinas de gimnasio.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ejercicios Asignados para Hoy:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              if (exList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No hay ejercicios registrados.', style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                ...exList.map((ex) {
                  final eMap = ex is Map ? ex : {};
                  final name = eMap['name'] ?? 'Ejercicio';
                  final sets = eMap['sets']?.toString() ?? '3';
                  final reps = eMap['reps']?.toString() ?? '12';
                  final prime = eMap['primary_muscle'] ?? '';
                  final bio = eMap['biomechanics'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$sets series × $reps',
                                style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (prime.toString().isNotEmpty)
                              Text(
                                prime.toString(),
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (bio.toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            bio.toString(),
                            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FAE87),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.fitness_center_rounded, color: Colors.white),
                label: const Text(
                  'Ir a la pestaña de Rutinas para Entrenar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  WeeklyPlanService.instance.notifyUpdate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('👉 Toca "Rutinas" en la barra inferior para ver y marcar tu sesión de casa.'),
                      backgroundColor: Color(0xFF1FAE87),
                      duration: Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido, cerrar', style: TextStyle(color: Colors.white60)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _bookSession(String st, String et) async {
    final baseUrl = AuthService.apiBaseUrl;
    final trainerId = _trainerInfo!['id'] ?? _trainerInfo!['cedula'];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/agenda/book'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': trainerId,
          'client_id': _myCedula,
          'schedule_date': today,
          'start_time': st,
          'end_time': et,
          'booked_by': 'client',
        }),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1FAE87),
            content: Text('¡Sesión reservada exitosamente para las $st - $et hrs!'),
          ),
        );
        await _loadPendingSession();
        await _loadAgendaSlots();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reservando sesión: $e')),
      );
    }
  }

  void _showTrainerProfileModal() {
    if (_trainerInfo == null) return;
    final name = _trainerInfo!['name'] ?? '${_trainerInfo!['nombre'] ?? ''} ${_trainerInfo!['apellido'] ?? ''}'.trim();
    final specialty = _trainerInfo!['specialty'] ?? 'Hipertrofia, Fuerza y Biomecánica';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Perfil del Entrenador', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF1FAE87),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                  style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1FAE87).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.4)),
                ),
                child: const Text('🟢 En línea · Coach Oficial Verificado', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF1FAE87), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Especialidad: $specialty', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      children: const [
                        Icon(Icons.access_time_rounded, color: Color(0xFF38BDF8), size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text('Horarios de Atención: Lunes a Sábado de 07:00 a 20:00 hrs', style: TextStyle(color: Colors.white70, fontSize: 12.5))),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      children: const [
                        Icon(Icons.star, color: Colors.amberAccent, size: 18),
                        SizedBox(width: 8),
                        Text('⭐ 4.9 / 5.0 (Valoraciones de alumnos en el gimnasio)', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: const Text('Ver otros coaches', style: TextStyle(fontSize: 12.5)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _activeHubTab = 3;
                          ChatNotificationService.instance.clearAllActiveChats();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1FAE87),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('Ver Horarios', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _activeHubTab = 1;
                          ChatNotificationService.instance.clearAllActiveChats();
                        });
                        _loadAgendaSlots();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87)));
    }
    if (_hasTrainer && _trainerInfo != null) {
      return _buildActiveCoachHub();
    }
    return _buildSearchState();
  }

  Widget _buildActiveCoachHub() {
    final trainerName = _trainerInfo!['name'] ?? '${_trainerInfo!['nombre'] ?? ''} ${_trainerInfo!['apellido'] ?? ''}'.trim();

    return SafeArea(
      child: Column(
        children: [
          // Header Interactivo: Tocar abre el perfil del coach
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F192B),
            child: Row(
              children: [
                InkWell(
                  onTap: _showTrainerProfileModal,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF1FAE87),
                        radius: 18,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Coach: $trainerName',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.info_outline, size: 14, color: Colors.white60),
                            ],
                          ),
                          const Text('En línea · Toca para ver perfil', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  onPressed: () async {
                    await _loadTrainerStatus();
                    await _loadPendingSession();
                    await _loadAgendaSlots();
                  },
                ),
              ],
            ),
          ),

          // Sub-Barra de Navegación del Hub de Coach (4 Módulos)
          Container(
            color: const Color(0xFF141F32),
            child: Row(
              children: [
                _buildHubTabItem(0, 'Chat', Icons.chat_bubble_outline),
                _buildHubTabItem(1, 'Horarios', Icons.calendar_today_outlined),
                _buildHubTabItem(2, 'Avisos (${_trainerAnnouncements.length})', Icons.campaign_outlined),
                _buildHubTabItem(3, 'Otros Coaches', Icons.people_outline),
              ],
            ),
          ),

          // Contenido según sub-tab seleccionado
          Expanded(
            child: _buildHubContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTabItem(int index, String label, IconData icon) {
    final bool isSel = _activeHubTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeHubTab = index;
            if (index == 0) {
              _registerActiveChatWithCoach();
            } else {
              ChatNotificationService.instance.clearAllActiveChats();
            }
          });
          if (index == 1) _loadAgendaSlots();
          if (index == 2) _loadTrainerAnnouncements();
          if (index == 3) _loadAvailableTrainers();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSel ? const Color(0xFF1FAE87) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSel ? const Color(0xFF1FAE87) : Colors.white54),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSel ? const Color(0xFF1FAE87) : Colors.white60,
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubContent() {
    switch (_activeHubTab) {
      case 1:
        return _buildHorariosView();
      case 2:
        return _buildAvisosView();
      case 3:
        return _buildOtrosCoachesView();
      case 0:
      default:
        return _buildChatView();
    }
  }

  // Vista 0: Chat Directo
  Widget _buildChatView() {
    final trainerName = _trainerInfo!['name'] ?? '${_trainerInfo!['nombre'] ?? ''} ${_trainerInfo!['apellido'] ?? ''}'.trim();

    return Column(
      children: [
        // Tarjeta interactiva de invitación si hay sesión pendiente
        _buildSessionProposalCard(),

        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Colors.white38, size: 48),
                        const SizedBox(height: 12),
                        Text('Inicia una conversación con tu Coach $trainerName.', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                        const SizedBox(height: 6),
                        const Text('Pregúntale sobre tus horarios, dudas de técnica o reporta cómo te sientes.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    final bool isFromTrainer = m['is_from_trainer'] == true || m['sender_role'] == 'trainer';
                    final bool isMe = !isFromTrainer;
                    final String senderLabel = isMe ? 'Tú' : (m['sender_name'] != null && (m['sender_name'] as String).isNotEmpty ? m['sender_name'] : 'Coach $trainerName');
                    return _chatBubble(m['message'] ?? '', isMe, m['created_at'], senderLabel);
                  },
                ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF0F192B),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escribe a tu coach...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF1FAE87),
                child: _isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _sendMessage),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Vista 1: Horarios y Agenda en Vivo
  Widget _buildHorariosView() {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    return RefreshIndicator(
      color: const Color(0xFF1FAE87),
      onRefresh: () async {
        await _loadAgendaSlots();
        await _loadPendingSession();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Disponibilidad de Horarios', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Horarios en vivo para hoy ($today):', style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA855F7),
                  side: const BorderSide(color: Color(0xFFA855F7)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.home_rounded, size: 16),
                label: const Text('En casa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _showHomeWorkoutDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoadingAgenda)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF1FAE87))))
          else if (_agendaBlocks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 40, color: Colors.white24),
                    const SizedBox(height: 12),
                    const Text('El entrenador no tiene horarios configurados para hoy.', style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FAE87)),
                      onPressed: _loadAgendaSlots,
                      child: const Text('Volver a consultar'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._agendaBlocks.map((b) {
              final timeLabel = b['time'] ?? 'Horario';
              final capacityText = b['capacity'] ?? '';
              final isFull = b['is_full'] == true;
              final students = (b['students'] as List<dynamic>?) ?? [];
              final bool alreadyBooked = students.any((s) => s['client_id'] == _myCedula || s['cedula'] == _myCedula);

              String? status;
              String? sessionId;
              if (alreadyBooked) {
                final mySession = students.firstWhere((s) => s['client_id'] == _myCedula || s['cedula'] == _myCedula, orElse: () => {});
                status = mySession['status']?.toString();
                sessionId = mySession['id']?.toString() ?? _pendingSession?['id']?.toString();
              }

              final bool isPending = status == 'pending_confirmation' || (_pendingSession != null && _pendingSession!['status'] == 'pending_confirmation' && _pendingSession!['start_time'] == b['start_time']?.toString().substring(0, 5));

              return Card(
                color: isPending
                    ? Colors.amberAccent.withOpacity(0.08)
                    : (alreadyBooked ? const Color(0xFF173B45) : const Color(0xFF1E293B)),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isPending
                        ? Colors.amberAccent
                        : (alreadyBooked ? const Color(0xFF1FAE87) : Colors.white10),
                    width: isPending || alreadyBooked ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_filled,
                                color: isPending ? Colors.amberAccent : (alreadyBooked ? Colors.greenAccent : (isFull ? Colors.redAccent : const Color(0xFF1FAE87))),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(timeLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPending ? Colors.amberAccent.withOpacity(0.2) : (alreadyBooked ? Colors.greenAccent.withOpacity(0.2) : Colors.white10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPending
                                  ? '⏳ Asignado (Pendiente)'
                                  : (alreadyBooked ? '🟢 Tu Cupo Reservado' : capacityText),
                              style: TextStyle(
                                color: isPending ? Colors.amberAccent : (alreadyBooked ? Colors.greenAccent : (isFull ? Colors.redAccent : Colors.white70)),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Tu entrenador te propuso asistir en este horario. ¿Podrás asistir?',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1FAE87),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Confirmar Asistencia', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _confirmSession(sessionId ?? '', b['start_time']?.toString().substring(0, 5) ?? '08:00'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF38BDF8),
                                  side: const BorderSide(color: Color(0xFF38BDF8)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Proponer otra hora', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _showRejectOrCounterModal({
                                  'id': sessionId,
                                  'start_time': b['start_time']?.toString().substring(0, 5) ?? '08:00',
                                  'end_time': b['end_time']?.toString().substring(0, 5) ?? '10:00',
                                }),
                              ),
                            ),
                          ],
                        ),
                      ] else if (!alreadyBooked) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFull ? Colors.white24 : const Color(0xFF1FAE87),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: isFull
                                ? null
                                : () => _bookSession(b['start_time'], b['end_time']),
                            child: Text(
                              isFull ? 'Horario Lleno' : 'Reservar este Horario',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // Vista 2: Avisos y Anuncios del Entrenador
  Widget _buildAvisosView() {
    final trainerName = _trainerInfo!['name'] ?? '${_trainerInfo!['nombre'] ?? ''} ${_trainerInfo!['apellido'] ?? ''}'.trim();

    return RefreshIndicator(
      color: const Color(0xFF1FAE87),
      onRefresh: _loadTrainerAnnouncements,
      child: _trainerAnnouncements.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.campaign_outlined, size: 54, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text('Coach $trainerName aún no ha publicado anuncios.', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text('Aquí aparecerán comunicados importantes del gimnasio, cambios de horario y tips técnicos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trainerAnnouncements.length,
              itemBuilder: (context, index) {
                final a = _trainerAnnouncements[index];
                String dateStr = 'Aviso';
                final rawCreated = a['created_at'];
                if (rawCreated != null && rawCreated.toString().isNotEmpty) {
                  try {
                    final dt = DateTime.parse(rawCreated.toString()).toLocal();
                    final dayStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                    final hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                    final minStr = dt.minute.toString().padLeft(2, '0');
                    dateStr = '$dayStr · $hour12:$minStr $ampm';
                  } catch (_) {
                    final s = rawCreated.toString();
                    dateStr = s.length >= 10 ? s.substring(0, 10) : s;
                  }
                }

                final rawMsg = (a['message'] ?? a['content'] ?? '').toString();
                String msg = rawMsg;
                String tag = (a['tag'] ?? '').toString();

                if (rawMsg.startsWith('[TAG:') && rawMsg.contains(']')) {
                  final parts = rawMsg.split(']');
                  tag = parts[0].replaceAll('[TAG:', '').trim();
                  msg = parts.sublist(1).join(']').trim();
                } else if (rawMsg.startsWith('[MOTIVO:') && rawMsg.contains(']')) {
                  final parts = rawMsg.split(']');
                  tag = parts[0].replaceAll('[MOTIVO:', '').trim();
                  msg = parts.sublist(1).join(']').trim();
                }

                final msgLower = msg.toLowerCase();
                final announcementId = (a['id'] ?? index).toString();

                // 1. Condicional: Ausencia del entrenador o propuesta de rutina en casa
                final isCoachAbsence = tag == 'coach_absence' || (tag.isEmpty && (
                    msgLower.contains('casa') ||
                    msgLower.contains('no podre') ||
                    msgLower.contains('no podré') ||
                    msgLower.contains('no voy a poder') ||
                    msgLower.contains('no asistire') ||
                    msgLower.contains('no asistiré') ||
                    msgLower.contains('entreno en casa')
                ));

                // 2. Condicional: Convocatoria para confirmar asistencia presencial u horario
                final isAttendanceCall = tag == 'attendance_call' || (tag.isEmpty && !isCoachAbsence && (
                    msgLower.contains('confirmar') ||
                    msgLower.contains('confirmen') ||
                    msgLower.contains('asistencia') ||
                    msgLower.contains('quiénes asisten') ||
                    msgLower.contains('quienes asisten') ||
                    msgLower.contains('quién va') ||
                    msgLower.contains('quien va') ||
                    msgLower.contains('cupo') ||
                    msgLower.contains('horario')
                ));

                final isGeneralInfo = !isCoachAbsence && !isAttendanceCall;

                String tagTitle = 'Comunicado Oficial';
                Color tagColor = const Color(0xFF38BDF8);
                IconData tagIcon = Icons.campaign_rounded;

                if (isCoachAbsence) {
                  tagTitle = 'Inasistencia del Coach (Rutina Casa)';
                  tagColor = const Color(0xFFA855F7);
                  tagIcon = Icons.home_repair_service_rounded;
                } else if (isAttendanceCall) {
                  tagTitle = 'Convocatoria Asistencia al Gym';
                  tagColor = const Color(0xFF1FAE87);
                  tagIcon = Icons.how_to_reg_rounded;
                }

                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: tagColor.withOpacity(0.6),
                      width: 1.3,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  tagIcon,
                                  color: tagColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tagTitle,
                                  style: TextStyle(
                                    color: tagColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: Colors.white38),
                                const SizedBox(width: 4),
                                Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          msg,
                          style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
                        ),

                        // CONDICIONAL 1: El coach no podrá asistir / Propuesta de casa o descanso
                        if (isCoachAbsence) ...[
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final isPostponed = _postponedAnnouncements.contains(announcementId);
                              final isHomeActive = WeeklyPlanService.instance.isTodayHomeWorkout;

                              if (isPostponed) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.amberAccent.withOpacity(0.6)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.pause_circle_filled_rounded, color: Colors.amberAccent, size: 18),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          '⏸️ Has pospuesto la sesión para mañana (Coach informado)',
                                          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                        onPressed: _showHomeWorkoutDialog,
                                        child: const Text('Hacer en casa', style: TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (isHomeActive) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1FAE87),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 2,
                                      ),
                                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      label: const Text(
                                        '✅ Entrenamiento en Casa Activo (Hoy) · Ver Ejercicios',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                      onPressed: () => _showHomeWorkoutDetailsSheet(),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.replay_rounded, size: 14, color: Color(0xFFA855F7)),
                                          label: const Text(
                                            'Reasignar ejercicios de casa',
                                            style: TextStyle(color: Color(0xFFA855F7), fontSize: 11.5, fontWeight: FontWeight.w600),
                                          ),
                                          onPressed: _showHomeWorkoutDialog,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFA855F7),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                                    label: const Text('🏠 Sí, haré la rutina en casa hoy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    onPressed: () {
                                      _sendAnnouncementFeedback(
                                        announcementId: announcementId,
                                        responseType: 'home_workout',
                                        successNotification: '🏠 ¡Rutina en casa activada y notificada a tu coach!',
                                      );
                                      _showHomeWorkoutDialog();
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: const BorderSide(color: Colors.white24),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.pause_circle_outline_rounded, size: 16, color: Colors.amberAccent),
                                    label: const Text(
                                      '⏭️ Posponer al día siguiente / Descanso',
                                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: () {
                                      setState(() => _postponedAnnouncements.add(announcementId));
                                      _sendAnnouncementFeedback(
                                        announcementId: announcementId,
                                        responseType: 'postponed',
                                        successNotification: '⏭️ Has pospuesto la sesión para mañana. Descanso registrado.',
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],

                        // CONDICIONAL 2: Convocatoria para confirmar asistencia presencial
                        if (isAttendanceCall) ...[
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final hasConfirmed = _confirmedAnnouncements.contains(announcementId);
                              final declinedReason = _declinedAnnouncements[announcementId];

                              if (hasConfirmed) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1FAE87).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF1FAE87), width: 1.2),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF1FAE87), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        '✅ ¡Asistencia confirmada para hoy! (Enviado al Coach)',
                                        style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (declinedReason != null) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '❌ Avisaste que no asistirás ($declinedReason)',
                                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                        icon: const Icon(Icons.home_outlined, size: 14, color: Color(0xFFA855F7)),
                                        label: const Text('¿Hacer rutina alternativa en casa hoy?', style: TextStyle(color: Color(0xFFA855F7), fontSize: 11.5, fontWeight: FontWeight.bold)),
                                        onPressed: _showHomeWorkoutDialog,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1FAE87),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                      label: const Text(
                                        '🙋‍♂️ Sí, allí estaré',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                      ),
                                      onPressed: () {
                                        setState(() => _confirmedAnnouncements.add(announcementId));
                                        _sendAnnouncementFeedback(
                                          announcementId: announcementId,
                                          responseType: 'attendance_confirmed',
                                          successNotification: '✅ ¡Asistencia confirmada enviada a tu Coach!',
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 5,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.cancel_outlined, size: 16),
                                      label: const Text(
                                        '❌ No podré',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      onPressed: () => _showDeclineAttendanceSheet(announcementId),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],

                        // CONDICIONAL 3: Comunicado general o informativo
                        if (isGeneralInfo) ...[
                          const SizedBox(height: 10),
                          Builder(
                            builder: (context) {
                              final hasAcknowledged = _confirmedAnnouncements.contains(announcementId);
                              if (hasAcknowledged) {
                                return const Row(
                                  children: [
                                    Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF1FAE87)),
                                    SizedBox(width: 4),
                                    Text('✓ Leído y confirmado', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  ActionChip(
                                    backgroundColor: const Color(0xFF0F1E2E),
                                    side: const BorderSide(color: Color(0xFF8BE0C0), width: 1),
                                    avatar: const Icon(Icons.thumb_up_alt_rounded, size: 14, color: Color(0xFF8BE0C0)),
                                    label: const Text('👍 ¡Entendido, gracias Coach!', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      setState(() => _confirmedAnnouncements.add(announcementId));
                                      _sendAnnouncementFeedback(
                                        announcementId: announcementId,
                                        responseType: 'acknowledged',
                                        successNotification: '✓ Confirmación de lectura enviada al Coach',
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white54),
                                    label: const Text('Abrir chat', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                    onPressed: () {
                                      setState(() => _activeHubTab = 0);
                                      _registerActiveChatWithCoach();
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.person_pin, size: 14, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text('Publicado por Coach $trainerName', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
              },
            ),
    );
  }

  // Vista 3: Directorio de Otros Entrenadores
  Widget _buildOtrosCoachesView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Equipo de Entrenadores del Gimnasio', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Puedes consultar las especialidades de otros profesionales y solicitar un cambio si lo requieres:', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 16),
        if (_availableTrainers.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF1FAE87))))
        else
          ..._availableTrainers.map((t) {
            final name = '${t['nombre'] ?? ''} ${t['apellido'] ?? ''}'.trim();
            final specialty = t['specialty'] ?? 'Hipertrofia, Fuerza y Biomecánica';
            final isCurrent = (_trainerInfo != null && (t['id'] == _trainerInfo!['id'] || t['cedula'] == _trainerInfo!['cedula']));

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isCurrent ? const Color(0xFF1FAE87) : Colors.white10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: isCurrent ? const Color(0xFF1FAE87) : const Color(0xFF173B45),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'E',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                title: Text(
                  name.isNotEmpty ? name : 'Entrenador Pro',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(specialty, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1FAE87).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('✓ Tu Coach Asignado Actualmente', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                trailing: isCurrent
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1FAE87),
                          side: const BorderSide(color: Color(0xFF1FAE87)),
                        ),
                        onPressed: () {
                          setState(() => _activeHubTab = 0);
                          _registerActiveChatWithCoach();
                        },
                        child: const Text('Ir al Chat'),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FAE87)),
                        onPressed: () => _assignTrainer(t),
                        child: const Text('Elegir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
              ),
            );
          }),
      ],
    );
  }

  // Tarjeta interactiva de propuesta de sesión presencial
  Widget _buildSessionProposalCard() {
    if (_pendingSession == null) return const SizedBox.shrink();

    final s = _pendingSession!;
    final status = s['status']?.toString() ?? 'pending_confirmation';
    final st = s['start_time'] ?? '08:00';
    final et = s['end_time'] ?? '10:00';
    final sessionId = s['id']?.toString() ?? '';

    if (status == 'pending_confirmation' || status == 'scheduled') {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amberAccent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm_add_rounded, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Asistencia Pendiente de Confirmar',
                    style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Hoy', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tu coach te ha agendado hoy de $st a $et hrs. Por favor confirma si podrás asistir a esa hora o propón otro horario.',
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1FAE87),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: Text('Confirmar ($st)', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _confirmSession(sessionId, st),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Otra hora', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showRejectOrCounterModal(s),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (status == 'confirmed') {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1FAE87), width: 1.2),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF1FAE87),
              radius: 14,
              child: Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sesión presencial confirmada hoy de $st a $et hrs.',
                style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (status.startsWith('counter_proposed')) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF38BDF8),
              radius: 14,
              child: Icon(Icons.swap_horiz, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Propusiste entrenar a las ${s['counter_time'] ?? 'otra hora'} hrs. Esperando confirmación de tu coach.',
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchState() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Entrenador', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.person_off, color: Colors.redAccent, size: 40),
                  SizedBox(height: 12),
                  Text('No tienes un entrenador asignado', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Selecciona un entrenador profesional para que supervise tus sesiones, adapte tus cargas y coordine tus horarios.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Entrenadores Disponibles', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: _availableTrainers.isEmpty
                  ? const Center(child: Text('Cargando entrenadores...', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: _availableTrainers.length,
                      itemBuilder: (context, index) {
                        final t = _availableTrainers[index];
                        final name = '${t['nombre'] ?? ''} ${t['apellido'] ?? ''}'.trim();
                        final specialty = t['specialty'] ?? 'Hipertrofia, Fuerza y Biomecánica';
                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Color(0xFF1FAE87), child: Icon(Icons.sports, color: Colors.white)),
                            title: Text(name.isNotEmpty ? name : 'Entrenador Pro', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(specialty, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FAE87)),
                              onPressed: () => _assignTrainer(t),
                              child: const Text('Elegir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(String text, bool isMe, dynamic createdAt, String senderLabel) {
    String timeStr = '';
    if (createdAt != null && createdAt is String && createdAt.length >= 16) {
      timeStr = createdAt.substring(11, 16);
    }

    final bool isSessionBookingMsg = !isMe && (text.contains('Te he asignado un bloque') || text.contains('bloque de entrenamiento presencial'));
    final bool canConfirmHere = isSessionBookingMsg && _pendingSession != null && _pendingSession!['status'] == 'pending_confirmation';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1FAE87) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              senderLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white70 : const Color(0xFF1FAE87),
              ),
            ),
            const SizedBox(height: 4),
            _buildMessageContent(text, isMe),
            if (canConfirmHere) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('¿Confirmas tu asistencia para este horario?', style: TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1FAE87),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _confirmSession(
                            _pendingSession!['id'].toString(),
                            _pendingSession!['start_time'] ?? '08:00',
                          ),
                          child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF38BDF8)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _showRejectOrCounterModal(_pendingSession!),
                          child: const Text('Otra hora', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(String rawText, bool isMe) {
    if (rawText.startsWith('[IMAGE]:')) {
      final firstLineEnd = rawText.indexOf('\n');
      final imgUrl = firstLineEnd == -1 ? rawText.substring(8).trim() : rawText.substring(8, firstLineEnd).trim();
      final caption = firstLineEnd == -1 ? '' : rawText.substring(firstLineEnd + 1).trim();

      Widget imgWidget;
      if (imgUrl.startsWith('data:image')) {
        try {
          final b64Part = imgUrl.split(',')[1];
          final bytes = base64Decode(b64Part);
          imgWidget = Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 40),
          );
        } catch (_) {
          imgWidget = const Icon(Icons.broken_image, color: Colors.white54, size: 40);
        }
      } else {
        imgWidget = Image.network(
          imgUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF1FAE87), strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 40),
        );
      }

      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imgUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 260),
                child: imgWidget,
              ),
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(caption, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ],
      );
    }

    if (rawText.startsWith('[FEEDBACK_ANUNCIO:')) {
      final closeIdx = rawText.indexOf(']');
      final cleanText = closeIdx != -1 ? rawText.substring(closeIdx + 1).trim() : rawText;
      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('RESPUESTA A COMUNICADO', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(cleanText, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
        ],
      );
    }

    return Text(
      rawText,
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  void _showFullScreenImage(BuildContext context, String imgUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imgUrl.startsWith('data:image')
                      ? Image.memory(base64Decode(imgUrl.split(',')[1]))
                      : Image.network(imgUrl),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
