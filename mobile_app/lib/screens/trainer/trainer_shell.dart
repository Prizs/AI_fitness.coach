import 'package:flutter/material.dart';
import 'package:mobile_app/screens/trainer/trainer_clients_tab.dart';
import 'package:mobile_app/screens/trainer/trainer_agenda_tab.dart';
import 'package:mobile_app/screens/trainer/trainer_announcements_tab.dart';
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
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar SesiÃ³n',
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
        backgroundColor: const Color(0xFF0F192B),
        selectedItemColor: const Color(0xFF1FAE87),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Alumnos'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Anuncios'),
        ],
      ),
    );
  }
}
