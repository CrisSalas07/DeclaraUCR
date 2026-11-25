"""Markdown -> document next to each deliverable source: `python tool/md2docx.py entregables`.

A source with images becomes a .pdf (through Word); the rest stay .docx.
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

BLUE = RGBColor(0x00, 0x5D, 0xA4)
INLINE = re.compile(r"(\*\*[^*]+\*\*|`[^`]+`|\[[^\]]+\]\([^)]+\)|<https?://[^>]+>|\*[^*\s][^*]*\*)")


def add_inline(par, text, size=None):
    for part in INLINE.split(text):
        if not part:
            continue
        if part.startswith("**"):
            run = par.add_run(part[2:-2]); run.bold = True
        elif part.startswith("`"):
            run = par.add_run(part[1:-1]); run.font.name = "Consolas"
            if part.startswith("`[COMPLETAR") or part.startswith("`[CONFIRMAR"):
                run.font.highlight_color = 7  # yellow: still to do
                run.font.name = None
        elif part.startswith("[") and "](" in part:
            label, url = re.match(r"\[([^\]]+)\]\(([^)]+)\)", part).groups()
            run = par.add_run(label); run.font.color.rgb = BLUE; run.underline = True
            if url.startswith("http"):
                par.add_run(f" ({url})").font.size = Pt(8)
        elif part.startswith("<http"):
            run = par.add_run(part[1:-1]); run.font.color.rgb = BLUE
        elif part.startswith("*") and part.endswith("*"):
            run = par.add_run(part[1:-1]); run.italic = True
        else:
            run = par.add_run(part)
        if size:
            run.font.size = size


def shade(cell, hex_color):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear"); shd.set(qn("w:color"), "auto"); shd.set(qn("w:fill"), hex_color)
    tc_pr.append(shd)


def flush_table(doc, rows, base=Path(".")):
    rows = [r for r in rows if not re.fullmatch(r"\|?[\s:|-]+\|?", r.strip())]
    cells = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows]
    width = max(len(r) for r in cells)
    table = doc.add_table(rows=len(cells), cols=width)
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, row in enumerate(cells):
        for j in range(width):
            cell = table.cell(i, j)
            text = row[j] if j < len(row) else ""
            par = cell.paragraphs[0]
            for k, chunk in enumerate(text.split("<br>")):
                if k:
                    par = cell.add_paragraph()
                img = re.fullmatch(r"!\[[^\]]*\]\(([^)]+)\)", chunk.strip())
                if img and (base / img.group(1)).exists():
                    par.add_run().add_picture(str(base / img.group(1)), height=Cm(9))
                else:
                    add_inline(par, chunk, Pt(8.5))
            if i == 0:
                cell.paragraphs[0].paragraph_format.keep_with_next = True  # header stays with its first row
                shade(cell, "DCEBF7")
                for run in cell.paragraphs[0].runs:
                    run.bold = True
    doc.add_paragraph()


def convert(md_path: Path, out_path: Path):
    doc = Document()
    style = doc.styles["Normal"]; style.font.name = "Arial"; style.font.size = Pt(10.5)
    for s in doc.sections:
        s.left_margin = s.right_margin = Cm(2); s.top_margin = s.bottom_margin = Cm(2)
    lines = md_path.read_text(encoding="utf-8").splitlines()
    table, code, quote = [], None, []
    i = 0
    while i < len(lines):
        line = lines[i]
        if code is not None:
            if line.startswith("```"):
                p = doc.add_paragraph(); run = p.add_run("\n".join(code))
                run.font.name = "Consolas"; run.font.size = Pt(8)
                code = None
            else:
                code.append(line)
            i += 1; continue
        if line.startswith("```"):
            code = []; i += 1; continue
        if line.startswith("|"):
            table.append(line); i += 1; continue
        if table:
            flush_table(doc, table, md_path.parent); table = []
        if line.startswith(">"):
            buf = [line.lstrip("> ").strip()]
            while i + 1 < len(lines) and lines[i + 1].startswith(">"):
                i += 1; buf.append(lines[i].lstrip("> ").strip())
            add_inline(doc.add_paragraph(style="Intense Quote"), " ".join(b for b in buf if b))
            i += 1; continue
        m = re.match(r"^(#{1,4}) (.*)", line)
        img = re.match(r"^!\[([^\]]*)\]\(([^)]+)\)", line)
        if m:
            h = doc.add_heading(level=len(m.group(1)) - 0 if len(m.group(1)) > 1 else 0)
            add_inline(h, m.group(2))
        elif img:
            path = (md_path.parent / img.group(2)).resolve()
            if path.exists():
                pic = doc.add_picture(str(path), height=Cm(11))
                if pic.width > Cm(17):  # wide screenshots: fit the text width
                    pic.height = int(pic.height * Cm(17) / pic.width); pic.width = Cm(17)
                cap = doc.add_paragraph(); r = cap.add_run(img.group(1)); r.italic = True; r.font.size = Pt(8)
        elif re.match(r"^\s*[-*] ", line):
            p = doc.add_paragraph(style="List Bullet")
            add_inline(p, re.sub(r"^\s*[-*] (\[[ x]\] )?", "", line).strip())
            if "[x]" in line[:8]:
                p.runs[0].text = "✔ " + p.runs[0].text
            elif "[ ]" in line[:8]:
                p.runs[0].text = "☐ " + p.runs[0].text
        elif re.match(r"^\s*\d+\. ", line):
            p = doc.add_paragraph(style="List Number")
            add_inline(p, re.sub(r"^\s*\d+\. ", "", line))
        elif line.strip().startswith("<br>"):
            for _ in range(line.count("<br>")):
                doc.add_paragraph()
        elif line.strip() == "---":
            pass
        elif line.strip():
            # join soft-wrapped paragraph lines
            buf = [line.strip()]
            while i + 1 < len(lines) and lines[i + 1].strip() and not re.match(r"^(#|\||>|!\[|```|\s*[-*] |\s*\d+\. |---)", lines[i + 1]):
                i += 1; buf.append(lines[i].strip())
            add_inline(doc.add_paragraph(), " ".join(buf))
        i += 1
    if table:
        flush_table(doc, table, md_path.parent)
    doc.save(out_path)


def to_pdf(docx: Path, pdf: Path):
    script = (f"$w = New-Object -ComObject Word.Application; $d = $w.Documents.Open('{docx}'); "
              f"$d.SaveAs2('{pdf}', 17); $d.Close(); $w.Quit()")
    subprocess.run(["powershell", "-NoProfile", "-Command", script], check=True)


if __name__ == "__main__":
    root = Path(sys.argv[1]).resolve()
    for md in sorted(list(root.glob("0*/*.md")) + list(root.glob("0*/sesiones-usuarios/*.md"))):
        stem = "kit-sesiones-usuarios" if md.stem == "README" else md.stem
        if "![" not in md.read_text(encoding="utf-8"):
            convert(md, md.with_name(f"{stem}.docx"))
            print(f"{stem}.docx"); continue
        with tempfile.TemporaryDirectory() as tmp:
            docx = Path(tmp) / f"{stem}.docx"
            convert(md, docx)
            to_pdf(docx, md.with_name(f"{stem}.pdf"))
        print(f"{stem}.pdf")
