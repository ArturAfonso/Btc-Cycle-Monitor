[Setup]
; Informações básicas do aplicativo
AppName=BTC Cycle Monitor
AppVersion=1.0.0
AppPublisher=artafonso
AppPublisherURL=
AppSupportURL=
AppUpdatesURL=
DefaultDirName={autopf}\BTC Cycle Monitor
DefaultGroupName=BTC Cycle Monitor
AllowNoIcons=yes
LicenseFile=
InfoBeforeFile=
InfoAfterFile=
OutputDir=installer_output
OutputBaseFilename=btc_cycle_monitor_setup
SetupIconFile=assets\icons\favicon-circular.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
; Arquivos principais da aplicação
Source: "build\windows\x64\runner\Release\btc_cycle_monitor.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; NOTA: Não use "Flags: ignoreversion" em arquivos do sistema

[Icons]
Name: "{group}\BTC Cycle Monitor"; Filename: "{app}\btc_cycle_monitor.exe"
Name: "{group}\{cm:UninstallProgram,BTC Cycle Monitor}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\BTC Cycle Monitor"; Filename: "{app}\btc_cycle_monitor.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\BTC Cycle Monitor"; Filename: "{app}\btc_cycle_monitor.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\btc_cycle_monitor.exe"; Description: "{cm:LaunchProgram,BTC Cycle Monitor}"; Flags: nowait postinstall skipifsilent

[CustomMessages]
brazilianportuguese.LaunchProgram=Executar %1
english.LaunchProgram=Launch %1