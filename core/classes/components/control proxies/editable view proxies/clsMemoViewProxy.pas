unit clsMemoViewProxy;

interface
uses
  variants,
  graphics,
  classes,
  controls,
  stdCtrls,
  sysUtils,
  clsClassKit,
  clsMulticastEvents,
  clsAbstractEditableViewProxy;

type
  cMemoViewProxy = class(cAbstractEditableViewProxy)
  private
    function    getCastedView: tMemo;

    function    getViewValue: variant; override;
    procedure   setViewValue(aValue: variant); override;

    procedure   setupViewEvents; override;
    procedure   disconnectViewEvents; override;
  public
    procedure   setView(aView: tWinControl); override;

    procedure   setEditable(aValue: boolean);
    function    isEditable: boolean;

    procedure   setWordWrap(aValue: boolean);
    function    isWordWrap: boolean;

    procedure   setScrollStyle(aValue: tScrollStyle);
    function    getScrollStyle: tScrollStyle;

    function    getFont: tFont;
    procedure   setHorizontalAlignment(aValue: tAlignment);
  end;

implementation

{ cMemoViewProxy }

procedure cMemoViewProxy.disconnectViewEvents;
begin
  inherited disconnectViewEvents;

  disconnect(fView, 'onChange', self, 'changed');
end;

function cMemoViewProxy.getCastedView: tMemo;
begin
  result:= fView as tMemo;
end;

function cMemoViewProxy.getFont: tFont;
begin
  result:= nil;

  if (not assigned(fView)) then exit;

  result:= getCastedView.font;
end;

function cMemoViewProxy.getScrollStyle: tScrollStyle;
begin
  result:= ssNone;

  if not assigned(fView) then exit;

  result:= getCastedView.scrollBars;
end;

function cMemoViewProxy.getViewValue: variant;
begin
  result:= getCastedView.text;
end;

function cMemoViewProxy.isEditable: boolean;
begin
  result:= false;

  if not assigned(fView) then exit;

  result:= not getCastedView.readOnly;
end;

function cMemoViewProxy.isWordWrap: boolean;
begin
  result:= false;

  if not assigned(fView) then exit;

  result:= getCastedView.wordWrap;
end;

procedure cMemoViewProxy.setEditable(aValue: boolean);
begin
  if not assigned(fView) then exit;

  getCastedView.readOnly:= not aValue;
end;

procedure cMemoViewProxy.setHorizontalAlignment(aValue: tAlignment);
begin
  if not assigned(fView) then exit;

  getCastedView.alignment:= aValue;
end;

procedure cMemoViewProxy.setScrollStyle(aValue: tScrollStyle);
begin
  if not assigned(fView) then exit;

  getCastedView.scrollBars:= aValue;
end;

procedure cMemoViewProxy.setupViewEvents;
begin
  inherited setupViewEvents;

  connect(fView, 'onChange', self, 'changed');
end;

procedure cMemoViewProxy.setView(aView: tWinControl);
begin
  inherited setView(aView);

  if (assigned(aView)) and (not (aView is tMemo)) then begin
    raise eClassError.createFmt(INVALID_CLASS_RECEIVED, [tMemo.className, aView.className]);
  end;
end;

procedure cMemoViewProxy.setViewValue(aValue: variant);
begin
  getCastedView.text:= aValue;
end;

procedure cMemoViewProxy.setWordWrap(aValue: boolean);
begin
  if not assigned(fView) then exit;

  getCastedView.wordWrap:= aValue;
end;

end.
