/// Base de datos de planes de alimentación diversificados, accesibles y económicos
/// basados en guías nutricionales reconocidas (OMS, ISSN, Dieta Mediterránea y Flexible).
class NutritionDatabase {
  static const List<Map<String, dynamic>> goals = [
    {
      'id': 'musculo',
      'label': '💪 Masa Muscular',
      'title': 'Aumento de Masa Muscular (Hipertrofia Limpia)',
      'description': 'Superávit calórico controlado (+300 kcal), 1.8-2.2g proteína/kg y alimentos ricos en nutrientes de fácil acceso.',
      'principles': 'Aporte proteico en cada comida, carbohidratos complejos para rendimiento en fuerza y grasas saludables.',
      'color': 0xFF8BE0C0,
    },
    {
      'id': 'grasa',
      'label': '🔥 Bajar de Peso',
      'title': 'Pérdida de Grasa / Definición Sostenible',
      'description': 'Déficit calórico moderado (-350 kcal), alta densidad nutricional, saciedad por fibra y proteína magra.',
      'principles': 'Prioridad a vegetales fibrosos, proteína saciante y carbohidratos de bajo índice glucémico sin pasar hambre.',
      'color': 0xFFFFB340,
    },
    {
      'id': 'resistencia',
      'label': '🏃 Resistencia Cardio',
      'title': 'Rendimiento Cardiovascular & Capacidad Aeróbica',
      'description': 'Combustible sostenido de glucógeno, hidratación con electrolitos naturales y rápida recuperación.',
      'principles': 'Carbohidratos de absorción sostenida antes del cardio, antioxidantes y digestión ligera.',
      'color': 0xFF60A5FA,
    },
    {
      'id': 'salud',
      'label': '🥗 Salud & Energía',
      'title': 'Equilibrio Metabólico & Recomposición Saludable',
      'description': 'Basado en principios de Dieta Mediterránea y Alimentación Intuitiva con ingredientes de mercado local.',
      'principles': 'Grasas monoinsaturadas, legumbres accesibles, frutas de temporada y reducción de ultraprocesados.',
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

  static Map<String, dynamic> _getMusclePlan(
      int day, bool isTraining, Map<String, dynamic> goal) {
    final mealsByDay = [
      // Lunes
      [
        {
          'title': '🍳 Desayuno Constructor',
          'items': [
            '3 huevos enteros revueltos con tomate y cebolla o espinaca',
            '1 taza de avena en hojuelas cocida con canela y 1 cambur (plátano)',
            'Vaso de agua 400 ml o café negro sin azúcar',
          ],
        },
        {
          'title': '🍛 Almuerzo Anabólico',
          'items': [
            '180 g de pechuga de pollo a la plancha o muslo deshuesado',
            '1.5 tazas de arroz blanco o integral cocido',
            '1/2 taza de caraotas negras o frijoles guisados',
            'Ensalada fresca rallada con unas gotas de aceite de oliva o maíz',
          ],
        },
        {
          'title': '🍌 Merienda / Pre-Entreno',
          'items': [
            '2 rebanadas de pan integral o 1 arepa mediana de maíz',
            'Queso blanco bajo en sal o 1 lata de atún al natural',
            '1 fruta fresca (naranja o manzana)',
          ],
        },
        {
          'title': '🍲 Cena de Recuperación Miofibrilar',
          'items': [
            '160 g de carne magra molida o pescado a la plancha',
            '1 taza de batata o papa cocida al vapor',
            'Porción abundante de brócoli, calabacín o zanahorias salteadas',
          ],
        },
      ],
      // Martes
      [
        {
          'title': '🍳 Desayuno Energético',
          'items': [
            'Arepa mediana rellena con 2 huevos revueltos y queso fresco',
            '1 taza de papaya o lechosa picada',
            'Té verde o café sin azúcar + 350 ml de agua',
          ],
        },
        {
          'title': '🍛 Almuerzo Completo',
          'items': [
            '180 g de carne de res magra o pollo guisado con papas',
            '1.5 tazas de pasta o arroz con vegetales',
            'Ensalada mixta (lechuga, pepino y tomate)',
          ],
        },
        {
          'title': '🥜 Merienda Nutritiva',
          'items': [
            '1 taza de yogur natural con 3 cucharadas de avena y semillas o maní',
            '1 cambur en rodajas',
          ],
        },
        {
          'title': '🍲 Cena Ligera y Reparadora',
          'items': [
            'Tortilla de 3 huevos con espinacas y cebollín',
            '1 plátano maduro horneado o sancochado',
            'Ensalada verde con aguacate fresco',
          ],
        },
      ],
      // Miércoles
      [
        {
          'title': '🍳 Desayuno Potente',
          'items': [
            'Panquecas caseras de avena (1 taza de avena licuada con 2 huevos y cambur)',
            '1 vaso de leche descremada o bebida de soya',
            'Agua fresca 400 ml',
          ],
        },
        {
          'title': '🍛 Almuerzo de Fuerza',
          'items': [
            '180 g de pollo al horno con especias',
            '1 taza grande de lentejas guisadas con zanahoria',
            '1 taza de arroz blanco',
            'Ensalada de repollo morado y zanahoria',
          ],
        },
        {
          'title': '🥪 Merienda Práctica',
          'items': [
            'Sándwich con atún o sardinas desmenuzadas con limón',
            '1 vaso de jugo de naranja natural sin azúcar',
          ],
        },
        {
          'title': '🍲 Cena Hipertrófica',
          'items': [
            '170 g de filete de pescado blanco o pollo a la plancha',
            'Puré de papas casero (1 taza)',
            'Vegetales verdes salteados al ajillo',
          ],
        },
      ],
      // Jueves
      [
        {
          'title': '🍳 Desayuno Proteico',
          'items': [
            'Revuelto de 3 huevos con champiñones o pimientos',
            '2 tostadas integrales o 1 arepa de avena',
            'Fruta de temporada (melón o piña)',
          ],
        },
        {
          'title': '🍛 Almuerzo Rendimiento',
          'items': [
            '180 g de lomo de cerdo magro o pechuga de pollo',
            '1.5 tazas de arroz con maíz tierno',
            'Porción de garbanzos o frijoles',
            'Ensalada verde crujiente',
          ],
        },
        {
          'title': '🍌 Merienda Pre-Fuerza',
          'items': [
            'Batido casero: 1 cambur, 1 vaso de leche/agua, 3 cucharadas de avena y 1 cda de mantequilla de maní',
          ],
        },
        {
          'title': '🍲 Cena de Síntesis Proteica',
          'items': [
            '160 g de carne magra en fajitas con pimentón y cebolla',
            '1 taza de yuca o batata cocida',
            'Ensalada de aguacate y tomate',
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
            'Café con un toque de canela + 400 ml de agua',
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
            'Tazón de yogur con granola económica o avena tostada',
            '1 manzana o pera picada',
          ],
        },
        {
          'title': '🍲 Cena Reconstituyente',
          'items': [
            '160 g de pescado a la plancha o atún',
            '1 papa grande al horno con hierbas',
            'Calabacín y berenjenas a la plancha',
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
            'Sancocho o sopa ligera de res/pollo con verduras (ñame, ocumo o papa)',
            'Porción de carne o pollo magro adicional (120 g)',
            'Arroz blanco 1 taza',
          ],
        },
        {
          'title': '🥪 Merienda Práctica',
          'items': [
            'Arepita tostada con revoltillo de huevo o queso',
            'Fruta fresca de temporada',
          ],
        },
        {
          'title': '🍲 Cena Ligera Anabólica',
          'items': [
            '160 g de pechuga desmechada o carne magra',
            'Ensalada abundante con aguacate y maíz',
            '1 rebanada de pan tostado o arepa pequeña',
          ],
        },
      ],
      // Domingo
      [
        {
          'title': '🍳 Desayuno Descanso Activo',
          'items': [
            'Huevos pericos (2 huevos revueltos con tomate y cebollín)',
            '1 arepa asada mediana con aguacate',
            'Infusión natural o café negro sin azúcar',
          ],
        },
        {
          'title': '🍛 Almuerzo Familiar Balanceado',
          'items': [
            'Pollo al horno o carne asada 180 g',
            'Yuca con mojo ligero o puré de batata 1 taza',
            'Ensalada fresca mixta con vinagreta de limón',
          ],
        },
        {
          'title': '🍌 Merienda Regenerativa',
          'items': [
            '1 cambur con un puñado pequeño de frutos secos o maní tostado sin sal',
            'Agua fresca 400 ml',
          ],
        },
        {
          'title': '🍲 Cena Digestiva y Anticatabólica',
          'items': [
            'Sopa o crema de auyama/calabaza con 120 g de pollo desmechado',
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
          ? '🔥 Día de Entrenamiento: Mayor disponibilidad de carbohidratos complejos en el almuerzo y merienda para potenciar la fuerza y recargar el glucógeno muscular.'
          : '🧘 Día de Recuperación: Balance proteico elevado (1.8g/kg) para optimizar la síntesis proteica miofibrilar y reparar fibras musculares.',
      'meals': mealsByDay[dayIndex],
    };
  }

  static Map<String, dynamic> _getFatLossPlan(
      int day, bool isTraining, Map<String, dynamic> goal) {
    final meals = [
      {
        'title': '🍳 Desayuno Saciante',
        'items': [
          '3 claras de huevo + 1 huevo entero revuelto con espinacas y cebolla',
          '1 rebanada de pan integral o 1/2 arepa pequeña delgada',
          'Café negro o té verde sin azúcar + 500 ml de agua',
        ],
      },
      {
        'title': '🍛 Almuerzo Hipocalórico Denso',
        'items': [
          '160 g de pechuga de pollo o pescado blanco a la plancha',
          '1/2 taza de arroz integral o 1 papa mediana cocida',
          'Plato grande de ensalada verde (lechuga, pepino, espinaca) con 1 cdta de aceite de oliva y vinagre',
        ],
      },
      {
        'title': '🍎 Merienda Anti-Ansiedad',
        'items': [
          '1 manzana verde o 1 taza de melón/sandía picada',
          '1 vaso de yogur natural sin azúcar o 1 huevo duro',
          'Infusión de manzanilla o té de menta',
        ],
      },
      {
        'title': '🍲 Cena Ligera Digestiva',
        'items': [
          '150 g de atún al natural o pollo desmechado',
          'Crema de calabacín o auyama sin crema ni lácteos grasos',
          'Vegetales al vapor (brócoli o espárragos) con limón',
        ],
      },
    ];

    return {
      'goal': goal['title'],
      'synergy':
          '🔥 Déficit calórico inteligente: Alta saciedad mediante fibra vegetal y proteína magra. Evita picos de insulina manteniendo un gasto lipídico óptimo.',
      'meals': meals,
    };
  }

  static Map<String, dynamic> _getCardioPlan(
      int day, bool isTraining, Map<String, dynamic> goal) {
    final meals = [
      {
        'title': '🍳 Desayuno Glucogénico Ligero',
        'items': [
          '1 tazón de avena cocida con agua y leche descremada, canela y 1 cambur maduro',
          '2 huevos duros (aporte de aminoácidos esenciales)',
          'Vaso grande de agua 500 ml con pizca de sal marina (electrolitos)',
        ],
      },
      {
        'title': '🍛 Almuerzo de Resistencia',
        'items': [
          '150 g de pechuga de pavo o pollo a la plancha con hierbas',
          '1.5 tazas de pasta o arroz con salsa de tomate natural',
          'Ensalada fresca de remolacha rallada y zanahoria (óxido nítrico natural)',
        ],
      },
      {
        'title': '🍌 Pre/Post Cardio Snack',
        'items': [
          '1 rebanada de pan integral con miel natural o 1 cambur',
          'Agua de coco natural o 400 ml de agua fresca',
        ],
      },
      {
        'title': '🍲 Cena Reparadora Ligera',
        'items': [
          '140 g de pescado blanco o pollo al vapor',
          '1 taza de batata horneada (recarga suave de glucógeno)',
          'Sopa ligera de vegetales y calabacín',
        ],
      },
    ];

    return {
      'goal': goal['title'],
      'synergy':
          '🏃 Enfoque de Resistencia: Glucógeno muscular sostenido, digestión ágil sin pesadez estomacal y reposición de electrolitos para prevenir calambres.',
      'meals': meals,
    };
  }

  static Map<String, dynamic> _getHealthPlan(
      int day, bool isTraining, Map<String, dynamic> goal) {
    final meals = [
      {
        'title': '🍳 Desayuno Mediterráneo Accesible',
        'items': [
          '2 huevos revueltos con tomate, orégano y unas gotas de aceite de oliva',
          '1 rebanada de pan integral tostado con aguacate triturado',
          'Té verde o café sin azúcar + 400 ml de agua',
        ],
      },
      {
        'title': '🍛 Almuerzo Completo y Antiinflamatorio',
        'items': [
          '150 g de sardinas frescas, atún o pollo al limón',
          '1 taza de lentejas o garbanzos guisados con vegetales',
          '1/2 taza de arroz integral o batata sancochada',
          'Ensalada fresca con repollo, zanahoria y limón',
        ],
      },
      {
        'title': '🍊 Merienda Antioxidante',
        'items': [
          '1 porción de frutas de temporada (naranja, mandarina o lechosa)',
          'Un puñado pequeño de maní o semillas de auyama tostadas',
        ],
      },
      {
        'title': '🍲 Cena Equilibrada y Tranquila',
        'items': [
          'Tortilla de espinacas y cebollín con 2 huevos',
          'Ensalada de tomate y pepino con aceite de oliva',
          'Infusión tibia de manzanilla o toronjil para descanso reparador',
        ],
      },
    ];

    return {
      'goal': goal['title'],
      'synergy':
          '🥗 Salud Integral: Alimentos naturales no ultraprocesados de mercado local, ricos en fibra prebiótica, grasas saludables y micronutrientes esenciales.',
      'meals': meals,
    };
  }
}
