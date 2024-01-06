program Pxy;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  PrxLstThread in 'PrxLstThread.pas',
  GlobalsUnit in 'GlobalsUnit.pas',
  MSHTMLbyString in 'MSHTMLbyString.pas',
  HTMLDocClass in 'HTMLDocClass.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
