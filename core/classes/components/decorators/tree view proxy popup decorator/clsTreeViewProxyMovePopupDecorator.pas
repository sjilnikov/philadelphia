unit clsTreeViewProxyMovePopupDecorator;

interface
uses
  windows,
  classes,
  sysUtils,
  menus,
  forms,
  virtualTrees,

  clsLists,
  clsAbstractPopupDecorator,
  clsMessageBox,
  clsApplication,
  clsTreeViewProxy,
  clsAbstractTreeModel,
  clsMulticastEvents;

type
  sMoveCheckedItemsInfo = record
    popupItemName: string;
    popupItemCaption: string;
    imageIndex: integer;

    questionTitle: string;
    questionCaption: string;
    questionMessageFormat: string;

    nothingToMoveCaption: string;
  end;

  cTreeViewProxyMovePopupDecorator = class(cAbstractPopupDecorator)
  private
    fMoveCheckedItemsInfo: sMoveCheckedItemsInfo;

    fDestinationNode: pVirtualNode;

    function    getCastedProxy: cTreeViewProxy;
    function    getProxyCheckedCount: integer;
    procedure   initialize;

    procedure   addPopupItems; override;

    procedure   setupEvents; override;
    procedure   disconnectEvents; override;

    procedure   setupViewProxyEvents; override;
    procedure   disconnectViewProxyEvents; override;

  public
    const

    DEFAULT_POPUP_MOVE_ITEMS_NAME = 'moveItems';
    DEFAULT_POPUP_DELETE_ITEMS_NAME = 'deleteItems';

    DEFAULT_POPUP_MOVE_ITEMS_CAPTION = 'move items';
    DEFAULT_POPUP_DELETE_ITEMS_CAPTION = 'move items';

    DEFAULT_MOVE_ITEMS_QUESTION_CAPTION = 'Move items';
    DEFAULT_MOVE_ITEMS_QUESTION_TITLE = 'Move items';
    DEFAULT_MOVE_ITEMS_QUESTION_MESSAGE_FORMAT = 'move selected (count: %d) to %s (id: %d)?';

    DEFAULT_MOVE_ITEMS_NOTHING_TO_MOVE_CAPTION = 'nothing to move!';
  public
    procedure   setMoveCheckedItemsInfo(aInfo: sMoveCheckedItemsInfo);
    function    getMoveCheckedItemsInfo: sMoveCheckedItemsInfo;

    constructor create;
    destructor  destroy; override;

  published
    //SLOTS
    procedure   popupItemClicked(aSender: tObject); override;
    procedure   popupInvoked(aSender: tObject); override;
  end;


implementation

{ cTreeViewProxyMovePopupDecorator }

constructor cTreeViewProxyMovePopupDecorator.create;
begin
  inherited create;

  fDestinationNode:= nil;

  initialize;
end;

destructor cTreeViewProxyMovePopupDecorator.destroy;
begin
  inherited;
end;

procedure cTreeViewProxyMovePopupDecorator.addPopupItems;
begin
  createMenuItem(getMoveCheckedItemsInfo.popupItemName, getMoveCheckedItemsInfo.popupItemCaption, getMoveCheckedItemsInfo.imageIndex);
end;

procedure cTreeViewProxyMovePopupDecorator.initialize;
var
  moveCheckedItemsInfo: sMoveCheckedItemsInfo;
begin
  moveCheckedItemsInfo.popupItemName:= DEFAULT_POPUP_MOVE_ITEMS_NAME;
  moveCheckedItemsInfo.popupItemCaption:= DEFAULT_POPUP_MOVE_ITEMS_CAPTION;
  moveCheckedItemsInfo.questionTitle:= DEFAULT_MOVE_ITEMS_QUESTION_TITLE;
  moveCheckedItemsInfo.questionCaption:= DEFAULT_MOVE_ITEMS_QUESTION_CAPTION;
  moveCheckedItemsInfo.questionMessageFormat:= DEFAULT_MOVE_ITEMS_QUESTION_MESSAGE_FORMAT;
  moveCheckedItemsInfo.imageIndex:= -1;

  moveCheckedItemsInfo.nothingToMoveCaption:= DEFAULT_MOVE_ITEMS_NOTHING_TO_MOVE_CAPTION;


  setMoveCheckedItemsInfo(moveCheckedItemsInfo);
end;

procedure cTreeViewProxyMovePopupDecorator.disconnectEvents;
begin

end;

procedure cTreeViewProxyMovePopupDecorator.disconnectViewProxyEvents;
begin

end;

function cTreeViewProxyMovePopupDecorator.getCastedProxy: cTreeViewProxy;
begin
  result:= viewProxy as cTreeViewProxy;
end;

function cTreeViewProxyMovePopupDecorator.getMoveCheckedItemsInfo: sMoveCheckedItemsInfo;
begin
  result:= fMoveCheckedItemsInfo;
end;

function cTreeViewProxyMovePopupDecorator.getProxyCheckedCount: integer;
begin
  result:= 0;

  if (not assigned(viewProxy)) then begin
    exit;
  end;

  result:= viewProxy.getCheckedCount;
end;

procedure cTreeViewProxyMovePopupDecorator.setMoveCheckedItemsInfo(aInfo: sMoveCheckedItemsInfo);
begin
  fMoveCheckedItemsInfo:= aInfo;
end;

procedure cTreeViewProxyMovePopupDecorator.setupEvents;
begin
end;

procedure cTreeViewProxyMovePopupDecorator.setupViewProxyEvents;
begin
end;

//SLOTS
procedure cTreeViewProxyMovePopupDecorator.popupInvoked(aSender: tObject);
var
  curItem: tMenuItem;
  i: integer;
begin
  for i:= 0 to menuItemsCount - 1 do begin
    curItem:= getMenuItem(i);

    curItem.enabled:= (not viewProxy.isEmpty) and (viewProxy.getCheckedCount > 0);
  end;
end;

procedure cTreeViewProxyMovePopupDecorator.popupItemClicked(aSender: tObject);
var
  popupItem: tMenuItem;
  popupClientPoint: tPoint;
  destNode: pVirtualNode;
  destItem: cTreeModelItem;
begin
  popupItem:= aSender as tMenuItem;
  if not assigned(popupItem) then begin
    exit;
  end;

  if (getProxyCheckedCount = 0) then begin
    cMessageBox.information(fMoveCheckedItemsInfo.questionCaption, fMoveCheckedItemsInfo.questionTitle, fMoveCheckedItemsInfo.nothingToMoveCaption);
    exit;
  end;


  popupClientPoint:= getCastedProxy.view.screenToClient(getPopupPoint);
  destNode:= getCastedProxy.getViewNodeAt(popupClientPoint);
  destItem:= getCastedProxy.getModelItemByViewNode(destNode);

  if (not assigned(destItem)) then begin
    exit;
  end;

  if (popupItem.name = DEFAULT_POPUP_MOVE_ITEMS_NAME) then begin
    if (cMessageBox.question(
      fMoveCheckedItemsInfo.questionCaption,
      fMoveCheckedItemsInfo.questionTitle,
      format(fMoveCheckedItemsInfo.questionMessageFormat, [getProxyCheckedCount,  destItem.title, destItem.id])) = mbbYes)
    then begin
      //getCastedProxy.moveItems(getCastedProxy.getSortedCheckedNodesOfView, destNode);
    end;

    exit;
  end;

end;

end.
