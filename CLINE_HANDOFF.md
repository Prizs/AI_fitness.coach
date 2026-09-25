# AI Fitness Coach - Handoff para Cline

Fecha del traspaso: 2026-09-24
Repositorio: https://github.com/Prizs/AI_fitness.coach
Rama activa: `main`
Raiz local: `C:\Users\Usuario\ai_fitness_coach`

## Instruccion principal

Continua el desarrollo desde el estado existente. No reescribas el proyecto desde cero. Antes de editar, lee los archivos afectados y revisa `git status`. Hay modificaciones locales pendientes en varias pantallas Flutter; no las reviertas ni las sobrescribas sin entenderlas.

Despues de cada cambio funcional:

1. Ejecuta una validacion enfocada.
2. Ejecuta `flutter analyze` o compilacion backend segun corresponda.
3. Ejecuta los tests disponibles.
4. Haz `git add`, `git commit` y `git push` a `origin/main`, excepto si hay cambios ajenos sin resolver que puedan entrar en el commit.
5. Nunca incluyas `.env`, contrasenas, claves API ni tokens.

## Arquitectura

- `backend/`: FastAPI + Python 3.11.
- `mobile_app/`: Flutter/Dart para Android y Web.
- `database/supabase_schema.sql`: esquema idempotente de Supabase.
- `backend/scripts/migrate_supabase.py`: aplica el esquema mediante PostgreSQL usando `DATABASE_URL`.
- `docker/`: configuracion local opcional.
- Supabase: Auth, PostgreSQL y Data API.
- Gemini: generacion opcional de planes mediante el backend.

## Backend

Entrada: `backend/app/main.py`

Rutas actuales:

- `GET /health`
- `GET /health/supabase`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/plans/generate`
- `POST /api/plans/feedback`
- `POST /api/coach/chat`
- `POST /api/workout/routine`
- `POST /api/recalibration/evaluate`

Entorno Python recomendado:

```powershell
cd C:\Users\Usuario\ai_fitness_coach\backend
..\.venv\Scripts\python.exe -m pip install -r requirements.txt
..\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

Dependencia importante: `supabase==2.31.0`, necesaria para claves modernas `sb_publishable_` y `sb_secret_`.

## Supabase

El esquema ya fue aplicado correctamente mediante el Session Pooler. Tablas verificadas:

- `public.usuarios`
- `public.aprendizaje_plan_anonimo`

`usuarios` contiene perfil, alergias alimentarias, lesiones actuales, discapacidad motora y zonas a evitar.

Para volver a aplicar migraciones:

```powershell
cd C:\Users\Usuario\ai_fitness_coach\backend
..\.venv\Scripts\python.exe scripts\migrate_supabase.py
```

`.env` esta en la raiz y esta ignorado por Git. Nunca imprimir ni copiar sus valores a archivos rastreados.

## Autenticacion

La app usa cedula venezolana como identificador visible. El backend crea un correo tecnico valido para Supabase Auth:

```text
cedula.<cedula>@aifitnesscoach.app
```

El registro usa Auth Admin en el backend y guarda el perfil en `public.usuarios`. El login usa `sign_in_with_password`. La respuesta de errores ya distingue duplicado `409` de error de esquema `500`.

Flutter persiste la sesion en `flutter_secure_storage` sin guardar la contrasena.

## Planes IA

`backend/app/routers/plans.py` acepta:

- `goal`
- `level`
- `days_per_week`
- `age`
- `weight`
- `health_notes`
- `food_allergies`
- `current_injuries`
- `motor_disability`
- `areas_to_avoid`
- `learning_consent`

Gemini se usa solo desde backend. Si falla o no esta configurado, responde un fallback seguro. El fallback conserva `constraints_applied` y no debe recomendar alimentos alergicos ni ejercicios que carguen zonas restringidas.

El aprendizaje debe ser consentido y agregado. No uses textos medicos privados de un usuario para entrenar o revelar informacion a otro. `POST /api/plans/feedback` guarda solo categoria, calificacion, proveedor y resultado seguro cuando `learning_consent=true`.

La clave de Gemini que esta localmente en `.env` fue compartida en conversaciones; antes de produccion debe rotarse.

## Flutter Web y Brave

Para ejecutar en Brave:

Terminal 1:

```powershell
cd C:\Users\Usuario\ai_fitness_coach\backend
..\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Terminal 2:

```powershell
cd C:\Users\Usuario\ai_fitness_coach\mobile_app
flutter pub get
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000
..\.venv\Scripts\python.exe -m http.server 52491 --bind 127.0.0.1 --directory build/web
```

Abrir:

```text
http://127.0.0.1:52491
```

El valor por defecto de Flutter Web es `http://127.0.0.1:8000`. Para Android emulator usa `--dart-define=API_BASE_URL=http://10.0.2.2:8000`. Para telefono fisico usa la IP LAN del PC.

## Registro actual

`mobile_app/lib/screens/auth/register_screen.dart` tiene:

- Seccion visual de perfil.
- Seccion de salud y adaptacion.
- Chips para alergias, lesiones, discapacidad y zonas a evitar.
- Enter o coma para agregar varias etiquetas.
- Eliminacion individual de chips.
- Correcciones locales como `nuezes -> Nueces`, `camarrones -> Camarones`, `lacteos -> Lacteos`.
- Envio de etiquetas limpias al backend.

La autocorreccion debe seguir siendo una ayuda, no una validacion medica. Para casos desconocidos, conserva el texto del usuario y permite corregirlo manualmente.

## Validacion minima

```powershell
cd C:\Users\Usuario\ai_fitness_coach\backend
..\.venv\Scripts\python.exe -m compileall -q app scripts

cd ..\mobile_app
flutter analyze
flutter test
```

Pruebas verificadas recientemente:

- Registro temporal Supabase: HTTP 200.
- Login temporal Supabase: HTTP 200.
- `GET /health/supabase`: `ok`, HTTP 200.
- Flutter tests: todos aprobados.
- Flutter Web build: correcto.

## Trabajo prioritario siguiente

1. Corregir y validar completamente el formulario de etiquetas en Web y Android.
2. Agregar pantalla de detalle de ejercicio con demostracion 3D/GLB y `animation_key`.
   El visor actual es un prototipo animado, **no** un visor 3D real con GLB.
3. Persistir planes generados en Supabase por usuario.
4. Agregar feedback consentido desde Flutter hacia `/api/plans/feedback`.
5. Implementar refresco seguro de sesiones y logout remoto.
6. Mejorar mensajes de error del login y registro.
7. Agregar tests backend para Auth, restricciones y feedback.
8. No incorporar modelos 3D sin licencia; usar assets propios o con licencia compatible.
9. Revisar limite de cuota de Gemini: el tier gratuito devuelve `ResourceExhausted`
   (HTTP 429) al hacer varias consultas seguidas. El backend ya lo informa, pero
   conviene evaluar un plan pago o cachear respuestas.

## Correcciones aplicadas (2026-09-25)

Contrato de planes (`backend/app/routers/plans.py`):

- `_normalize_sessions` y `_normalize_meals` convierten cualquier forma de respuesta
  de Gemini en el contrato estable que consume Flutter.
- `sessions`: lista de `{day, title, exercises:[{name, sets, reps, animation_key,
  primary_muscle, secondary_muscle}]}`.
- `nutrition`: lista de `{title, items:[str]}`.
- Si Gemini no entrega sesiones o comidas utilizables, se usa el fallback seguro.
- Tiempo limite efectivo de 20 s en la llamada a Gemini (`request_options`).

Coach (`backend/app/routers/coach.py`):

- Se elimino el `ThreadPoolExecutor` que no cancelaba la peticion.
- `request_options={"timeout": 15}` aplica un tiempo limite real.
- Nuevo campo `history` (lista de `{role, content}`) para conversacion multi-turno.
- Contexto ampliado: discapacidad motora, zonas a evitar, RPE y alergias.
- Se elimino el fallback que simulaba respuestas de IA. Ahora, si Gemini falla,
  se informa un error real: 429 (cuota), 504 (timeout) o 503 (no disponible).

Flutter:

- `plan_service.dart` ya no inventa un perfil; exige perfil real y expone `lastError`.
- `workouts_screen.dart` y `nutrition_screen.dart` muestran el error con boton
  "Reintentar" en lugar de un texto generico.
- `coach_screen.dart` envia el historial y el perfil real (alergias, lesiones,
  discapacidad, zonas a evitar) y muestra el detalle del error del backend.

Validacion ejecutada:

- `python -m compileall -q app scripts`: OK.
- `pytest tests`: 4 aprobadas (incluye contrato de planes y normalizadores).
- `flutter analyze`: sin problemas.
- `flutter test`: aprobado (prueba de login actualizada a los textos actuales).
- `flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000`: OK.
- Conversacion real con Gemini: turno 1 HTTP 200 con `provider=gemini` y plan con 3
  ejercicios; el turno 2 inmediato devuelve 429 por cuota del tier gratuito.

## IA multi-proveedor con failover (2026-09-25, segunda tanda)

`backend/app/services/ai_providers.py` centraliza las llamadas de IA. Intenta los
proveedores configurados en este orden y se detiene en el primero que responda:

| Orden | Proveedor | Variable | Tier gratuito (sin tarjeta) |
| --- | --- | --- | --- |
| 1 | Google Gemini | `GEMINI_API_KEY` | Buena calidad; cuota por proyecto en AI Studio |
| 2 | Groq | `GROQ_API_KEY` | 30 RPM, 1000 RPD, 200k tokens/dia |
| 3 | OpenRouter | `OPENROUTER_API_KEY` | ~20 modelos `:free` |
| 4 | Mistral | `MISTRAL_API_KEY` | Modo gratuito con topes por proyecto |

- Todos son accesibles desde Venezuela y no exigen tarjeta.
- Groq y OpenRouter son la mejor combinacion con Gemini: cada uno tiene su propia
  cuota, asi que la capacidad total se suma y los cortes por cuota desaparecen.
- Si todos fallan se lanza `AllProvidersFailed` y la API responde 503 con un
  mensaje claro. Nunca se simula una respuesta de IA.
- Diagnostico: `GET /health/ai` devuelve los proveedores configurados y el orden.
- Si Gemini agota cuota y no hay mas claves, la app sigue arrancando con el plan
  local seguro de `plans.py` (rutinas y nutricin no se rompen).

Recomendacion: registrar al menos `OPENROUTER_API_KEY` para eliminar los errores
intermitentes.

### Hallazgo real: Groq esta bloqueado desde Venezuela (2026-09-25)

Se probo la clave de Groq del usuario y **no es un problema de la clave**:

```
GET https://api.groq.com/                      -> 403 Forbidden (sin clave)
GET https://api.groq.com/openai/v1/models      -> 403 Forbidden (clave invalida)
```

Un 403 tambien con clave ficticia y en la raiz del dominio indica bloqueo por
red o pais, no credenciales invalidas. La clave quedo comentada en `.env`.

Alcance real medido desde esta red:

| Proveedor | Respuesta | Estado |
| --- | --- | --- |
| OpenRouter | 200 (modelos publicos) | Accesible |
| Mistral | 401 (pide clave) | Accesible |
| Cohere | 401 (pide clave) | Accesible |
| DeepSeek | 401 (pide clave) | Accesible |
| NVIDIA | 200 | Accesible |
| Gemini | responde con contenido real | Accesible, cuota corta |
| Groq | 403 siempre | **Bloqueado** |
| HuggingFace | sin conexion | Inaccesible |

Por eso el orden de intento quedo como `gemini -> openrouter -> mistral -> groq`
y el modelo por defecto de OpenRouter cambio a `google/gemma-4-31b-it:free`
(los modelos `:free` rotan; `meta-llama/llama-3.3-70b-instruct:free` ya no existe).

Con solo Gemini configurado el Coach agota la cuota y responde 503 con mensaje
claro. Para uso sostenido hace falta `OPENROUTER_API_KEY` (o `MISTRAL_API_KEY`).

### Emulador Android no disponible en esta maquina

`emulator -avd medium_phone` falla con:

```
x86_64 emulation currently requires hardware acceleration!
Android Emulator hypervisor driver is not installed on this machine
```

La virtualizacion de firmware esta activa, pero falta instalar el driver
hypervisor de Android, que requiere permisos de administrador y reiniciar.
Para probar en el telefono real hay dos rutas: USB con depuracion autorizada o
depuracion inalambrica mediante `adb pair` + `adb connect`.

## Visor 3D real en movil

`mobile_app/lib/widgets/exercise_3d_viewer.dart` sustituye a los animadores falsos.

- Motor 3D propio en Dart puro: rotacion por matrices, proyeccion en perspectiva,
  orden por profundidad y sombreado por distancia.
- Esqueleto humanoide de 16 articulaciones con poses por ejercicio: sentadilla,
  flexion, plancha, press de banca, remo, kettlebell swing, caminata y generica.
- Interaccion: giro automatico, arrastre con un dedo y zoom con pinza de dos.
- Resalta en rojo el musculo agonista y en ambar el sinergista, leyendo
  `primary_muscle` y `secondary_muscle` del plan generado por la IA.
- Sin WebView, sin OpenGL, sin assets y sin licencias de modelos 3D: funciona en
  cualquier Android, desde telefonos gama baja hasta los mas recientes.
- Se usa en `workouts_screen.dart` y `workout_schedule_screen.dart`.

## Servidor configurable desde la app

- `AuthService.apiBaseUrl` paso a ser dinamico (antes era una constante).
- El valor por defecto sigue siendo `--dart-define=API_BASE_URL=...`, pero ahora
  la pantalla de login muestra `Servidor: <url>` y permite cambiarlo.
- Se guarda con `flutter_secure_storage`, de modo que un mismo APK funciona en
  varios telefonos y redes sin recompilar.
- El backend debe escuchar en `0.0.0.0` para ser alcanzable desde el movil:
  `uvicorn app.main:app --host 0.0.0.0 --port 8000`.

## Compilar el APK para telefonos Android

```powershell
cd C:\Users\Usuario\ai_fitness_coach\backend
..\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000

cd C:\Users\Usuario\ai_fitness_coach\mobile_app
flutter build apk --release --dart-define=API_BASE_URL=http://<IP-LOCAL>:8000
```

El APK queda en `mobile_app/build/app/outputs/flutter-apk/app-release.apk` y se
instala copiandolo al telefono o con `adb install`. La app pide permiso de
`INTERNET` y permite trafico en claro, ambos ya configurados en el manifiesto.

Requisitos para ver el Coach en el movil: PC y telefono en la misma red WiFi y
el firewall de Windows permitiendo el puerto 8000.

## Estado Git al crear este documento

El commit publicado mas reciente es `e792202 Add corrected health tags to registration`.
Hay cambios locales no incluidos en ese commit en:

- `mobile_app/analysis_options.yaml`
- `mobile_app/lib/screens/auth/login_screen.dart`
- `mobile_app/lib/screens/auth/register_screen.dart`
- `mobile_app/lib/screens/coach_screen.dart`
- `mobile_app/lib/screens/home_screen.dart`
- `mobile_app/lib/screens/nutrition_screen.dart`
- `mobile_app/lib/screens/progress_screen.dart`
- `mobile_app/lib/screens/workouts_screen.dart`
- `mobile_app/lib/services/auth_service.dart`
- `mobile_app/lib/services/plan_service.dart`

Cline debe revisar esos cambios antes de agruparlos en un commit. No usar `git reset --hard` ni `git checkout --`.
