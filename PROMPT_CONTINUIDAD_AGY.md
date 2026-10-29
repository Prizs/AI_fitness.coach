# 🚀 ESTADO DEL PROYECTO Y PROMPT DE CONTINUIDAD PARA ANTIGRAVITY (AGY)

> **Repositorio GitHub:** `https://github.com/Prizs/AI_fitness.coach.git`  
> **Rama principal:** `main`  
> **Última actualización:** 2026-10-29  
> **Objetivo General:** Software de Tesis Universitaria de Ingeniería - Coach de Fitness con IA, prescripción biomecánica y periodización neuromuscular adaptativa.

---

## 📋 ¿CÓMO ABRIR EL PROYECTO EN TU LAPTOP?

En tu laptop, abre la terminal o Antigravity y ejecuta:
```bash
git clone https://github.com/Prizs/AI_fitness.coach.git
cd AI_fitness.coach
```
*(Si ya lo tenías clonado en tu laptop, solo haz `git pull origin main`).*

---

## 📌 PROMPT EXACTO PARA COPIAR Y PEGAR EN ANTIGRAVITY EN TU LAPTOP:

Copia y pega el siguiente bloque de texto en el chat de Antigravity en tu laptop:

```markdown
Hola Antigravity. Estoy continuando el desarrollo de mi software de tesis AI Fitness Coach.
Lee por favor este prompt y el archivo `PROMPT_CONTINUIDAD_AGY.md` en la raíz del proyecto.

### CONTEXTO DEL SISTEMA:
- Stack: Backend FastAPI (Python 3.11) desplegado en Render (`https://ai-fitness-coach-818a.onrender.com`), Frontend Flutter Web/Mobile desplegado y sincronizado en `backend/app/web_dist/`.
- Repositorio: `https://github.com/Prizs/AI_fitness.coach.git` en rama `main`.
- Base de datos de GIFs: Más de 1.300 ejercicios reales GymVisual en `https://raw.githubusercontent.com/JahelCuadra/exercises-gifs-and-images/master/exercises/` y en `/static/`.
- Motor Coach IA: Archivo `backend/app/routers/coach.py`.
- Servicio de Cronograma y Rutinas: `mobile_app/lib/services/weekly_plan_service.dart`.
- Pantalla de Rutinas: `mobile_app/lib/screens/workouts_screen.dart`.
- Pantalla del Coach: `mobile_app/lib/screens/coach_screen.dart`.

### LO QUE SE ACABA DE RESOLVER CON ÉXITO:
1. Timeouts de IA eliminados (se redujo timeout acumulativo a 12s en `backend/app/services/ai_providers.py`).
2. Se corrigió el NameError en el fallback local inteligente de `coach.py`.
3. Se garantizó que la restricción de "sin herramientas" / calistenia en casa se memorice e inspeccione desde el historial (`payload.history`), evitando que se cuelen mancuernas o máquinas si el usuario presiona un botón rápido.

### TAREAS ACTIVAS PENDIENTES POR TERMINAR AHORA:
1. **PLANIFICACIÓN MULTICICLO POR FECHAS (Ciclo Activo vs. Próximo Ciclo Programado):**
   - El usuario solicita planificar para semanas o fechas futuras (ejemplo real: *"para la semana comprendida del 9/11 al viernes 13/11"* o *"para la próxima semana"*).
   - En `backend/app/routers/coach.py`: Extraer las fechas solicitadas (`start_date`, `end_date`, `range_str`, `is_future_cycle: True`) y enviarlas en `structured_plan`.
   - En `mobile_app/lib/services/weekly_plan_service.dart`: Soportar `upcomingWeek` (Próximo ciclo programado) guardado en local cache/storage además de `week` (Ciclo activo actual). Si el plan es futuro, guardarlo en `upcomingWeek` sin sobreescribir el ciclo en curso. Cuando llegue la fecha de inicio del ciclo próximo, debe promoverse automáticamente como ciclo activo principal.
   - En `mobile_app/lib/screens/workouts_screen.dart`: Mostrar el banner del **🟢 CICLO ACTIVO** (ej. 26/10 al 01/11), y abajo una tarjeta desplegable/expandible del **📅 PRÓXIMO CICLO PROGRAMADO** (ej. 09/11 al 13/11) donde el atleta puede ver de antemano lo que tiene planificado para esa semana.

2. **DIVERSIFICACIÓN ABSOLUTA Y CERO REPETICIÓN (DE EJERCICIOS Y DE GIFS):**
   - Problema reportado: Hay ejercicios que tienen nombres ligeramente diferentes pero enlazan al MISMO GIF (ej. Sentadilla profunda y Sentadilla sumo con el mismo GIF), repitiéndose el mismo ejercicio con otro nombre el mismo día.
   - Solución obligatoria:
     a) En `_normalize_exercises`: Llevar control estricto de `seen_exercise_names` Y de `seen_gif_urls`. Si un candidato usa un GIF que ya se utilizó en el día, descartarlo y elegir otro ejercicio con un GIF completamente distinto.
     b) Entre días de la semana: Ningún día debe repetir ejercicios ni GIFs de los días anteriores de la misma semana.
   - Enfoque "Cuerpo Completo" (Full Body): Si el usuario pide *"cuerpo completo"* o *"full body"*, reconocerlo en `_detect_requested_focus` y estructurar los 5 días con variantes balanceadas y diferentes de cuerpo completo (Lunes: Empuje/Cuádriceps, Martes: Tracción/Isquios, Miércoles: Glúteos/Hombros/Core, Jueves: Unilateral/Tríceps, Viernes: Movilidad/Bombeo/Cardio).

Por favor, continúa directamente con la implementación de estas dos tareas, compila Flutter web, sincroniza con `backend/app/web_dist/`, haz commit y push a `main`.
```

---

## 🔄 ¿CÓMO REGRESAR A ESTA PC DE ESCRITORIO DESPUÉS?

Cuando termines en tu laptop y hagas `git push origin main`, simplemente cuando vuelvas a esta PC de escritorio, abre la terminal y ejecuta:

```powershell
git pull origin main
```
Y todo el código estará 100% sincronizado y actualizado.
