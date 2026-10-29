# 🚀 ESTADO DEL PROYECTO Y GUÍA DE CONTINUIDAD PARA ANTIGRAVITY (AGY)

> **Repositorio GitHub:** `https://github.com/Prizs/AI_fitness.coach.git`  
> **Rama principal:** `main`  
> **Última actualización:** 2026-10-29  
> **Objetivo General:** Software de Tesis Universitaria de Ingeniería - Coach de Fitness con IA, prescripción biomecánica y periodización neuromuscular adaptativa.

---

## 💻 ¿CÓMO EJECUTAR DIRECTO EN TU LAPTOP CON 1 SOLO CLIC?

Hemos creado un archivo ejecutable automatizado en la raíz del proyecto:
**`CONTINUAR_DESARROLLO_LAPTOP.bat`**

### Instrucciones para llegar a tu laptop:
1. Si aún no clonaste el repo en tu laptop:
   ```bash
   git clone https://github.com/Prizs/AI_fitness.coach.git
   cd AI_fitness.coach
   ```
2. **Haz doble clic sobre el archivo `CONTINUAR_DESARROLLO_LAPTOP.bat`** (o ejecútalo desde la consola).
   Este archivo automáticamente:
   - Hace `git pull origin main` para traer todos los últimos cambios.
   - Verifica tu entorno Python e instala cualquier dependencia requerida (`backend/requirements.txt`).
   - Ejecuta el banco de pruebas de integridad (`python backend/test_coach_e2e.py`).
   - Inicia el servidor FastAPI local en el puerto 8000.
   - Abre tu navegador automáticamente en `http://localhost:8000`.

---

## 📌 PROMPT EXACTO PARA COPIAR Y PEGAR EN ANTIGRAVITY EN TU LAPTOP:

Copia y pega el siguiente bloque de texto en el chat de Antigravity en tu laptop si deseas continuar programando:

```markdown
Hola Antigravity. Estoy continuando el desarrollo de mi software de tesis AI Fitness Coach en mi laptop.
Por favor lee este prompt y el archivo `PROMPT_CONTINUIDAD_AGY.md` en la raíz del proyecto.

### CONTEXTO DEL SISTEMA:
- Stack: Backend FastAPI (Python 3.11) desplegado en Render (`https://ai-fitness-coach-818a.onrender.com`), Frontend Flutter Web/Mobile desplegado y sincronizado en `backend/app/web_dist/`.
- Repositorio: `https://github.com/Prizs/AI_fitness.coach.git` en rama `main`.
- Base de datos de GIFs: Más de 1.300 ejercicios GymVisual en `https://raw.githubusercontent.com/JahelCuadra/exercises-gifs-and-images/master/exercises/` y en `/static/`.
- Motor Coach IA: Archivo `backend/app/routers/coach.py`.
- Base de GIFs e Intensidad: `backend/app/routers/exercises.py`.
- Servicio de Cronograma y Rutinas: `mobile_app/lib/services/weekly_plan_service.dart`.
- Base de Datos Local Cache: `mobile_app/lib/database/db_helper.dart`.
- Pantalla de Rutinas: `mobile_app/lib/screens/workouts_screen.dart`.
- Pantalla del Coach: `mobile_app/lib/screens/coach_screen.dart`.
- Script de Ejecución 1-Clic: `CONTINUAR_DESARROLLO_LAPTOP.bat`.
- Banco de Pruebas Automatizadas E2E: `python backend/test_coach_e2e.py`.

### LO QUE SE ACABA DE RESOLVER CON ÉXITO:
1. **DEDUPLICACIÓN RADICAL AL 100% (EJERCICIOS Y GIFS):**
   - Se eliminó la reutilización de nombres o GIFs a lo largo de los 5 días de la semana y en la misma jornada.
   - Tanto para Full Body (Cuerpo Completo) sin equipamiento como para divisiones musculares estándar: 20 de 20 y 26 de 26 ejercicios con nombres y GIFs únicos garantizados.
   - Se corrigieron los mapeos de Flexiones Declinadas (`pectorals/decline-push-up.gif`) y Superman / Extensiones lumbares (`spine/hyperextension.gif`).
   - Verificado con `test_coach_e2e.py` arrojando [SUCCESS] en cada ejecución.

2. **SISTEMA MULTI-CICLO INTELIGENTE (Ciclo Activo vs. Próximo Ciclo Programado):**
   - Si el usuario interactúa con Coach IA y ya tiene un ciclo activo vigente (ej. 26/10 al 01/11), el nuevo plan se asigna automáticamente como **Próximo Ciclo** (`upcomingWeek`) sin alterar ni sobreescribir la rutina actual del atleta.
   - Se reconoce automáticamente si pide fechas futuras (ej. "semana del 9/11 al 13/11", "a partir del 2/11", "próxima semana").
   - **Excepción explícita:** Si el atleta pide explícitamente "cambiar ciclo actual", "reemplazar rutina actual" o "reiniciar semana", el sistema actualiza de inmediato el ciclo activo vigente.
   - **Auto-promoción de Ciclos:** Al llegar el día de inicio del próximo ciclo (`today >= cycle_start_date`), la aplicación promueve automáticamente el ciclo futuro a ciclo activo principal.
   - **Frontend UI:** Se añadió en `workouts_screen.dart` la tarjeta desplegable `_UpcomingCycleCard` (Próximo Ciclo Programado) con desglose de días, ejercicios, botón de activación manual y botón de descarte.

3. **COMPILACIÓN Y SINCRONIZACIÓN WEB:**
   - Flutter web compilado en modo release (`mobile_app/build/web`).
   - Sincronizado al 100% en `backend/app/web_dist/` para servir directamente desde FastAPI.

Por favor indícame qué requerimiento deseas afinar o probar a continuación.
```

---

## 🔄 ¿CÓMO REGRESAR A ESTA PC DE ESCRITORIO DESPUÉS?

Cuando termines en tu laptop y hagas `git push origin main`, simplemente cuando vuelvas a esta PC de escritorio, abre la terminal y ejecuta:

```powershell
git pull origin main
```
¡Y todo el código estará 100% sincronizado y actualizado!
