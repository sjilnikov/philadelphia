unit clsAbstractEditableViewProxy;

interface
uses
  windows,
  messages,
  variants,
  graphics,
  classes,
  controls,
  stdCtrls,
  sysUtils,

  clsCompleter,
  clsAbstractViewProxy,
  clsClassKit,
  clsException,
  clsAbstractValidator;

type
  eAbstractEditableViewProxy = class(cException);

  cAbstractEditableViewProxy = class;

  cEditableViewProxyClass = class of cAbstractEditableViewProxy;

  cAbstractEditableViewProxy = class(cAbstractViewProxy)
  private
    fAutoWidth              : boolean;
    fOnChanged              : tNotifyEvent;
    fCompleter              : cCompleter;
    fCompleterUpdatingValue : boolean;

    procedure   beginCompleterUpdateValue;
    procedure   endCompleterUpdateValue;

    procedure   setupCompleterEvents;
    procedure   disconnectCompleterEvents;
  protected
    fValidator  : cAbstractValidator;

    function    getViewValue: variant; virtual; abstract;
    procedure   setViewValue(aValue: variant); virtual; abstract;

    procedure   autoWidth; virtual;
    procedure   wndProc(var aMessage: tMessage); override;

    procedure   setupViewEvents; override;
    procedure   disconnectViewEvents; override;

  public
    procedure   setCursorPos(aPos: integer); virtual; abstract;
    function    getCursorPos: integer; virtual; abstract;

    procedure   setCompleter(aCompleter: cCompleter);
    function    getCompleter: cCompleter;

    procedure   setValidator(aValidator: cAbstractValidator);
    function    getValidator: cAbstractValidator;
    procedure   removeValidator;
    procedure   removeCompleter;

    procedure   setAutoWidth(aValue: boolean);
    function    isAutoWidth: boolean;

    procedure   setValue(aValue: variant);
    function    getValue: variant;

    constructor create;
    destructor  destroy; override;

    property    completer: cCompleter read getCompleter write setCompleter;
  published
    property    value: variant read getValue write setValue;
  published
    //EVENTS
    property    onChanged: tNotifyEvent read fOnChanged write fOnChanged;
  published
    //SLOTS
    procedure   keyPress(aSender: tObject; var aKey: char); override;
    procedure   keyDown(aSender: tObject; var aKey: word; aShift: tShiftState); override;
    procedure   changed(aSender: tObject); virtual;
    procedure   mouseWheel(aSender: tObject; aShift: tShiftState; aWheelDelta: integer; aMousePos: tPoint; var aHandled: boolean); override;


    procedure   completerItemSelected(aCompleter: cCompleter; aIndex: integer; aData: variant);
  end;

implementation
uses
  clsMulticastEvents;

{ cEditViewProxy }

procedure cAbstractEditableViewProxy.autoWidth;
begin
  //stub
end;

procedure cAbstractEditableViewProxy.changed(aSender: tObject);
var
  borderWidth: integer;
begin
  if fAutoWidth then begin
    autoWidth;
  end;

  if assigned(fOnChanged) then fOnChanged(self);


  if (assigned(fCompleter)) and (not fCompleter.isAccepted) and (getValue <> '') then begin
    fCompleter.setMinWidth(getWidth);

    borderWidth:= (fView.width - fView.clientWidth) div 2;

    fCompleter.popup(fView.clientToScreen(point(-borderWidth, getHeight)));
  end;
end;

constructor cAbstractEditableViewProxy.create;
begin
  inherited create;

  fValidator:= nil;
  fCompleter:= nil;
end;

destructor cAbstractEditableViewProxy.destroy;
begin
  removeValidator;

  disconnectCompleterEvents;

  removeCompleter;

  inherited;
end;

procedure cAbstractEditableViewProxy.beginCompleterUpdateValue;
begin
  fCompleterUpdatingValue:= true;
end;

procedure cAbstractEditableViewProxy.endCompleterUpdateValue;
begin
  fCompleterUpdatingValue:= false;
end;

procedure cAbstractEditableViewProxy.setupCompleterEvents;
begin
  if not assigned(fCompleter) then begin
    exit;
  end;

  connect(fCompleter, 'onItemSelected', self, 'completerItemSelected');
end;

procedure cAbstractEditableViewProxy.disconnectCompleterEvents;
begin
  if not assigned(fCompleter) then begin
    exit;
  end;

  disconnect(fCompleter, 'onItemSelected', self, 'completerItemSelected');
end;

procedure cAbstractEditableViewProxy.disconnectViewEvents;
begin
  inherited disconnectViewEvents;
end;

procedure cAbstractEditableViewProxy.wndProc(var aMessage: tMessage);
begin
  inherited wndProc(aMessage);

  case aMessage.msg of
    CM_CANCELMODE, WM_KILLFOCUS:
    begin
      if assigned(fCompleter) and (fCompleter.isVisible) then begin
        fCompleter.hide;
      end;
    end;
  end;
end;

procedure cAbstractEditableViewProxy.setCompleter(aCompleter: cCompleter);
begin
  disconnectCompleterEvents;
  fCompleter:= aCompleter;

  if assigned(fCompleter) then begin
    fCompleter.setViewProxy(self);
  end;

  setupCompleterEvents;
end;

function cAbstractEditableViewProxy.getCompleter: cCompleter;
begin
  result:= fCompleter;
end;

function cAbstractEditableViewProxy.isAutoWidth: boolean;
begin
  result:= fAutoWidth;
end;

function cAbstractEditableViewProxy.getValidator: cAbstractValidator;
begin
  result:= fValidator;
end;

function cAbstractEditableViewProxy.getValue: variant;
var
  pos: integer;
begin
  result:= null;

  if not assigned(view) then exit;

  result:= getViewValue;
  if (assigned(fValidator)) then begin

    if (fValidator.validate(result, pos) <> vsAcceptable) then begin
      result:= fValidator.fixup(result);
      exit;
    end;
  end;
end;

procedure cAbstractEditableViewProxy.setValidator(aValidator: cAbstractValidator);
begin
  fValidator:= aValidator;

  if not assigned(view) then exit;

  if not assigned(fValidator) then exit;

  setValue(getValue);
end;

procedure cAbstractEditableViewProxy.setValue(aValue: variant);
var
  validValue: variant;

  pos: integer;
begin
  if not assigned(view) then exit;

  validValue:= aValue;
  if (assigned(fValidator)) then begin

    if (fValidator.validate(validValue, pos) = vsInvalid) then begin
      validValue:= fValidator.fixup(validValue);
    end;
  end;

  setViewValue(validValue);
end;

procedure cAbstractEditableViewProxy.removeValidator;
begin
  if assigned(fValidator) then begin
    freeAndNil(fValidator);
  end;
end;

procedure cAbstractEditableViewProxy.removeCompleter;
begin
  if assigned(fCompleter) then begin
    freeAndNil(fCompleter);
  end;
end;
procedure cAbstractEditableViewProxy.setAutoWidth(aValue: boolean);
begin
  fAutoWidth:= aValue;
end;

procedure cAbstractEditableViewProxy.setupViewEvents;
begin
  inherited setupViewEvents;
end;

procedure cAbstractEditableViewProxy.keyDown(aSender: tObject; var aKey: word; aShift: tShiftState);
const
  PAGE_SIZE = 20;
begin
  inherited keyDown(aSender, aKey, aShift);

  //completer
  if not assigned(fCompleter) then begin
    exit;
  end;

  if not (fCompleter.isVisible) then begin
    exit;
  end;

  case aKey of
    VK_DOWN   :  fCompleter.selectNextItem(1);
    VK_UP     :  fCompleter.selectNextItem(-1);
    VK_NEXT   :  fCompleter.selectNextItem(PAGE_SIZE);
    VK_PRIOR  :  fCompleter.selectNextItem(-1 * PAGE_SIZE);
    VK_RETURN :  fCompleter.acceptCurrentItem;
    VK_ESCAPE :  fCompleter.hide;
  end;

  aKey:= 0;
end;

procedure cAbstractEditableViewProxy.keyPress(aSender: tObject; var aKey: char);
const
  RETURN_KEY_CODE = #13;
begin
  //ctr + a, ctrl + v, ...

  if (aKey in [^A, ^V, ^C, ^X]) then begin
    exit;
  end;

  if (assigned(fValidator)) then begin

    if (fValidator.validateSingleValue(getViewValue, aKey) <> vsAcceptable) then begin
      aKey:= #0;
    end;

  end;

  inherited keyPress(aSender, aKey);
end;

procedure cAbstractEditableViewProxy.mouseWheel(aSender: tObject; aShift: tShiftState; aWheelDelta: integer; aMousePos: tPoint; var aHandled: boolean);
begin
  inherited mouseWheel(aSender, aShift, aWheelDelta, aMousePos, aHandled);
end;

procedure cAbstractEditableViewProxy.completerItemSelected(aCompleter: cCompleter; aIndex: integer; aData: variant);
begin
  if (fCompleterUpdatingValue) then begin
    exit;
  end;

  beginCompleterUpdateValue;
  try
    setValue(aData);
    setCursorPos(maxInt);
  finally
    endCompleterUpdateValue;
  end;
end;

end.
