/// Traduce el nombre de musculo que devuelve la IA a los identificadores
/// anatomicos del atlas (`flutter_body_atlas`).
///
/// Los identificadores fueron verificados contra el catalogo del paquete para
/// evitar referencias a musculos inexistentes.
class MuscleMap {
  MuscleMap._();

  /// Grupos de musculos con sus IDs del atlas (izquierda y derecha).
  static const Map<String, List<String>> groups = {
    'cuadriceps': [
      'rectus_femoris_l',
      'rectus_femoris_r',
      'vastus_lateralis_l',
      'vastus_lateralis_r',
      'vastus_medialis_l',
      'vastus_medialis_r',
    ],
    'isquiotibiales': [
      'biceps_femoris_l',
      'biceps_femoris_r',
      'semitendinosus_l',
      'semitendinosus_r',
      'semimembranosus_1_l',
      'semimembranosus_1_r',
      'semimembranosus_2_l',
      'semimembranosus_2_r',
    ],
    'gluteos': [
      'gluteus_maximus_l',
      'gluteus_maximus_r',
      'gluteus_medius_1_l',
      'gluteus_medius_1_r',
      'gluteus_medius_2_l',
      'gluteus_medius_2_r',
    ],
    'gemelos': ['gastrocnemius_l', 'gastrocnemius_r'],
    'tibial_anterior': ['tibialis_anterior_l', 'tibialis_anterior_r'],
    'aductores': [
      'adductor_longus_l',
      'adductor_longus_r',
      'adductor_magnus_l',
      'adductor_magnus_r',
      'gracilis_l',
      'gracilis_r',
    ],
    'pectoral': ['pectoralis_major_l', 'pectoralis_major_r'],
    'dorsal_ancho': ['latissimus_dorsi_l', 'latissimus_dorsi_r'],
    'biceps': [
      'biceps_brachii_caput_longum_l',
      'biceps_brachii_caput_longum_r',
      'biceps_brachii_caput_breve_l',
      'biceps_brachii_caput_breve_r',
    ],
    'triceps': [
      'triceps_brachii_caput_longum_l',
      'triceps_brachii_caput_longum_r',
      'triceps_brachii_caput_laterale_l',
      'triceps_brachii_caput_laterale_r',
      'triceps_brachii_caput_mediale_l',
      'triceps_brachii_caput_mediale_r',
    ],
    'hombros': [
      'anterior_deltoid_l',
      'anterior_deltoid_r',
      'lateral_deltoid_l',
      'lateral_deltoid_r',
      'posterior_deltoid_l',
      'posterior_deltoid_r',
    ],
    'core': [
      'rectus_abdominis_1_l',
      'rectus_abdominis_1_r',
      'rectus_abdominis_2_l',
      'rectus_abdominis_2_r',
      'external_oblique_1_l',
      'external_oblique_1_r',
      'external_oblique_2_l',
      'external_oblique_2_r',
      'external_oblique_3_l',
      'external_oblique_3_r',
      'external_oblique_4_l',
      'external_oblique_4_r',
      'external_oblique_5_l',
      'external_oblique_5_r',
      'external_oblique_6_l',
      'external_oblique_6_r',
      'external_oblique_7_l',
      'external_oblique_7_r',
      'external_oblique_8_l',
      'external_oblique_8_r',
    ],
    'espalda': [
      'trapezius_upper_l',
      'trapezius_upper_r',
      'trapezius_middle_l',
      'trapezius_middle_r',
      'trapezius_lower_l',
      'trapezius_lower_r',
      'infraspinatus_l',
      'infraspinatus_r',
    ],
    'cuello': ['sternocleidomastoid_l', 'sternocleidomastoid_r'],
  };

  /// Palabras clave (en español o ingles) que identifican cada grupo.
  static const Map<String, List<String>> keywords = {
    'cuadriceps': ['cuadriceps', 'cuádriceps', 'quad', 'vasto', 'recto anterior', 'pierna frontal'],
    'isquiotibiales': [
      'isquio',
      'isquiotibial',
      'isquiotibiales',
      'hamstring',
      'femoral',
      'femorales',
      'biceps femoral',
      'bíceps femoral',
      'semitendinoso',
      'semimembranoso',
      'femoral posterior',
      'posterior del muslo',
    ],
    'gluteos': ['gluteo', 'glute', 'nalga', 'cadera', 'hip'],
    'gemelos': ['gemelo', 'gastrocnemio', 'calf', 'pantorrilla'],
    'tibial_anterior': ['tibial', 'tibialis'],
    'aductores': ['aductor', 'muslo interno'],
    'pectoral': [
      'pectoral',
      'pecho',
      'pectoralis',
      'empuje',
      'push',
      'press de pecho',
    ],
    'dorsal_ancho': [
      'dorsal',
      'latissimus',
      'espalda',
      'remo',
      'row',
      'pull',
      'tiron',
    ],
    'biceps': ['biceps', 'flexion de codo'],
    'triceps': ['triceps', 'extension de codo'],
    'hombros': [
      'hombro',
      'deltoid',
      'shoulder',
      'press',
      'elevacion lateral',
    ],
    'core': [
      'core',
      'abdominal',
      'abdomen',
      'planche',
      'estabilidad',
      'antebrazo',
      'diafragma',
    ],
    'espalda': ['trapecio', 'trapezius', 'postura', 'erector'],
    'cuello': ['cuello', 'neck', 'esternocleidomastoideo'],
  };

  /// Devuelve los IDs del atlas que corresponden al musculo indicado.
  ///
  /// Si el texto no coincide con ningun grupo devuelve un conjunto vacio para
  /// que la vista siga funcionando sin resaltados.
  static Set<String> idsFor(String? muscleText) {
    if (muscleText == null || muscleText.trim().isEmpty) return const {};
    final text = _normalize(muscleText);
    final ids = <String>{};
    keywords.forEach((group, words) {
      if (words.any((word) => text.contains(_normalize(word)))) {
        ids.addAll(groups[group]!);
      }
    });
    return ids;
  }

  /// Nombres legibles de los grupos activados, para mostrarlos en pantalla.
  static List<String> groupNamesFor(String? muscleText) {
    if (muscleText == null || muscleText.trim().isEmpty) return const [];
    final text = _normalize(muscleText);
    return keywords.entries
        .where(
          (entry) =>
              entry.value.any((word) => text.contains(_normalize(word))),
        )
        .map((entry) => _prettyName(entry.key))
        .toList();
  }

  static String _normalize(String value) {
    final lower = value.toLowerCase();
    // Quita acentos para comparar "cuádriceps" con "cuadriceps".
    return lower
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  static String _prettyName(String group) {
    const names = {
      'cuadriceps': 'Cuádriceps',
      'isquiotibiales': 'Isquiotibiales',
      'gluteos': 'Glúteos',
      'gemelos': 'Gemelos',
      'tibial_anterior': 'Tibial anterior',
      'aductores': 'Aductores',
      'pectoral': 'Pectoral',
      'dorsal_ancho': 'Dorsal ancho',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'hombros': 'Hombros / deltoides',
      'core': 'Core',
      'espalda': 'Espalda alta',
      'cuello': 'Cuello',
    };
    return names[group] ?? group;
  }
}
