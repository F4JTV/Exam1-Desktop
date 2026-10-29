@echo off
rem ===========================================================================
rem  Exam'1 - Windows build, deployment and Inno Setup installer.
rem
rem  Run from the "x64 Native Tools Command Prompt for VS 2022".
rem  Usage:  packaging\windows\build_windows.bat [QtDir] [--fetch-bank]
rem    QtDir         Qt kit, e.g. C:\Qt\6.8.0\msvc2022_64 (default: QTDIR variable,
rem                  else the most recent C:\Qt\6.*\msvc20*_64 found)
rem    --fetch-bank  download the current question bank before packaging
rem
rem  Output: dist\Exam1\ (portable folder) and build-win\Exam1-<version>-setup.exe
rem ===========================================================================
setlocal EnableExtensions EnableDelayedExpansion

pushd "%~dp0..\.."
set "ROOT=%CD%"
set "FETCH=0"

:args
if "%~1"=="" goto argsdone
if /I "%~1"=="--fetch-bank" (set "FETCH=1") else (set "QTDIR=%~1")
shift
goto args
:argsdone

rem --- Qt kit ------------------------------------------------------------------
if "%QTDIR%"=="" (
    for /d %%D in (C:\Qt\6.*) do (
        for /d %%M in ("%%D\msvc20*_64") do set "QTDIR=%%M"
    )
)
if not exist "%QTDIR%\bin\windeployqt.exe" (
    echo [ERREUR] Qt introuvable. Indiquez le dossier du kit, par exemple :
    echo          packaging\windows\build_windows.bat C:\Qt\6.8.0\msvc2022_64
    goto fail
)
echo Qt : %QTDIR%

where cl.exe >nul 2>nul
if errorlevel 1 (
    echo [ERREUR] Compilateur MSVC introuvable : lancez ce script depuis
    echo          "x64 Native Tools Command Prompt for VS 2022".
    goto fail
)

rem --- Version (from CMakeLists.txt) ---------------------------------------------
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "(Select-String -Path 'CMakeLists.txt' -Pattern '^\s*VERSION ([0-9.]+)').Matches[0].Groups[1].Value"`) do set "VERSION=%%V"
if "%VERSION%"=="" (
    echo [ERREUR] Version introuvable dans CMakeLists.txt.
    goto fail
)
echo Version : %VERSION%

rem --- Question bank -----------------------------------------------------------------
if "%FETCH%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\packaging\fetch_bank.ps1" || goto fail
)

rem --- Build ---------------------------------------------------------------------------
set "GEN=Ninja"
where ninja.exe >nul 2>nul || set "GEN=NMake Makefiles"
cmake -S "%ROOT%" -B "%ROOT%\build-win" -G "%GEN%" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="%QTDIR%" || goto fail
cmake --build "%ROOT%\build-win" --config Release || goto fail

rem --- Deployment ----------------------------------------------------------------------
set "DIST=%ROOT%\dist\Exam1"
if exist "%ROOT%\dist" rmdir /s /q "%ROOT%\dist"
mkdir "%DIST%" || goto fail
copy /y "%ROOT%\build-win\exam1.exe" "%DIST%\" >nul || goto fail
"%QTDIR%\bin\windeployqt.exe" --release --qmldir "%ROOT%\qml" --no-translations --no-compiler-runtime "%DIST%\exam1.exe" || goto fail

rem Visual C++ runtime next to the executable (no separate installer needed)
if defined VCToolsRedistDir (
    for /d %%C in ("%VCToolsRedistDir%x64\Microsoft.VC*.CRT") do copy /y "%%C\*.dll" "%DIST%\" >nul
) else (
    echo [ATTENTION] VCToolsRedistDir non defini : runtime Visual C++ non copie.
)

if exist "%ROOT%\packaging\data\questions.json" (
    mkdir "%DIST%\data"
    copy /y "%ROOT%\packaging\data\questions.json" "%DIST%\data\" >nul
    if exist "%ROOT%\packaging\data\series.json" copy /y "%ROOT%\packaging\data\series.json" "%DIST%\data\" >nul
    if exist "%ROOT%\packaging\data\questions.zip" copy /y "%ROOT%\packaging\data\questions.zip" "%DIST%\data\" >nul
    echo Base de questions incluse.
) else (
    echo [ATTENTION] Pas de base dans packaging\data : elle sera telechargee au premier lancement.
    echo             Relancez avec --fetch-bank pour l'inclure.
)

rem --- Installer -------------------------------------------------------------------------
set "ISCC="
for %%I in (ISCC.exe) do set "ISCC=%%~$PATH:I"
if "%ISCC%"=="" if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if "%ISCC%"=="" if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if "%ISCC%"=="" (
    echo [ATTENTION] Inno Setup 6 introuvable : seul le dossier portable dist\Exam1 a ete cree.
    goto done
)
"%ISCC%" /Q /DAppVersion=%VERSION% /DSourceDir="%DIST%" /DOutputDir="%ROOT%\build-win" "%ROOT%\packaging\windows\exam1.iss" || goto fail
echo.
echo Installateur : %ROOT%\build-win\Exam1-%VERSION%-setup.exe

:done
echo Dossier portable : %DIST%
echo   (ajoutez un fichier portable.txt a cote de exam1.exe pour une cle USB)
popd
endlocal
exit /b 0

:fail
echo.
echo *** Echec de la construction ***
popd
endlocal
exit /b 1
