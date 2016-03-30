unit clsDateTimePickerViewProxy;

interface
uses
  windows,
  variants,
  graphics,
  classes,
  controls,
  stdCtrls,
  comCtrls,
  sysUtils,
  clsClassKit,
  clsMulticastEvents,
  clsAbstractEditableViewProxy;

type
  cDateTimePickerViewProxy = class(cAbstractEditableViewProxy)
  private
    fEditable   : boolean;

    function    getCastedView: tDateTimePicker;

    function    getViewValue: variant; override;
    procedure   setViewValue(aValue: variant); override;

    procedure   setupViewEvents; override;
    procedure   disconnectViewEvents; override;

  public
    constructor create;


    procedure   setView(aView: tWinControl); override;

    procedure   setEditable(aValue: boolean);
    function    isEditable: boolean;

    function    getFont: tFont;
    procedure   setHorizontalAlignment(aValue: tAlignment);
  published
    //SLOTS
    procedure   keyDown(aSender: tObject; var aKey: word; aShift: tShiftState); override;
    procedure   changed(aSender: tObject); override;
  end;

implementation

{ cDateTimePickerViewProxy }

procedure cDateTimePickerViewProxy.changed(aSender: tObject);
begin
  inherited changed(aSender);
  if (getViewValue = 0) then begin
    getCastedView.format:= ' ';
  end else begin
    getCastedView.format:= '';
  end;
end;

constructor cDateTimePickerViewProxy.create;
begin
  inherited create;

  setEditable(true);
end;

procedure cDateTimePickerViewProxy.disconnectViewEvents;
begin
  inherited disconnectViewEvents;

  disconnect(fView, 'onChange', self, 'changed');
end;

function cDateTimePickerViewProxy.getCastedView: tDateTimePicker;
begin
  result:= fView as tDateTimePicker;
end;

function cDateTimePickerViewProxy.getFont: tFont;
begin
  result:= nil;

  if (not assigned(fView)) then exit;

  result:= getCastedView.font;
end;

function cDateTimePickerViewProxy.getViewValue: variant;
begin
  result:= getCastedView.dateTime;
end;

function cDateTimePickerViewProxy.isEditable: boolean;
begin
  result:= fEditable;
end;

procedure cDateTimePickerViewProxy.keyDown(aSender: tObject; var aKey: word; aShift: tShiftState);
begin
  inherited keyDown(aSender, aKey, aShift);
  if aKey = VK_DELETE then begin
    setViewValue(0);
  end;
end;

procedure cDateTimePickerViewProxy.setEditable(aValue: boolean);
begin
  fEditable:= aValue;
end;

procedure cDateTimePickerViewProxy.setHorizontalAlignment(aValue: tAlignment);
begin
  if not assigned(fView) then exit;

  raise eAbstractEditableViewProxy.createFmt(METHOD_NOT_IMPLEMENTED, ['cDateTimePickerViewProxy.setHorizontalAlignment']);
end;

procedure cDateTimePickerViewProxy.setView(aView: tWinControl);
begin
  inherited setView(aView);

  if (assigned(aView)) and (not (aView is tDateTimePicker)) then begin
    raise eClassError.createFmt(INVALID_CLASS_RECEIVED, [tEdit.className, aView.className]);
  end;
end;

procedure cDateTimePickerViewProxy.setupViewEvents;
begin
  inherited setupViewEvents;

  connect(fView, 'onChange', self, 'changed');
end;

procedure cDateTimePickerViewProxy.setViewValue(aValue: variant);
begin
  if (not(fEditable)) then exit;

  if varToStr(aValue) = '' then begin
    getCastedView.dateTime:= 0;
  end else begin
    getCastedView.dateTime:= aValue;
  end;

  changed(fView);
end;

end.
