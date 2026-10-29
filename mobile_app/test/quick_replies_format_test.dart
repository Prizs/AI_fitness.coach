import 'package:flutter_test/flutter_test.dart';

String cleanQrItem(dynamic qr) {
  if (qr == null) return '';
  if (qr is Map) {
    final val = qr['title'] ?? qr['text'] ?? qr['label'] ?? qr['payload'];
    if (val != null) return val.toString().trim();
  }
  String s = qr.toString().trim();
  if (s.startsWith('{') && (s.contains('title') || s.contains('text') || s.contains('label'))) {
    final match = RegExp(r"(?:title|text|label)\s*[:=]\s*(.+?)(?:,\s*[a-zA-Z0-9_]+[:=]|\}\s*$)").firstMatch(s);
    if (match != null) {
      String extracted = match.group(1)!.trim();
      extracted = extracted.replaceAll(RegExp(r"^['" + '"]|[' + '"]' + r"$"), '').trim();
      if (extracted.isNotEmpty) return extracted;
    }
  }
  return s;
}

List<String> sanitizeQuickReplies(dynamic list) {
  if (list is! List) return [];
  return list
      .map((item) => cleanQrItem(item))
      .where((s) => s.isNotEmpty)
      .toList();
}

void main() {
  test('cleanQrItem sanitizes maps and stringified map objects into clean titles', () {
    // Caso 1: String normal
    expect(cleanQrItem('🗓️ Plan Semanal (Lunes a Viernes)'), '🗓️ Plan Semanal (Lunes a Viernes)');

    // Caso 2: Objeto Map con title
    expect(
      cleanQrItem({'content_type': 'text', 'title': '🗓️ Plan Semanal (Lunes a Viernes)'}),
      '🗓️ Plan Semanal (Lunes a Viernes)',
    );

    // Caso 3: String generado por Map.toString() como el del bug visual visto en la imagen
    const rawMapString = '{content_type: text, title: 🗓️ Plan Semanal (Lunes a Viernes)}';
    expect(cleanQrItem(rawMapString), '🗓️ Plan Semanal (Lunes a Viernes)');

    // Caso 4: Con coma dentro del texto
    const rawWithComma = '{content_type: text, title: 💪 ¡Me siento al 100%, listo para entrenar!}';
    expect(cleanQrItem(rawWithComma), '💪 ¡Me siento al 100%, listo para entrenar!');

    // Caso 5: Title no al final sino al inicio
    const rawTitleFirst = '{title: 💪 ¡Me siento al 100%, listo para entrenar!, content_type: text}';
    expect(cleanQrItem(rawTitleFirst), '💪 ¡Me siento al 100%, listo para entrenar!');

    // Caso 6: Lista mixta procesada con sanitizeQuickReplies
    final rawList = [
      '🏋️ Ver ejercicios de hoy',
      {'content_type': 'text', 'title': '🗓️ Plan Semanal (Lunes a Viernes)'},
      '{content_type: text, title: 💪 ¡Me siento al 100%, listo para entrenar!}'
    ];
    final cleaned = sanitizeQuickReplies(rawList);
    expect(cleaned, [
      '🏋️ Ver ejercicios de hoy',
      '🗓️ Plan Semanal (Lunes a Viernes)',
      '💪 ¡Me siento al 100%, listo para entrenar!'
    ]);
  });
}
