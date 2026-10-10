import 'package:flutter/material.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientName;
  const ClientDetailScreen({super.key, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: Text('Expediente: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen AI
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
                      Text('AnÃ¡lisis IA del Rendimiento', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Basado en los Ãºltimos entrenamientos y fotos de progreso de este alumno, la IA detecta lo siguiente:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  _buildAiTip('Progreso Positivo', 'Ha aumentado 5kg en Press de Banca en 2 semanas.'),
                  _buildAiTip('Alerta de Estancamiento', 'La pÃ©rdida de grasa corporal se detuvo (estÃ¡ en 18%). Revisar nutriciÃ³n.'),
                  _buildAiTip('Sugerencia IA', 'Asignar rutina de fuerza mÃ¡xima para romper el estancamiento e invitar a charla motivacional.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text('Chat Privado', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Ver Progreso', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FAE87), padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            )
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
