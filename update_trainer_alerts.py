# 1. Update trainer_agenda_tab.dart
path_agenda = 'mobile_app/lib/screens/trainer/trainer_agenda_tab.dart'
with open(path_agenda, 'r', encoding='utf-8') as f:
    text_agenda = f.read()

old_blocks = """                  _buildTimeBlock(context, '12:00 PM - 2:00 PM', '2/2 Cupos Llenos', [
                    {'name': 'Juan Pérez', 'workout': 'Pecho e hipertrofia'},
                    {'name': 'Ana Gómez', 'workout': 'Cardio intenso'},
                  ], Colors.redAccent),
                  _buildTimeBlock(context, '2:00 PM - 4:00 PM', '1/2 Cupos Libres', [
                    {'name': 'Carlos Ruiz', 'workout': 'Piernas'},
                  ], Colors.orangeAccent),"""

new_blocks = """                  _buildTimeBlock(context, '12:00 PM - 2:00 PM', '2/2 Cupos Llenos', [
                    {'name': 'Juan Pérez', 'workout': 'Pecho e hipertrofia', 'risk': 'none'},
                    {'name': 'Ana Gómez', 'workout': 'Cardio intenso', 'risk': '🔴 Molestia Rodilla'},
                  ], Colors.redAccent),
                  _buildTimeBlock(context, '2:00 PM - 4:00 PM', '1/2 Cupos Libres', [
                    {'name': 'Carlos Ruiz', 'workout': 'Piernas', 'risk': '⚠️ Fatiga Alta'},
                  ], Colors.orangeAccent),"""

text_agenda = text_agenda.replace(old_blocks, new_blocks)

old_row = """                      Text(s['name']!, style: const TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.underline)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('- ' + s['workout']!, style: const TextStyle(color: Colors.white54, fontSize: 14), overflow: TextOverflow.ellipsis)),"""

new_row = """                      Text(s['name']!, style: const TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.underline)),
                      if (s['risk'] != null && s['risk'] != 'none') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                          ),
                          child: Text(
                            s['risk']!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Expanded(child: Text('- ' + s['workout']!, style: const TextStyle(color: Colors.white54, fontSize: 14), overflow: TextOverflow.ellipsis)),"""

text_agenda = text_agenda.replace(old_row, new_row)

with open(path_agenda, 'w', encoding='utf-8') as f:
    f.write(text_agenda)
print("Updated trainer_agenda_tab.dart with risk alerts!")

# 2. Update trainer_clients_tab.dart
path_clients = 'mobile_app/lib/screens/trainer/trainer_clients_tab.dart'
with open(path_clients, 'r', encoding='utf-8') as f:
    text_clients = f.read()

old_clients_mock = """    final List<Map<String, dynamic>> mockClients = [
      {'id': '1', 'name': 'Juan Pérez', 'goal': 'Ganar Músculo', 'status': 'Activo', 'last_photo': 'Hace 2 días'},
      {'id': '2', 'name': 'Ana Gómez', 'goal': 'Perder Peso', 'status': 'Requiere revisión', 'last_photo': 'Hoy'},
    ];"""

new_clients_mock = """    final List<Map<String, dynamic>> mockClients = [
      {'id': '1', 'name': 'Juan Pérez', 'goal': 'Ganar Músculo', 'status': 'Activo', 'last_photo': 'Hace 2 días', 'alert': null},
      {'id': '2', 'name': 'Ana Gómez', 'goal': 'Perder Peso', 'status': 'Requiere revisión', 'last_photo': 'Hoy', 'alert': '🔴 Molestia en Rodilla'},
    ];"""

text_clients = text_clients.replace(old_clients_mock, new_clients_mock)

old_client_item = """                                Text(client['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Meta: ' + (client['goal'] as String), style: const TextStyle(color: Colors.white70, fontSize: 14)),"""

new_client_item = """                                Row(
                                  children: [
                                    Text(client['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    if (client['alert'] != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.redAccent),
                                        ),
                                        child: Text(
                                          client['alert'] as String,
                                          style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Meta: ' + (client['goal'] as String), style: const TextStyle(color: Colors.white70, fontSize: 14)),"""

text_clients = text_clients.replace(old_client_item, new_client_item)

with open(path_clients, 'w', encoding='utf-8') as f:
    f.write(text_clients)
print("Updated trainer_clients_tab.dart with risk alerts!")
