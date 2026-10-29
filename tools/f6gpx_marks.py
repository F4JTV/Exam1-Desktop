#!/usr/bin/env python3
"""Builds resources/bank/marks.json from the Excel file of the question bank kept by F6GPX.

In that file, the statement of every question that needs its picture (diagram, formula,
drawing) starts with "- " (typed "'- " in Excel). The conversion to the questions.json
published by the REF drops this marker, and it also cuts one to three characters off some
statements ("- tension aux bornes" becomes "Ension aux bornes", "Un mélangeur" becomes
"Un mélangeu"). The application therefore bundles:
  - picture: questions marked "- "            -> shown with their picture
  - text:    questions without the marker       -> shown as text only
  - statements: full statement from the Excel file, for the questions whose text in
                questions.json is a truncated piece of it (only with --questions)

Run it again whenever F6GPX sends a new version of his file, then rebuild the application:
    pip install xlrd openpyxl
    python3 tools/f6gpx_marks.py Questions_v3aw.xls --questions packaging/data/questions.json
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT / "resources/bank/marks.json"
MARKER = re.compile(r"^\s*-")


def read_rows(path: Path):
    """Rows of the first sheet as lists of strings (.xls with xlrd, .xlsx with openpyxl)."""
    if path.suffix.lower() == ".xls":
        import xlrd
        sheet = xlrd.open_workbook(str(path)).sheet_by_index(0)
        for r in range(sheet.nrows):
            yield [cell_text(sheet.cell_value(r, c)) for c in range(sheet.ncols)]
    else:
        import openpyxl
        sheet = openpyxl.load_workbook(str(path), read_only=True, data_only=True).worksheets[0]
        for row in sheet.iter_rows(values_only=True):
            yield [cell_text(v) for v in row]


def cell_text(value) -> str:
    if value is None:
        return ""
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value)


def normalised(text: str) -> str:
    """Same comparison form as Statement::Marks::repair() in src/statement.cpp."""
    s = text.replace("''", "'")
    s = re.sub(r"^[\s*\-]+", "", s)
    return re.sub(r"\s+", " ", s).strip().lower()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("excel", type=Path, help="F6GPX's file (Questions_vXXX.xls or .xlsx)")
    ap.add_argument("--questions", type=Path, help="questions.json published by the REF, to find truncated statements")
    ap.add_argument("-o", "--output", type=Path, default=DEFAULT_OUT)
    args = ap.parse_args()

    rows = list(read_rows(args.excel))
    header = next((i for i, r in enumerate(rows[:10]) if any(c.strip().lower() == "question" for c in r)), None)
    if header is None:
        sys.exit("No 'Question' column found in the first rows of the sheet.")
    cols = [c.strip().lower() for c in rows[header]]
    num_col = next(i for i, c in enumerate(cols) if c.startswith("n"))
    text_col = cols.index("question")

    statements = {}
    for r in rows[header + 1:]:
        num = r[num_col].strip().strip("'") if num_col < len(r) else ""
        if num.isdigit():
            statements[int(num)] = r[text_col] if text_col < len(r) else ""
    if not statements:
        sys.exit("No question found in the Excel file.")

    picture = sorted(n for n, t in statements.items() if MARKER.match(t))
    text = sorted(n for n, t in statements.items() if not MARKER.match(t))

    repairs = {}
    if args.questions:
        published = json.loads(args.questions.read_text(encoding="utf-8"))
        for q in published.get("questions", []):
            n = int(q["num"])
            if n not in statements:
                continue
            full = re.sub(r"^\s*-\s*", "", statements[n]).strip()
            mine, theirs = normalised(full), normalised(q.get("question") or "")
            if theirs and theirs != mine and theirs in mine:
                repairs[str(n)] = full

    data = {
        "source": args.excel.name,
        "picture": picture,
        "text": text,
        "statements": dict(sorted(repairs.items(), key=lambda kv: int(kv[0]))),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    # One list per line and one statement per line: compact, and readable in a diff.
    lines = ["{"]
    lines.append(f'  "source": {json.dumps(data["source"], ensure_ascii=False)},')
    lines.append(f'  "picture": {json.dumps(picture)},')
    lines.append(f'  "text": {json.dumps(text)},')
    items = [f"    {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}" for k, v in data["statements"].items()]
    lines.append('  "statements": {' + ("\n" + ",\n".join(items) + "\n  " if items else "") + "}")
    lines.append("}")
    args.output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    json.loads(args.output.read_text(encoding="utf-8"))  # sanity check

    print(f"{args.excel.name}: {len(statements)} questions, {len(picture)} with picture, {len(text)} text only")
    if args.questions:
        print(f"{len(repairs)} statements truncated in {args.questions.name} replaced by the full text")
    print(f"Written {args.output}")


if __name__ == "__main__":
    main()
