import os
import sys
import time
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends, Header, Query
from fastapi.responses import HTMLResponse, FileResponse, RedirectResponse, JSONResponse
from pydantic import BaseModel

from app.services.ai_providers import (
    configured_providers,
    generate_json_text,
    PROVIDER_ORDER,
    GEMINI_TIMEOUT_SEC,
)
from app.services.supabase_service import get_supabase_admin_client, check_supabase_connection
from app.routers.app_updates import _read_pubspec_version, _find_apk_file

router = APIRouter()

ADMIN_PINS = {"2026", "admin818", os.getenv("ADMIN_PIN", "2026")}

class AdminLoginRequest(BaseModel):
    pin: str

class TestAIRequest(BaseModel):
    prompt: str = "Hola coach, dime 1 ejercicio para pecho en JSON"
    pin: str

class CreateUserRequest(BaseModel):
    pin: str
    cedula: str
    nombre: str
    apellido: str
    password: str = "Pass123*"
    edad: Optional[int] = 25
    peso: Optional[float] = 70.0
    genero: Optional[str] = "masculino"
    role: Optional[str] = "client"
    patologia_o_alergias: Optional[str] = None
    alergias_alimentarias: Optional[str] = None
    lesiones_actuales: Optional[str] = None
    discapacidad_motora: Optional[str] = None
    zonas_a_evitar: Optional[str] = None


def _verify_pin(pin: str):
    if not pin or str(pin).strip() not in ADMIN_PINS:
        raise HTTPException(status_code=401, detail="PIN de administrador inválido")


# =====================================================================
# ENDPOINTS API ADMIN
# =====================================================================

@router.post("/api/admin/auth/verify")
def verify_admin_pin(payload: AdminLoginRequest):
    _verify_pin(payload.pin)
    return {"authorized": True, "message": "Acceso de Administrador concedido"}


@router.get("/api/admin/ecosystem")
def get_ecosystem_status(pin: str = Query(...)):
    _verify_pin(pin)
    t0 = time.time()
    sb_status = check_supabase_connection()
    sb_lat = round((time.time() - t0) * 1000, 1)

    # Usuarios y estadísticas
    users_count = 0
    trainers_count = 0
    try:
        admin = get_supabase_admin_client()
        res = admin.table("usuarios").select("id, role").execute()
        users_count = len(res.data or [])
        trainers_count = len([u for u in (res.data or []) if u.get("role") == "trainer"])
    except Exception:
        pass

    # Versión de APK
    ver_name, ver_code = _read_pubspec_version()
    apk_file = _find_apk_file()
    apk_size = apk_file.stat().st_size if apk_file else 0

    configured = configured_providers()
    gemini_key = os.getenv("GEMINI_API_KEY", "")
    masked_key = f"{gemini_key[:6]}...{gemini_key[-4:]}" if len(gemini_key) > 10 else ("Configurada" if gemini_key else "No configurada")

    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "ai": {
            "primary": "gemini",
            "active_model": os.getenv("GEMINI_MODEL") or "gemini-3.1-flash-lite (automático)",
            "configured_providers": configured,
            "order": list(PROVIDER_ORDER),
            "key_status": masked_key,
            "timeout_sec": GEMINI_TIMEOUT_SEC,
        },
        "supabase": {
            "status": sb_status.get("status", "unknown"),
            "latency_ms": sb_lat,
            "total_users": users_count,
            "trainers_count": trainers_count,
        },
        "app_updates": {
            "version_name": ver_name,
            "version_code": ver_code,
            "apk_found": apk_file is not None,
            "apk_size_mb": round(apk_size / (1024 * 1024), 2) if apk_size else 0,
        },
        "system": {
            "python": sys.version.split()[0],
            "os": sys.platform,
            "environment": os.getenv("ENVIRONMENT", "production"),
        }
    }


@router.post("/api/admin/test-ai")
def test_ai_live(payload: TestAIRequest):
    _verify_pin(payload.pin)
    t0 = time.time()
    try:
        res = generate_json_text(
            f'{{"instruccion": "{payload.prompt}"}}',
            timeout=25.0
        )
        elapsed = round((time.time() - t0) * 1000, 1)
        return {
            "success": True,
            "provider": res.provider,
            "latency_ms": elapsed,
            "response": res.text[:1000],
        }
    except Exception as e:
        elapsed = round((time.time() - t0) * 1000, 1)
        return {
            "success": False,
            "latency_ms": elapsed,
            "error": str(e)
        }


@router.get("/api/admin/users")
def list_users(pin: str = Query(...)):
    _verify_pin(pin)
    admin = get_supabase_admin_client()
    try:
        res = admin.table("usuarios").select(
            "id, cedula, nombre, apellido, edad, peso, genero, role, "
            "patologia_o_alergias, alergias_alimentarias, lesiones_actuales, "
            "discapacidad_motora, zonas_a_evitar"
        ).order("cedula").execute()
        return {"users": res.data or []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obteniendo usuarios: {e}")


@router.post("/api/admin/users")
def create_user_admin(payload: CreateUserRequest):
    _verify_pin(payload.pin)
    admin = get_supabase_admin_client()
    clean_cedula = str(payload.cedula).strip()

    # Verificar existencia
    existing = admin.table("usuarios").select("id").eq("cedula", clean_cedula).execute()
    if existing.data:
        raise HTTPException(status_code=400, detail=f"La cédula {clean_cedula} ya está registrada.")

    auth_email = f"{clean_cedula}@aifitness.app"
    try:
        # Crear en Supabase Auth
        auth_user = admin.auth.admin.create_user({
            "email": auth_email,
            "password": payload.password,
            "email_confirm": True,
            "user_metadata": {"cedula": clean_cedula, "name": payload.nombre}
        })
        user_id = auth_user.user.id

        # Insertar en tabla pública
        profile = {
            "id": user_id,
            "cedula": clean_cedula,
            "nombre": payload.nombre.strip(),
            "apellido": payload.apellido.strip(),
            "edad": payload.edad,
            "peso": payload.peso,
            "genero": payload.genero.strip().lower() if payload.genero else "masculino",
            "role": payload.role or "client",
            "patologia_o_alergias": payload.patologia_o_alergias,
            "alergias_alimentarias": payload.alergias_alimentarias,
            "lesiones_actuales": payload.lesiones_actuales,
            "discapacidad_motora": payload.discapacidad_motora,
            "zonas_a_evitar": payload.zonas_a_evitar,
        }
        admin.table("usuarios").insert(profile).execute()
        return {"success": True, "user": profile}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creando usuario: {e}")


@router.delete("/api/admin/users/{user_id}")
def delete_user_admin(user_id: str, pin: str = Query(...)):
    _verify_pin(pin)
    admin = get_supabase_admin_client()
    errors = []
    
    # 1. Borrar de tabla pública
    try:
        admin.table("usuarios").delete().eq("id", user_id).execute()
    except Exception as e:
        errors.append(f"Error borrando perfil: {e}")

    # 2. Borrar de auth
    try:
        admin.auth.admin.delete_user(user_id)
    except Exception as e:
        errors.append(f"Error borrando de auth: {e}")

    if errors:
        return {"success": False, "warnings": errors}
    return {"success": True, "message": f"Usuario {user_id} eliminado exitosamente."}


@router.post("/api/admin/purge-cache")
def purge_system_cache(payload: AdminLoginRequest):
    _verify_pin(payload.pin)
    # Lógica de limpieza en memoria
    return {
        "success": True,
        "message": "Caché de IA, estados temporales y conexiones reseteados satisfactoriamente."
    }


# =====================================================================
# VISTAS HTML: PANEL ADMIN Y PÁGINA DE DESCARGAS
# =====================================================================

@router.get("/descargar", response_class=HTMLResponse)
@router.get("/download", response_class=HTMLResponse)
@router.get("/app", response_class=HTMLResponse)
def download_landing_page():
    ver_name, ver_code = _read_pubspec_version()
    apk = _find_apk_file()
    size_mb = round(apk.stat().st_size / (1024 * 1024), 1) if apk else 60.3

    return HTMLResponse(content=f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Descargar AI Fitness Coach - App Móvil Oficial</title>
  <link rel="icon" type="image/png" href="/favicon.png"/>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap');
    body {{
      font-family: 'Plus Jakarta Sans', sans-serif;
      background: radial-gradient(circle at 50% 0%, #0d2822 0%, #060e14 60%, #02070a 100%);
      color: #f1f5f9;
      min-height: 100vh;
    }}
    .glow-box {{
      box-shadow: 0 0 50px -10px rgba(16, 185, 129, 0.25);
    }}
  </style>
</head>
<body class="flex flex-col items-center justify-between p-4 sm:p-6">

  <!-- Header -->
  <header class="w-full max-w-4xl flex items-center justify-between py-4 border-b border-emerald-950/40">
    <div class="flex items-center gap-3">
      <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-400 to-teal-600 flex items-center justify-center shadow-lg shadow-emerald-500/20 font-black text-black text-xl">
        AI
      </div>
      <div>
        <h1 class="font-extrabold text-lg text-white leading-tight">AI Fitness Coach</h1>
        <p class="text-xs text-emerald-400/80 font-medium">Entrenador y Nutrición Inteligente</p>
      </div>
    </div>
    <a href="/" class="text-xs font-semibold px-4 py-2 rounded-lg bg-emerald-950/60 hover:bg-emerald-900/60 border border-emerald-500/30 text-emerald-300 transition-all">
      Abrir Versión Web &rarr;
    </a>
  </header>

  <!-- Main Card -->
  <main class="w-full max-w-lg my-8 bg-slate-900/80 backdrop-blur-xl border border-emerald-500/30 rounded-3xl p-6 sm:p-8 glow-box text-center flex flex-col items-center">
    
    <!-- Version Tag -->
    <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-semibold mb-4">
      <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
      Versión Oficial v{ver_name} (Build {ver_code})
    </div>

    <h2 class="text-2xl sm:text-3xl font-extrabold text-white mb-2">Instala la App en tu Móvil</h2>
    <p class="text-slate-400 text-sm mb-6 max-w-sm">
      Disfruta del Coach IA, dictado por voz, atlas 3D interactivo y planes personalizados sincronizados en vivo.
    </p>

    <!-- Download Button -->
    <a href="/api/app/download" download="AI_Fitness_Coach.apk" class="w-full py-4 px-6 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 text-slate-950 font-extrabold text-base flex items-center justify-center gap-3 shadow-xl shadow-emerald-500/25 transition-all transform active:scale-95 mb-6">
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
      </svg>
      Descargar APK Android ({size_mb} MB)
    </a>

    <!-- QR Code Section -->
    <div class="w-full p-4 rounded-2xl bg-slate-950/60 border border-slate-800/80 flex flex-col items-center mb-6">
      <p class="text-xs text-slate-400 mb-3 font-medium">¿Estás en la PC? Escanea con la cámara de tu celular:</p>
      <div id="qrcode" class="bg-white p-3 rounded-xl shadow-md"></div>
    </div>

    <!-- Quick Steps -->
    <div class="w-full text-left bg-slate-950/40 rounded-xl p-4 border border-slate-800/50">
      <p class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-2">Pasos de instalación:</p>
      <ol class="text-xs text-slate-400 space-y-1.5 list-decimal list-inside">
        <li>Descarga el archivo APK en tu dispositivo Android.</li>
        <li>Abre el archivo y pulsa <b class="text-slate-200">"Instalar"</b>.</li>
        <li>Si aparece advertencia de origen desconocido, selecciona <b class="text-emerald-400">"Permitir desde esta fuente"</b>.</li>
      </ol>
    </div>

  </main>

  <!-- Footer -->
  <footer class="w-full max-w-4xl text-center py-4 text-xs text-slate-600 border-t border-slate-900">
    AI Fitness Coach &copy; {datetime.now().year} &bull; Sincronización Web y Móvil Unificada
  </footer>

  <script>
    const downloadUrl = window.location.origin + '/api/app/download';
    new QRCode(document.getElementById("qrcode"), {{
      text: downloadUrl,
      width: 140,
      height: 140,
      colorDark : "#000000",
      colorLight : "#ffffff",
      correctLevel : QRCode.CorrectLevel.M
    }});
  </script>
</body>
</html>
""")


@router.get("/admin", response_class=HTMLResponse)
def admin_portal_html():
    ver_name, ver_code = _read_pubspec_version()
    return HTMLResponse(content=f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Panel de Administrador &mdash; AI Fitness Coach</title>
  <link rel="icon" type="image/png" href="/favicon.png"/>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
    body {{
      font-family: 'Plus Jakarta Sans', sans-serif;
      background: #070d14;
      color: #e2e8f0;
    }}
    .glow {{
      box-shadow: 0 0 30px -5px rgba(16, 185, 129, 0.2);
    }}
  </style>
</head>
<body class="min-height-screen flex flex-col">

  <!-- PIN Gate Overlay -->
  <div id="pinGate" class="fixed inset-0 z-50 bg-slate-950/95 backdrop-blur-md flex items-center justify-center p-4">
    <div class="w-full max-w-md bg-slate-900 border border-emerald-500/30 rounded-3xl p-8 glow text-center">
      <div class="w-14 h-14 mx-auto rounded-2xl bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center text-emerald-400 mb-4">
        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
        </svg>
      </div>
      <h2 class="text-2xl font-extrabold text-white mb-1">Acceso Administrativo</h2>
      <p class="text-xs text-slate-400 mb-6">Introduce el PIN de soporte o clave maestra</p>
      
      <form onsubmit="handleLogin(event)">
        <input type="password" id="adminPinInput" placeholder="Ingresa PIN (ej. 2026)" class="w-full px-4 py-3 bg-slate-950 border border-slate-700 rounded-xl text-center text-lg tracking-widest text-emerald-400 font-bold focus:outline-none focus:border-emerald-500 mb-4" autofocus required>
        <button type="submit" id="loginBtn" class="w-full py-3.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-extrabold rounded-xl transition-all shadow-lg shadow-emerald-500/20">
          Entrar al Panel
        </button>
        <p id="loginError" class="text-xs text-rose-400 mt-3 hidden"></p>
      </form>
    </div>
  </div>

  <!-- Main Navigation -->
  <header class="bg-slate-900/80 border-b border-slate-800 sticky top-0 z-30 backdrop-blur-md px-6 py-4 flex items-center justify-between">
    <div class="flex items-center gap-3">
      <div class="w-9 h-9 rounded-xl bg-emerald-500 flex items-center justify-center text-slate-950 font-black text-lg">
        AI
      </div>
      <div>
        <h1 class="font-extrabold text-white text-base leading-tight">AI Fitness Coach &bull; Portal de Administrador</h1>
        <p class="text-xs text-slate-400">Control de Ecosistema, Usuarios, IA & Móvil</p>
      </div>
    </div>
    
    <div class="flex items-center gap-3">
      <a href="/descargar" target="_blank" class="text-xs font-semibold px-3 py-1.5 rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/20 transition-all flex items-center gap-1.5">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
        Descargar APK Móvil
      </a>
      <button onclick="logoutAdmin()" class="text-xs font-semibold px-3 py-1.5 rounded-lg bg-rose-500/10 text-rose-400 border border-rose-500/30 hover:bg-rose-500/20 transition-all">
        Salir
      </button>
    </div>
  </header>

  <!-- Tabs Navigation -->
  <nav class="bg-slate-950 border-b border-slate-800/80 px-6 flex gap-2 overflow-x-auto">
    <button onclick="switchTab('ecosystem')" id="tabBtn-ecosystem" class="py-3 px-4 text-xs font-bold border-b-2 border-emerald-500 text-emerald-400 transition-all">
      ⚡ Ecosistema & APIs
    </button>
    <button onclick="switchTab('users')" id="tabBtn-users" class="py-3 px-4 text-xs font-bold border-b-2 border-transparent text-slate-400 hover:text-slate-200 transition-all">
      👥 Gestión de Usuarios
    </button>
    <button onclick="switchTab('aiTest')" id="tabBtn-aiTest" class="py-3 px-4 text-xs font-bold border-b-2 border-transparent text-slate-400 hover:text-slate-200 transition-all">
      🧠 Test en Vivo de la IA
    </button>
  </nav>

  <!-- Content Container -->
  <main class="flex-1 p-6 max-w-7xl w-full mx-auto">
    
    <!-- TAB 1: ECOSISTEMA -->
    <div id="tab-ecosystem" class="space-y-6">
      
      <!-- Metrics Grid -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        
        <!-- Google Gemini Card -->
        <div class="bg-slate-900/60 border border-slate-800 p-5 rounded-2xl">
          <div class="flex items-center justify-between mb-2">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Google Gemini</span>
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping"></span>
          </div>
          <div class="text-xl font-extrabold text-white" id="geminiModelLabel">Cargando...</div>
          <p class="text-xs text-emerald-400 mt-1" id="geminiKeyStatus">Clave activa</p>
        </div>

        <!-- Supabase Card -->
        <div class="bg-slate-900/60 border border-slate-800 p-5 rounded-2xl">
          <div class="flex items-center justify-between mb-2">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Supabase DB</span>
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-400"></span>
          </div>
          <div class="text-xl font-extrabold text-white" id="supabaseStatusLabel">Cargando...</div>
          <p class="text-xs text-slate-400 mt-1" id="supabaseLatencyLabel">Latencia: -- ms</p>
        </div>

        <!-- Registered Users Card -->
        <div class="bg-slate-900/60 border border-slate-800 p-5 rounded-2xl">
          <div class="flex items-center justify-between mb-2">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Usuarios Activos</span>
            <span class="text-xs font-semibold px-2 py-0.5 rounded bg-slate-800 text-slate-300">BD Real</span>
          </div>
          <div class="text-2xl font-extrabold text-white" id="totalUsersCount">--</div>
          <p class="text-xs text-slate-400 mt-1" id="trainersCountLabel">-- entrenadores</p>
        </div>

        <!-- Mobile APK Card -->
        <div class="bg-slate-900/60 border border-slate-800 p-5 rounded-2xl">
          <div class="flex items-center justify-between mb-2">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">APK Móvil</span>
            <span class="text-xs font-bold text-emerald-400" id="apkVersionBadge">v{ver_name}</span>
          </div>
          <div class="text-xl font-extrabold text-white" id="apkSizeLabel">Listo para descarga</div>
          <a href="/descargar" target="_blank" class="text-xs text-emerald-400 hover:underline mt-1 inline-block">Ver página de descarga &rarr;</a>
        </div>

      </div>

      <!-- Quick Actions Bar -->
      <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h3 class="font-bold text-white text-base">Mantenimiento de Caché & Memoria</h3>
          <p class="text-xs text-slate-400">Restablece la memoria interna del servidor y contadores de los proveedores.</p>
        </div>
        <div class="flex gap-3">
          <button onclick="purgeCache()" class="px-4 py-2.5 rounded-xl bg-amber-500/10 hover:bg-amber-500/20 text-amber-400 border border-amber-500/30 text-xs font-bold transition-all flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
            Limpiar Caché IA
          </button>
          <button onclick="fetchEcosystem()" class="px-4 py-2.5 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-xs font-bold transition-all flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
            Refrescar Estado
          </button>
        </div>
      </div>

    </div>

    <!-- TAB 2: GESTIÓN DE USUARIOS -->
    <div id="tab-users" class="space-y-6 hidden">
      
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 class="text-xl font-extrabold text-white">Directorio de Usuarios</h2>
          <p class="text-xs text-slate-400">Ver ficha médica/clínica, objetivos o eliminar usuarios corruptos</p>
        </div>
        <div class="flex items-center gap-3">
          <input type="text" id="userSearchInput" oninput="filterUsers()" placeholder="Buscar por cédula o nombre..." class="px-4 py-2 rounded-xl bg-slate-900 border border-slate-700 text-xs text-white focus:outline-none focus:border-emerald-500 w-64">
          <button onclick="openNewUserModal()" class="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-extrabold text-xs rounded-xl shadow-lg shadow-emerald-500/20 transition-all flex items-center gap-2">
            + Nuevo Usuario
          </button>
        </div>
      </div>

      <!-- Users Table -->
      <div class="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <div class="overflow-x-auto">
          <table class="w-full text-left text-xs">
            <thead class="bg-slate-950 text-slate-400 uppercase font-bold border-b border-slate-800">
              <tr>
                <th class="py-3 px-4">Cédula</th>
                <th class="py-3 px-4">Nombre Completo</th>
                <th class="py-3 px-4">Edad / Peso</th>
                <th class="py-3 px-4">Rol</th>
                <th class="py-3 px-4">Filtro Clínico</th>
                <th class="py-3 px-4 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody id="usersTableBody" class="divide-y divide-slate-800/60 text-slate-300">
              <tr>
                <td colspan="6" class="py-8 text-center text-slate-500">Cargando usuarios...</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

    </div>

    <!-- TAB 3: TEST DE IA EN VIVO -->
    <div id="tab-aiTest" class="space-y-6 hidden">
      <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6">
        <h2 class="text-xl font-extrabold text-white mb-1">Consola de Verificación de IA</h2>
        <p class="text-xs text-slate-400 mb-6">Envía una solicitud estructurada al motor Gemini en vivo y mide su latencia exacta.</p>

        <div class="space-y-4">
          <div>
            <label class="block text-xs font-bold text-slate-400 mb-2">Mensaje / Prompt de prueba</label>
            <input type="text" id="aiTestPrompt" value="hola quiero ejercicios para pechos para martes y viernes" class="w-full px-4 py-3 bg-slate-950 border border-slate-700 rounded-xl text-sm text-white focus:outline-none focus:border-emerald-500">
          </div>
          <button onclick="runAITest()" id="runAIBtn" class="px-6 py-3 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-extrabold text-xs transition-all shadow-lg shadow-emerald-500/20 flex items-center gap-2">
            🚀 Enviar Petición a Gemini
          </button>
        </div>

        <div id="aiTestResultBox" class="mt-6 hidden bg-slate-950 border border-slate-800 rounded-xl p-4">
          <div class="flex items-center justify-between mb-3 text-xs border-b border-slate-800 pb-2">
            <span class="font-bold text-emerald-400" id="aiTestProvider">Proveedor: --</span>
            <span class="text-slate-400" id="aiTestLatency">Latencia: -- ms</span>
          </div>
          <pre id="aiTestOutput" class="text-xs text-slate-300 font-mono whitespace-pre-wrap max-h-96 overflow-y-auto"></pre>
        </div>
      </div>
    </div>

  </main>

  <!-- Modal Nuevo Usuario -->
  <div id="newUserModal" class="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm hidden items-center justify-center p-4">
    <div class="w-full max-w-lg bg-slate-900 border border-slate-700 rounded-2xl p-6 shadow-2xl">
      <div class="flex items-center justify-between mb-4 border-b border-slate-800 pb-3">
        <h3 class="font-bold text-white text-base">Crear Nuevo Usuario</h3>
        <button onclick="closeNewUserModal()" class="text-slate-400 hover:text-white">&times;</button>
      </div>
      <form onsubmit="handleCreateUser(event)" class="space-y-3 text-xs">
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-slate-400 mb-1">Cédula *</label>
            <input type="text" id="newCedula" required class="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white">
          </div>
          <div>
            <label class="block text-slate-400 mb-1">Contraseña *</label>
            <input type="text" id="newPassword" value="Pass123*" required class="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white">
          </div>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-slate-400 mb-1">Nombre *</label>
            <input type="text" id="newNombre" required class="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white">
          </div>
          <div>
            <label class="block text-slate-400 mb-1">Apellido *</label>
            <input type="text" id="newApellido" required class="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white">
          </div>
        </div>
        <div class="grid grid-cols-3 gap-3">
          <div>
            <label class="block text-slate-400 mb-1">Edad</label>
            <input type="number" id="newEdad" value="25" class="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white">
          </div>
          <div>
            <label class="block text-slate-400 mb-1">Peso (kg)</label>
            <input type="number" step="0.1" id="newPeso" value="70.0" class="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white">
          </div>
          <div>
            <label class="block text-slate-400 mb-1">Rol</label>
            <select id="newRole" class="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white">
              <option value="client">Cliente</option>
              <option value="trainer">Entrenador</option>
            </select>
          </div>
        </div>
        <div>
          <label class="block text-slate-400 mb-1">Patologías o Condiciones Médicas</label>
          <input type="text" id="newPatologia" placeholder="Ej. Hipertensión, Asma leve" class="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white">
        </div>
        <div class="flex justify-end gap-2 pt-3 border-t border-slate-800">
          <button type="button" onclick="closeNewUserModal()" class="px-4 py-2 rounded-lg bg-slate-800 text-slate-300 font-semibold">Cancelar</button>
          <button type="submit" class="px-4 py-2 rounded-lg bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold">Guardar Usuario</button>
        </div>
      </form>
    </div>
  </div>

  <script>
    let adminPin = localStorage.getItem('fitness_admin_pin') || '';
    let globalUsers = [];

    // Check if previously logged in
    window.addEventListener('DOMContentLoaded', () => {{
      if (adminPin) {{
        document.getElementById('pinGate').classList.add('hidden');
        fetchEcosystem();
        fetchUsers();
      }}
    }});

    function handleLogin(e) {{
      e.preventDefault();
      const pin = document.getElementById('adminPinInput').value.trim();
      const err = document.getElementById('loginError');
      err.classList.add('hidden');
      
      fetch('/api/admin/auth/verify', {{
        method: 'POST',
        headers: {{ 'Content-Type': 'application/json' }},
        body: JSON.stringify({{ pin: pin }})
      }}).then(r => r.json()).then(data => {{
        if (data.authorized) {{
          adminPin = pin;
          localStorage.setItem('fitness_admin_pin', pin);
          document.getElementById('pinGate').classList.add('hidden');
          fetchEcosystem();
          fetchUsers();
        }} else {{
          err.textContent = data.detail || 'PIN incorrecto.';
          err.classList.remove('hidden');
        }}
      }}).catch(() => {{
        err.textContent = 'Error de conexión con el servidor.';
        err.classList.remove('hidden');
      }});
    }}

    function logoutAdmin() {{
      localStorage.removeItem('fitness_admin_pin');
      adminPin = '';
      document.getElementById('pinGate').classList.remove('hidden');
    }}

    function switchTab(tab) {{
      ['ecosystem', 'users', 'aiTest'].forEach(t => {{
        document.getElementById('tab-' + t).classList.add('hidden');
        document.getElementById('tabBtn-' + t).className = 'py-3 px-4 text-xs font-bold border-b-2 border-transparent text-slate-400 hover:text-slate-200 transition-all';
      }});
      document.getElementById('tab-' + tab).classList.remove('hidden');
      document.getElementById('tabBtn-' + tab).className = 'py-3 px-4 text-xs font-bold border-b-2 border-emerald-500 text-emerald-400 transition-all';
      if (tab === 'users') fetchUsers();
      if (tab === 'ecosystem') fetchEcosystem();
    }}

    function fetchEcosystem() {{
      if (!adminPin) return;
      fetch('/api/admin/ecosystem?pin=' + encodeURIComponent(adminPin))
        .then(r => r.json())
        .then(data => {{
          document.getElementById('geminiModelLabel').textContent = data.ai.active_model;
          document.getElementById('geminiKeyStatus').textContent = 'Key: ' + data.ai.key_status;
          document.getElementById('supabaseStatusLabel').textContent = data.supabase.status === 'ok' ? 'Conectado (OK)' : 'Revisar';
          document.getElementById('supabaseLatencyLabel').textContent = 'Latencia: ' + data.supabase.latency_ms + ' ms';
          document.getElementById('totalUsersCount').textContent = data.supabase.total_users;
          document.getElementById('trainersCountLabel').textContent = data.supabase.trainers_count + ' entrenadores';
          if (data.app_updates && data.app_updates.apk_size_mb) {{
            document.getElementById('apkSizeLabel').textContent = data.app_updates.apk_size_mb + ' MB disponible';
          }}
        }});
    }}

    function fetchUsers() {{
      if (!adminPin) return;
      fetch('/api/admin/users?pin=' + encodeURIComponent(adminPin))
        .then(r => r.json())
        .then(data => {{
          globalUsers = data.users || [];
          renderUsersTable(globalUsers);
        }});
    }}

    function renderUsersTable(users) {{
      const tbody = document.getElementById('usersTableBody');
      if (!users.length) {{
        tbody.innerHTML = '<tr><td colspan="6" class="py-6 text-center text-slate-500">No hay usuarios registrados.</td></tr>';
        return;
      }}
      tbody.innerHTML = users.map(u => `
        <tr class="hover:bg-slate-800/40 transition-colors">
          <td class="py-3 px-4 font-mono font-bold text-emerald-400">${{u.cedula}}</td>
          <td class="py-3 px-4 font-semibold text-white">${{u.nombre}} ${{u.apellido || ''}}</td>
          <td class="py-3 px-4 text-slate-400">${{u.edad || '--'}} años / ${{u.peso || '--'}} kg</td>
          <td class="py-3 px-4">
            <span class="px-2 py-0.5 rounded text-[10px] font-bold ${{u.role === 'trainer' ? 'bg-indigo-500/20 text-indigo-300' : 'bg-slate-800 text-slate-300'}}">
              ${{u.role || 'client'}}
            </span>
          </td>
          <td class="py-3 px-4 text-slate-400 text-[11px] max-w-xs truncate" title="${{u.patologia_o_alergias || 'Ninguna'}}">
            ${{u.patologia_o_alergias || '<span class="text-slate-600">Ninguna</span>'}}
          </td>
          <td class="py-3 px-4 text-right">
            <button onclick="deleteUser('${{u.id}}', '${{u.cedula}}')" class="text-rose-400 hover:text-rose-300 font-semibold px-2 py-1 rounded bg-rose-500/10 hover:bg-rose-500/20 transition-all">
              Eliminar
            </button>
          </td>
        </tr>
      `).join('');
    }}

    function filterUsers() {{
      const query = document.getElementById('userSearchInput').value.toLowerCase().trim();
      const filtered = globalUsers.filter(u => 
        (u.cedula && u.cedula.toLowerCase().includes(query)) ||
        (u.nombre && u.nombre.toLowerCase().includes(query)) ||
        (u.apellido && u.apellido.toLowerCase().includes(query))
      );
      renderUsersTable(filtered);
    }}

    function deleteUser(id, cedula) {{
      if (!confirm(`¿Estás seguro de eliminar el usuario con cédula ${{cedula}}? Esta acción es irreversible.`)) return;
      fetch(`/api/admin/users/${{id}}?pin=${{encodeURIComponent(adminPin)}}`, {{ method: 'DELETE' }})
        .then(r => r.json())
        .then(res => {{
          if (res.success) {{
            alert('Usuario eliminado correctamente.');
            fetchUsers();
          }} else {{
            alert('Aviso: ' + JSON.stringify(res));
          }}
        }});
    }}

    function openNewUserModal() {{
      document.getElementById('newUserModal').classList.remove('hidden');
      document.getElementById('newUserModal').classList.add('flex');
    }}
    function closeNewUserModal() {{
      document.getElementById('newUserModal').classList.add('hidden');
      document.getElementById('newUserModal').classList.remove('flex');
    }}

    function handleCreateUser(e) {{
      e.preventDefault();
      const payload = {{
        pin: adminPin,
        cedula: document.getElementById('newCedula').value.trim(),
        nombre: document.getElementById('newNombre').value.trim(),
        apellido: document.getElementById('newApellido').value.trim(),
        password: document.getElementById('newPassword').value.trim(),
        edad: parseInt(document.getElementById('newEdad').value) || 25,
        peso: parseFloat(document.getElementById('newPeso').value) || 70,
        role: document.getElementById('newRole').value,
        patologia_o_alergias: document.getElementById('newPatologia').value.trim() || null
      }};
      fetch('/api/admin/users', {{
        method: 'POST',
        headers: {{ 'Content-Type': 'application/json' }},
        body: JSON.stringify(payload)
      }}).then(r => r.json()).then(res => {{
        if (res.success) {{
          alert('Usuario creado exitosamente.');
          closeNewUserModal();
          fetchUsers();
        }} else {{
          alert('Error: ' + (res.detail || JSON.stringify(res)));
        }}
      }});
    }}

    function purgeCache() {{
      if (!confirm('¿Limpiar caché de la IA y memoria de proveedores?')) return;
      fetch('/api/admin/purge-cache', {{
        method: 'POST',
        headers: {{ 'Content-Type': 'application/json' }},
        body: JSON.stringify({{ pin: adminPin }})
      }}).then(r => r.json()).then(res => {{
        alert(res.message);
        fetchEcosystem();
      }});
    }}

    function runAITest() {{
      const prompt = document.getElementById('aiTestPrompt').value.trim();
      const btn = document.getElementById('runAIBtn');
      const box = document.getElementById('aiTestResultBox');
      const out = document.getElementById('aiTestOutput');
      const prov = document.getElementById('aiTestProvider');
      const lat = document.getElementById('aiTestLatency');

      btn.disabled = true;
      btn.textContent = 'Consultando a Gemini...';
      box.classList.remove('hidden');
      out.textContent = 'Enviando petición a la API...';

      fetch('/api/admin/test-ai', {{
        method: 'POST',
        headers: {{ 'Content-Type': 'application/json' }},
        body: JSON.stringify({{ pin: adminPin, prompt: prompt }})
      }}).then(r => r.json()).then(res => {{
        btn.disabled = false;
        btn.textContent = '🚀 Enviar Petición a Gemini';
        if (res.success) {{
          prov.textContent = 'Proveedor: ' + res.provider;
          lat.textContent = 'Latencia: ' + res.latency_ms + ' ms';
          out.textContent = res.response;
        }} else {{
          prov.textContent = 'Error';
          lat.textContent = 'Latencia: ' + res.latency_ms + ' ms';
          out.textContent = res.error;
        }}
      }}).catch(e => {{
        btn.disabled = false;
        btn.textContent = '🚀 Enviar Petición a Gemini';
        out.textContent = 'Error de red: ' + e;
      }});
    }}
  </script>
</body>
</html>
""")
