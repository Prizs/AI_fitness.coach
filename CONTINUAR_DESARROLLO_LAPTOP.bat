@echo off
chcp 65001 > nul
title AI FITNESS COACH - CONTINUIDAD DE DESARROLLO EN LAPTOP
color 0A

echo ===============================================================================
echo            🚀 AI FITNESS COACH - ENTORNO INTEGRADO DE DESARROLLO
echo ===============================================================================
echo.
echo [1/5] Posicionando en el directorio de trabajo...
cd /d "%~dp0"
echo Carpeta actual: %CD%
echo.

echo [2/5] Descargando ultimas actualizaciones desde GitHub (git pull origin main)...
git pull origin main
if %ERRORLEVEL% NEQ 0 (
    echo [ADVERTENCIA] No se pudo hacer git pull automatico. Verifica conexion a internet.
) else (
    echo [OK] Repositorio local actualizado con exito.
)
echo.

echo [3/5] Verificando entorno Python e instalando dependencias backend...
python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python no fue detectado en tu PATH de Windows.
    echo Por favor instala Python 3.10 o 3.11 marcando "Add python.exe to PATH".
    pause
    exit /b 1
)
pip install -r backend\requirements.txt
echo [OK] Dependencias verificadas.
echo.

echo [4/5] Ejecutando banco de pruebas automatizadas E2E de Coach IA...
python backend\test_coach_e2e.py
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Fallaron las pruebas de Coach IA. Revisa los mensajes anteriores.
    pause
    exit /b 1
)
echo.

echo ===============================================================================
echo   ✔ PRUEBAS SUPERADAS: DEDUPLICACION AL 100%% Y MULTI-CICLO FUNCIONANDO
echo ===============================================================================
echo.
echo [5/5] Iniciando servidor local FastAPI (Backend + Frontend Web sincronizado)...
echo.
echo  * Acceso Web Local:     http://localhost:8000
echo  * Documentacion API:    http://localhost:8000/docs
echo  * Instrucciones AGY:    Revisa el archivo PROMPT_CONTINUIDAD_AGY.md
echo.
echo Abriendo navegador en http://localhost:8000 en 3 segundos...
start "" timeout /t 3 /nobreak > nul & start http://localhost:8000
echo.
echo Presiona Ctrl+C para detener el servidor en cualquier momento.
echo -------------------------------------------------------------------------------
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
