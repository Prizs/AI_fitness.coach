import os
import re

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix _load to NOT auto-generate
load_pattern = r'        // 2\. Si no hay cache, descargar de internet\n        await _fetchAndSave\(profile\);\n      } catch \(error\) \{'
load_new = '''        // 2. Si no hay cache, no autogeneramos.
        week = null;
        lastError = null;
        isLoading = false;
        _pending = null;
        notifyListeners();
      } catch (error) {'''

text = re.sub(load_pattern, load_new, text)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

# Now fix workouts_screen.dart empty state
screen_path = 'mobile_app/lib/screens/workouts_screen.dart'
with open(screen_path, 'r', encoding='utf-8') as f:
    screen = f.read()

# Replace _EmptyState usage inside _buildBody
body_old = '''      return _EmptyState(
        message: _service.lastError ?? 'No se pudo cargar la semana.',
        onRetry: () => showPlanOptionsSheet(context),
      );'''

body_new = '''      if (_service.lastError != null) {
        return _EmptyState(
          message: _service.lastError!,
          onRetry: () => _service.refresh(AuthService.instance.loggedInUser),
          isError: true,
        );
      }
      
      return _EmptyState(
        message: 'Aún no tienes una rutina activa.\\n\\nPresiona el botón de abajo para que la IA diseñe un plan personalizado a tu nivel, disponibilidad y equipo.',
        onRetry: () => showPlanOptionsSheet(context),
        isError: false,
      );'''

screen = screen.replace(body_old, body_new)

# Update _EmptyState widget to support isError
empty_old = '''class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 46, color: Color(0xFFFF7A7A)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),
              foregroundColor: const Color(0xFF0B1220),
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}'''

empty_new = '''class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry, this.isError = true});

  final String message;
  final VoidCallback onRetry;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.cloud_off_rounded : Icons.fitness_center_rounded,
              size: 56, 
              color: isError ? const Color(0xFFFF7A7A) : const Color(0xFF8BE0C0)
            ),
            const SizedBox(height: 16),
            Text(
              isError ? 'Error de Carga' : 'Bienvenido',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.5)),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8BE0C0),
                foregroundColor: const Color(0xFF0B1220),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              ),
              onPressed: onRetry,
              icon: Icon(isError ? Icons.refresh_rounded : Icons.add_rounded),
              label: Text(isError ? 'Reintentar' : 'Crear mi rutina', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}'''

screen = screen.replace(empty_old, empty_new)

with open(screen_path, 'w', encoding='utf-8') as f:
    f.write(screen)
