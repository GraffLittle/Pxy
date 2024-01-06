object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Try Proxy'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Constraints.MinHeight = 300
  Constraints.MinWidth = 500
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 337
    Top = 49
    Height = 244
    ExplicitLeft = 320
    ExplicitTop = 192
    ExplicitHeight = 100
  end
  object Splitter2: TSplitter
    Left = 0
    Top = 293
    Width = 624
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitLeft = 337
    ExplicitTop = 49
    ExplicitWidth = 247
  end
  object TopPnl: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 49
    Align = alTop
    Caption = 'TopPnl'
    ShowCaption = False
    TabOrder = 0
    ExplicitWidth = 622
    object IdHTTPBtn: TButton
      Left = 16
      Top = 13
      Width = 57
      Height = 25
      Caption = 'IdHTTP'
      TabOrder = 0
      OnClick = IdHTTPBtnClick
    end
    object HTTPSendBtn: TButton
      Left = 79
      Top = 13
      Width = 75
      Height = 25
      Caption = 'HTTPSend'
      TabOrder = 1
      OnClick = HTTPSendBtnClick
    end
    object ThreadBtn: TButton
      Left = 160
      Top = 13
      Width = 65
      Height = 25
      Caption = 'Thread'
      TabOrder = 2
      OnClick = ThreadBtnClick
    end
    object DocBtn: TButton
      Left = 272
      Top = 13
      Width = 83
      Height = 25
      Caption = 'THTMLDoc'
      TabOrder = 3
      OnClick = DocBtnClick
    end
  end
  object M1: TMemo
    Left = 0
    Top = 296
    Width = 624
    Height = 145
    Align = alBottom
    Lines.Strings = (
      'M1')
    ScrollBars = ssBoth
    TabOrder = 1
    ExplicitTop = 288
    ExplicitWidth = 622
  end
  object SG1: TStringGrid
    Left = 0
    Top = 49
    Width = 337
    Height = 244
    Align = alLeft
    TabOrder = 2
    ExplicitHeight = 236
  end
  object WB1: TWebBrowser
    Left = 352
    Top = 55
    Width = 264
    Height = 150
    TabOrder = 3
    ControlData = {
      4C000000D4150000670C00000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126208000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
end
