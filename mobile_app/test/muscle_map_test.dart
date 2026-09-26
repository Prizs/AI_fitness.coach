import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/muscle_map.dart';

void main() {
  group('mapeo de musculos a IDs del atlas', () {
    test('cuadriceps devuelve los cuatro musculos del muslo', () {
      final ids = MuscleMap.idsFor('Cuádriceps');
      expect(ids, contains('rectus_femoris_l'));
      expect(ids, contains('vastus_lateralis_r'));
      expect(ids.length, 6);
    });

    test('funciona sin acentos y con sinonimos', () {
      expect(
        MuscleMap.idsFor('cuadriceps'),
        MuscleMap.idsFor('Cuádriceps'),
      );
      expect(MuscleMap.idsFor('pectoral'), contains('pectoralis_major_l'));
    });

    test('dorsal ancho incluye escapula y espalda', () {
      final ids = MuscleMap.idsFor('Dorsal ancho');
      expect(ids, contains('latissimus_dorsi_l'));
    });

    test('core incluye abdominales y oblicuos', () {
      final ids = MuscleMap.idsFor('Core');
      expect(ids, contains('rectus_abdominis_1_l'));
      expect(ids, contains('external_oblique_1_r'));
    });

    test('texto desconocido devuelve conjunto vacio', () {
      expect(MuscleMap.idsFor('Musculo inexistente'), isEmpty);
    });

    test('nulo o vacio devuelve conjunto vacio', () {
      expect(MuscleMap.idsFor(null), isEmpty);
      expect(MuscleMap.idsFor('   '), isEmpty);
    });

    test('los nombres de grupo son legibles', () {
      expect(MuscleMap.groupNamesFor('Glúteos'), contains('Glúteos'));
      expect(MuscleMap.groupNamesFor('Hombros'), isNotEmpty);
    });
  });
}
