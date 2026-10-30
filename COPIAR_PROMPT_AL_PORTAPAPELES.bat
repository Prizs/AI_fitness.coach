@echo off
chcp 65001 > nul
title COPIAR PROMPT PARA ANTIGRAVITY (AGY)
color 0B

echo ===============================================================================
echo            📋 COPIANDO PROMPT PARA ANTIGRAVITY AL PORTAPAPELES
echo ===============================================================================
echo.
cd /d "%~dp0"

powershell -NoProfile -Command "Get-Content -Path '%~dp0PROMPT_ANTIGRAVITY_LAPTOP.txt' -Raw -Encoding utf8 | Set-Clipboard"

echo.
echo ===============================================================================
echo   ✔ PROMPT COPIADO AL PORTAPAPELES DE WINDOWS CON EXITO
echo ===============================================================================
echo.
echo Pasos siguientes:
echo   1. Ve a la ventana de Antigravity en tu laptop.
echo   2. En la caja de texto del chat, presiona:
echo.
echo                  [ Ctrl + V ]   y luego   [ Enter ]
echo.
echo ===============================================================================
echo Abriendo tambien el archivo en Bloc de Notas por si prefieres verlo...
echo.
start notepad "%~dp0PROMPT_ANTIGRAVITY_LAPTOP.txt"

echo Presiona cualquier tecla para cerrar esta ventana...
pause > nul
