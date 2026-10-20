# -*- coding: utf-8 -*-
"""
Script para generar el documento oficial en Word (.docx) y visor interactivo tipo Notion (.html)
para la evaluación docente y defensa de proyecto.
"""

import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), hex_color)
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_cell_left_border(cell, hex_color="0D9488", sz="24"):
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    left = OxmlElement('w:left')
    left.set(qn('w:val'), 'single')
    left.set(qn('w:sz'), sz)
    left.set(qn('w:space'), '0')
    left.set(qn('w:color'), hex_color)
    tcBorders.append(left)
    for side in ['top', 'bottom', 'right']:
        edge = OxmlElement(f'w:{side}')
        edge.set(qn('w:val'), 'none')
        tcBorders.append(edge)
    tcPr.append(tcBorders)

def add_callout(doc, text, title=None, emoji="💡"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    tbl.columns[0].width = Inches(6.5)
    
    cell = tbl.cell(0, 0)
    set_cell_background(cell, "F0FDFA")
    set_cell_left_border(cell, "0D9488", "24")
    set_cell_margins(cell, top=140, bottom=140, left=200, right=200)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.15
    
    if title:
        run_title = p.add_run(f"{emoji} {title}\n")
        run_title.bold = True
        run_title.font.name = "Calibri"
        run_title.font.size = Pt(10.5)
        run_title.font.color.rgb = RGBColor(15, 76, 92)
        
    run_text = p.add_run(text)
    run_text.font.name = "Calibri"
    run_text.font.size = Pt(10)
    run_text.font.color.rgb = RGBColor(30, 41, 59)
    doc.add_paragraph() # spacing

def format_table(tbl, col_widths, headers, data):
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    
    # Header row
    hdr_cells = tbl.rows[0].cells
    for i, title in enumerate(headers):
        hdr_cells[i].text = title
        set_cell_background(hdr_cells[i], "0F192B")
        set_cell_margins(hdr_cells[i], top=120, bottom=120, left=140, right=140)
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        for run in p.runs:
            run.font.name = "Calibri"
            run.font.bold = True
            run.font.size = Pt(10)
            run.font.color.rgb = RGBColor(255, 255, 255)
            
    for row_idx, row_data in enumerate(data):
        row_cells = tbl.add_row().cells
        bg_color = "F8FAFC" if row_idx % 2 == 1 else "FFFFFF"
        for col_idx, cell_value in enumerate(row_data):
            row_cells[col_idx].text = str(cell_value)
            set_cell_background(row_cells[col_idx], bg_color)
            set_cell_margins(row_cells[col_idx], top=90, bottom=90, left=140, right=140)
            p = row_cells[col_idx].paragraphs[0]
            p.paragraph_format.line_spacing = 1.1
            for run in p.runs:
                run.font.name = "Calibri"
                run.font.size = Pt(9.5)
                run.font.color.rgb = RGBColor(30, 41, 59)
                
    for row in tbl.rows:
        for idx, width in enumerate(col_widths):
            row.cells[idx].width = Inches(width)

def build_docx():
    doc = Document()
    
    # Page setup
    sections = doc.sections
    for s in sections:
        s.top_margin = Inches(0.8)
        s.bottom_margin = Inches(0.8)
        s.left_margin = Inches(0.8)
        s.right_margin = Inches(0.8)
        
    # Title / Header
    title_p = doc.add_paragraph()
    title_p.paragraph_format.space_before = Pt(0)
    title_p.paragraph_format.space_after = Pt(4)
    run_tag = title_p.add_run("DOCUMENTO MAESTRO DE EVALUACIÓN ACADÉMICA · DEFENSE BRIEF\n")
    run_tag.font.name = "Calibri"
    run_tag.font.size = Pt(9.5)
    run_tag.font.bold = True
    run_tag.font.color.rgb = RGBColor(13, 148, 136) # Teal
    
    run_title = title_p.add_run("AI FITNESS COACH — ENTRENADOR INTELIGENTE Y NUTRICIÓN ADAPTATIVA")
    run_title.font.name = "Calibri"
    run_title.font.size = Pt(20)
    run_title.font.bold = True
    run_title.font.color.rgb = RGBColor(15, 25, 43)
    
    sub_p = doc.add_paragraph()
    sub_p.paragraph_format.space_after = Pt(16)
    run_sub = sub_p.add_run("Arquitectura de Software, Motores de IA, Base de Datos Supabase (PostgreSQL) y Especificación Técnica por Pantallas")
    run_sub.font.name = "Calibri"
    run_sub.font.size = Pt(11)
    run_sub.font.italic = True
    run_sub.font.color.rgb = RGBColor(71, 85, 105)
    
    # Metadata Table
    meta_tbl = doc.add_table(rows=1, cols=4)
    format_table(
        meta_tbl,
        [1.8, 1.8, 1.7, 1.6],
        ["Plataforma", "Versión Actual", "Base de Datos", "Servidor Cloud"],
        [["Flutter (Dart 3.x)", "v1.0.58 (Render Activo)", "Supabase PostgreSQL 17", "FastAPI en Render Cloud"]]
    )
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    # Callout: Resumen
    add_callout(
        doc,
        "Este documento presenta de forma pedagógica, estructurada y profesional todas las decisiones de arquitectura de 'AI Fitness Coach'. Diseñado especialmente para facilitar la interpretación de jurados docentes y profesores de sistemas, abarcando desde el backend asíncrono y los motores de IA con failover, hasta la estructura relacional de Supabase y las fuentes nutricionales adaptadas al contexto venezolano.",
        title="Objetivo del Informe para la Profesora",
        emoji="🎯"
    )
    
    # 1. Visión General
    h1 = doc.add_heading("1. Visión General del Sistema y Concepto de Sinergia", level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    
    p = doc.add_paragraph(
        "AI Fitness Coach es una plataforma multiplataforma de entrenamiento deportivo, planificación nutricional y acompañamiento con Inteligencia Artificial generativa. Conecta a usuarios con planes hiper-personalizados y permite la supervisión en tiempo real por parte de preparadores físicos y entrenadores personales (modelo B2B).\n\n"
        "El núcleo científico del proyecto radica en la SINERGIA DEPORTIVA-NUTRICIONAL: el entrenamiento y la alimentación no se manejan como registros inconexos, sino como una unidad biológica indisoluble. Cada día de la semana posee una rutina calibrada biomecánicamente, un menú alimenticio complementario y una justificación metabólica explícita de cómo los macronutrientes reparan el tejido muscular trabajado según la intensidad de la sesión."
    )
    p.paragraph_format.line_spacing = 1.15
    p.paragraph_format.space_after = Pt(8)
    
    # 2. Stack Tecnológico
    h1 = doc.add_heading("2. Stack Tecnológico Integral", level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    
    stack_data = [
        ["Frontend Móvil & Web", "Flutter (Dart 3.1+) / CanvasKit", "Permite un código base único de alto rendimiento compilado a APK Android nativo y Web PWA a 60 FPS con Material Design 3."],
        ["Backend RESTful", "Python 3.11 + FastAPI + Uvicorn", "Servidor asíncrono de alto desempeño con serialización automática mediante Pydantic y llamadas no bloqueantes a LLMs."],
        ["Base de Datos Cloud", "Supabase (PostgreSQL 17)", "Motor relacional estándar con Row Level Security (RLS), integridad referencial y autenticación segura con JWT."],
        ["Persistencia Local", "SQLite (sqflite 2.4+)", "Base de datos embebida en el dispositivo para registrar sesiones completadas, cálculo de rachas y modo offline."],
        ["Visor Anatómico 3D", "model_viewer_plus / WebGL / glTF", "Renderiza maniquíes anatómicos tridimensionales con interacción táctil (rotación 360°, zoom orbital) para prevención de lesiones."],
        ["Atlas Muscular 2D", "flutter_body_atlas (SVG dinámico)", "Mapa corporal interactivo que resalta grupos musculares trabajados o lesionados."],
        ["Entrada por Voz", "speech_to_text (Español)", "Captura comandos de voz y check-ins para dictar al Coach IA sin necesidad de teclear."],
        ["Despliegue & Nube", "Render Cloud PaaS + Dockerfile", "Alojamiento en contenedor Linux con sincronización continua y conmutación transparente con servidor local."]
    ]
    st_tbl = doc.add_table(rows=1, cols=3)
    format_table(st_tbl, [1.8, 2.0, 3.1], ["Capa / Componente", "Tecnología Utilizada", "Justificación Didáctica y Técnica"], stack_data)
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    # 3. Motores de IA
    h1 = doc.add_heading("3. Motores de Inteligencia Artificial y Cadena con Failover", level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    
    doc.add_paragraph(
        "Para garantizar una disponibilidad del 100% y evitar caídas por saturación o límites de cuota (especialmente en pruebas académicas), el sistema implementa una Cadena de Proveedores de IA con Conmutación por Error (Multi-Provider Cascade Failover) definida en 'app.services.ai_providers':\n\n"
        "1. Google Gemini API (Proveedor Primario): Seleccionado por su alta capacidad de razonamiento y soporte nativo para generación de respuestas en esquema JSON rígido.\n"
        "2. OpenRouter Free Pool (Primer Respaldo): Accede de forma gratuita y balanceada a modelos de pesos abiertos de última generación: Gemma 4, Qwen 3.8 27B y Nemotron 120B.\n"
        "3. Mistral AI API (Segundo Respaldo): Utiliza 'mistral-small-latest' para garantizar redacción en español natural, comprensible y empática.\n"
        "4. Groq Cloud Engine (Tercer Respaldo): Modelos Llama para inferencia rápida.\n"
        "5. Algoritmo Fail-Safe Local: Si el dispositivo no tiene internet o fallan todas las APIs externas, el backend activa automáticamente la generación algorítmica de 'weekly_plan.py', respetando las restricciones médicas del usuario sin arrojar error 500."
    ).paragraph_format.line_spacing = 1.15
    
    add_callout(
        doc,
        "Directivas Éticas y Preventivas del Prompt del Coach:\n"
        "• Nunca emite diagnósticos médicos ni prescribe fármacos.\n"
        "• Si el alumno reporta dolor articular agudo, la IA sustituye ejercicios lesivos por protocolos de movilidad y advierte la necesidad de atención profesional presencial.\n"
        "• Regla Estricta de Coherencia de Equipo: Si el usuario entrena en casa con mancuernas, la IA jamás propone poleas ni máquinas de gimnasio.",
        title="Protocolo de Seguridad y Biomecánica del LLM",
        emoji="🛡️"
    )
    
    # 4. Origen de Entrenamientos y Nutrición
    h1 = doc.add_heading("4. Origen de Entrenamientos y Planes Alimenticios", level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    
    doc.add_paragraph(
        "Frecuentemente surge la duda de si la IA inventa ejercicios alucinados o comidas extravagantes. En AI Fitness Coach, la IA actúa como un seleccionador inteligente sobre catálogos científicos ya validados:\n\n"
        "A) Proveniencia de los Entrenamientos:\n"
        "• Base de Datos Open Source Free Exercise DB: Catálogo de más de 800 ejercicios indexados con clasificación anatómica, nivel de intensidad y grupos musculares primarios/secundarios.\n"
        "• Catálogo Visual de Demostración (ExerciseGymGifsDB): Indexado en 'gifs_db.json' y renderizado en vivo mediante GIFs animados de técnica biomecánica impecable.\n"
        "• Algoritmo de Periodización 48-72 Horas: Asegura que el músculo trabajado tenga entre 48 y 72 horas de recuperación activa antes de volver a ser sobrecargado (Split de Tren Superior, Tren Inferior y Descanso Activo).\n\n"
        "B) Proveniencia de los Planes Alimenticios (Adaptación Real al Mercado Venezolano):\n"
        "• Base Nutricional Local ('nutrition_database.dart'): Diseñada específicamente con ingredientes cotidianos, económicos y accesibles en los mercados venezolanos (arepa de maíz, avena, cambur, huevos sancochados/pericos, pollo, carne molida magra, atún, sardinas, caraotas negras, lentejas, arroz, batata, yuca, plátano verde o maduro y aguacate criollo).\n"
        "• Cuatro Objetivos Nutricionales Clínicos:\n"
        "   1. Hipertrofia (Masa Muscular): Superávit calórico controlado con proteína accesible y carbohidratos complejos.\n"
        "   2. Pérdida de Grasa (Definición): Déficit calórico saciante priorizando vegetales económicos locales (repollo, pepino, calabacín, chayota) y proteína magra.\n"
        "   3. Resistencia Cardio: Optimización de reservas de glucógeno mediante tubérculos criollos y frutas hidratantes.\n"
        "   4. Salud y Energía: Adaptación criolla de la dieta mediterránea con fibra prebiótica y omega-3 accesible (sardina/granos)."
    ).paragraph_format.line_spacing = 1.15
    
    # 5. Estructura de la Base de Datos
    h1 = doc.add_heading("5. Estructura de la Base de Datos en Supabase (PostgreSQL)", level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    
    doc.add_paragraph(
        "La base de datos se encuentra alojada en Supabase (PostgreSQL 17), diseñada bajo Tercera Forma Normal (3FN). Separa con rigor las credenciales criptográficas, los perfiles de salud, la agenda deportiva y el portal B2B del entrenador."
    )
    
    # Insert schema image if exists
    schema_img_path = r"C:/Users/miope/.gemini/antigravity/brain/d1e1171e-d6c3-4ed8-8769-1402d5e1e556/.user_uploaded/media_1792242449252_ee263181.png"
    if os.path.exists(schema_img_path):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.paragraph_format.space_before = Pt(6)
        p_img.paragraph_format.space_after = Pt(4)
        run_img = p_img.add_run()
        run_img.add_picture(schema_img_path, width=Inches(6.2))
        
        cap = doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        cap.paragraph_format.space_after = Pt(12)
        r_cap = cap.add_run("Figura 1: Diagrama Entidad-Relación implementado en Supabase PostgreSQL.")
        r_cap.font.name = "Calibri"
        r_cap.font.size = Pt(9)
        r_cap.font.italic = True
        r_cap.font.color.rgb = RGBColor(100, 116, 139)
        
    db_tables_data = [
        ["auth.users", "uuid (PK)", "Sistema nativo de Supabase Auth. Gestiona correo, contraseñas con hash criptográfico y tokens JWT. Ninguna clave viaja en texto plano."],
        ["usuarios", "id (PK/FK) -> auth.users.id", "Perfil maestro del usuario. Contiene cédula, nombres, edad, peso, alergias alimentarias, patologías, lesiones actuales y rol ('client' o 'trainer')."],
        ["workout_sessions", "id (PK), client_id (FK), trainer_id (FK)", "Calendario de sesiones de entrenamiento programadas y completadas entre el atleta y el preparador personal."],
        ["trainer_schedules", "id (PK), trainer_id (FK)", "Configuración de la jornada del entrenador: día de la semana (1-7), hora inicio, hora fin y aforo máximo de alumnos."],
        ["trainer_chat", "id (PK), client_id, trainer_id, sender_id", "Canal de mensajería directa y privada entre el entrenador y su alumno para soporte continuo."],
        ["trainer_announcements", "id (PK), trainer_id (FK)", "Muro de anuncios digitales emitidos por el entrenador para difusión masiva a todos sus atletas."],
        ["progress_photos", "id (PK), user_id (FK)", "Historial de fotografías físicas almacenadas en Supabase Storage, vinculadas a reportes de evolución morfológica con IA."],
        ["aprendizaje_plan_anonimo", "id (PK), proveedor, calificacion", "Módulo de telemetría ética: registra calificaciones anónimas (1-5) del plan sin almacenar nombres ni datos médicos (cumplimiento GDPR)."]
    ]
    db_tbl = doc.add_table(rows=1, cols=3)
    format_table(db_tbl, [1.8, 1.9, 3.2], ["Tabla en Supabase", "Claves y Relaciones", "Propósito Didáctico y Técnico"], db_tables_data)
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    # 6. Pantallas de la Aplicación
    h1 = doc.add_heading("6. Arquitectura y Funcionalidad por Pantalla", level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    
    home_img_path = r"C:/Users/miope/.gemini/antigravity/brain/d1e1171e-d6c3-4ed8-8769-1402d5e1e556/.user_uploaded/media_1792242348496_737147d5.png"
    if os.path.exists(home_img_path):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.paragraph_format.space_before = Pt(6)
        p_img.paragraph_format.space_after = Pt(4)
        run_img = p_img.add_run()
        run_img.add_picture(home_img_path, width=Inches(6.2))
        
        cap = doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        cap.paragraph_format.space_after = Pt(12)
        r_cap = cap.add_run("Figura 2: Interfaz Principal de la Aplicación Móvil (v1.0.52 - Conexión Cloud Render Activa).")
        r_cap.font.name = "Calibri"
        r_cap.font.size = Pt(9)
        r_cap.font.italic = True
        r_cap.font.color.rgb = RGBColor(100, 116, 139)
        
    screens_data = [
        ["1. Inicio (HomeScreen)", "home_screen.dart", "AppBar con estado de conexión Render, insignias reactivas de notificaciones (punto rojo), chips de objetivo y nivel físico, acceso a Anatomía 3D y 4 tarjetas modulares."],
        ["2. Coach IA (CoachScreen)", "coach_screen.dart", "Chat generativo con reconocimiento de voz (Speech-to-Text), modal de check-in inicial, renderizado de tarjetas de ejercicios con GIFs biomecánicos y botón de inyección a cronograma."],
        ["3. Rutinas (WorkoutsScreen)", "workouts_screen.dart", "Cronograma de la semana activa, desglose de series/reps/tempo, marcado de sesiones completadas y sincronización con SQLite local para rachas."],
        ["4. Anatomía 3D (AnatomyScreen)", "anatomy_workout_screen.dart", "Visor 3D orbital táctil (WebGL / model_viewer_plus) con panel deslizante de músculos agonistas, sinergistas y advertencias preventivas."],
        ["5. Nutrición (NutritionScreen)", "nutrition_screen.dart", "Selector de 4 metas nutricionales, menú de 4 tiempos con ingredientes venezolanos económicos y tarjeta didáctica de Sinergia Nutricional Diaria."],
        ["6. Progreso (ProgressScreen)", "progress_screen.dart", "Carga de fotos de evolución física (cámara/galería) con peticiones multipart al storage cloud y retroalimentación morfológica."],
        ["7. Mi Perfil y Salud", "user_profile_screen.dart", "Gestión de restricciones (alergias y lesiones), histórico de entrenamientos locales y alternancia de servidores (Cloud vs Local)."],
        ["8. Notificaciones", "notifications_screen.dart", "Disparadores automáticos: aviso de fin de ciclo semanal, alertas de cronograma vacío y recordatorio diario de entrenamiento."],
        ["9. Portal Entrenador B2B", "trainer_shell.dart", "Pestaña de alumnos con ALERTA ROJA (🔴) en vivo para alumnos lesionados, ficha técnica de ejercicios/comidas, agenda de sesiones y chat."]
    ]
    sc_tbl = doc.add_table(rows=1, cols=3)
    format_table(sc_tbl, [1.8, 1.8, 3.3], ["Pantalla / Vista", "Archivo Fuente", "Tecnología y Funcionalidad Implementada"], screens_data)
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    # 7. Módulos del Sistema
    h1 = doc.add_heading("7. Módulos del Sistema y sus Funciones", level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    
    modules_data = [
        ["Módulo de Autenticación y Seguridad", "Gestiona el ciclo de vida de sesiones de usuario con JWT, cifrado de claves en Supabase Auth y validación de roles ('client' vs 'trainer')."],
        ["Módulo del Coach IA y Memoria Adaptativa", "Procesa audio y texto, recuerda el equipo de casa del usuario de forma persistente y genera planes sin pisar la semana en curso."],
        ["Módulo de Entrenamiento y Biomecánica", "Administra la visualización 2D (GIFs), 3D (WebGL) y el registro offline de sesiones en SQLite local."],
        ["Módulo Nutricional Adaptativo", "Alinea las demandas calóricas del entrenamiento con opciones alimenticias cultural y económicamente viables en el entorno local."],
        ["Módulo de Supervisión del Entrenador (B2B)", "Permite a entrenadores colegiados auditar a sus alumnos, recibir advertencias automáticas de lesiones y programar citas."],
        ["Módulo de Conmutación de Servidores (Failover)", "Detecta caídas de red y conmuta de forma transparente entre la nube de Render y servidores de laboratorio local."]
    ]
    mod_tbl = doc.add_table(rows=1, cols=2)
    format_table(mod_tbl, [2.3, 4.6], ["Nombre del Módulo", "Funciones Principales y Responsabilidad en el Sistema"], modules_data)
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    # Conclusión
    h1 = doc.add_heading("8. Conclusiones y Puntos Clave para la Defensa", level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    
    doc.add_paragraph(
        "AI Fitness Coach demuestra un equilibrio integral entre rigor técnico e impacto práctico:\n"
        "1. Solidez Arquitectónica: Despliegue moderno desacoplado (Flutter en cliente, FastAPI en backend, Supabase en datos).\n"
        "2. Resiliencia: La aplicación nunca falla ante cortes de conexión o límites de API gracias a su cascada de IA multi-proveedor y persistencia SQLite local.\n"
        "3. Pertinencia Social: Planes de nutrición y ejercicios diseñados para la realidad económica y de equipamiento del usuario venezolano.\n"
        "4. Ética e Integridad: Supervisión B2B para entrenadores profesionales y estricta privacidad de datos médicos."
    ).paragraph_format.line_spacing = 1.15
    
    # Save document
    out_path = os.path.abspath("AI_FITNESS_COACH_DOCUMENTO_PROFESORA.docx")
    doc.save(out_path)
    print(f"Documento Word guardado exitosamente en: {out_path}")
    return out_path

if __name__ == "__main__":
    build_docx()
