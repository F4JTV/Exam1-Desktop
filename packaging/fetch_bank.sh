#!/usr/bin/env bash
# Downloads the current Exam'1 question bank (published by the REF for the web and
# Android versions) into packaging/data, so that it is bundled with the packages.
# Usage: packaging/fetch_bank.sh [base-url]
set -euo pipefail

BASE_URL="${1:-https://exam1.r-e-f.org/assets/}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HERE/data"
TMP="$(mktemp -d)"
OK=0
cleanup() {
    if [ "$OK" = 1 ]; then
        rm -rf "$TMP"
    else
        echo "Downloaded files kept for inspection in $TMP" >&2
    fi
}
trap cleanup EXIT

# Downloads $1 into $2. A connection cut short (curl error 18) or stalled for a minute
# (error 28) is resumed where it stopped with an HTTP Range request (-C -), up to 5 times.
fetch() {
    local url="$1" out="$2" attempt rc code
    rm -f "$out"
    for attempt in 1 2 3 4 5; do
        rc=0
        code="$(curl -fL -C - --connect-timeout 20 --speed-limit 1024 --speed-time 60 \
                     -w '%{http_code}' -o "$out" "$url")" || rc=$?
        [ "$rc" -eq 0 ] && return 0
        # Client errors (404, 403...) will not go away by retrying.
        if [ "$rc" -eq 22 ] && [[ "$code" =~ ^4 ]] && [ "$code" != 408 ] && [ "$code" != 416 ] && [ "$code" != 429 ]; then
            echo "$url: HTTP $code" >&2
            return 1
        fi
        # Server unable to resume (33), or bad range (416): start again from the beginning.
        if [ "$rc" -eq 33 ] || [ "$code" = 416 ]; then
            rm -f "$out"
        fi
        local size=0
        [ -f "$out" ] && size="$(stat -c %s "$out")"
        echo "  attempt $attempt/5 failed (curl error $rc), $size bytes received" >&2
        [ "$attempt" -lt 5 ] && sleep $((2 * attempt))
    done
    echo "$url: download incomplete after 5 attempts" >&2
    return 1
}

mkdir -p "$DEST"
for f in questions.json series.json questions.zip; do
    echo "Downloading ${BASE_URL}${f}"
    fetch "${BASE_URL}${f}" "$TMP/$f"
    echo "  $(stat -c %s "$TMP/$f") bytes"
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
if ! unzip -tq "$TMP/questions.zip" > /dev/null 2>&1; then
    echo "questions.zip is not a valid ZIP archive ($(stat -c %s "$TMP/questions.zip") bytes, starts with" \
         "$(head -c 16 "$TMP/questions.zip" | od -An -tx1 | tr -s ' ' | sed 's/^ //'); a ZIP file starts with 50 4b 03 04)" >&2
    exit 1
fi
echo "questions.zip: archive OK"

mv -f "$TMP"/questions.json "$TMP"/series.json "$TMP"/questions.zip "$DEST"/
echo "Question bank stored in $DEST"
OK=1
