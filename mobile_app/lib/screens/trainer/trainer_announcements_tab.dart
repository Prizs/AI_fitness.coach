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

  String get _trainerCedula => AuthService.instance.loggedInUser?.cedula ?? '';

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
        }),
      );

      if (res.statusCode == 200) {
        _announcementController.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1FAE87),
            content: Text('¡Anuncio publicado en el muro de tus alumnos!'),
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
                      Text('Envía avisos globales a todos tus alumnos.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF1FAE87)),
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
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _announcementController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un nuevo aviso, cambio de horario o recomendación técnica...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isPublishing ? null : _publishAnnouncement,
                          icon: _isPublishing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send, color: Colors.white, size: 16),
                          label: const Text('Publicar Anuncio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1FAE87),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
              const Text('Anuncios Publicados', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  final id = ann['id'] as String?;
                  final msg = ann['message'] as String? ?? '';
                  final createdAt = ann['created_at'] as String? ?? '';
                  String timeLabel = 'Reciente';
                  if (createdAt.isNotEmpty) {
                    try {
                      final dt = DateTime.parse(createdAt).toLocal();
                      timeLabel = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }

                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                                  const Icon(Icons.campaign, color: Color(0xFF1FAE87), size: 18),
                                  const SizedBox(width: 8),
                                  Text(timeLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                              if (id != null)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  tooltip: 'Eliminar anuncio',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _deleteAnnouncement(id),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
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
