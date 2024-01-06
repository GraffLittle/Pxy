unit HTMLDocClass;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, //XMLDoc, XMLIntf, //GlobalsUnit,
  System.Generics.Collections, System.Generics.Defaults;
  //Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  //Vcl.OleCtrls, SHDocVw;
// -------------------------
type
  PPat = ^TPat;
  TPat = record
    data: integer;
  end;
var
  AList: TList<PPat>;
// -------------------------
type
  THTMLElement = class;
  TElArr = Array of THTMLElement;
  TElList = TList<THTMLElement>;

  THTMLElement = class(TObject)
    Constructor CreateEmpty( Owner: TObject);
    Destructor Destroy; override;
  private
    { Private declarations }
    //Procedure GetDoc( url: String); // url => idoc
    //Procedure CtrlW;
    Procedure All2All; // anAll: TStrings => FAll: TElList
    //Function GetParent: THTMLElement;
  protected
    { Protected declarations }
    anOwner: TObject;
    anHTML: String;
    anAll: TStrings;
    FAll: TElList;
    AllCnt: Integer;
    anTag: String;
    anInner: String;
    anClass: String;
    anHead: String;
    anAttrs: TStrings;
    //Function GetTag: String;
    Function GetInner: String;
    Procedure GetHeadAttrs;
    //Function getChilds: TElList;
  public
    { Public declarations }
    Constructor CreateByHTML( HTML: String);
//Property Name : Type Index Constant read Getter write Setter {default : Constant|nodefault;} {stored : Boolean};
    Property All: TElList read FAll;
    Property AllCount: Integer read AllCnt;
    Property HTML: String read anHTML;
    Property TagName: String read anTag;
    Property Inner: String read anInner;
    Function getElementsByTagName( TN: String): TElList;
    Function getElementsByClassName( CN: String): TElList;
    Property ClassName: String read anClass;
    Property Head: String read anHead;
    Property Attrs: TStrings read anAttrs;
  end;

  THTMLDoc = class(THTMLElement)
    Constructor CreateEmpty( Owner: TObject);
    Destructor Destroy;
  private
    { Private declarations }
    anURL: String;
    FTitle: String;
    //Procedure GetDoc( url: String); // url => idoc
    //Procedure CtrlW;
    Function GetTitle: String;
  protected
    { Protected declarations }
  public
    { Public declarations }
    Constructor CreateByHTML( HTML: String); //override;
    Constructor CreateByURL( URL: String; pip: String = '');
//Property Name : Type Index Constant read Getter write Setter {default : Constant|nodefault;} {stored : Boolean};
    Property Title : String read FTitle;
  end;

var
  MainDoc: THTMLDoc = nil;

Procedure DebugLines4Doc( Lines: TStrings);

implementation

Uses MSHTMLbyString, GlobalsUnit,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdCompressorZLib, IdException, IdCookieManager, IdCookie,
  System.JSON, MSHTML, activex, ComObj, Vcl.OleCtrls, SHDocVw;
  //Generics.Defaults, Generics.Collections,
{
  IdAntiFreezeBase, IdBuffer, IdBaseComponent, IdComponent, IdGlobal, IdExceptionCore,
  IdIntercept, IdResourceStringsCore, IdStream;
}
Const
  NulStr = '';

Var
  anId: TIdHTTP = nil;
  SSL1: TIdSSLIOHandlerSocketOpenSSL = nil;
  dbgLines: TStrings = nil;
  {
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
  }
// ------------------- Commons -------------------------------------------------
Procedure DebugLines4Doc( Lines: TStrings);
Begin
  dbgLines := Lines;
End;
// ------------------- THTMLElement ------------------------------------------------
Constructor THTMLElement.CreateEmpty( Owner: TObject);
Begin
  inherited Create;
  anOwner := Owner;
  anHTML := '';
  anAll := nil;
  AllCnt := 0;
  self.anTag := '';
  self.anInner := '';
  self.anClass := '';
End;

Destructor THTMLElement.Destroy;
Begin
  FreeAndNil(anAll);
  FAll.Free;
  inherited Destroy;
End;

Constructor THTMLElement.CreateByHTML( HTML: String);
Begin
  CreateEmpty(nil);
  self.anHTML := HTML;
  self.anAll := getAll(HTML);
  All2All;
  self.anTag := ElTag(anHTML);
  self.anInner := GetInner;
  GetHeadAttrs;
  self.anClass := anAttrs.Values['class'].Trim(['"']);
End;

Procedure THTMLElement.All2All; // anAll: TStrings => FAll: TElList
Var
  i: Integer;
Begin
  AllCnt := anAll.Count; //Length();
  FAll := TList<THTMLElement>.Create; //(self.anAll);
  For i := 0 to AllCnt-1 do FAll.Add(THTMLElement.CreateByHTML(anAll[i]));
End;

Function THTMLElement.GetInner: String;
Begin
  Result := ElInnerHTML(anHTML);
End;

Procedure THTMLElement.GetHeadAttrs;
Var
  arr: TArray<string>;
Begin
  anAttrs := TStringList.Create;
  self.anHead := ElHead(anHTML);
  arr := anHead.Split([' '],'"');
  //Assert( arr[0] = ElTag(Element), 'arr[0] = ElTag(Element)');
  //var len := Length(arr);
  //anAttrs.Assign(arr);
  // [dcc64 Error]: E2010 Incompatible types: 'TPersistent' and 'TArray<string>'
  anAttrs.AddStrings(arr);
  //anAttrs.NameValueSeparator; == '='
  //Result := anAttrs.Values[attr].Trim(['"']);
End;

Function THTMLElement.getElementsByTagName( TN: String): TElList;
Var
  i: Integer;
  eli: THTMLElement;
Begin
  //Result := nil;
  Result := TElList.Create; //(self.anAll);
  var ltn := TN.ToLower;
  For i := 0 to FAll.Count-1 do begin
    eli := FAll[i];
    var ltg := eli.anTag.ToLower;
    If ltg = ltn then //Result.Add(THTMLElement.CreateByHTML(FAll[i].anHTML));
      Result.Add(eli);
  end;
End;

Function THTMLElement.getElementsByClassName( CN: String): TElList;
Var
  i: Integer;
Begin
  //Result := nil;
  Result := TElList.Create; //(self.anAll);
  For i := 0 to FAll.Count-1 do
    If FAll[i].anClass = CN then //Result.Add(THTMLElement.CreateByHTML(FAll[i].anHTML));
      Result.Add(FAll[i]);
End;
// ------------------- THTMLDoc ------------------------------------------------
Constructor THTMLDoc.CreateEmpty( Owner: TObject);
Begin
  inherited CreateEmpty(Owner);
  anURL := '';
End;

Destructor THTMLDoc.Destroy;
Begin
  inherited Destroy;
End;

Constructor THTMLDoc.CreateByHTML( HTML: String); //override;
Begin
  inherited CreateByHTML(HTML);
  //anHTML := HTML;
  //anAll := getAll( HTML);
  self.FTitle := GetTitle;
End;

Constructor THTMLDoc.CreateByURL( URL: String; pip: String = '');
Begin
  //CreateEmpty(nil);
  inherited Create;
  anURL := URL;
  If dbgLines <> nil then
    dbgLines.Add('THTMLDoc.CreateByURL("' + URL + '","' + pip + '"):');
  If pip = '' then anId := CreateId else anId := CreateProxyId(pip);
  anHTML := anId.Get(URL);
  anId.Free;
  CreateByHTML(anHTML);
End;

Function THTMLDoc.GetTitle: String;
Var
  //HTML: String;
  i: Integer;
Begin
  Result := '';
  For i := 0 to FAll.Count-1 do
    //dbgLines.Add(i.ToString + ': ' + MainDoc.All[i].TagName);
    If FAll[i].TagName.ToLower = 'title' then Exit(FAll[i].Inner);
End;

end.
