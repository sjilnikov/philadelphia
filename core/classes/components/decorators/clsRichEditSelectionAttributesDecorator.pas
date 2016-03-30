unit clsRichEditSelectionAttributesDecorator;

interface
uses
  classes,
  graphics,
  sysUtils,
  windows,
  controls,
  comCtrls,
  dialogs,
  menus,

  clsMulticastEvents;

type
  cRichEditSelectionAttributesDecorator = class
  private
    const

    POPUP_MENU_ITEM_SELECT_COLOR_CAPTION  = 'Выделить цветом';
    POPUP_MENU_ITEM_TOGGLE_BOLD_CAPTION   = 'Выделить жирным';
  private
    fRichEdit    : tRichEdit;
    fPopupMenu   : tPopupMenu;
    fColorDialog : tColorDialog;

    procedure    setupRichEditEvents;
    procedure    disconnectRichEditEvents;

    procedure    setupPopupMenuEvents;
    procedure    disconnectPopupMenuEvents;

    procedure    createPopupMenu;
    procedure    destroyPopupMenu;
    procedure    createPopupMenuItems;

    procedure    createColorDialog;
    procedure    destroyColorDialog;

    procedure    selectColor;
    procedure    toggleBold;
  public
    procedure    setRichEdit(aRichEdit: tRichEdit);

    constructor  create;
    destructor   destroy; override;
  published
    {$REGION 'SLOTS'}
    procedure    richEditMouseUp(aSender: tObject; aButton: tMouseButton; aShift: tShiftState; aX, aY: integer);
    procedure    popupMenuPopupItemClicked(aSender: tObject);
    {$ENDREGION}
  end;

implementation

constructor cRichEditSelectionAttributesDecorator.create;
begin
  inherited create;

  createColorDialog;

  createPopupMenu;
  createPopupMenuItems;

  setupPopupMenuEvents;
end;

destructor cRichEditSelectionAttributesDecorator.destroy;
begin
  disconnectRichEditEvents;

  disconnectPopupMenuEvents;
  destroyPopupMenu;

  destroyColorDialog;

  inherited destroy;
end;

procedure cRichEditSelectionAttributesDecorator.destroyColorDialog;
begin
  if assigned(fColorDialog) then begin
    freeAndNil(fColorDialog);
  end;
end;

procedure cRichEditSelectionAttributesDecorator.createPopupMenuItems;
var
  menuItem: tMenuItem;
begin
  menuItem:= fPopupMenu.createMenuItem;
  menuItem.caption:= POPUP_MENU_ITEM_SELECT_COLOR_CAPTION;
  fPopupMenu.items.add(menuItem);
  connect(menuItem, 'onClick', self, 'popupMenuPopupItemClicked');

  menuItem:= fPopupMenu.createMenuItem;
  menuItem.caption:= POPUP_MENU_ITEM_TOGGLE_BOLD_CAPTION;
  fPopupMenu.items.add(menuItem);
  connect(menuItem, 'onClick', self, 'popupMenuPopupItemClicked');
end;

procedure cRichEditSelectionAttributesDecorator.createColorDialog;
begin
  fColorDialog:= tColorDialog.create(nil);
end;

procedure cRichEditSelectionAttributesDecorator.createPopupMenu;
begin
  fPopupMenu:= tPopupMenu.create(nil);
end;


procedure cRichEditSelectionAttributesDecorator.destroyPopupMenu;
begin
  if assigned(fPopupMenu) then begin
    freeAndNil(fPopupMenu);
  end;
end;

procedure cRichEditSelectionAttributesDecorator.selectColor;
begin
  if not fColorDialog.execute then exit;

  fRichEdit.selAttributes.color:= fColorDialog.color;
end;

procedure cRichEditSelectionAttributesDecorator.setRichEdit(aRichEdit: tRichEdit);
begin
  disconnectRichEditEvents;
  fRichEdit:= aRichEdit;
  setupRichEditEvents;
end;

procedure cRichEditSelectionAttributesDecorator.setupPopupMenuEvents;
begin
end;

procedure cRichEditSelectionAttributesDecorator.setupRichEditEvents;
begin
  if not assigned(fRichEdit) then exit;

  connect(fRichEdit, 'onMouseUp', self, 'richEditMouseUp');
end;

procedure cRichEditSelectionAttributesDecorator.toggleBold;
begin
  if (fsBold in fRichEdit.selAttributes.style) then begin
    fRichEdit.selAttributes.style:= fRichEdit.selAttributes.style - [fsBold];
  end else begin
    fRichEdit.selAttributes.style:= fRichEdit.selAttributes.style + [fsBold];
  end;
end;

procedure cRichEditSelectionAttributesDecorator.disconnectPopupMenuEvents;
begin
  disconnectReceiver(self);
end;

procedure cRichEditSelectionAttributesDecorator.disconnectRichEditEvents;
begin
  if not assigned(fRichEdit) then exit;

  disconnect(fRichEdit, 'onMouseUp', self, 'richEditMouseUp');
end;

{$REGION 'SLOTS'}
procedure cRichEditSelectionAttributesDecorator.richEditMouseUp(aSender: tObject; aButton: tMouseButton; aShift: tShiftState; aX, aY: integer);
var
  cursorPos: tPoint;
begin
  if (fRichEdit.selLength = 0) or (aButton = mbLeft) then exit;

  cursorPos:= mouse.cursorPos;
  fPopupMenu.popup(cursorPos.x, cursorPos.y);
end;

procedure cRichEditSelectionAttributesDecorator.popupMenuPopupItemClicked(aSender: tObject);
var
  menuItem: tMenuItem;
begin
  menuItem:= aSender as tMenuItem;
  if not assigned(menuItem) then exit;

  if (menuItem.caption = POPUP_MENU_ITEM_SELECT_COLOR_CAPTION) then begin
    selectColor;
    exit;
  end;

  if (menuItem.caption = POPUP_MENU_ITEM_TOGGLE_BOLD_CAPTION) then begin
    toggleBold;
    exit;
  end;
end;

{$ENDREGION}
end.
