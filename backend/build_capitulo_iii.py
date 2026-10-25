# -*- coding: utf-8 -*-
"""
Generador del Capítulo III: Estudio de Factibilidad
Universidad Dr. José Gregorio Hernández (UJGH) - Maracaibo, Estado Zulia
Autor: Emmanuel Guerra, C.I: 30.557.639
"""

import os
import docx
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

OUTPUT_DIR = r"C:\Users\miope\Desktop\emmanuel cap"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "CAPITULO III - ESTUDIO DE FACTIBILIDAD (EMMANUEL GUERRA).docx")

def create_document():
    doc = docx.Document()

    # 1. Configuración de Página y Márgenes (Estándar UJGH)
    section = doc.sections[0]
    section.page_width = Cm(21.59)   # Carta (Letter)
    section.page_height = Cm(27.94)
    section.top_margin = Cm(3.0)
    section.bottom_margin = Cm(3.0)
    section.left_margin = Cm(3.0)    # Margen izquierdo para encuadernación
    section.right_margin = Cm(3.0)

    # 2. Configuración del Estilo Normal (Arial 12, interlineado 1.5)
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Arial'
    font.size = Pt(12)
    font.color.rgb = RGBColor(0, 0, 0)

    # Helper: Párrafo normal justificado con sangría
    def add_p(text, indent=True, space_after=6):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        p.paragraph_format.line_spacing = 1.5
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.space_before = Pt(0)
        if indent:
            p.paragraph_format.first_line_indent = Cm(1.0)
        else:
            p.paragraph_format.first_line_indent = Cm(0)
        run = p.add_run(text)
        run.font.name = 'Arial'
        run.font.size = Pt(12)
        return p

    # Helper: Título de Nivel 1 (Centrado o Izquierda)
    def add_h1(text, centered=False):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER if centered else WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.line_spacing = 1.5
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = 'Arial'
        run.font.size = Pt(12)
        run.bold = True
        return p

    # Helper: Subtítulo de Nivel 2 (Izquierda, Negrita)
    def add_h2(text):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.line_spacing = 1.5
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = 'Arial'
        run.font.size = Pt(12)
        run.bold = True
        return p

    # Helper: Título de Tabla o Cuadro
    def add_table_title(text):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.line_spacing = 1.15
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = 'Arial'
        run.font.size = Pt(12)
        run.bold = True
        return p

    # Helper: Fuente de Tabla o Cuadro
    def add_table_source(text="Fuente: Elaboración propia (2026)."):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.line_spacing = 1.15
        p.paragraph_format.space_before = Pt(3)
        p.paragraph_format.space_after = Pt(12)
        p.paragraph_format.first_line_indent = Cm(0)
        run = p.add_run(text)
        run.font.name = 'Arial'
        run.font.size = Pt(10)
        return p

    # Helper: Formateo de Tablas (Bordes formales, sombreado sutil institucional #DEEAF6)
    def format_table(table, col_widths=None):
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        tblPr = table._tbl.tblPr
        
        # Bordes limpios individuales en negro fino (4 = 0.5 pt)
        borders = parse_xml(
            f'<w:tblBorders {nsdecls("w")}>'
            f'<w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            f'<w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            f'<w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            f'<w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            f'<w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            f'<w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            f'</w:tblBorders>'
        )
        tblPr.append(borders)

        for row_idx, row in enumerate(table.rows):
            is_header = (row_idx == 0)
            trPr = row._tr.get_or_add_trPr()
            trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
            if is_header:
                trPr.append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))

            for col_idx, cell in enumerate(row.cells):
                tcPr = cell._tc.get_or_add_tcPr()
                # Margen interno de celda (padding)
                tcMar = parse_xml(
                    f'<w:tcMar {nsdecls("w")}>'
                    f'<w:top w:w="120" w:type="dxa"/>'
                    f'<w:bottom w:w="120" w:type="dxa"/>'
                    f'<w:left w:w="160" w:type="dxa"/>'
                    f'<w:right w:w="160" w:type="dxa"/>'
                    f'</w:tcMar>'
                )
                tcPr.append(tcMar)

                # Ancho de columna
                if col_widths and col_idx < len(col_widths):
                    cell.width = Cm(col_widths[col_idx])

                # Sombreado de encabezado
                if is_header:
                    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="DEEAF6"/>')
                    tcPr.append(shd)

                # Formateo de texto en celdas
                for p in cell.paragraphs:
                    p.paragraph_format.line_spacing = 1.15
                    p.paragraph_format.space_before = Pt(2)
                    p.paragraph_format.space_after = Pt(2)
                    p.paragraph_format.first_line_indent = Cm(0)
                    for r in p.runs:
                        r.font.name = 'Arial'
                        r.font.size = Pt(10)
                        if is_header:
                            r.bold = True

    print("Iniciando construcción formal del documento...")

    # ==========================================
    # PORTADA INSTITUCIONAL FORMAL (UJGH)
    # ==========================================
    p_inst = doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_inst.paragraph_format.line_spacing = 1.15
    p_inst.paragraph_format.space_after = Pt(2)
    p_inst.paragraph_format.first_line_indent = Cm(0)
    for line in [
        "REPÚBLICA BOLIVARIANA DE VENEZUELA",
        "MINISTERIO DEL PODER POPULAR PARA LA EDUCACIÓN UNIVERSITARIA",
        "UNIVERSIDAD DR. JOSÉ GREGORIO HERNÁNDEZ",
        "FACULTAD DE INGENIERÍA",
        "ESCUELA DE COMPUTACIÓN"
    ]:
        r = p_inst.add_run(line + "\n")
        r.font.name = 'Arial'
        r.font.size = Pt(11)
        r.bold = True

    # Espacio vertical
    for _ in range(4):
        p_sp = doc.add_paragraph()
        p_sp.paragraph_format.line_spacing = 1.15
        p_sp.paragraph_format.space_after = Pt(0)

    # Título del Proyecto
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.line_spacing = 1.5
    p_title.paragraph_format.space_after = Pt(12)
    p_title.paragraph_format.first_line_indent = Cm(0)
    r_t = p_title.add_run(
        "SISTEMA EXPERTO MÓVIL PARA LA ASISTENCIA INTEGRAL DE FITNESS: "
        "DESDE LA GESTIÓN OPERATIVA HASTA LA TUTORÍA TÉCNICA DE EJERCICIOS "
        "Y ALIMENTACIÓN CON INTELIGENCIA ARTIFICIAL"
    )
    r_t.font.name = 'Arial'
    r_t.font.size = Pt(12)
    r_t.bold = True

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.line_spacing = 1.15
    p_sub.paragraph_format.space_after = Pt(12)
    p_sub.paragraph_format.first_line_indent = Cm(0)
    r_sub = p_sub.add_run(
        "Trabajo Especial de Grado presentado como requisito para optar al título de\n"
        "Ingeniero en Computación"
    )
    r_sub.font.name = 'Arial'
    r_sub.font.size = Pt(11)

    for _ in range(4):
        p_sp = doc.add_paragraph()
        p_sp.paragraph_format.line_spacing = 1.15
        p_sp.paragraph_format.space_after = Pt(0)

    # Autor y Tutor
    p_autor = doc.add_paragraph()
    p_autor.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p_autor.paragraph_format.line_spacing = 1.15
    p_autor.paragraph_format.space_after = Pt(24)
    p_autor.paragraph_format.first_line_indent = Cm(0)
    r_aut = p_autor.add_run(
        "Autor: Br. Emmanuel Guerra\n"
        "C.I: V-30.557.639\n"
        "Tutor Académico: [Comité Académico UJGH]\n"
        "Asesor Metodológico: [Comité Metodológico UJGH]"
    )
    r_aut.font.name = 'Arial'
    r_aut.font.size = Pt(11)
    r_aut.bold = True

    for _ in range(3):
        p_sp = doc.add_paragraph()
        p_sp.paragraph_format.line_spacing = 1.15
        p_sp.paragraph_format.space_after = Pt(0)

    p_city = doc.add_paragraph()
    p_city.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_city.paragraph_format.line_spacing = 1.15
    p_city.paragraph_format.space_after = Pt(0)
    p_city.paragraph_format.first_line_indent = Cm(0)
    r_city = p_city.add_run("Maracaibo, 2026")
    r_city.font.name = 'Arial'
    r_city.font.size = Pt(11)
    r_city.bold = True

    doc.add_page_break()

    # ==========================================
    # CAPÍTULO III: ESTUDIO DE FACTIBILIDAD
    # ==========================================
    add_h1("CAPÍTULO III", centered=True)
    add_h1("ESTUDIO DE FACTIBILIDAD", centered=True)

    add_p(
        "El presente capítulo tiene como propósito fundamental determinar la viabilidad integral del proyecto "
        "denominado Sistema experto móvil para la asistencia integral de fitness: Desde la gestión operativa hasta "
        "la tutoría técnica de ejercicios y alimentación con inteligencia artificial, mediante la evaluación sistemática "
        "y rigurosa de los factores técnicos, operativos, económicos, de mercado y legales que condicionan su desarrollo "
        "e implantación efectiva en el ámbito deportivo y de acondicionamiento físico."
    )

    add_p(
        "La factibilidad dentro de la investigación tecnológica aplicada se concibe como el análisis estructurado de los "
        "recursos disponibles, requerimientos funcionales y restricciones contextuales que permiten establecer con certeza "
        "si una solución computacional puede llevarse a la práctica con éxito. Al respecto, Hernández-Sampieri y Mendoza "
        "(2022) sostienen que el estudio de factibilidad permite valorar la pertinencia y aplicabilidad real de una "
        "propuesta en entornos operativos concretos, asegurando que el diseño teórico responda con solvencia a las "
        "exigencias del medio al que va dirigido."
    )

    add_p(
        "Bajo esta perspectiva metodológica, el capítulo examina de forma articulada los pilares que sustentan la "
        "sostenibilidad de la solución: el estudio de mercado (demanda, oferta y comercialización), el estudio técnico "
        "(arquitectura de software, hardware y capital humano), el estudio operativo (costos y procesos de producción bajo "
        "marcos ágiles), el estudio económico-financiero (inversión inicial, proyecciones de ingresos y egresos, estado de "
        "resultados, presupuesto de caja e indicadores de rentabilidad VAN, TIR y Beneficio/Costo) y el marco de aspectos "
        "legales e institucionales que rigen el ejercicio informático en la República Bolivariana de Venezuela."
    )

    add_p(
        "En el contexto específico del presente estudio, la factibilidad se orienta a validar la puesta en marcha de un "
        "sistema experto móvil que combina la potencia de modelos avanzados de inteligencia artificial con visión computacional "
        "y motores de inferencia biomecánica, facilitando el control automatizado de la sobrecarga progresiva, la corrección "
        "técnica de movimientos, la prescripción nutricional contextualizada y la lectura automática de métricas biométricas "
        "directamente desde balanzas e imágenes de progreso, adaptándose con realismo a las condiciones tecnológicas y de "
        "conectividad de la ciudad de Maracaibo y del país."
    )

    # ------------------------------------------
    # 3.1 ESTUDIO DEL MERCADO
    # ------------------------------------------
    add_h1("3.1 Estudio del Mercado")

    add_p(
        "El estudio de mercado representa una etapa decisiva dentro de la formulación del proyecto, debido a que "
        "proporciona el conocimiento empírico y analítico sobre el entorno en el cual operará la herramienta tecnológica. "
        "Permite identificar con precisión los requerimientos insatisfechos de los usuarios, los patrones de comportamiento "
        "del segmento objetivo, las alternativas existentes y las oportunidades reales de adopción e impacto social. En este "
        "sentido, el estudio de mercado no constituye una simple recopilación documental, sino un instrumento directivo que "
        "orienta el diseño del software hacia la solución de problemas concretos."
    )

    add_p(
        "De acuerdo con Philip Kotler y Kevin Lane Keller (2022), el estudio de mercado permite evaluar sistemáticamente "
        "la dinámica que se produce entre la demanda de los consumidores, la oferta de los competidores y los canales de "
        "comercialización pertinentes, ofreciendo una visión integral de las fuerzas que impulsan o restringen el desarrollo "
        "de un bien o servicio. En el ámbito del software aplicado a las ciencias del ejercicio, este enfoque permite verificar "
        "que la solución propuesta responda a una necesidad sentida y posea viabilidad comercial sostenible."
    )

    add_p(
        "En el caso del presente proyecto, el estudio de mercado se enfoca en analizar la necesidad imperiosa de contar "
        "con una plataforma tecnológica capaz de automatizar y guiar la planificación deportiva de fuerza, hipertrofia y salud "
        "física en Maracaibo, considerando la masificación de los dispositivos móviles inteligentes y la creciente demanda "
        "de asesoría calificada por parte de atletas, entrenadores personales y usuarios de centros de entrenamiento físico."
    )

    # 3.1.1 Demanda
    add_h2("3.1.1 Demanda")

    add_p(
        "La demanda se define como el volumen total de un bien o servicio que un grupo específico de consumidores está "
        "dispuesto a adquirir o utilizar bajo determinadas condiciones temporales, geográficas y de precio. En el marco del "
        "entrenamiento deportivo y la actividad física, la demanda se manifiesta en la necesidad urgente de acceder a "
        "orientación técnica fundamentada, que organice las sesiones de entrenamiento sin riesgo de sobrecarga lesiva y "
        "proporcione planes de nutrición coherentes con los requerimientos energéticos individuales."
    )

    add_p(
        "En el municipio Maracaibo y en el territorio venezolano en general, se observa un incremento notable en la cantidad "
        "de personas que asisten regularmente a gimnasios, centros de acondicionamiento funcional y espacios deportivos al aire "
        "libre. Sin embargo, la gran mayoría de estos practicantes carece de la posibilidad de costear un preparador físico "
        "exclusivo de manera permanente, lo cual deriva en entrenamientos empíricos, improvisación de ejercicios, ausencia de "
        "periodización y un elevado índice de frustración o lesiones articulares y musculares."
    )

    add_p(
        "Asimismo, existe una demanda calificada por parte de los propios entrenadores e instructores de gimnasio, quienes "
        "enfrentan serias dificultades para gestionar las rutinas de decenas de alumnos simultáneamente mediante libretas o notas "
        "dispersas en aplicaciones de mensajería instantánea, requiriendo herramientas informáticas centralizadas que calculen "
        "el volumen de trabajo, sugieran variantes biomecánicas por grupos musculares específicos y supervisen la progresión "
        "de cargas con rigor profesional."
    )

    add_p(
        "De este modo, la demanda objetivo del presente sistema experto está conformada por practicantes regulares de fitness "
        "(niveles principiante, intermedio y avanzado), atletas de fuerza, entrenadores personales y centros de acondicionamiento "
        "físico en el ámbito local y regional, quienes demandan una asistencia interactiva, confiable y disponible de forma continua."
    )

    # 3.1.2 Oferta
    add_h2("3.1.2 Oferta")

    add_p(
        "La oferta se conceptualiza como la cantidad de bienes, productos o soluciones tecnológicas que los proveedores "
        "disponen en el mercado para satisfacer las exigencias de los usuarios. En el área del acondicionamiento físico y la "
        "gestión del entrenamiento, la oferta disponible presenta características sumamente polarizadas y descontextualizadas "
        "respecto a la realidad socioeconómica venezolana."
    )

    add_p(
        "Por un lado, se encuentran aplicaciones móviles comerciales de alcance internacional (tales como MyFitnessPal, "
        "Hevy, Fitbod o JEFIT). Aunque estas herramientas poseen interfaces atractivas, presentan barreras determinantes: "
        "la gran mayoría de sus módulos analíticos avanzados exige suscripciones en moneda extranjera con tarifas elevadas "
        "(oscilantes entre 10 y 15 dólares mensuales), requieren pasarelas de pago internacionales inaccesibles para amplios "
        "sectores locales, sus bases de datos nutricionales ignoran por completo los patrones y disponibilidad real de "
        "ingredientes en Venezuela, y sus algoritmos de entrenamiento operan como listas estáticas prediseñadas que no responden "
        "a especificaciones anatómicas minuciosas solicitadas por el deportista en lenguaje natural."
    )

    add_p(
        "Por otro lado, la oferta convencional en el entorno local está dominada por métodos manuales y empíricos: cuadernos "
        "físicos de anotación, tablas estáticas en formato PDF o mensajes informales por WhatsApp. Adicionalmente, la contratación "
        "de asesorías personalizadas presenciales maneja costos mensuales que van desde los 40 hasta más de 120 dólares por mes, "
        "restringiendo dicho servicio a un porcentaje reducido de la población."
    )

    add_p(
        "En este sentido, la oferta del presente proyecto se diferencia radicalmente de las opciones tradicionales al "
        "proporcionar un sistema experto accesible que integra inteligencia artificial multimodal: dialoga con el usuario, "
        "genera cronogramas sin duplicación de ejercicios, acata peticiones anatómicas quirúrgicas (ej. especialización en "
        "pantorrillas/sóleo, cuádriceps, femorales o combinaciones simultáneas), incorpora reconocimiento por visión artificial "
        "para capturar el peso exacto desde la pantalla de balanzas y ofrece recomendaciones dietéticas sustentadas en los "
        "recursos nutricionales propios de la región."
    )

    # 3.1.3 Comercialización
    add_h2("3.1.3 Comercialización")

    add_p(
        "La comercialización se define como el conjunto coordinado de acciones, canales y estrategias comerciales mediante "
        "las cuales se logra la transferencia, distribución y adopción de un producto o servicio informático entre los "
        "usuarios potenciales, asegurando su posicionamiento y permanencia en el mercado meta."
    )

    add_p(
        "Para el sistema experto móvil desarrollado, se formula una estrategia de comercialización apoyada en canales "
        "digitales y alianzas comunitarias, considerando las características de adopción tecnológica y los canales de "
        "comunicación más utilizados en el municipio Maracaibo y en Venezuela:"
    )

    add_p(
        "a) Modelo de Distribución Freemium: Se plantea la descarga libre del aplicativo con acceso completo a las funciones "
        "esenciales de registro de entrenamientos, visualizador de rutinas del día y cronogramas semanales. Las funciones de alta "
        "gama —como la interacción conversacional continua con el Coach IA, el análisis biomecánico interactivo, el reconocimiento "
        "OCR de balanzas y los ajustes nutricionales adaptativos automáticos— se integran bajo una suscripción Premium de bajo "
        "costo, fijada en una tarifa mensual accesible de 4,00 USD (o 35,00 USD anuales), altamente competitiva frente a las "
        "tarifas de aplicaciones extranjeras o entrenadores particulares."
    )

    add_p(
        "b) Licenciamiento Institucional para Gimnasios y Entrenadores (B2B): Esquema de membresías profesionales para entrenadores "
        "e instructores de sala, quienes por un canon mensual de 25,00 USD pueden vincular y supervisar de forma centralizada "
        "el progreso técnico de grupos de hasta 30 alumnos, optimizando sus tiempos y otorgando un valor agregado tecnológico "
        "a sus asesorías."
    )

    add_p(
        "c) Estrategia de Difusión y Alianzas Regionales: Campañas activas en redes sociales con alta penetración deportiva "
        "(Instagram y TikTok), exhibiciones técnicas y jornadas de pruebas piloto en gimnasios emblemáticos y centros deportivos "
        "de Maracaibo, así como la vinculación con la comunidad universitaria y atletas de la Universidad Dr. José Gregorio "
        "Hernández, impulsando la credibilidad institucional y la adopción orgánica del sistema."
    )

    # ------------------------------------------
    # 3.2 ESTUDIO DE FACTIBILIDAD
    # ------------------------------------------
    add_h1("3.2 Estudio de Factibilidad")

    add_p(
        "El estudio de factibilidad representa el núcleo metodológico de la evaluación del proyecto, debido a que permite "
        "examinar minuciosamente la viabilidad técnica, operativa y financiera requerida para materializar el sistema propuesto. "
        "De acuerdo con Jack Gido y James P. Clements (2021), el análisis de factibilidad asegura que los objetivos trazados "
        "en el proyecto puedan cumplirse satisfactoriamente dentro de los límites de tiempo, costos y recursos asignados, "
        "minimizando las incertidumbres y garantizando que la solución alcance los estándares de calidad comprometidos."
    )

    add_p(
        "Asimismo, autores clásicos de la formulación de proyectos como Gabriel Baca Urbina (2021) enfatizan que la factibilidad "
        "debe abordarse de forma multidimensional, conjugando la capacidad técnica instalada, la organización del proceso "
        "productivo y el equilibrio económico entre los recursos invertidos y los beneficios proyectados."
    )

    # 3.2.1 Estudio Técnico
    add_h2("3.2.1 Estudio Técnico")

    add_p(
        "El estudio técnico tiene por objetivo analizar, proponer y justificar las herramientas tecnológicas, arquitecturas "
        "computacionales, especificaciones de hardware y perfiles de capital humano requeridos para el diseño, codificación, "
        "entrenamiento de modelos y despliegue del sistema experto móvil."
    )

    add_p(
        "Desde la perspectiva arquitectónica, el sistema se fundamenta en un patrón desacoplado de tres capas de alta "
        "escalabilidad: la Capa de Presentación (desarrollada con Flutter SDK y Dart, garantizando compilación nativa tanto "
        "para plataformas móviles Android mediante APK como para entornos web responsivos mediante CanvasKit/HTML5); la Capa "
        "de Lógica de Negocio y Servicio (estructurada con Python 3.11 y el framework FastAPI, bajo un servidor ASGI Uvicorn "
        "con tipado estricto mediante Pydantic y comunicación bidireccional mediante APIs REST seguras); y la Capa de Datos "
        "y Conocimiento (soportada en SQLite relacional local para persistencia en el dispositivo móvil y PostgreSQL para "
        "la sincronización en la nube, interconectada con los servicios fundacionales de Google Gemini API para el procesamiento "
        "del lenguaje natural, visión artificial OCR y generación experta de cronogramas)."
    )

    add_p(
        "A continuación, la Tabla N° 1 detalla los insumos intangibles (software, lenguajes, frameworks y plataformas de nube) "
        "utilizados para el desarrollo y puesta en marcha del sistema móvil:"
    )

    add_table_title("Tabla N° 1. Insumos Intangibles (Software)")
    t1 = doc.add_table(rows=10, cols=3)
    t1_data = [
        ["Tipo de Software", "Descripción de la Plataforma / Herramienta", "Versión / Licencia"],
        ["Framework Multiplataforma", "Flutter SDK (Frontend móvil Android y Web responsivo)", "3.24+ (Código Abierto)"],
        ["Lenguaje de Programación", "Dart (Lenguaje base para cliente e interfaces móviles)", "3.5+ (Código Abierto)"],
        ["Lenguaje de Backend", "Python (Procesamiento analítico y lógica de negocio)", "3.11 LTS (PSFL)"],
        ["Framework de Backend / API", "FastAPI (Construcción de APIs REST asíncronas de alto rendimiento)", "0.115+ (Código Abierto)"],
        ["Mapeador Objeto-Relacional", "SQLAlchemy ORM (Persistencia y modelado de datos relacionales)", "2.0+ (Código Abierto)"],
        ["Base de Datos Relacional", "SQLite (Cliente local) / PostgreSQL (Persistencia en la nube)", "3.40+ / 16.x"],
        ["Motor de Inteligencia Artificial", "Google Gemini API (Gemini 2.5 Flash & Pro / Gemini Vision OCR)", "SDK v1.0+ (Nube)"],
        ["Entorno de Desarrollo (IDE)", "Visual Studio Code / Android Studio (Plugins Flutter y Dart)", "1.94+ / Koala-Ladybug"],
        ["Control de Versiones y Nube", "Git, GitHub y Render Cloud Hosting (Despliegue continuo de API)", "Git 2.45+ / Render PaaS"]
    ]
    for r_i, row in enumerate(t1.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = t1_data[r_i][c_i]
    format_table(t1, col_widths=[4.5, 7.5, 3.5])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "Por otra parte, la Tabla N° 2 detalla los insumos tangibles (equipamiento físico de computación, dispositivos de prueba "
        "y conectividad) indispensables para las fases de compilación, emulación, captura biométrica y validación física de la aplicación:"
    )

    add_table_title("Tabla N° 2. Insumos Tangibles (Hardware)")
    t2 = doc.add_table(rows=4, cols=3)
    t2_data = [
        ["Tipo de Equipo", "Descripción del Equipo", "Especificaciones Técnicas / Modelo"],
        [
            "Estación de Trabajo / Laptop",
            "Equipo principal de desarrollo, entrenamiento y compilación de software",
            "Procesador Intel Core i5 / AMD Ryzen 5 (6 núcleos @ 3.5 GHz), Memoria RAM: 16 GB DDR4, Almacenamiento: Disco Sólido SSD 512 GB NVMe, Sistema Operativo: Windows 11 Pro 64-bit."
        ],
        [
            "Dispositivo Móvil de Prueba",
            "Smartphone para pruebas de campo, instalación de APK y captura de fotos",
            "Dispositivo Android 13/14, Procesador Octa-Core, Memoria RAM: 8 GB, Almacenamiento Interno: 128 GB, Cámara de 50 MP para OCR de balanzas y pantalla táctil de 6.67\" FHD+."
        ],
        [
            "Equipo de Conectividad y Red",
            "Router inalámbrico de alta velocidad para transmisión local y pruebas de API",
            "Router Gigabit Doble Banda Wi-Fi 6 / AC1200, 4 antenas de alta ganancia, soporte para múltiples conexiones concurrentes y baja latencia de respuesta."
        ]
    ]
    for r_i, row in enumerate(t2.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = t2_data[r_i][c_i]
    format_table(t2, col_widths=[4.0, 5.0, 6.5])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "Asimismo, el desarrollo exitoso del sistema descansa en la participación organizada del capital humano especializado, "
        "cuyos perfiles profesionales, asignaciones funcionales y compromisos técnicos se consolidan en la Tabla N° 3:"
    )

    add_table_title("Tabla N° 3. Capital Humano (Recurso Humano de Desarrollo)")
    t3 = doc.add_table(rows=5, cols=3)
    t3_data = [
        ["Profesión / Perfil", "Rol en el Proyecto", "Responsabilidades y Tareas Asignadas"],
        [
            "Ingeniero en Computación / Sistemas",
            "Proyectista y Desarrollador Líder",
            "Diseño de la arquitectura de software, codificación frontend en Flutter/Dart, construcción de APIs asíncronas en FastAPI, orquestación de prompts para Gemini IA, integración del módulo de visión OCR y documentación técnica."
        ],
        [
            "Docente / Tutor Académico UJGH",
            "Orientador Metodológico e Institucional",
            "Supervisión del cumplimiento de los estándares de investigación, validación de la rigurosidad científica, revisión periódica de entregables y aseguramiento de la coherencia con el manual de grado de la facultad."
        ],
        [
            "Licenciado en Educación Física / Entrenador",
            "Asesor Especialista en Ciencias del Ejercicio",
            "Validación experta de las rutinas de hipertrofia y fuerza, verificación de la seguridad articular en ejercicios prescritos, revisión de los cálculos de sobrecarga progresiva y pertinencia de las directrices nutricionales."
        ],
        [
            "Atletas y Practicantes de Gimnasio",
            "Usuarios Piloto de Campo",
            "Ejecución de pruebas de usabilidad in situ, validación del flujo interactivo en teléfonos móviles, retroalimentación sobre la claridad de las rutinas y verificación del reconocimiento fotográfico en balanzas."
        ]
    ]
    for r_i, row in enumerate(t3.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = t3_data[r_i][c_i]
    format_table(t3, col_widths=[4.5, 4.0, 7.0])
    add_table_source("Fuente: Elaboración propia (2026).")

    # 3.2.2 Estudio Operativo
    add_h2("3.2.2 Estudio Operativo")

    add_p(
        "El estudio operativo tiene por finalidad evaluar la viabilidad de los procesos productivos, la organización de "
        "las tareas de ingeniería de software, los factores de producción y los costos operativos recurrentes que garantizan "
        "la disponibilidad ininterrumpida de la solución. Al respecto, Castro Sánchez (2023) señala que el estudio operativo "
        "establece la cuantificación económica de los insumos y capacidades humanas requeridas para sostener la actividad "
        "productiva de forma regular."
    )

    add_p(
        "La producción del software se organizó bajo el marco de trabajo ágil Scrum, estructurado en ciclos iterativos de dos "
        "semanas (sprints) en los cuales se definieron requerimientos, se programaron componentes y se llevaron a cabo pruebas "
        "unitarias y de integración continua. Este enfoque permite responder con agilidad ante cualquier ajuste en los módulos "
        "de inteligencia artificial y biomecánica."
    )

    add_p(
        "A continuación, se exponen de forma analítica las tablas de costos correspondientes a los insumos y factores operativos. "
        "La Tabla N° 4 detalla los costos asociados al software, licenciamiento y servicios de computación en la nube:"
    )

    add_table_title("Tabla N° 4. Costos de Insumos Intangibles (Software)")
    t4 = doc.add_table(rows=7, cols=4)
    t4_data = [
        ["Descripción de la Herramienta", "Cantidad", "Costo Unitario (USD)", "Costo Total Anualizado (USD)"],
        ["Entorno Flutter SDK / Dart / Python / FastAPI", "1", "$0,00", "$0,00 (Código Abierto)"],
        ["Base de Datos SQLite / PostgreSQL", "1", "$0,00", "$0,00 (Código Abierto)"],
        ["Visual Studio Code / Android Studio IDE", "1", "$0,00", "$0,00 (Licencia Gratuita)"],
        ["Licencia de Desarrollador Google Play Store", "1", "$25,00", "$25,00 (Pago Único Vitalicio)"],
        ["Infraestructura Nube Render & Google Gemini API", "12 meses", "$10,00", "$120,00 (Consumo Controlado)"],
        ["Dominio Web y Certificados de Seguridad SSL", "1 año", "$15,00", "$15,00"],
        ["Total General de Insumos Intangibles", "6", "$50,00", "$160,00"]
    ]
    for r_i, row in enumerate(t4.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = t4_data[r_i][c_i]
    format_table(t4, col_widths=[6.5, 2.5, 3.2, 3.3])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "Por su parte, la Tabla N° 5 especifica los costos de adquisición y el cálculo de depreciación anual en línea recta "
        "(a razón de 5 años de vida útil, correspondiente al 20% anual según las normas contables estandarizadas) para el "
        "equipamiento de hardware empleado en el desarrollo del sistema:"
    )

    add_table_title("Tabla N° 5. Costos de Insumos Tangibles (Hardware)")
    t5 = doc.add_table(rows=5, cols=4)
    t5_data = [
        ["Descripción del Equipo", "Cantidad", "Costo Unitario (USD)", "Depreciación Anual (5 Años) (USD)"],
        ["Estación de Trabajo / Laptop Core i5, 16 GB RAM, SSD 512 GB", "1", "$450,00", "$90,00 ($450,00 / 5 años)"],
        ["Smartphone de Pruebas Android 13/14, 8 GB RAM, 128 GB ROM", "1", "$180,00", "$36,00 ($180,00 / 5 años)"],
        ["Router Inalámbrico Gigabit Wi-Fi 6 / AC1200", "1", "$50,00", "$10,00 ($50,00 / 5 años)"],
        ["Total Equipos de Hardware", "3", "$680,00", "$136,00"]
    ]
    for r_i, row in enumerate(t5.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = t5_data[r_i][c_i]
    format_table(t5, col_widths=[6.5, 2.5, 3.2, 3.3])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "El componente humano constituye el factor de producción más relevante para la creación y mantenimiento del software. "
        "La Tabla N° 6 presenta la estructura de nómina técnica, considerando sueldos mensuales referenciales del mercado "
        "informático venezolano y el factor de beneficios de ley (prestaciones sociales, bono vacacional y utilidades anuales "
        "según la LOTTT), junto con la proyección trianual de compensación salarial:"
    )

    add_table_title("Tabla N° 6. Costo de Recurso Humano de Desarrollo")
    t6 = doc.add_table(rows=5, cols=8)
    t6_data = [
        ["Cargo / Perfil", "Cant.", "Sueldo Mensual (USD)", "Factor Beneficio (USD)", "Costo Anual Nómina (USD)", "Año 1 (USD)", "Año 2 (+10%) (USD)", "Año 3 (+15%) (USD)"],
        ["Desarrollador Full-Stack", "1", "$450,00", "$900,00", "$6.300,00", "$6.300,00", "$6.930,00", "$7.969,50"],
        ["Administrador BD & Backend", "1", "$300,00", "$600,00", "$4.200,00", "$4.200,00", "$4.620,00", "$5.313,00"],
        ["Analista QA & Biomecánica", "1", "$250,00", "$500,00", "$3.500,00", "$3.500,00", "$3.850,00", "$4.427,50"],
        ["Total Nómina Técnica", "3", "$1.000,00", "$2.000,00", "$14.000,00", "$14.000,00", "$15.400,00", "$17.710,00"]
    ]
    for r_i, row in enumerate(t6.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = t6_data[r_i][c_i]
    format_table(t6, col_widths=[2.8, 1.0, 1.8, 1.8, 2.0, 2.0, 2.1, 2.1])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "Adicionalmente, el estudio operativo contempla los gastos por concepto de suministros de oficina, papelería, servicios "
        "de conectividad a internet de fibra óptica y contingencias de respaldo eléctrico indispensables para la operatividad en "
        "el municipio Maracaibo, tal como se refleja en la Tabla N° 7 con su proyección a tres años:"
    )

    add_table_title("Tabla N° 7. Costos de Suministros / Servicios")
    t7 = doc.add_table(rows=6, cols=6)
    t7_data = [
        ["Descripción del Suministro / Servicio", "Cantidad", "Costo Unitario (USD)", "Año 1 Costo Total (USD)", "Año 2 (+10%) (USD)", "Año 3 (+10%) (USD)"],
        ["Resma de papel, carpetas y bolígrafos", "1 paquete", "$35,00", "$35,00", "$38,50", "$42,35"],
        ["Internet de Fibra Óptica (Airtek Maracaibo)", "12 meses", "$35,00", "$420,00", "$462,00", "$508,20"],
        ["Respaldo de conectividad móvil / datos móviles", "12 meses", "$5,00", "$60,00", "$66,00", "$72,60"],
        ["Tinta para impresión de documentación técnica", "1 juego", "$20,00", "$20,00", "$22,00", "$24,20"],
        ["Total Suministros y Servicios", "4", "$95,00", "$515,00", "$566,50", "$623,15"]
    ]
    for r_i, row in enumerate(t7.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = t7_data[r_i][c_i]
    format_table(t7, col_widths=[5.0, 1.8, 2.4, 2.4, 2.4, 2.4])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "Por último, dentro del estudio operativo se quantifica la inversión en mobiliario y equipos auxiliares que conforman "
        "el espacio de trabajo físico del proyectista, detallando sus valores y su correspondiente depreciación anual a 5 años "
        "en la Tabla N° 8:"
    )

    add_table_title("Tabla N° 8. Mobiliario y Equipos")
    t8 = doc.add_table(rows=6, cols=4)
    t8_data = [
        ["Descripción del Mobiliario / Equipo", "Cantidad", "Costo Unitario (USD)", "Depreciación Anual (5 Años) (USD)"],
        ["Escritorio ergonómico de trabajo de oficina", "1", "$120,00", "$24,00 ($120,00 / 5 años)"],
        ["Silla ergonómica ejecutiva de oficina", "1", "$80,00", "$16,00 ($80,00 / 5 años)"],
        ["Regulador de voltaje / Protector UPS Forza (Respaldo eléctrico)", "1", "$90,00", "$18,00 ($90,00 / 5 años)"],
        ["Aire acondicionado de ventana 12.000 BTU (Climatización de oficina)", "1", "$250,00", "$50,00 ($250,00 / 5 años)"],
        ["Total Mobiliario y Equipos", "4", "$540,00", "$108,00"]
    ]
    for r_i, row in enumerate(t8.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = t8_data[r_i][c_i]
    format_table(t8, col_widths=[6.5, 2.5, 3.2, 3.3])
    add_table_source("Fuente: Elaboración propia (2026).")

    # 3.2.3 Estudio Económico
    add_h2("3.2.3 Estudio Económico")

    add_p(
        "El estudio económico tiene como propósito fundamental sistematizar la información de carácter financiero "
        "relacionada con la inversión inicial requerida, la estimación proyectada de los ingresos brutos, la programación "
        "de los costos operativos, la determinación de la utilidad gravable y el comportamiento del flujo de tesorería "
        "a lo largo de un horizonte de evaluación de tres años. Este análisis permite contrastar los desembolsos de capital "
        "contra los excedentes generados, demostrando la viabilidad y sostenibilidad económica del proyecto en el tiempo."
    )

    add_p(
        "De acuerdo con Gabriel Baca Urbina (2021), la evaluación económica de un proyecto tecnológico reside en cuantificar "
        "el rendimiento de los recursos aplicados mediante el uso de modelos dinámicos como el Valor Actual Neto (VAN) y la "
        "Tasa Interna de Retorno (TIR), herramientas analíticas que consideran el valor del dinero en el tiempo y permiten "
        "establecer conclusiones fundadas sobre la conveniencia gerencial de ejecutar la propuesta."
    )

    add_p(
        "El Cuadro N° 1 presenta de forma consolidada el Plan de Inversión Inicial para el Año 0, diferenciando las inversiones "
        "tangibles e intangibles requeridas para la puesta en marcha del sistema experto, evidenciando que el capital es cubierto "
        "en su totalidad mediante aportes propios del proyectista sin necesidad de endeudamiento financiero externo:"
    )

    add_table_title("Cuadro N° 1. Plan de Inversión")
    c1 = doc.add_table(rows=11, cols=4)
    c1_data = [
        ["Concepto de Inversión", "Aporte Propio (USD)", "Financiamiento Bancario", "Total Inversión (USD)"],
        ["INVERSIÓN TANGIBLE", "INVERSIÓN TANGIBLE", "INVERSIÓN TANGIBLE", "INVERSIÓN TANGIBLE"],
        ["Equipamiento de Hardware (Laptop, Móvil, Router)", "$680,00", "$0,00", "$680,00"],
        ["Mobiliario y Equipos de Oficina (Climatización y UPS)", "$540,00", "$0,00", "$540,00"],
        ["Subtotal Inversión Tangible", "$1.220,00", "$0,00", "$1.220,00"],
        ["INVERSIÓN INTANGIBLE", "INVERSIÓN INTANGIBLE", "INVERSIÓN INTANGIBLE", "INVERSIÓN INTANGIBLE"],
        ["Software, Licencias y Alojamiento Nube (Año 1)", "$160,00", "$0,00", "$160,00"],
        ["Gastos de Registro de Marca y Formalización Legal (SAPI)", "$400,00", "$0,00", "$400,00"],
        ["Fondo para Imprevistos Operativos (5% sobre inversión)", "$89,00", "$0,00", "$89,00"],
        ["Subtotal Inversión Intangible", "$649,00", "$0,00", "$649,00"],
        ["TOTAL GENERAL DE INVERSIÓN INICIAL (AÑO 0)", "$1.869,00", "$0,00", "$1.869,00"]
    ]
    for r_i, row in enumerate(c1.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = c1_data[r_i][c_i]
    format_table(c1, col_widths=[6.5, 3.2, 3.0, 3.3])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "La sostenibilidad económica del proyecto a largo plazo se sustenta en la diversificación de sus flujos de entrada. "
        "En el Cuadro N° 2 se expone la proyección analítica de los ingresos brutos anuales para el trienio de operaciones, "
        "desglosando tres líneas comerciales realistas: suscripciones Premium de usuarios individuales, licencias B2B para "
        "entrenadores y gimnasios de la región zuliana, y convenios publicitarios contextuales no invasivos con marcas deportivas:"
    )

    add_table_title("Cuadro N° 2. Ingresos Proyectados")
    c2 = doc.add_table(rows=5, cols=6)
    c2_data = [
        ["Concepto de Venta / Servicio", "Usuarios Mes (Prom.)", "Tarifa Unit. (USD)", "Año 1 (USD)", "Año 2 (USD)", "Año 3 (USD)"],
        ["Suscripciones Premium Individuales (Atletas/Usuarios)", "250 - 520", "$4,00 - $4,50", "$12.000,00", "$18.240,00", "$28.080,00"],
        ["Licencias Profesionales B2B (Gimnasios y Entrenadores)", "15 - 35", "$25,00 - $30,00", "$4.500,00", "$7.500,00", "$12.600,00"],
        ["Convenios Publicitarios y Marcas Fitness Locales", "Alianzas", "$150,00 - $400,00/mes", "$1.800,00", "$3.000,00", "$4.800,00"],
        ["TOTAL DE INGRESOS BRUTOS PROYECTADOS", "--", "--", "$18.300,00", "$28.740,00", "$45.480,00"]
    ]
    for r_i, row in enumerate(c2.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = c2_data[r_i][c_i]
    format_table(c2, col_widths=[4.5, 2.2, 2.3, 2.3, 2.3, 2.3])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "Frente a los ingresos estimados, el sistema genera egresos operativos indispensables para sostener la infraestructura "
        "digital, la nómina técnica y los servicios públicos. En el Cuadro N° 3 se presenta la consolidación sistemática de estos "
        "egresos operativos proyectados para los tres primeros años de operación continua:"
    )

    add_table_title("Cuadro N° 3. Egresos Proyectados")
    c3 = doc.add_table(rows=6, cols=4)
    c3_data = [
        ["Partida de Egreso Operativo", "Año 1 (USD)", "Año 2 (USD)", "Año 3 (USD)"],
        ["Mano de Obra Técnica (Nómina y Beneficios de Ley)", "$14.000,00", "$15.400,00", "$17.710,00"],
        ["Infraestructura Nube, APIs de IA Gemini y Almacenamiento", "$180,00", "$350,00", "$600,00"],
        ["Suministros de Oficina, Papelería y Conectividad Fibra Óptica", "$515,00", "$566,50", "$623,15"],
        ["Mantenimiento Técnico, Seguridad y Contingencias", "$200,00", "$250,00", "$300,00"],
        ["TOTAL DE EGRESOS OPERATIVOS PROYECTADOS", "$14.895,00", "$16.566,50", "$19.233,15"]
    ]
    for r_i, row in enumerate(c3.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = c3_data[r_i][c_i]
    format_table(c3, col_widths=[6.5, 3.0, 3.0, 3.3])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "Al contrastar los ingresos brutos frente a los egresos operativos y deducir la depreciación anualizada de los activos "
        "físicos de computación y oficina ($244,00 anuales entre hardware y mobiliario), se determina la rentabilidad real de la "
        "iniciativa mediante el cálculo del Estado de Resultados (Ganancias y Pérdidas), aplicando la alícuota del 34% correspondiente "
        "al Impuesto Sobre la Renta (ISLR) según la normativa tributaria venezolana, tal como se refleja en el Cuadro N° 4:"
    )

    add_table_title("Cuadro N° 4. Estado de Resultados (Ganancias y Pérdidas Proyectado)")
    c4 = doc.add_table(rows=7, cols=4)
    c4_data = [
        ["Descripción de la Cuenta Financiera", "Año 1 (USD)", "Año 2 (USD)", "Año 3 (USD)"],
        ["Ingresos Operativos Totales", "$18.300,00", "$28.740,00", "$45.480,00"],
        ["(-) Egresos Operativos Totales", "$14.895,00", "$16.566,50", "$19.233,15"],
        ["(-) Depreciación Acumulada de Activos (Hardware y Mobiliario)", "$244,00", "$244,00", "$244,00"],
        ["Utilidad Bruta antes de Impuestos", "$3.161,00", "$11.929,50", "$26.002,85"],
        ["Impuesto Sobre la Renta (ISLR 34% Tarifa Legal Vigente)", "$1.074,74", "$4.056,03", "$8.840,97"],
        ["UTILIDAD NETA FINAL DEL EJERCICIO", "$2.086,26", "$7.873,47", "$17.161,88"]
    ]
    for r_i, row in enumerate(c4.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = c4_data[r_i][c_i]
    format_table(c4, col_widths=[6.5, 3.0, 3.0, 3.3])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "Asimismo, resulta fundamental verificar la liquidez y solvencia en efectivo de la organización tecnológica a través "
        "del presupuesto de caja. En el Cuadro N° 5 se expone el Flujo de Caja Proyectado, incorporando el desembolso inicial de "
        "inversión en el Año 0 y contrastando las entradas reales de efectivo contra las salidas operativas y los compromisos "
        "tributarios efectivamente cancelados:"
    )

    add_table_title("Cuadro N° 5. Flujo de Caja Proyectado")
    c5 = doc.add_table(rows=7, cols=5)
    c5_data = [
        ["Períodos / Conceptos Financieros", "Año 0 (USD)", "Año 1 (USD)", "Año 2 (USD)", "Año 3 (USD)"],
        ["Ingresos Efectivos de Caja", "$0,00", "$18.300,00", "$28.740,00", "$45.480,00"],
        ["(-) Inversión Inicial de Capital", "$1.869,00", "$0,00", "$0,00", "$0,00"],
        ["(-) Egresos Operativos Efectivos", "$0,00", "$14.895,00", "$16.566,50", "$19.233,15"],
        ["(-) Pago de Impuesto Sobre la Renta (ISLR)", "$0,00", "$1.074,74", "$4.056,03", "$8.840,97"],
        ["FLUJO DE CAJA NETO (FCN)", "($1.869,00)", "$2.330,26", "$8.117,47", "$17.405,88"],
        ["FLUJO DE CAJA ACUMULADO (FCA)", "($1.869,00)", "$461,26", "$8.578,73", "$25.984,61"]
    ]
    for r_i, row in enumerate(c5.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = c5_data[r_i][c_i]
    format_table(c5, col_widths=[4.5, 2.7, 2.7, 2.7, 3.0])
    add_table_source("Fuente: Elaboración propia (2026).")

    add_p(
        "El comportamiento del Flujo de Caja Acumulado demuestra que el proyecto recupera la totalidad del capital invertido "
        "en el transcurso del primer año de operaciones ($461,26 de saldo neto positivo al cierre del Año 1), consolidando una "
        "reserva acumulada superior a los 25.900,00 USD al finalizar el trienio. Esta solidez en tesorería garantiza la capacidad "
        "de autofinanciamiento para futuras expansiones del clúster de servidores e investigación en inteligencia artificial."
    )

    add_p(
        "Finalmente, para emitir un juicio concluyente sobre la factibilidad financiera, se procedió al cálculo de los tres "
        "indicadores cuantitativos universales de evaluación de proyectos: el Valor Actual Neto (VAN), la Tasa Interna de "
        "Retorno (TIR) y la Relación Beneficio/Costo (B/C), empleando una tasa de descuento de referencia del 12,00% anual "
        "(costo de oportunidad del capital en el sector de tecnologías de información y servicios de software). Los resultados "
        "y sus respectivas interpretaciones gerenciales se sintetizan en el Cuadro N° 6:"
    )

    add_table_title("Cuadro N° 6. Indicadores Financieros de Evaluación")
    c6 = doc.add_table(rows=7, cols=3)
    c6_data = [
        ["Indicador Financiero de Evaluación", "Resultado Cuantitativo", "Interpretación y Dictamen Gerencial"],
        ["Inversión Inicial de Capital (I0)", "$1.869,00 USD", "Monto total de fondos desembolsados en el Año 0, cubiertos al 100% con aportes propios."],
        ["Tasa de Descuento de Referencia (i)", "12,00% Anual", "Rendimiento mínimo exigido para proyectos tecnológicos de desarrollo de software."],
        ["Valor Actual Neto (VAN)", "$19.071,95 USD", "Al ser estrictamente positivo (VAN > 0), demuestra que el proyecto recupera la inversión y crea un valor económico sustancial."],
        ["Tasa Interna de Retorno (TIR)", "236,23% Anual", "Rendimiento intrínseco muy superior a la tasa de descuento (236,23% > 12%), ratificando una rentabilidad extraordinaria."],
        ["Relación Beneficio / Costo (B/C)", "1,36", "Por cada 1,00 USD invertido y comprometido en egresos operativos, el sistema genera 1,36 USD en valor actual neto."],
        ["Período de Recuperación de Inversión (PRI)", "9,6 Meses", "El capital inicial se reintegra plenamente antes de culminar el primer año fiscal de operaciones comerciales."]
    ]
    for r_i, row in enumerate(c6.rows):
        for c_i, cell in enumerate(row.cells):
            cell.text = c6_data[r_i][c_i]
    format_table(c6, col_widths=[4.5, 3.2, 8.0])
    add_table_source("Fuente: Elaboración propia (2026).")

    # ------------------------------------------
    # 3.3 ASPECTOS LEGALES
    # ------------------------------------------
    add_h1("3.3 Aspectos Legales")

    add_p(
        "El marco legal constituye una dimensión indispensable dentro del estudio de factibilidad, ya que permite verificar "
        "que el diseño, codificación, despliegue y explotación comercial de la aplicación móvil se ajusten plenamente al "
        "ordenamiento jurídico de la República Bolivariana de Venezuela, previniendo litigios, resguardando los derechos "
        "de propiedad intelectual del desarrollador y asegurando la debida custodia de la privacidad de los usuarios."
    )

    add_p(
        "De acuerdo con Andrew Murray (2022), las soluciones fundamentadas en tecnologías de la información deben observar "
        "un estricto apego a las disposiciones sobre protección de datos personales, uso legítimo de librerías bajo licencias "
        "permisivas y cumplimiento del marco regulatorio del sector de software, asegurando un despliegue ético y jurídicamente blindado."
    )

    add_p(
        "En primer término, el proyecto se sustenta en la Constitución de la República Bolivariana de Venezuela (1999), "
        "cuyo Artículo 110 consagra que el Estado reconoce el interés público de la ciencia, la tecnología, el conocimiento, "
        "la innovación y sus aplicaciones, así como los servicios de información, por ser instrumentos fundamentales para el "
        "desarrollo económico, social y político del país. Asimismo, el Artículo 111 consagra el derecho fundamental al deporte "
        "y a la recreación como actividades que benefician la calidad de vida individual y colectiva, precepto constitucional "
        "que ampara y estimula la creación de herramientas tecnológicas orientadas al acondicionamiento físico responsable."
    )

    add_p(
        "En el ámbito de las tecnologías de información y la administración del software, la iniciativa se alinea con los "
        "postulados de la Ley de Infogobierno (Gaceta Oficial N° 40.274, 2013), la cual establece como principio rector el uso "
        "prioritario de tecnologías libres y estándares abiertos para garantizar la soberanía tecnológica, la transparencia "
        "y la interoperabilidad. La elección de Flutter, Dart, Python, FastAPI y PostgreSQL como pila tecnológica central "
        "cumple cabalmente con esta premisa de apertura y no dependencia tecnológica."
    )

    add_p(
        "Asimismo, el proyecto se encuentra enmarcado en la Ley Orgánica de Ciencia, Tecnología e Innovación (LOCTI, 2022), "
        "la cual promueve el fomento de soluciones informáticas innovadoras formuladas por instituciones de educación universitaria "
        "que respondan a las necesidades concretas de la sociedad y fortalezcan las capacidades del capital humano nacional."
    )

    add_p(
        "Para salvaguardar la confidencialidad de la información y la integridad de los datos procesados, el sistema "
        "cumple de manera estricta con las disposiciones de la Ley Especial contra los Delitos Informáticos (Gaceta Oficial "
        "N° 37.313, 2001). Esta normativa resulta vital para tipificar y prevenir cualquier acceso no autorizado (Artículo 6), "
        "sabotaje o daño a sistemas computacionales (Artículo 7) o violación a la privacidad de las comunicaciones y datos "
        "biométricos de los usuarios (Artículo 20). En concordancia con esta ley, el sistema implementa mecanismos robustos "
        "de autenticación mediante tokens criptográficos JWT, cifrado en reposo para credenciales y transmisión segura bajo "
        "protocolo HTTPS/TLS, asegurando que las fotografías de progreso y datos de peso del usuario se mantengan estrictamente "
        "privados y resguardados de accesos ilegítimos."
    )

    add_p(
        "Por su parte, el manejo de las transacciones electrónicas, la aceptación de términos de servicio y el consentimiento "
        "informado del usuario se rigen por la Ley sobre Mensajes de Datos y Firmas Electrónicas (Gaceta Oficial N° 37.072, "
        "2001), otorgando plena validez probatoria y eficacia jurídica a los registros digitales y acuerdos suscritos a través "
        "de la aplicación móvil."
    )

    add_p(
        "En materia de propiedad intelectual, el código fuente original, los modelos de inferencia, las interfaces gráficas y "
        "la base de conocimientos construida para el sistema experto gozan del régimen tutelar de la Ley sobre el Derecho de "
        "Autor (1993), la cual protege los programas de computación como obras del ingenio desde el momento mismo de su creación, "
        "pudiendo tramitarse su registro formal ante el Servicio Autónomo de la Propiedad Intelectual (SAPI) para su explotación "
        "comercial pacífica frente a plagios o reproducciones no autorizadas."
    )

    add_p(
        "Adicionalmente, el proyecto respeta la Ley Orgánica de Deporte, Actividad Física y Educación Física (Gaceta Oficial "
        "N° 39.759, 2011), al promover un entrenamiento científicamente estructurado que previene sobrecargas musculares, "
        "promueve la salud preventiva y democratiza el acceso a la preparación física metodológica."
    )

    add_p(
        "Por último, el modelo de ingresos por suscripciones y convenios comerciales proyectado cumple con la normativa "
        "tributaria emanada del Servicio Nacional Integrado de Administración Aduanera y Tributaria (SENIAT) y las disposiciones "
        "del Código Orgánico Tributario, formalizando la tributación del Impuesto Sobre la Renta (ISLR) correspondiente al "
        "ejercicio de actividades económicas comerciales lícitas dentro del territorio nacional."
    )

    add_p(
        "En conclusión, se dictamina que el proyecto denominado Sistema experto móvil para la asistencia integral de fitness: "
        "Desde la gestión operativa hasta la tutoría técnica de ejercicios y alimentación con inteligencia artificial resulta "
        "plenamente viable desde el punto de vista legal, al conformar una solución tecnológica original, respetuosa del marco "
        "jurídico vigente y orientada al bienestar de la sociedad venezolana."
    )

    # Guardar documento
    doc.save(OUTPUT_FILE)
    print(f"Documento generado exitosamente en: {OUTPUT_FILE}")

if __name__ == "__main__":
    create_document()
