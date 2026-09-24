# AI Fitness Coach

Proyecto monorepo para un entrenador personal inteligente con app móvil, backend API y base de datos relacional.

## Estructura

- `backend/` — API FastAPI
- `mobile_app/` — aplicación Flutter para Android
- `database/` — scripts y documentación de BD
- `docker/` — configuración para entorno local
- `.env.example` — variables de entorno

## Stack recomendado

- Frontend: Flutter + Dart
- Backend: Python + FastAPI
- Base de datos: Supabase (PostgreSQL)
- Auth: Supabase Auth
- IA: modelo generativo

## Requisitos

- Python 3.11+
- Flutter SDK
- Git
- Docker (opcional para entorno local)
- Cuenta Supabase

## Variables de entorno

Crear un archivo `.env` en la raíz con:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_KEY=tu-anon-key
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key
DATABASE_URL=postgresql://postgres:password@host:5432/postgres
```

## Ejecutar backend local

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Linux/macOS
# o .venv\Scripts\activate  # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Ejecutar app Flutter

```bash
cd mobile_app
flutter pub get
flutter run
```

## Publicar en GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/ai-fitness-coach.git
git push -u origin main
```

## Siguientes pasos

1. Crear base de datos en Supabase
2. Crear tablas de usuarios, perfil, rutinas y nutrición
3. Conectar Flutter y FastAPI a Supabase
4. Implementar coach IA
5. Preparar despliegue futuro para APK y web
