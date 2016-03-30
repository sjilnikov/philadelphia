unit clsEditButtonViewProxy;

interface
uses
  variants,
  graphics,
  classes,
  controls,
  stdCtrls,
  extCtrls,
  sysUtils,

  clsClassKit,
  clsMulticastEvents,
  clsAbstractEditableViewProxy;

type

  tEditButtonType = (btLeft, btRigth);

  cEditButtonViewProxy = class;

  tEditButtonViewProxyButtonClickedEvent = procedure (aSender: cEditButtonViewProxy; aButtonType: tEditButtonType) of object;

  cEditButtonViewProxy = class(cAbstractEditableViewProxy)
  private
    fOnButtonClicked  : tEditButtonViewProxyButtonClickedEvent;

    function    getCastedView: tButtonedEdit;

    function    getViewValue: variant; override;
    procedure   setViewValue(aValue: variant); override;

    procedure   setupViewEvents; override;
    procedure   disconnectViewEvents; override;
  public
    procedure   setView(aView: tWinControl); override;

    procedure   setEditable(aValue: boolean);
    function    isEditable: boolean;

    procedure   setImageList(aImageList: tImageList);

    function    getLeftButton: tEditButton;
    function    getRightButton: tEditButton;

    function    getFont: tFont;

    procedure   setHorizontalAlignment(aValue: tAlignment);
  published
    {$REGION 'SLOTS'}
    procedure   leftButtonClicked(aSender: tObject);
    procedure   rightButtonClicked(aSender: tObject);
    {$ENDREGION}
  published
    {$REGION 'EVENTS'}
    property    onButtonClicked: tEditButtonViewProxyButtonClickedEvent read fOnButtonClicked write fOnButtonClicked;
    {$ENDREGION}
  end;

implementation

{ cEditButtonViewProxy }

procedure cEditButtonViewProxy.disconnectViewEvents;
begin
  inherited disconnectViewEvents;

  disconnect(getCastedView, 'onChange', self, 'changed');

  disconnect(getCastedView, 'onRightButtonClick', self, 'rightButtonClicked');
  disconnect(getCastedView, 'onLeftButtonClick', self, 'leftButtonClicked');
end;

function cEditButtonViewProxy.getCastedView: tButtonedEdit;
begin
  result:= fView as tButtonedEdit;
end;

procedure cEditButtonViewProxy.setViewValue(aValue: variant);
begin
  getCastedView.text:= aValue;
end;

function cEditButtonViewProxy.getViewValue: variant;
begin
  result:= getCastedView.text;
end;

function cEditButtonViewProxy.isEditable: boolean;
begin
  result:= false;

  if not assigned(fView) then exit;

  result:= not getCastedView.readOnly;
end;

function cEditButtonViewProxy.getFont: tFont;
begin
  result:= nil;
  if (not assigned(fView)) then exit;

  result:= getCastedView.font;
end;

function cEditButtonViewProxy.getLeftButton: tEditButton;
begin
  result:= nil;
  if not assigned(fView) then exit;

  result:= getCastedView.leftButton;
end;

function cEditButtonViewProxy.getRightButton: tEditButton;
begin
  result:= nil;
  if not assigned(fView) then exit;

  result:= getCastedView.rightButton;
end;

procedure cEditButtonViewProxy.setEditable(aValue: boolean);
begin
  if not assigned(fView) then exit;

  getCastedView.readOnly:= not aValue;
end;

procedure cEditButtonViewProxy.setHorizontalAlignment(aValue: tAlignment);
begin
  if not assigned(fView) then exit;

  getCastedView.alignment:= aValue;
end;

procedure cEditButtonViewProxy.setImageList(aImageList: tImageList);
begin
  if not assigned(fView) then exit;

  getCastedView.images:= aImageList;
end;

procedure cEditButtonViewProxy.setupViewEvents;
begin
  inherited setupViewEvents;

  connect(getCastedView, 'onChange', self, 'changed');

  connect(getCastedView, 'onRightButtonClick', self, 'rightButtonClicked');
  connect(getCastedView, 'onLeftButtonClick', self, 'leftButtonClicked');
end;

procedure cEditButtonViewProxy.setView(aView: tWinControl);
begin
  inherited setView(aView);

  if (assigned(aView)) and (not (aView is tButtonedEdit)) then begin
    raise eClassError.createFmt(INVALID_CLASS_RECEIVED, [tButtonedEdit.className, aView.className]);
  end;
end;

{$REGION 'SLOTS'}
procedure cEditButtonViewProxy.leftButtonClicked(aSender: tObject);
begin
  if assigned(fOnButtonClicked) then begin
    fOnButtonClicked(self, btLeft);
  end;
end;

procedure cEditButtonViewProxy.rightButtonClicked(aSender: tObject);
begin
  if assigned(fOnButtonClicked) then begin
    fOnButtonClicked(self, btRigth);
  end;
end;
{$ENDREGION}

end.
