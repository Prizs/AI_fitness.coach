import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/chat_notification_service.dart';

class TrainerMessagesTab extends StatefulWidget {
  const TrainerMessagesTab({super.key});

  @override
  State<TrainerMessagesTab> createState() => _TrainerMessagesTabState();
}

class _TrainerMessagesTabState extends State<TrainerMessagesTab> {
  bool _isLoading = true;
  List<dynamic> _conversations = [];

  String get _trainerCedula => AuthService.instance.loggedInUser?.cedula ?? '';

  Timer? _convTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _convTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _loadConversationsSilently();
    });
  }

  @override
  void dispose() {
    _convTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversationsSilently() async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/conversations/$_trainerCedula'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List && mounted) {
          setState(() {
            _conversations = list;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/conversations/$_trainerCedula'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List && mounted) {
          setState(() {
            _conversations = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando conversaciones: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mensajes Directos', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF1FAE87)),
                  onPressed: _loadConversations,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87)))
                  : _conversations.isEmpty
                      ? const Center(
                          child: Text('No hay mensajes aún con tus alumnos.', style: TextStyle(color: Colors.white54)),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF1FAE87),
                          onRefresh: _loadConversations,
                          child: ListView.separated(
                            itemCount: _conversations.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                            itemBuilder: (context, index) {
                              final chat = _conversations[index];
                              final hasUnread = chat['unread'] == '1';
                              final clientName = chat['name'] ?? 'Alumno';
                              final lastMsg = chat['last_msg'] ?? 'Sin mensajes';
                              final time = chat['time'] ?? 'Hoy';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1FAE87).withOpacity(0.2),
                                  child: Text(clientName.isNotEmpty ? clientName[0].toUpperCase() : 'A', style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
                                ),
                                title: Text(clientName, style: TextStyle(color: Colors.white, fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal)),
                                subtitle: Text(lastMsg, style: TextStyle(color: hasUnread ? Colors.white70 : Colors.white38), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    if (hasUnread) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(color: Color(0xFF1FAE87), shape: BoxShape.circle),
                                        child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TrainerClientChatScreen(
                                        clientId: chat['client_id'] ?? chat['cedula'] ?? '',
                                        clientName: clientName,
                                      ),
                                    ),
                                  ).then((_) => _loadConversations());
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrainerClientChatScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const TrainerClientChatScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<TrainerClientChatScreen> createState() => _TrainerClientChatScreenState();
}

class _TrainerClientChatScreenState extends State<TrainerClientChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isSending = false;
  List<dynamic> _messages = [];

  String get _trainerCedula => AuthService.instance.loggedInUser?.cedula ?? '';

  Timer? _msgTimer;

  @override
  void initState() {
    super.initState();
    ChatNotificationService.instance.pushActiveChat(
      userId: widget.clientId,
      userName: widget.clientName,
    );
    _loadMessages();
    _msgTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _loadMessagesSilently();
    });
  }

  @override
  void dispose() {
    ChatNotificationService.instance.popActiveChat(
      userId: widget.clientId,
      userName: widget.clientName,
    );
    _msgTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessagesSilently() async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/messages/$_trainerCedula/${widget.clientId}'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List && mounted && list.length != _messages.length) {
          setState(() {
            _messages = list;
          });
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/messages/$_trainerCedula/${widget.clientId}'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List && mounted) {
          setState(() {
            _messages = list;
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error cargando mensajes: $e');
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _sendMessageDirect(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    setState(() => _isSending = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': _trainerCedula,
          'client_id': widget.clientId,
          'sender_id': _trainerCedula,
          'message': text.trim(),
        }),
      );
      if (res.statusCode == 200) {
        await _loadMessages();
      }
    } catch (e) {
      debugPrint('Error enviando mensaje directo: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showActionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Herramientas del Coach (+)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Atención y seguimiento para ${widget.clientName}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _actionMenuTile(
                  icon: Icons.add_photo_alternate_rounded,
                  iconColor: const Color(0xFF1FAE87),
                  title: 'Subir Imagen / Foto de Referencia',
                  subtitle: 'Envía infografías, fotos de técnica o correcciones',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSendImage();
                  },
                ),
                const SizedBox(height: 10),
                _actionMenuTile(
                  icon: Icons.fitness_center_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'Plan de Entrenamiento de Hoy & Horario',
                  subtitle: 'Rutina asignada para hoy, horario y ejercicios clave',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showTodayPlanModal();
                  },
                ),
                const SizedBox(height: 10),
                _actionMenuTile(
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Respuestas Rápidas',
                  subtitle: 'Mensajes frecuentes de técnica, hidratación y ánimo',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showQuickRepliesModal();
                  },
                ),
                const SizedBox(height: 10),
                _actionMenuTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFFA855F7),
                  title: 'Asistente IA del Coach (Consejo & Repaso)',
                  subtitle: 'Analiza la conversación y redacta el consejo perfecto',
                  onTap: () {
                    Navigator.pop(ctx);
                    _askAiCoachAssist();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;

    final captionController = TextEditingController();
    if (!mounted) return;
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F192B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enviar Imagen al Alumno', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imagen: ${image.name}', style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: captionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Añadir nota técnica o mensaje (opcional)...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FAE87)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldSend != true) return;

    setState(() => _isSending = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final bytes = await image.readAsBytes();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/trainer/upload-chat-image'));
      request.fields['trainer_id'] = _trainerCedula;
      request.fields['client_id'] = widget.clientId;
      request.fields['sender_id'] = _trainerCedula;
      if (captionController.text.trim().isNotEmpty) {
        request.fields['caption'] = captionController.text.trim();
      }
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        await _loadMessages();
      }
    } catch (e) {
      debugPrint('Error enviando imagen: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showTodayPlanModal() async {
    final baseUrl = AuthService.apiBaseUrl;
    Map<String, dynamic>? planData;
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (loading) {
              http.get(Uri.parse('$baseUrl/api/trainer/client-today-plan/$_trainerCedula/${widget.clientId}')).then((res) {
                if (res.statusCode == 200) {
                  final data = json.decode(utf8.decode(res.bodyBytes));
                  if (ctx.mounted) {
                    setModalState(() {
                      planData = data is Map<String, dynamic> ? data : null;
                      loading = false;
                    });
                  }
                } else if (ctx.mounted) {
                  setModalState(() => loading = false);
                }
              }).catchError((_) {
                if (ctx.mounted) setModalState(() => loading = false);
              });
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Plan de Hoy & Horario', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (loading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF1FAE87))))
                  else if (planData == null)
                    const Text('No se pudo cargar el plan del día.', style: TextStyle(color: Colors.white70))
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(planData!['day_name'] ?? 'Hoy', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  planData!['schedule_time'] != null ? '⏰ ${planData!['schedule_time']}' : '⏰ Sin horario agendado',
                                  style: TextStyle(
                                    color: planData!['schedule_time'] != null ? const Color(0xFF1FAE87) : Colors.amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(planData!['routine_title'] ?? 'Rutina General', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (planData!['exercises'] is List)
                            ...((planData!['exercises'] as List).take(4).map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: Color(0xFF1FAE87), size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${e['name']} (${e['sets'] ?? 3}x${e['reps'] ?? '10-12'})',
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF38BDF8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final msg = planData!['formatted_message'] ?? '';
                              _controller.text = msg;
                              Navigator.pop(ctx);
                            },
                            child: const Text('Insertar en Chat', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1FAE87),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final msg = planData!['formatted_message'] ?? '';
                              Navigator.pop(ctx);
                              _sendMessageDirect(msg);
                            },
                            child: const Text('Enviar Directo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickRepliesModal() {
    final quickReplies = [
      '¡Excelente trabajo hoy! Mantén esa constancia y descansa bien.',
      '¿Cómo sentiste las cargas y la intensidad del entrenamiento de hoy?',
      'Recuerda hidratarte bien y realizar los estiramientos post-entreno.',
      'Te espero en el gimnasio a la hora acordada. ¡Puntualidad para aprovechar la sesión!',
      'Si sientes alguna molestia muscular o articular, avísame de inmediato para ajustar.',
      '¡A darlo todo hoy con disciplina! Cada repetición suma a tu meta.',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Respuestas Rápidas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                ...quickReplies.map((qr) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _sendMessageDirect(qr);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                          ),
                          child: Text(qr, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _askAiCoachAssist() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF0F192B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFA855F7)),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Analizando conversación y plan de hoy con IA...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );

    final baseUrl = AuthService.apiBaseUrl;
    Map<String, dynamic>? aiResult;

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/ai-coach-assist'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': _trainerCedula,
          'client_id': widget.clientId,
          'recent_messages': _messages.take(8).toList(),
        }),
      );

      if (mounted) Navigator.pop(context);

      if (res.statusCode == 200) {
        aiResult = json.decode(utf8.decode(res.bodyBytes));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error en IA coach assist: $e');
    }

    if (!mounted) return;
    if (aiResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar la recomendación de la IA en este momento.')),
      );
      return;
    }

    final suggested = aiResult['suggested_message'] ?? '';
    final summary = aiResult['summary'] ?? '';
    final keyPoint = aiResult['key_point'] ?? '';
    final quote = aiResult['motivation_quote'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 22),
                      SizedBox(width: 8),
                      Text('Asistente IA del Coach', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              if (summary.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📌 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          summary,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1FAE87).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mensaje Sugerido para Enviar:', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(suggested, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                    if (keyPoint.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('💡 Consejo clave: $keyPoint', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                    if (quote.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('🔥 "$quote"', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFA855F7)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _controller.text = suggested;
                        Navigator.pop(ctx);
                      },
                      child: const Text('Insertar en Chat', style: TextStyle(color: Color(0xFFA855F7), fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1FAE87),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendMessageDirect(suggested);
                      },
                      child: const Text('Enviar al Alumno', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() => _isSending = true);

    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': _trainerCedula,
          'client_id': widget.clientId,
          'sender_id': _trainerCedula,
          'message': text,
        }),
      );
      if (res.statusCode == 200) {
        await _loadMessages();
      }
    } catch (e) {
      debugPrint('Error enviando mensaje: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F192B),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1FAE87),
              child: Text(widget.clientName.isNotEmpty ? widget.clientName[0].toUpperCase() : 'A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Alumno', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87)))
                : _messages.isEmpty
                    ? Center(
                        child: Text('No hay mensajes previos con ${widget.clientName}.', style: const TextStyle(color: Colors.white54)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          final bool isTrainer = m['is_from_trainer'] == true || m['sender_role'] == 'trainer';
                          final bool isMe = isTrainer;
                          final String senderLabel = isMe ? 'Tú (Coach)' : (widget.clientName.isNotEmpty ? widget.clientName : 'Alumno');
                          return _buildBubble(m['message'] ?? '', isMe, m['created_at'], senderLabel);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF0F192B),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Herramientas del Coach e IA (+)',
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF1FAE87), size: 20),
                  ),
                  onPressed: _showActionsMenu,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Responder al alumno...',
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
      ),
    );
  }

  Widget _buildBubble(String text, bool isTrainer, dynamic createdAt, String senderLabel) {
    String timeStr = '';
    if (createdAt != null && createdAt is String && createdAt.length >= 16) {
      timeStr = createdAt.substring(11, 16);
    }

    return Align(
      alignment: isTrainer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          color: isTrainer ? const Color(0xFF1FAE87) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isTrainer ? 16 : 4),
            bottomRight: Radius.circular(isTrainer ? 4 : 16),
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
          crossAxisAlignment: isTrainer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              senderLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isTrainer ? Colors.white70 : const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(height: 4),
            _buildMessageContent(text, isTrainer),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                  color: isTrainer ? Colors.white70 : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(String rawText, bool isTrainer) {
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
        crossAxisAlignment: isTrainer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
        crossAxisAlignment: isTrainer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
