object Frm_MainForm: TFrm_MainForm
  Left = 202
  Top = 134
  Caption = 'Demo - Mongo Delphi Driver'
  ClientHeight = 571
  ClientWidth = 964
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    964
    571)
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 680
    Top = 8
    Width = 284
    Height = 249
    Anchors = [akTop, akRight]
    ParentShowHint = False
    Proportional = True
    ShowHint = True
  end
  object ListView1: TListView
    Left = 8
    Top = 8
    Width = 657
    Height = 481
    Anchors = [akLeft, akTop, akRight]
    Columns = <
      item
        Caption = 'Id'
        Width = 170
      end
      item
        Caption = 'Code'
        Width = 80
      end
      item
        Caption = 'Name'
        Width = 250
      end
      item
        Caption = 'Date'
        Width = 120
      end>
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
    OnClick = ListView1Click
  end
  object btnAdd: TButton
    Left = 24
    Top = 512
    Width = 75
    Height = 25
    Caption = 'Add'
    TabOrder = 1
    OnClick = btnAddClick
  end
  object btnUpdate: TButton
    Left = 112
    Top = 512
    Width = 75
    Height = 25
    Caption = 'Update'
    TabOrder = 2
    OnClick = btnUpdateClick
  end
  object btnRemove: TButton
    Left = 200
    Top = 512
    Width = 75
    Height = 25
    Caption = 'Remove'
    TabOrder = 3
    OnClick = btnRemoveClick
  end
  object btnClear: TButton
    Left = 288
    Top = 512
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 4
    OnClick = btnClearClick
  end
  object btnFind: TButton
    Left = 376
    Top = 512
    Width = 75
    Height = 25
    Caption = 'Find'
    TabOrder = 5
    OnClick = btnFindClick
  end
  object Button1: TButton
    Left = 488
    Top = 512
    Width = 75
    Height = 25
    Caption = 'all'
    TabOrder = 6
    OnClick = Button1Click
  end
end
