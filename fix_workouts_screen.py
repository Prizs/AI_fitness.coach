import sys
import re

path = 'mobile_app/lib/screens/workouts_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add imports
if 'package:http/http.dart' not in text:
    text = text.replace("import 'package:mobile_app/widgets/exercise_detail.dart';", "import 'package:mobile_app/widgets/exercise_detail.dart';\nimport 'package:mobile_app/models/anatomy_exercise.dart';\nimport 'package:http/http.dart' as http;\nimport 'dart:convert';")

# 2. Modify onPressed in ListTile
old_onpressed = "onPressed: () => _openExercisePreview(context, item),"
new_onpressed = "onPressed: () => _openExercisePreview(context, item, exercises),"
text = text.replace(old_onpressed, new_onpressed)

# 3. Modify _openExercisePreview signature and body
old_preview = '''  void _openExercisePreview(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _Exercise3DPreviewSheet(exercise: item),
    );
  }'''

new_preview = '''  void _openExercisePreview(BuildContext context, Map<String, dynamic> item, List<dynamic> exercises) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    List<AnatomyExercise> dyn = [];
    for (var e in exercises) {
      final ex = Map<String, dynamic>.from(e as Map);
      final exName = ex['name'] as String? ?? 'Ejercicio';
      final primary = ex['primary_muscle'] as String? ?? 'General';
      final secondary = ex['secondary_muscle'] as String? ?? 'Secundario';
      
      String url = '';
      try {
        final res = await http.get(Uri.parse('https://ai-fitness-coach-818a.onrender.com/api/exercises/gif?query=' + Uri.encodeComponent(exName)));
        if (res.statusCode == 200) {
          url = jsonDecode(res.body)['url'] ?? '';
        }
      } catch (_) {}
      
      dyn.add(AnatomyExercise(
        id: exName,
        name: exName,
        shortName: exName,
        gifUrl: url,
        agonist: primary,
        synergists: [secondary],
        biomechanics: 'Activación dinámica sugerida por IA.',
        tempo: '3-1-1',
        posture: 'Mantén la postura natural.',
        warning: 'Consulta a tu entrenador si sientes dolor.'
      ));
    }
    
    if (!context.mounted) return;
    Navigator.pop(context); // close dialog
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _Exercise3DPreviewSheet(exercise: item, dynamicExercises: dyn),
    );
  }'''

text = text.replace(old_preview, new_preview)

# 4. Modify _Exercise3DPreviewSheet and its state
old_sheet = '''class _Exercise3DPreviewSheet extends StatefulWidget {
  const _Exercise3DPreviewSheet({required this.exercise});
  final Map<String, dynamic> exercise;

  @override
  State<_Exercise3DPreviewSheet> createState() =>
      _Exercise3DPreviewSheetState();
}'''

new_sheet = '''class _Exercise3DPreviewSheet extends StatefulWidget {
  const _Exercise3DPreviewSheet({required this.exercise, this.dynamicExercises});
  final Map<String, dynamic> exercise;
  final List<AnatomyExercise>? dynamicExercises;

  @override
  State<_Exercise3DPreviewSheet> createState() =>
      _Exercise3DPreviewSheetState();
}'''

text = text.replace(old_sheet, new_sheet)

old_detail = '''          ExerciseDetailView(
            animationKey: animKey,
            primaryMuscle: widget.exercise['primary_muscle'] as String?,
            secondaryMuscle: widget.exercise['secondary_muscle'] as String?,
            height: 300,
          ),'''

new_detail = '''          ExerciseDetailView(
            animationKey: name, // We use 'name' as ID now!
            primaryMuscle: widget.exercise['primary_muscle'] as String?,
            secondaryMuscle: widget.exercise['secondary_muscle'] as String?,
            height: 300,
            dynamicExercises: widget.dynamicExercises,
          ),'''

text = text.replace(old_detail, new_detail)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
