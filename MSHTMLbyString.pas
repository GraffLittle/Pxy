unit MSHTMLbyString;
//TODO: use Regular Expressions here
interface

Uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdCompressorZLib, IdException, IdCookieManager, IdCookie,
  System.JSON, MSHTML, activex, ComObj, Vcl.OleCtrls, SHDocVw, System.StrUtils;
  //Generics.Defaults, Generics.Collections,
{
  IdAntiFreezeBase, IdBuffer, IdBaseComponent, IdComponent, IdGlobal, IdExceptionCore,
  IdIntercept, IdResourceStringsCore, IdStream;
}
Function ExBtwn(const str, s1, s2: String; const w12: Boolean = false): String;
Function getElementsByTagName(const str, tag: String): TStrings;
Function ElTag(const Element: String): String;
Function ElInnerHTML(const Element: String): String;
Function ElHead(const Element: String): String;
Function ElAttr(const Element: String; const attr: String): String;
Function getAll(var Element: String; Lines: TStrings = nil): TStrings;

implementation

Uses GlobalsUnit, System.Generics.Collections, System.Generics.Defaults;

// -------------- HTML tags ----------------------------------------------------
Const
  tags: Array of String = ['1','2','3'];
  HTMLtags: Array of String = [ // NOT ALL!
'a','b','br','body','button',
'col','canvas','caption','center',
'div',
'embed',
'form','frame',
'hr','h1','h2','h3','h4','h5','h6','head','html',
'img','input','iframe','ins',
'keygen',
'link','li',
'menuitem','meta','map','menu','mark',
'noscript',
'object','ol','option',
'param','p','pre',
'source','script','section','select','span','strong','style','sub','sup',
'track','table','tbody','td','tr','th','textarea','tfoot','thead','title','tr',
'u','ul','wbr'
  ];
  voidHTMLtags: Array of String = [ '!DOCTYPE',
  // Comment: !-- = <!-- Global site tag (gtag.js) - Google Analytics -->
  '!--',
'area',
'base',
'br',
'col',
'embed',
'hr',
'img',
'input',
'keygen',
'link',
'menuitem',
'meta',
'param',
'source',
'track',
'wbr'
  ];
{ JUSTSO: }
type
  TNumber   = (Ace, One, Two, Three, Four, Five, Siz, Seven, Eight,
  Nine, Ten, Jack, Queen, King);
var
  CourtCards: Set of TNumber;      // Масти карт
  CardNumbers : array[1..4] of TNumber;
  A: set of Char;
// A:=['A','B','K'..'N','R','X'..'Z'];
// if 'D' in A then ShowMessage('Элемент В находится во множестве A.');
procedure FormCreate(Sender: TObject);
type
  TEmpty = record end;
var
  MySet: TDictionary<String, TEmpty>;
  Dummy: TEmpty;
begin
  MySet := TDictionary<String, TEmpty>.Create;
  try
    MySet.Add('Str1', Dummy);
    MySet.Add('Str2', Dummy);
    MySet.Add('Str3', Dummy);
    if MySet.TryGetValue('Str2', Dummy) then
      ShowMessage('Exists');;
  finally
    MySet.Free;
  end;
end;
// TOSEE: https://stackoverflow.com/questions/3150858/set-of-string
{
function MatchStr(const AText: string; const AValues: array of string): Boolean; overload;
MatchStr determines if any of the strings in the array AValues match the string
specified by AText using a case sensitive comparison.
It returns true if at least one of the strings in the array match,
or false if none of the strings match.
For a case insensitive match, use the MatchText routine.
}
Function _isTag( S: String): Boolean;
var
  mySet: TStringList;
Begin
  mySet := TStringList.Create;
  try
    mySet.Add('a');
    mySet.Add('b');
    mySet.Add('c');
    if mySet.IndexOf(S) <> -1 Then ShowMessage('Exists');
  finally
    mySet.Free;
  end;

  if MatchText( 'sLanguages', ['fr-FR', 'en-GB', 'de-DE', 'it-IT', 'fr-CH', 'es-ES']) then
    Writeln('found');
End;

Function isTag( S: String): Boolean;
Begin
  Result := MatchText( S, voidHTMLtags) or MatchText( S, HTMLtags);
End;
// -------------- end:  HTML tags ----------------------------------------------
// Extract string between s1 - s2 in str: w12 == result With s1, s2
Function ExBtwn(const str, s1, s2: String; const w12: Boolean = false): String;
Var
  //i, p, p1, p2, len, l1, l2, cnt: Integer;
  p1, p2, l1, l2: Integer;
Begin
  Result := '';
  l1 := Length(s1); l2 := Length(s2);
  p1 := str.IndexOf(s1);
  p2 := str.IndexOf( s2, p1 + l1);
  If w12 then Result := str.Substring( p1, p2-p1+l2)
  else Result := str.Substring( p1+l1, p2-p1-l1);
End;
  //Doc3.getElementsByName('WideString');
  //Doc3.getElementById('WideString');
  //Doc3.getElementsByTagName('WideString');
  //col := Doc7.getElementsByClassName('ip');

// Extract entire tag element: sp == start position
// Вложенность <div><div>...</div></div> не проверяется!
Function ExTag(const str, tag: String; sp: Integer; var res: String): Integer;
//Var
  //i, p, p1, p2, len, l1, l2, cnt: Integer;
  //ft: String; // Full Tag == "<tag>"
Begin
  //Result := -1;
  //l1 := Length(str); l2 := Length(tag);
  var ft := '<' + tag + '>'; // full tag
  var ts := '<' + tag + ''; // tag start
  var te := '</' + tag + '>'; // tag end
  var l2 := Length(te);
  //p := str.IndexOf(tag);
  var p1 := str.IndexOf(ts,sp);
  If p1 < 0 then Exit(-1);
  var p2 := str.IndexOf(te,p1);
  If p2 < 0 then begin
    p2 := str.IndexOf('>',p1);
    res := str.Substring( p1, p2-p1+1);
    Exit(p2);
  end;
  res := str.Substring( p1, p2-p1+l2);
  Result := p2+l2;
End;
// MAYBE: Element == <meta name="robots" content="noindex,nofollow">

// Extracts <tag> list in str
Function getElementsByTagName(const str, tag: String): TStrings;
Var
  //i, p, p1, p2, len, l1, l2, cnt: Integer;
  p: Integer;
  res: String;
Begin
  Result := TStringList.Create;
  p := 0; //p2 := 0;
  Repeat
    p := ExTag( str, tag, p, res);
    //If p < 0 then Exit;
    //Result.Add(res);
    If p > 0 then Result.Add(res);
    Application.ProcessMessages;
  Until (p < 0) or doStopIt; //(p1 < 0) or (p2 < 0);
End;

// Extract Element TAG
Function ElTag(const Element: String): String;
Begin
  Result := '';
  If Element[1] <> '<' then Exit;
  //var p1 := Element.IndexOf('>');
  //var spp := Element.IndexOf(' ');
  //If spp > 0 then ;
  var ep := Element.IndexOfAny(['>',' ']); // end position
  If ep < 0 then Exit;
  Result := Element.Substring( 1, ep-1);
End;

// Extract Element.innerHTML
Function ElInnerHTML(const Element: String): String;
Var
  //i, p, p1, p2, len, l1, l2, cnt: Integer;
  p1, p2: Integer;
Begin
  Result := '';
  If Element[1] <> '<' then Exit;
  p1 := Element.IndexOf('>');
  If p1 = Element.Length-1 then Exit;
  var tag := ElTag(Element);
  //var ep := Element.IndexOfAny(['>','</'+tag+'>']); // end position
  var te := '</' + tag + '>'; // tag end
  //l2 := Length(te);
  p2 := Element.IndexOf( te, p1);
  If p2 < 0 then Exit; // NO InnerHTML (Result == '')
  //p2 := Element.IndexOf('>',p1);
  Result := Element.Substring( p1+1, p2-p1-1); // +tag.Length
End;

Function ElHead(const Element: String): String;
Begin
  Result := '';
  If Element[1] <> '<' then Exit;
  var p1 := Element.IndexOf('>');
  Result := Element.Substring( 1, p1-1);
End;

// Extract Element attribute
Function ElAttr(const Element: String; const attr: String): String;
Var
  arr: TArray<string>;
  SL: TStringList;
Begin
  Result := '';
  If Element[1] <> '<' then Exit;
  //var p1 := Element.IndexOf('>');
  //var head := Element.Substring( 1, p1-2);
  var head := ElHead(Element);
  //var spp := Element.IndexOf(' ');
  //If spp > 0 then ;
  //var ep := Element.IndexOfAny(['>',' ']); // end position
  //If ep < 0 then Exit;
  //Result := Element.Substring( 1, ep-1);
  arr := head.Split([' '],'"');
  Assert( arr[0] = ElTag(Element), 'arr[0] = ElTag(Element)');
  var len := Length(arr);
  SL := TStringList.Create; //(arr);
  //SL.Assign(arr);
  // [dcc64 Error]: E2010 Incompatible types: 'TPersistent' and 'TArray<string>'
  SL.AddStrings(arr);
  //SL.NameValueSeparator; == '='
  Result := SL.Values[attr].Trim(['"']);
End;

// Extracts Element.ALL elements list
Function getAll(var Element: String; Lines: TStrings = nil): TStrings;
Var
  i, p, p1, p2, len, l1, l2, cnt, cur: Integer;
  El, eli, tag, elcur: String;
  Els: TStringList;
  LS: TList<String>; //TList<integer>;
  stack: TStack<string>; // Стек
  // stack.Push('Алексей'); stack.Count; stack.Peek; stack.Pop; stack.Clear;
  // for item in stack do WriteLn(item);
  queue: TQueue<string>; // Очередь
  // queue.Enqueue('Алексей'); queue.Count; queue.Peek; queue.Dequeue; queue.Clear;
  // for item in queue do WriteLn(item);
  closing: Boolean;
  Function gw( d: Integer = 1): String; // GetWord() from El[i+d]
  Var k: Integer;
  begin
    Result := ''; k := i + d;
    While (k < len) and (El[k] <> ' ') and (El[k] <> Char(13))
      and (El[k] <> Char(10)) and (El[k] <> '>') do
        begin Result := Result+El[k]; Inc(k); end;
  end;
  Function s2s: String; // Stack to String
  Var item: String; sl: TStringList;
  begin
    //for item in stack do Result := Result + item;
    sl := TStringList.Create;
    for item in stack do sl.Add(item);
    Result := sl.CommaText; sl.Free;
  end;
Begin
  Result := TStringList.Create;
  Els := TStringList.Create;
  cnt := 0; i := 1; cur := 0;
  El := Element.Trim;
  len := El.Length;
  stack := TStack<string>.Create;
  closing := False;
  // '!DOCTYPE' : MatchText( S, voidHTMLtags)
  Repeat // TODO: isTag()
    If El[i] = '<' then begin
      Inc(cnt);
      eli := '<';
      If El[i+1] = '/' then begin // закрывающий тег
        tag := gw(2);
        If Lines <> nil then Lines.Add('tag = "/' + tag + '"'); // MAYBE: tag = "div", tag = "/div"
        closing := True;
        Els[cur] := Els[cur] + '<';
      end else begin
        tag := gw;
        If Lines <> nil then Lines.Add('tag = "' + tag + '"'); // MAYBE: tag = "div", tag = "/div"
        If MatchText( tag, voidHTMLtags) then begin
          stack.Push(tag);
          closing := True;
        end else closing := False;
        //Els[cur] := Els[cur] + '<';
        Els.Add('<');
        cur := Els.Count - 1;
      end;
      //If closing then //If tag[1] = '/' Then
        //if stack.Peek = tag.Substring(1) then stack.Extract else
        //if stack.Peek = tag then stack.Extract else
      //Else stack.Push(tag);
      // stack = "TStack<System.string>"
      //Lines.Add('stack = "' + stack.ToString + '"'); //stack.ToArray; stack.List;
      If Lines <> nil then Lines.Add('stack = "' + s2s + '"');
      // stack = "tdtddivtddivdivtddivtdtdspantd" // stack = "td,div"; stack = "td,span"
    end else If El[i] = '>' then begin
      Dec(cnt);
      eli := eli + '>';
      //tag := gw;
      //If cur >= 0 then Els[cur] := Els[cur] + '>';
      Els[cur] := Els[cur] + '>';
      If Lines <> nil then Lines.Add('(Els[' + cur.ToString + ']) = ' + Els[cur]);
      //Result.Add(Els[cur]);
      If closing then begin
        elcur := Els[cur];
        Result.Add(elcur);
        Els.Delete(cur);
        cur := Els.Count - 1;
        // <!DOCTYPE html>
        //If stack.IsEmpty then ; => If stack.Count = 0 then ;
        if stack.Peek = tag then stack.Extract else ;
        //stack.Extract;
        closing := False;
        If cur >= 0 then Els[cur] := Els[cur] + elcur;
      end Else stack.Push(tag);
      If Lines <> nil then Lines.Add('stack = "' + s2s + '"');
    end else begin
      eli := eli + El[i];
      If cur >= 0 then Els[cur] := Els[cur] + El[i];
    end;
    Inc(i);
    //If Lines <> nil then Lines.Add(eli);
  //Until (cnt = 0) or (i = len);
  Until (i = len);
  stack.Free;
  Els.Free;
End;

end.

