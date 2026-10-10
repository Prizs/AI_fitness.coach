import 'package:flutter/material.dart';

class TrainerMessagesTab extends StatelessWidget {
  const TrainerMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> activeChats = [
      {'name': 'Juan Pérez', 'last_msg': 'Profe, me duele un poco la rodilla.', 'time': '10:30 AM', 'unread': '1'},
      {'name': 'Ana Gómez', 'last_msg': 'Listo el entreno de hoy, estuvo rudo.', 'time': 'Ayer', 'unread': '0'},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mensajes Directos', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: activeChats.length,
                itemBuilder: (context, index) {
                  final chat = activeChats[index];
                  final hasUnread = chat['unread'] != '0';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1FAE87).withOpacity(0.2),
                      child: Text(chat['name']![0], style: const TextStyle(color: Color(0xFF1FAE87))),
                    ),
                    title: Text(chat['name']!, style: TextStyle(color: Colors.white, fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(chat['last_msg']!, style: TextStyle(color: hasUnread ? Colors.white70 : Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(chat['time']!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFF1FAE87), shape: BoxShape.circle),
                            child: Text(chat['unread']!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    onTap: () {
                      // Abrir chat
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Abriendo chat con ')));
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
