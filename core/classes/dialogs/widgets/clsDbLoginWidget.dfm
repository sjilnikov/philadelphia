object frmDbLogin: TfrmDbLogin
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  ClientHeight = 131
  ClientWidth = 262
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object pClient: TPanel
    Left = 0
    Top = 0
    Width = 262
    Height = 90
    Align = alClient
    Constraints.MinHeight = 90
    TabOrder = 0
    DesignSize = (
      262
      90)
    object lbLogin: TLabel
      Left = 8
      Top = 19
      Width = 33
      Height = 13
      Caption = 'lbLogin'
    end
    object lbPassword: TLabel
      Left = 8
      Top = 54
      Width = 54
      Height = 13
      Caption = 'lbPassword'
    end
    object lbAttempts: TLabel
      Left = 90
      Top = 74
      Width = 52
      Height = 13
      Caption = 'lbAttempts'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object eLogin: TEdit
      Left = 90
      Top = 16
      Width = 160
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
    object ePassword: TEdit
      Left = 90
      Top = 51
      Width = 160
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      PasswordChar = '*'
      TabOrder = 1
    end
  end
  object pBottom: TPanel
    Left = 0
    Top = 90
    Width = 262
    Height = 41
    Align = alBottom
    TabOrder = 1
    object gPanel: TGridPanel
      Left = 1
      Top = 1
      Width = 260
      Height = 39
      Align = alClient
      BevelOuter = bvNone
      ColumnCollection = <
        item
          Value = 100.000000000000000000
        end>
      ControlCollection = <
        item
          Column = 0
          Control = pButtons
          Row = 0
        end>
      RowCollection = <
        item
          Value = 100.000000000000000000
        end
        item
          SizeStyle = ssAuto
        end>
      TabOrder = 0
      DesignSize = (
        260
        39)
      object pButtons: TPanel
        Left = 37
        Top = 4
        Width = 185
        Height = 30
        Anchors = []
        BevelOuter = bvNone
        Constraints.MinWidth = 185
        TabOrder = 0
        DesignSize = (
          185
          30)
        object sbLogin: TButton
          Left = 15
          Top = 2
          Width = 75
          Height = 25
          Anchors = []
          Caption = 'sbLogin'
          Default = True
          TabOrder = 0
        end
        object sbCancel: TButton
          Left = 94
          Top = 2
          Width = 75
          Height = 25
          Anchors = []
          Caption = 'sbCancel'
          TabOrder = 1
        end
      end
    end
  end
end
