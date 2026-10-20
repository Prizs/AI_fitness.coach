# -*- coding: utf-8 -*-
"""
Script para generar el visor web interactivo con estética oficial de Notion (.html)
Renderiza diagramas Mermaid interactivos, switch de tema oscuro/claro y botón de impresión a PDF.
"""

import os
import base64

def get_base64_image(image_path):
    if os.path.exists(image_path):
        with open(image_path, "rb") as f:
            encoded = base64.b64encode(f.read()).decode("utf-8")
            return f"data:image/png;base64,{encoded}"
    return ""

def build_html():
    img_home = get_base64_image(r"C:/Users/miope/.gemini/antigravity/brain/d1e1171e-d6c3-4ed8-8769-1402d5e1e556/.user_uploaded/media_1792242348496_737147d5.png")
    img_schema = get_base64_image(r"C:/Users/miope/.gemini/antigravity/brain/d1e1171e-d6c3-4ed8-8769-1402d5e1e556/.user_uploaded/media_1792242449252_ee263181.png")

    html_content = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Fitness Coach — Documento Maestro (Estilo Notion)</title>
    <!-- Mermaid.js para renderizado de diagramas de arquitectura en vivo -->
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
        mermaid.initialize({{ startOnLoad: true, theme: 'neutral' }});
    </script>
    <style>
        :root {{
            --bg-page: #0d1117;
            --bg-card: #161b22;
            --bg-callout: #16242c;
            --border-callout: #2dd4bf;
            --text-main: #e6edf3;
            --text-muted: #8b949e;
            --accent-teal: #2dd4bf;
            --accent-blue: #58a6ff;
            --accent-orange: #f0883e;
            --table-border: #30363d;
            --table-header: #21262d;
            --table-row-alt: #1c2128;
            --shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
        }}

        .light-theme {{
            --bg-page: #f8fafc;
            --bg-card: #ffffff;
            --bg-callout: #f0fdfa;
            --border-callout: #0d9488;
            --text-main: #0f172a;
            --text-muted: #64748b;
            --accent-teal: #0d9488;
            --accent-blue: #2563eb;
            --accent-orange: #ea580c;
            --table-border: #e2e8f0;
            --table-header: #f1f5f9;
            --table-row-alt: #f8fafc;
            --shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
        }}

        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }}

        body {{
            background-color: var(--bg-page);
            color: var(--text-main);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.65;
            padding: 40px 20px 80px 20px;
            transition: background-color 0.3s ease, color 0.3s ease;
        }}

        .container {{
            max-width: 900px;
            margin: 0 auto;
        }}

        /* Header / Banner */
        .notion-cover {{
            height: 140px;
            background: linear-gradient(135deg, #0f192b 0%, #164e63 50%, #0d9488 100%);
            border-radius: 16px 16px 0 0;
            position: relative;
        }}

        .notion-header {{
            background: var(--bg-card);
            border: 1px solid var(--table-border);
            border-top: none;
            border-radius: 0 0 16px 16px;
            padding: 30px 40px 35px 40px;
            box-shadow: var(--shadow);
            margin-bottom: 30px;
            position: relative;
        }}

        .page-icon {{
            font-size: 54px;
            margin-top: -65px;
            background: var(--bg-card);
            display: inline-block;
            padding: 8px 12px;
            border-radius: 14px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2);
            margin-bottom: 12px;
        }}

        h1.page-title {{
            font-size: 30px;
            font-weight: 800;
            color: var(--text-main);
            margin-bottom: 8px;
            line-height: 1.25;
        }}

        .page-subtitle {{
            color: var(--text-muted);
            font-size: 15px;
            margin-bottom: 18px;
        }}

        /* Badges */
        .badge-bar {{
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-top: 10px;
        }}

        .badge {{
            display: inline-flex;
            align-items: center;
            font-size: 12px;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 20px;
            background: rgba(45, 212, 191, 0.12);
            color: var(--accent-teal);
            border: 1px solid rgba(45, 212, 191, 0.3);
        }}

        /* Toolbar Actions */
        .toolbar {{
            position: fixed;
            top: 20px;
            right: 20px;
            display: flex;
            gap: 10px;
            z-index: 100;
        }}

        .tool-btn {{
            background: var(--bg-card);
            color: var(--text-main);
            border: 1px solid var(--table-border);
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            box-shadow: var(--shadow);
            transition: all 0.2s ease;
        }}

        .tool-btn:hover {{
            background: var(--accent-teal);
            color: #0f192b;
            border-color: var(--accent-teal);
        }}

        /* Sections & Content */
        .section-card {{
            background: var(--bg-card);
            border: 1px solid var(--table-border);
            border-radius: 12px;
            padding: 28px 32px;
            margin-bottom: 24px;
            box-shadow: var(--shadow);
        }}

        h2.section-heading {{
            font-size: 21px;
            font-weight: 700;
            color: var(--text-main);
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 16px;
            padding-bottom: 8px;
            border-bottom: 2px solid rgba(45, 212, 191, 0.2);
        }}

        h3.sub-heading {{
            font-size: 17px;
            font-weight: 600;
            color: var(--accent-blue);
            margin: 18px 0 10px 0;
        }}

        p {{
            margin-bottom: 14px;
            color: var(--text-main);
        }}

        /* Callout Box */
        .callout {{
            background: var(--bg-callout);
            border-left: 4px solid var(--border-callout);
            border-radius: 6px;
            padding: 16px 20px;
            margin: 18px 0;
            display: flex;
            gap: 14px;
            align-items: flex-start;
        }}

        .callout-icon {{
            font-size: 22px;
            line-height: 1;
        }}

        .callout-content {{
            font-size: 14.5px;
            color: var(--text-main);
        }}

        .callout-content strong {{
            color: var(--accent-teal);
        }}

        /* Tables */
        .table-responsive {{
            overflow-x: auto;
            margin: 18px 0;
        }}

        table {{
            width: 100%;
            border-collapse: collapse;
            font-size: 13.5px;
            text-align: left;
        }}

        th {{
            background-color: var(--table-header);
            color: var(--text-main);
            font-weight: 700;
            padding: 12px 14px;
            border: 1px solid var(--table-border);
        }}

        td {{
            padding: 12px 14px;
            border: 1px solid var(--table-border);
            vertical-align: top;
        }}

        tr:nth-child(even) {{
            background-color: var(--table-row-alt);
        }}

        /* Collapsible Toggle */
        details {{
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid var(--table-border);
            border-radius: 8px;
            margin: 12px 0;
            padding: 12px 16px;
        }}

        summary {{
            font-weight: 600;
            cursor: pointer;
            color: var(--accent-blue);
            outline: none;
            user-select: none;
        }}

        details[open] summary {{
            margin-bottom: 12px;
            border-bottom: 1px dashed var(--table-border);
            padding-bottom: 6px;
        }}

        /* Images */
        .img-wrapper {{
            text-align: center;
            margin: 20px 0;
            padding: 10px;
            background: rgba(0,0,0,0.15);
            border-radius: 10px;
            border: 1px solid var(--table-border);
        }}

        .img-wrapper img {{
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            box-shadow: 0 4px 14px rgba(0,0,0,0.3);
        }}

        .img-caption {{
            font-size: 12.5px;
            color: var(--text-muted);
            margin-top: 8px;
            font-style: italic;
        }}

        /* Mermaid diagram container */
        .mermaid {{
            background: var(--table-header);
            padding: 20px;
            border-radius: 8px;
            margin: 16px 0;
            border: 1px solid var(--table-border);
            text-align: center;
        }}

        /* Print styles */
        @media print {{
            .toolbar {{ display: none !important; }}
            body {{ background: #fff !important; color: #000 !important; padding: 0 !important; }}
            .section-card, .notion-header {{ border: 1px solid #ccc !important; box-shadow: none !important; }}
        }}
    </style>
</head>
<body>

    <div class="toolbar">
        <button class="tool-btn" onclick="toggleTheme()">🌓 Alternar Tema</button>
        <button class="tool-btn" onclick="window.print()">🖨️ Imprimir / Guardar PDF</button>
    </div>

    <div class="container">
        <!-- Notion Header & Cover -->
        <div class="notion-cover"></div>
        <div class="notion-header">
            <div class="page-icon">🏋️‍♂️</div>
            <h1 class="page-title">AI FITNESS COACH — Manual Didáctico del Sistema</h1>
            <div class="page-subtitle">Stack Tecnológico, Motores de IA, Base de Datos en Supabase y Explicación Pantalla por Pantalla para Evaluación Docente</div>
            
            <div class="badge-bar">
                <span class="badge">📱 Flutter & Dart</span>
                <span class="badge">⚡ FastAPI / Python 3.11</span>
                <span class="badge">🗄️ Supabase PostgreSQL 17</span>
                <span class="badge">🤖 Multi-IA: Gemini + OpenRouter + Mistral</span>
                <span class="badge">🌐 Render Cloud Activo</span>
                <span class="badge">🇻🇪 Nutrición Criolla Adaptada</span>
            </div>
        </div>

        <!-- 1. Visión General -->
        <div class="section-card">
            <h2 class="section-heading"><span>1.</span> Visión General del Sistema y Concepto de Sinergia</h2>
            <p>
                <strong>AI Fitness Coach</strong> es una plataforma integral desarrollada para resolver el problema de los entrenamientos genéricos y las dietas inaplicables. El sistema conecta de forma interactiva a usuarios con rutinas hiper-personalizadas y permite la supervisión profesional por parte de preparadores físicos colegiados (modelo B2B).
            </p>
            <div class="callout">
                <div class="callout-icon">💡</div>
                <div class="callout-content">
                    <strong>Principio Fundamental de Sinergia Deportiva-Nutricional:</strong><br>
                    En el cuerpo humano, el entrenamiento físico y la alimentación no son eventos independientes. En <em>AI Fitness Coach</em> cada sesión de entrenamiento de la semana va acompañada de su propio menú complementario y una justificación biológica que explica cómo los carbohidratos recargan glucógeno y las proteínas reparan las micro-roturas musculares del día.
                </div>
            </div>
            
            <div class="mermaid">
            flowchart LR
                A[👤 Usuario / Atleta] <--> B[📱 App Flutter Móvil & Web]
                C[🧑‍🏫 Entrenador Colegiado B2B] <--> B
                B <--> D[⚡ Backend FastAPI en Render Cloud]
                D <--> E[🤖 Cascada Multi-IA Gemini / OpenRouter / Mistral]
                D <--> F[(🗄️ Supabase PostgreSQL 17)]
            </div>
        </div>

        <!-- 2. Stack Tecnológico -->
        <div class="section-card">
            <h2 class="section-heading"><span>2.</span> Stack Tecnológico Integral</h2>
            <p>A continuación se resume la arquitectura de tecnologías seleccionadas y su justificación técnica para el jurado:</p>
            
            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>Capa / Componente</th>
                            <th>Tecnología y Versión</th>
                            <th>Justificación Didáctica y Técnica</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>Frontend Móvil & Web</strong></td>
                            <td>Flutter (Dart 3.1+) · Versión 1.0.58</td>
                            <td>Un único código multiplataforma que compila tanto a APK Android nativo como a Web PWA mediante CanvasKit a 60 FPS fluidos.</td>
                        </tr>
                        <tr>
                            <td><strong>Backend RESTful</strong></td>
                            <td>Python 3.11 + FastAPI + Uvicorn</td>
                            <td>Framework moderno asíncrono con validación estricta de datos mediante Pydantic y llamadas no bloqueantes a LLMs de IA.</td>
                        </tr>
                        <tr>
                            <td><strong>Base de Datos Cloud</strong></td>
                            <td>Supabase (PostgreSQL 17)</td>
                            <td>Motor relacional robusto con Row Level Security (RLS), integridad referencial y autenticación segura con JWT.</td>
                        </tr>
                        <tr>
                            <td><strong>Persistencia Local</strong></td>
                            <td>SQLite (sqflite 2.4+)</td>
                            <td>Base de datos embebida en el móvil para registrar entrenamientos offline y calcular rachas sin consumir megas del usuario.</td>
                        </tr>
                        <tr>
                            <td><strong>Visor Anatómico 3D</strong></td>
                            <td>model_viewer_plus / WebGL / glTF</td>
                            <td>Renderiza maniquíes anatómicos tridimensionales con interacción táctil (360° orbital) para prevención de lesiones.</td>
                        </tr>
                        <tr>
                            <td><strong>Atlas Muscular 2D</strong></td>
                            <td>flutter_body_atlas (SVG dinámico)</td>
                            <td>Mapa muscular interactivo para resaltar visualmente los grupos musculares involucrados y zonas de dolor.</td>
                        </tr>
                        <tr>
                            <td><strong>Entrada por Voz</strong></td>
                            <td>speech_to_text (Español)</td>
                            <td>Permite al usuario interactuar con el Coach IA mediante comandos de voz en español sin escribir.</td>
                        </tr>
                        <tr>
                            <td><strong>Despliegue Cloud</strong></td>
                            <td>Render PaaS (Docker)</td>
                            <td>Alojamiento en contenedor Linux conectado en vivo a <code>https://ai-fitness-coach-818a.onrender.com</code> con conmutación local de respaldo.</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- 3. Motores de IA -->
        <div class="section-card">
            <h2 class="section-heading"><span>3.</span> Motores de Inteligencia Artificial y Cadena con Failover</h2>
            <p>
                El sistema implementa una arquitectura de <strong>Conmutación en Cascada (Multi-Provider Cascade Failover)</strong> programada en <code>app.services.ai_providers</code> para garantizar que la aplicación <strong>nunca se caiga</strong>:
            </p>

            <div class="mermaid">
            flowchart TD
                P[Petición del Usuario + Perfil Médico/Físico] --> P1{{1. Google Gemini API}}
                P1 -- Éxito --> J[Respuesta JSON Estructurada]
                P1 -- Error 429 / Cuota --> P2{{2. OpenRouter Free Pool}}
                P2 -- Éxito --> J
                P2 -- Fallo --> P3{{3. Mistral AI API}}
                P3 -- Éxito --> J
                P3 -- Fallo --> P4{{4. Groq Cloud Engine}}
                P4 -- Fallo --> F[Plan Local Seguro Fisiológico]
            </div>

            <details open>
                <summary>Detalle de los Modelos y Políticas de Seguridad</summary>
                <ul style="padding-left: 20px; margin-top: 10px;">
                    <li><strong>Google Gemini (Primario):</strong> Seleccionado por su precisión biomecánica y capacidad nativa de responder en esquemas JSON rígidos.</li>
                    <li><strong>OpenRouter Free Pool (1er Respaldo):</strong> Rota automáticamente entre modelos abiertos como Gemma 4, Qwen 3.8 27B y Nemotron 120B.</li>
                    <li><strong>Mistral AI (2do Respaldo):</strong> Garantiza redacción en español empática, orientativa y natural con <code>mistral-small-latest</code>.</li>
                    <li><strong>Algoritmo Fail-Safe Local:</strong> Si no hay conexión o caen las APIs, <code>weekly_plan.py</code> genera una semana segura sin arrojar nunca un error 500 al alumno.</li>
                    <li><strong>Regla de Biomecánica Estricta:</strong> Si el usuario entrena en casa con mancuernas, la IA tiene prohibido por prompt proponer poleas o prensas de gimnasio.</li>
                    <li><strong>Filtro Ético-Médico:</strong> La IA no emite diagnósticos médicos ni prescribe fármacos; en casos de dolor agudo, remite a un profesional de salud.</li>
                </ul>
            </details>
        </div>

        <!-- 4. Origen de Entrenamientos y Nutrición -->
        <div class="section-card">
            <h2 class="section-heading"><span>4.</span> Origen de Entrenamientos y Planes Alimenticios</h2>
            <p>
                Una de las mayores virtudes evaluables del proyecto es que la IA no "inventa" ejercicios ni comidas extravagantes, sino que actúa como un <strong>curador inteligente</strong> sobre fuentes científicas y contextuales:
            </p>

            <h3 class="sub-heading">🏋️ Origen de los Entrenamientos</h3>
            <ul style="padding-left: 20px; margin-bottom: 15px;">
                <li><strong>Catálogo Abierto Free Exercise DB:</strong> Repositorio con más de 800 ejercicios indexados con clasificación anatómica y nivel de intensidad.</li>
                <li><strong>Biblioteca de Animaciones Biomecánicas (ExerciseGymGifsDB):</strong> Cada ejercicio se enlaza a un GIF de técnica estricta indexado en <code>gifs_db.json</code>.</li>
                <li><strong>Periodización de Sobrecarga (48-72h):</strong> Distribución calculada entre días de Tren Superior, Tren Inferior, Core y Descanso Activo para evitar fatiga de sobreentrenamiento.</li>
            </ul>

            <h3 class="sub-heading">🥑 Origen de los Planes Alimenticios (Realidad Venezolana)</h3>
            <div class="callout">
                <div class="callout-icon">🇻🇪</div>
                <div class="callout-content">
                    <strong>Adaptación Real al Mercado Local:</strong><br>
                    En lugar de prescribir ingredientes costosos e importados (salmón, frutos del bosque o suplementos inaccesibles), la base de datos <code>nutrition_database.dart</code> está formulada con <strong>ingredientes de mercado popular venezolano</strong>: arepas de maíz, avena, cambur, huevos enteros o pericos, pollo, carne molida magra, atún, sardinas, caraotas negras, lentejas, arroz, batata, yuca, plátano verde o maduro y aguacate criollo.
                </div>
            </div>

            <p><strong>4 Objetivos Nutricionales Clínicos Soportados:</strong></p>
            <ol style="padding-left: 20px;">
                <li><strong>Hipertrofia Limpia:</strong> Superávit calórico controlado con proteína accesible y carbohidratos densos (yuca, plátano, arroz).</li>
                <li><strong>Pérdida de Grasa / Definición:</strong> Déficit saciante con abundantes vegetales económicos (repollo, pepino, calabacín, chayota).</li>
                <li><strong>Resistencia Cardio:</strong> Recarga de glucógeno mediante tubérculos y frutas hidratantes locales.</li>
                <li><strong>Salud & Energía:</strong> Adaptación criolla de la dieta mediterránea con grasas saludables (aguacate) y omega-3 accesible (sardina/granos).</li>
            </ol>
        </div>

        <!-- 5. Base de Datos en Supabase -->
        <div class="section-card">
            <h2 class="section-heading"><span>5.</span> Estructura de la Base de Datos en Supabase (PostgreSQL)</h2>
            <p>
                La base de datos sigue las mejores prácticas de la industria en <strong>Tercera Forma Normal (3FN)</strong>, protegiendo las credenciales mediante el motor criptográfico de Supabase Auth y enlazando perfiles médicos y módulos B2B:
            </p>

            <div class="img-wrapper">
                <img src="{img_schema}" alt="Esquema Relacional en Supabase">
                <div class="img-caption">Figura 1: Esquema Relacional de Tablas en Supabase PostgreSQL.</div>
            </div>

            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>Tabla en Supabase</th>
                            <th>Claves y Relaciones</th>
                            <th>Propósito Didáctico y Técnico</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><code>auth.users</code></td>
                            <td>uuid (PK)</td>
                            <td>Tabla interna de Supabase Auth. Custodia correos, hashes de contraseñas y tokens JWT. Ninguna clave viaja en texto plano.</td>
                        </tr>
                        <tr>
                            <td><code>usuarios</code></td>
                            <td>id (PK/FK) &rarr; auth.users.id</td>
                            <td>Perfil del usuario: cédula, nombres, peso, edad, rol ('client' o 'trainer') y restricciones médicas (alergias, lesiones, zonas a evitar).</td>
                        </tr>
                        <tr>
                            <td><code>workout_sessions</code></td>
                            <td>id (PK), client_id (FK), trainer_id (FK)</td>
                            <td>Calendario de sesiones de entrenamiento programadas y completadas entre el atleta y su preparador físico.</td>
                        </tr>
                        <tr>
                            <td><code>trainer_schedules</code></td>
                            <td>id (PK), trainer_id (FK)</td>
                            <td>Horarios base del entrenador (día de la semana 1-7, horas de apertura/cierre y capacidad máxima de alumnos).</td>
                        </tr>
                        <tr>
                            <td><code>trainer_chat</code></td>
                            <td>id (PK), client_id, trainer_id, sender_id</td>
                            <td>Canal de mensajería privada y directa entre el alumno y su entrenador asignado para resolución de dudas.</td>
                        </tr>
                        <tr>
                            <td><code>trainer_announcements</code></td>
                            <td>id (PK), trainer_id (FK)</td>
                            <td>Muro digital de avisos masivos publicados por el entrenador hacia todos sus atletas.</td>
                        </tr>
                        <tr>
                            <td><code>progress_photos</code></td>
                            <td>id (PK), user_id (FK)</td>
                            <td>Historial de fotografías físicas almacenadas en Supabase Storage con reportes de evolución morfológica con IA.</td>
                        </tr>
                        <tr>
                            <td><code>aprendizaje_plan_anonimo</code></td>
                            <td>id (PK), proveedor, calificacion</td>
                            <td>Telemetría ética y anónima: mide la satisfacción (1-5) del plan de IA sin guardar nombres ni datos personales (GDPR Compliant).</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- 6. Arquitectura por Pantalla -->
        <div class="section-card">
            <h2 class="section-heading"><span>6.</span> Arquitectura y Funcionalidad por Pantalla</h2>
            
            <div class="img-wrapper">
                <img src="{img_home}" alt="Pantalla de Inicio">
                <div class="img-caption">Figura 2: Pantalla de Inicio en Flutter (v1.0.52 - Conexión Cloud Render Activa).</div>
            </div>

            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>Pantalla</th>
                            <th>Archivo Fuente</th>
                            <th>Tecnología y Funcionalidad Implementada</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>Inicio (HomeScreen)</strong></td>
                            <td><code>home_screen.dart</code></td>
                            <td>Muestra el estado de la conexión a Render, campana de notificaciones con insignia reactiva de alerta (punto rojo), chips de objetivo actual y tarjetas de navegación a los 4 módulos núcleo.</td>
                        </tr>
                        <tr>
                            <td><strong>Coach IA (CoachScreen)</strong></td>
                            <td><code>coach_screen.dart</code></td>
                            <td>Chat generativo por texto y voz (Speech-to-Text). Incluye cuestionario check-in de energía/dolor, renderizado de tarjetas con GIFs y botón para inyectar la rutina directamente al cronograma.</td>
                        </tr>
                        <tr>
                            <td><strong>Rutinas (WorkoutsScreen)</strong></td>
                            <td><code>workouts_screen.dart</code></td>
                            <td>Planificador semanal con días activos, desglose de series, repeticiones y tempo. Permite marcar sesiones completadas sincronizadas con la base de datos local SQLite para rachas.</td>
                        </tr>
                        <tr>
                            <td><strong>Anatomía 3D (AnatomyScreen)</strong></td>
                            <td><code>anatomy_workout_screen.dart</code></td>
                            <td>Visor táctil orbital 3D (WebGL / model_viewer_plus) con panel deslizante que detalla músculos agonistas, sinergistas, postura recomendada y advertencias biomecánicas.</td>
                        </tr>
                        <tr>
                            <td><strong>Nutrición (NutritionScreen)</strong></td>
                            <td><code>nutrition_screen.dart</code></td>
                            <td>Selector de los 4 objetivos nutricionales, desglose de comidas con alimentos venezolanos económicos y tarjeta didáctica de Sinergia Nutricional Diaria.</td>
                        </tr>
                        <tr>
                            <td><strong>Progreso (ProgressScreen)</strong></td>
                            <td><code>progress_screen.dart</code></td>
                            <td>Carga de fotografías de evolución física desde cámara o galería mediante peticiones HTTP multipart al bucket cloud, con análisis de cambio corporal.</td>
                        </tr>
                        <tr>
                            <td><strong>Mi Perfil y Salud</strong></td>
                            <td><code>user_profile_screen.dart</code></td>
                            <td>Ficha médica interactiva donde el atleta define alergias, molestias articulares y alterna la conexión entre el servidor cloud en Render y el servidor local.</td>
                        </tr>
                        <tr>
                            <td><strong>Notificaciones</strong></td>
                            <td><code>notifications_screen.dart</code></td>
                            <td>Alertas inteligentes: caducidad de plan al acercarse el fin de semana, aviso de cronograma vacío y recordatorio diario de la sesión de hoy.</td>
                        </tr>
                        <tr>
                            <td><strong>Portal Entrenador B2B</strong></td>
                            <td><code>trainer_shell.dart</code></td>
                            <td>Pestaña de alumnos con <strong>ALERTA ROJA (🔴)</strong> para atletas que reportan molestias o lesiones en tiempo real, ficha técnica del alumno, agenda de citas y chat directo.</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- 7. Funciones de los Módulos -->
        <div class="section-card">
            <h2 class="section-heading"><span>7.</span> Funciones de los Módulos del Sistema</h2>
            <ul style="padding-left: 20px; line-height: 1.8;">
                <li><strong>Módulo de Autenticación y Seguridad:</strong> Protege el acceso mediante tokens JWT, hash de contraseñas en Supabase Auth y redirección según el rol ('client' vs 'trainer').</li>
                <li><strong>Módulo del Coach IA y Memoria Adaptativa:</strong> Procesa voz y texto en español, retiene en memoria el equipo del usuario (ej.: *mancuernas de 10 kg*) para no re-preguntar en sesiones futuras y programa planes sin pisar la semana en curso.</li>
                <li><strong>Módulo de Entrenamiento y Biomecánica:</strong> Gestiona la visualización 2D (GIFs), 3D (WebGL) y el registro offline de sesiones en SQLite local.</li>
                <li><strong>Módulo Nutricional Adaptativo:</strong> Sincroniza la demanda de macronutrientes del entrenamiento con opciones alimenticias cultural y económicamente viables en el entorno local.</li>
                <li><strong>Módulo de Supervisión del Entrenador (B2B):</strong> Permite a entrenadores colegiados auditar a sus alumnos, recibir advertencias automáticas de lesiones y programar citas.</li>
                <li><strong>Módulo de Conmutación de Servidores (Failover):</strong> Detecta caídas de red y conmuta de forma transparente entre la nube de Render y servidores de laboratorio local.</li>
            </ul>
        </div>
    </div>

    <script>
        function toggleTheme() {{
            document.body.classList.toggle('light-theme');
        }}
    </script>
</body>
</html>
"""
    out_path = os.path.abspath("AI_FITNESS_COACH_NOTION_VIEWER.html")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"Visor interactivo Notion generado en: {out_path}")
    return out_path

if __name__ == "__main__":
    build_html()
