# MANUAL DE INSTALACIÓN, EJECUCIÓN Y CONTROL TOTAL
## Proyecto: AI Fitness Coach (Entrenador Deportivo Inteligente)

Este documento contiene todo lo necesario para instalar, ejecutar, desplegar y tener **control total y absoluto** de este proyecto en cualquier PC o servidor.

---

## 1. ESTRUCTURA GENERAL DEL PROYECTO

```text
ai_fitness_coach/
├── .env                              # Claves maestras (Supabase, Gemini, OpenRouter, DB)
├── requirements.txt                  # Dependencias de Python para el Backend
├── keep_alive.py                     # Script de mantenimiento activo para Render / Supabase
├── backend/                          # Backend FastAPI
│   ├── app/
│   │   ├── main.py                   # Punto de entrada de la API FastAPI
│   │   ├── config.py                 # Configuración de variables de entorno
│   │   ├── routers/                  # Endpoints REST (auth, coach, plans, trainer, workouts, etc.)
│   │   │   ├── auth.py               # Autenticación, JWT y contraseña maestra (prueba123)
│   │   │   ├── coach.py              # Motor IA del Coach, memoria de herramientas y planes
│   │   │   ├── trainer.py            # Módulo de Entrenadores, ficha técnica y agenda
│   │   │   ├── workouts.py           # Gestión y ejecución de entrenamientos
│   │   │   └── ...
│   │   ├── services/                 # Servicios auxiliares (IA con failover, Supabase)
│   │   └── static/                   # GIFs y animaciones de ejercicios biomecánicos
│   └── requirements.txt
├── mobile_app/                       # Aplicación Frontend en Flutter (Web / Android / iOS)
│   ├── pubspec.yaml                  # Dependencias Flutter
│   ├── lib/
│   │   ├── main.dart                 # Inicialización de la App
│   │   ├── screens/                  # Pantallas (Coach, Nutrición, Cronograma, Entrenador, Perfil)
│   │   │   ├── coach_screen.dart     # Chat inteligente con el Coach IA y micrófono
│   │   │   ├── home_screen.dart      # Pantalla principal con notificaciones dinámicas
│   │   │   ├── nutrition_screen.dart # Pantalla de menús y sinergia nutricional
│   │   │   ├── notifications_screen.dart # Alertas de caducidad y avisos
│   │   │   └── trainer/              # Módulos del entrenador personal y fichas técnicas
│   │   ├── services/                 # AuthService (failover local/nube), WeeklyPlanService, etc.
│   │   └── widgets/                  # Componentes reutilizables (Cuestionario Estado Actual, etc.)
│   └── assets/                       # Base de datos de ejercicios, animaciones Lottie y GIFs
└── database/                         # Scripts SQL y migraciones de Supabase
    ├── schema.sql                    # Esquema relacional base
    ├── supabase_schema.sql           # Esquema Supabase
    ├── supabase_trainer_modules.sql  # Tablas para entrenadores, citas y alertas
    └── supabase_chat_affiliation.sql # Afiliación y chat alumno-entrenador
```

---

## 2. REQUISITOS PREVIOS EN LA PC

Para ejecutar el proyecto en una PC nueva necesitas tener instalado:

1. **Python 3.10 o superior**:
   * Descargar de [python.org](https://www.python.org/downloads/).
   * ⚠️ **MUY IMPORTANTE**: En el instalador de Windows, marca la casilla **"Add python.exe to PATH"**.
2. **Flutter SDK (3.13 o superior)**:
   * Descargar de [docs.flutter.dev](https://docs.flutter.dev/get-started/install/windows).
   * Agregar la carpeta `flutter\bin` a las Variables de Entorno (PATH).
3. **Google Chrome**:
   * Para probar y ejecutar la aplicación Web de Flutter de inmediato.
4. **Git**:
   * Descargar de [git-scm.com](https://git-scm.com/).

---

## 3. PASOS PARA LEVANTAR EL BACKEND (FastAPI)

1. Abre una terminal (PowerShell o CMD) en la carpeta raíz del proyecto (`ai_fitness_coach`):
   ```powershell
   cd ai_fitness_coach
   ```

2. Crea el entorno virtual de Python:
   ```powershell
   python -m venv .venv
   ```

3. Activa el entorno virtual:
   * En Windows (PowerShell):
     ```powershell
     .\.venv\Scripts\Activate.ps1
     ```
     *(Si PowerShell bloquea scripts, ejecuta una sola vez: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`)*
   * En Windows (CMD):
     ```cmd
     .\.venv\Scripts\activate.bat
     ```

4. Instala todas las dependencias del Backend:
   ```powershell
   pip install -r requirements.txt
   ```

5. Inicia el servidor de desarrollo:
   ```powershell
   $env:PYTHONPATH="backend"
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **¡Control Total del Backend!**:
   * Tu servidor estará corriendo en: `http://localhost:8000`
   * **Panel Interactivo Swagger (Docs)**: Abre en tu navegador `http://localhost:8000/docs` para ver, probar y ejecutar directamente cualquier endpoint de la API con un solo clic.

---

## 4. PASOS PARA LEVANTAR EL FRONTEND (Flutter)

1. Abre una nueva terminal en la carpeta `mobile_app`:
   ```powershell
   cd ai_fitness_coach\mobile_app
   ```

2. Descarga los paquetes y librerías de Flutter:
   ```powershell
   flutter pub get
   ```

3. Ejecuta la aplicación en Chrome (Modo Web):
   * Conectada al Backend Local (`localhost:8000`):
     ```powershell
     flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
     ```
   * O conectada al Backend en la Nube (Render):
     ```powershell
     flutter run -d chrome --dart-define=API_BASE_URL=https://ai-fitness-coach-818a.onrender.com
     ```

*(Nota: En la pantalla de Login de la app, también tienes chips de 1-clic para cambiar entre Servidor Local :8000 y Servidor Render en cualquier momento sin recompilar).*

---

## 5. CONTRASEÑA MAESTRA Y ACCESO UNIVERSAL

Para pruebas rápidas de desarrollo, evaluación y auditoría:
* **Contraseña Maestra**: `prueba123`
* Puedes ingresar con **cualquier cédula de usuario o entrenador** registrada en la base de datos usando `prueba123`.
* El backend valida la contraseña de forma insensible a mayúsculas/minúsculas y recorta espacios en blanco accidentales (funciona con `prueba123`, `Prueba123`, `PRUEBA123`, etc.).

---

## 6. BASE DE DATOS SUPABASE (Control en la Nube)

El proyecto utiliza **Supabase Cloud** (PostgreSQL):
* **URL del Proyecto**: `https://xbokmqogzysrqwxbbamm.supabase.co`
* **Tablas principales**:
  * `users`: Cédula, nombre, rol (`client` o `trainer`), peso, edad, lesiones, equipamiento.
  * `trainer_profiles`: Especialidades, certificaciones y años de experiencia.
  * `trainer_appointments`: Agendas, bloques de atención y citas con alumnos.
  * `trainer_affiliations`: Vínculo entre alumno y entrenador personal con canal de chat.
  * `weekly_plans`: Planes de entrenamiento y nutrición generados.
* Todos los scripts para crear o restaurar tablas desde cero se encuentran en la carpeta `database/`.

---

## 7. INTELIGENCIA ARTIFICIAL Y FAILOVER (Gemini + OpenRouter)

El backend cuenta con una arquitectura de IA resiliente:
1. **Google Gemini (Primario)**: Utiliza `gemini-2.5-flash` con salida estructurada forzada (`application/json`).
2. **OpenRouter (Secundario / Failover automático)**: Si Gemini agota cuota o falla temporalmente, el backend salta de inmediato a modelos gratuitos de OpenRouter sin interrumpir al usuario.
3. **Mecanismo Zero-Crash**: El parser de respuestas en `backend/app/routers/coach.py` está blindado contra errores de formato; si el modelo responde en texto libre, lo captura como respuesta limpia sin generar nunca un error `503`.

---

## 8. SINCRONIZACIÓN CON GITHUB Y DESPLIEGUE EN RENDER

El repositorio Git está conectado a:
* **Repositorio GitHub**: `https://github.com/Prizs/AI_fitness.coach.git`
* **Despliegue Continuo (CI/CD)**: Cada vez que haces `git push origin main`, Render compila y actualiza automáticamente el servidor en la nube (`https://ai-fitness-coach-818a.onrender.com`).
* **Keep-Alive**: Para evitar que el servidor gratuito de Render se suspenda por inactividad, puedes dejar corriendo en segundo plano:
  ```powershell
  python keep_alive.py
  ```
