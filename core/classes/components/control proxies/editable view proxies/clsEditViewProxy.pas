unit clsEditViewProxy;

interface
uses
  windows,
  variants,
  messages,
  graphics,
  classes,
  controls,
  stdCtrls,
  sysUtils,

  clsClassKit,
  clsMulticastEvents,
  clsAbstractEditableViewProxy;

type
  cEditViewProxy = class(cAbstractEditableViewProxy)
  private
    const

    AUTO_WIDTH_MARGIN = 8;
  private
    function    getCastedView: tEdit;

    function    getViewValue: variant; override;
    procedure   setViewValue(aValue: variant); override;

    procedure   setupViewEvents; override;
    procedure   disconnectViewEvents; override;

  protected
    procedure   autoWidth; override;
  public
    procedure   setCursorPos(aPos: integer); override;
    function    getCursorPos: integer; override;

    procedure   setView(aView: tWinControl); override;

    procedure   setAutoSize(aValue: boolean);

    procedure   setEditable(aValue: boolean);
    function    isEditable: boolean;

    function    getFont: tFont;
    procedure   setHorizontalAlignment(aValue: tAlignment);

    constructor create;
    destructor  destroy; override;
  published
    //PARENT SLOTS
    procedure   changed(aSender: tObject); override;
    procedure   keyDown(aSender: tObject; var aKey: word; aShift: tShiftState); override;

    procedure   mouseWheel(aSender: tObject; aShift: tShiftState; aWheelDelta: integer; aMousePos: tPoint; var aHandled: boolean); override;
    procedure   mouseMove(aSender: tObject; aShift: tShiftState; aX, aY: integer); override;
    procedure   mouseDown(aSender: tObject; aButton: tMouseButton; aShift: tShiftState; aX, aY: integer); override;
  end;

implementation

{ cEditViewProxy }

procedure cEditViewProxy.autoWidth;
var
  controlCanvas: tControlCanvas;

  textWidth: integer;
begin
  inherited autoWidth;

  if (not assigned(fView)) then exit;

  controlCanvas:= tControlCanvas.create;
  try
    controlCanvas.control:= fView;
    controlCanvas.font:= getCastedView.font;

    textWidth:= controlCanvas.textWidth(getValue) + 2 * AUTO_WIDTH_MARGIN;

    setWidth(textWidth);

  finally
    freeAndNil(controlCanvas);
  end;
end;

constructor cEditViewProxy.create;
begin
  inherited create;
end;

destructor cEditViewProxy.destroy;
begin
  inherited;
end;

procedure cEditViewProxy.disconnectViewEvents;
begin
  inherited disconnectViewEvents;

  disconnect(fView, 'onChange', self, 'changed');
end;

function cEditViewProxy.getCastedView: tEdit;
begin
  result:= fView as tEdit;
end;

function cEditViewProxy.getCursorPos: integer;
begin
  result:= -1;
  if (not assigned(fView)) then exit;

  result:= getCastedView.selStart;
end;

function cEditViewProxy.getFont: tFont;
begin
  result:= nil;

  if (not assigned(fView)) then exit;

  result:= getCastedView.font;
end;

function cEditViewProxy.getViewValue: variant;
begin
  result:= getCastedView.text;
end;

function cEditViewProxy.isEditable: boolean;
begin
  result:= false;

  if not assigned(fView) then exit;

  result:= not getCastedView.readOnly;
end;

procedure cEditViewProxy.keyDown(aSender: tObject; var aKey: word; aShift: tShiftState);
begin
  inherited keyDown(aSender, aKey, aShift);
end;

procedure cEditViewProxy.mouseDown(aSender: tObject; aButton: tMouseButton; aShift: tShiftState; aX, aY: integer);
begin
  inherited mouseDown(aSender, aButton, aShift, aX, aY);
end;

procedure cEditViewProxy.mouseMove(aSender: tObject; aShift: tShiftState; aX, aY: integer);
begin
  inherited mouseMove(aSender, aShift, aX, aY);
end;

procedure cEditViewProxy.mouseWheel(aSender: tObject; aShift: tShiftState; aWheelDelta: integer; aMousePos: tPoint; var aHandled: boolean);
begin
  inherited mouseWheel(aSender, aShift, aWheelDelta, aMousePos, aHandled);
end;

procedure cEditViewProxy.setAutoSize(aValue: boolean);
begin
  if not assigned(fView) then exit;

  getCastedView.autoSize:= aValue;
end;

procedure cEditViewProxy.setCursorPos(aPos: integer);
begin
  if (not assigned(fView)) then exit;

  getCastedView.selStart:= aPos;
end;

procedure cEditViewProxy.setEditable(aValue: boolean);
begin
  if not assigned(fView) then exit;

  getCastedView.readOnly:= not aValue;
end;

procedure cEditViewProxy.setHorizontalAlignment(aValue: tAlignment);
begin
  if not assigned(fView) then exit;

  getCastedView.alignment:= aValue;
end;

procedure cEditViewProxy.setupViewEvents;
begin
  inherited setupViewEvents;

  connect(fView, 'onChange', self, 'changed');
end;

procedure cEditViewProxy.setView(aView: tWinControl);
begin
  inherited setView(aView);

  if (assigned(aView)) and (not (aView is tEdit)) then begin
    raise eClassError.createFmt(INVALID_CLASS_RECEIVED, [tEdit.className, aView.className]);
  end;

end;

procedure cEditViewProxy.setViewValue(aValue: variant);
begin
  getCastedView.text:= aValue;
end;

procedure cEditViewProxy.changed(aSender: tObject);
begin
  inherited changed(aSender);
end;

end.
