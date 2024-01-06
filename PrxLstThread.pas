unit PrxLstThread;

interface

uses
  System.Classes, System.SysUtils, System.Variants, Vcl.Forms, MSHTML;
{
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.OleCtrls, SHDocVw;
}
type
  TPrxLstThread = class(TThread)
  private
    { Private declarations }
    Lines: TStrings;
    OnEnd: TNotifyEvent;
    OutS: String;
    HTML: String; // = '';
    Doc2: IHTMLDocument2; // = nil;
    Doc3: IHTMLDocument3; // = nil;
    Doc7: IHTMLDocument7; // = nil;
    Procedure _doOut;
    Procedure ThreadTerminate(Sender: TObject);
    Function GetDoc( url: String; pip: String = ''): IHTMLDocument2;
  protected
    procedure Execute; override;
    Procedure doOut( S: String);
  public
    Constructor CreateThread( _Lines: TStrings; _End: TNotifyEvent);
  end;

implementation

{
  Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TPrxLstThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end;

    or

    Synchronize(
      procedure
      begin
        Form1.Caption := 'Updated in thread via an anonymous method'
      end
      )
    );

  where an anonymous method is passed.

  Similarly, the developer can call the Queue method with similar parameters as
  above, instead passing another TThread class as the first parameter, putting
  the calling thread in a queue with the other thread.

}
//Uses GlobalsUnit;
Uses
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdCompressorZLib, IdException, IdCookieManager, IdCookie,
  System.JSON, activex, ComObj, //Generics.Defaults, Generics.Collections,
  GlobalsUnit; //, Synapse;
{
  IdAntiFreezeBase, IdBuffer, IdBaseComponent, IdComponent, IdGlobal, IdExceptionCore,
  IdIntercept, IdResourceStringsCore, IdStream;
}

{ TPrxLstThread }
Constructor TPrxLstThread.CreateThread( _Lines: TStrings; _End: TNotifyEvent);
Begin
  inherited Create(True);
  self.FreeOnTerminate := True;
  self.OnTerminate := ThreadTerminate;
  self.Lines := _Lines;
  self.OnEnd := _End;
  self.HTML := '';
  self.Doc2 := nil; self.Doc3 := nil; self.Doc7 := nil;
  //CoInitializeEx( 0, COINIT_MULTITHREADED); //OleInitialize(0);
  self.Resume;
End;

Procedure TPrxLstThread.ThreadTerminate(Sender: TObject);
Begin
  doOut('TPrxLstThread.ThreadTerminate(Sender=' + Sender.ClassName + '):');
  // TPrxLstThread.ThreadTerminate(Sender=TPrxLstThread):
  self.OnEnd(Self);
End;

Procedure TPrxLstThread.doOut( S: String);
Begin
  If Lines = nil then Exit;
  self.OutS := S;
  Synchronize(_doOut);
End;
Procedure TPrxLstThread._doOut;
Begin
  self.Lines.Add(self.OutS);
End;

procedure TPrxLstThread.Execute;
Var
  WS: WideString;
begin
  { Place thread code here }
  doOut('TPrxLstThread.Execute:');
  self.Doc2 := GetDoc( lstUrl1); // -> HTML
  //self.Synchronize( Procedure Begin self.Doc2 := GetDoc( lstUrl1); end);
  WS := self.Doc2.title;
  doOut('Doc2.Title = "' + WS + '"');
  If WS = '' then doOut('HTML = "' + self.HTML + '"');
  //else doOut('Doc2.Title = "' + WS + '"');
  Exit;
  //ParseDoc2asProxyTools( Lines); // => PrxLst: TStringList;
  self.Synchronize( Procedure Begin ParseDoc2asProxyTools(Lines) end);
  //CheckPrxLst;
  //self.Synchronize( Procedure Begin CheckPrxLst(Lines) end);
end;

Function TPrxLstThread.GetDoc( url: String; pip: String = ''): IHTMLDocument2;
Var
  V: OleVariant;
  id: TIdHTTP;
  //page: String;
  Done: Boolean;
  Step: Integer;
Begin
  id := nil;
  Result := nil;
  //If Lines <> nil then Lines.Add('_GetDoc( ' + url + ' ):');
  Try
    Done := False;
    Step := 0;
    Repeat
      try
        If id = nil then
          If pip = '' then id := CreateId else id := CreateProxyId(pip);
        Inc(Step);
        If pip = '' then
          doOut('TPrxLstThread.GetDoc( ' + url + ' ): ' + Step.ToString)
        else doOut('TPrxLstThread.GetDoc( ' + url + ' via ' + pip + ' ): ' + Step.ToString);
        //page := id.Get(url);
        self.HTML := id.Get(url);
        Done := True;
      // EIdConnClosedGracefully is raised when remote side closes connection normally.
      except
      on e: EIdConnClosedGracefully do begin
        // HTTP.Response.ResponseCode - это 401
        // HTTP.Response.ResponseText - «Соединение закрыто изящно».
          doOut('CATCHED: Exception ' + e.ClassName + ': ' + e.Message);
          //Lines.Add('ResponseCode = ' + IntToStr(id.Response.ResponseCode)); // -1
          //Lines.Add('ResponseText = ' + (id.Response.ResponseText)); // ''
        //id.destroy;
        //id.Socket.Close; // disconnect TIdHTTP.Socket.Close
        //id.Disconnect;
        //FreeAndNil(id);
        Dec(Step);
        id.Connect;
      end;
      on e: Exception do
        doOut('Exception ' + e.ClassName + ': ' + e.Message);
        // Exception EIdHTTPProtocolException: HTTP/1.1 400 Bad Request
        // Exception EIdConnClosedGracefully: Connection Closed Gracefully.
      End;
      Application.ProcessMessages;
    Until doStopIt or Done or (Step > 2);
    //Создаем вариантный массив
    v := VarArrayCreate([0,0],VarVariant);
    v[0] := self.HTML; //page; // присваиваем 0 элементу массива строку с html
    // Создаем интерфейс
    CoInitialize(nil); //CoInitializeEx( 0, COINIT_MULTITHREADED);
    {Можно загружать через CreateComObject либо через coHTMLDocument.Create}
    //iDoc:=CreateComObject(Class_HTMLDOcument) as IHTMLDocument2;
    Result := coHTMLDocument.Create as IHTMLDocument2;
    Result.designMode := 'on';
    //пишем в интерфейс
    Result.write(PSafeArray(System.TVarData(v).VArray));
    Result.designMode := 'off';
    {все, теперь страницу можно обрабатывать при помощи MSHTML}
    //while Result.readyState <> 'complete' do ;
    // IHTMLDocument2.write() IHTMLDocument2.readyState
    Result.close;
    doOut('Result.Title = "' + Result.title + '"');
  Finally
    id.Free;
  End;
End;

end.

