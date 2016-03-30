unit clsWinControlPopupDecorator;

interface
uses
  forms,
  controls,
  classes,
  messages,
  windows,
  sysUtils,
  math,

  clsApplication,
  clsMulticastEvents;

type
  cWinControlPopupDecorator = class;

  tWinControlPopupDecoratorPopupShowingProc = reference to procedure(aSender: cWinControlPopupDecorator);
  tWinControlPopupDecoratorPopupHidingProc = reference to procedure(aSender: cWinControlPopupDecorator);
  tWinControlPopupDecoratorPopupItemSelectedProc = reference to procedure(aSender: cWinControlPopupDecorator; var aCloseAndFree: boolean);

  tWinControlPopupDecoratorPopupDirection = (pdAutoUp, pdAutoDown, pdUp, pdDown);

  cWinControlPopupDecorator = class
  private
    const

    DEFAULT_POPUP_MIN_HEIGHT = 100;
    DEFAULT_POPUP_MIN_WIDTH  = 100;

    DEFAULT_POPUP_MAX_HEIGHT = 1000;
    DEFAULT_POPUP_MAX_WIDTH  = 1000;

    DEFAULT_POPUP_WIDTH      = 0;
    DEFAULT_POPUP_HEIGHT     = 300;
  private
    fControlClass          : tWinControlClass;
    fControl               : tWinControl;
    fMinPopupHeight        : integer;
    fMaxPopupHeight        : integer;
    fMinPopupWidth         : integer;
    fMaxPopupWidth         : integer;
    fOldControlWndProc     : tWndMethod;

    fPopupWidth            : integer;
    fPopupHeight           : integer;
    fPopupControl          : tWinControl;
    fOldPopupControlWndProc: tWndMethod;
    fPopupShowingProc      : tWinControlPopupDecoratorPopupShowingProc;
    fPopupHidingProc       : tWinControlPopupDecoratorPopupHidingProc;
    fPopupItemSelectedProc : tWinControlPopupDecoratorPopupItemSelectedProc;

    procedure   createControl;
    procedure   destroyControl;

    procedure   popupControlWndProc(var aMessage: tMessage);
    procedure   wndProc(var aMessage: tMessage);
    procedure   restorePopupControlWndProc;
    procedure   checkPopupBounds(aPopupUpPoint, aPopupDownPoint: tPoint; aPopupDirection: tWinControlPopupDecoratorPopupDirection; var aPopupPoint: tPoint);

    procedure   popup(aX, aY: integer); overload;
  public
    procedure   setPopupShowingProc(aPopupShowingProc: tWinControlPopupDecoratorPopupShowingProc);
    procedure   setPopupHidingProc(aPopupHidingProc: tWinControlPopupDecoratorPopupHidingProc);
    procedure   setPopupItemSelectedProc(aPopupItemSelectedProc: tWinControlPopupDecoratorPopupItemSelectedProc);

    procedure   setPopupMinHeight(aMinHeight: integer);
    procedure   setPopupMaxHeight(aMaxHeight: integer);
    procedure   setPopupMinWidth(aMinWidth: integer);
    procedure   setPopupMaxWidth(aMaxWidth: integer);

    procedure   setPopupWidth(aWidth: integer);
    procedure   setPopupHeight(aHeight: integer);

    procedure   setControlClass(aControlClass: tWinControlClass);

    function    getControl: tWinControl; overload;

    procedure   popup(aControl: tWinControl; aPopupDirection: tWinControlPopupDecoratorPopupDirection = pdAutoDown; aMarginX: integer = 0; aMarginY: integer = 1); overload;

    constructor create;
    destructor  destroy; override;

  published
    property    controlClass: tWinControl read getControl;
  end;


implementation

{ cWinControlPopupDecorator }

constructor cWinControlPopupDecorator.create;
begin
  inherited create;

  setPopupMinHeight(DEFAULT_POPUP_MIN_HEIGHT);
  setPopupMinWidth(DEFAULT_POPUP_MIN_WIDTH);

  setPopupMaxHeight(DEFAULT_POPUP_MAX_HEIGHT);
  setPopupMaxWidth(DEFAULT_POPUP_MAX_WIDTH);

  setPopupWidth(DEFAULT_POPUP_WIDTH);
  setPopupHeight(DEFAULT_POPUP_HEIGHT);
end;

destructor cWinControlPopupDecorator.destroy;
begin
  destroyControl;
  inherited;
end;

procedure cWinControlPopupDecorator.createControl;
begin
  destroyControl;
  fControl:= fControlClass.createParented(getDesktopWindow);

  fOldControlWndProc:= fControl.windowProc;
  fControl.windowProc:= wndProc;
end;

procedure cWinControlPopupDecorator.destroyControl;
begin
  restorePopupControlWndProc;
  if assigned(fControl) then begin
    freeAndNil(fControl);
  end;
end;

procedure cWinControlPopupDecorator.setControlClass(aControlClass: tWinControlClass);
begin
  fControlClass:= aControlClass;

  createControl;
end;

procedure cWinControlPopupDecorator.setPopupItemSelectedProc(aPopupItemSelectedProc: tWinControlPopupDecoratorPopupItemSelectedProc);
begin
  fPopupItemSelectedProc:= aPopupItemSelectedProc;
end;

procedure cWinControlPopupDecorator.setPopupHeight(aHeight: integer);
begin
  fPopupHeight:= aHeight;
end;

procedure cWinControlPopupDecorator.setPopupHidingProc(aPopupHidingProc: tWinControlPopupDecoratorPopupHidingProc);
begin
  fPopupHidingProc:= aPopupHidingProc;
end;

procedure cWinControlPopupDecorator.setPopupMaxHeight(aMaxHeight: integer);
begin
  fMaxPopupHeight:= aMaxHeight;
end;

procedure cWinControlPopupDecorator.setPopupMaxWidth(aMaxWidth: integer);
begin
  fMaxPopupWidth:= aMaxWidth;
end;

procedure cWinControlPopupDecorator.setPopupMinHeight(aMinHeight: integer);
begin
  fMinPopupHeight:= aMinHeight;
end;

procedure cWinControlPopupDecorator.setPopupMinWidth(aMinWidth: integer);
begin
  fMinPopupWidth:= aMinWidth;
end;

procedure cWinControlPopupDecorator.setPopupShowingProc(aPopupShowingProc: tWinControlPopupDecoratorPopupShowingProc);
begin
  fPopupShowingProc:= aPopupShowingProc;
end;

procedure cWinControlPopupDecorator.setPopupWidth(aWidth: integer);
begin
  fPopupWidth:= aWidth;
end;

procedure cWinControlPopupDecorator.wndProc(var aMessage: tMessage);
var
  freeNeeded: boolean;
  itemSelected: boolean;
begin
  freeNeeded:= false;
  itemSelected:= false;

  fOldControlWndProc(aMessage);

  case aMessage.msg of
    CM_CANCELMODE: begin
      freeNeeded:= true;
    end;

    WM_LBUTTONUP: begin
      itemSelected:= true;
    end;

    WM_KEYUP: begin
      if (aMessage.wParam = VK_RETURN) then begin
        itemSelected:= true;
      end;
    end;
  end;

  if itemSelected then begin

    if assigned(fPopupItemSelectedProc) then begin
      fPopupItemSelectedProc(self, freeNeeded);
    end;

  end;

  if freeNeeded then begin
    fControl.windowProc:= fOldControlWndProc;

    if assigned(fPopupHidingProc) then begin
      fPopupHidingProc(self);
    end;

    free;
  end;
end;

procedure cWinControlPopupDecorator.popupControlWndProc(var aMessage: tMessage);
const
  VK_NO_KEY_CODE = 0;
begin
  try

    case aMessage.msg of
      CM_CANCELMODE, WM_KILLFOCUS, WM_MOUSEWHEEL, WM_KEYDOWN, WM_KEYUP: begin
        fControl.perform(aMessage.msg, aMessage.wParam, aMessage.lParam);
      end;
    end;

    if (aMessage.msg = WM_KEYDOWN) or (aMessage.msg = WM_KEYUP) then begin
      aMessage.wParam:= VK_NO_KEY_CODE;
    end;

  finally
    fOldPopupControlWndProc(aMessage);
  end;
end;

function cWinControlPopupDecorator.getControl: tWinControl;
begin
  result:= fControl;
end;

procedure cWinControlPopupDecorator.popup(aX, aY: integer);
var
  actualWidth: integer;
  actualHeight: integer;

begin
  actualWidth:= min(fMaxPopupWidth, fPopupWidth);
  actualWidth:= max(actualWidth, fMinPopupWidth);

  actualHeight:= min(fMaxPopupHeight, fPopupHeight);
  actualHeight:= max(actualHeight, fMinPopupHeight);

  fControl.setBounds(aX, aY, actualWidth, actualHeight);

  if assigned(fPopupShowingProc) then begin
    fPopupShowingProc(self);
  end;

  setWindowLong(fControl.handle, GWL_EXSTYLE, WS_EX_TOOLWINDOW or WS_EX_TOPMOST);
  sendMessage(fControl.handle, WM_SETFOCUS, 0, 0);
  setWindowPos(fControl.handle, HWND_TOP, aX, aY, actualWidth, actualHeight, SWP_NOSIZE or SWP_NOACTIVATE or SWP_SHOWWINDOW);

  fPopupControl.setFocus;
  sendMessage(fPopupControl.handle, EM_SETSEL, 0, 0);
  sendMessage(fPopupControl.handle, EM_SCROLLCARET, 0, 0);
end;

procedure cWinControlPopupDecorator.popup(aControl: tWinControl; aPopupDirection: tWinControlPopupDecoratorPopupDirection; aMarginX, aMarginY: integer);
var
  popupUpPoint: tPoint;
  popupDownPoint: tPoint;

  popupPoint: tPoint;
  borderWidth: integer;
  borderHeight: integer;
begin
  restorePopupControlWndProc;

  if not assigned(aControl) then begin
    destroyControl;
    exit;
  end;

  fPopupControl:= aControl;
  fOldPopupControlWndProc:= fPopupControl.windowProc;
  fPopupControl.windowProc:= popupControlWndProc;

  borderWidth:= (fPopupControl.width - fPopupControl.clientWidth) div 2;
  borderHeight:= (fPopupControl.height - fPopupControl.clientHeight) div 2;

  popupUpPoint:= fPopupControl.clientToScreen(point(aMarginX - borderWidth, - (aMarginY + fPopupHeight + borderHeight)));
  popupDownPoint:= fPopupControl.clientToScreen(point(aMarginX - borderWidth, aControl.height + aMarginY));
  case aPopupDirection of
    pdUp, pdAutoUp      : begin
      popupPoint:= popupUpPoint;
    end;
    pdDown, pdAutoDown  : begin
      popupPoint:= popupDownPoint;
    end;
  end;


  case aPopupDirection of
    pdAutoUp, pdAutoDown: checkPopupBounds(popupUpPoint, popupDownPoint, aPopupDirection, popupPoint);
  end;


  if (fPopupWidth = 0) then begin
    fPopupWidth:= fPopupControl.width;
  end;

  popup(popupPoint.x, popupPoint.y);
end;

procedure cWinControlPopupDecorator.checkPopupBounds(aPopupUpPoint, aPopupDownPoint: tPoint; aPopupDirection: tWinControlPopupDecoratorPopupDirection; var aPopupPoint: tPoint);
begin
  case aPopupDirection of
    pdAutoUp      : begin
      if (aPopupPoint.y < 0) then begin
        aPopupPoint:= aPopupDownPoint;
      end;
    end;
    pdAutoDown  : begin
      if (aPopupPoint.y + fPopupHeight > screen.workAreaHeight) then begin
        aPopupPoint:= aPopupUpPoint;
      end;
    end;
  end;
end;

procedure cWinControlPopupDecorator.restorePopupControlWndProc;
begin
  if assigned(fPopupControl) then begin
    fPopupControl.windowProc:= fOldPopupControlWndProc;
  end;
end;

end.
