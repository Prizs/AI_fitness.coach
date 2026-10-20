import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTrainerStatus();
  }

  @override
  void dispose() {
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
          await _loadChatMessages();
          await _loadTrainerAnnouncements();
          _startPolling();
        } else {
          _pollTimer?.cancel();
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

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _loadChatMessagesSilently();
    });
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
        }
      }
    } catch (_) {}
  }

  Future<void> _loadAvailableTrainers() async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/trainers'));
      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes));
        if (list is List) {
          setState(() {
            _availableTrainers = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando entrenadores disponibles: $e');
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1FAE87),
            content: Text('¡Entrenador ${trainer['nombre']} asignado con éxito!'),
          ),
        );
        await _loadTrainerStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo asignar el entrenador.')),
        );
      }
    } catch (e) {
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

  Future<void> _showBookingDialog() async {
    final baseUrl = AuthService.apiBaseUrl;
    final trainerId = _trainerInfo!['id'] ?? _trainerInfo!['cedula'];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    List<dynamic> realBlocks = [];
    bool loadingSlots = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (loadingSlots) {
              http.get(Uri.parse('$baseUrl/api/trainer/agenda/$trainerId?target_date=$today')).then((res) {
                if (res.statusCode == 200) {
                  final data = json.decode(utf8.decode(res.bodyBytes));
                  if (data is Map && ctx.mounted) {
                    setModalState(() {
                      realBlocks = data['blocks'] ?? [];
                      loadingSlots = false;
                    });
                  }
                } else if (ctx.mounted) {
                  setModalState(() => loadingSlots = false);
                }
              }).catchError((e) {
                if (ctx.mounted) setModalState(() => loadingSlots = false);
              });
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Agendar Sesión con tu Entrenador', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Horarios en vivo para hoy ($today):', style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  if (loadingSlots)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF1FAE87))))
                  else if (realBlocks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay bloques disponibles por el momento.', style: TextStyle(color: Colors.white54)),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: realBlocks.length,
                        itemBuilder: (c, idx) {
                          final b = realBlocks[idx];
                          final timeLabel = b['time'] ?? 'Horario';
                          final capacityText = b['capacity'] ?? '';
                          final isFull = b['is_full'] == true;
                          final students = (b['students'] as List<dynamic>?) ?? [];
                          final bool alreadyBooked = students.any((s) => s['client_id'] == _myCedula || s['cedula'] == _myCedula);

                          return Card(
                            color: const Color(0xFF1E293B),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(Icons.access_time_filled, color: alreadyBooked ? Colors.greenAccent : (isFull ? Colors.redAccent : const Color(0xFF1FAE87))),
                              title: Text(timeLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                alreadyBooked ? '✅ Ya estás inscrito en este bloque' : capacityText,
                                style: TextStyle(
                                  color: alreadyBooked ? Colors.greenAccent : (isFull ? Colors.redAccent : Colors.white60),
                                  fontSize: 12,
                                  fontWeight: alreadyBooked ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: alreadyBooked
                                  ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFull ? Colors.white24 : const Color(0xFF1FAE87),
                                      ),
                                      onPressed: isFull
                                          ? null
                                          : () async {
                                              Navigator.pop(ctx);
                                              await _bookSession(b['start_time'], b['end_time']);
                                            },
                                      child: Text(isFull ? 'Lleno' : 'Reservar', style: const TextStyle(color: Colors.white)),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
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
        }),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1FAE87),
            content: Text('¡Sesión reservada exitosamente en la agenda del entrenador!'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reservando sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87)));
    }
    if (_hasTrainer && _trainerInfo != null) {
      return _buildActiveChat();
    }
    return _buildSearchState();
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

  Widget _buildActiveChat() {
    final trainerName = _trainerInfo!['name'] ?? '${_trainerInfo!['nombre'] ?? ''} ${_trainerInfo!['apellido'] ?? ''}'.trim();

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF0F192B),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF1FAE87), child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coach: $trainerName', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('En línea · Entrenador Asignado', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 12)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Agendar Horario',
                  icon: const Icon(Icons.calendar_month, color: Color(0xFF1FAE87)),
                  onPressed: _showBookingDialog,
                ),
                IconButton(
                  tooltip: 'Actualizar Mensajes',
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  onPressed: _loadChatMessages,
                ),
              ],
            ),
          ),
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
                      final senderId = (m['sender_id'] ?? '').toString();
                      final isMe = senderId == _myCedula || senderId == AuthService.instance.loggedInUser?.cedula;
                      return _chatBubble(m['message'] ?? '', isMe, m['created_at']);
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
          )
        ],
      ),
    );
  }

  Widget _chatBubble(String text, bool isMe, dynamic createdAt) {
    String timeStr = '';
    if (createdAt != null && createdAt is String && createdAt.length >= 16) {
      timeStr = createdAt.substring(11, 16);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1FAE87) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(timeStr, style: TextStyle(color: isMe ? Colors.white70 : Colors.white38, fontSize: 10)),
            ]
          ],
        ),
      ),
    );
  }
}
