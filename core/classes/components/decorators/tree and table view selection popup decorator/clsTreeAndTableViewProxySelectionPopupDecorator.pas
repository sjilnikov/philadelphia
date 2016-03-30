unit clsTreeAndTableViewProxySelectionPopupDecorator;

interface
uses
  classes,
  menus,
  windows,
  sysUtils,
  virtualTrees,



  clsException,
  clsAbstractViewProxy,

  clsAbstractTableModel,
  clsAbstractTreeModel,

  clsTableViewProxy,
  clsTreeViewProxy,

  clsLists,
  clsAbstractPopupDecorator,
  clsMulticastEvents,
  clsMessageBox;

type
  eTreeAndTableViewProxySelectionPopupDecorator = class(cException);

  sSelectionToCheckItemsInfo = record
    popupItemName: string;
    popupItemCaption: string;

    imageIndex: integer;
  end;

  sSelectionToUnCheckItemsInfo = record
    popupItemName: string;
    popupItemCaption: string;

    imageIndex: integer;
  end;

  tTreeAndTableViewProxySelectionPopupCommand = (pcSelectionToCheck, pcSelectionToUnCheck);

  cTreeAndTableViewProxySelectionPopupDecorator = class(cAbstractPopupDecorator)
  private
    fSelectionToCheckItemsInfo: sSelectionToCheckItemsInfo;
    fSelectionToUnCheckItemsInfo: sSelectionToUnCheckItemsInfo;

    procedure   initialize;

    procedure   addPopupItems; override;

    procedure   setupEvents; override;
    procedure   disconnectEvents; override;

    procedure   setupViewProxyEvents; override;
    procedure   disconnectViewProxyEvents; override;


    procedure   viewSelectionToCheck(aValue: boolean);
  public
    const
    ONLY_TREE_VIEW_OR_TABLE_VIEW_SUPPURTS_FORMAT = 'only tree view or table view supports, got: %s';


    DEFAULT_SELECTION_TO_CHECK_ITEMS_NAME        = 'selectionToCheck';
    DEFAULT_SELECTION_TO_CHECK_ITEMS_CAPTION     = 'selection to check';

    DEFAULT_SELECTION_TO_UNCHECK_ITEMS_NAME      = 'selectionToUnCheck';
    DEFAULT_SELECTION_TO_UNCHECK_ITEMS_CAPTION   = 'selection to uncheck';
  public
    procedure   doCommand(aCommand: tTreeAndTableViewProxySelectionPopupCommand);

    procedure   setSelectionToCheckItemsInfo(aInfo: sSelectionToCheckItemsInfo);
    function    getSelectionToCheckItemsInfo: sSelectionToCheckItemsInfo;

    procedure   setSelectionToUnCheckItemsInfo(aInfo: sSelectionToUnCheckItemsInfo);
    function    getSelectionToUnCheckItemsInfo: sSelectionToUnCheckItemsInfo;

    procedure   setViewProxy(aViewProxy: cAbstractViewProxy); override;

    constructor create;
    destructor  destroy; override;

  published
    //SLOTS
    procedure   popupItemClicked(aSender: tObject); override;
    procedure   popupInvoked(aSender: tObject); override;
  end;


implementation

{ cTreeAndTableViewProxySelectionPopupDecorator }

constructor cTreeAndTableViewProxySelectionPopupDecorator.create;
begin
  inherited create;

  initialize;
end;

destructor cTreeAndTableViewProxySelectionPopupDecorator.destroy;
begin
  inherited;
end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.addPopupItems;
begin
  createMenuItem(getSelectionToCheckItemsInfo.popupItemName, getSelectionToCheckItemsInfo.popupItemCaption, getSelectionToCheckItemsInfo.imageIndex);
  createMenuItem(getSelectionToUnCheckItemsInfo.popupItemName, getSelectionToUnCheckItemsInfo.popupItemCaption, getSelectionToUnCheckItemsInfo.imageIndex);
end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.disconnectEvents;
begin

end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.disconnectViewProxyEvents;
begin

end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.doCommand(aCommand: tTreeAndTableViewProxySelectionPopupCommand);
begin
  case aCommand of
    pcSelectionToCheck     : viewSelectionToCheck(true);
    pcSelectionToUnCheck   : viewSelectionToCheck(false);
  end;
end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.setupEvents;
begin

end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.setupViewProxyEvents;
begin

end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.setViewProxy(aViewProxy: cAbstractViewProxy);
begin
  if not ((aViewProxy is cTreeViewProxy) or (aViewProxy is cTableViewProxy)) then begin
    raise eTreeAndTableViewProxySelectionPopupDecorator.createFmt(ONLY_TREE_VIEW_OR_TABLE_VIEW_SUPPURTS_FORMAT, [aViewProxy.className]);
  end;

  inherited setViewProxy(aViewProxy);
end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.viewSelectionToCheck(aValue: boolean);
begin
  getViewProxy.selectionToCheck(aValue);
end;

function cTreeAndTableViewProxySelectionPopupDecorator.getSelectionToCheckItemsInfo: sSelectionToCheckItemsInfo;
begin
  result:= fSelectionToCheckItemsInfo;
end;

function cTreeAndTableViewProxySelectionPopupDecorator.getSelectionToUnCheckItemsInfo: sSelectionToUnCheckItemsInfo;
begin
  result:= fSelectionToUnCheckItemsInfo;
end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.setSelectionToCheckItemsInfo(aInfo: sSelectionToCheckItemsInfo);
begin
  fSelectionToCheckItemsInfo:= aInfo;
end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.setSelectionToUnCheckItemsInfo(aInfo: sSelectionToUnCheckItemsInfo);
begin
  fSelectionToUnCheckItemsInfo:= aInfo;
end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.initialize;
var
  selectionToCheckInfo: sSelectionToCheckItemsInfo;
  selectionToUnCheckInfo: sSelectionToUnCheckItemsInfo;
begin
  selectionToCheckInfo.popupItemName:= DEFAULT_SELECTION_TO_CHECK_ITEMS_NAME;
  selectionToCheckInfo.popupItemCaption:= DEFAULT_SELECTION_TO_CHECK_ITEMS_CAPTION;
  selectionToCheckInfo.imageIndex:= -1;
  setSelectionToCheckItemsInfo(selectionToCheckInfo);


  selectionToUnCheckInfo.popupItemName:= DEFAULT_SELECTION_TO_UNCHECK_ITEMS_NAME;
  selectionToUnCheckInfo.popupItemCaption:= DEFAULT_SELECTION_TO_UNCHECK_ITEMS_CAPTION;
  selectionToUnCheckInfo.imageIndex:= -1;
  setSelectionToUnCheckItemsInfo(selectionToUnCheckInfo);
end;


//SLOTS
procedure cTreeAndTableViewProxySelectionPopupDecorator.popupItemClicked(aSender: tObject);
var
  popupItem: tMenuItem;
begin
  popupItem:= aSender as tMenuItem;
  if not assigned(popupItem) then begin
    exit;
  end;

  if (popupItem.name = getSelectionToCheckItemsInfo.popupItemName) then begin
    viewSelectionToCheck(true);

    exit;
  end;

  if (popupItem.name = getSelectionToUnCheckItemsInfo.popupItemName) then begin
    viewSelectionToCheck(false);

    exit;
  end;
end;

procedure cTreeAndTableViewProxySelectionPopupDecorator.popupInvoked(aSender: tObject);
begin
end;



end.
