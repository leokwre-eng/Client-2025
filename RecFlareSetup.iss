; RecFlare installer - GUI equivalent of download.bat.
; Always downloads the game client from the community mirror (no Steam /
; DepotDownloader path).
; Build with Inno Setup 6.1+ (https://jrsoftware.org/isinfo.php):
;   iscc RecFlareSetup.iss
; Output: Output\RecFlareSetup.exe

[Setup]
AppId={{8E1D2A7B-6C43-4F0A-9B7E-3D5F80C21A96}
AppName=RecFlare
AppVersion=2025.1
AppPublisher=RecFlare project
AppSupportURL=https://github.com/djdevin/recflare
DefaultDirName={sd}\Games\RecFlare
PrivilegesRequired=lowest
; tar.exe ships with Windows 10 1803+; the downloads and extraction depend on it
MinVersion=10.0.17134
WizardStyle=modern
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\icon.ico
DisableProgramGroupPage=yes
OutputBaseFilename=RecFlareSetup
SolidCompression=yes
UninstallDisplayName=RecFlare

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; The shortcuts must go through the .bat launchers, not Recroom_Release.exe: the
; bats start Injector.exe first and wait for it to attach 2025Patch.dll, so
; launching the exe directly would run an unpatched client. The bats ship in the
; patch zip and carry the +forcemode: argument themselves.
Name: "{autoprograms}\RecFlare (Desktop mode)"; Filename: "{app}\RecRoomScreen.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Flags: runminimized
Name: "{autoprograms}\RecFlare (VR)"; Filename: "{app}\RecRoomVR.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Flags: runminimized
Name: "{autodesktop}\RecFlare (Desktop mode)"; Filename: "{app}\RecRoomScreen.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Flags: runminimized; Tasks: desktopicon
Name: "{autodesktop}\RecFlare (VR)"; Filename: "{app}\RecRoomVR.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Flags: runminimized; Tasks: desktopicon

[UninstallDelete]
; The game files are downloaded, not installed, so Inno does not track them;
; remove the whole folder on uninstall.
Type: filesandordirs; Name: "{app}"

[Code]
const
  PatchVersion = 'v0.0.8';
  ClientMD5 = '6820e89bff41906ded7f5c066027f1d6';
  ClientURL = 'https://s3.g.megas4.com/2koayuyiwxv4groxzwdbbxg43cwustavrkvfb/recflare/2025/client.zip';
  PatchURL = 'https://github.com/recflare/patch-2025/releases/download/' + PatchVersion + '/2025Patch-' + PatchVersion + '-x64.zip';
  { Points the client at the RecFlare server; to use your own instance, fork and
    change these, then rebuild the installer (see README "Custom server"). }
  ApiHost = 'ns.recflare.net';
  PhotonHost = 'photon.recflare.net';

var
  DownloadPage: TDownloadWizardPage;
  ReuseLocalClientZip: Boolean;

function OnDownloadProgress(const Url, FileName: String; const Progress, ProgressMax: Int64): Boolean;
begin
  if Progress = ProgressMax then
    Log(Format('Downloaded %s', [FileName]));
  Result := True;
end;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing),
    SetupMessage(msgPreparingDesc), @OnDownloadProgress);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = wpReady then begin
    DownloadPage.Clear;
    ReuseLocalClientZip := False;
    { A client.zip left behind by download.bat (or a previous run) is reused
      when it matches the expected hash. }
    if FileExists(ExpandConstant('{app}\client.zip')) and
       SameText(GetMD5OfFile(ExpandConstant('{app}\client.zip')), ClientMD5) then
      ReuseLocalClientZip := True
    else
      DownloadPage.Add(ClientURL, 'client.zip', '');
    DownloadPage.Add(PatchURL, '2025Patch.zip', '');
    DownloadPage.Show;
    try
      try
        DownloadPage.Download;
        if not ReuseLocalClientZip and
           not SameText(GetMD5OfFile(ExpandConstant('{tmp}\client.zip')), ClientMD5) then begin
          SuppressibleMsgBox('The downloaded game client did not match the expected checksum. ' +
            'Please run Setup again.', mbCriticalError, MB_OK, IDOK);
          Result := False;
        end;
      except
        if DownloadPage.AbortedByUser then
          Log('Download aborted by user.')
        else
          SuppressibleMsgBox(AddPeriod(GetExceptionMessage), mbCriticalError, MB_OK, IDOK);
        Result := False;
      end;
    finally
      DownloadPage.Hide;
    end;
  end;
end;

procedure SetPreparingStatus(const Msg: String);
begin
  WizardForm.PreparingLabel.Visible := True;
  WizardForm.PreparingLabel.Caption := Msg;
  WizardForm.Refresh;
end;

function ExtractZip(const ZipPath, DestDir: String): Boolean;
var
  ResultCode: Integer;
begin
  Result := ForceDirectories(DestDir) and
    Exec(ExpandConstant('{sys}\tar.exe'), Format('-xf "%s" -C "%s"', [ZipPath, DestDir]),
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

{ Sets Key=Value in the ini shipped by the patch, replacing an existing line
  for that key or appending one, so other settings in the file are kept. }
procedure SetIniKey(var Lines: TArrayOfString; const Key, Value: String);
var
  I: Integer;
  L: String;
begin
  for I := 0 to GetArrayLength(Lines) - 1 do begin
    L := Trim(Lines[I]);
    if (Pos('=', L) > 0) and SameText(Trim(Copy(L, 1, Pos('=', L) - 1)), Key) then begin
      Lines[I] := Key + '=' + Value;
      Exit;
    end;
  end;
  SetArrayLength(Lines, GetArrayLength(Lines) + 1);
  Lines[GetArrayLength(Lines) - 1] := Key + '=' + Value;
end;

function WritePatchIni(const IniPath: String): Boolean;
var
  Lines: TArrayOfString;
begin
  if not FileExists(IniPath) or not LoadStringsFromFile(IniPath, Lines) then begin
    SetArrayLength(Lines, 1);
    Lines[0] := '[config]';
  end;
  SetIniKey(Lines, 'ApiHost', ApiHost);
  SetIniKey(Lines, 'PhotonHost', PhotonHost);
  Result := SaveStringsToFile(IniPath, Lines, False);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ClientZip: String;
begin
  Result := '';
  if not ForceDirectories(ExpandConstant('{app}')) then begin
    Result := 'Could not create the installation folder.';
    Exit;
  end;

  if ReuseLocalClientZip then
    ClientZip := ExpandConstant('{app}\client.zip')
  else
    ClientZip := ExpandConstant('{tmp}\client.zip');
  SetPreparingStatus('Extracting the game client (this can take a few minutes)...');
  if not ExtractZip(ClientZip, ExpandConstant('{app}')) then begin
    Result := 'Could not extract the game client archive.';
    Exit;
  end;

  if not SaveStringToFile(ExpandConstant('{app}\steam_appid.txt'), '480', False) then begin
    Result := 'Could not write steam_appid.txt.';
    Exit;
  end;

  SetPreparingStatus('Installing the Rec Room 2025 patch...');
  if not ExtractZip(ExpandConstant('{tmp}\2025Patch.zip'), ExpandConstant('{app}')) then begin
    Result := 'Could not extract the Rec Room 2025 patch.';
    Exit;
  end;

  if not WritePatchIni(ExpandConstant('{app}\2025patch.ini')) then begin
    Result := 'Could not write 2025patch.ini.';
    Exit;
  end;
end;
