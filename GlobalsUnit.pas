unit GlobalsUnit;

interface

Uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdCompressorZLib, IdException, IdCookieManager, IdCookie,
  System.JSON, MSHTML, activex, ComObj, Vcl.OleCtrls, SHDocVw;
  //Generics.Defaults, Generics.Collections,
{
  IdAntiFreezeBase, IdBuffer, IdBaseComponent, IdComponent, IdGlobal, IdExceptionCore,
  IdIntercept, IdResourceStringsCore, IdStream;
}
{
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.OleCtrls, SHDocVw;
}
Const
  lstUrl1 = 'https://ru.proxy-tools.com/proxy';
  lstUrl2 = 'https://niek.github.io/free-proxy-list/';
  lstUrl3 = 'https://freeproxylist.ru/';
  lstUrl4 = 'http://free-proxy.cz/ru/';
Const
  myip = 'https://myip.ru/';
  toip = 'https://2ip.ru/';
  // You can make automated requests to the site using the API:
  myip_com = 'https://www.myip.com/';
  myip_api = 'https://api.myip.com/';

Var
  anId: TIdHTTP = nil;
  SSL1: TIdSSLIOHandlerSocketOpenSSL = nil;
  idoc: IHTMLDocument2 = nil;
  HTML: String = '';
  DocHTML: String = '';
  Doc2: IHTMLDocument2 = nil;
  Doc3: IHTMLDocument3 = nil;
  Doc7: IHTMLDocument7 = nil;
  col: IHTMLElementCollection;
  PrxLst: TStrings = nil; //TStringList = nil;
  doStopIt: Boolean = False;
  ActivePrxThread: TThread = nil;
  WS: WideString;

Function CreateSSL( full: Boolean = false): TIdSSLIOHandlerSocketOpenSSL;
Function CreateId: TIdHTTP;
Function CreateProxyId( pip: String): TIdHTTP; // pip - Proxy IP
Function _GetDoc( url: String; Lines: TStrings = nil; pip: String = ''): IHTMLDocument2;
Function GetByApi( Lines: TStrings = nil; pip: String = ''; WB: TWebBrowser = nil): String;
Procedure ParseDoc2asProxyTools( Lines: TStrings = nil);
Procedure CheckPrxLst( Lines: TStrings = nil);
Procedure ParseDoc2as2ip( Lines: TStrings = nil); // Doc2
procedure DocumentFromString(Document: IHTMLDocument2; const S: WideString);

implementation

// ------------------------ Commons --------------------------------------------
Function CreateSSL( full: Boolean = false): TIdSSLIOHandlerSocketOpenSSL;
Begin
  Result := TIdSSLIOHandlerSocketOpenSSL.Create;
  If not full then Exit;
  with Result do begin
    SSLOptions.Method := sslvTLSv1; //sslvSSLv23;
    SSLOptions.Mode := sslmUnassigned;
    { Проверка серверного сертификата SSL
    SSLOptions.Mode := sslmClient;
    SSLOptions.VerifyMode := [sslvrfPeer];
    SSLOptions.VerifyDepth := 10;
    }
  end;
End;

Function CreateId: TIdHTTP;
Begin
  Result := nil;
  Result := TIdHTTP.Create;
  Result.IOHandler := CreateSSL; //(True); //SSL1; // IOHandler: TIdIOHandler
  Result.HandleRedirects := True;
  Result.CookieManager := TIdCookieManager.Create(Result);
  Result.AllowCookies := True;
  Result.Compressor := TIdCompressorZLib.Create(Result);
  Result.Request.Referer := 'https://ya.ru';
  //Result.Request.UserAgent := 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36';
  //Result.HTTPOptions := [hoKeepOrigProtocol,hoForceEncodeParams];
  Result.HTTPOptions := [hoKeepOrigProtocol,hoForceEncodeParams,hoNoProtocolErrorException,hoWantProtocolErrorContent];
  Result.ProtocolVersion := pv1_1;
  Result.Request.UserAgent := 'Go-http-client/1.1';
  //Result.Request.ContentType := 'application/json';
  //Result.Request.Accept := 'application/json';
  //Result.Request.AcceptEncoding := 'gzip, identity;q=0';
End;

Function CreateProxyId( pip: String): TIdHTTP; // pip - Proxy IP
Begin
  Result := CreateId;
  Result.ProxyParams.Create;
  Result.ProxyParams.ProxyServer := pip;
  Result.ProxyParams.ProxyPort := 80; // 8080??? 999???
End;

procedure DocumentFromString(Document: IHTMLDocument2; const S: WideString);
var
  v: OleVariant;
begin
  v := VarArrayCreate([0, 0], varVariant);
  v[0] := S;
  Document.Write(PSafeArray(TVarData(v).VArray));
  Document.Close;
end;

Function _GetDoc( url: String; Lines: TStrings = nil; pip: String = ''): IHTMLDocument2;
Var
  V: OleVariant;
  id: TIdHTTP;
  //page: String;
  Done: Boolean;
  Step: Integer;
  msg: tagMSG;
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
        If Lines <> nil then If pip = '' then
          Lines.Add('_GetDoc( ' + url + ' ): ' + Step.ToString)
        else Lines.Add('_GetDoc( ' + url + ' via ' + pip + ' ): ' + Step.ToString);
        //page := id.Get(url);
        DocHTML := id.Get(url);
        Done := True;
      // EIdConnClosedGracefully is raised when remote side closes connection normally.
      except
      on e: EIdConnClosedGracefully do begin
        // HTTP.Response.ResponseCode - это 401
        // HTTP.Response.ResponseText - «Соединение закрыто изящно».
        If Lines <> nil then begin
          Lines.Add('CATCHED: Exception ' + e.ClassName + ': ' + e.Message);
          //Lines.Add('ResponseCode = ' + IntToStr(id.Response.ResponseCode)); // -1
          //Lines.Add('ResponseText = ' + (id.Response.ResponseText)); // ''
        end;
        //id.destroy;
        //id.Socket.Close; // disconnect TIdHTTP.Socket.Close
        //id.Disconnect;
        //FreeAndNil(id);
        Dec(Step);
        id.Connect;
      end;
      on e: Exception do
        If Lines <> nil then Lines.Add('Exception ' + e.ClassName + ': ' + e.Message);
        // Exception EIdHTTPProtocolException: HTTP/1.1 400 Bad Request
        // Exception EIdConnClosedGracefully: Connection Closed Gracefully.
      End;
      Application.ProcessMessages;
    Until doStopIt or Done or (Step > 2);
    //Создаем вариантный массив
    v := VarArrayCreate([0,0],VarVariant);
    v[0] := DocHTML; //page; // присваиваем 0 элементу массива строку с html
    // Создаем интерфейс
    CoInitialize(nil); //OleInitialize(0);
    {Можно загружать через CreateComObject либо через coHTMLDocument.Create}
    //iDoc:=CreateComObject(Class_HTMLDOcument) as IHTMLDocument2;
    Result := coHTMLDocument.Create as IHTMLDocument2;
    Result.designMode := 'on';
    //пишем в интерфейс
    Result.write(PSafeArray(System.TVarData(v).VArray));
    Result.close;
    {все, теперь страницу можно обрабатывать при помощи MSHTML}
    //while Result.readyState <> 'complete' do PeekMessage(msg, 0, 0, 0, PM_NOREMOVE);
    //CoUninitialize;
  Finally
    id.Free;
  End;
End;
// myip_api = 'https://api.myip.com/';
Function GetByApi( Lines: TStrings = nil; pip: String = ''; WB: TWebBrowser = nil): String;
Var
  V: OleVariant;
  id: TIdHTTP;
  s, json: String;
  FJSONObject: TJSONObject;
  i, tout: integer;
  WS: WideString;
  Doc: Variant;
Begin
  Result := '';
  If Lines <> nil then Lines.Add('GetByApi( pip = ' + pip + ' ):');
  If pip = '' then id := CreateId else id := CreateProxyId(pip);
  Try // TIdHTTP.Timeout: 1000 == 1sec
    tout := id.ConnectTimeout; // = 0
    tout := id.ReadTimeout; // = -1
    tout := id.Socket.ConnectTimeout; // = 0
    tout := id.Socket.ReadTimeout; // = -1
    If id.Socket.ReadLnTimedout then; // = false
    //id.CheckForGracefulDisconnect();
    //id.Request;
    json := id.Get(myip_api);
    If Lines <> nil then Lines.Add(json);
    // {"ip":"217.107.124.85","country":"Russian Federation","cc":"RU"}
    s := json.Substring( 0, 15);
    If (s = '<!DOCTYPE html>') and (WB <> nil) then begin
      WB.Silent := True;
      if NOT Assigned(WB.Document) then WB.Navigate('about:blank');
      Doc := WB.Document;
      Doc.Clear;
      Doc.Write(json); //(DocHTML); //(Doc2.body.innerHTML); //(HTMLCode);
      Doc.Close;
      Doc2 := WB.Document as IHTMLDocument2;
      // <title>Just a moment...</title>
      WS := Doc2.title;
      If Lines <> nil then Lines.Add(WS);
      Result := WS;
      Exit;
    end;
    FJSONObject := TJSONObject.ParseJSONValue(json) as TJSONObject;
    for i := 0 to FJSONObject.Count-1 do begin
      Lines.Add(FJSONObject.Pairs[i].JsonString.Value);
      Lines.Add(FJSONObject.Pairs[i].JsonValue.Value);
    end;
    If FJSONObject.Pairs[0].JsonString.Value = 'ip' then
      Result := FJSONObject.Pairs[0].JsonValue.Value;
  except
    on e: EIdException do
      If Lines <> nil then Lines.Add('EIdException ' + e.ClassName + ': ' + e.Message);
    on e: Exception do
      If Lines <> nil then Lines.Add('Exception ' + e.ClassName + ': ' + e.Message);
      // Exception EIdSocketError: Socket Error # 10060 - Connection timed out.
      // ??? Exception EIdHTTPProtocolException: HTTP/1.1 400 Bad Request
      // ??? Exception EIdConnClosedGracefully: Connection Closed Gracefully.
  End
End;
{ JUSTSO:
	TThread.CreateAnonymousThread(nil, procedure()
	var
		IdHTTP1 : TIdHTTP;
	begin
		IdHTTP1 := TIdHTTP.Create(nil);
		form1.MyFlag := false;
		IdHTTP1.Get('http://lenta.ru');
		form1.MyFlag := true;
		IdHTTP1.free;
	end).start;
...
IdHTTP1.ConnectTimeout:=5000;
IdHTTP1.ReadTimeout:=5000;
try
  IdHTTP1.Get('http://my1.ru/Update.txt');
    connected := True;
Except
    connected := false;
end;
}
Procedure ParseDoc2asProxyTools( Lines: TStrings = nil);
Var
  i, j, len: integer;
  s, ip: string;
  idisp: IDispatch;
  iElement: IHTMLElement;
  Collection, Tbls, TRs, TDs: IHTMLElementCollection;
  SL: TStringList;
Begin
  Lines.Add('Parse: ' + lstUrl1);
  len := Doc2.all.length;
  Lines.Add('idoc.all.length = ' + IntToStr(len));
  PrxLst := TStringList.Create;
  SL := TStringList.Create;
  TRs := Doc2.all.tags('TR') as IHTMLElementCollection;
  for i := 0 to TRs.length-1 do  begin
    iElement := TRs.Item(i,0) as IHtmlElement;
    //link:=iElement.getAttribute('href',0);
    Lines.Add(iElement.innerText);
    TDs := iElement.children as IHTMLElementCollection;
    len := TDs.length; // = 9
    Lines.Add( i.ToString + ': TDs.length = ' + IntToStr(len));
    // ALL: TDs.length = 9
    ip := (TDs.Item(0,0) as IHtmlElement).innerText;
    Lines.Add( i.ToString + '.0: ip = ' + ip);
    SL.Clear; SL.Add(ip);
    for j := 1 to len-1 do  begin
      s := (TDs.Item(j,0) as IHtmlElement).innerText;
      //M1.Lines.Add( i.ToString + ',' + j.ToString + ': ' + s);
      SL.Add(s);
    end;
    Lines.Add(SL.CommaText);
    //If i > 0 then PrxLst.Add(ip);
    If i > 0 then If SL[2].Trim = 'HTTP' then // MAYBE: "HTTP ", "HTTPS ", "SOCKS5 ", "SOCKS4 "
      PrxLst.Add(ip);
    // SL[3] = "Прозрачный ", "Элитный ", "Анонимный "
  end;
End;

Procedure CheckPrxLst( Lines: TStrings = nil);
Var
  i, cnt: integer;
  s, html: string;
  //pid: TIdHTTP;
  //Doc2: IHTMLDocument2;
  //Doc3: IHTMLDocument3 = nil;
  //Doc7: IHTMLDocument7 = nil;
  WS: WideString;
Begin
  //M1.Lines.Add('PrxLst.Count = ' + IntToStr(PrxLst.Count));
  cnt := PrxLst.Count;
  Lines.Add('PrxLst = ' + IntToStr(cnt) + ': ' + PrxLst.CommaText);
  for i := 0 to cnt-1 do  begin
    //pid := CreateProxyId(PrxLst[i]);
    //M1.Lines.Add(PrxLst[i] + ':');
    //html := pid.Get(myip);
    Doc2 := _GetDoc( toip, Lines, PrxLst[i]);
    WS := Doc2.title;
    Lines.Add(PrxLst[i] + ': Doc2.title = "' + WS + '"');
    // <table class="network-info">
    //WS := 'TABLE';
    //Doc2.all.tags(WS);
    If WS = '' then else ParseDoc2as2ip(Lines);
    Application.ProcessMessages;
  end;
  PrxLst.Free;
End;

Procedure ParseDoc2as2ip( Lines: TStrings = nil); // Doc2
Var
  WS: WideString;
  iElement: IHtmlElement;
  i, len: Integer;
Begin
  WS := Doc2.title;
  Lines.Add('ParseAs2ip(): ' + toip + ' - Doc2.title = "' + WS + '"');
  // ParseAs2ip(): https://2ip.ru/ - Doc2.title = "Узнать IP адрес"
  If Doc2.QueryInterface( IHTMLDocument3, Doc3) <> 0 then Exit;
  //Doc3.getElementsByName('WideString');
  //Doc3.getElementById('WideString');
  //Doc3.getElementsByTagName('WideString');
  If Doc2.QueryInterface( IHTMLDocument7, Doc7) <> 0 then Exit;
  // <form method="post" action="https://ru.proxy-tools.com/proxy/download" class="pt-3 border-top border-secondary">
  col := Doc7.getElementsByClassName('ip');
  len := col.length;
  Lines.Add('class("ip").length = ' + IntToStr(len));
  If len > 0 then begin
    iElement := col.Item(0,0) as IHtmlElement;
    Lines.Add('ip = ' + iElement.innerText);
  end;
  // <table class="table table-sm table-responsive-md table-hover">
  //Collection:=idoc.all.tags('TABLE') as IHTMLElementCollection;
  //Tbls := Doc7.getElementsByClassName('table table-sm table-responsive-md table-hover');
  //M1.Lines.Add('Table.length = ' + IntToStr(Tbls.length)); // Table.length = 1
  //iElement := Tbls.Item(0,0) as IHtmlElement;
  //iElement.all;
  {
  TRs:=idoc.all.tags('TR') as IHTMLElementCollection;
  for i := 0 to TRs.length-1 do  begin
    iElement := TRs.Item(i,0) as IHtmlElement;
    //link:=iElement.getAttribute('href',0);
    M1.Lines.Add(iElement.innerText);
  end;
  }
End;

end.

