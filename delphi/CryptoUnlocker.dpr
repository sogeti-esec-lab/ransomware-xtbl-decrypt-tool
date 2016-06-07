program CryptoUnlocker;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$R *.dres}

uses
  Vcl.Forms,
  Main in 'Main.pas' {MainForm} ,
  Vcl.Themes,
  Vcl.Styles,
  DecThread in 'DecThread.pas',
  BFThread in 'BFThread.pas',
  BTMemoryModule in 'BTMemoryModule.pas',
  Utils in 'Utils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  if not isXP then
    TStyleManager.TrySetStyle('Carbon');
  Application.Title := 'Ransom.FileCryptor.xtbl Removal Tool';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;

end.
