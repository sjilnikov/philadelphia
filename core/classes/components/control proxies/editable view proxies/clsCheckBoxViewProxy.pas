unit clsCheckBoxViewProxy;

interface
uses
  variants,
  graphics,
  classes,
  controls,
  stdCtrls,
  sysUtils,

  clsMulticastEvents,
  clsClassKit,
  clsAbstractEditableViewProxy;

type
  cCheckBoxViewProxy = class(cAbstractEditableViewProxy)
  private
    fEditable   : boolean;

    function    getCastedView: tCheckBox;

    function    getViewValue: variant; override;
    procedure   setViewValue(aValue: variant); override;

    procedure   setupViewEvents; override;
    procedure   disconnectViewEvents; override;
  public
    procedure   setView(aView: tWinControl); override;

    procedure   setEditable(aValue: boolean);
    function    isEditable: boolean;

    function    getFont: tFont;
    procedure   setHorizontalAlignment(aValue: tAlignment);
  end;

implementation

{ cCheckBoxViewProxy }

function cCheckBoxViewProxy.getCastedView: tCheckBox;
begin
  result:= fView as tCheckBox;
end;

function cCheckBoxViewProxy.getFont: tFont;
begin
  result:= nil;

  if (not assigned(fView)) then exit;

  result:= getCastedView.font;
end;

function cCheckBoxViewProxy.getViewValue: variant;
begin
  result:= getCastedView.checked;
end;

function cCheckBoxViewProxy.isEditable: boolean;
begin
  result:= fEditable;
end;

procedure cCheckBoxViewProxy.setEditable(aValue: boolean);
begin
  fEditable:= aValue;
end;

procedure cCheckBoxViewProxy.setHorizontalAlignment(aValue: tAlignment);
begin
  if not assigned(fView) then exit;

  getCastedView.alignment:= aValue;
end;

procedure cCheckBoxViewProxy.setView(aView: tWinControl);
begin
  inherited setView(aView);

  if (assigned(aView)) and (not (aView is tCheckBox)) then begin
    raise eClassError.createFmt(INVALID_CLASS_RECEIVED, [tEdit.className, aView.className]);
  end;

  setEditable(true);
end;

procedure cCheckBoxViewProxy.disconnectViewEvents;
begin
  inherited disconnectViewEvents;

  disconnect(fView, 'onClick', self, 'changed');
end;

procedure cCheckBoxViewProxy.setupViewEvents;
begin
  inherited setupViewEvents;

  connect(fView, 'onClick', self, 'changed');
end;

procedure cCheckBoxViewProxy.setViewValue(aValue: variant);
begin
  if (not (fEditable)) then exit;


  getCastedView.checked:= aValue;
end;

end.
