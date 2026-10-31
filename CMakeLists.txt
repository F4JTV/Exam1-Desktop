cmake_minimum_required(VERSION 3.21)

# The version is set here only: the application, the Windows, macOS and Linux packages,
# the GitHub release (tag v<version>) and its notes (CHANGELOG.md) all follow it.
project(Exam1
    VERSION 4.1.0
    DESCRIPTION "French amateur radio licence exam trainer"
    HOMEPAGE_URL "https://f6kgl-f5kff.fr/exam1/"
    LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt 6.4 is the version shipped by Ubuntu 24.04; newer Qt 6 releases work as well.
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Sql Network Svg)
qt_standard_project_setup()

if(ANDROID AND Qt6_VERSION VERSION_LESS 6.9)
    # Android 15 and later draw the application under the system bars: Qt 6.9 gives their size.
    message(FATAL_ERROR "The Android package needs Qt 6.9 or later (found Qt ${Qt6_VERSION}).")
endif()

# --- miniz (MIT) : ZIP reading for the image archive ------------------------------------
add_library(miniz STATIC third_party/miniz/miniz.c)
target_include_directories(miniz PUBLIC third_party/miniz)
target_compile_definitions(miniz PUBLIC MINIZ_NO_STDIO MINIZ_NO_TIME MINIZ_NO_ARCHIVE_WRITING_APIS)
set_target_properties(miniz PROPERTIES POSITION_INDEPENDENT_CODE ON)
if(MSVC)
    target_compile_options(miniz PRIVATE /W0)
else()
    target_compile_options(miniz PRIVATE -w)
endif()

# --- application ---------------------------------------------------------------------
qt_add_executable(exam1 WIN32 MACOSX_BUNDLE
    src/main.cpp
    src/appinfo.cpp src/appinfo.h
    src/appsettings.cpp src/appsettings.h
    src/appupdate.cpp src/appupdate.h
    src/bankimporter.cpp src/bankimporter.h
    src/bankstore.cpp src/bankstore.h
    src/browsermodel.cpp src/browsermodel.h
    src/examsession.cpp src/examsession.h
    src/iconprovider.cpp src/iconprovider.h
    src/question.h
    src/statement.cpp src/statement.h
    src/themes.cpp src/themes.h
    src/updater.cpp src/updater.h
    src/userstore.cpp src/userstore.h
)

if(WIN32)
    # Version information of exam1.exe, taken from project(VERSION) above.
    set(EXAM1_ICO "${CMAKE_CURRENT_SOURCE_DIR}/packaging/windows/exam1.ico")
    configure_file(packaging/windows/exam1.rc.in "${CMAKE_CURRENT_BINARY_DIR}/exam1.rc" @ONLY)
    target_sources(exam1 PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/exam1.rc")
endif()

if(APPLE)
    # Application bundle Exam1.app (see packaging/macos/build_macos.sh).
    set(EXAM1_ICNS packaging/macos/exam1.icns)
    target_sources(exam1 PRIVATE ${EXAM1_ICNS})
    set_source_files_properties(${EXAM1_ICNS} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    set_target_properties(exam1 PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/packaging/macos/Info.plist.in"
        MACOSX_BUNDLE_GUI_IDENTIFIER org.exam1.Exam1
        MACOSX_BUNDLE_BUNDLE_NAME "Exam'1"
        MACOSX_BUNDLE_ICON_FILE exam1.icns
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
        MACOSX_BUNDLE_COPYRIGHT "GNU GPL v3")
endif()

# GitHub repository whose releases announce new versions of the application (src/appupdate.cpp).
set(EXAM1_RELEASES_REPO "F4JTV/Exam1-Desktop" CACHE STRING "GitHub repository (owner/name) of the releases")
target_compile_definitions(exam1 PRIVATE EXAM1_VERSION="${PROJECT_VERSION}" EXAM1_RELEASES_REPO="${EXAM1_RELEASES_REPO}")
if(MSVC)
    # Sources contain French text in UTF-8.
    target_compile_options(exam1 PRIVATE /utf-8)
endif()

# Byte-code only: the QML-to-C++ compiler of Qt 6.4 (Ubuntu 24.04) miscompiles some
# property lookups on items returned by Repeater.itemAt().
set_target_properties(exam1 PROPERTIES QT_QMLCACHEGEN_ARGUMENTS "--only-bytecode")

set_source_files_properties(qml/Style.qml qml/Nav.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(exam1
    URI Exam1App
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        qml/Main.qml
        qml/Style.qml
        qml/Nav.qml
        qml/components/ActionButton.qml
        qml/components/AnswerOption.qml
        qml/components/CheckRow.qml
        qml/components/EvalCheck.qml
        qml/components/EvalQuestion.qml
        qml/components/ConfirmDialog.qml
        qml/components/Icon.qml
        qml/components/NavRail.qml
        qml/components/NoteBar.qml
        qml/components/PageHeader.qml
        qml/components/QuestionSheet.qml
        qml/components/ScoreBadge.qml
        qml/components/Section.qml
        qml/components/SegmentedChoice.qml
        qml/components/Spinner.qml
        qml/components/TextField2.qml
        qml/components/TopBar.qml
        qml/pages/AboutPage.qml
        qml/pages/BrowserPage.qml
        qml/pages/CandidatesPage.qml
        qml/pages/CorrectionPage.qml
        qml/pages/ExamPage.qml
        qml/pages/FirstRunPage.qml
        qml/pages/HistoryPage.qml
        qml/pages/HomePage.qml
        qml/pages/ResultPage.qml
        qml/pages/ReviewPage.qml
        qml/pages/SeriesPage.qml
        qml/pages/SettingsPage.qml
        qml/pages/TrainingPage.qml
        qml/pages/UpdatePage.qml
    RESOURCES
        resources/fonts/AtkinsonHyperlegible-Regular.ttf
        resources/fonts/AtkinsonHyperlegible-Bold.ttf
        resources/fonts/AtkinsonHyperlegible-Italic.ttf
        resources/fonts/AtkinsonHyperlegible-BoldItalic.ttf
        resources/icons/exam1.png
        resources/icons/pin.svg
        resources/icons/pin-filled.svg
        resources/icons/clock.svg
        resources/icons/home.svg
        resources/icons/target.svg
        resources/icons/layers.svg
        resources/icons/bookmark.svg
        resources/icons/bookmark-filled.svg
        resources/icons/search.svg
        resources/icons/chart.svg
        resources/icons/users.svg
        resources/icons/refresh.svg
        resources/icons/settings.svg
        resources/icons/info.svg
        resources/icons/check.svg
        resources/icons/cross.svg
        resources/icons/book.svg
        resources/icons/chevron-left.svg
        resources/icons/chevron-right.svg
        resources/icons/flag.svg
        resources/icons/eye.svg
        resources/icons/trash.svg
        resources/icons/edit.svg
        resources/icons/folder.svg
        resources/icons/download.svg
        resources/icons/menu.svg
        resources/icons/chevrons-down.svg
        resources/icons/accessibility.svg
        resources/icons/caret-down.svg
)

# F6GPX's markers: which questions need their picture (built by tools/f6gpx_marks.py).
qt_add_resources(exam1 "bank_marks"
    PREFIX "/"
    FILES resources/bank/marks.json)

target_link_libraries(exam1 PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::Sql Qt6::Network Qt6::Svg
    miniz)

# exam1 / exam1.exe on Linux and Windows; Exam1.app on macOS.
if(APPLE)
    set_target_properties(exam1 PROPERTIES OUTPUT_NAME Exam1)
else()
    set_target_properties(exam1 PROPERTIES OUTPUT_NAME exam1)
endif()

# --- Android (see packaging/android/build_android.sh) ---------------------------------
if(ANDROID)
    # Android installs an update only over an older version: the version number grows with each
    # release, 4.1.0 gives 40100. A package rebuilt for the same version can be given a higher
    # one with -DEXAM1_ANDROID_VERSION_CODE=40101 (and the next release must then go above it).
    if(NOT EXAM1_ANDROID_VERSION_CODE)
        math(EXPR EXAM1_ANDROID_VERSION_CODE
             "${PROJECT_VERSION_MAJOR} * 10000 + ${PROJECT_VERSION_MINOR} * 100 + ${PROJECT_VERSION_PATCH}")
    endif()

    # Files of the package: launcher icon and name (packaging/android/res), and the question bank
    # of packaging/data (filled by packaging/fetch_bank.sh) as assets, installed at first launch.
    set(EXAM1_ANDROID_PACKAGE_DIR "${CMAKE_CURRENT_BINARY_DIR}/android-package")
    if(NOT QT_IS_ANDROID_MULTI_ABI_EXTERNAL_PROJECT)
        file(REMOVE_RECURSE "${EXAM1_ANDROID_PACKAGE_DIR}")
        file(COPY packaging/android/res DESTINATION "${EXAM1_ANDROID_PACKAGE_DIR}")
        set(EXAM1_BANK_FILES questions.json series.json questions.zip)
        foreach(bank_file IN LISTS EXAM1_BANK_FILES)
            if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/packaging/data/${bank_file}")
                file(COPY "packaging/data/${bank_file}" DESTINATION "${EXAM1_ANDROID_PACKAGE_DIR}/assets/data")
            endif()
        endforeach()
        if(NOT EXISTS "${EXAM1_ANDROID_PACKAGE_DIR}/assets/data/questions.json")
            message(WARNING "No question bank in packaging/data: the application will download it at first launch "
                            "(run packaging/fetch_bank.sh to bundle it).")
        endif()
    endif()

    # Application ID: it cannot change once the application is published (another ID is another
    # application), and updates must come with the same ID and the same signing key.
    set(EXAM1_ANDROID_PACKAGE_NAME "io.github.f4jtv.exam1" CACHE STRING "Android application ID")

    set_target_properties(exam1 PROPERTIES
        QT_ANDROID_PACKAGE_NAME "${EXAM1_ANDROID_PACKAGE_NAME}"
        QT_ANDROID_APP_NAME "@string/app_name"
        QT_ANDROID_APP_ICON "@mipmap/ic_launcher"
        QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}"
        QT_ANDROID_VERSION_CODE "${EXAM1_ANDROID_VERSION_CODE}"
        QT_ANDROID_MIN_SDK_VERSION 28      # Android 9, the oldest supported by Qt 6.9 and later
        QT_ANDROID_TARGET_SDK_VERSION 36   # Android 16
        QT_ANDROID_PACKAGE_SOURCE_DIR "${EXAM1_ANDROID_PACKAGE_DIR}")

    # HTTPS (question bank updates from the REF server) needs OpenSSL, which Android does not provide
    # to applications: prebuilt libraries from https://github.com/KDAB/android_openssl.
    set(EXAM1_ANDROID_OPENSSL "${CMAKE_CURRENT_SOURCE_DIR}/third_party/android_openssl" CACHE PATH
        "Clone of https://github.com/KDAB/android_openssl")
    if(EXISTS "${EXAM1_ANDROID_OPENSSL}/android_openssl.cmake")
        include("${EXAM1_ANDROID_OPENSSL}/android_openssl.cmake")
        add_android_openssl_libraries(exam1)
    else()
        message(WARNING "OpenSSL for Android not found in ${EXAM1_ANDROID_OPENSSL}: "
                        "question bank updates over HTTPS will not work.")
    endif()
endif()

if(NOT ANDROID)
    include(GNUInstallDirs)
    install(TARGETS exam1
        BUNDLE DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()
if(UNIX AND NOT APPLE AND NOT ANDROID)
    install(FILES packaging/linux/exam1.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
    install(FILES resources/icons/exam1.png DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/256x256/apps)
    install(FILES packaging/linux/exam1.metainfo.xml DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo)
    # Question bank bundled with the package (filled by packaging/fetch_bank.sh), installed if present.
    install(DIRECTORY packaging/data/ DESTINATION ${CMAKE_INSTALL_DATADIR}/exam1/data
            FILES_MATCHING PATTERN "*.json" PATTERN "*.zip")
endif()
