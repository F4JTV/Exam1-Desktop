#!/usr/bin/env bash
# Builds Exam'1 for macOS: universal application bundle (Apple Silicon and Intel) and DMG.
# Written for the bash 3.2 shipped with macOS.
#
# Usage: packaging/macos/build_macos.sh [QtDir] [--fetch-bank]
#   QtDir         Qt kit for macOS, e.g. ~/Qt/6.8.3/macos
#                 (default: QT_ROOT_DIR, else the kit of qmake6 / qmake found in PATH)
#   --fetch-bank  download the current question bank first (packaging/fetch_bank.sh)
#
# Signing, through environment variables (both optional):
#   MACOS_SIGN_IDENTITY  "Developer ID Application: Name (TEAMID)"; default "-" (ad-hoc signature)
#   APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD
#                        with a Developer ID, notarize and staple the DMG when all three are set
#
# Output: build-mac/Exam1.app and build-mac/Exam1-<version>.dmg
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
QTDIR="${QT_ROOT_DIR:-}"
FETCH=0
for arg in "$@"; do
    case "$arg" in
        --fetch-bank) FETCH=1 ;;
        -*) echo "Unknown option: $arg" >&2; exit 1 ;;
        *) QTDIR="$arg" ;;
    esac
done
if [ -z "$QTDIR" ]; then
    for q in qmake6 qmake; do
        if command -v "$q" > /dev/null; then
            QTDIR="$("$q" -query QT_INSTALL_PREFIX)"
            break
        fi
    done
fi
if [ -z "$QTDIR" ] || [ ! -x "$QTDIR/bin/macdeployqt" ]; then
    echo "Qt for macOS not found. Pass the kit folder, for example:" >&2
    echo "  $0 ~/Qt/6.8.3/macos" >&2
    exit 1
fi
echo "Qt: $QTDIR"

VERSION="$(sed -n 's/^ *VERSION \([0-9.]*\)$/\1/p' "$ROOT/CMakeLists.txt" | head -1)"
echo "Version: $VERSION"

if [ "$FETCH" = 1 ]; then
    bash "$ROOT/packaging/fetch_bank.sh"
fi

# --- Build ------------------------------------------------------------------------------
BUILD="$ROOT/build-mac"
GENERATOR="Unix Makefiles"
if command -v ninja > /dev/null; then GENERATOR="Ninja"; fi
cmake -S "$ROOT" -B "$BUILD" -G "$GENERATOR" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH="$QTDIR" \
      -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0
cmake --build "$BUILD" --parallel

APP="$BUILD/Exam1.app"
if [ ! -d "$APP" ]; then
    echo "Application bundle not found: $APP" >&2
    exit 1
fi

# --- Question bank, installed on first launch (Updater::findSeedDir) -----------------------
rm -rf "$APP/Contents/Resources/data"
if [ -f "$ROOT/packaging/data/questions.json" ]; then
    mkdir -p "$APP/Contents/Resources/data"
    for f in questions.json series.json questions.zip; do
        if [ -f "$ROOT/packaging/data/$f" ]; then
            cp "$ROOT/packaging/data/$f" "$APP/Contents/Resources/data/"
        fi
    done
    echo "Question bank bundled."
else
    echo "WARNING: no question bank in packaging/data. The application will download it on first launch."
    echo "         Run this script with --fetch-bank to bundle it."
fi

# --- Qt deployment ------------------------------------------------------------------------
"$QTDIR/bin/macdeployqt" "$APP" -qmldir="$ROOT/qml" -always-overwrite
# Only the SQLite driver is used; the others need client libraries that a Mac does not have.
if [ -d "$APP/Contents/PlugIns/sqldrivers" ]; then
    find "$APP/Contents/PlugIns/sqldrivers" -type f ! -name 'libqsqlite.dylib' -delete
fi

# --- Signature ------------------------------------------------------------------------------
# Apple Silicon refuses to run unsigned code: without a Developer ID, sign ad hoc ("-").
IDENTITY="${MACOS_SIGN_IDENTITY:--}"
if [ "$IDENTITY" = "-" ]; then
    codesign --force --deep --sign - "$APP"
else
    codesign --force --deep --options runtime --timestamp \
             --entitlements "$ROOT/packaging/macos/exam1.entitlements" \
             --sign "$IDENTITY" "$APP"
fi
codesign --verify --deep --strict "$APP"
lipo -info "$APP/Contents/MacOS/Exam1"

# --- Disk image -------------------------------------------------------------------------------
DMG="$BUILD/Exam1-$VERSION.dmg"
STAGE="$BUILD/dmg"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/Exam1.app"
ln -s /Applications "$STAGE/Applications"
# hdiutil sometimes fails with "Resource busy" on build machines: retry a few times.
for attempt in 1 2 3 4 5; do
    if hdiutil create -volname "Exam'1 $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG"; then
        break
    fi
    if [ "$attempt" = 5 ]; then
        echo "hdiutil failed" >&2
        exit 1
    fi
    sleep $((attempt * 5))
done
rm -rf "$STAGE"

if [ "$IDENTITY" != "-" ]; then
    codesign --force --timestamp --sign "$IDENTITY" "$DMG"
    if [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ] && [ -n "${APPLE_APP_PASSWORD:-}" ]; then
        xcrun notarytool submit "$DMG" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" \
                                       --password "$APPLE_APP_PASSWORD" --wait
        xcrun stapler staple "$DMG"
    fi
fi

echo
echo "Application: $APP"
echo "Disk image:  $DMG"
