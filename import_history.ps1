# Script PowerShell de importacion directa para Windows
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "      ACTIVADOR AUTOMATICO DE HISTORIAL DE ANTIGRAVITY (AGY) - 1 CLIC          " -ForegroundColor Cyan
Write-Host "===============================================================================`n" -ForegroundColor Cyan

$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ZipPath = Join-Path $CurrentDir "MIGRAR_HISTORIAL_A_LAPTOP.zip"

if (-not (Test-Path $ZipPath)) {
    Write-Host "[INFO] Buscando actualizaciones en GitHub..." -ForegroundColor Yellow
    try {
        git -C $CurrentDir pull origin main
    } catch {}
}

if (-not (Test-Path $ZipPath)) {
    Write-Host "[ERROR] No se encontro '$ZipPath'." -ForegroundColor Red
    Write-Host "Por favor descarga MIGRAR_HISTORIAL_A_LAPTOP.zip o haz git pull." -ForegroundColor Red
    pause
    exit 1
}

# Determinar carpeta de usuario (especialmente C:\Users\USUARIO o $env:USERPROFILE)
$UserProfile = $env:USERPROFILE
if (Test-Path "C:\Users\USUARIO") {
    $UserProfile = "C:\Users\USUARIO"
}

Write-Host "[1/4] Directorio de usuario detectado: $UserProfile" -ForegroundColor Green

$AgyDir = Join-Path $UserProfile ".gemini\antigravity"
$ConvDir = Join-Path $AgyDir "conversations"
$BrainDir = Join-Path $AgyDir "brain"

if (-not (Test-Path $ConvDir)) { New-Item -ItemType Directory -Path $ConvDir -Force | Out-Null }
if (-not (Test-Path $BrainDir)) { New-Item -ItemType Directory -Path $BrainDir -Force | Out-Null }

$TempExtract = Join-Path $CurrentDir "_temp_import_history"
if (Test-Path $TempExtract) { Remove-Item -Path $TempExtract -Recurse -Force }

Write-Host "[2/4] Descomprimiendo historial completo..." -ForegroundColor Yellow
Expand-Archive -Path $ZipPath -DestinationPath $TempExtract -Force

$ConvId = "d1e1171e-d6c3-4ed8-8769-1402d5e1e556"

Write-Host "[3/4] Instalando base de datos de mensajes y artefactos..." -ForegroundColor Yellow
Copy-Item -Path (Join-Path $TempExtract "$ConvId.db") -Destination (Join-Path $ConvDir "$ConvId.db") -Force

$SrcBrain = Join-Path $TempExtract "brain\$ConvId"
$DestBrain = Join-Path $BrainDir $ConvId
if (Test-Path $DestBrain) { Remove-Item -Path $DestBrain -Recurse -Force }
Copy-Item -Path $SrcBrain -Destination $DestBrain -Recurse -Force

Write-Host "[4/4] Vinculando conversacion al indice de Antigravity..." -ForegroundColor Yellow
# Intentar registrar via Python si esta disponible, si no, se deja listo para que AGY lo lea
$PyCmd = Get-Command python -ErrorAction SilentlyContinue
if ($PyCmd) {
    python (Join-Path $CurrentDir "import_history.py")
} else {
    Write-Host "  -> Archivos de conversacion y memoria copiados exitosamente." -ForegroundColor Green
}

if (Test-Path $TempExtract) { Remove-Item -Path $TempExtract -Recurse -Force }

Write-Host "`n===============================================================================" -ForegroundColor Cyan
Write-Host "  ✔ ¡HISTORIAL TRANSFERIDO E INSTALADO AL 100% CON EXITO!                       " -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "Instruccion final:" -ForegroundColor White
Write-Host "  1. Abre Antigravity en tu laptop (o cierralo y vuelve a abrirlo)." -ForegroundColor White
Write-Host "  2. En la barra lateral izquierda veras la conversacion:" -ForegroundColor White
Write-Host "     'Resumen De Stack Tecnologico E IA'" -ForegroundColor Cyan
Write-Host "  3. Dale clic y ya tendras todo el historial activo de este chat." -ForegroundColor White
Write-Host "===============================================================================`n" -ForegroundColor Cyan
