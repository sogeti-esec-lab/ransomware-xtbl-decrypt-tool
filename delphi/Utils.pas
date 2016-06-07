unit Utils;

interface

uses Windows, SysUtils, Classes, BTMemoryModule, DateUtils, ExtCtrls, Graphics;

const
  DRIVE_UNKNOWN = 0;
  DRIVE_NO_ROOT_DIR = 1;
  DRIVE_REMOVABLE = 2;
  DRIVE_FIXED = 3;
  DRIVE_REMOTE = 4;
  DRIVE_CDROM = 5;
  DRIVE_RAMDISK = 6;
  HOUR = 3600;
  DAY = 86400;

type
  TKey = array [0 .. 31] of byte;
  TBlock16 = array [0 .. 15] of byte;
  TRSA1024Block = array [0 .. 127] of byte;

type
  TDll = record
    Data: Pointer;
    Size: Integer;
    Module: PBTMemoryModule;
  end;

type
  TEncFile = packed record
    Magic: array [0 .. 5] of byte;
    IV: TBlock16;
    Padding: byte;
    RSA: TRSA1024Block;
    Data: TBlock16;
    TimeStamp: Int64;
  end;

procedure Antialiasing(Image: TImage; Percent: Integer);
function ReadEncFile(filename: String): TEncFile;
function BSwap(const a: longword): longword;
function GetSystemInformation: TSystemInfo;
function GetPCName: String;
function GetUserFromWindows: string;
function GetWindowsDir: string;
function GetVolumeName(DriveLetter: Char): string;
function GetDrives: TStringList;
function GetTempDir: string;
function HexToInt(HexNum: string): Integer;
function ToHex(a: array of byte; Size: Integer): String;
function isXP: Boolean;

implementation

function isXP: Boolean;
begin
  result := Win32MajorVersion < 6;
end;

procedure Antialiasing(Image: TImage; Percent: Integer);
type
  TRGBTripleArray = array [0 .. 32767] of TRGBTriple;
  PRGBTripleArray = ^TRGBTripleArray;
var
  SL, SL2: PRGBTripleArray;
  l, m, p: Integer;
  R, G, B: TColor;
  R1, R2, G1, G2, B1, B2: byte;
begin
  with Image.Canvas do
  begin
    Brush.Style := bsClear;
    Pixels[1, 1] := Pixels[1, 1];
    for l := 0 to Image.Height - 1 do
    begin
      SL := Image.Picture.Bitmap.ScanLine[l];
      for p := 1 to Image.Width - 1 do
      begin
        R1 := SL[p].rgbtRed;
        G1 := SL[p].rgbtGreen;
        B1 := SL[p].rgbtBlue;

        // Left
        if (p < 1) then
          m := Image.Width
        else
          m := p - 1;
        R2 := SL[m].rgbtRed;
        G2 := SL[m].rgbtGreen;
        B2 := SL[m].rgbtBlue;
        if (R1 <> R2) or (G1 <> G2) or (B1 <> B2) then
        begin
          R := Round(R1 + (R2 - R1) * 50 / (Percent + 50));
          G := Round(G1 + (G2 - G1) * 50 / (Percent + 50));
          B := Round(B1 + (B2 - B1) * 50 / (Percent + 50));
          SL[m].rgbtRed := R;
          SL[m].rgbtGreen := G;
          SL[m].rgbtBlue := B;
        end;

        // Right
        if (p > Image.Width - 2) then
          m := 0
        else
          m := p + 1;
        R2 := SL[m].rgbtRed;
        G2 := SL[m].rgbtGreen;
        B2 := SL[m].rgbtBlue;
        if (R1 <> R2) or (G1 <> G2) or (B1 <> B2) then
        begin
          R := Round(R1 + (R2 - R1) * 50 / (Percent + 50));
          G := Round(G1 + (G2 - G1) * 50 / (Percent + 50));
          B := Round(B1 + (B2 - B1) * 50 / (Percent + 50));
          SL[m].rgbtRed := R;
          SL[m].rgbtGreen := G;
          SL[m].rgbtBlue := B;
        end;

        if (l < 1) then
          m := Image.Height - 1
        else
          m := l - 1;
        // Over
        SL2 := Image.Picture.Bitmap.ScanLine[m];
        R2 := SL2[p].rgbtRed;
        G2 := SL2[p].rgbtGreen;
        B2 := SL2[p].rgbtBlue;
        if (R1 <> R2) or (G1 <> G2) or (B1 <> B2) then
        begin
          R := Round(R1 + (R2 - R1) * 50 / (Percent + 50));
          G := Round(G1 + (G2 - G1) * 50 / (Percent + 50));
          B := Round(B1 + (B2 - B1) * 50 / (Percent + 50));
          SL2[p].rgbtRed := R;
          SL2[p].rgbtGreen := G;
          SL2[p].rgbtBlue := B;
        end;

        if (l > Image.Height - 2) then
          m := 0
        else
          m := l + 1;
        // Under
        SL2 := Image.Picture.Bitmap.ScanLine[m];
        R2 := SL2[p].rgbtRed;
        G2 := SL2[p].rgbtGreen;
        B2 := SL2[p].rgbtBlue;
        if (R1 <> R2) or (G1 <> G2) or (B1 <> B2) then
        begin
          R := Round(R1 + (R2 - R1) * 50 / (Percent + 50));
          G := Round(G1 + (G2 - G1) * 50 / (Percent + 50));
          B := Round(B1 + (B2 - B1) * 50 / (Percent + 50));
          SL2[p].rgbtRed := R;
          SL2[p].rgbtGreen := G;
          SL2[p].rgbtBlue := B;
        end;
      end;
    end;
  end;
end;

function ReadEncFile(filename: String): TEncFile;
var
  f: File of byte;
  date: TDateTime;
begin
  AssignFile(f, filename);
  FileMode := fmOpenRead;
  Reset(f);
  BlockRead(f, result.Data, 16);
  Seek(f, filesize(f) - 151);
  BlockRead(f, result, 151);
  CloseFile(f);
  FileAge(filename, date);
  result.TimeStamp := DateTimeToUnix(date, False);
end;

function GetVolumeName(DriveLetter: Char): string;
var
  dummy: DWORD;
  buffer: array [0 .. MAX_PATH] of WideChar;
  oldmode: LongInt;
begin
  oldmode := SetErrorMode(SEM_FAILCRITICALERRORS);
  try
    GetVolumeInformation(PWideChar(DriveLetter + ':\'), buffer, SizeOf(buffer),
      nil, dummy, dummy, nil, 0);
    if (ord(buffer[0]) > 32) and (ord(buffer[0]) < 128) then
    begin
      result := '(' + StrPas(buffer) + ')';
    end
    else
    begin
      result := '';
    end;
  finally
    SetErrorMode(oldmode);
  end;
end;

function GetDrives: TStringList;
var
  MyStr: PWideChar;
  i, Length: Integer;
begin
  result := TStringList.Create;
  GetMem(MyStr, 400);
  Length := GetLogicalDriveStrings(400, MyStr);
  for i := 0 to Length - 1 do
  begin
    if (MyStr[i] >= 'A') and (MyStr[i] <= 'Z') then
      result.Add(MyStr[i]);
  end;
  FreeMem(MyStr);
end;

function BSwap(const a: longword): longword;
asm
  BSWAP EAX;
end;

function GetSystemInformation: TSystemInfo;
var
  SysInfo: TSystemInfo;
begin
  GetSystemInfo(SysInfo);
  result := SysInfo;
end;

function GetPCName: String;
var
  ComputerName: Array [0 .. 256] of Char;
  Size: DWORD;
begin
  Size := 256;
  GetComputerName(ComputerName, Size);
  result := ComputerName;
end;

function GetUserFromWindows: string;
Var
  UserName: string;
  UserNameLen: DWORD;
Begin
  UserNameLen := 255;
  SetLength(UserName, UserNameLen);
  If GetUserName(PChar(UserName), UserNameLen) Then
    result := Copy(UserName, 1, UserNameLen - 1)
  Else
    result := 'Unknown';
End;

function GetWindowsDir: string;
var
  dir: array [0 .. MAX_PATH] of Char;
begin
  GetWindowsDirectory(dir, MAX_PATH);
  result := StrPas(dir);
end;

function GetTempDir: string;
var
  tempFolder: array [0 .. MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, @tempFolder);
  result := StrPas(tempFolder);
end;

function HexToInt(HexNum: string): Integer;
begin
  result := StrToInt('$' + HexNum);
end;

function ToHex(a: array of byte; Size: Integer): String;
var
  i: Integer;
begin
  result := '';
  for i := 0 to Size - 1 do
  begin
    result := result + IntToHex(a[i], 2);
  end;
end;

end.
