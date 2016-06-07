unit BFThread;

interface

uses Vcl.Forms, System.Classes, Windows, Utils, SysUtils;

type
  TBFThread = class(TThread)
  private
    Fkey: TKey;
    FData: TBlock16;
    FIV: TBlock16;
    FOrigHeader: Int32;
    FStartTS: Integer;
    FStartTime: Cardinal;
    FCurrentTS: Integer;
    FRange: Cardinal;
    FKeyFound: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(start: Integer; range: Cardinal; data: TBlock16;
      IV: TBlock16; origHeader: Int32);
    destructor Destroy; override;
    function isKeyFound: Boolean;
    function GetKey: TKey;
    function GetProgress: Integer;
    function GetCurrentTS: Integer;
    function GetElapsedTime: Integer;
  end;

implementation

uses Main;

constructor TBFThread.Create(start: Integer; range: Cardinal; data: TBlock16;
  IV: TBlock16; origHeader: Int32);
begin
  inherited Create(True);
  FData := data;
  FIV := IV;
  FRange := range;
  FStartTS := start;
  FCurrentTS := start;
  FOrigHeader := origHeader;
  FreeOnTerminate := True;
  FKeyFound := False;
end;

destructor TBFThread.Destroy;
begin
  inherited;
end;

function TBFThread.GetKey: TKey;
begin
  Result := Self.Fkey;
end;

function TBFThread.isKeyFound: Boolean;
begin
  Result := FKeyFound;
end;

function TBFThread.GetProgress: Integer;
begin
  Result := Trunc(100 * (Self.FStartTS - Self.FCurrentTS) / FRange);
end;

function TBFThread.GetCurrentTS: Integer;
begin
  Result := Self.FCurrentTS;
end;

function TBFThread.GetElapsedTime: Integer;
begin
  Result := Trunc((GetTickCount() - FStartTime) / 1000);
end;

procedure TBFThread.Execute;
begin
  FStartTime := GetTickCount;
  FKeyFound := MainForm.FBFRange(@FCurrentTS, FRange,
    PAnsiChar(Addr(Self.FData[0])), PAnsiChar(Addr(FIV[0])), Bswap(FOrigHeader),
    PAnsiChar(Addr(Fkey[0]))) = 0;
end;

end.
