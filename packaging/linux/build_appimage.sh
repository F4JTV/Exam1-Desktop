#!/usr/bin/env bash
# Builds Exam1-<version>-x86_64.AppImage: Exam'1 and the Qt libraries it uses in a single file, for
# the 64-bit Linux distributions without a .deb package of their own (Fedora, openSUSE, Arch,
# Manjaro, Linux Mint...). Nothing to install: the file is made executable, then run.
#
# Usage: packaging/linux/build_appimage.sh [--fetch-bank] [--clean] [--host [--install-deps]] [--image IMAGE]
#
#   (no option)     builds in a Debian 12 container, with podman or docker. An AppImage runs on the
#                   systems whose C library (glibc) is at least as recent as the build system's:
#                   Debian 12's (2.36) covers Debian 12 and later, Ubuntu 23.04 and later, Fedora 37
#                   and later, openSUSE Leap 15.6 and Tumbleweed, Arch, Manjaro, Linux Mint 22...
#                   The Qt of Debian 12 (6.4) goes into the AppImage.
#   --host          builds on this computer, with its own Qt 6 (6.4 or later): the AppImage then needs
#                   a glibc at least as recent as this computer's (2.39 on Ubuntu 24.04). Used inside
#                   the container and by GitHub Actions. Another Qt than the system's: set
#                   CMAKE_PREFIX_PATH to its folder and QMAKE to its qmake.
#   --install-deps  with --host, on Debian or Ubuntu: installs the build dependencies (apt).
#   --image IMAGE   another container image than Debian 12, e.g. docker.io/library/debian:13 (needs a
#                   newer glibc, bundles a newer Qt).
#   --fetch-bank    downloads the current question bank first (packaging/fetch_bank.sh), to bundle it.
#                   Without a bank in packaging/data, the application downloads it at first launch.
#   --clean         starts again from an empty build folder.
#
# Result: build-appimage/dist/Exam1-<version>-x86_64.AppImage
#
# The packaging tools are downloaded once from GitHub into build-appimage/tools, at the versions
# below, and checked against their SHA-256.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/build-appimage"
IMAGE="docker.io/library/debian:12"   # fully qualified: podman needs it
HOST=0
DEPS=0
FETCH=0
CLEAN=0
OWNER=""

LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20251107-1/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_SHA256="c20cd71e3a4e3b80c3483cef793cda3f4e990aca14014d23c544ca3ce1270b4d"
PLUGIN_QT_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/1-alpha-20250213-1/linuxdeploy-plugin-qt-x86_64.AppImage"
PLUGIN_QT_SHA256="15106be885c1c48a021198e7e1e9a48ce9d02a86dd0a1848f00bdbf3c1c92724"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage"
APPIMAGETOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"
RUNTIME_URL="https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64"
RUNTIME_SHA256="2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d"

die() { echo "Error: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --host) HOST=1 ;;
        --install-deps) DEPS=1 ;;
        --fetch-bank) FETCH=1 ;;
        --clean) CLEAN=1 ;;
        --image) shift; [ $# -gt 0 ] || die "--image needs a value"; IMAGE="$1" ;;
        --owner) shift; [ $# -gt 0 ] || die "--owner needs a value"; OWNER="$1" ;;   # internal: container
        -h|--help) sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option $1 (see --help)" ;;
    esac
    shift
done

[ "$(uname -m)" = "x86_64" ] || die "the AppImage is built for x86_64 (64-bit PC) only."
VERSION="$(sed -n 's/^ *VERSION \([0-9.]*\)$/\1/p' "$ROOT/CMakeLists.txt" | head -1)"
[ -n "$VERSION" ] || die "no VERSION found in CMakeLists.txt"

if [ "$FETCH" = 1 ]; then
    bash "$ROOT/packaging/fetch_bank.sh"
fi
if [ "$CLEAN" = 1 ]; then
    rm -rf "$OUT"
fi

# --- In a container -----------------------------------------------------------------------------
if [ "$HOST" = 0 ]; then
    ENGINE=""
    if command -v podman > /dev/null; then
        ENGINE=podman
    elif command -v docker > /dev/null; then
        ENGINE=docker
    else
        die "neither podman nor docker is installed. Install one (Ubuntu: sudo apt install podman),
or build on this computer with --host (the AppImage then needs a glibc as recent as this one's)."
    fi
    if ! "$ENGINE" info > /dev/null 2>&1; then
        die "$ENGINE does not answer. With docker, add yourself to the docker group
(sudo usermod -aG docker \$USER, then log in again), or install podman."
    fi
    # Rootless podman maps the container's root to you; docker writes as root, so the build folder
    # is given back to you at the end.
    OWNER_ARGS=()
    if [ "$ENGINE" = docker ]; then
        OWNER_ARGS=(--owner "$(id -u):$(id -g)")
    fi
    echo "Building in a $IMAGE container with $ENGINE..."
    "$ENGINE" run --rm -v "$ROOT:/src:z" -w /src -e DEBIAN_FRONTEND=noninteractive "$IMAGE" \
        bash packaging/linux/build_appimage.sh --host --install-deps "${OWNER_ARGS[@]}"
    echo
    echo "AppImage: $OUT/dist/Exam1-$VERSION-x86_64.AppImage"
    exit 0
fi

# --- On this computer ----------------------------------------------------------------------------
# In a docker container (running as root), the build folder is given back to the user at the end,
# even if the build fails.
if [ -n "$OWNER" ]; then
    trap 'chown -R "$OWNER" "$OUT" 2> /dev/null || true' EXIT
fi
if [ "$DEPS" = 1 ]; then
    command -v apt-get > /dev/null || die "--install-deps uses apt (Debian, Ubuntu); install the dependencies yourself."
    SUDO=""
    if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get update
    $SUDO apt-get install -y --no-install-recommends build-essential cmake ninja-build pkg-config \
        qt6-base-dev qt6-base-dev-tools qmake6 qt6-declarative-dev qt6-declarative-dev-tools qt6-svg-dev \
        qt6-tools-dev libgl1-mesa-dev \
        qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
        qml6-module-qtquick-templates qml6-module-qtquick-window qml6-module-qtquick-dialogs \
        qml6-module-qtqml-workerscript qml6-module-qt-labs-folderlistmodel qml6-module-qtcore \
        libqt6sql6-sqlite libqt6svg6 qt6-qpa-plugins \
        ca-certificates curl file
fi

for tool in cmake curl sha256sum; do
    command -v "$tool" > /dev/null || die "$tool is missing (try --install-deps, or the container build)."
done
if [ -z "${QMAKE:-}" ]; then
    for q in qmake6 /usr/lib/qt6/bin/qmake qmake-qt6 qmake; do
        if command -v "$q" > /dev/null; then QMAKE="$(command -v "$q")"; break; fi
    done
fi
[ -n "${QMAKE:-}" ] || die "qmake of Qt 6 not found (Debian, Ubuntu: qt6-base-dev-tools); or set QMAKE."
QT_VERSION="$("$QMAKE" -query QT_VERSION)"
case "$QT_VERSION" in
    6.*) ;;
    *) die "$QMAKE is Qt $QT_VERSION, Qt 6.4 or later is needed." ;;
esac
export QMAKE
echo "Exam'1 $VERSION, Qt $QT_VERSION ($QMAKE), glibc $(ldd --version | head -1 | sed 's/.* //')"

BUILD="$OUT/build"
APPDIR="$OUT/AppDir"
TOOLS="$OUT/tools"
DIST="$OUT/dist"
# A build folder configured elsewhere (in the container, with another Qt) is started again.
STAMP="$ROOT|$QMAKE|$QT_VERSION|$(ldd --version | head -1)"
if [ -f "$BUILD/exam1-appimage.stamp" ] && [ "$(cat "$BUILD/exam1-appimage.stamp")" != "$STAMP" ]; then
    rm -rf "$BUILD"
fi
mkdir -p "$BUILD" "$TOOLS" "$DIST"
echo "$STAMP" > "$BUILD/exam1-appimage.stamp"

GENERATOR="Unix Makefiles"
command -v ninja > /dev/null && GENERATOR="Ninja"
cmake -S "$ROOT" -B "$BUILD" -G "$GENERATOR" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "$BUILD" --parallel

rm -rf "$APPDIR"
DESTDIR="$APPDIR" cmake --install "$BUILD"
if [ ! -f "$APPDIR/usr/share/exam1/data/questions.json" ]; then
    echo "Note: no question bank in packaging/data (see --fetch-bank): the application will download it at first launch."
fi

# Downloads tool $1 from $2 into $TOOLS, unless it is already there, and checks it.
fetch_tool() {
    local name="$1" url="$2" sum="$3" file="$TOOLS/$1"
    if [ ! -f "$file" ] || ! echo "$sum  $file" | sha256sum -c --status; then
        echo "Downloading $name..."
        curl -fL --retry 3 -o "$file.part" "$url"
        echo "$sum  $file.part" | sha256sum -c --status || die "$name: unexpected SHA-256, file not used."
        mv "$file.part" "$file"
    fi
    chmod +x "$file"
}
fetch_tool linuxdeploy-x86_64.AppImage "$LINUXDEPLOY_URL" "$LINUXDEPLOY_SHA256"
fetch_tool linuxdeploy-plugin-qt-x86_64.AppImage "$PLUGIN_QT_URL" "$PLUGIN_QT_SHA256"
fetch_tool appimagetool-x86_64.AppImage "$APPIMAGETOOL_URL" "$APPIMAGETOOL_SHA256"
fetch_tool runtime-x86_64 "$RUNTIME_URL" "$RUNTIME_SHA256"

# The packaging tools are AppImages themselves: they unpack instead of needing FUSE (containers).
export APPIMAGE_EXTRACT_AND_RUN=1

# Started by AppRun before Exam'1. Only the X11 (xcb) display plugin is bundled: on a Wayland
# desktop, Exam'1 runs through XWayland. QT_QPA_PLATFORM set by the user still wins.
mkdir -p "$APPDIR/apprun-hooks"
cat > "$APPDIR/apprun-hooks/exam1-hook.sh" <<'EOF'
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
EOF

# Copies the libraries Exam'1 needs into the AppDir, with the Qt plugins and the QML modules
# imported by the qml/ files. OpenSSL stays the system's: Qt loads libssl for HTTPS at run time, and
# a bundled libcrypto would not match it.
PATH="$TOOLS:$PATH" QML_SOURCES_PATHS="$ROOT/qml" \
    "$TOOLS/linuxdeploy-x86_64.AppImage" --appdir "$APPDIR" \
        --exclude-library 'libcrypto.so*' --exclude-library 'libssl.so*' \
        --executable "$APPDIR/usr/bin/exam1" \
        --desktop-file "$APPDIR/usr/share/applications/exam1.desktop" \
        --icon-file "$APPDIR/usr/share/icons/hicolor/256x256/apps/exam1.png" \
        --plugin qt
# The Qt plugin of linuxdeploy ignores --exclude-library for the libraries it copies itself.
rm -f "$APPDIR"/usr/lib/libcrypto.so* "$APPDIR"/usr/lib/libssl.so*

for needed in usr/plugins/platforms/libqxcb.so usr/plugins/sqldrivers/libqsqlite.so usr/plugins/tls/libqopensslbackend.so \
              usr/qml/QtQuick/Controls usr/qml/QtQuick/Dialogs; do
    [ -e "$APPDIR/$needed" ] || die "$needed is missing from the AppDir."
done

APPIMAGE_FILE="$DIST/Exam1-$VERSION-x86_64.AppImage"
rm -f "$APPIMAGE_FILE"
ARCH=x86_64 VERSION="$VERSION" "$TOOLS/appimagetool-x86_64.AppImage" --no-appstream \
    --runtime-file "$TOOLS/runtime-x86_64" "$APPDIR" "$APPIMAGE_FILE"
chmod +x "$APPIMAGE_FILE"

echo
echo "Built: $APPIMAGE_FILE ($(du -h "$APPIMAGE_FILE" | cut -f1))"
echo "Needs glibc $(ldd --version | head -1 | sed 's/.* //') or later on the computer that runs it."
