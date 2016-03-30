unit clsKeyboard;

interface

uses
  sysUtils,
  windows;

type

  cKeyboard = class
  public
    class function isAltDown: boolean;
    class function isShiftDown: boolean;
    class function isCtrlDown: boolean;
  end;

implementation

{ cKeyboard }

class function cKeyboard.isAltDown: boolean;
var
  state : tKeyboardState;
begin
  getKeyboardState(State);
  result := ((state[VK_MENU] and 128) <> 0);
end;

class function cKeyboard.isCtrlDown: boolean;
var
  state : tKeyboardState;
begin
  getKeyboardState(State);
  result := ((state[VK_CONTROL] and 128) <> 0);
end;

class function cKeyboard.isShiftDown: boolean;
var
  state : tKeyboardState;
begin
  getKeyboardState(State);
  result := ((state[VK_SHIFT] and 128) <> 0);
end;

end.
