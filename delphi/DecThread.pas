unit DecThread;

interface

uses Vcl.Forms, System.Classes, Windows, Utils, SysUtils;

type
  TDecThread = class(TThread)
  private
    FFixed: Boolean;
    FRemote: Boolean;
    FRemovable: Boolean;
    FDeleteAfterDecryption: Boolean;
    FStartTime: Cardinal;
    FFilename: String;
    FEncrypted: Integer;
    FDecrypted: Integer;
    FKey: TKey;
    FRSA: TRSA1024Block;
  protected
    procedure Execute; override;
    procedure DecryptDir(dirname: String);
  public
    constructor Create(Key: TKey; RSA: TRSA1024Block; fixed: Boolean;
      remote: Boolean; removable: Boolean; delete: Boolean);
    destructor Destroy; override;
    function GetCurrentFilename: String;
    function GetEncrypted: Integer;
    function GetDecrypted: Integer;
    function GetElapsedTime: Integer;
  end;

implementation

uses Main;

constructor TDecThread.Create(Key: TKey; RSA: TRSA1024Block; fixed: Boolean;
  remote: Boolean; removable: Boolean; delete: Boolean);
begin
  inherited Create(True);
  FFixed := fixed;
  FDeleteAfterDecryption := delete;
  FRemote := remote;
  FRemovable := removable;
  FreeOnTerminate := True;
  FFilename := '';
  FEncrypted := 0;
  FDecrypted := 0;
  FKey := Key;
  FRSA := RSA;
end;

destructor TDecThread.Destroy;
begin
  inherited;
end;

function TDecThread.GetCurrentFilename: String;
begin
  Result := FFilename;
end;

function TDecThread.GetEncrypted: Integer;
begin
  Result := FEncrypted;
end;

function TDecThread.GetDecrypted: Integer;
begin
  Result := FDecrypted;
end;

function TDecThread.GetElapsedTime: Integer;
begin
  Result := Trunc((GetTickCount() - FStartTime) / 1000);
end;

procedure TDecThread.DecryptDir(dirname: String);
var
  SR: TWin32FindData;
  Size: Int64;
  ok: Integer;
  h: THandle;
  f: File;
begin
  h := FindFirstFile(PWideChar(dirname + INFECTED_FILE_MASK), SR);
  if h <> INVALID_HANDLE_VALUE then
  begin
    repeat
      if ((SR.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0) then
      begin
        Inc(FEncrypted);
        FFilename := string(SR.cFileName);
        Size := Int64(SR.nFileSizeHigh) shl 32;
        Size := Size + SR.nFileSizeLow;
        if Size > 150 then
        begin
          ok := MainForm.FDecrypt(PWideChar(WideString(dirname + FFilename)),
            PAnsiChar(Addr(FKey[0])), PAnsiChar(Addr(FRSA[0])));
        end
        else
        begin
          AssignFile(f, Copy(dirname + FFilename, 1,
            Length(dirname + FFilename) - 23));
          Rewrite(f);
          CloseFile(f);
          ok := 0;
        end;
        case ok of
          0:
            begin
              MainForm.Log('Decrypting ' + dirname + FFilename + ' : OK');
              if FDeleteAfterDecryption then
                DeleteFile(dirname + FFilename);
              Inc(FDecrypted);
            end;
          1:
            MainForm.Log('Decrypting ' + dirname + FFilename + ' : Wrong key');
          2:
            MainForm.Log('Decrypting ' + dirname + FFilename +
              ' : Unable to open file');
        else
          MainForm.Log('Decrypting ' + dirname + FFilename +
            ' : Unknown error');
        end;
      end;
    until FindNextFile(h, SR) = False;
    Windows.FindClose(h);
  end;
  h := FindFirstFile(PWideChar(dirname + '*'), SR);
  if h <> INVALID_HANDLE_VALUE then
  begin
    repeat
      FFilename := String(SR.cFileName);
      if ((SR.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0) and
        (FFilename <> '.') and (FFilename <> '..') then
      begin
        DecryptDir(IncludeTrailingPathDelimiter(dirname + FFilename));
      end;
    until FindNextFile(h, SR) = False;
    Windows.FindClose(h);
  end;
end;

procedure TDecThread.Execute;
var
  drives: TStringList;
  i: Integer;
  driveType: Cardinal;
begin
  FStartTime := GetTickCount;
  drives := GetDrives;
  for i := 0 to drives.Count - 1 do
  begin
    driveType := GetDriveType(PChar(drives.Strings[i] + ':\'));
    if (driveType = DRIVE_FIXED) and FFixed then
      MainForm.Log('Scanning fixed drive : ' + drives[i] + ':\' +
        GetVolumeName(drives[i][1]))
    else if (driveType = DRIVE_REMOTE) and FRemote then
      MainForm.Log('Scanning remote drive : ' + drives[i] + ':\' +
        GetVolumeName(drives[i][1]))
    else if (driveType = DRIVE_REMOVABLE) and FRemovable then
      MainForm.Log('Scanning removable drive : ' + drives[i] + ':\' +
        GetVolumeName(drives[i][1]))
    else
      Continue;
    DecryptDir(drives[i] + ':\');
  end;
end;

end.
