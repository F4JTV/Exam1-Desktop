#!/usr/bin/env bash
# Builds the Android package of Exam'1, for phones and tablets: build-android/dist/Exam1-<version>.apk,
# a signed APK to install directly or to attach to the GitHub release, for every Android ABI
# installed with Qt for Android (or those given with --abis).
#
# Requirements (Ubuntu 24.04), see "Android" in README.md:
#   - Qt 6.9 or later for Android, from the Qt online installer: in the same Qt version, the
#     "Android" component and "Desktop" (gcc 64-bit), e.g. ~/Qt/6.11.3/android_arm64_v8a and
#     ~/Qt/6.11.3/gcc_64. Qt 6.11 and 6.12 target Android 16 (API 36).
#   - Android SDK command-line tools (e.g. ~/Android/Sdk, as set up by Android Studio or by
#     Qt Creator in Preferences > Devices > Android); --setup-sdk installs the NDK
#     27.2.12479018, the android-36 platform and build-tools 36 if they are missing.
#   - JDK 21 (or 17 for Qt 6.10 and older): sudo apt install openjdk-21-jdk
#   - cmake, ninja, git and curl: sudo apt install cmake ninja-build git curl
#
# Usage: packaging/android/build_android.sh [options] [<Qt for Android directory>]
#   --fetch-bank   download the current question bank first, to bundle it in the package
#   --abis LIST    ABIs to build, e.g. "arm64-v8a;armeabi-v7a" (default: all those installed)
#   --setup-sdk    install the missing Android SDK packages with sdkmanager
#   --new-key      create the release signing key (~/.android/exam1-release.jks) and stop
#   --clean        start from an empty build directory
#
# Signing. Android installs an update only if it is signed with the same key as the installed
# application, forever: keep the keystore and its passwords safe, with a backup.
#   EXAM1_KEYSTORE           keystore file (default: ~/.android/exam1-release.jks, if it exists)
#   EXAM1_KEY_ALIAS          key alias (default: exam1)
#   EXAM1_KEYSTORE_PASSWORD  keystore password (asked if not set)
#   EXAM1_KEY_PASSWORD       key password (default: the keystore password)
# Without a keystore the APK is signed with a test key (build-android/test-key.jks):
# fine to try the application, but not to publish it.
#
# Other variables: QT_ANDROID (Qt for Android directory), QT_HOST_PATH (Qt for the desktop,
# same version), ANDROID_SDK_ROOT, ANDROID_NDK_ROOT, JAVA_HOME, EXAM1_ANDROID_VERSION_CODE.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/build-android"
DIST="$BUILD/dist"
NDK_VERSION="27.2.12479018"
PLATFORM="android-36"
BUILD_TOOLS="36.0.0"
# Prebuilt OpenSSL for Android (HTTPS), pinned to a tested revision.
OPENSSL_REPO="https://github.com/KDAB/android_openssl.git"
OPENSSL_COMMIT="b71f1470962019bd89534a2919f5925f93bc5779"
DEFAULT_KEYSTORE="$HOME/.android/exam1-release.jks"

die() { echo "Error: $*" >&2; exit 1; }
note() { echo "==> $*"; }

FETCH_BANK=0
ABIS=""
SETUP_SDK=0
NEW_KEY=0
CLEAN=0
QT_ARG=""
while [ $# -gt 0 ]; do
    case "$1" in
        --fetch-bank) FETCH_BANK=1 ;;
        --abis) shift; ABIS="${1:-}"; [ -n "$ABIS" ] || die "--abis needs a list, e.g. \"arm64-v8a;armeabi-v7a\"" ;;
        --setup-sdk) SETUP_SDK=1 ;;
        --new-key) NEW_KEY=1 ;;
        --clean) CLEAN=1 ;;
        -h|--help) sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
        -*) die "unknown option $1 (see --help)" ;;
        *) QT_ARG="$1" ;;
    esac
    shift
done

VERSION="$(sed -n 's/^ *VERSION \([0-9.]*\)$/\1/p' "$ROOT/CMakeLists.txt" | head -1)"
[ -n "$VERSION" ] || die "no VERSION found in CMakeLists.txt"

# --- Java ---------------------------------------------------------------------------------
find_java() {
    if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        return
    fi
    local candidate
    for candidate in /usr/lib/jvm/java-21-openjdk-* /usr/lib/jvm/java-17-openjdk-*; do
        if [ -x "$candidate/bin/java" ]; then
            export JAVA_HOME="$candidate"
            return
        fi
    done
    die "no JDK found: sudo apt install openjdk-21-jdk (or set JAVA_HOME)"
}
find_java
export PATH="$JAVA_HOME/bin:$PATH"
JAVA_MAJOR="$("$JAVA_HOME/bin/java" -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -1)"
[ "${JAVA_MAJOR:-0}" -ge 17 ] || die "JDK 17 or later needed, found ${JAVA_MAJOR:-?} in $JAVA_HOME"

# --- Release key ----------------------------------------------------------------------------
if [ "$NEW_KEY" = 1 ]; then
    KEYSTORE="${EXAM1_KEYSTORE:-$DEFAULT_KEYSTORE}"
    ALIAS="${EXAM1_KEY_ALIAS:-exam1}"
    [ ! -e "$KEYSTORE" ] || die "$KEYSTORE already exists: it is not replaced"
    mkdir -p "$(dirname "$KEYSTORE")"
    note "Creating the release key \"$ALIAS\" in $KEYSTORE"
    echo "keytool asks for a password (6 characters or more) and for your name: the name is written"
    echo "in the certificate, visible to anyone who inspects the APK."
    keytool -genkeypair -v -keystore "$KEYSTORE" -alias "$ALIAS" -keyalg RSA -keysize 4096 -validity 10000
    chmod 600 "$KEYSTORE"
    echo
    echo "Release key created: $KEYSTORE (alias $ALIAS)."
    echo "Keep a copy of this file and of its password in a safe place: without them, no update"
    echo "of the application can be published."
    exit 0
fi

# --- Qt ---------------------------------------------------------------------------------------
QT_ANDROID="${QT_ARG:-${QT_ANDROID:-}}"
if [ -z "$QT_ANDROID" ]; then
    # Newest Qt for Android installed by the Qt online installer.
    QT_ANDROID="$(find "$HOME/Qt" -mindepth 2 -maxdepth 2 -type d -name 'android_arm64_v8a' 2>/dev/null | sort -V | tail -1 || true)"
    [ -n "$QT_ANDROID" ] || QT_ANDROID="$(find "$HOME/Qt" -mindepth 2 -maxdepth 2 -type d -name 'android_*' 2>/dev/null | sort -V | tail -1 || true)"
fi
[ -n "$QT_ANDROID" ] || die "Qt for Android not found in ~/Qt: give its directory, e.g. $0 ~/Qt/6.11.3/android_arm64_v8a"
QT_ANDROID="$(cd "$QT_ANDROID" && pwd)"
[ -x "$QT_ANDROID/bin/qt-cmake" ] || die "$QT_ANDROID is not a Qt for Android directory (no bin/qt-cmake)"
QT_VERSION_DIR="$(basename "$(dirname "$QT_ANDROID")")"

if [ -z "${QT_HOST_PATH:-}" ]; then
    for candidate in "$QT_ANDROID/../gcc_64" "$QT_ANDROID/../linux_gcc_64"; do
        if [ -d "$candidate/lib/cmake/Qt6" ]; then
            QT_HOST_PATH="$(cd "$candidate" && pwd)"
            break
        fi
    done
fi
[ -n "${QT_HOST_PATH:-}" ] && [ -d "$QT_HOST_PATH/lib/cmake/Qt6" ] \
    || die "Qt for the desktop $QT_VERSION_DIR not found next to $QT_ANDROID: install the \"Desktop gcc 64-bit\" component of the same version (or set QT_HOST_PATH)"

# --- Android SDK --------------------------------------------------------------------------------
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
[ -d "$SDK" ] || die "Android SDK not found in $SDK (set ANDROID_SDK_ROOT)"
SDKMANAGER=""
for candidate in "$SDK"/cmdline-tools/latest/bin/sdkmanager "$SDK"/cmdline-tools/*/bin/sdkmanager; do
    if [ -x "$candidate" ]; then
        SDKMANAGER="$candidate"
        break
    fi
done
[ -n "$SDKMANAGER" ] || SDKMANAGER="$(command -v sdkmanager || true)"

MISSING=()
NDK="${ANDROID_NDK_ROOT:-$SDK/ndk/$NDK_VERSION}"
[ -d "$NDK" ] || MISSING+=("ndk;$NDK_VERSION")
[ -d "$SDK/platforms/$PLATFORM" ] || MISSING+=("platforms;$PLATFORM")
compgen -G "$SDK/build-tools/36*" > /dev/null || MISSING+=("build-tools;$BUILD_TOOLS")
[ -d "$SDK/platform-tools" ] || MISSING+=("platform-tools")
if [ ${#MISSING[@]} -gt 0 ]; then
    if [ "$SETUP_SDK" = 1 ]; then
        [ -n "$SDKMANAGER" ] || die "sdkmanager not found: install the Android SDK command-line tools in $SDK/cmdline-tools/latest"
        note "Installing ${MISSING[*]}"
        yes | "$SDKMANAGER" --sdk_root="$SDK" --licenses > /dev/null || true
        "$SDKMANAGER" --sdk_root="$SDK" --install "${MISSING[@]}"
    else
        die "missing in the Android SDK: ${MISSING[*]}. Run again with --setup-sdk to install them."
    fi
fi
NDK="${ANDROID_NDK_ROOT:-$SDK/ndk/$NDK_VERSION}"
[ -d "$NDK" ] || die "Android NDK not found in $NDK"

# --- Build tools --------------------------------------------------------------------------------
for tool_dir in "$HOME/Qt/Tools/Ninja" "$HOME/Qt/Tools/CMake/bin"; do
    if [ -d "$tool_dir" ]; then
        export PATH="$PATH:$tool_dir"
    fi
done
command -v cmake > /dev/null || die "cmake not found: sudo apt install cmake"
command -v ninja > /dev/null || die "ninja not found: sudo apt install ninja-build"

# --- OpenSSL for HTTPS (question bank updates) -------------------------------------------------
OPENSSL_DIR="$ROOT/third_party/android_openssl"
if [ ! -f "$OPENSSL_DIR/android_openssl.cmake" ]; then
    command -v git > /dev/null || die "git not found: sudo apt install git"
    note "Downloading OpenSSL for Android (KDAB android_openssl)"
    mkdir -p "$OPENSSL_DIR"
    git -C "$OPENSSL_DIR" init -q
    git -C "$OPENSSL_DIR" fetch -q --depth 1 "$OPENSSL_REPO" "$OPENSSL_COMMIT"
    git -C "$OPENSSL_DIR" checkout -q FETCH_HEAD
fi

# --- Question bank ------------------------------------------------------------------------------
if [ "$FETCH_BANK" = 1 ]; then
    bash "$ROOT/packaging/fetch_bank.sh"
fi
if [ ! -f "$ROOT/packaging/data/questions.json" ]; then
    echo "Warning: no question bank in packaging/data: the application will download it at first"
    echo "         launch. Use --fetch-bank to bundle it."
fi

# --- Signing ------------------------------------------------------------------------------------
KEYSTORE="${EXAM1_KEYSTORE:-}"
if [ -z "$KEYSTORE" ] && [ -f "$DEFAULT_KEYSTORE" ]; then
    KEYSTORE="$DEFAULT_KEYSTORE"
fi
TEST_KEY=0
if [ -n "$KEYSTORE" ]; then
    [ -f "$KEYSTORE" ] || die "keystore $KEYSTORE not found"
    ALIAS="${EXAM1_KEY_ALIAS:-exam1}"
    STORE_PASS="${EXAM1_KEYSTORE_PASSWORD:-}"
    if [ -z "$STORE_PASS" ]; then
        [ -t 0 ] || die "EXAM1_KEYSTORE_PASSWORD is not set"
        read -r -s -p "Password of $KEYSTORE: " STORE_PASS
        echo
    fi
    KEY_PASS="${EXAM1_KEY_PASSWORD:-$STORE_PASS}"
    note "Signing with the key \"$ALIAS\" of $KEYSTORE"
else
    TEST_KEY=1
    KEYSTORE="$BUILD/test-key.jks"
    ALIAS="exam1-test"
    STORE_PASS="android"
    KEY_PASS="android"
    if [ ! -f "$KEYSTORE" ]; then
        mkdir -p "$BUILD"
        keytool -genkeypair -keystore "$KEYSTORE" -alias "$ALIAS" -storepass "$STORE_PASS" -keypass "$KEY_PASS" \
                -dname "CN=Exam1 test key" -keyalg RSA -keysize 2048 -validity 10000 > /dev/null
    fi
    note "No release key (EXAM1_KEYSTORE or $DEFAULT_KEYSTORE): signing with a test key"
fi
export QT_ANDROID_KEYSTORE_PATH="$KEYSTORE"
export QT_ANDROID_KEYSTORE_ALIAS="$ALIAS"
export QT_ANDROID_KEYSTORE_STORE_PASS="$STORE_PASS"
export QT_ANDROID_KEYSTORE_KEY_PASS="$KEY_PASS"

# --- Configure and build ------------------------------------------------------------------------
if [ "$CLEAN" = 1 ] && [ -d "$BUILD" ]; then
    find "${BUILD:?}" -mindepth 1 -maxdepth 1 ! -name 'test-key.jks' -exec rm -rf {} +
fi
mkdir -p "$BUILD" "$DIST"

CMAKE_ARGS=(
    -S "$ROOT" -B "$BUILD" -G Ninja
    -DCMAKE_BUILD_TYPE=Release
    -DQT_HOST_PATH="$QT_HOST_PATH"
    -DANDROID_SDK_ROOT="$SDK"
    -DANDROID_NDK_ROOT="$NDK"
    -DQT_ANDROID_SIGN_APK=ON
    -DEXAM1_ANDROID_OPENSSL="$OPENSSL_DIR"
    -DQT_ANDROID_MULTI_ABI_FORWARD_VARS=EXAM1_ANDROID_OPENSSL
)
if [ -n "$ABIS" ]; then
    CMAKE_ARGS+=(-DQT_ANDROID_BUILD_ALL_ABIS=OFF -DQT_ANDROID_ABIS="$ABIS")
else
    CMAKE_ARGS+=(-DQT_ANDROID_BUILD_ALL_ABIS=ON)
fi
if [ -n "${EXAM1_ANDROID_VERSION_CODE:-}" ]; then
    CMAKE_ARGS+=(-DEXAM1_ANDROID_VERSION_CODE="$EXAM1_ANDROID_VERSION_CODE")
fi

note "Exam'1 $VERSION for Android with Qt $QT_VERSION_DIR ($QT_ANDROID)"
echo "    Qt host: $QT_HOST_PATH"
echo "    SDK: $SDK"
echo "    NDK: $NDK"
echo "    JDK: $JAVA_HOME"
"$QT_ANDROID/bin/qt-cmake" "${CMAKE_ARGS[@]}"

note "Building the APK"
cmake --build "$BUILD" --target apk

# Most recent signed APK made by Gradle (build/outputs of the Android build folder).
APK="$(find "$BUILD" -path '*/build/outputs/apk/*' -name '*-signed.apk' -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)"
[ -n "$APK" ] || die "no signed APK was produced (see the messages above)"

rm -f "$DIST"/Exam1-*.apk
cp "$APK" "$DIST/Exam1-$VERSION.apk"

echo
echo "Android package of Exam'1 $VERSION:"
echo "    $DIST/Exam1-$VERSION.apk ($(du -h "$DIST/Exam1-$VERSION.apk" | cut -f1))"
APKSIGNER="$(find "$SDK/build-tools" -name apksigner -type f 2>/dev/null | sort -V | tail -1 || true)"
if [ -n "$APKSIGNER" ]; then
    echo "Signing certificate:"
    "$APKSIGNER" verify --print-certs "$DIST/Exam1-$VERSION.apk" | grep -E 'SHA-256' | sed 's/^/    /' || true
fi
if [ "$TEST_KEY" = 1 ]; then
    echo
    echo "This APK is signed with a TEST key: install it to try the application, but do not publish"
    echo "it. Create the release key once with: $0 --new-key"
fi
echo
echo "Install on a phone connected by USB (developer options, USB debugging):"
echo "    adb install -r \"$DIST/Exam1-$VERSION.apk\""
