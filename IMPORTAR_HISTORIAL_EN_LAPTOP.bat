@echo off
chcp 65001 > nul
title IMPORTAR HISTORIAL COMPLETO DE ANTIGRAVITY (AGY)
color 0A

echo ===============================================================================
echo        🚀 MIGRACION DE HISTORIAL COMPLETO DE ANTIGRAVITY A LA LAPTOP
echo ===============================================================================
echo.
cd /d "%~dp0"

python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python no fue detectado en tu PATH de Windows.
    echo Por favor instala Python 3.10 o 3.11 marcando "Add python.exe to PATH".
    pause
    exit /b 1
)

python import_history.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Ocurrio un inconveniente durante la importacion.
    pause
    exit /b 1
)

pause
