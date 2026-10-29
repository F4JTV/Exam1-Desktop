#!/usr/bin/env bash
# Creates the Debian package for the distribution it runs on (Ubuntu 24.04 / 26.04, Debian 12 / 13):
#   build/exam1_<version>_<distribution>_<arch>.deb, e.g. exam1_4.0.2_ubuntu24.04_amd64.deb
# Build it on the distribution it is meant for: the dependencies are those of its Qt packages.
# The question bank in packaging/data (see packaging/fetch_bank.sh) is included when present.
# Usage: packaging/linux/make_deb.sh [--fetch-bank]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ "${1:-}" == "--fetch-bank" ]]; then
    bash "$ROOT/packaging/fetch_bank.sh"
fi

VERSION="$(sed -n 's/^ *VERSION \([0-9.]*\)$/\1/p' "$ROOT/CMakeLists.txt" | head -1)"
ARCH="$(dpkg --print-architecture)"
# Distribution tag in the file name ("ubuntu24.04", "debian12"...): one package per distribution.
# shellcheck source=/dev/null
DISTRO="$(. /etc/os-release && echo "${ID}${VERSION_ID}")"
STAGE="$ROOT/build/deb/exam1_${VERSION}_${DISTRO}_${ARCH}"

[[ -x "$ROOT/build/exam1" ]] || bash "$ROOT/packaging/linux/build_linux.sh"
cmake --build "$ROOT/build" --parallel

rm -rf "$STAGE"
DESTDIR="$STAGE" cmake --install "$ROOT/build" --prefix /usr
strip --strip-unneeded "$STAGE/usr/bin/exam1" || true

if [[ -f "$ROOT/packaging/data/questions.json" ]]; then
    BANK_JSON="$ROOT/packaging/data/questions.json"
    echo "Bundling question bank: version $(grep -o '"version":"[^"]*"' "$BANK_JSON" | head -1 | cut -d'"' -f4)," \
         "$(grep -o '"question":' "$BANK_JSON" | wc -l) questions"
else
    echo "WARNING: no question bank in packaging/data. The application will download it on first launch."
    echo "         Run packaging/fetch_bank.sh (or this script with --fetch-bank) to bundle it."
fi

# Shared library dependencies, computed by dpkg-shlibdeps when available.
SHLIBS=""
if command -v dpkg-shlibdeps > /dev/null; then
    TMPD="$(mktemp -d)"
    mkdir -p "$TMPD/debian"
    printf 'Source: exam1\n\nPackage: exam1\nArchitecture: any\n' > "$TMPD/debian/control"
    SHLIBS="$( (cd "$TMPD" && dpkg-shlibdeps -O --ignore-missing-info "$STAGE/usr/bin/exam1" 2>/dev/null | sed -n 's/^shlibs:Depends=//p') || true)"
    rm -rf "$TMPD"
fi
if [[ -z "$SHLIBS" ]]; then
    SHLIBS="libqt6core6t64 (>= 6.4), libqt6gui6t64 (>= 6.4), libqt6network6t64 (>= 6.4), libqt6sql6t64 (>= 6.4), libqt6qml6 (>= 6.4), libqt6quick6 (>= 6.4), libqt6quickcontrols2-6 (>= 6.4), libqt6svg6 (>= 6.4)"
fi
QML_DEPS="libqt6sql6-sqlite, qt6-qpa-plugins, qml6-module-qtqml, qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-templates, qml6-module-qtquick-window, qml6-module-qtquick-dialogs, qml6-module-qtqml-workerscript, qml6-module-qt-labs-folderlistmodel, qml6-module-qtcore"
SIZE_KB="$(du -sk "$STAGE/usr" | cut -f1)"

mkdir -p "$STAGE/DEBIAN"
cat > "$STAGE/DEBIAN/control" <<CONTROL
Package: exam1
Version: ${VERSION}
Section: hamradio
Priority: optional
Architecture: ${ARCH}
Installed-Size: ${SIZE_KB}
Depends: ${SHLIBS}, ${QML_DEPS}
Maintainer: Exam'1 Community <noreply@exam1.invalid>
Homepage: https://f6kgl-f5kff.fr/exam1/
Description: French amateur radio licence exam trainer
 Mock exams for the French amateur radio operator certificate (ANFR),
 with the question bank maintained by F6GPX. The exam screen reproduces
 the ANFR examination interface: all questions in one list, check boxes,
 pinned questions and a single "finalise" step.
 .
 Also offers training by theme, fixed series for radio clubs, review of
 mistakes, a searchable question bank and quarterly online updates.
CONTROL

cat > "$STAGE/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e
if command -v update-desktop-database > /dev/null 2>&1; then update-desktop-database -q /usr/share/applications || true; fi
if command -v gtk-update-icon-cache > /dev/null 2>&1; then gtk-update-icon-cache -q /usr/share/icons/hicolor || true; fi
exit 0
POSTINST
chmod 755 "$STAGE/DEBIAN/postinst"

find "$STAGE" -type d -exec chmod 755 {} +
OUT="$ROOT/build/exam1_${VERSION}_${DISTRO}_${ARCH}.deb"
dpkg-deb --build --root-owner-group "$STAGE" "$OUT"
echo
echo "Package: $OUT"
echo "Install with: sudo apt install $OUT"
