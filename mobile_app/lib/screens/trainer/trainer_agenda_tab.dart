import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/screens/trainer/client_detail_screen.dart';
import 'package:mobile_app/services/auth_service.dart';

class TrainerAgendaTab extends StatefulWidget {
  const TrainerAgendaTab({super.key});

  @override
  State<TrainerAgendaTab> createState() => _TrainerAgendaTabState();
}

class _TrainerAgendaTabState extends State<TrainerAgendaTab> {
  bool _isLoading = true;
  List<dynamic> _agendaBlocks = [];
  String _currentDate = '';

  String get _trainerCedula => AuthService.instance.loggedInUser?.cedula ?? '';

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  Future<void> _loadAgenda() async {
    setState(() => _isLoading = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/agenda/$_trainerCedula'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is Map && mounted) {
          setState(() {
            _currentDate = data['date'] ?? '';
            _agendaBlocks = data['blocks'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando agenda: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddSlotModal(BuildContext context) {
    final startController = TextEditingController(text: '10:00');
    final endController = TextEditingController(text: '12:00');
    final capacityController = TextEditingController(text: '2');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Añadir Bloque Horario a la Agenda', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: startController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Hora Inicio (ej: 08:00)',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Hora Fin (ej: 10:00)',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Capacidad Máxima de Alumnos',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1FAE87),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _saveSlot(
                      startController.text.trim(),
                      endController.text.trim(),
                      int.tryParse(capacityController.text.trim()) ?? 2,
                    );
                  },
                  child: const Text('Guardar Horario', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveSlot(String start, String end, int capacity) async {
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/agenda/slot'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': _trainerCedula,
          'day_of_week': DateTime.now().weekday,
          'start_time': '$start:00',
          'end_time': '$end:00',
          'max_capacity': capacity,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1FAE87),
            content: Text('Nuevo bloque horario añadido a la agenda.'),
          ),
        );
        await _loadAgenda();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando horario: $e')),
      );
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Agenda de Hoy', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    if (_currentDate.isNotEmpty)
                      Text(_currentDate, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddSlotModal(context),
                  icon: const Icon(Icons.edit_calendar, color: Color(0xFF1FAE87), size: 18),
                  label: const Text('Añadir Horario', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 13)),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFF1FAE87).withOpacity(0.1)),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87)))
                  : RefreshIndicator(
                      color: const Color(0xFF1FAE87),
                      onRefresh: _loadAgenda,
                      child: ListView.builder(
                        itemCount: _agendaBlocks.length,
                        itemBuilder: (context, index) {
                          final block = _agendaBlocks[index];
                          final timeStr = block['time'] ?? 'Horario';
                          final capacityText = block['capacity'] ?? '2 Cupos';
                          final isFull = block['is_full'] == true;
                          final students = (block['students'] as List<dynamic>?) ?? [];

                          Color capColor = Colors.greenAccent;
                          if (isFull) {
                            capColor = Colors.redAccent;
                          } else if (students.isNotEmpty) {
                            capColor = Colors.orangeAccent;
                          }

                          return _buildTimeBlock(context, timeStr, capacityText, students, capColor);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBlock(
    BuildContext context,
    String time,
    String capacity,
    List<dynamic> students,
    Color capacityColor,
  ) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    const Icon(Icons.access_time_filled, color: Color(0xFF1FAE87), size: 18),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: capacityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: capacityColor.withOpacity(0.4)),
                  ),
                  child: Text(capacity, style: TextStyle(color: capacityColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              const Text('No hay alumnos inscritos en este bloque.', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic, fontSize: 13))
            else
              ...students.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientDetailScreen(clientName: s['name'] ?? 'Alumno'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F192B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 12, backgroundColor: Color(0xFF1FAE87), child: Icon(Icons.person, color: Colors.white, size: 14)),
                            const SizedBox(width: 8),
                            Text(s['name'] ?? 'Alumno', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                            if (s['risk'] != null && s['risk'] != 'none') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                                ),
                                child: Text(
                                  s['risk'],
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '- ${s['workout'] ?? ''}',
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                          ],
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
