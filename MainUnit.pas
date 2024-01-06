unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.OleCtrls, SHDocVw;

type
  TMainForm = class(TForm)
    TopPnl: TPanel;
    M1: TMemo;
    IdHTTPBtn: TButton;
    SG1: TStringGrid;
    HTTPSendBtn: TButton;
    WB1: TWebBrowser;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    ThreadBtn: TButton;
    DocBtn: TButton;
    procedure FormCreate(Sender: TObject);
    procedure IdHTTPBtnClick(Sender: TObject);
    procedure HTTPSendBtnClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure ThreadBtnClick(Sender: TObject);
    procedure DocBtnClick(Sender: TObject);
  private
    { Private declarations }
    Procedure GetDoc( url: String); // url => idoc
    Procedure ParseProxyTools; // proxy-tools
    Procedure CheckPrxLst;
    Procedure ParseAs2ip; // Doc2
    Procedure PrxThreadEnd(Sender: TObject);
    Procedure CtrlW;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

Uses
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdCompressorZLib, IdException, IdCookieManager, IdCookie,
  System.JSON, MSHTML, activex, ComObj, IOUtils,
  //Generics.Defaults, Generics.Collections,
  GlobalsUnit, DateUtils, MSHTMLbyString, HTMLDocClass,
  PrxLstThread; //, Synapse;
{
  IdAntiFreezeBase, IdBuffer, IdBaseComponent, IdComponent, IdGlobal, IdExceptionCore,
  IdIntercept, IdResourceStringsCore, IdStream;
}
// ------------------------ TMainForm ------------------------------------------
// NEED: Synapse
procedure TMainForm.HTTPSendBtnClick(Sender: TObject);
//var
  //HTTPSend: THTTPSend;
begin
  ShowMessage('NEED Synapse!');
  //HTTPSend := THTTPSend.Create;
  //HTTPSend.ProxyHost := '213.167.53.138';
  //HTTPSend.ProxyPort := '3128';
  //HTTPSend.HTTPMethod('GET','https://www.google.ru');
  //M1.Lines.LoadFromStream(HTTPSend.Document);
end;

Procedure TMainForm.GetDoc( url: String); // url => HTML & idoc
Var
  V: OleVariant;
  WS: WideString;
Begin
  M1.Lines.Add('GetDoc( ' + url + ' ):');
  //anId := TIdHTTP.Create;
  anId := CreateId;
  Try
    Try
      {
      SSL1 := TIdSSLIOHandlerSocketOpenSSL.Create;
      with SSL1 do begin
        SSLOptions.Method := sslvTLSv1; //sslvSSLv23;
        SSLOptions.Mode := sslmUnassigned;
      end;
      anId.IOHandler := SSL1;
      anId.AllowCookies := True;
      anId.HandleRedirects := True;
      //anId.CookieManager;
      //anId.Compressor;
      anId.Request.Referer := 'ya.ru';
      anId.Request.UserAgent := 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36';
      }
      //anId.Get(lstUrl,MS);
      //M1.Lines.Add('Size = ' + MS.Size.ToString); // Size = 89951
      HTML := anId.Get(lstUrl1);
      //Создаем вариантный массив
      v := VarArrayCreate([0,0],VarVariant);
      v[0] := HTML; // присваиваем 0 элементу массива строку с html
      // Создаем интерфейс
      {Можно загружать через CreateComObject либо через coHTMLDocument.Create}
      //iDoc:=CreateComObject(Class_HTMLDOcument) as IHTMLDocument2;
      idoc := coHTMLDocument.Create as IHTMLDocument2;
      idoc.designMode := 'on';
      //пишем в интерфейс
      idoc.write(PSafeArray(System.TVarData(v).VArray));
      {все, теперь страницу можно обрабатывать при помощи MSHTML}
      WS := idoc.title;
      M1.Lines.Add('Loaded: ' + url + ' - "' + WS + '"');
      // Loaded: https://ru.proxy-tools.com/proxy - "Список бесплатных прокси онлайн – Proxy-Tools.com"
    except on e: Exception do
{$IFNDEF DEBUG}
      self.Caption := ('Exception ' + e.ClassName + ': ' + e.Message);
{$ELSE}
      M1.Lines.Add('Exception ' + e.ClassName + ': ' + e.Message);
{$ENDIF}
    End;
  Finally
    anId.Free;
  End;
End;

Procedure TMainForm.ParseProxyTools;
Var
  i, j, len: integer;
  s, ip: string;
  idisp: IDispatch;
  iElement: IHTMLElement;
  Collection, Tbls, TRs, TDs: IHTMLElementCollection;
  SL: TStringList;
Begin
  M1.Lines.Add('Parse: ' + lstUrl1);
  len := idoc.all.length;
  M1.Lines.Add('idoc.all.length = ' + IntToStr(len));
  PrxLst := TStringList.Create;
  SL := TStringList.Create;
  TRs:=idoc.all.tags('TR') as IHTMLElementCollection;
  for i := 0 to TRs.length-1 do  begin
    iElement := TRs.Item(i,0) as IHtmlElement;
    //link:=iElement.getAttribute('href',0);
    M1.Lines.Add(iElement.innerText);
    TDs := iElement.children as IHTMLElementCollection;
    len := TDs.length; // = 9
    M1.Lines.Add( i.ToString + ': TDs.length = ' + IntToStr(len));
    // ALL: TDs.length = 9
    ip := (TDs.Item(0,0) as IHtmlElement).innerText;
    M1.Lines.Add( i.ToString + '.0: ip = ' + ip);
    SL.Clear; SL.Add(ip);
    for j := 1 to len-1 do  begin
      s := (TDs.Item(j,0) as IHtmlElement).innerText;
      //M1.Lines.Add( i.ToString + ',' + j.ToString + ': ' + s);
      SL.Add(s);
    end;
    M1.Lines.Add(SL.CommaText);
    //If i > 0 then PrxLst.Add(ip);
    If i > 0 then If SL[2].Trim = 'HTTP' then // MAYBE: "HTTP ", "HTTPS ", "SOCKS5 ", "SOCKS4 "
      PrxLst.Add(ip);
    // SL[3] = "Прозрачный ", "Элитный ", "Анонимный "
  end;
End;

procedure TMainForm.ThreadBtnClick(Sender: TObject);
begin
  M1.Lines.Add('ThreadBtnClick():');
  CoInitializeEx( 0, COINIT_MULTITHREADED); //OleInitialize(0);
  ActivePrxThread := TPrxLstThread.CreateThread( M1.Lines, PrxThreadEnd);
end;

Procedure TMainForm.PrxThreadEnd(Sender: TObject);
Begin
  M1.Lines.Add('PrxThreadEnd(): ' + Sender.ClassName);
  //FreeAndNil(ActivePrxThread);
End;

Procedure TMainForm.CheckPrxLst;
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
  M1.Lines.Add('PrxLst = ' + IntToStr(cnt) + ': ' + PrxLst.CommaText);
  for i := 0 to cnt-1 do  begin
    //pid := CreateProxyId(PrxLst[i]);
    //M1.Lines.Add(PrxLst[i] + ':');
    //html := pid.Get(myip);
    Doc2 := _GetDoc( toip, M1.Lines, PrxLst[i]);
    WS := Doc2.title;
    M1.Lines.Add(PrxLst[i] + ': Doc2.title = "' + WS + '"');
    // <table class="network-info">
    //WS := 'TABLE';
    //Doc2.all.tags(WS);
    If WS = '' then else ParseAs2ip;
    Application.ProcessMessages;
  end;
  PrxLst.Free;
End;
{ myip:
Ваш IP-адрес: 217.107.124.85
Имя вашего хоста: 217.107.124.85
 2ip:
Ваш IP адрес: 217.107.124.85
}
procedure TMainForm.IdHTTPBtnClick(Sender: TObject);
Var
  //MS: TMemoryStream;
  V: OleVariant;
  i, len: integer;
  s, link: string;
  idisp: IDispatch;
  iElement: IHTMLElement;
  Collection, Tbls, TRs: IHTMLElementCollection;
begin
  GetDoc(lstUrl1);
  ParseProxyTools; // => PrxLst: TStringList;
  CheckPrxLst;
  Exit;
  M1.Lines.Add('Do It!!!');
  anId := TIdHTTP.Create;
  //MS := TMemoryStream.Create;
  Try
    //anId.ProxyParams.ProxyServer := 'адрес_прокси_сервера';
    //anId.ProxyParams.ProxyPort := 8080;
    // Выполнение HTTP-запросов через прокси
    //anId.Get('http://www.example.com');
    Try
      SSL1 := TIdSSLIOHandlerSocketOpenSSL.Create;
      with SSL1 do begin
        SSLOptions.Method := sslvTLSv1; //sslvSSLv23;
        SSLOptions.Mode := sslmUnassigned;
        { Проверка серверного сертификата SSL
        SSLOptions.Mode := sslmClient;
        SSLOptions.VerifyMode := [sslvrfPeer];
        SSLOptions.VerifyDepth := 10;
        }
      end;
      anId.IOHandler := SSL1;
      anId.AllowCookies := True;
      anId.HandleRedirects := True;
      //anId.CookieManager;
      //anId.Compressor;
      anId.Request.Referer := 'ya.ru';
      anId.Request.UserAgent := 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36';
      //anId.Get(lstUrl,MS);
      //M1.Lines.Add('Size = ' + MS.Size.ToString); // Size = 89951
      HTML := anId.Get(lstUrl1);
      //Создаем вариантный массив
      v := VarArrayCreate([0,0],VarVariant);
      v[0] := HTML; // присваиваем 0 элементу массива строку с html
      // Создаем интерфейс
      {Можно загружать через CreateComObject либо через coHTMLDocument.Create}
      //iDoc:=CreateComObject(Class_HTMLDOcument) as IHTMLDocument2;
      idoc := coHTMLDocument.Create as IHTMLDocument2;
      idoc.designMode := 'on';
      //пишем в интерфейс
      idoc.write(PSafeArray(System.TVarData(v).VArray));
      {все, теперь страницу можно обрабатывать при помощи MSHTML}
      M1.Lines.Add(idoc.title); // "Список бесплатных прокси онлайн – Proxy-Tools.com"
      len := idoc.all.length;
      M1.Lines.Add('idoc.all.length = ' + IntToStr(len));
      // idoc.all.length = 977
      for i := 1 to len do begin
        idisp:=idoc.all.item(pred(i),0);
        idisp.QueryInterface(IHTMLElement,iElement);// <<Тот самый <b>QueryInterface</b>
        str(pred(i),s); s:=s+' ';
        if assigned(ielement) then S:=S+' tag '+iElement.tagName+' ';
        //M1.Lines.Add(s);
      end;
      //M1.Lines.Clear;
      for i := 0 to idoc.all.length-1 do begin
        iElement := idoc.all.item(i,0) as IHTMLElement;
        //M1.Lines.Add(inttostr(i)+' '+iElement.tagName);
      end;
      // idoc.forms.length = 2
      M1.Lines.Add('idoc.forms.length = ' + IntToStr(idoc.forms.length));
      //Collection := idoc.all.tags('A') as IHTMLElementCollection;
      //M1.Lines.Clear;
      Collection:=idoc.all.tags('A') as IHTMLElementCollection;
      for i := 0 to Collection.length-1 do  begin
        iElement := Collection.Item(i,0) as IHtmlElement;
        link:=iElement.getAttribute('href',0);
        if (Pos('http:',link)>0) or (Pos('https:',link)>0) then M1.Lines.Add(link);
      end;
      // Query Doc3=0
      //M1.Lines.Add('Query Doc3='+IntToStr(idoc.QueryInterface( IHTMLDocument3, Doc3)));
      If idoc.QueryInterface( IHTMLDocument3, Doc3) <> 0 then Exit;
      //Doc3.getElementsByName('WideString');
      //Doc3.getElementById('WideString');
      //Doc3.getElementsByTagName('WideString');
      If idoc.QueryInterface( IHTMLDocument7, Doc7) <> 0 then Exit;
      // <form method="post" action="https://ru.proxy-tools.com/proxy/download" class="pt-3 border-top border-secondary">
      col := Doc7.getElementsByClassName('pt-3 border-top border-secondary');
      M1.Lines.Add('form.length = ' + IntToStr(col.length)); // form.length = 1
      // <table class="table table-sm table-responsive-md table-hover">
      //Collection:=idoc.all.tags('TABLE') as IHTMLElementCollection;
      Tbls := Doc7.getElementsByClassName('table table-sm table-responsive-md table-hover');
      M1.Lines.Add('Table.length = ' + IntToStr(Tbls.length)); // Table.length = 1
      iElement := Tbls.Item(0,0) as IHtmlElement;
      //iElement.all;
      TRs:=idoc.all.tags('TR') as IHTMLElementCollection;
      for i := 0 to TRs.length-1 do  begin
        iElement := TRs.Item(i,0) as IHtmlElement;
        //link:=iElement.getAttribute('href',0);
        M1.Lines.Add(iElement.innerText);
      end;
    except on e: Exception do
{$IFNDEF DEBUG}
      self.Caption := ('Exception ' + e.ClassName + ': ' + e.Message);
{$ELSE}
      M1.Lines.Add('Exception ' + e.ClassName + ': ' + e.Message);
{$ENDIF}
      // free-proxy.cz == Exception EIdHTTPProtocolException: HTTP/1.1 401 Unauthorized
      // freeproxylist.ru == Exception EIdHTTPProtocolException: HTTP/1.1 403 Forbidden
      { niek.github.io:
Exception EIdOSSLUnderlyingCryptoError: Error connecting with SSL.
error:1409442E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version
      }
    End;
  Finally
    //MS.Free;
    SSL1.Free;
    FreeAndNil(anId); //anId.Free;
  End;
end;
{
libeay32.dll ssleay32.dll
}
procedure TMainForm.FormCreate(Sender: TObject);
begin
{$IFNDEF DEBUG}
  //M1.Visible := False;
{$ELSE}
  //OutputDebugString(i.ToString);
  M1.Text := 'DEBUG:';
{$ENDIF}
  self.KeyPreview := True;
  WB1.Align := alClient;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  M1.Lines.Add('Ctrl-Q == GetByApi( pip = 173.170.204.137 ):');
  M1.Lines.Add('Ctrl-D == _GetDoc( toip, M1.Lines, "173.170.204.137");');
  M1.Lines.Add('Ctrl-W == getElementsByTagName( "GetByApi.html", "tr")');
  M1.Lines.Add('Ctrl-E == all := getAll( HTML, M1.Lines);');
end;
{$IFDEF MSWINDOWS}
  //SetPermissions;
{$ENDIF}
Procedure TMainForm.CtrlW;
Var
  i, p: Integer;
  ttl, tbl, S: String;
  SL: TStringList;
  tags, ths, tds, metas, all: TStrings;
Begin
 Try
  SL := TStringList.Create;
  // SL.Encoding := TEncoding.UTF8; - read-only
  SL.DefaultEncoding := TEncoding.UTF8;
  SL.LoadFromFile('GetByApi.html');
  M1.Lines.Add('Lines count = ' + IntToStr(SL.Count));
  HTML := SL.Text;
  M1.Lines.Add('SL[17] = ' + SL[17]);
  FreeAndNil(SL); //SL.Free;
  M1.Lines.Add('Char count = ' + IntToStr(Length(HTML)));
{}
  ttl := ExBtwn( HTML, '<title>', '</title>'); //, True);
  // w12 = True : <title> = "<title>Just a moment...</title>"
  M1.Lines.Add('<title> = "' + ttl + '"'); // <title> = "Just a moment..."
  //Exit;
  tbl := ExBtwn( HTML, '<table', '</table>', True);
  //M1.Lines.Add('<table> = "' + tbl + '"');
  M1.Lines.Add('table.class = "' + ElAttr( tbl, 'class') + '"');
  // GetElement
  metas := getElementsByTagName( HTML, 'meta');
  M1.Lines.Add('META count = ' + IntToStr(metas.Count)); // TR count = 36
  for i := 0 to metas.Count-1 do begin
    M1.Lines.Add(i.ToString + ': "' + ElTag(metas[i]) + '" = ' + metas[i]);
    M1.Lines.Add('content = "' + ElAttr( metas[i], 'content') + '"');
    M1.Lines.Add('http-equiv = "' + ElAttr( metas[i], 'http-equiv') + '"');
    M1.Lines.Add('name = "' + ElAttr( metas[i], 'name') + '"');
  end;
  metas.Free;
  tags := getElementsByTagName( HTML, 'tr');
  M1.Lines.Add('TR count = ' + IntToStr(tags.Count)); // TR count = 36
  //for i := 0 to tags.Count-1 do M1.Lines.Add(i.ToString + ': ' + tags[i]);
  M1.Lines.Add('SL[0]: ' + tags[0]);
  ths := getElementsByTagName( tags[0], 'th');
  M1.Lines.Add('TH count = ' + IntToStr(ths.Count)); // TH count = 9
  for i := 0 to ths.Count-1 do
    //M1.Lines.Add(i.ToString + ': "' + ElTag(ths[i]) + '" = ' + ths[i]);
    M1.Lines.Add(i.ToString + ': "' + ElTag(ths[i]) + '" = ' + ElInnerHTML(ths[i]));
  // 0: "th" = <th scope="col">IP адрес</th>
  // 8: "th" = <th scope="col">Проверка</th>
  ths.Free;
  tds := getElementsByTagName( tags[1], 'td');
  tags.Free;
  M1.Lines.Add('TD count = ' + IntToStr(tds.Count)); // TD count = 9
  for i := 0 to tds.Count-1 do
    M1.Lines.Add(i.ToString + ': "' + ElTag(tds[i]) + '" = ' + ElInnerHTML(tds[i]).Trim);
  S := tds[5];
  all := getAll(S); //, M1.Lines);
  tds.Free;
  M1.Lines.Add('tds[5].all = ' + IntToStr(all.Count)); // TD count = 9
  for i := 0 to all.Count-1 do
    M1.Lines.Add(i.ToString + ': "' + (all[i]) + '"');
  all.Free;
 Except on e: Exception do
{$IFNDEF DEBUG}
  self.Caption := ('Exception ' + e.ClassName + ': ' + e.Message);
{$ELSE}
  M1.Lines.Add('Exception ' + e.ClassName + ': ' + e.Message);
  // Exception EListError: Unbalanced stack or queue operation
  // Exception EStringListError: List index out of bounds (-1).  TStringList is empty
  // Exception EStringListError: List index out of bounds (-1).  TStringList range is 0..0
{$ENDIF}
 End;
End;

procedure TMainForm.DocBtnClick(Sender: TObject);
Var
  //_HTML: String;
  i, j, cnt, trc, tdc: Integer;
  lst1, lst2, tbl, trs, tds: TElList;
  EL, eli, tri, tdi: THTMLElement;
begin
  M1.Lines.Add('Doc := THTMLDoc:');
  DebugLines4Doc(M1.Lines);
  //MainDoc := THTMLDoc.EmptyCreate(self);
{$IFDEF DOCFILE}
  var _HTML := TFile.ReadAllText('GetByApi.html',TEncoding.UTF8);
  M1.Lines.Add('Loaded: ' + _HTML.Substring(0,99));
  // Loaded: <!DOCTYPE html><html lang="en-US"><head><title>Just a moment...</title>...
  MainDoc := THTMLDoc.CreateByHTML(_HTML);
{$ELSE}
  MainDoc := THTMLDoc.CreateByURL(lstUrl1);
{$ENDIF}
  M1.Lines.Add('MainDoc: Title = "' + (MainDoc.Title) + '"');
  // MainDoc: Title = "Just a moment..."
  // MainDoc: Title = "Список бесплатных прокси онлайн &ndash; Proxy-Tools.com"
  M1.Lines.Add('MainDoc: All.Count = ' + IntToStr(MainDoc.AllCount));
  // MainDoc: All.Count = 591
  // MainDoc: All.Count = 975
  {
  For i := 0 to 51 do begin //MainDoc.All.Count-1 do
    //M1.Lines.Add(i.ToString + ': ' + MainDoc.All[i].TagName);
    El := MainDoc.All[i];
    M1.Lines.Add(i.ToString + ': ' + El.TagName + ' = ' + El.HTML);
  end;
  }
  lst1 := MainDoc.getElementsByTagName('meta');
  M1.Lines.Add('meta.Count = ' + lst1.Count.ToString); // meta.Count = 5, 7
  // <div class="progress" style="height: 7px;">...</div>
  lst2 := MainDoc.getElementsByClassName('progress');
  M1.Lines.Add('progress.Count = ' + lst2.Count.ToString); // progress.Count = 35
  tbl := MainDoc.getElementsByTagName('table');
  cnt := tbl.Count;
  M1.Lines.Add('<table>.Count = ' + cnt.ToString); // <table>.Count = 1
  If cnt > 0 then begin
    El := tbl[0];
    trs := El.getElementsByTagName('tr');
    trc := trs.Count;
    M1.Lines.Add('<TR>.Count = ' + trc.ToString); // <TR>.Count = 36
    For i := 1 to trc-1 do begin // <TR>[0] == THEAD
      tri := trs[i]; //El.All[i];
      tds := tri.getElementsByTagName('td');
      tdc := tds.Count;
      For j := 0 to tdc-1 do begin
        tdi := tds[j]; //El.All[i];
        //M1.Lines.Add(i.ToString + ': ' + tdi.TagName + ' = "' + tdi.Inner + '"');
      end;
      M1.Lines.Add(i.ToString + ': ' + tds[0].Inner + ' = "' + tds[2].Inner.Trim + '"');
    end;
  end;
  MainDoc.Free;
end;
{
5: "td" = <div class="progress" style="height: 7px;">
    <div class="progress-bar bg-success" role="progressbar" style="width: 100%" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100"></div>
</div>
<span class="text-success">100% (350&nbsp;/&nbsp;350)</span>
:
0: "<td class="text-center">"
}
procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
Var
  i, p: Integer;
  ip, json, HTML, S: String;
  //Doc2: IHTMLDocument2;
  WS: WideString;
  Doc: Variant;
  Started: TDateTime;
  all: TStrings;
  SL: TStringList;
begin
  p := Integer(Key);
  If p = 24 then //M1.Lines.Add('Ctrl-X')
  else If p = 26 then //M1.Lines.Add('Ctrl-Z')
  else If p = 3 then begin
    //M1.Lines.Add('Ctrl-С');
  end else If p = 22 then begin
    //M1.Lines.Add('Ctrl-V');
  end else If p = 13 then begin
    //M1.Lines.Add('Ctrl-M');
  end else If p = 10 then begin
    M1.Lines.Add('Ctrl-J');
  end else If p = 17 then begin
    M1.Lines.Add('Ctrl-Q');
    json := GetByApi( M1.Lines, '173.170.204.137', WB1); //, '');
    // {"ip":"217.107.124.85","country":"Russian Federation","cc":"RU"}
    M1.Lines.Add('GetByApi() => "' + json + '"');
    // GetByApi() => "217.107.124.85"
  end else If p = 23 then begin
    M1.Lines.Add('Ctrl-W');
    //Started := Now; Sleep(1000);
    //M1.Lines.Add(FormatDateTime('hh:nn:ss', SecondsBetween(Started, Now) / SecsPerDay));
    // 00:00:01
    CtrlW;
  end else If p = 5 then begin
    M1.Lines.Add('Ctrl-E');
    //HTML := '<tbody><tr><td>td</td><td>td</td></tr></tbody>';
    //HTML := '<div class="progress-bar bg-success" role="progressbar" style="width: 100%" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100"></div>';
    //S := ElHead( HTML);
    //M1.Lines.Add('ElHead(' + HTML + ')=' + ElHead(HTML));
    // =div class="progress-bar bg-success" role="progressbar" style="width: 100%" aria-valuenow="100" ...
    // ElHead(<tbody><tr><td>td</td><td>td</td></tr></tbody>)=tbod
    //Exit;
    SL := TStringList.Create; SL.DefaultEncoding := TEncoding.UTF8;
    SL.LoadFromFile('GetByApi.html'); HTML := SL.Text;
    // <!DOCTYPE html> : MatchText( S, voidHTMLtags)
    all := getAll( HTML); //, M1.Lines);
    M1.Lines.Add('HTML(GetByApi.html).all = ' + IntToStr(all.Count));
    // HTML(GetByApi.html).all = 591
    for i := 0 to all.Count-1 do
      // 589: "<table class="table table-sm table-responsive-md table-hover">
      If (ElTag(all[i]) = 'table') then // 589: table class="table table-sm table-responsive-md table-hover"
        //M1.Lines.Add('table: ' + ElAttr(all[i],'class'))
        M1.Lines.Add(i.ToString + ': table class="' + ElAttr(all[i],'class') + '"')
      // 588: "<tbody>
      else if (ElTag(all[i]) = 'tbody') then // 588: tbody class=""
        M1.Lines.Add(i.ToString + ': tbody class="' + ElAttr(all[i],'class') + '"')
      // 590: "<body class="no-js"><div class="main-wrapper" role="main">
      else if (ElTag(all[i]) = 'body') then // 590: body class="no-js"
        M1.Lines.Add(i.ToString + ': body class="' + ElAttr(all[i],'class') + '"')
      else M1.Lines.Add(i.ToString + ': "' + (all[i]) + '"');
    all.Free;
    SL.Free;
  end else If p = 18 then begin
    M1.Lines.Add('Ctrl-R');
  end else If p = 20 then begin
    M1.Lines.Add('Ctrl-T');
  end else If p = 25 then begin
    M1.Lines.Add('Ctrl-Y');
  end else If p = 21 then begin
    M1.Lines.Add('Ctrl-U');
  end else If p = 9 then begin
    M1.Lines.Add('Ctrl-I');
  end else If p = 15 then begin
    M1.Lines.Add('Ctrl-O');
  end else If p = 16 then begin
    M1.Lines.Add('Ctrl-P');
  end else If p = 2 then begin
    M1.Lines.Add('Ctrl-B');
  end else If p = 14 then begin
    M1.Lines.Add('Ctrl-N');
  end else If p = 11 then begin
    M1.Lines.Add('Ctrl-K');
  end else If p = 12 then begin
    M1.Lines.Add('Ctrl-L');
  end else If p = 1 then begin
    //M1.Lines.Add('Ctrl-A');
  end else If p = 19 then begin
    M1.Lines.Add('Ctrl-S');
    doStopIt := not doStopIt;
    M1.Lines.Add('doStopIt = ' + BoolToStr( doStopIt,True));
  end else If p = 4 then begin
    M1.Lines.Add('Ctrl-D');
    //Doc2 := _GetDoc( myip, M1.Lines, '185.162.228.86'); //PrxLst[i]);
    //Doc2 := _GetDoc( toip, M1.Lines); // Ваш IP адрес: 217.107.124.85
    Doc2 := _GetDoc( toip, M1.Lines, '173.170.204.137'); //'172.67.171.197'); //'172.67.167.202'); //'172.67.180.5'); //'104.16.108.45');
    WS := Doc2.title;
    M1.Lines.Add('DEBUG: ' + toip + ' - Doc2.title = "' + WS + '"');
    If WS = '' then else ParseAs2ip;
    //WB1.Document := Doc2; // [dcc64 Error] MainUnit.pas(486): E2129 Cannot assign to a read-only property
    WB1.Silent := True;
    if NOT Assigned(WB1.Document) then WB1.Navigate('about:blank');
    Doc := WB1.Document;
    Doc.Clear;
    Doc.Write(DocHTML); //(Doc2.body.innerHTML); //(HTMLCode);
    // "Error 1001. DNS resolution error. Please enable cookies."
    Doc.Close;
    //WB1.OleObject;
    //M1.Lines.Add('DocHTML: ' + IntToStr(Length(DocHTML)) + ' = "' + DocHTML + '"');
    // Proxy => DocHTML: 0 = ""
  end else If p = 6 then begin
    M1.Lines.Add('Ctrl-F');
  end else If p = 7 then begin
    M1.Lines.Add('Ctrl-G');
  end else If p = 8 then begin
    M1.Lines.Add('Ctrl-H');
  end else M1.Lines.Add('FormKeyPress(' + Key + ') = ' + p.ToString);
end;
{ Doc2 := _GetDoc( toip, M1.Lines, '173.170.204.137'):::
Ваш IP адрес:
173.170.192.181
173.170.1...
Пожалуйста, отключите AdBlock, чтобы отобразить IP-адрес целиком
Имя вашего компьютера:
173-170-192-181.res.spectrum.com
Операционная система:
неизвестно
Ваш браузер:
Internet Explorer
Обновить? Ваше местоположение:
Спринг-Хилл, США Уточнить? Ваш провайдер:
Road runner holdco
Прокси:
Не используется Уточнить?
Защита данных:
Отсутствует Исправить?
---------------------------------
Ctrl-D
_GetDoc( https://myip.ru/ ): 1
CATCHED: Exception EIdConnClosedGracefully: Connection Closed Gracefully.
_GetDoc( https://myip.ru/ ): 1
DEBUG: https://myip.ru/ - Doc2.title = "DNS resolution error | myip.ru | Cloudflare"
Ctrl-D
_GetDoc( https://myip.ru/ ): 1
Exception EIdHTTPProtocolException: HTTP/1.1 400 Bad Request
_GetDoc( https://myip.ru/ ): 2
Exception EIdHTTPProtocolException: HTTP/1.1 400 Bad Request
_GetDoc( https://myip.ru/ ): 3
Exception EIdHTTPProtocolException: HTTP/1.1 400 Bad Request
DEBUG: https://myip.ru/ = ""
...
FormKeyPress(Ctrl-{) = 27
FormKeyPress(Ctrl-)) = 29
}
Procedure TMainForm.ParseAs2ip; // Doc2
Var
  WS: WideString;
  iElement: IHtmlElement;
  i, len: Integer;
Begin
  WS := Doc2.title;
  M1.Lines.Add('ParseAs2ip(): ' + toip + ' - Doc2.title = "' + WS + '"');
  // ParseAs2ip(): https://2ip.ru/ - Doc2.title = "Узнать IP адрес"
  If Doc2.QueryInterface( IHTMLDocument3, Doc3) <> 0 then Exit;
  //Doc3.getElementsByName('WideString');
  //Doc3.getElementById('WideString');
  //Doc3.getElementsByTagName('WideString');
  If Doc2.QueryInterface( IHTMLDocument7, Doc7) <> 0 then Exit;
  // <form method="post" action="https://ru.proxy-tools.com/proxy/download" class="pt-3 border-top border-secondary">
  col := Doc7.getElementsByClassName('ip');
  len := col.length;
  M1.Lines.Add('class("ip").length = ' + IntToStr(len));
  If len > 0 then begin
    iElement := col.Item(0,0) as IHtmlElement;
    M1.Lines.Add('ip = ' + iElement.innerText);
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
{
ParseAs2ip(): https://2ip.ru/ - Doc2.title = "Узнать IP адрес"
class("ip").length = 1
ip = 173.170.204.137
}
end.

