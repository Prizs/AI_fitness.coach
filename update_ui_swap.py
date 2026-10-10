import sys
import re

path = 'mobile_app/lib/screens/workouts_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Update signature of _openExercisePreview to pass dayIndex
old_open = '''void _openExercisePreview(BuildContext context, Map<String, dynamic> item, List<dynamic> exercises) async {'''
new_open = '''void _openExercisePreview(BuildContext context, Map<String, dynamic> item, List<dynamic> exercises, int dayIndex) async {'''
text = text.replace(old_open, new_open)

old_call = '''onPressed: () => _openExercisePreview(context, item, exercises),'''
new_call = '''onPressed: () => _openExercisePreview(context, item, exercises, _selectedDay),'''
text = text.replace(old_call, new_call)

old_sheet_call = '''builder: (ctx) => _Exercise3DPreviewSheet(exercise: item, dynamicExercises: dyn),'''
new_sheet_call = '''builder: (ctx) => _Exercise3DPreviewSheet(exercise: item, dynamicExercises: dyn, dayIndex: dayIndex),'''
text = text.replace(old_sheet_call, new_sheet_call)

old_sheet_def = '''class _Exercise3DPreviewSheet extends StatefulWidget {
  const _Exercise3DPreviewSheet({required this.exercise, this.dynamicExercises});
  final Map<String, dynamic> exercise;
  final List<AnatomyExercise>? dynamicExercises;'''
new_sheet_def = '''class _Exercise3DPreviewSheet extends StatefulWidget {
  const _Exercise3DPreviewSheet({required this.exercise, this.dynamicExercises, required this.dayIndex});
  final Map<String, dynamic> exercise;
  final List<AnatomyExercise>? dynamicExercises;
  final int dayIndex;'''
text = text.replace(old_sheet_def, new_sheet_def)

# Add Swap Button
old_btn = '''          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),'''
new_btn = '''          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
              side: const BorderSide(color: Colors.orangeAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              // Swap exercise logic
              final currentName = widget.exercise['name'] as String? ?? '';
              final primaryMuscle = widget.exercise['primary_muscle'] as String? ?? 'General';
              
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              final newEx = await WeeklyPlanService.instance.swapExercise(currentName, primaryMuscle, widget.dayIndex);
              if (context.mounted) Navigator.pop(context); // close dialog
              
              if (newEx != null && context.mounted) {
                 Navigator.pop(context); // close sheet
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cambiado por: \')));
              } else if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cambiar ejercicio')));
              }
            },
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Máquina Ocupada (Cambiar)', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),'''
text = text.replace(old_btn, new_btn)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
