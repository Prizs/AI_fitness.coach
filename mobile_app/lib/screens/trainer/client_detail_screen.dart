import 'package:flutter/material.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientName;
  const ClientDetailScreen({super.key, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        appBar: AppBar(
          title: Text('Ficha: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F192B),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF1FAE87),
            labelColor: Color(0xFF1FAE87),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Perfil & Progreso'),
              Tab(text: 'Entrenamiento'),
              Tab(text: 'Nutrición'),
              Tab(text: 'Análisis IA'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPerfilTab(),
            _buildEntrenamientoTab(),
            _buildNutricionTab(),
            _buildAiTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfilTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(
          title: 'Información Personal',
          icon: Icons.person,
          content: Column(
            children: [
              _infoRow('Edad', '28 años'),
              _infoRow('Peso Actual', '75 kg'),
              _infoRow('Objetivo', 'Ganancia Muscular'),
              _infoRow('Patologías', 'Ninguna'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Progreso y Ritmo',
          icon: Icons.trending_up,
          content: Column(
            children: [
              _infoRow('Frecuencia', '4 días a la semana'),
              _infoRow('Consistencia', '85% este mes'),
              const SizedBox(height: 12),
              const Text('Evolución de Peso (Últimas 4 semanas)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('72 kg', style: TextStyle(color: Colors.white54)),
                  Icon(Icons.arrow_right_alt, color: Color(0xFF1FAE87)),
                  Text('75 kg', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntrenamientoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Rutina Programada para Hoy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Día de Piernas y Glúteos',
          icon: Icons.fitness_center,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Máquinas y Equipos a utilizar:', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _machineItem('Prensa de Piernas (Leg Press)'),
              _machineItem('Máquina de Extensión de Cuádriceps'),
              _machineItem('Mancuernas (Pesos Libres)'),
              const Divider(color: Colors.white24, height: 24),
              const Text('El alumno espera asistencia en la Prensa de Piernas.', style: TextStyle(color: Colors.orangeAccent, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutricionTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(
          title: 'Plan de Alimentación',
          icon: Icons.restaurant,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Calorías Diarias', '2,800 kcal'),
              _infoRow('Proteína', '160g'),
              _infoRow('Carbohidratos', '350g'),
              _infoRow('Grasas', '85g'),
              const Divider(color: Colors.white24, height: 24),
              const Text('Sugerencia para hoy:', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Batido de proteína post-entrenamiento con plátano.', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.smart_toy, color: Color(0xFF1FAE87)),
                  SizedBox(width: 8),
                  Text('Recomendaciones de la IA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Resumen generado automáticamente basándose en el historial reciente del alumno:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              _buildAiTip('Rendimiento', 'Excelente progresión de cargas en las últimas 2 semanas. El usuario se está adaptando muy bien al volumen actual.'),
              _buildAiTip('Punto a Mejorar', 'La asimetría en el hombro derecho reportada persiste. Recomiendo que hoy verifiques su postura durante los ejercicios de tren superior.'),
              _buildAiTip('Ajuste Sugerido', 'Incrementar las calorías diarias a 3,000 kcal la próxima semana si el peso se estanca, ya que su gasto energético ha subido considerablemente.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _machineItem(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Widget content}) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1FAE87)),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildAiTip(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
