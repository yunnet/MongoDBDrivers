object Frm_Find: TFrm_Find
  Left = 331
  Top = 209
  Width = 585
  Height = 212
  Caption = 'Find'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 26
    Top = 47
    Width = 25
    Height = 13
    Alignment = taRightJustify
    Caption = 'Code'
  end
  object Label2: TLabel
    Left = 23
    Top = 79
    Width = 28
    Height = 13
    Alignment = taRightJustify
    Caption = 'Name'
  end
  object Label3: TLabel
    Left = 28
    Top = 111
    Width = 23
    Height = 13
    Alignment = taRightJustify
    Caption = 'Date'
  end
  object Label4: TLabel
    Left = 42
    Top = 15
    Width = 9
    Height = 13
    Alignment = taRightJustify
    Caption = 'Id'
  end
  object Label5: TLabel
    Left = 208
    Top = 42
    Width = 32
    Height = 13
    Caption = 'Label5'
  end
  object edCode: TEdit
    Left = 56
    Top = 40
    Width = 121
    Height = 21
    TabOrder = 1
  end
  object edName: TEdit
    Left = 56
    Top = 72
    Width = 337
    Height = 21
    TabOrder = 2
  end
  object edId: TEdit
    Left = 56
    Top = 8
    Width = 121
    Height = 21
    TabOrder = 0
  end
  object btnFind: TButton
    Left = 56
    Top = 136
    Width = 75
    Height = 25
    Caption = 'Find'
    TabOrder = 3
    OnClick = btnFindClick
  end
  object btnClose: TButton
    Left = 152
    Top = 136
    Width = 75
    Height = 25
    Caption = 'Close'
    ModalResult = 2
    TabOrder = 4
  end
  object edDate: TEdit
    Left = 56
    Top = 104
    Width = 121
    Height = 21
    TabOrder = 5
  end
  object edCode2: TEdit
    Left = 248
    Top = 40
    Width = 121
    Height = 21
    TabOrder = 6
  end
end
