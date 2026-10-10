"""Genera el PDF del stack tecnologico y funcionalidades de AI Fitness Coach.

Lee el archivo de texto con el mismo contenido y lo convierte en un PDF con
indice, portada y estilos (titulos, tablas y bloques de codigo).

Uso:
    python scripts/build_stack_pdf.py
"""

from __future__ import annotations

import os
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    ListFlowable,
    ListItem,
    PageBreak,
    PageTemplate,
    Paragraph,
    Preformatted,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "STACK_TECNOLOGICO_Y_FUNCIONALIDADES.txt"
OUTPUT = ROOT / "docs" / "STACK_TECNOLOGICO_Y_FUNCIONALIDADES.pdf"

GREEN = colors.HexColor("#1FAE87")
DARK = colors.HexColor("#16233A")
GREY = colors.HexColor("#5A6472")
LIGHT = colors.HexColor("#E8EDF2")

PAGE_W, PAGE_H = A4
MARGIN = 2 * cm


def build_styles() -> dict[str, ParagraphStyle]:
    """Estilos del documento, pensados para leerse en pantalla o impreso."""
    base = getSampleStyleSheet()
    return {
        "cover_title": ParagraphStyle(
            "cover_title", parent=base["Title"], fontSize=30, leading=36,
            textColor=DARK, spaceAfter=10, alignment=TA_CENTER,
        ),
        "cover_sub": ParagraphStyle(
            "cover_sub", parent=base["Normal"], fontSize=13, leading=19,
            textColor=GREY, alignment=TA_CENTER, spaceAfter=6,
        ),
        "h1": ParagraphStyle(
            "h1", parent=base["Heading1"], fontSize=19, leading=24,
            textColor=DARK, spaceBefore=20, spaceAfter=10,
        ),
        "h2": ParagraphStyle(
            "h2", parent=base["Heading2"], fontSize=14, leading=19,
            textColor=GREEN, spaceBefore=15, spaceAfter=7,
        ),
        "h3": ParagraphStyle(
            "h3", parent=base["Heading3"], fontSize=11.5, leading=16,
            textColor=DARK, spaceBefore=11, spaceAfter=5,
        ),
        "body": ParagraphStyle(
            "body", parent=base["Normal"], fontSize=9.8, leading=15.5,
            textColor=colors.HexColor("#22262B"), spaceAfter=7,
            alignment=4,
        ),
        "cell": ParagraphStyle(
            "cell", parent=base["Normal"], fontSize=8.6, leading=12,
            textColor=colors.HexColor("#22262B"),
        ),
        "cell_head": ParagraphStyle(
            "cell_head", parent=base["Normal"], fontSize=8.6, leading=12,
            textColor=colors.white, fontName="Helvetica-Bold",
        ),
        "code": ParagraphStyle(
            "code", parent=base["Code"], fontSize=8, leading=11.5,
            textColor=colors.HexColor("#0B1220"), backColor=LIGHT,
            borderPadding=6, spaceAfter=7,
        ),
    }


def esc(text: str) -> str:
    """Escapa el texto para que ReportLab lo interprete como literal."""
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def is_section(line: str) -> bool:
    """True si la linea es un separador de seccion (===== o ----)."""
    return bool(re.fullmatch(r"[=\-]{3,}", line.strip()))


def is_numbered(line: str) -> bool:
    """True si la linea empieza un punto numerado."""
    return bool(re.match(r"^\s{0,4}\d+\.\s+\S", line))


def make_table(rows: list[list[str]], styles: dict) -> Table:
    """Arma una tabla con cabecera verde y filas alternadas."""
    header, body = rows[0], rows[1:]
    data = [[Paragraph(esc(c), styles["cell_head"]) for c in header]]
    for row in body:
        data.append([Paragraph(esc(c), styles["cell"]) for c in row])

    # Anchos proporcionales al contenido de cada columna.
    widths = []
    for index in range(len(header)):
        longest = max(len(r[index]) for r in rows)
        widths.append(min(9 * cm, max(2.6 * cm, longest * 0.19 * cm)))

    table = Table(data, colWidths=widths, repeatRows=1, hAlign="LEFT")
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), DARK),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("GRID", (0, 0), (-1, -1), 0.4, LIGHT),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
    ] + [
        ("BACKGROUND", (0, i), (-1, i), colors.HexColor("#F7F9FB"))
        for i in range(1, len(data)) if i % 2 == 0
    ]))
    return table


def collect_rows(block: list[str]) -> list[list[str]]:
    """Convierte un bloque de texto con dos columnas en filas de tabla."""
    rows = []
    for line in block:
        if not line.strip():
            continue
        cells = [c.strip() for c in re.split(r"\s{2,}", line.strip()) if c.strip()]
        # La fila de guiones que separa la cabecera no es contenido real.
        if cells and all(set(c) <= set("-= .") for c in cells):
            continue
        if len(cells) >= 2:
            rows.append(cells[:2])
        elif rows:
            rows[-1][-1] += " " + cells[0]
    return rows


def parse(lines: list[str], styles: dict) -> list:
    """Convierte el archivo de texto en elementos del PDF."""
    story: list = []
    index = 0
    in_code = False
    code_lines: list[str] = []
    para_lines: list[str] = []
    bullets: list[str] = []
    table_lines: list[str] = []
    items: list[str] = []

    def flush_paragraph() -> None:
        nonlocal para_lines
        if para_lines:
            story.append(Paragraph(esc(" ".join(para_lines)), styles["body"]))
            para_lines = []

    def flush_bullets() -> None:
        nonlocal bullets
        if bullets:
            story.append(ListFlowable(
                [ListItem(Paragraph(esc(b), styles["body"])) for b in bullets],
                bulletType="bullet", leftIndent=14, bulletFontSize=7,
            ))
            bullets = []

    def flush_table() -> None:
        nonlocal table_lines
        if table_lines:
            rows = collect_rows(table_lines)
            if len(rows) > 1 and all(len(r) == 2 for r in rows):
                story.append(Spacer(1, 4))
                story.append(make_table(rows, styles))
                story.append(Spacer(1, 8))
            else:
                for line in table_lines:
                    if line.strip():
                        story.append(Paragraph(esc(line.strip()), styles["body"]))
        table_lines = []

    def flush_numbered() -> None:
        nonlocal items
        if items:
            story.append(ListFlowable(
                [ListItem(Paragraph(esc(t), styles["body"])) for t in items],
                bulletType="1", leftIndent=16, bulletFontSize=8,
            ))
            items = []

    def flush_all() -> None:
        flush_paragraph()
        flush_bullets()
        flush_table()
        flush_numbered()

    while index < len(lines):
        line = lines[index].rstrip()
        stripped = line.strip()

        # Tablas: dos o mas columnas separadas por espacios.
        # Se revisan antes que el codigo, porque una linea como
        # \Papel    Framework web de la API REST\ tiene sangria de 4
        # espacios y de otro modo se tomaria como bloque de codigo.
        if stripped and re.search(r'\S\s{2,}\S', stripped):
            flush_all()
            table_lines = [line]
            index += 1
            while index < len(lines):
                nxt = lines[index].rstrip()
                if nxt.strip() and re.search(r'\S\s{2,}\S', nxt):
                    table_lines.append(nxt)
                    index += 1
                    continue
                break
            flush_table()
            continue

        # Bloque de codigo: sangria de 4 espacios y que no sea tabla.
        if stripped.startswith('    ') and stripped.strip('.'):
            code_lines = [line]
            index += 1
            while index < len(lines):
                nxt = lines[index].rstrip()
                if nxt.strip().startswith('...'):
                    index += 1
                    break
                # Una linea en blanco o sin sangria cierra el bloque.
                if not nxt.strip() or not nxt.startswith('    '):
                    break
                code_lines.append(nxt)
                index += 1
            flush_all()
            story.append(Preformatted(
                '\n'.join(l[4:] if l.startswith('    ') else l
                          for l in code_lines),
                styles['code'],
            ))
            continue

        # Separadores decorativos: se ignoran.
        if is_section(line):
            flush_all()
            index += 1
            # El texto anterior al separador es el titulo de la seccion.
            continue

        # Titulos numerados: "1. QUE ES LA APLICACION"
        heading = re.match(r"^(\d+)\.\s+([A-ZÁÉÍÓÚÑ0-9 .\-]{4,})$", stripped)
        if heading and not line.startswith(" "):
            flush_all()
            story.append(Paragraph(esc(heading.group(2).title()), styles["h1"]))
            story.append(Paragraph("", styles["body"]))
            index += 1
            continue

        # Subtitulos: "  4.1 PERFIL DE SALUD"
        sub = re.match(r"^(\d+\.\d+)\s+(.+)$", stripped)
        if sub:
            flush_all()
            story.append(Paragraph(esc(sub.group(2).title().strip()), styles["h2"]))
            index += 1
            continue

        # Linea de primer nivel con asterisco: encabezado de pantalla.
        if re.match(r"^[A-ZÁÉÍÓÚÑ][A-Za-zÁÉÍÓÚÑáéíóúñ ]{3,40}$", stripped) and stripped.endswith(":"):
            flush_all()
            story.append(Paragraph(esc(stripped[:-1]), styles["h3"]))
            index += 1
            continue

        # Tablas: varias columnas separadas por dos o mas espacios.
        if stripped and re.search(r"\S\s{2,}\S", stripped):
            flush_all()
            table_lines = [line]
            index += 1
            continue

        # Listas con vinetas.
        if stripped.startswith("- "):
            flush_all()
            bullets.append(stripped[2:].strip())
            index += 1
            continue

        # Puntos numerados dentro de una seccion: se acumulan y se emiten
        # juntos, para que la numeracion sea 1, 2, 3 y no 1, 1, 1.
        if is_numbered(line):
            flush_paragraph()
            flush_bullets()
            flush_table()
            items.append(re.sub(r"^\s*\d+\.\s+", "", line))
            index += 1
            continue

        # Parrafo normal: se acumula hasta la proxima linea en blanco.
        if stripped:
            flush_all()
            para_lines.append(stripped)
            index += 1
            continue

        # Linea en blanco cierra lo que hubiera abierto.
        flush_all()
        index += 1

    flush_all()
    return story

def draw_page(canvas, doc) -> None:
    """Dibuja el pie de pagina con el nombre del proyecto y la numeracion."""
    canvas.saveState()
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(GREY)
    canvas.drawString(MARGIN, 1.2 * cm, "AI Fitness Coach  |  Documento tecnico")
    canvas.drawRightString(PAGE_W - MARGIN, 1.2 * cm, f"Pagina {doc.page}")
    canvas.setStrokeColor(LIGHT)
    canvas.setLineWidth(0.5)
    canvas.line(MARGIN, 1.5 * cm, PAGE_W - MARGIN, 1.5 * cm)
    canvas.restoreState()


def build_cover(styles: dict) -> list:
    """Portada e indice de secciones."""
    return [
        Spacer(1, 5 * cm),
        Paragraph("AI FITNESS COACH", styles["cover_title"]),
        Paragraph("Stack tecnologico y funcionalidades esenciales",
                  styles["cover_sub"]),
        Spacer(1, 0.6 * cm),
        Paragraph("Version 1.0.7+8  ·  26 de septiembre de 2026",
                  styles["cover_sub"]),
        Spacer(1, 3.2 * cm),
        Paragraph("Que es la aplicacion", styles["h2"]),
        Paragraph(esc(
            "Entrenador personal digital que genera planes de entrenamiento y "
            "alimentacion personalizados, organizados dia a dia. La idea central "
            "es la sinergia: entrenamiento y alimentacion forman un unico plan."
        ), styles["body"]),
        Spacer(1, 0.8 * cm),
        Paragraph("Stack en una linea", styles["h2"]),
        Paragraph(esc(
            "Flutter (Android) + FastAPI (Python) + Supabase (PostgreSQL) + "
            "cadena de IA con failover (Gemini, OpenRouter, Mistral)."
        ), styles["body"]),
        PageBreak(),
    ]


def main() -> None:
    """Genera el PDF a partir del archivo de texto."""
    if not SOURCE.exists():
        raise SystemExit(f"No se encuentra el archivo fuente: {SOURCE}")

    styles = build_styles()
    lines = SOURCE.read_text(encoding="utf-8").splitlines()

    # Se descarta la portada de texto, porque el PDF ya trae la suya.
    start = 0
    for i, line in enumerate(lines):
        if re.match(r"^\s*1\.\s+QUE ES LA APLICACION", line):
            start = i
            break

    doc = BaseDocTemplate(
        str(OUTPUT), pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=MARGIN, bottomMargin=2 * cm,
        title="AI Fitness Coach - Stack tecnologico y funcionalidades",
        author="AI Fitness Coach",
    )
    frame = Frame(
        MARGIN, 2 * cm, PAGE_W - 2 * MARGIN, PAGE_H - MARGIN - 2 * cm,
        id="main",
    )
    doc.addPageTemplates([
        PageTemplate(id="cover", frames=[frame], onPage=draw_page),
    ])

    story = build_cover(styles) + parse(lines[start:], styles)
    doc.build(story)
    print(f"PDF generado: {OUTPUT}")


if __name__ == "__main__":
    main()
