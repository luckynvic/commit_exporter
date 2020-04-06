program commit_exporter;

{$R 'sound.res' 'sound.rc'}

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {MainF},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Glossy');
  Application.CreateForm(TMainF, MainF);
  Application.Run;

end.
