$ErrorActionPreference = "Stop"

Write-Host "=== INICIANDO CONFIGURACIÓN AUTOMÁTICA DE ANDROID SDK Y COMPILACIÓN DE APK ==="

$toolsDir = "C:\AndroidBuildTools"
if (!(Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
}

$jdkDir = "$toolsDir\jdk-17"
$androidSdkDir = "$toolsDir\sdk"

# 1. OpenJDK 17
if (!(Test-Path "$jdkDir\bin\java.exe")) {
    Write-Host "[1/5] Descargando OpenJDK 17 portátil..."
    $jdkZip = "$toolsDir\jdk17.zip"
    $jdkUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.12%2B7/OpenJDK17U-jdk_x64_windows_hotspot_17.0.12_7.zip"
    Invoke-WebRequest -Uri $jdkUrl -OutFile $jdkZip -UseBasicParsing
    
    Write-Host "Extrayendo JDK 17..."
    $tempJdk = "$toolsDir\jdk_temp"
    Expand-Archive -Path $jdkZip -DestinationPath $tempJdk -Force
    $extractedFolder = Get-ChildItem -Path $tempJdk -Directory | Select-Object -First 1
    Move-Item -Path $extractedFolder.FullName -Destination $jdkDir -Force
    Remove-Item -Path $tempJdk -Recurse -Force
    Remove-Item -Path $jdkZip -Force
} else {
    Write-Host "[1/5] JDK 17 ya está disponible."
}

# 2. Android Command-line Tools
$cmdlineLatest = "$androidSdkDir\cmdline-tools\latest"
if (!(Test-Path "$cmdlineLatest\bin\sdkmanager.bat")) {
    Write-Host "[2/5] Descargando Android Command-line tools..."
    $cmdZip = "$toolsDir\cmdline.zip"
    $cmdUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    Invoke-WebRequest -Uri $cmdUrl -OutFile $cmdZip -UseBasicParsing
    
    Write-Host "Extrayendo Command-line tools..."
    $tempCmd = "$toolsDir\cmd_temp"
    Expand-Archive -Path $cmdZip -DestinationPath $tempCmd -Force
    New-Item -ItemType Directory -Path "$androidSdkDir\cmdline-tools" -Force | Out-Null
    Move-Item -Path "$tempCmd\cmdline-tools" -Destination $cmdlineLatest -Force
    Remove-Item -Path $tempCmd -Recurse -Force
    Remove-Item -Path $cmdZip -Force
} else {
    Write-Host "[2/5] Command-line tools ya están disponibles."
}

# 3. Configurar Entorno
$env:JAVA_HOME = $jdkDir
$env:ANDROID_HOME = $androidSdkDir
$env:ANDROID_SDK_ROOT = $androidSdkDir
$env:Path = "$jdkDir\bin;$cmdlineLatest\bin;$androidSdkDir\platform-tools;$env:Path"

# 4. Instalar SDK components y Licencias
$sdkManager = "$cmdlineLatest\bin\sdkmanager.bat"
if (!(Test-Path "$androidSdkDir\platforms\android-34")) {
    Write-Host "[3/5] Aceptando licencias e instalando Android SDK 34 y Build Tools..."
    
    # Aceptar licencias
    $proc = Start-Process -FilePath $sdkManager -ArgumentList "--licenses", "--sdk_root=$androidSdkDir" -NoNewWindow -PassThru -RedirectStandardInput "$toolsDir\licenses_in.txt"
    # Si no existe archivo de entrada, usamos echo y
    $yesText = "y`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`n"
    $yesText | & $sdkManager --licenses --sdk_root=$androidSdkDir | Out-Null

    # Instalar platform-tools, build-tools;34.0.0, platforms;android-34
    & $sdkManager --sdk_root=$androidSdkDir "platform-tools" "build-tools;34.0.0" "platforms;android-34"
} else {
    Write-Host "[3/5] Android SDK 34 ya está instalado."
}

# 5. Configurar Flutter y compilar APK
Write-Host "[4/5] Configurando Flutter con Android SDK..."
& flutter config --android-sdk $androidSdkDir
& flutter doctor -v

Write-Host "[5/5] Compilando APK Release oficial de AI Fitness Coach..."
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location "$projectRoot\mobile_app"

& flutter build apk --release --dart-define=API_BASE_URL=https://ai-fitness-coach-818a.onrender.com

$newApk = "$projectRoot\mobile_app\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $newApk) {
    Write-Host "¡APK compilado exitosamente!"
    Copy-Item -Path $newApk -Destination "$projectRoot\releases\app-release.apk" -Force
    New-Item -ItemType Directory -Path "$projectRoot\backend\app\web_dist" -Force | Out-Null
    Copy-Item -Path $newApk -Destination "$projectRoot\backend\app\web_dist\AI_Fitness_Coach.apk" -Force
    
    $apkSize = (Get-Item "$projectRoot\releases\app-release.apk").Length / 1MB
    Write-Host ("Tamaño del APK generado: {0:N2} MB" -f $apkSize)
    Write-Host "Listo para subir y desplegar."
} else {
    Write-Error "No se encontró el APK generado en $newApk"
}
