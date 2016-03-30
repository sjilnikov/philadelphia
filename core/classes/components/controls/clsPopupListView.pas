unit clsPopupListView;

interface

uses
  graphics,
  windows,
  messages,
  sysUtils,
  stdCtrls,
  controls,
  classes,
  math,

  clsDebug,
  clsComponentUtils,
  clsMulticastEvents;

type
  cPopupListView = class;


  tPopupListViewItemSelectedEvent = procedure(aSender: cPopupListView; aIndex: integer) of object;

  cPopupListView = class(tCustomListBox)
  private
    fAutoSize       : boolean;
    fMinWidth       : integer;
    fUpdating       : boolean;

    fOnItemSelected : tPopupListViewItemSelectedEvent;

    fOldMousePoint  : tPoint;

    fOldWndProc     : tWndMethod;

    procedure   createParams(var aParams: tCreateParams); override;
    procedure   createWnd; override;

    procedure   resize;

    procedure   setupEvents;
    procedure   disconnectEvents;

    procedure   wndProc(var aMessage: tMessage);


    procedure   selectItem(aIndex: integer);
  public
    function    getItemIndexAtPos(aPoint: tPoint): integer;

    procedure   beginUpdate;
    procedure   endUpdate;

    function    isVisible: boolean;

    procedure   hide;
    procedure   show;

    procedure   clear; override;

    procedure   setSelectedIndex(aIndex: integer);
    function    getSelectedIndex: integer;

    procedure   setMinWidth(aValue: integer);
    function    getMinWidth: integer;


    procedure   setWidth(aValue: integer);
    function    getWidth: integer;

    procedure   setHeight(aValue: integer);
    function    getHeight: integer;

    procedure   setColor(aColor: tColor);
    function    getColor: tColor;

    procedure   setAutoSize(aValue: boolean);
    function    getAutoSize: boolean;

    function    getCount: integer;
    function    getItemData(aIndex: integer): tObject;
    function    getItemText(aIndex: integer): string;

    procedure   addItem(aText: string; aObject: tObject = nil);


    procedure   popup(aX, aY: integer); overload;
    procedure   popup(aPoint: tPoint); overload;

    constructor create(aOwner: tComponent); overload; override;
    constructor create; overload;

    destructor  destroy; override;

    property    itemData[aIndex: integer]: tObject read getItemData;
    property    itemText[aIndex: integer]: string read getItemText;

    property    count: integer read getCount;
  published
    //EVENTS
    property    onMouseMove;
    property    onMouseDown;

    property    onItemSelected: tPopupListViewItemSelectedEvent read fOnItemSelected write fOnItemSelected;
  published
    //SLOTS
    procedure   mouseMove(aSender: tObject; aShift: tShiftState; aX, aY: integer);
    procedure   mouseDown(aSender: tObject; aButton: tMouseButton; aShift: tShiftState; aX, aY: integer);
  end;

implementation


constructor cPopupListView.create(aOwner: tComponent);
begin
  inherited create(aOwner);

  fOldWndProc:= windowProc;
  windowProc:= wndProc;

  setupEvents;

  hide;

  parentWindow:= getDesktopWindow;

  setMinWidth(0);

  setAutoSize(true);
  setColor(clWindow);
  setHeight(150);
  setWidth(200);
end;

procedure cPopupListView.addItem(aText: string; aObject: tObject);
begin
  items.addObject(aText, aObject);

  resize;
end;

procedure cPopupListView.beginUpdate;
begin
  fUpdating:= true;
end;

procedure cPopupListView.clear;
var
  i: integer;
  curObj: tObject;
begin
  for i := 0 to count - 1 do begin
    curObj:= itemData[i];
    if assigned(curObj) then begin
      freeAndNil(curObj);
    end;
  end;

  inherited clear;
end;

constructor cPopupListView.create;
begin
  create(nil);
end;

procedure cPopupListView.createParams(var aParams: tCreateParams);
begin
  inherited createParams(aParams);
  with aParams do begin
    style             := style or WS_BORDER;
    exStyle           := WS_EX_TOOLWINDOW or WS_EX_TOPMOST;
    windowClass.style := CS_SAVEBITS;
  end;
end;

procedure cPopupListView.createWnd;
begin
  inherited createWnd;
  windows.setParent(handle, 0);
  callWindowProc(defWndProc, handle, WM_SETFOCUS, 0, 0);
end;


destructor cPopupListView.destroy;
begin
  disconnectEvents;

  clear;

  inherited;
end;

function cPopupListView.getAutoSize: boolean;
begin
  result:= fAutoSize;
end;

function cPopupListView.getColor: tColor;
begin
  result:= color;
end;

function cPopupListView.getCount: integer;
begin
  result:= items.count;
end;

function cPopupListView.getHeight: integer;
begin
  result:= height;
end;

function cPopupListView.getItemData(aIndex: integer): tObject;
begin
  result:= items.objects[aIndex];
end;

function cPopupListView.getItemIndexAtPos(aPoint: tPoint): integer;
begin
  result:= itemAtPos(aPoint, false);
end;

function cPopupListView.getItemText(aIndex: integer): string;
begin
  result:= items.strings[aIndex];
end;

function cPopupListView.getMinWidth: integer;
begin
  result:= fMinWidth;
end;

function cPopupListView.getSelectedIndex: integer;
begin
  result:= itemIndex;
end;

function cPopupListView.getWidth: integer;
begin
  result:= width;
end;

procedure cPopupListView.hide;
begin
  inherited hide;
end;

function cPopupListView.isVisible: boolean;
begin
  result:= visible;
end;

procedure cPopupListView.mouseDown(aSender: tObject; aButton: tMouseButton; aShift: tShiftState; aX, aY: integer);
begin
  selectItem(getSelectedIndex);
end;

procedure cPopupListView.mouseMove(aSender: tObject; aShift: tShiftState; aX, aY: integer);
var
  foundIndex: integer;

  newPoint: tPoint;
begin
  newPoint:= point(aX, aY);

  foundIndex:= getItemIndexAtPos(newPoint);

  if (foundIndex = -1) then begin
    exit;
  end;

  if (fOldMousePoint.y <> newPoint.y) then begin
    setSelectedIndex(foundIndex);
  end;

  fOldMousePoint:= newPoint;
end;

procedure cPopupListView.resize;
const
  LIST_BORDER_SIZE = 16;
var
  newWidth: integer;
begin
  if fUpdating then begin
    exit;  
  end;

  newWidth:= 0;
  if (fAutoSize) then begin
    newWidth:= 2 * LIST_BORDER_SIZE + cComponentUtils.getWidthForStrings(canvas, items);
  end;

  newWidth:= max(newWidth, getMinWidth);
  
  setWidth(newWidth);
end;

procedure cPopupListView.selectItem(aIndex: integer);
begin
  if assigned(fOnItemSelected) then begin
    fOnItemSelected(self, aIndex);
  end;
end;

procedure cPopupListView.setAutoSize(aValue: boolean);
begin
  fAutoSize:= aValue;

  resize;
end;

procedure cPopupListView.setColor(aColor: tColor);
begin
  color:= aColor;
end;

procedure cPopupListView.setHeight(aValue: integer);
begin
  height:= aValue;
end;

procedure cPopupListView.setMinWidth(aValue: integer);
begin
  fMinWidth:= aValue;

  resize;
end;

procedure cPopupListView.setSelectedIndex(aIndex: integer);
begin
  itemIndex:= aIndex;
end;

procedure cPopupListView.setupEvents;
begin
  connect(self, 'onMouseMove', self, 'mouseMove');
  connect(self, 'onMouseDown', self, 'mouseDown');
end;

procedure cPopupListView.disconnectEvents;
begin
  disconnect(self, 'onMouseMove', self, 'mouseMove');
  disconnect(self, 'onMouseDown', self, 'mouseDown');
end;

procedure cPopupListView.endUpdate;
begin
  fUpdating:= false;

  resize;
end;

procedure cPopupListView.setWidth(aValue: integer);
begin
  width:= aValue;
end;

procedure cPopupListView.show;
begin
  inherited show;
end;

procedure cPopupListView.wndProc(var aMessage: tMessage);
begin
  fOldWndProc(aMessage);
end;

procedure cPopupListView.popup(aPoint: tPoint);
begin
  popup(aPoint.x, aPoint.y);
end;

procedure cPopupListView.popup(aX, aY: integer);
begin
  left:= aX;
  top:= aY;

  show;
end;

end.
