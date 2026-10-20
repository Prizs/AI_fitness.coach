import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

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
  bool _isLoading = true;
  bool _isSending = false;
  List<dynamic> _messages = [];

  String get _trainerCedula => AuthService.instance.loggedInUser?.cedula ?? '';

  Timer? _msgTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _msgTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _loadMessagesSilently();
    });
  }

  @override
  void dispose() {
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
                          final senderId = (m['sender_id'] ?? '').toString();
                          final isTrainer = senderId == _trainerCedula || senderId == AuthService.instance.loggedInUser?.cedula;
                          return _buildBubble(m['message'] ?? '', isTrainer, m['created_at']);
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

  Widget _buildBubble(String text, bool isTrainer, dynamic createdAt) {
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isTrainer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(timeStr, style: TextStyle(color: isTrainer ? Colors.white70 : Colors.white38, fontSize: 10)),
            ]
          ],
        ),
      ),
    );
  }
}
