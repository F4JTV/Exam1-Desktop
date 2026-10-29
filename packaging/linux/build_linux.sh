#!/usr/bin/env bash
# Builds Exam'1 with the Qt 6 of the distribution: Ubuntu 24.04 / 26.04, Debian 12 / 13.
# Usage: packaging/linux/build_linux.sh [--install-deps] [--debug]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_TYPE=Release
# sudo is not needed (nor installed) when running as root, e.g. in a container.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
for arg in "$@"; do
    case "$arg" in
        --install-deps)
            export DEBIAN_FRONTEND=noninteractive
            $SUDO apt-get update
            $SUDO apt-get install -y build-essential cmake ninja-build pkg-config \
                qt6-base-dev qt6-declarative-dev qt6-svg-dev qt6-tools-dev libgl1-mesa-dev \
                qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
                qml6-module-qtquick-templates qml6-module-qtquick-window qml6-module-qtquick-dialogs \
                qml6-module-qtqml-workerscript qml6-module-qt-labs-folderlistmodel qml6-module-qtcore \
                libqt6sql6-sqlite qt6-qpa-plugins dpkg-dev
            ;;
        --debug) BUILD_TYPE=Debug ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

GENERATOR="Unix Makefiles"
command -v ninja > /dev/null && GENERATOR="Ninja"

cmake -S "$ROOT" -B "$ROOT/build" -G "$GENERATOR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "$ROOT/build" --parallel

echo
echo "Built: $ROOT/build/exam1"
echo "Run it with: $ROOT/build/exam1"
