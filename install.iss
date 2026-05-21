[Setup]
AppName=OH MEDIC
AppVersion=1.0
DefaultDirName={pf}\OH MEDIC
DefaultGroupName=OH MEDIC
OutputDir=output
OutputBaseFilename=OH_MEDIC_SETUP

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\OH MEDIC"; Filename: "{app}\medic_app.exe"
Name: "{commondesktop}\OH MEDIC"; Filename: "{app}\medic_app.exe"