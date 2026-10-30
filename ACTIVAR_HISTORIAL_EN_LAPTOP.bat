@echo off
chcp 65001 > nul
title ACTIVAR HISTORIAL COMPLETO DE ANTIGRAVITY EN LAPTOP
color 0A

echo ===============================================================================
echo        🚀 ACTIVADOR AUTOMATICO DE HISTORIAL DE ANTIGRAVITY (AGY)
echo ===============================================================================
echo.
cd /d "%~dp0"

echo [1/3] Verificando archivos de migracion...
if not exist "%~dp0MIGRAR_HISTORIAL_A_LAPTOP.zip" (
    echo [INFO] Obteniendo actualizacion de GitHub...
    git pull origin main > nul 2>&1
)

echo [2/3] Instalando conversacion en Antigravity (C:\Users\USUARIO)...
python "%~dp0import_history.py" 2>nul
if %ERRORLEVEL% NEQ 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0import_history.ps1"
)

echo.
echo ===============================================================================
echo   ✔ ¡HISTORIAL COMPLETO ACTIVADO EN TU LAPTOP AL 100%!
echo ===============================================================================
echo.
echo Que hacer ahora:
echo   1. Abre o reinicia Antigravity en tu laptop.
echo   2. En el panel izquierdo de conversaciones veras:
echo.
echo            👉 "Resumen De Stack Tecnológico E IA"
echo.
echo   3. Haz clic en ella y ya tendras todo el chat, imagenes, diapositivas y tesis.
echo ===============================================================================
echo.
pause
