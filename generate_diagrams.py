import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch

plt.rcParams['font.family'] = 'DejaVu Sans'
plt.rcParams['font.size'] = 10

def create_deployment_diagram():
    fig, ax = plt.subplots(figsize=(11.5, 7.5), dpi=300)
    ax.set_xlim(0, 115)
    ax.set_ylim(0, 75)
    ax.axis('off')
    fig.patch.set_facecolor('#FFFFFF')
    ax.set_facecolor('#FFFFFF')

    # Titulo superior
    ax.text(57.5, 71.5, "DIAGRAMA DE DESPLIEGUE FÍSICO DE LA INFRAESTRUCTURA EN LA NUBE", 
            ha='center', va='center', fontsize=12, fontweight='bold', color='#1E293B')
    ax.text(57.5, 68.8, "Topología de Hardware, Servidores Cloud, Protocolos de Comunicación y Contenedores", 
            ha='center', va='center', fontsize=9.5, fontstyle='italic', color='#64748B')

    def draw_node(x, y, w, h, title, subtitle, items, color_header='#1E3A8A', color_bg='#F8FAFC'):
        box = FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.5,rounding_size=1.5",
                             facecolor=color_bg, edgecolor='#CBD5E1', linewidth=1.4)
        ax.add_patch(box)
        header = FancyBboxPatch((x, y + h - 7.5), w, 7.5, boxstyle="round,pad=0.2,rounding_size=1.2",
                                facecolor=color_header, edgecolor=color_header, linewidth=1)
        ax.add_patch(header)
        ax.text(x + w/2, y + h - 3.2, title, ha='center', va='center', fontsize=10, fontweight='bold', color='#FFFFFF')
        ax.text(x + w/2, y + h - 5.8, subtitle, ha='center', va='center', fontsize=8, color='#E2E8F0', fontstyle='italic')
        
        for idx, item in enumerate(items):
            iy = y + h - 11 - (idx * 4.6)
            c_box = FancyBboxPatch((x + 2, iy - 1.8), w - 4, 3.8, boxstyle="round,pad=0.2,rounding_size=0.8",
                                   facecolor='#FFFFFF', edgecolor='#E2E8F0', linewidth=1)
            ax.add_patch(c_box)
            ax.text(x + 4, iy + 0.1, f"«artefacto» {item}", ha='left', va='center', fontsize=8, color='#334155')

    # 1. Nodo Cliente
    draw_node(5, 18, 28, 44, 
              "«dispositivo» Cliente", 
              "Smartphone / Navegador Web",
              ["Frontend Multiplataforma (Flutter)", 
               "Web Browser (Brave / Chrome)", 
               "Motor de Renderizado CanvasKit",
               "Almacenamiento Local (SQLite/Cache)", 
               "Módulo Reconocimiento de Voz STT"],
              color_header='#2563EB', color_bg='#EFF6FF')

    # 2. Nodo Servidor de Aplicación (Render Cloud)
    draw_node(43, 30, 31, 34, 
              "«servidor» Render Cloud", 
              "Contenedor Linux Ubuntu (Cloud)",
              ["Backend RESTful (FastAPI / Python)", 
               "Servidor ASGI Uvicorn", 
               "Motor de Inferencia y Reglas IA",
               "Gestor Memoria de Equipamiento",
               "Daemon Keep-Alive (Ping 14 min)"],
              color_header='#0D9488', color_bg='#F0FDFA')

    # 3. Nodo Servidor de Base de Datos (Supabase Cloud)
    draw_node(83, 30, 27, 34, 
              "«servidor» Supabase Cloud", 
              "Instancia PostgreSQL Gestionada",
              ["PostgreSQL 15 (Motor Relacional)", 
               "Políticas de Seguridad RLS", 
               "Módulo de Autenticación JWT",
               "Storage Buckets (Fotos Progreso)"],
              color_header='#4338CA', color_bg='#EEF2FF')

    # 4. Nodo CDN Multimedia (GitHub Content Delivery)
    draw_node(43, 6, 31, 19, 
              "«servidor» GitHub CDN", 
              "Repositorio Multimedia Seguro",
              ["Catálogo Biomecánico Ejercicios", 
               "Animaciones Anatómicas (GIFs HD)"],
              color_header='#475569', color_bg='#F8FAFC')

    # Flechas
    ax.annotate('', xy=(43, 48), xytext=(33, 48),
                arrowprops=dict(arrowstyle="<->", color='#0284C7', lw=1.8))
    ax.text(38, 51.5, "HTTPS / TLS 1.3\n(Puerto 443 / REST)", ha='center', va='center', fontsize=7.5, fontweight='bold', color='#0284C7')

    ax.annotate('', xy=(83, 48), xytext=(74, 48),
                arrowprops=dict(arrowstyle="<->", color='#4338CA', lw=1.8))
    ax.text(78.5, 51.5, "PostgreSQL Protocol\n(Puerto 5432 / SSL)", ha='center', va='center', fontsize=7.5, fontweight='bold', color='#4338CA')

    ax.annotate('', xy=(43, 16), xytext=(30, 18),
                arrowprops=dict(arrowstyle="->", color='#64748B', lw=1.5, ls='--'))
    ax.text(32, 12.5, "HTTP GET (CDN Media)\nStreaming de GIFs", ha='center', va='center', fontsize=7.5, color='#475569')

    ax.annotate('', xy=(58.5, 25), xytext=(58.5, 30),
                arrowprops=dict(arrowstyle="->", color='#64748B', lw=1.5, ls='--'))
    ax.text(64, 27.5, "HTTP GET Cache", ha='left', va='center', fontsize=7.5, color='#475569')

    plt.tight_layout()
    os.makedirs('docs', exist_ok=True)
    out_path = 'docs/figura7_diagrama_despliegue.png'
    plt.savefig(out_path, dpi=300, facecolor='#FFFFFF', edgecolor='none')
    plt.close()
    print(f"Figura 7 guardada en: {out_path}")

def create_navigation_diagram():
    fig, ax = plt.subplots(figsize=(12, 8.5), dpi=300)
    ax.set_xlim(0, 120)
    ax.set_ylim(0, 85)
    ax.axis('off')
    fig.patch.set_facecolor('#FFFFFF')
    ax.set_facecolor('#FFFFFF')

    # Titulo
    ax.text(60, 82, "MAPA DE NAVEGACIÓN Y CARTA ESTRUCTURADA DE LA APLICACIÓN", 
            ha='center', va='center', fontsize=12, fontweight='bold', color='#1E293B')
    ax.text(60, 79.5, "Flujo Jerárquico de Pantallas, Control de Roles y Transición Operativa", 
            ha='center', va='center', fontsize=9.5, fontstyle='italic', color='#64748B')

    def draw_screen(x, y, w, h, title, subtitle="", color_header='#1E3A8A', color_bg='#FFFFFF'):
        box = FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.3,rounding_size=1.2",
                             facecolor=color_bg, edgecolor=color_header, linewidth=1.3)
        ax.add_patch(box)
        header = FancyBboxPatch((x, y + h - 4.5), w, 4.5, boxstyle="round,pad=0.1,rounding_size=1.0",
                                facecolor=color_header, edgecolor=color_header, linewidth=1)
        ax.add_patch(header)
        ax.text(x + w/2, y + h - 2.2, title, ha='center', va='center', fontsize=8.5, fontweight='bold', color='#FFFFFF')
        if subtitle:
            ax.text(x + w/2, y + (h - 4.5)/2, subtitle, ha='center', va='center', fontsize=7.5, color='#334155', multialignment='center')

    # Nivel 1: Splash Screen
    draw_screen(48, 70, 24, 7, "Splash Screen", "Inicialización y Carga de Caché", color_header='#334155', color_bg='#F8FAFC')

    # Nivel 2: AuthGate
    draw_screen(48, 59, 24, 7.5, "AuthGate Router", "Validación de Token JWT y Sesión", color_header='#2563EB', color_bg='#EFF6FF')

    # Nivel 3: Login y Registro
    draw_screen(26, 48, 22, 7.5, "Pantalla de Login", "Acceso con Cédula y Clave", color_header='#0284C7', color_bg='#F0F9FF')
    draw_screen(72, 48, 22, 7.5, "Pantalla de Registro", "Captura de Perfil y Rol", color_header='#0284C7', color_bg='#F0F9FF')

    # Nivel 4: Bifurcación de Roles
    draw_screen(12, 34, 48, 7.5, "Dashboard del Alumno", "Navegación Inferior (Coach IA, Cronograma, Nutrición, Perfil)", color_header='#0D9488', color_bg='#F0FDFA')
    draw_screen(68, 34, 42, 7.5, "Consola del Entrenador", "Gestión de Alumnos, Ficha Técnica y Agenda", color_header='#7C3AED', color_bg='#FAF5FF')

    # Nivel 5 - Submódulos del Alumno
    draw_screen(2, 19, 17, 9.5, "Coach IA", "Chat con Micrófono STT\ny Memoria de Equipo", color_header='#0D9488', color_bg='#FFFFFF')
    draw_screen(21, 19, 17, 9.5, "Cronograma", "Plan Semanal y Rutinas\nInyectadas Activas", color_header='#0D9488', color_bg='#FFFFFF')
    draw_screen(40, 19, 17, 9.5, "Nutrición", "Menú Sincronizado\n(Desayuno, Almuerzo, Cena)", color_header='#0D9488', color_bg='#FFFFFF')

    # Nivel 5 - Submódulos del Entrenador
    draw_screen(64, 19, 21, 9.5, "Ficha de Alumnos", "Alertas Rojas de Lesión [!]\ny Monitoreo Biomecánico", color_header='#DC2626', color_bg='#FEF2F2')
    draw_screen(88, 19, 21, 9.5, "Agenda de Citas", "Horarios y Sesiones\n(workout_sessions)", color_header='#7C3AED', color_bg='#FFFFFF')

    # Nivel 6 - Pantallas Especiales de Nivel Profundo
    draw_screen(2, 4, 17, 9.5, "Modal Check-in", "Evaluación de Dolor,\nEnergía y Entorno", color_header='#D97706', color_bg='#FFFBEB')
    draw_screen(21, 4, 36, 9.5, "Anatomía 3D / Visor Biomecánico", "Animación GIF HD · Foco Muscular Agonista/Sinergistas\nTempo, Postura y Prevención de Lesiones", color_header='#059669', color_bg='#ECFDF5')

    # Flechas
    ax.annotate('', xy=(60, 66.5), xytext=(60, 70), arrowprops=dict(arrowstyle="->", color='#64748B', lw=1.5))
    ax.annotate('', xy=(37, 55.5), xytext=(52, 59), arrowprops=dict(arrowstyle="->", color='#64748B', lw=1.3))
    ax.annotate('', xy=(83, 55.5), xytext=(68, 59), arrowprops=dict(arrowstyle="->", color='#64748B', lw=1.3))
    ax.annotate('', xy=(36, 41.5), xytext=(36, 48), arrowprops=dict(arrowstyle="->", color='#0D9488', lw=1.5))
    ax.annotate('', xy=(89, 41.5), xytext=(83, 48), arrowprops=dict(arrowstyle="->", color='#7C3AED', lw=1.5))

    ax.annotate('', xy=(10.5, 28.5), xytext=(24, 34), arrowprops=dict(arrowstyle="->", color='#0D9488', lw=1.3))
    ax.annotate('', xy=(29.5, 28.5), xytext=(36, 34), arrowprops=dict(arrowstyle="->", color='#0D9488', lw=1.3))
    ax.annotate('', xy=(48.5, 28.5), xytext=(48, 34), arrowprops=dict(arrowstyle="->", color='#0D9488', lw=1.3))

    ax.annotate('', xy=(74.5, 28.5), xytext=(80, 34), arrowprops=dict(arrowstyle="->", color='#7C3AED', lw=1.3))
    ax.annotate('', xy=(98.5, 28.5), xytext=(98, 34), arrowprops=dict(arrowstyle="->", color='#7C3AED', lw=1.3))

    ax.annotate('', xy=(10.5, 13.5), xytext=(10.5, 19), arrowprops=dict(arrowstyle="<->", color='#D97706', lw=1.4))
    ax.annotate('', xy=(30, 13.5), xytext=(16, 19), arrowprops=dict(arrowstyle="->", color='#059669', lw=1.4))
    ax.annotate('', xy=(39, 13.5), xytext=(32, 19), arrowprops=dict(arrowstyle="->", color='#059669', lw=1.4))

    plt.tight_layout()
    os.makedirs('docs', exist_ok=True)
    out_path = 'docs/figura8_mapa_navegacion.png'
    plt.savefig(out_path, dpi=300, facecolor='#FFFFFF', edgecolor='none')
    plt.close()
    print(f"Figura 8 guardada en: {out_path}")

if __name__ == '__main__':
    create_deployment_diagram()
    create_navigation_diagram()
