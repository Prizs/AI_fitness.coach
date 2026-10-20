import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/screens/trainer/trainer_clients_tab.dart';
import 'package:mobile_app/screens/trainer/trainer_agenda_tab.dart';
import 'package:mobile_app/screens/trainer/trainer_announcements_tab.dart';
import 'package:mobile_app/screens/trainer/trainer_messages_tab.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/main.dart';

class TrainerShell extends StatefulWidget {
  const TrainerShell({super.key});

  @override
  State<TrainerShell> createState() => _TrainerShellState();
}

class _TrainerShellState extends State<TrainerShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TrainerAgendaTab(),
    TrainerClientsTab(),
    TrainerAnnouncementsTab(),
    TrainerMessagesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('Panel Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Color(0xFF1FAE87)),
            tooltip: 'Notificaciones y Alertas',
            onPressed: () => _showNotificationsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              AuthService.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()), 
                (r) => false
              );
            },
          )
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F192B),
        selectedItemColor: const Color(0xFF1FAE87),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Alumnos'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Anuncios'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chats'),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final trainerCedula = AuthService.instance.loggedInUser?.cedula ?? '';
        final baseUrl = AuthService.apiBaseUrl;

        return FutureBuilder<http.Response>(
          future: http.get(Uri.parse('$baseUrl/api/trainer/notifications/$trainerCedula')),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87))),
              );
            }

            List<dynamic> notifs = [];
            if (snapshot.hasData && snapshot.data!.statusCode == 200) {
              try {
                notifs = json.decode(utf8.decode(snapshot.data!.bodyBytes));
              } catch (_) {}
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
                      const Text('Notificaciones y Alertas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (notifs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No hay alertas pendientes en este momento.', style: TextStyle(color: Colors.white54))),
                    )
                  else
                    ...notifs.map((n) {
                      final isHigh = n['priority'] == 'high';
                      final title = n['title'] ?? 'Alerta';
                      final msg = n['message'] ?? '';
                      final time = n['time'] ?? '';

                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isHigh ? Colors.redAccent.withOpacity(0.5) : const Color(0xFF1FAE87).withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            isHigh ? Icons.warning_amber_rounded : Icons.info_outline,
                            color: isHigh ? Colors.redAccent : const Color(0xFF1FAE87),
                          ),
                          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          trailing: Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
