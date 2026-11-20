[Setup]
AppName=TextSpeech
AppVersion=1.0
DefaultDirName={autopf}\TextSpeech
DefaultGroupName=TextSpeech
UninstallDisplayIcon={app}\text_speech_app.exe
Compression=lzma2
SolidCompression=yes
OutputDir=C:\Users\GOOFCEE\Desktop
OutputBaseFilename=TextSpeechApp_Setup

DisableDirPage=yes
DisableProgramGroupPage=yes

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\TextSpeech"; Filename: "{app}\text_speech_app.exe"
Name: "{autodesktop}\TextSpeech"; Filename: "{app}\text_speech_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\text_speech_app.exe"; Description: "Launch TextSpeech"; Flags: nowait postinstall skipifsilent
