unit clsAbstractViewProxy;

interface
uses
  forms,
  messages,
  windows,
  variants,
  graphics,
  classes,
  controls,
  imgList,
  menus,
  stdCtrls,
  sysUtils,

  clsDebug,
  clsClassKit,
  clsException,
  clsAbstractValidator;

type
  cWinControlPrivate = class(tWinControl)
  published
    property onMouseWheel;
  end;

  eAbstractViewProxy = class(cException);

  cAbstractViewProxy = class;

  cViewProxyClass = class of cAbstractViewProxy;

  tAbstractViewProxyLoseFocusEvent = procedure (aSender: cAbstractViewProxy) of object;

  tAbstractViewProxySelectedItemPaintedEvent = procedure (aSender: cAbstractViewProxy; aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment) of object;
  tAbstractViewProxySelectedItemPaintingEvent = procedure (aSender: cAbstractViewProxy; aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment) of object;
  tAbstractViewProxyMouseEvent = procedure(aSender: cAbstractViewProxy; aButton: tMouseButton; aShift: tShiftState; aX, aY: integer) of object;
  tAbstractViewProxyMouseMoveEvent = procedure(aSender: cAbstractViewProxy; aShift: tShiftState; aX, aY: integer) of object;
  tAbstractViewProxyKeyEvent = procedure(aSender: cAbstractViewProxy; var aKey: word; aShift: tShiftState) of object;
  tAbstractViewProxyKeyPressEvent = procedure(aSender: cAbstractViewProxy; var aKey: char) of object;
  tAbstractViewProxyMouseWheelEvent = procedure(aSender: cAbstractViewProxy; aShift: tShiftState; aWheelDelta: integer; aMousePos: tPoint; var aHandled: boolean) of object;


  tViewSearchDirection = (sdForward, sdBackward);
  tViewSearchPosition = (spFirst, spCurrent, spNextFromCurrent, spPrevFromCurrent, spLast);
  tViewSearchType = (stEntire, stPartial);

  cAbstractViewProxy = class
  private
    fCanTakeFocus             : boolean;
    fSelectedFramePenStyle    : tPenStyle;
    fSelectedFramePenColor    : tColor;
    fCanDrawFrameSelected     : boolean;
    fSelectedFramePenWidth    : integer;
    fSelectedBgColor          : tColor;
    fSelectedTextColor        : tColor;
    fFocusedBgColor           : tColor;
    fFocusedTextColor         : tColor;

    fSelectedRangeBgColor     : tColor;
    fSelectedRangeTextColor   : tColor;
    fFocusedRangeBgColor      : tColor;
    fFocusedRangeTextColor    : tColor;
    fHint                     : string;


    fOnKeyPress               : tAbstractViewProxyKeyPressEvent;
    fOnKeyDown                : tAbstractViewProxyKeyEvent;
    fOnMouseMove              : tAbstractViewProxyMouseMoveEvent;
    fOnMouseWheel             : tAbstractViewProxyMouseWheelEvent;
    fOnMouseDown              : tAbstractViewProxyMouseEvent;

    fOnItemPainting           : tAbstractViewProxySelectedItemPaintingEvent;
    fOnItemPainted            : tAbstractViewProxySelectedItemPaintedEvent;
    fOnLoseFocus              : tAbstractViewProxyLoseFocusEvent;

    fPopupMenu                : tPopupMenu;

    fOldWndProc               : tWndMethod;

    procedure   createPopupMenu;
    procedure   destroyPopupMenu;


    procedure   attachWndProc;
    procedure   detachWndProc;
  protected
    const

    INVALID_CLASS_RECEIVED = 'invalid class received, excepted: %s, got: %s ';

    METHOD_NOT_IMPLEMENTED = 'method %s not implemented';
  protected
    fView       : tWinControl;

    procedure   wndProc(var aMessage: tMessage); virtual;
    procedure   setupViewEvents; virtual;
    procedure   disconnectViewEvents; virtual;

    procedure   selectedItemPainted(aSender: cAbstractViewProxy; aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment);
    procedure   selectedItemPainting(aSender: cAbstractViewProxy; aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment);
  public
    procedure   setImageList(aImageList: tImageList);
    function    getImageList: tCustomImageList;


    procedure   setHint(aHint: string); virtual;

    procedure   setFocusedBgColor(aColor: tColor);virtual;
    function    getFocusedBgColor: tColor;virtual;

    procedure   setFocusedRangeBgColor(aColor: tColor);virtual;
    function    getFocusedRangeBgColor: tColor;virtual;

    procedure   setFocusedTextColor(aColor: tColor);virtual;
    function    getFocusedTextColor: tColor;virtual;

    procedure   setFocusedRangeTextColor(aColor: tColor);virtual;
    function    getFocusedRangeTextColor: tColor;virtual;

    procedure   setSelectedBgColor(aColor: tColor);virtual;
    function    getSelectedBgColor: tColor;virtual;

    procedure   setSelectedRangeBgColor(aColor: tColor);virtual;
    function    getSelectedRangeBgColor: tColor;virtual;

    procedure   setSelectedTextColor(aColor: tColor);virtual;
    function    getSelectedTextColor: tColor;virtual;

    procedure   setSelectedRangeTextColor(aColor: tColor);virtual;
    function    getSelectedRangeTextColor: tColor;virtual;

    procedure   setSelectedFramePenWidth(aWidth: integer);virtual;
    function    getSelectedFramePenWidth: integer;virtual;

    procedure   setSelectedFramePenStyle(aPenStyle: tPenStyle);virtual;
    function    getSelectedFramePenStyle: tPenStyle;virtual;

    procedure   setSelectedFramePenColor(aColor: tColor);virtual;
    function    getSelectedFramePenColor: tColor;virtual;

    procedure   setCanDrawFrameSelected(aValue: boolean);virtual;
    function    canDrawFrameSelected: boolean;virtual;

    procedure   setCanTakeFocus(aValue: boolean); virtual;
    function    canTakeFocus: boolean; virtual;

    function    isEmpty: boolean; virtual; abstract;
    function    getSelectedCount: integer; virtual; abstract;
    function    getCheckedCount: integer; virtual; abstract;

    function    locate(aText: string; aSearchDirection: tViewSearchDirection = sdForward; aSearchPosition: tViewSearchPosition = spFirst; aSearchType: tViewSearchType = stPartial): boolean; virtual; abstract;

    procedure   invalidate;

    procedure   setFocus;

    procedure   setView(aView: tWinControl); virtual;
    function    getView: tWinControl;

    procedure   setPopupImages(aImages: tImageList);

    procedure   setEnabled(aValue: boolean);
    function    isEnabled: boolean;

    procedure   setVisible(aValue: boolean);
    function    isVisible: boolean;

    procedure   setWidth(aValue: integer);
    function    getWidth: integer;
    procedure   setHeight(aValue: integer);
    function    getHeight: integer;

    procedure   setParent(aViewProxy: cAbstractViewProxy); overload;
    procedure   setParent(aWinControl: tWinControl); overload;
    function    getParent: tWinControl;

    function    getMargins: tMargins;
    function    getPadding: TPadding;

    function    getWindowProc: tWndMethod;

    function    getBounds: tRect;
    procedure   setBounds(aRect: tRect);

    procedure   setPopupMenu(aMenu: tPopupMenu);
    function    getPopupMenu: tPopupMenu;

    procedure   selectionToCheck(aValue: boolean); virtual; abstract;


    constructor create;
    destructor  destroy; override;

    property    windowProc: tWndMethod read getWindowProc;
    property    view: tWinControl read getView;
    property    popupMenu: tPopupMenu read getPopupMenu;
  published
    //EVENTS
    property    onSelectedItemPainting: tAbstractViewProxySelectedItemPaintingEvent read fOnItemPainting write fOnItemPainting;
    property    onSelectedItemPainted: tAbstractViewProxySelectedItemPaintedEvent read fOnItemPainted write fOnItemPainted;
    property    onKeyPress: tAbstractViewProxyKeyPressEvent read fOnKeyPress write fOnKeyPress;
    property    onKeyDown: tAbstractViewProxyKeyEvent read fOnKeyDown write fOnKeyDown;

    property    onMouseWheel: tAbstractViewProxyMouseWheelEvent read fOnMouseWheel write fOnMouseWheel;

    property    onMouseMove: tAbstractViewProxyMouseMoveEvent read fOnMouseMove write fOnMouseMove;
    property    onMouseDown: tAbstractViewProxyMouseEvent read fOnMouseDown write fOnMouseDown;

    property    onLoseFocus: tAbstractViewProxyLoseFocusEvent read fOnLoseFocus write fOnLoseFocus;
  published
    //SLOTS
    procedure   loseFocus(aSender: tObject); virtual;
    procedure   keyPress(aSender: tObject; var aKey: char); virtual;
    procedure   keyDown(aSender: tObject; var aKey: word; aShift: tShiftState); virtual;

    procedure   mouseWheel(aSender: tObject; aShift: tShiftState; aWheelDelta: integer; aMousePos: tPoint; var aHandled: boolean); virtual;
    procedure   mouseMove(aSender: tObject; aShift: tShiftState; aX, aY: integer); virtual;
    procedure   mouseDown(aSender: tObject; aButton: tMouseButton; aShift: tShiftState; aX, aY: integer); virtual;
  end;

implementation
uses
  clsMulticastEvents;

{ cEditViewProxy }

function cAbstractViewProxy.canDrawFrameSelected: boolean;
begin
  result:= fCanDrawFrameSelected;
end;

function cAbstractViewProxy.canTakeFocus: boolean;
begin
  result:= fCanTakeFocus;
end;

constructor cAbstractViewProxy.create;
begin
  inherited create;

  fView:= nil;

  createPopupMenu;
end;

procedure cAbstractViewProxy.createPopupMenu;
begin
  fPopupMenu:= tPopupMenu.create(nil);
end;

destructor cAbstractViewProxy.destroy;
begin
  detachWndProc;

  disconnectViewEvents;

  destroyPopupMenu;

  inherited;
end;

procedure cAbstractViewProxy.destroyPopupMenu;
begin
  if assigned(fPopupMenu) then begin
    freeAndNil(fPopupMenu);
  end;
end;

procedure cAbstractViewProxy.setBounds(aRect: tRect);
begin
  if (not assigned(fView)) then exit;

  fView.boundsRect:= aRect;
end;

procedure cAbstractViewProxy.setCanDrawFrameSelected(aValue: boolean);
begin
  fCanDrawFrameSelected:= aValue;
end;

procedure cAbstractViewProxy.setCanTakeFocus(aValue: boolean);
begin
  fCanTakeFocus:= aValue;
end;

procedure cAbstractViewProxy.setEnabled(aValue: boolean);
begin
  if (not assigned(fView)) then exit;

  fView.enabled:= aValue;
end;

procedure cAbstractViewProxy.setFocus;
begin
  if (not(assigned(fView))) then exit;
  fView.setFocus;
end;

procedure cAbstractViewProxy.setFocusedBgColor(aColor: tColor);
begin
  fFocusedBgColor:= aColor;
end;

procedure cAbstractViewProxy.setFocusedRangeBgColor(aColor: tColor);
begin
  fFocusedRangeBgColor:= aColor;
end;

procedure cAbstractViewProxy.setFocusedRangeTextColor(aColor: tColor);
begin
  fFocusedRangeTextColor:= aColor;
end;

procedure cAbstractViewProxy.setFocusedTextColor(aColor: tColor);
begin
  fFocusedTextColor:= aColor;
end;

procedure cAbstractViewProxy.setHeight(aValue: integer);
var
  curRect: tRect;
begin
  if (not(assigned(fView))) then exit;

  curRect:= getBounds;

  curRect.bottom:= curRect.top + aValue;

  setBounds(curRect);
end;

procedure cAbstractViewProxy.setHint(aHint: string);
begin
  fHint:= aHint;
end;

procedure cAbstractViewProxy.setImageList(aImageList: tImageList);
begin
  fPopupMenu.images:= aImageList;
end;

procedure cAbstractViewProxy.setParent(aViewProxy: cAbstractViewProxy);
begin
  if not assigned(aViewProxy) then exit;

  setParent(aViewProxy.getView);
end;

procedure cAbstractViewProxy.setParent(aWinControl: tWinControl);
begin
  if (not(assigned(fView))) then exit;
  fView.parent:= aWinControl;
end;

procedure cAbstractViewProxy.setPopupImages(aImages: tImageList);
begin
  fPopupMenu.images:= aImages;
end;

procedure cAbstractViewProxy.setPopupMenu(aMenu: tPopupMenu);
begin
  if assigned(fPopupMenu) then begin
    destroyPopupMenu;
  end;

  fPopupMenu:= aMenu;
end;

procedure cAbstractViewProxy.setSelectedBgColor(aColor: tColor);
begin
  fSelectedBgColor:= aColor;
end;

procedure cAbstractViewProxy.setSelectedFramePenColor(aColor: tColor);
begin
  fSelectedFramePenColor:= aColor;
end;

procedure cAbstractViewProxy.setSelectedFramePenStyle(aPenStyle: tPenStyle);
begin
  fSelectedFramePenStyle:= aPenStyle;
end;

procedure cAbstractViewProxy.setSelectedFramePenWidth(aWidth: integer);
begin
  fSelectedFramePenWidth:= aWidth;
end;

procedure cAbstractViewProxy.setSelectedRangeBgColor(aColor: tColor);
begin
  fSelectedRangeBgColor:= aColor;
end;

procedure cAbstractViewProxy.setSelectedRangeTextColor(aColor: tColor);
begin
  fSelectedRangeTextColor:= aColor;
end;

procedure cAbstractViewProxy.setSelectedTextColor(aColor: tColor);
begin
  fSelectedTextColor:= aColor;
end;

procedure cAbstractViewProxy.setupViewEvents;
begin
  if (not(assigned(fView))) then exit;

  if cClassKit.propertyExists(fView, 'onKeyPress') then begin
    connect(fView, 'onKeyPress', self, 'keyPress');
  end else begin
    cDebug.write('object class: %s, onKeyPress not exists', [fView.className]);
  end;

  if cClassKit.propertyExists(fView, 'onKeyDown') then begin
    connect(fView, 'onKeyDown', self, 'keyDown');
  end else begin
    cDebug.write('object class: %s, onKeyDown not exists', [fView.className]);
  end;

  if cClassKit.propertyExists(fView, 'onMouseMove') then begin
    connect(fView, 'onMouseMove', self, 'mouseMove');
  end else begin
    cDebug.write('object class: %s, onMouseMove not exists', [fView.className]);
  end;

  if cClassKit.propertyExists(fView, 'onMouseDown') then begin
    connect(fView, 'onMouseDown', self, 'mouseDown');
  end else begin
    cDebug.write('object class: %s, onMouseDown not exists', [fView.className]);
  end;

  if cClassKit.propertyExists(fView, 'onExit') then begin
    connect(fView, 'onExit', self, 'loseFocus');
  end else begin
    cDebug.write('object class: %s, onExit not exists', [fView.className]);
  end;
end;

procedure cAbstractViewProxy.disconnectViewEvents;
begin
  if (not(assigned(fView))) then exit;

  if cClassKit.propertyExists(fView, 'onKeyPress') then begin
    disconnect(fView, 'onKeyPress', self, 'keyPress');
  end;

  if cClassKit.propertyExists(fView, 'onKeyDown') then begin
    disconnect(fView, 'onKeyDown', self, 'keyDown');
  end;

  if cClassKit.propertyExists(fView, 'onMouseMove') then begin
    disconnect(fView, 'onMouseMove', self, 'mouseMove');
  end;

  if cClassKit.propertyExists(fView, 'onMouseDown') then begin
    disconnect(fView, 'onMouseDown', self, 'mouseDown');
  end;

  if cClassKit.propertyExists(fView, 'onExit') then begin
    disconnect(fView, 'onExit', self, 'loseFocus');
  end;
end;


function cAbstractViewProxy.getBounds: tRect;
begin
  result:= rect(0, 0, 0, 0);

  if not assigned(fView) then exit;

  result:= fView.boundsRect;
end;

function cAbstractViewProxy.getFocusedBgColor: tColor;
begin
  result:= fFocusedBgColor;
end;

function cAbstractViewProxy.getFocusedRangeBgColor: tColor;
begin
  result:= fFocusedRangeBgColor;
end;

function cAbstractViewProxy.getFocusedRangeTextColor: tColor;
begin
  result:= fFocusedRangeTextColor;
end;

function cAbstractViewProxy.getFocusedTextColor: tColor;
begin
  result:= fFocusedTextColor;
end;

function cAbstractViewProxy.getHeight: integer;
var
  curRect: tRect;
begin
  result:= 0;
  if not assigned(fView) then exit;

  curRect:= getBounds;
  result:= curRect.bottom - curRect.top;
end;

function cAbstractViewProxy.getImageList: tCustomImageList;
begin
  result:= fPopupMenu.images;
end;

function cAbstractViewProxy.getMargins: tMargins;
begin
  result:= nil;

  if not assigned(fView) then exit;

  result:= fView.margins;
end;

function cAbstractViewProxy.getPadding: TPadding;
begin
  result:= nil;

  if not assigned(fView) then exit;

  result:= fView.padding;
end;

function cAbstractViewProxy.getParent: tWinControl;
begin
  if (not(assigned(fView))) then exit;
  result:= fView.parent;
end;

function cAbstractViewProxy.getPopupMenu: tPopupMenu;
begin
  result:= fPopupMenu;
end;

function cAbstractViewProxy.getSelectedBgColor: tColor;
begin
  result:= fSelectedBgColor;
end;

function cAbstractViewProxy.getSelectedFramePenColor: tColor;
begin
  result:= fSelectedFramePenColor;
end;

function cAbstractViewProxy.getSelectedFramePenStyle: tPenStyle;
begin
  result:= fSelectedFramePenStyle;
end;

function cAbstractViewProxy.getSelectedFramePenWidth: integer;
begin
  result:= fSelectedFramePenWidth;
end;

function cAbstractViewProxy.getSelectedRangeBgColor: tColor;
begin
  result:= fSelectedRangeBgColor;
end;

function cAbstractViewProxy.getSelectedRangeTextColor: tColor;
begin
  result:= fSelectedRangeTextColor;
end;

function cAbstractViewProxy.getSelectedTextColor: tColor;
begin
  result:= fSelectedTextColor;
end;

function cAbstractViewProxy.getView: tWinControl;
begin
  result:= fView;
end;

function cAbstractViewProxy.getWidth: integer;
var
  curRect: tRect;
begin
  result:= 0;
  if not assigned(fView) then exit;

  curRect:= getBounds;
  result:= curRect.right - curRect.left;
end;

function cAbstractViewProxy.getWindowProc: tWndMethod;
begin
  result:= nil;

  if not assigned(fView) then exit;

  result:= fView.windowProc;
end;

procedure cAbstractViewProxy.invalidate;
begin
  if (not assigned(fView)) then exit;
  fView.invalidate;
end;

function cAbstractViewProxy.isEnabled: boolean;
begin
  result:= false;

  if (not assigned(fView)) then exit;

  result:= fView.enabled;
end;

function cAbstractViewProxy.isVisible: boolean;
begin
  result:= false;

  if (not assigned(fView)) then exit;

  result:= fView.visible;
end;

procedure cAbstractViewProxy.selectedItemPainted(aSender: cAbstractViewProxy; aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment);
begin
  if assigned(fOnItemPainted) then begin
    fOnItemPainted(aSender, aCanvas, aRect, aText, aHAlign, aVAlign);
  end;

  if (not canDrawFrameSelected) then begin
    exit;
  end;

  inflateRect(aRect, 0, -1);

  //drawFocusRect(aCanvas.handle, aRect);
  aCanvas.brush.style:= bsClear;

  aCanvas.pen.color:= getSelectedFramePenColor;
  aCanvas.pen.style:= getSelectedFramePenStyle;
  aCanvas.pen.width:= getSelectedFramePenWidth;


  aCanvas.rectangle(aRect);
end;

procedure cAbstractViewProxy.selectedItemPainting(aSender: cAbstractViewProxy; aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment);
begin
  if (not canDrawFrameSelected) then begin
    exit;
  end;

  if assigned(fOnItemPainting) then begin
    fOnItemPainting(aSender, aCanvas, aRect, aText, aHAlign, aVAlign);
  end;
end;

procedure cAbstractViewProxy.detachWndProc;
begin
  if not assigned(fView) then begin
    exit;
  end;

  fView.windowProc:= fOldWndProc;
end;

procedure cAbstractViewProxy.attachWndProc;
begin
  if not assigned(fView) then begin
    exit;
  end;

  fOldWndProc:= fView.windowProc;

  fView.windowProc:= wndProc;
end;

procedure cAbstractViewProxy.setView(aView: tWinControl);
begin
  disconnectViewEvents;
  detachWndProc;

  fView:= aView;
  if (not(assigned(fView))) then exit;

  setupViewEvents;
  attachWndProc;

  //stub
  setParent(aView.parent);
end;

procedure cAbstractViewProxy.setVisible(aValue: boolean);
begin
  fView.visible:= aValue;
end;

procedure cAbstractViewProxy.setWidth(aValue: integer);
var
  curRect: tRect;
begin
  if (not(assigned(fView))) then exit;

  curRect:= getBounds;

  curRect.right:= curRect.left + aValue;

  setBounds(curRect);
end;

procedure cAbstractViewProxy.wndProc(var aMessage: tMessage);
var
  mouseWheelMessage: tWMMouseWheel;
  handled: boolean;
begin
  case aMessage.msg of
    WM_MOUSEWHEEL:
    begin
      mouseWheelMessage:= tWMMouseWheel(aMessage);

      mouseWheel(
        fView,
        keysToShiftState(mouseWheelMessage.keys),
        mouseWheelMessage.wheelDelta,
        point(mouseWheelMessage.xPos, mouseWheelMessage.yPos),
        handled
      );
    end;
  end;

  fOldWndProc(aMessage);
end;

procedure cAbstractViewProxy.keyDown(aSender: tObject; var aKey: word; aShift: tShiftState);
begin
  if (assigned(fOnKeyDown)) then fOnKeyDown(self, aKey, aShift);
end;

procedure cAbstractViewProxy.keyPress(aSender: tObject; var aKey: char);
begin
  if (assigned(fOnKeyPress)) then fOnKeyPress(self, aKey);
end;

procedure cAbstractViewProxy.loseFocus(aSender: tObject);
begin
  if assigned(fOnLoseFocus) then begin
    fOnLoseFocus(self);
  end;
end;

procedure cAbstractViewProxy.mouseDown(aSender: tObject; aButton: tMouseButton; aShift: tShiftState; aX, aY: integer);
begin
  if assigned(fOnMouseDown) then begin
    fOnMouseDown(self, aButton, aShift, aX, aY);
  end;
end;

procedure cAbstractViewProxy.mouseMove(aSender: tObject; aShift: tShiftState; aX, aY: integer);
begin
  if assigned(fOnMouseMove) then begin
    fOnMouseMove(self, aShift, aX, aY);
  end;
end;

procedure cAbstractViewProxy.mouseWheel(aSender: tObject; aShift: tShiftState; aWheelDelta: integer; aMousePos: tPoint; var aHandled: boolean);
begin
  if assigned(fOnMouseWheel) then begin
    fOnMouseWheel(self, aShift, aWheelDelta, aMousePos, aHandled);
  end;
end;

end.
