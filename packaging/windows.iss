#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
[Setup]
AppId={{1145E0C7-560A-4531-A632-46A14F69DBE0}
AppName=Media Knowledge
AppVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\MediaKnowledge
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=MediaKnowledge-windows-x64-setup
Compression=lzma2
SolidCompression=yes
UninstallDisplayIcon={app}\media_knowledge.exe
[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{autoprograms}\Media Knowledge"; Filename: "{app}\media_knowledge.exe"
[Run]
Filename: "{app}\media_knowledge.exe"; Description: "Открыть Media Knowledge"; Flags: nowait postinstall skipifsilent
