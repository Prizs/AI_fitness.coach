# AI Fitness Coach

Monorepo para el proyecto de entrenador personal inteligente con backend API y app móvil.

## Estructura

- `backend/` - API FastAPI con coach, rutinas y recalibración.
- `mobile_app/` - Proyecto Flutter para Android.
- `.vscode/settings.json` - configuración para autoguardado del editor.

## Estado actual

La carpeta base del proyecto quedó en:

`C:\Users\Usuario\ai_fitness_coach`

Desde aquí continuamos trabajando con:

- backend en Python/FastAPI
- app móvil en Flutter/Dart
- guardado automático en VS Code

## Cómo continuar

1. Abrir esta carpeta en VS Code.
2. Trabajar sobre `backend/` y `mobile_app/`.
3. Mantener autoguardado habilitado por la configuración de `.vscode/settings.json`.

## Comandos útiles

Backend:

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Mobile app:

```bash
cd mobile_app
flutter pub get
flutter run
```
