import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/screens/trainer/client_detail_screen.dart';

class TrainerClientsTab extends StatefulWidget {
  const TrainerClientsTab({super.key});

  @override
  State<TrainerClientsTab> createState() => _TrainerClientsTabState();
}

class _TrainerClientsTabState extends State<TrainerClientsTab> {
  bool _isLoading = true;
  List<dynamic> _clients = [];

  String get _trainerCode => AuthService.instance.loggedInUser?.cedula ?? 'Desconocido';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/clients/$_trainerCode'));
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF1FAE87),
        onRefresh: _loadClients,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1FAE87), Color(0xFF107055)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1FAE87).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.fitness_center_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text('Tu Código de Vinculación', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      _trainerCode,
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Comparte este código con tus alumnos para que te asignen como su entrenador.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Motivational Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.military_tech, color: Colors.amber, size: 28),
                            SizedBox(width: 8),
                            Text('Nivel Élite', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          '${_clients.length} Alumnos',
                          style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Supervisando activamente a ${_clients.length} alumnos registrados en tu roster.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 0.85,
                        backgroundColor: Colors.black26,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tus Alumnos', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF1FAE87)),
                    onPressed: _loadClients,
                  )
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF1FAE87)),
                  ),
                )
              else if (_clients.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text(
                        'Aún no tienes alumnos vinculados',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pídeles a tus alumnos que ingresen tu cédula ($_trainerCode) en la pestaña "Mi Entrenador".',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    final name = '${client['nombre']} ${client['apellido']}'.trim();
                    final cedula = client['cedula'] ?? '';
                    final bool hasRisk = client['has_risk'] == true;
                    final String riskLabel = client['risk_label'] ?? '';
                    final edad = client['edad'] != null ? '${client['edad']} años' : '';
                    final peso = client['peso'] != null ? '${client['peso']} kg' : '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientDetailScreen(clientName: name),
                          ),
                        );
                      },
                      child: Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF1FAE87).withOpacity(0.2),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                  style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                        if (hasRisk) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.redAccent),
                                            ),
                                            child: Text(
                                              '🔴 $riskLabel',
                                              style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'C.I: $cedula ${edad.isNotEmpty ? "• $edad" : ""} ${peso.isNotEmpty ? "• $peso" : ""}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white54)
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
