#!/usr/bin/env bash
# Downloads the current Exam'1 question bank (published by the REF for the web and
# Android versions) into packaging/data, so that it is bundled with the packages.
# Usage: packaging/fetch_bank.sh [base-url]
set -euo pipefail

BASE_URL="${1:-https://exam1.r-e-f.org/assets/}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HERE/data"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$DEST"
for f in questions.json series.json questions.zip; do
    echo "Downloading ${BASE_URL}${f}"
    curl -fL --retry 3 --connect-timeout 20 -o "$TMP/$f" "${BASE_URL}${f}"
done

# Sanity checks before replacing the bundled copy
python3 - "$TMP/questions.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
n = len(d.get("questions", []))
if n == 0:
    sys.exit("questions.json contains no question")
print(f"questions.json: version {d.get('version')}, {n} questions")
PY
unzip -tq "$TMP/questions.zip" > /dev/null && echo "questions.zip: archive OK"

mv -f "$TMP"/questions.json "$TMP"/series.json "$TMP"/questions.zip "$DEST"/
echo "Question bank stored in $DEST"
