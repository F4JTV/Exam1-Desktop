#!/usr/bin/env python3
"""Writes the notes of the GitHub release of a version, from:
  - CHANGELOG.md: the section "## <version>" (what is new in this version);
  - packaging/release/notes.md.in: the rest of the notes, in which {{VERSION}},
    {{REPOSITORY}}, {{CHANGES}} and {{BANK}} are replaced;
  - the question bank bundled with the packages (questions.json, series.json), if any.

The version is the one of CMakeLists.txt, like everywhere else. Used by
.github/workflows/release.yml, and by hand to preview the notes:
    python3 tools/release_notes.py --bank packaging/data -o notes.md
    python3 tools/release_notes.py --check      # CHANGELOG.md has a section for the version
"""
import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MONTHS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
          "septembre", "octobre", "novembre", "décembre"]


def project_version() -> str:
    text = (ROOT / "CMakeLists.txt").read_text(encoding="utf-8")
    match = re.search(r"^\s*VERSION\s+([0-9.]+)\s*$", text, re.MULTILINE)
    if not match:
        sys.exit("No VERSION found in CMakeLists.txt")
    return match.group(1)


def changelog_section(version: str) -> str:
    """Body of "## <version>" in CHANGELOG.md, headings moved one level down."""
    lines = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8").splitlines()
    body, inside = [], False
    for line in lines:
        if line.startswith("## "):
            if inside:
                break
            inside = line[3:].split()[0:1] == [version]
            continue
        if inside:
            body.append("#" + line if line.startswith("###") else line)
    return "\n".join(body).strip()


def french_date(iso: str) -> str:
    try:
        moment = datetime.fromisoformat(iso.replace("Z", "+00:00"))
    except ValueError:
        return iso
    try:
        from zoneinfo import ZoneInfo
        moment = moment.astimezone(ZoneInfo("Europe/Paris"))
    except Exception:
        pass
    return f"{moment.day} {MONTHS[moment.month - 1]} {moment.year}"


def number(n: int) -> str:
    return f"{n:,}".replace(",", " ")


def bank_text(folder) -> str:
    questions = Path(folder) / "questions.json" if folder else None
    if not questions or not questions.is_file():
        return ("La base de questions n'est pas incluse dans les paquets : "
                "l'application la télécharge au premier lancement (environ 35 Mo).")
    data = json.loads(questions.read_text(encoding="utf-8"))
    count = len(data.get("questions", []))
    series = Path(folder) / "series.json"
    series_count = len(json.loads(series.read_text(encoding="utf-8")).get("series", [])) if series.is_file() else 0
    what = f"{number(count)} questions" + (f" et {number(series_count)} séries" if series_count else "")
    return (f"Tous les paquets contiennent la base de questions de Jean-Luc F6GPX dans sa version du "
            f"**{french_date(data.get('version', ''))}** : {what}. Elle est installée au premier lancement, "
            "sans connexion Internet ; l'application vérifie ensuite elle-même les nouvelles versions de la base.")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--version", help="default: VERSION of CMakeLists.txt")
    ap.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY", "OWNER/REPOSITORY"),
                    help="owner/name of the GitHub repository (default: GITHUB_REPOSITORY)")
    ap.add_argument("--bank", help="folder with the bundled questions.json and series.json")
    ap.add_argument("--check", action="store_true", help="only check that CHANGELOG.md has a section for the version")
    ap.add_argument("-o", "--output", type=Path)
    args = ap.parse_args()

    version = args.version or project_version()
    changes = changelog_section(version)
    if not changes:
        sys.exit(f'CHANGELOG.md has no section "## {version}": add one before releasing version {version}.')
    if args.check:
        print(f"CHANGELOG.md has a section for version {version}.")
        return

    notes = (ROOT / "packaging/release/notes.md.in").read_text(encoding="utf-8")
    for key, value in {"CHANGES": changes, "BANK": bank_text(args.bank),
                       "VERSION": version, "REPOSITORY": args.repository}.items():
        notes = notes.replace("{{" + key + "}}", value)
    left = re.findall(r"\{\{\w+\}\}", notes)
    if left:
        sys.exit(f"Unknown placeholders in notes.md.in: {', '.join(sorted(set(left)))}")
    if args.output:
        args.output.write_text(notes, encoding="utf-8")
        print(f"Release notes of version {version} written to {args.output}")
    else:
        sys.stdout.write(notes)


if __name__ == "__main__":
    main()
