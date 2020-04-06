unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.ImgList, JvBaseDlg, JvBrowseFolder, TextFade, Vcl.Buttons;

type
  TArg<T> = reference to procedure(const Arg: T);

  TMainF = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    edAuthor: TLabeledEdit;
    mResult: TMemo;
    btExit: TButton;
    btSave: TButton;
    btClear: TButton;
    btDo: TButton;
    dtPicker1: TDateTimePicker;
    dtPicker2: TDateTimePicker;
    Label3: TLabel;
    ImageList1: TImageList;
    edFormat: TLabeledEdit;
    edRepo: TButtonedEdit;
    Label4: TLabel;
    browserFolder: TJvBrowseForFolderDialog;
    SaveDialog1: TSaveDialog;
    TextFader1: TTextFader;
    btSound: TSpeedButton;
    procedure btExitClick(Sender: TObject);
    procedure edRepoRightButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btDoClick(Sender: TObject);
    procedure btClearClick(Sender: TObject);
    procedure btSaveClick(Sender: TObject);
    procedure btSoundClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    procedure CaptureConsoleOutput(const ACommand, AParameters: String;
      CallBack: TArg<PAnsiChar>);
  public
    { Public declarations }
  end;

var
  MainF: TMainF;

implementation

{$R *.dfm}

uses
  System.DateUtils, Winapi.MMSystem;

procedure TMainF.CaptureConsoleOutput(const ACommand, AParameters: String;
  CallBack: TArg<PAnsiChar>);
const
  CReadBuffer = 2400;
var
  saSecurity: TSecurityAttributes;
  hRead: THandle;
  hWrite: THandle;
  suiStartup: TStartupInfo;
  piProcess: TProcessInformation;
  pBuffer: array [0 .. CReadBuffer] of AnsiChar;
  dBuffer: array [0 .. CReadBuffer] of AnsiChar;
  dRead: DWORD;
  dRunning: DWORD;
  dAvailable: DWORD;
begin
  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := true;
  saSecurity.lpSecurityDescriptor := nil;
  if CreatePipe(hRead, hWrite, @saSecurity, 0) then
    try
      FillChar(suiStartup, SizeOf(TStartupInfo), #0);
      suiStartup.cb := SizeOf(TStartupInfo);
      suiStartup.hStdInput := hRead;
      suiStartup.hStdOutput := hWrite;
      suiStartup.hStdError := hWrite;
      suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      suiStartup.wShowWindow := SW_HIDE;
      if CreateProcess(nil, PChar(ACommand + ' ' + AParameters), @saSecurity,
        @saSecurity, true, NORMAL_PRIORITY_CLASS, nil, nil, suiStartup,
        piProcess) then
        try
          repeat
            dRunning := WaitForSingleObject(piProcess.hProcess, 100);
            PeekNamedPipe(hRead, nil, 0, nil, @dAvailable, nil);
            if (dAvailable > 0) then
              repeat
                dRead := 0;
                ReadFile(hRead, pBuffer[0], CReadBuffer, dRead, nil);
                pBuffer[dRead] := #0;
                OemToCharA(pBuffer, dBuffer);
                CallBack(dBuffer);
              until (dRead < CReadBuffer);
            Application.ProcessMessages;
          until (dRunning <> WAIT_TIMEOUT);
        finally
          CloseHandle(piProcess.hProcess);
          CloseHandle(piProcess.hThread);
        end;
    finally
      CloseHandle(hRead);
      CloseHandle(hWrite);
    end;
end;

procedure TMainF.btClearClick(Sender: TObject);
begin
  mResult.Clear;
end;

procedure TMainF.btDoClick(Sender: TObject);
var
  s: String;
begin
  s := ' --no-pager -C "' + edRepo.Text + '" log ';
  s := s + ' --before="' + FormatDateTime('yyyy-MM-dd', dtPicker2.Date) + '"';
  s := s + ' --after="' + FormatDateTime('yyyy-MM-dd', dtPicker1.Date) + '"';
  if edAuthor.Text <> '' then
    s := s + ' --author="' + edAuthor.Text + '"';
  if edFormat.Text <> '' then
    s := s + ' --format="' + edFormat.Text + '"';

  mResult.Clear;
  CaptureConsoleOutput('git', s,
    procedure(const Line: PAnsiChar)
    begin
      mResult.Lines.Add(String(Line) + sLineBreak);
    end);
end;

procedure TMainF.btExitClick(Sender: TObject);
begin
  close;
end;

procedure TMainF.btSaveClick(Sender: TObject);
begin
  SaveDialog1.FileName := ExtractFileName(edRepo.Text) +
    FormatDateTime('yyyyMMdd', dtPicker2.Date) + '_' +
    FormatDateTime('yyyyMMdd', dtPicker1.Date) + '.txt';
  if SaveDialog1.Execute then
  begin
    mResult.Lines.SaveToFile(SaveDialog1.FileName);
    MessageDlg('Saved successfully !', mtInformation, [mbOk], 0);
  end;

end;

procedure TMainF.edRepoRightButtonClick(Sender: TObject);
begin
  if browserFolder.Execute then
  begin
    if DirectoryExists(browserFolder.Directory + '/.git') then
      edRepo.Text := browserFolder.Directory
    else
      MessageDlg('Not git repository', mtError, [mbOk], 0);
  end;
end;

procedure TMainF.FormCreate(Sender: TObject);
begin
  dtPicker1.Date := EncodeDate(YearOf(now), MonthOf(now), 1);
  dtPicker2.Date := EncodeDate(YearOf(now), MonthOf(now),
    DayOf(EndOfAmonth(YearOf(now), MonthOf(now))));
end;

procedure TMainF.FormShow(Sender: TObject);
begin
  btSoundClick(self);
end;

procedure TMainF.btSoundClick(Sender: TObject);
var
  HResource: TResourceHandle;
  HResData: THandle;
  PWav: Pointer;
begin
  if btSound.Tag = 0 then
  begin
    HResource := FindResource(HInstance, PChar('wow'), 'WAV');
    if HResource <> 0 then
    begin
      HResData := LoadResource(HInstance, HResource);
      if HResData <> 0 then
      begin
        PWav := LockResource(HResData);
        if Assigned(PWav) then
        begin
          sndPlaySound(PWav, SND_ASYNC or SND_MEMORY);
          btSound.Tag := 1;
          btSound.Font.Style := [fsItalic];
          UnlockResource(HResData);
        end;
        FreeResource(HResource);
      end;
    end;

  end
  else
  begin
    sndPlaySound(nil, 0);
    btSound.Tag := 0;
    btSound.Font.Style := [fsStrikeOut, fsItalic];
  end;
end;

end.
