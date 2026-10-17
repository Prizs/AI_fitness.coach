/// Base de datos de planes de alimentación diversificados, accesibles y económicos
/// adaptados 100% al mercado local venezolano (ingredientes cotidianos y económicos:
/// arepa de maíz, huevos pericos, pollo, carne molida magra, atún, sardinas, caraotas,
/// lentejas, arroz, batata, yuca, plátano verde o maduro, avena, cambur, lechosa y aguacate criollo).
class NutritionDatabase {
  static const List<Map<String, dynamic>> goals = [
    {
      'id': 'musculo',
      'label': '💪 Masa Muscular',
      'title': 'Aumento de Masa Muscular (Hipertrofia Limpia)',
      'description': 'Superávit calórico controlado con proteína accesible de mercado venezolano, carbohidratos densos y grasas saludables.',
      'principles': 'Arepas, avena con cambur, huevos enteros o pericos, pollo, carne molida, caraotas negras, arroz, batata, yuca y plátano maduro.',
      'color': 0xFF8BE0C0,
    },
    {
      'id': 'grasa',
      'label': '🔥 Bajar de Peso',
      'title': 'Pérdida de Grasa / Definición Sostenible',
      'description': 'Déficit calórico saciante priorizando vegetales de mercado (repollo, pepino, tomate, calabacín, chayota) y proteína magra local.',
      'principles': 'Huevos sancochados o pericos, pollo a la plancha, atún, sardinas, arepas delgadas con afrecho y sopas de verduras sin grasa.',
      'color': 0xFFFFB340,
    },
    {
      'id': 'resistencia',
      'label': '🏃 Resistencia Cardio',
      'title': 'Rendimiento Cardiovascular & Capacidad Aeróbica',
      'description': 'Combustible sostenido de glucógeno con tubérculos criollos, avena, frutas locales hidratantes y reposición de electrolitos.',
      'principles': 'Avena con cambur, batata horneada, plátano sancochado, pasta o arroz con granos y ensaladas de remolacha (óxido nítrico).',
      'color': 0xFF60A5FA,
    },
    {
      'id': 'salud',
      'label': '🥗 Salud & Energía',
      'title': 'Equilibrio Metabólico & Recomposición Saludable',
      'description': 'Principios de Dieta Mediterránea adaptados a ingredientes venezolanos frescos, ricos en omega-3 accesible y fibra prebiótica.',
      'principles': 'Sardinas frescas o atún, caraotas, lentejas, aguacate criollo, huevos de granja, vegetales salteados y frutas de temporada.',
      'color': 0xFFF472B6,
    },
  ];

  static Map<String, dynamic> getPlanForDay({
    required String goalId,
    required int weekday, // 0 = Lunes ... 6 = Domingo
    required bool isTrainingDay,
  }) {
    final effectiveGoal = goals.firstWhere(
      (g) => g['id'] == goalId,
      orElse: () => goals[0],
    );

    switch (goalId) {
      case 'musculo':
        return _getMusclePlan(weekday, isTrainingDay, effectiveGoal);
      case 'grasa':
        return _getFatLossPlan(weekday, isTrainingDay, effectiveGoal);
      case 'resistencia':
        return _getCardioPlan(weekday, isTrainingDay, effectiveGoal);
      case 'salud':
      default:
        return _getHealthPlan(weekday, isTrainingDay, effectiveGoal);
    }
  }

  // =========================================================================
  // 1. MASA MUSCULAR (7 DÍAS CON ALIMENTOS DE VENEZUELA)
  // =========================================================================
  static Map<String, dynamic> _getMusclePlan(int day, bool isTraining, Map<String, dynamic> goal) {
    final mealsByDay = [
      // Lunes
      [
        {
          'title': '🍳 Desayuno Constructor',
          'items': [
            '3 huevos revueltos con tomate y cebolla (perico criollo) + 1 arepa asada mediana con queso blanco rallado',
            '1 taza de avena en hojuelas cocida con canela y 1 cambur picado',
            'Café negro o con leche descremada sin azúcar + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Anabólico Criollo',
          'items': [
            '180 g de pechuga de pollo a la plancha o muslo deshuesado dorado',
            '1.5 tazas de arroz blanco cocido',
            '1/2 taza de caraotas negras guisadas con comino y ajo',
            'Tajada de plátano asado o hervido + ensalada fresca de repollo, tomate y limón',
          ],
        },
        {
          'title': '🥪 Merienda / Pre-Entreno',
          'items': [
            '1 arepa mediana rellena con queso blanco bajo en sal o 1 lata de atún con limón',
            '1 cambur maduro o 1 porción de lechosa fresca',
          ],
        },
        {
          'title': '🍲 Cena de Recuperación Muscular',
          'items': [
            '160 g de carne molida magra guisada con calabacín, pimentón y cebolla',
            '1 taza de batata o yuca hervida con un toque de aceite de maíz u oliva',
            'Ensalada de aguacate criollo con tomate',
          ],
        },
      ],
      // Martes
      [
        {
          'title': '🍳 Desayuno Energético',
          'items': [
            'Arepa asada mediana rellena con 2 huevos revueltos y queso blanco paisa o llanero',
            '1 taza de lechosa o patilla picada en cubos',
            'Café sin azúcar + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Completo de Fuerza',
          'items': [
            '180 g de carne magra guisada con papas y zanahoria',
            '1.5 tazas de pasta corta o arroz blanco con vegetales',
            'Ensalada fresca de pepino, tomate y lechuga con limón',
          ],
        },
        {
          'title': '🥜 Merienda Nutritiva',
          'items': [
            'Avena tibia espesa con cambur y un puñado de maní tostado criollo sin sal',
            'Vaso grande de agua fresca',
          ],
        },
        {
          'title': '🍲 Cena Ligera y Reparadora',
          'items': [
            'Tortilla de 3 huevos con acelga o espinaca y cebollín',
            '1 plátano maduro horneado o sancochado',
            'Porción de aguacate criollo fresco',
          ],
        },
      ],
      // Miércoles
      [
        {
          'title': '🍳 Desayuno Potente',
          'items': [
            'Panquecas caseras de avena (1 taza de avena licuada con 2 huevos y 1 cambur maduro)',
            'Queso blanco fresco rallado (40 g)',
            'Café o infusión natural + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo de Fuerza',
          'items': [
            '180 g de pollo al horno sazonado con ajo y orégano',
            '1 taza grande de lentejas guisadas con zanahoria y calabacín',
            '1 taza de arroz blanco',
            'Ensalada rallada de zanahoria y repollo con limón',
          ],
        },
        {
          'title': '🥪 Merienda Práctica',
          'items': [
            'Arepita tostada o sándwich con atún desmenuzado, tomate y limón',
            '1 jugo de naranja o guayaba natural sin azúcar añadida',
          ],
        },
        {
          'title': '🍲 Cena Hipertrófica',
          'items': [
            '170 g de pescado blanco (merluza o corvina) a la plancha con ajo',
            'Puré casero de papas (1 taza)',
            'Vegetales salteados (calabacín, pimentón y cebolla)',
          ],
        },
      ],
      // Jueves
      [
        {
          'title': '🍳 Desayuno Proteico',
          'items': [
            'Revuelto de 3 huevos con cebolla, pimentón y cilantro',
            '1 arepa mediana de maíz con afrecho o avena',
            'Fruta fresca de temporada (lechosa, melón o piña)',
          ],
        },
        {
          'title': '🍛 Almuerzo Rendimiento',
          'items': [
            '180 g de lomo de cerdo magro o pechuga de pollo a la plancha',
            '1.5 tazas de arroz blanco con maíz tierno',
            'Porción de frijoles bayos o caraotas guisadas',
            'Ensalada verde crujiente de lechuga y pepino',
          ],
        },
        {
          'title': '🍌 Merienda Pre-Fuerza',
          'items': [
            'Batido casero: 1 cambur maduro, agua o leche descremada, 3 cucharadas de avena en hojuelas y 1 cda de maní',
          ],
        },
        {
          'title': '🍲 Cena de Síntesis Proteica',
          'items': [
            '160 g de carne magra en tiritas salteadas con pimentón y cebolla',
            '1 taza de yuca o batata cocida',
            'Ensalada de tomate fresco con aguacate criollo',
          ],
        },
      ],
      // Viernes
      [
        {
          'title': '🍳 Desayuno Rápido y Nutritivo',
          'items': [
            '3 huevos cocidos o pochados',
            '1 arepa mediana con queso blanco y rodajas de tomate',
            'Café con toque de canela + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Fuerte de Cierre',
          'items': [
            '180 g de pollo en salsa casera de tomate natural',
            '1.5 tazas de pasta corta o arroz con caraotas',
            'Ensalada de lechuga romana, pepino y limón',
          ],
        },
        {
          'title': '🥜 Merienda Energética',
          'items': [
            'Avena tibia con cambur machacado y canela en polvo',
            '1 fruta fresca de temporada (guayaba o mandarina)',
          ],
        },
        {
          'title': '🍲 Cena Reconstituyente',
          'items': [
            '160 g de pescado a la plancha o atún aliñado',
            '1 papa grande hervida o asada con hierbas',
            'Calabacín y berenjenas a la plancha con ajo',
          ],
        },
      ],
      // Sábado
      [
        {
          'title': '🍳 Desayuno de Fin de Semana',
          'items': [
            'Tortilla completa de 3 huevos con queso blanco y cilantro',
            'Avena tibia con cambur machacado y canela',
            'Vaso de agua 400 ml',
          ],
        },
        {
          'title': '🍛 Almuerzo Nutritivo Casero',
          'items': [
            'Sancocho o sopa ligera de res/pollo con verduras criollas (ñame, auyama, ocumo)',
            'Porción de carne o pollo magro adicional (120 g)',
            'Arroz blanco 1 taza + aguacate criollo',
          ],
        },
        {
          'title': '🥪 Merienda Práctica',
          'items': [
            'Arepita tostada con revoltillo de huevo o queso blanco',
            'Fruta fresca de temporada (lechosa o patilla)',
          ],
        },
        {
          'title': '🍲 Cena Ligera Anabólica',
          'items': [
            '160 g de pechuga desmechada o carne magra guisada',
            'Ensalada abundante con aguacate y tomate',
            '1 casabe tostado o arepa pequeña de maíz',
          ],
        },
      ],
      // Domingo
      [
        {
          'title': '🍳 Desayuno Descanso Activo',
          'items': [
            'Huevos pericos (2 huevos revueltos con tomate y cebollín)',
            '1 arepa asada mediana con aguacate y queso blanco',
            'Infusión natural o café negro sin azúcar',
          ],
        },
        {
          'title': '🍛 Almuerzo Familiar Balanceado',
          'items': [
            'Pollo al horno o carne asada 180 g',
            'Yuca con mojo ligero de ajo o puré de batata 1 taza',
            'Ensalada fresca mixta con vinagreta de limón',
          ],
        },
        {
          'title': '🍌 Merienda Regenerativa',
          'items': [
            '1 cambur con un puñado pequeño de maní tostado criollo sin sal',
            'Agua fresca 400 ml',
          ],
        },
        {
          'title': '🍲 Cena Digestiva y Anticatabólica',
          'items': [
            'Sopa o crema de auyama con 120 g de pollo desmechado',
            '2 huevos cocidos',
            'Ensalada verde con limón',
          ],
        },
      ],
    ];

    final dayIndex = day.clamp(0, 6);
    return {
      'goal': goal['title'],
      'synergy': isTraining
          ? '🔥 Día de Entrenamiento: Mayor disponibilidad de carbohidratos complejos en almuerzo y merienda (arepa, arroz, caraotas, batata) para potenciar la fuerza y recargar el glucógeno muscular.'
          : '🧘 Día de Recuperación: Balance proteico elevado (1.8-2.2 g/kg) con huevos, pollo, carne y queso blanco criollo para optimizar la síntesis proteica y reparar fibras musculares.',
      'meals': mealsByDay[dayIndex],
    };
  }

  // =========================================================================
  // 2. BAJAR DE PESO / DEFINICIÓN (7 DÍAS CON ALIMENTOS DE VENEZUELA)
  // =========================================================================
  static Map<String, dynamic> _getFatLossPlan(int day, bool isTraining, Map<String, dynamic> goal) {
    final mealsByDay = [
      // Lunes
      [
        {
          'title': '🍳 Desayuno Saciante Criollo',
          'items': [
            '3 claras + 1 huevo entero en perico (tomate y cebolla con poco aceite)',
            '1/2 arepa pequeña asada fina (con afrecho o avena)',
            'Café negro o té verde sin azúcar + 500 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Hipocalórico Denso',
          'items': [
            '160 g de pechuga de pollo a la plancha con limón y orégano',
            '1/2 taza de arroz blanco cocido',
            'Plato grande de ensalada de repollo, pepino y tomate con vinagreta de limón',
          ],
        },
        {
          'title': '🍎 Merienda Anti-Ansiedad',
          'items': [
            '1 taza de lechosa o patilla picada en cubos',
            'Infusión de manzanilla o té de menta fría',
          ],
        },
        {
          'title': '🍲 Cena Ligera Digestiva',
          'items': [
            '1 lata de atún al natural con cebolla picada y cilantro',
            'Crema de auyama o calabacín ligera (sin lácteos grasos)',
            'Chayota y calabacín al vapor con limón',
          ],
        },
      ],
      // Martes
      [
        {
          'title': '🍳 Desayuno Proteico Ligero',
          'items': [
            '2 huevos sancochados (duros) con pizca de sal',
            '1/2 arepita asada delgada',
            'Café negro sin azúcar + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Saciante con Granos',
          'items': [
            '150 g de carne molida magra guisada con calabacín rallado y tomate',
            '1/2 taza de caraotas negras (fibra saciante sin manteca)',
            'Ensalada fresca de lechuga, pepino y zanahoria',
          ],
        },
        {
          'title': '🍊 Merienda Hidratante',
          'items': [
            '1 naranja o mandarina fresca en gajos',
            'Vaso grande de agua fría',
          ],
        },
        {
          'title': '🍲 Cena Reparadora Hipocalórica',
          'items': [
            '150 g de pollo desmechado con ajo y hierbas',
            'Sopa ligera de vegetales criollos (auyama y calabacín)',
            'Rodajita pequeña de aguacate criollo',
          ],
        },
      ],
      // Miércoles
      [
        {
          'title': '🍳 Desayuno Fit de Avena',
          'items': [
            'Panqueca ligera: 2 cdas de avena licuada con 2 huevos y canela en polvo',
            'Café negro o té verde sin azúcar + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Marino Ligero',
          'items': [
            '170 g de pescado blanco (merluza/corvina) a la plancha con ajo y perejil',
            '1/2 taza de lentejas guisadas con zanahoria',
            'Ensalada mixta abundante de repollo morado y pepino',
          ],
        },
        {
          'title': '🍌 Merienda Energética Controlada',
          'items': [
            '1 cambur pequeño o medio cambur',
            'Vaso de agua fresca',
          ],
        },
        {
          'title': '🍲 Cena Verde Liviana',
          'items': [
            'Tortilla de 2 huevos con acelgas o espinacas y cebollín',
            'Ensalada de tomate, pepino y vinagre de manzana',
          ],
        },
      ],
      // Jueves
      [
        {
          'title': '🍳 Desayuno Perico Criollo',
          'items': [
            'Revuelto de 2 huevos con tomate, cebolla y pimentón',
            '1/2 arepa de maíz asada delgada',
            'Café negro o té sin azúcar + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Quemagrasa',
          'items': [
            '160 g de pechuga de pollo a la plancha en tiras',
            '1/2 taza de batata hervida (carbohidrato de bajo impacto glucémico)',
            'Plato grande de ensalada verde crujiente con limón',
          ],
        },
        {
          'title': '🍉 Merienda Refrescante',
          'items': [
            '1 taza de patilla o melón picado en cubos',
            'Té frío de limón sin azúcar',
          ],
        },
        {
          'title': '🍲 Cena Depurativa',
          'items': [
            '1 lata de atún al natural desmenuzado con limón',
            'Ensalada tibia de vainitas y zanahoria sancochada',
            'Crema de calabacín casera',
          ],
        },
      ],
      // Viernes
      [
        {
          'title': '🍳 Desayuno Rápido y Saciante',
          'items': [
            'Avena cocida en agua con canela (3 cucharadas) + 2 huevos duros',
            'Café negro sin azúcar + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo de Res Magra',
          'items': [
            '150 g de carne magra a la plancha o bisteck encebollado',
            '1/2 taza de arroz blanco',
            'Ensalada rallada de repollo, zanahoria y limón',
          ],
        },
        {
          'title': '🍊 Merienda Rica en Fibra',
          'items': [
            '1 guayaba fresca o 1 mandarina',
            'Infusión de manzanilla o té verde',
          ],
        },
        {
          'title': '🍲 Cena Quema-Calorías',
          'items': [
            '150 g de pollo desmechado con ajo',
            'Ensalada de tomate fresco con rodaja de aguacate criollo',
          ],
        },
      ],
      // Sábado
      [
        {
          'title': '🍳 Desayuno de Fin de Semana',
          'items': [
            '2 huevos pochados o revueltos con cilantro',
            '1/2 arepa fina tostada',
            'Vaso grande de agua fresca con unas gotas de limón',
          ],
        },
        {
          'title': '🍛 Almuerzo Sancocho Ligero',
          'items': [
            'Sopa casera de pollo desgrasada con auyama, ñame y calabacín',
            'Porción de pechuga de pollo (120 g) con limón',
            'Ensalada verde fresca',
          ],
        },
        {
          'title': '🍈 Merienda Natural',
          'items': [
            '1 taza de lechosa fresca picada',
            'Agua fresca 400 ml',
          ],
        },
        {
          'title': '🍲 Cena Ligera Anti-Hinchazón',
          'items': [
            '2 huevos cocidos sobre ensalada tibia de vainitas y zanahorias',
            'Té de manzanilla para un sueño profundo y reparador',
          ],
        },
      ],
      // Domingo
      [
        {
          'title': '🍳 Desayuno Relajado Saciante',
          'items': [
            'Tortilla de 2 huevos con cebollín y tomate',
            'Café negro sin azúcar + 500 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Familiar Fit',
          'items': [
            '160 g de pollo al horno sazonado con orégano y ajo',
            '1/2 taza de arroz blanco con caraotas',
            'Plato abundante de ensalada mixta con vinagre y limón',
          ],
        },
        {
          'title': '🍊 Merienda Cero Ansiedad',
          'items': [
            '1 naranja en gajos o 1 mandarina',
            'Vaso grande de agua fría',
          ],
        },
        {
          'title': '🍲 Cena Ligera de Cierre',
          'items': [
            'Atún al natural aliñado con limón, perejil y cebolla picada',
            'Ensalada de repollo morado, pepino y aguacate criollo',
          ],
        },
      ],
    ];

    final dayIndex = day.clamp(0, 6);
    return {
      'goal': goal['title'],
      'synergy':
          '🔥 Déficit calórico inteligente adaptado a Venezuela: Alta saciedad con vegetales frescos de mercado y proteína magra (huevos, pollo, atún, sardinas). Evita picos de insulina y maximiza la quema de grasa sin pasar hambre ni recurrir a productos costosos.',
      'meals': mealsByDay[dayIndex],
    };
  }

  // =========================================================================
  // 3. RESISTENCIA CARDIO & RENDIMIENTO AERÓBICO (7 DÍAS CON ALIMENTOS DE VZLA)
  // =========================================================================
  static Map<String, dynamic> _getCardioPlan(int day, bool isTraining, Map<String, dynamic> goal) {
    final mealsByDay = [
      // Lunes
      [
        {
          'title': '🍳 Desayuno Glucogénico Ligero',
          'items': [
            '1 tazón de avena en hojuelas cocida con canela y 1 cambur maduro en rodajas',
            '2 huevos duros (aporte de aminoácidos para los músculos)',
            'Vaso grande de agua 500 ml con pizca de sal marina (electrolitos naturales)',
          ],
        },
        {
          'title': '🍛 Almuerzo de Resistencia Criollo',
          'items': [
            '160 g de pechuga de pollo a la plancha con ajo y hierbas',
            '1.5 tazas de pasta o arroz con salsa casera de tomate natural',
            'Ensalada fresca de remolacha rallada y zanahoria (óxido nítrico para oxigenación)',
          ],
        },
        {
          'title': '🍌 Pre/Post Cardio Snack',
          'items': [
            '1 cambur maduro o 1 arepita pequeña con queso blanco',
            'Agua fresca 400 ml',
          ],
        },
        {
          'title': '🍲 Cena Reparadora Ligera',
          'items': [
            '150 g de pescado blanco o pollo al vapor',
            '1 taza de batata horneada (recarga suave de glucógeno muscular)',
            'Sopa ligera de vegetales y calabacín',
          ],
        },
      ],
      // Martes a Domingo adaptados con glucógeno y digestión ágil
      [
        {
          'title': '🍳 Desayuno Energético',
          'items': [
            'Arepa mediana asada con huevos pericos y aguacate',
            '1 cambur o vaso de jugo de lechosa natural',
            'Café o infusión + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Cardiovascular',
          'items': [
            '160 g de carne magra guisada con papas',
            '1 taza de arroz con lentejas o caraotas',
            'Ensalada de repollo, pepino y zanahoria con limón',
          ],
        },
        {
          'title': '🍊 Merienda Hidratante',
          'items': [
            '1 naranja fresca en gajos + agua de coco o agua fresca 400 ml',
          ],
        },
        {
          'title': '🍲 Cena de Recuperación Aeróbica',
          'items': [
            '150 g de pollo a la plancha',
            'Puré de batata o yuca hervida',
            'Ensalada verde con limón',
          ],
        },
      ],
      [
        {
          'title': '🍳 Desayuno Potente Cardio',
          'items': [
            'Panquecas de avena y cambur con 2 huevos',
            'Agua fresca 500 ml + café negro',
          ],
        },
        {
          'title': '🍛 Almuerzo de Resistencia Marina',
          'items': [
            '170 g de pescado a la plancha o atún',
            '1.5 tazas de pasta con vegetales salteados',
            'Ensalada de remolacha y zanahoria cocida',
          ],
        },
        {
          'title': '🍌 Snack Pre-Carrera / Cardio',
          'items': [
            '1 cambur maduro con puñado de maní tostado',
          ],
        },
        {
          'title': '🍲 Cena Ligera Regenerativa',
          'items': [
            'Tortilla de 3 huevos con espinacas y cebollín',
            '1 plátano maduro sancochado',
            'Ensalada de tomate y pepino',
          ],
        },
      ],
      [
        {
          'title': '🍳 Desayuno de Carga Suave',
          'items': [
            'Avena tibia con cambur machacado + 2 huevos cocidos',
            'Vaso grande de agua 500 ml',
          ],
        },
        {
          'title': '🍛 Almuerzo Energético Criollo',
          'items': [
            'Pollo al horno 170 g con papas asadas',
            '1 taza de arroz con caraotas negras',
            'Ensalada verde con limón',
          ],
        },
        {
          'title': '🍉 Snack Hidratante',
          'items': [
            '1 porción abundante de patilla fresca (excelente hidratación)',
          ],
        },
        {
          'title': '🍲 Cena Antifatiga',
          'items': [
            'Pechuga desmechada con cebolla y pimentón',
            'Puré de papas casero + aguacate criollo',
          ],
        },
      ],
      [
        {
          'title': '🍳 Desayuno Ágil',
          'items': [
            '1 arepa mediana con queso blanco y 2 huevos revueltos',
            '1 fruta fresca (naranja o mandarina)',
            'Café + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo de Fondo Aeróbico',
          'items': [
            'Carne magra salteada con vegetales y arroz blanco',
            'Plátano maduro hervido (potasio contra calambres)',
            'Ensalada de repollo y zanahoria',
          ],
        },
        {
          'title': '🍌 Snack Pre-Trote',
          'items': [
            '1 cambur con 2 galletas de soda o arepita pequeña',
          ],
        },
        {
          'title': '🍲 Cena de Recarga Nocturna',
          'items': [
            'Pescado a la plancha con yuca hervida',
            'Sopa ligera de vegetales criollos',
          ],
        },
      ],
      [
        {
          'title': '🍳 Desayuno de Fondo Largo',
          'items': [
            'Avena cocida con cambur y canela + 2 huevos sancochados',
            'Vaso de agua grande con pizca de sal',
          ],
        },
        {
          'title': '🍛 Almuerzo Recuperador Completo',
          'items': [
            'Sancocho casero de res/pollo con verduras criollas (ñame, ocumo, auyama)',
            'Porción de carne magra o pollo con arroz blanco',
          ],
        },
        {
          'title': '🍊 Snack Post-Cardio',
          'items': [
            'Jugo de naranja natural sin azúcar + agua fresca',
          ],
        },
        {
          'title': '🍲 Cena Relajante Muscular',
          'items': [
            'Tortilla de huevos con cebollín y calabacín',
            'Batata hervida + aguacate criollo',
          ],
        },
      ],
      [
        {
          'title': '🍳 Desayuno Domingo Regenerativo',
          'items': [
            'Huevos pericos con 1 arepa asada mediana',
            'Fruta fresca (lechosa o melón)',
            'Café o infusión natural',
          ],
        },
        {
          'title': '🍛 Almuerzo Balanceado Aeróbico',
          'items': [
            'Pollo al horno con arroz y ensalada fresca con aguacate',
            '1 taza de lentejas o caraotas guisadas',
          ],
        },
        {
          'title': '🍌 Merienda Digestiva',
          'items': [
            '1 cambur maduro con agua fresca',
          ],
        },
        {
          'title': '🍲 Cena Ligera Reparadora',
          'items': [
            'Crema de auyama con pollo desmechado y 2 huevos cocidos',
            'Infusión de manzanilla para optimizar el descanso',
          ],
        },
      ],
    ];

    final dayIndex = day.clamp(0, 6);
    return {
      'goal': goal['title'],
      'synergy':
          '🏃 Enfoque de Resistencia adaptado a Venezuela: Carbohidratos energéticos de rápida asimilación (avena, cambur, plátano, arroz, batata) que reponen glucógeno, potasio natural contra calambres y digestión ágil sin pesadez estomacal.',
      'meals': mealsByDay[dayIndex],
    };
  }

  // =========================================================================
  // 4. SALUD & ENERGÍA (DIETA MEDITERRÁNEA ADAPTADA A MERCADO VENEZOLANO)
  // =========================================================================
  static Map<String, dynamic> _getHealthPlan(int day, bool isTraining, Map<String, dynamic> goal) {
    final mealsByDay = [
      // Lunes
      [
        {
          'title': '🍳 Desayuno Mediterráneo Criollo',
          'items': [
            '2 huevos revueltos con tomate, orégano y un toque de aceite de oliva o maíz',
            '1 arepa mediana de maíz con semillas de auyama o afrecho + queso blanco rallado',
            'Té verde o café sin azúcar + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Completo y Antiinflamatorio',
          'items': [
            '160 g de sardinas frescas guisadas con tomate y cebolla, o pollo al limón',
            '1 taza de lentejas o caraotas guisadas con vegetales',
            '1/2 taza de arroz blanco o batata sancochada',
            'Ensalada fresca de repollo, zanahoria y limón',
          ],
        },
        {
          'title': '🍊 Merienda Antioxidante',
          'items': [
            '1 porción de frutas de temporada (naranja, mandarina, guayaba o lechosa)',
            'Un puñado pequeño de maní criollo tostado sin sal',
          ],
        },
        {
          'title': '🍲 Cena Equilibrada y Tranquila',
          'items': [
            'Tortilla de espinacas y cebollín con 2 huevos de granja',
            'Ensalada de tomate y pepino con aguacate criollo',
            'Infusión tibia de manzanilla o toronjil para descanso reparador',
          ],
        },
      ],
      // Martes
      [
        {
          'title': '🍳 Desayuno Vital',
          'items': [
            'Avena en hojuelas cocida con canela y rodajas de cambur fresco',
            '2 huevos sancochados con cilantro',
            'Café negro o té sin azúcar',
          ],
        },
        {
          'title': '🍛 Almuerzo Saludable de Mercado',
          'items': [
            '160 g de pollo a la plancha sazonado con cúrcuma y ajo',
            '1 taza de arroz con frijoles o caraotas',
            'Ensalada verde con aguacate criollo y limón',
          ],
        },
        {
          'title': '🍈 Merienda Digestiva',
          'items': [
            '1 taza de lechosa picada con unas gotas de limón',
            'Agua fresca 400 ml',
          ],
        },
        {
          'title': '🍲 Cena Anti-Estrés',
          'items': [
            'Pescado a la plancha con puré de auyama casero',
            'Calabacín salteado al ajillo con cebolla',
          ],
        },
      ],
      // Miércoles a Domingo
      [
        {
          'title': '🍳 Desayuno Nutritivo',
          'items': [
            'Panquecas caseras de avena con 2 huevos y canela',
            'Queso blanco fresco (30 g)',
            'Café o infusión natural',
          ],
        },
        {
          'title': '🍛 Almuerzo Longevidad Criolla',
          'items': [
            '160 g de pescado blanco o atún con cebolla y tomate',
            '1 taza de lentejas guisadas con zanahoria',
            'Ensalada de repollo morado, pepino y limón',
          ],
        },
        {
          'title': '🍉 Snack Hidratante',
          'items': [
            '1 taza de patilla fresca en trozos',
          ],
        },
        {
          'title': '🍲 Cena Liviana y Saludable',
          'items': [
            'Tortilla de 2 huevos con acelgas y queso blanco',
            'Ensalada fresca de tomate y aguacate criollo',
          ],
        },
      ],
      [
        {
          'title': '🍳 Desayuno Perico Saludable',
          'items': [
            'Huevos pericos con tomate, cebolla y pimentón',
            '1 arepa asada mediana con aguacate',
            'Infusión natural + 400 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Protector Cardiovascular',
          'items': [
            'Pollo al horno con hierbas criollas y ajo',
            '1/2 taza de arroz blanco + caraotas negras',
            'Ensalada de remolacha y zanahoria',
          ],
        },
        {
          'title': '🍊 Merienda Vitamina C',
          'items': [
            '1 guayaba fresca o 1 naranja en gajos',
          ],
        },
        {
          'title': '🍲 Cena Reparadora',
          'items': [
            'Crema de calabacín con atún desmenuzado y limón',
            'Casabe tostado o arepita pequeña',
          ],
        },
      ],
      [
        {
          'title': '🍳 Desayuno Completo Criollo',
          'items': [
            '2 huevos cocidos + 1 arepa mediana con queso blanco',
            '1 fruta fresca de temporada',
            'Café negro sin azúcar',
          ],
        },
        {
          'title': '🍛 Almuerzo Energético Sano',
          'items': [
            'Carne magra a la plancha con cebolla y pimentón',
            'Batata hervida (1 taza)',
            'Ensalada verde con limón y aceite',
          ],
        },
        {
          'title': '🥜 Snack Saludable',
          'items': [
            '1 cambur maduro con un puñado de maní tostado criollo',
          ],
        },
        {
          'title': '🍲 Cena Calma y Balance',
          'items': [
            'Pechuga de pollo a la plancha con ensalada de pepino y aguacate',
            'Té tibio de manzanilla',
          ],
        },
      ],
      [
        {
          'title': '🍳 Desayuno Sabatino de Bienestar',
          'items': [
            'Tortilla de 3 huevos con cilantro y tomate',
            'Avena tibia con canela',
            'Agua fresca 400 ml',
          ],
        },
        {
          'title': '🍛 Almuerzo Casero Nutritivo',
          'items': [
            'Sancocho ligero de res/pollo desgrasado con verduras (auyama, ocumo, ñame)',
            'Porción de carne magra + arroz blanco',
          ],
        },
        {
          'title': '🍈 Snack Ligero',
          'items': [
            '1 taza de lechosa o melón fresco',
          ],
        },
        {
          'title': '🍲 Cena Equilibrada',
          'items': [
            'Pescado a la plancha o atún con ensalada mixta y aguacate',
          ],
        },
      ],
      [
        {
          'title': '🍳 Desayuno Dominical Armonioso',
          'items': [
            'Huevos pericos con 1 arepa asada mediana con queso blanco',
            'Café negro o con leche descremada',
          ],
        },
        {
          'title': '🍛 Almuerzo Familiar Mediterráneo Criollo',
          'items': [
            'Pollo al horno con yuca sancochada',
            'Ensalada mixta abundante de tomate, pepino, repollo y aguacate criollo',
          ],
        },
        {
          'title': '🍊 Snack Refrescante',
          'items': [
            '1 mandarina o naranja fresca',
          ],
        },
        {
          'title': '🍲 Cena Ligera de Cierre Semanal',
          'items': [
            'Sopa o crema de auyama con 120 g de pollo desmechado',
            '2 huevos cocidos y té de manzanilla',
          ],
        },
      ],
    ];

    final dayIndex = day.clamp(0, 6);
    return {
      'goal': goal['title'],
      'synergy':
          '🥗 Salud Integral adaptada a Venezuela: Alimentos no ultraprocesados de mercado local (sardinas, caraotas, lentejas, huevos, aguacate criollo, verduras frescas) ricos en omega-3 accesible, fibra prebiótica y micronutrientes para máximo bienestar y energía.',
      'meals': mealsByDay[dayIndex],
    };
  }
}
