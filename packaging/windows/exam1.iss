; Inno Setup script for Exam'1 (Windows x64).
; Normally run by build_windows.bat, which passes AppVersion, SourceDir and OutputDir.

#ifndef AppVersion
  ; Normally passed by build_windows.bat, from CMakeLists.txt
  #define AppVersion "dev"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\dist\Exam1"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build-win"
#endif

[Setup]
AppId={{0354B6C1-EE7D-43CF-B1C6-F5284A3F0505}
AppName=Exam'1
AppVersion={#AppVersion}
AppVerName=Exam'1 {#AppVersion}
AppPublisher=Exam'1 Community
AppPublisherURL=https://f6kgl-f5kff.fr/exam1/
AppSupportURL=https://f6kgl-f5kff.fr/exam1/
DefaultDirName={autopf}\Exam1
DefaultGroupName=Exam'1
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\exam1.exe
UninstallDisplayName=Exam'1
OutputDir={#OutputDir}
OutputBaseFilename=Exam1-{#AppVersion}-setup
SetupIconFile=exam1.ico
LicenseFile=..\..\LICENSE
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Exam'1"; Filename: "{app}\exam1.exe"
Name: "{autodesktop}\Exam'1"; Filename: "{app}\exam1.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\exam1.exe"; Description: "{cm:LaunchProgram,Exam'1}"; Flags: nowait postinstall skipifsilent
