import 'package:flutter/material.dart';

class TrainerAnnouncementsTab extends StatelessWidget {
  const TrainerAnnouncementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Muro de Anuncios', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('EnvÃ­a avisos globales a todos tus alumnos.', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe un nuevo anuncio o recomendaciÃ³n general...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('Publicar Anuncio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FAE87),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Anuncios Recientes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Hoy, 9:00 AM', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    SizedBox(height: 8),
                    Text('Chicos, el gimnasio estarÃ¡ cerrado maÃ±ana en la maÃ±ana. Ãšnanse al chat en lÃ­nea para asesorÃ­a.', style: TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
