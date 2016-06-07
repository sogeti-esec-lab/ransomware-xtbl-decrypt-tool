unit Main;

interface

uses
  Windows, System.Variants, Vcl.Forms, System.ImageList,
  Vcl.ImgList, Vcl.Controls, Vcl.ExtCtrls, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Samples.Gauges, System.Classes,
  System.SysUtils, System.DateUtils,
  Vcl.Graphics, ShellApi, Vcl.Buttons, Utils, BFThread, DecThread,
  BTMemoryModule, Vcl.ComCtrls, Vcl.Themes;

const
  INFECTED_FILE_MASK = '*.{a_princ@aol.com}.xtbl';

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    CloseButton: TButton;
    SogetiLinkLabel: TLabel;
    OpenDialog1: TOpenDialog;
    GroupBox1: TGroupBox;
    Panel2: TPanel;
    StartButton: TSpeedButton;
    Title: TLabel;
    Explanation1: TLabel;
    Explanation2: TLabel;
    Panel3: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Image1: TImage;
    PanelReady: TPanel;
    PanelBF: TPanel;
    Key_CurrentDate: TLabel;
    Key_CurrentKey: TLabel;
    Key_Title: TLabel;
    Key_ElapsedTime: TLabel;
    Key_ProgressLabel: TLabel;
    UpdateTimer1: TTimer;
    Key_CurrentDate_Value: TStaticText;
    Key_CurrentKey_Value: TStaticText;
    Key_ElapsedTime_Value: TStaticText;
    Key_Progress_Value: TGauge;
    ImageList1: TImageList;
    Label3: TLabel;
    Key_Filename_Value: TStaticText;
    GroupBox2: TGroupBox;
    Panel5: TPanel;
    Label10: TLabel;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    StaticText5: TStaticText;
    StaticText6: TStaticText;
    StaticText7: TStaticText;
    StaticText9: TStaticText;
    StaticText10: TStaticText;
    StaticText11: TStaticText;
    StaticText4: TStaticText;
    StaticText8: TStaticText;
    StaticText12: TStaticText;
    StaticText13: TStaticText;
    Panel4: TPanel;
    StartButton2: TSpeedButton;
    Label4: TLabel;
    UpdateTimer2: TTimer;
    GroupBox3: TGroupBox;
    ComboBox1: TComboBox;
    StaticText3: TStaticText;
    CheckBox1: TCheckBox;
    GroupBox4: TGroupBox;
    FileTimestampRadioButton: TRadioButton;
    SpecificDateTimestampRadioButton: TRadioButton;
    DateTimePicker2: TDateTimePicker;
    procedure FormCreate(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure SogetiLinkLabelClick(Sender: TObject);
    procedure SogetiLinkLabelMouseEnter(Sender: TObject);
    procedure SogetiLinkLabelMouseLeave(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StartButtonClick(Sender: TObject);
    procedure UpdateTimer1Timer(Sender: TObject);
    procedure StartButton2Click(Sender: TObject);
    procedure UpdateTimer2Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SpecificDateTimestampRadioButtonClick(Sender: TObject);
  private
    FBitmap: TBitmap;
    FBFThreadStarted: Boolean;
    FDecThreadStarted: Boolean;
    FEmbeddedDLL: TDll;
    procedure Initialize;
    procedure UpdateUIForBF;
    procedure UpdateUIForDec;
    procedure FindKey(filename: String);
    procedure BFThreadTerminated(Sender: TObject);
    procedure DecThreadTerminated(Sender: TObject);
  public
    Headers: TStrings;
    logFile: TextFile;
    BFTh: TBFThread;
    DecTh: TDecThread;
    KEY: TKey;
    RSA: TRSA1024Block;
    FDecrypt: function(encfilename: PWideChar; KEY: PAnsiChar;
      RSACheck: PAnsiChar): Integer; cdecl;
    FBFRange: function(start: PINT; range: UInt32; encHeader: PAnsiChar;
      IV: PAnsiChar; origHeader: Int32; KEY: PAnsiChar): Integer; cdecl;
    FBFBenchmark: function(range: Integer): Integer; cdecl;
    procedure Log(s: String);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.UpdateUIForBF;
var
  k: TKey;
  KStr: String;
begin
  k := BFTh.GetKey();
  KStr := ToHex(k, 32);
  Key_CurrentKey_Value.Caption := Copy(KStr, 1, 32) + #13 + #10 +
    Copy(KStr, 33, 32);
  Key_CurrentDate_Value.Caption := IntToStr(BFTh.GetCurrentTS());
  Key_ElapsedTime_Value.Caption := FormatDateTime('hh:nn:ss',
    BFTh.GetElapsedTime() / SecsPerDay);
  Key_Progress_Value.Progress := BFTh.GetProgress();
end;

procedure TMainForm.UpdateUIForDec;
var
  enc: Integer;
  dec: Integer;
  name: String;
begin
  enc := DecTh.GetEncrypted;
  dec := DecTh.GetDecrypted;
  name := DecTh.GetCurrentFilename;
  StaticText4.Caption := name;
  StaticText8.Caption := IntToStr(enc);
  StaticText12.Caption := IntToStr(dec) + ' (Wrong key : ' +
    IntToStr(enc - dec) + ')';
  StaticText13.Caption := FormatDateTime('hh:nn:ss', DecTh.GetElapsedTime() /
    SecsPerDay);
end;

procedure TMainForm.BFThreadTerminated(Sender: TObject);
var
  KStr: String;
  ts: Integer;
begin
  Log('Thread terminated');
  UpdateTimer1.Enabled := False;
  FBFThreadStarted := False;
  if BFTh.isKeyFound then
  begin
    KEY := BFTh.GetKey();
    KStr := ToHex(KEY, 32);
    Log('Key: ' + KStr);
    ts := BFTh.GetCurrentTS();
    Log('Timestamp: ' + IntToStr(ts));
    MessageBox(Self.Handle, PWideChar('Encryption key : ' + KStr),
      PWideChar('Key found'), MB_ICONASTERISK);
    GroupBox2.Visible := True;
    Log('== Decrypting files ============================================================');
  end
  else
  begin
    Log('Key not found');
    MessageBox(Self.Handle,
      PWideChar('The encryption key is not found. Retry with another date.'),
      PWideChar('Key not found'), MB_ICONWARNING);
    PanelReady.Visible := True;
    PanelBF.Visible := False;
  end;
  Key_Progress_Value.Progress := 100;
  StartButton.Caption := ' Start';
  ImageList1.GetBitmap(0, FBitmap);
  StartButton.Glyph.Assign(FBitmap);
end;

procedure TMainForm.DecThreadTerminated(Sender: TObject);
var
  enc: Integer;
  dec: Integer;
begin
  enc := DecTh.GetEncrypted;
  dec := DecTh.GetDecrypted;
  Log('Thread terminated');
  UpdateTimer2.Enabled := False;
  FDecThreadStarted := False;
  UpdateUIForDec;
  Application.ProcessMessages;
  MessageBox(Self.Handle, PWideChar(IntToStr(dec) + ' decrypted files (' +
    IntToStr(enc - dec) + ' have another key)'),
    PWideChar('Decryption finished'), MB_ICONASTERISK);
  StartButton2.Caption := ' Start';
  ImageList1.GetBitmap(0, FBitmap);
  StartButton2.Glyph.Assign(FBitmap);
end;

procedure TMainForm.FindKey(filename: String);
var
  origFilename: String;
  origHeader: Int32;
  encFile: TEncFile;
begin
  Log('== Finding Key =================================================================');
  Log('Encrypted file: ' + ExtractFileName(filename));
  origFilename := Copy(filename, 0, Length(filename) - 23);
  if Headers.Values[ExtractFileExt(origFilename)] <> '' then
  begin
    encFile := ReadEncFile(filename);
    RSA := encFile.RSA;
    origHeader := HexToInt(Headers.Values[ExtractFileExt(origFilename)]);

    Log('Header: ' + ToHex(encFile.Data, 16));
    Log('IV: ' + ToHex(encFile.IV, 16));
    Log('Filetime: ' + IntToHex(encFile.TimeStamp, 8));
    Log('Bruteforcing from ' + DateTimeToStr
      (UnixToDateTime(encFile.TimeStamp)));

    StartButton.Caption := ' Stop';
    ImageList1.GetBitmap(1, FBitmap);
    StartButton.Glyph.Assign(FBitmap);
    Key_Filename_Value.Caption := ExtractFileName(filename);
    Key_Progress_Value.Progress := 0;
    Key_CurrentDate_Value.Caption := IntToStr(encFile.TimeStamp);
    Key_CurrentKey_Value.Caption := '00000000000000000000000000000' + #13 + #10
      + '00000000000000000000000000000';
    Key_ElapsedTime_Value.Caption := '00:00:00';
    PanelReady.Visible := False;
    PanelBF.Visible := True;
    Application.ProcessMessages;

    Log('Benchmark(50) : ' + IntToStr(FBFBenchmark(50)));

    if SpecificDateTimestampRadioButton.Checked then
    begin
      encFile.TimeStamp := DateTimeToUnix(DateTimePicker2.DateTime, False);
    end;

    BFTh := TBFThread.Create(encFile.TimeStamp, DAY, encFile.Data, encFile.IV,
      origHeader);
    with BFTh do
    begin
      OnTerminate := BFThreadTerminated;
      start();
      Log('Bruteforce thread started');
      FBFThreadStarted := True;
    end;
    UpdateTimer1.Enabled := True;
  end
  else
  begin
    MessageBox(Self.Handle,
      PWideChar(
      'Supported extension : exe, dll, docx, xlsx, pptx, zip, jpeg, jpg, png, psd, 7z, pdf, avi, lnk, mkv, rtf, wmv.'),
      PWideChar('Extension ' + ExtractFileExt(origFilename) +
      ' is not supported'), MB_ICONWARNING);
  end;
end;

procedure TMainForm.SogetiLinkLabelClick(Sender: TObject);
begin
  ShellApi.ShellExecute(0, 'Open', PChar(SogetiLinkLabel.Caption), nil, nil, 1);
end;

procedure TMainForm.SogetiLinkLabelMouseEnter(Sender: TObject);
begin
  SogetiLinkLabel.Font.Style := [fsUnderline];
end;

procedure TMainForm.SogetiLinkLabelMouseLeave(Sender: TObject);
begin
  SogetiLinkLabel.Font.Style := [];
end;

procedure TMainForm.SpecificDateTimestampRadioButtonClick(Sender: TObject);
begin
  DateTimePicker2.Enabled := SpecificDateTimestampRadioButton.Checked;
end;

procedure TMainForm.StartButton2Click(Sender: TObject);
var
  enc: Integer;
  dec: Integer;
begin
  if FDecThreadStarted then
  begin
    Log('Thread stopped by user');
    TerminateThread(DecTh.Handle, 1);
    UpdateTimer2.Enabled := False;
    StartButton2.Caption := ' Start';
    ImageList1.GetBitmap(0, FBitmap);
    StartButton2.Glyph.Assign(FBitmap);
    Application.ProcessMessages;
    FDecThreadStarted := False;
    enc := DecTh.GetEncrypted;
    dec := DecTh.GetDecrypted;
    MessageBox(Self.Handle, PWideChar(IntToStr(dec) + ' decrypted files (' +
      IntToStr(enc - dec) + ' have another key)'),
      PWideChar('Decryption stopped'), MB_ICONASTERISK);
  end
  else
  begin
    ImageList1.GetBitmap(1, FBitmap);
    StartButton2.Glyph.Assign(FBitmap);
    StartButton2.Caption := ' Stop';
    Log('Options: ' + ComboBox1.Text + ', Delete(' +
      BoolToStr(CheckBox1.Checked, True) + ')');

    DecTh := TDecThread.Create(KEY, RSA, ComboBox1.ItemIndex = 0,
      ComboBox1.ItemIndex = 1, ComboBox1.ItemIndex = 2, CheckBox1.Checked);
    with DecTh do
    begin
      OnTerminate := DecThreadTerminated;
      start();
      Log('Decryption thread started');
      FDecThreadStarted := True;
    end;

    UpdateTimer2.Enabled := True;
  end;
end;

procedure TMainForm.Log(s: String);
begin
  Writeln(logFile, '[' + DateTimeToStr(Now) + '] - ' + s);
  Flush(logFile);
end;

procedure TMainForm.StartButtonClick(Sender: TObject);
begin
  if FBFThreadStarted then
  begin
    Log('Thread stopped by user');
    TerminateThread(BFTh.Handle, 1);
    UpdateTimer1.Enabled := False;
    Key_Progress_Value.Progress := 0;
    StartButton.Caption := ' Start';
    ImageList1.GetBitmap(0, FBitmap);
    StartButton.Glyph.Assign(FBitmap);
    Application.ProcessMessages;
    FBFThreadStarted := False;
    PanelReady.Visible := True;
    PanelBF.Visible := False;
  end
  else
  begin
    if OpenDialog1.Execute then
    begin
      FindKey(OpenDialog1.filename);
    end;
  end;
end;

procedure TMainForm.UpdateTimer1Timer(Sender: TObject);
begin
  UpdateUIForBF;
end;

procedure TMainForm.UpdateTimer2Timer(Sender: TObject);
begin
  UpdateUIForDec;
end;

procedure TMainForm.Initialize;
var
  date: String;
  drives: TStringList;
  i: Integer;
  ResStream: TResourceStream;
begin
  BFTh := nil;
  FBFThreadStarted := False;
  FDecThreadStarted := False;
  Key_Progress_Value.ForeColor := RGB(250, 213, 53);
  FBitmap := TBitmap.Create;
  ImageList1.GetBitmap(0, FBitmap);
  StartButton.Glyph.Assign(FBitmap);
  StartButton2.Glyph.Assign(FBitmap);
  DateTimePicker2.DateTime := Now;

  AssignFile(logFile, ExtractFileName(Application.ExeName) + '.log', CP_UTF8);
  ReWrite(logFile);
  Log('Starting: ' + Application.Title);
  Log('Filename: ' + Application.ExeName);

  Log('== System information ==========================================================');
  DateTimeToString(date, 'c', Now);
  Log('OS: ' + TOSVersion.ToString);
  Log('Computer name: ' + GetPCName());
  Log('User name: ' + GetUserFromWindows());
  Log('Windows directory: ' + GetWindowsDir());
  Log('Temp directory: ' + GetTempDir());
  Log('CPU architecture: ' + GetEnvironmentVariable('PROCESSOR_ARCHITECTURE'));
  Log('Number of processors: ' + GetEnvironmentVariable
    ('NUMBER_OF_PROCESSORS'));
  Log('Page size: ' + IntToStr(GetSystemInformation().dwPageSize));

  drives := GetDrives();
  date := '';
  for i := 0 to drives.Count - 1 do
  begin
    date := date + UpperCase(drives[i]) + ';';
  end;
  Log('Drives: ' + date);

  Log('== Initializing ================================================================');
  Headers := TStringList.Create;
  Headers.Add(Format('%s=%s', ['.dll', '4D5A9000']));
  Headers.Add(Format('%s=%s', ['.exe', '4D5A9000']));
  Headers.Add(Format('%s=%s', ['.docx', '504b0304']));
  Headers.Add(Format('%s=%s', ['.xlsx', '504b0304']));
  Headers.Add(Format('%s=%s', ['.pptx', '504b0304']));
  Headers.Add(Format('%s=%s', ['.zip', '504b0304']));
  Headers.Add(Format('%s=%s', ['.jpeg', 'ffd8ffe0']));
  Headers.Add(Format('%s=%s', ['.jpg', 'ffd8ffe0']));
  Headers.Add(Format('%s=%s', ['.png', '89504E47']));
  Headers.Add(Format('%s=%s', ['.psd', '38425053']));
  Headers.Add(Format('%s=%s', ['.7z', '377ABCAF']));
  Headers.Add(Format('%s=%s', ['.pdf', '25504446']));
  Headers.Add(Format('%s=%s', ['.avi', '52494646']));
  Headers.Add(Format('%s=%s', ['.lnk', '4c000000']));
  Headers.Add(Format('%s=%s', ['.mkv', '1a45dfa3']));
  Headers.Add(Format('%s=%s', ['.rtf', '7b5c7274']));
  Headers.Add(Format('%s=%s', ['.wmv', '3026B275']));
  Log('Default header values (' + IntToStr(Headers.Count) + ')');

  OpenDialog1.Title := 'Select one of the encrypted files';
  OpenDialog1.Filter :=
    'Encrypted file (*.{a_princ@aol.com}.xtbl)|*.{a_princ@aol.com}.xtbl';
  OpenDialog1.Options := [ofFileMustExist, ofEnableSizing, ofForceShowHidden];
  Log('Dialog properties');

  ResStream := TResourceStream.Create(HInstance, 'CRYPTODLL', RT_RCDATA);
  ResStream.Position := 0;
  FEmbeddedDLL.Size := ResStream.Size;
  FEmbeddedDLL.Data := GetMemory(ResStream.Size);
  ResStream.Read(FEmbeddedDLL.Data^, ResStream.Size);
  ResStream.Free;
  Log('Embedded DLL read');
  FEmbeddedDLL.Module := BTMemoryLoadLibary(FEmbeddedDLL.Data,
    FEmbeddedDLL.Size);
  Log('Embedded DLL loaded');
  @FDecrypt := BTMemoryGetProcAddress(FEmbeddedDLL.Module, 'decrypt_file');
  @FBFRange := BTMemoryGetProcAddress(FEmbeddedDLL.Module, 'bf_range');
  @FBFBenchmark := BTMemoryGetProcAddress(FEmbeddedDLL.Module, 'bf_benchmark');
  Log('Embedded DLL functions loaded');
end;

procedure TMainForm.CloseButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Log('== Deinitializing ==============================================================');
  if (BFTh <> nil) and FBFThreadStarted then
    TerminateThread(BFTh.Handle, 1);
  if (DecTh <> nil) and FDecThreadStarted then
    TerminateThread(DecTh.Handle, 1);
  CloseFile(logFile);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Self.Icon.Handle := Application.Icon.Handle;
  Self.Initialize();
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  BTMemoryFreeLibrary(FEmbeddedDLL.Module);
  FreeMemory(FEmbeddedDLL.Data);
  FBitmap.Free;
  Headers.Free;
end;

end.
