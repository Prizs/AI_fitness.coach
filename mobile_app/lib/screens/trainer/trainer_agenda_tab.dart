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
  String _dayName = '';
  int _totalStudents = 0;
  DateTime _selectedDate = DateTime.now();

  List<dynamic> _clients = [];
  bool _isLoadingClients = false;

  String get _trainerCedula => AuthService.instance.loggedInUser?.cedula ?? '';

  @override
  void initState() {
    super.initState();
    _loadAgenda();
    _loadClients();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadClients() async {
    setState(() => _isLoadingClients = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/clients/$_trainerCedula'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is List && mounted) {
          setState(() {
            _clients = data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando alumnos: $e');
    } finally {
      if (mounted) setState(() => _isLoadingClients = false);
    }
  }

  Future<void> _loadAgenda() async {
    setState(() => _isLoading = true);
    final baseUrl = AuthService.apiBaseUrl;
    final dateStr = _formatDate(_selectedDate);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/trainer/agenda/$_trainerCedula?target_date=$dateStr'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is Map && mounted) {
          setState(() {
            _currentDate = data['date'] ?? dateStr;
            _dayName = data['day_name'] ?? '';
            _totalStudents = (data['total_students'] as int?) ?? 0;
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

  void _changeDate(int offsetDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offsetDays));
    });
    _loadAgenda();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1FAE87),
              onPrimary: Colors.white,
              surface: Color(0xFF0F192B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAgenda();
    }
  }

  void _showAddSlotModal(BuildContext context) {
    final startController = TextEditingController(text: '08:00');
    final endController = TextEditingController(text: '10:00');
    final capacityController = TextEditingController(text: '2');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              const Text(
                'Añadir Bloque Horario a la Agenda',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Se añadirá para el día ${_dayName.isNotEmpty ? _dayName : "seleccionado"}.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
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
                  child: const Text(
                    'Guardar Horario',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
          'day_of_week': _selectedDate.weekday,
          'start_time': start.length == 5 ? '$start:00' : start,
          'end_time': end.length == 5 ? '$end:00' : end,
          'max_capacity': capacity,
        }),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1FAE87),
            content: Text('Nuevo bloque horario añadido a la agenda.'),
          ),
        );
        await _loadAgenda();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando horario: $e')),
      );
    }
  }

  void _showAssignClientModal(Map<String, dynamic> block) {
    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay alumnos registrados o asignados aún.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
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
                        'Inscribir Alumno en Horario',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bloque: ${block['time']} (${_formatDate(_selectedDate)})',
                        style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona el alumno para agendar:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    final clientName = '${client['nombre']} ${client['apellido']}'.trim();
                    final clientCedula = client['cedula'] ?? '';
                    final bool hasRisk = client['has_risk'] == true;
                    final String riskLabel = client['risk_label'] ?? '';

                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1FAE87).withOpacity(0.2),
                          child: Text(
                            clientName.isNotEmpty ? clientName[0].toUpperCase() : 'A',
                            style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          clientName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('C.I: $clientCedula', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            if (hasRisk)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '🔴 $riskLabel',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1FAE87),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _assignClientToSlot(client, block);
                          },
                          child: const Text('Asignar', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
  }

  Future<void> _assignClientToSlot(Map<String, dynamic> client, Map<String, dynamic> block) async {
    final baseUrl = AuthService.apiBaseUrl;
    final dateStr = _formatDate(_selectedDate);
    final clientCedula = client['cedula'] ?? client['id'];

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/agenda/book'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': _trainerCedula,
          'client_id': clientCedula,
          'schedule_date': dateStr,
          'start_time': block['start_time'],
          'end_time': block['end_time'],
        }),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1FAE87),
            content: Text('¡${client['nombre']} agendado correctamente para ${block['time']}!'),
          ),
        );
        await _loadAgenda();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo inscribir el alumno en este bloque.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar: $e')),
      );
    }
  }

  Future<void> _cancelSession(Map<String, dynamic> student) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F192B),
        title: const Text('Cancelar Sesión', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Deseas desvincular a ${student['name']} de este horario?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('No, volver', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final sessionId = student['id'];
    if (sessionId == null) return;

    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.delete(Uri.parse('$baseUrl/api/trainer/agenda/session/$sessionId'));
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1FAE87),
            content: Text('Sesión cancelada con éxito.'),
          ),
        );
        await _loadAgenda();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelando sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isToday = _formatDate(_selectedDate) == _formatDate(DateTime.now());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title + Añadir Horario
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agenda y Cronograma',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dayName.isNotEmpty ? '$_dayName • $_currentDate' : _currentDate,
                      style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddSlotModal(context),
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1FAE87), size: 18),
                  label: const Text('Añadir Horario', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 13, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF1FAE87).withOpacity(0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Interactive Date Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    tooltip: 'Día anterior',
                    onPressed: () => _changeDate(-1),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF1FAE87), size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${_dayName.isNotEmpty ? _dayName : "Fecha"}: ${_formatDate(_selectedDate)}',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isToday)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ActionChip(
                        label: const Text('Hoy', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFF1FAE87),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() => _selectedDate = DateTime.now());
                          _loadAgenda();
                        },
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    tooltip: 'Día siguiente',
                    onPressed: () => _changeDate(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Summary Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _totalStudents == 1
                        ? '1 Alumno agendado para este día'
                        : '$_totalStudents Alumnos agendados para este día',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  InkWell(
                    onTap: _loadAgenda,
                    child: Row(
                      children: const [
                        Icon(Icons.refresh, color: Color(0xFF1FAE87), size: 14),
                        SizedBox(width: 4),
                        Text('Actualizar', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Agenda List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87)))
                  : _agendaBlocks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 48, color: Colors.white24),
                              const SizedBox(height: 12),
                              const Text('No hay horarios configurados para esta fecha.', style: TextStyle(color: Colors.white54)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FAE87)),
                                onPressed: () => _showAddSlotModal(context),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text('Configurar Horario', style: TextStyle(color: Colors.white)),
                              )
                            ],
                          ),
                        )
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

                              Color capColor = const Color(0xFF1FAE87);
                              if (isFull) {
                                capColor = Colors.redAccent;
                              } else if (students.isNotEmpty) {
                                capColor = Colors.orangeAccent;
                              }

                              return _buildTimeBlock(context, block, timeStr, capacityText, students, capColor, isFull);
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
    Map<String, dynamic> block,
    String time,
    String capacity,
    List<dynamic> students,
    Color capacityColor,
    bool isFull,
  ) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: students.isNotEmpty ? capacityColor.withOpacity(0.3) : Colors.white10,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Block Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: Color(0xFF1FAE87), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: capacityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: capacityColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        capacity,
                        style: TextStyle(color: capacityColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!isFull) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showAssignClientModal(block),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1FAE87).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1FAE87)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.person_add, color: Color(0xFF1FAE87), size: 14),
                              SizedBox(width: 4),
                              Text('Inscribir', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Students in Block
            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.white38),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Sin alumnos inscritos en este bloque. Pulsa "Inscribir" para asignar uno.',
                        style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...students.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F192B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF1FAE87),
                              child: Text(
                                (s['name'] as String? ?? 'A')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ClientDetailScreen(clientName: s['name'] ?? 'Alumno'),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      s['name'] ?? 'Alumno',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.open_in_new, color: Color(0xFF1FAE87), size: 14),
                                  ],
                                ),
                              ),
                            ),
                            // Risk / Health Badge
                            if (s['risk'] != null && s['risk'] != 'none') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (s['risk'].toString().startsWith('🔴'))
                                      ? Colors.redAccent.withOpacity(0.2)
                                      : ((s['risk'].toString().startsWith('⚠️'))
                                          ? Colors.orangeAccent.withOpacity(0.2)
                                          : Colors.greenAccent.withOpacity(0.15)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (s['risk'].toString().startsWith('🔴'))
                                        ? Colors.redAccent.withOpacity(0.7)
                                        : ((s['risk'].toString().startsWith('⚠️'))
                                            ? Colors.orangeAccent.withOpacity(0.7)
                                            : Colors.greenAccent.withOpacity(0.5)),
                                  ),
                                ),
                                child: Text(
                                  s['risk'],
                                  style: TextStyle(
                                    color: (s['risk'].toString().startsWith('🔴'))
                                        ? Colors.redAccent
                                        : ((s['risk'].toString().startsWith('⚠️'))
                                            ? Colors.orangeAccent
                                            : Colors.greenAccent),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Cancel booking button
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                              tooltip: 'Desvincular alumno de este horario',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _cancelSession(s),
                            ),
                          ],
                        ),
                        // Workout / Routine scheduled for the student
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: Row(
                            children: [
                              const Icon(Icons.fitness_center, color: Colors.white38, size: 13),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Plan: ${s['workout'] ?? "Rutina planificada"}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
