/// Calculadora metabólica para ejercicios de fuerza y calistenia.
/// Basada en modelos de gasto energético total (aeróbico + anaeróbico láctico/aláctico + EPOC de recuperación)
/// validados en fisiología del ejercicio (Dr. Christopher B. Scott, ACSM, Ainsworth Compendium of Physical Activities).
class MetabolicCalculator {
  /// Calcula las calorías reales estimadas para un ejercicio por serie.
  ///
  /// - Multiarticular masivo (sentadillas, peso muerto, burpees, zancadas): ~6.5 - 9.0 kcal / serie
  /// - Multiarticular de torso (flexiones, dominadas, remos, presses): ~4.2 - 5.5 kcal / serie
  /// - Core y estabilización (planchas, dead bug, crunches): ~3.0 - 3.8 kcal / serie
  /// - Aislamiento muscular pequeño (gemelos, sóleo, bíceps, tríceps, hombro lateral): ~1.8 - 2.8 kcal / serie
  static int estimateCalories({
    required String exerciseName,
    required int sets,
    double userWeight = 75.0,
    String intensityLevel = 'Media',
  }) {
    final nameLower = exerciseName.toLowerCase();

    final isHeavyCompound = nameLower.contains('burpee') ||
        nameLower.contains('sentadilla') ||
        nameLower.contains('squat') ||
        nameLower.contains('peso muerto') ||
        nameLower.contains('deadlift') ||
        nameLower.contains('prensa') ||
        nameLower.contains('zancada') ||
        nameLower.contains('lunge') ||
        nameLower.contains('step-up') ||
        nameLower.contains('hip thrust');

    final isMediumCompound = nameLower.contains('flexion') ||
        nameLower.contains('push-up') ||
        nameLower.contains('dominada') ||
        nameLower.contains('pull-up') ||
        nameLower.contains('remo') ||
        nameLower.contains('row') ||
        nameLower.contains('press') ||
        nameLower.contains('fondo') ||
        nameLower.contains('dips') ||
        nameLower.contains('escalador') ||
        nameLower.contains('mountain climber') ||
        nameLower.contains('jumping jack') ||
        nameLower.contains('cardio') ||
        nameLower.contains('buenos d');

    final isCore = nameLower.contains('plancha') ||
        nameLower.contains('plank') ||
        nameLower.contains('dead bug') ||
        nameLower.contains('crunch') ||
        nameLower.contains('abdomen') ||
        nameLower.contains('oblicuo') ||
        nameLower.contains('core');

    double baseKcalPerSet;
    if (isHeavyCompound) {
      baseKcalPerSet = 6.8;
    } else if (isMediumCompound) {
      baseKcalPerSet = 4.6;
    } else if (isCore) {
      baseKcalPerSet = 3.2;
    } else {
      // Grupos aislados: Sóleo, gemelos, batatas, bíceps, tríceps, deltoides lateral
      baseKcalPerSet = 2.2;
    }

    final intLow = intensityLevel.toLowerCase();
    double intensityFactor = 1.0;
    if (intLow.contains('alta') || intLow.contains('avanzado')) {
      intensityFactor = 1.25;
    } else if (intLow.contains('baja') || intLow.contains('básico') || intLow.contains('basico')) {
      intensityFactor = 0.85;
    }

    final weightFactor = (userWeight / 75.0).clamp(0.65, 1.45);

    final total = (sets * baseKcalPerSet * intensityFactor * weightFactor).round();
    return total.clamp(4, 75);
  }

  /// Estima los gramos de grasa corporal oxidados (~38% de la energía de recuperación entre series y EPOC).
  /// 1 g de grasa = 9 kcal.
  static double estimateFatGrams(int calories) {
    return (calories * 0.38) / 9.0;
  }
}
