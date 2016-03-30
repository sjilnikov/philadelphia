unit clsAbstractPopupDecorator;


interface
uses
  windows,
  classes,
  sysUtils,
  menus,
  forms,
  virtualTrees,

  clsAbstractViewProxy,
  clsLists,
  clsApplication,
  clsMulticastEvents;

type
  cMenuItems = class
  private
    fList: cList;
  public
    procedure   add(aItem: tMenuItem);
    function    getCount: integer;

    function    getItemByIndex(aIndex: integer): tMenuItem;
    function    indexOfName(aName: string): integer;

    constructor create;
    destructor  destroy; override;
  public
    property    items[aIndex: integer]: tMenuItem read getItemByIndex;
    property    count: integer read getCount;
  end;


  cAbstractPopupDecorator = class
  private
    fViewProxy  : cAbstractViewProxy;
    fMenuItems  : cMenuItems;
    fPopupMenu  : tPopupMenu;
    function    getMenuItemsCount: integer;
  protected
    procedure   addPopupItems; virtual; abstract;

    procedure   setupPopupEvents;
    procedure   disconnectPopupEvents;

    procedure   setupEvents; virtual; abstract;
    procedure   disconnectEvents; virtual; abstract;

    procedure   setupViewProxyEvents; virtual; abstract;
    procedure   disconnectViewProxyEvents; virtual; abstract;
  public
    function    getPopupPoint: tPoint;

    procedure   createMenuItem(aName: string; aCaption: string; aImageIndex: integer = -1);
    function    getMenuItem(aIndex: integer): tMenuItem; overload;
    function    getMenuItem(aName: string): tMenuItem; overload;

    procedure   setViewProxy(aViewProxy: cAbstractViewProxy); virtual;
    function    getViewProxy: cAbstractViewProxy;

    constructor create;
    destructor  destroy; override;

  published
    property    viewProxy: cAbstractViewProxy read getViewProxy;
    property    menuItemsCount: integer read getMenuItemsCount;
  //  property    menuItems:
  published
    //SLOTS
    procedure   popupItemClicked(aSender: tObject); virtual; abstract;
    procedure   popupInvoked(aSender: tObject); virtual; abstract;
  end;


implementation

{ cAbstractPopupDecorator }

procedure cAbstractPopupDecorator.createMenuItem(aName: string; aCaption: string; aImageIndex: integer);
var
  popupItem: tMenuItem;
begin
  popupItem:= fPopupMenu.createMenuItem;
  popupItem.caption:= aCaption;
  popupItem.name:= aName;
  popupItem.imageIndex:= aImageIndex;

  fMenuItems.add(popupItem);
  fPopupMenu.items.add(popupItem);
end;

constructor cAbstractPopupDecorator.create;
begin
  inherited create;

  fMenuItems:= cMenuItems.create;
  fPopupMenu:= nil;

  setupEvents;
  setupViewProxyEvents;
end;

destructor cAbstractPopupDecorator.destroy;
begin
  disconnectEvents;
  disconnectViewProxyEvents;
  disconnectPopupEvents;

  if assigned(fMenuItems) then begin
    freeAndNil(fMenuItems);
  end;

  inherited;
end;

procedure cAbstractPopupDecorator.disconnectPopupEvents;
var
  curItem: tMenuItem;
  i: integer;
begin
  for i:= 0 to fMenuItems.count - 1 do begin
    curItem:= fMenuItems.items[i];

    disconnect(curItem);
  end;

  disconnect(fPopupMenu, 'onPopup', self, 'popupInvoked');
end;

function cAbstractPopupDecorator.getMenuItem(aName: string): tMenuItem;
var
  foundIndex: integer;

begin
  result:= nil;

  foundIndex:= fMenuItems.indexOfName(aName);
  if (foundIndex = -1) then begin
    exit;
  end;

  result:= fMenuItems.items[foundIndex];
end;

function cAbstractPopupDecorator.getMenuItem(aIndex: integer): tMenuItem;
begin
  result:= fMenuItems.items[aIndex];
end;

function cAbstractPopupDecorator.getMenuItemsCount: integer;
begin
  result:= fMenuItems.count;
end;

function cAbstractPopupDecorator.getPopupPoint: tPoint;
begin
  result:= point(0,0);

  if not assigned(fPopupMenu) then begin
    exit;
  end;


  result:= fPopupMenu.popupPoint;
end;

function cAbstractPopupDecorator.getViewProxy: cAbstractViewProxy;
begin
  result:= fViewProxy;
end;

procedure cAbstractPopupDecorator.setupPopupEvents;
var
  curItem: tMenuItem;
  i: integer;
begin
  for i:= 0 to fMenuItems.count - 1 do begin
    curItem:= fMenuItems.items[i];

    connect(curItem, 'onClick', self, 'popupItemClicked');
  end;

  connect(fPopupMenu, 'onPopup', self, 'popupInvoked');
end;

procedure cAbstractPopupDecorator.setViewProxy(aViewProxy: cAbstractViewProxy);
begin
  disconnectViewProxyEvents;

  if (assigned(fViewProxy)) then begin
    disconnectPopupEvents;
  end;

  fViewProxy:= aViewProxy;

  if assigned(fViewProxy) then begin
    fPopupMenu:= aViewProxy.popupMenu;

    addPopupItems;
    setupPopupEvents;
  end;

  setupViewProxyEvents;
end;

{ cMenuItems }

procedure cMenuItems.add(aItem: tMenuItem);
begin
  fList.add(aItem);
end;

constructor cMenuItems.create;
begin
  inherited create;

  fList:= cList.create;
end;

destructor cMenuItems.destroy;
begin
  if assigned(fList) then begin
//    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

function cMenuItems.getCount: integer;
begin
  result:= fList.count;
end;

function cMenuItems.getItemByIndex(aIndex: integer): tMenuItem;
begin
  result:= fList.items[aIndex];
end;

function cMenuItems.indexOfName(aName: string): integer;
var
  i: integer;
  cutItem: tMenuItem;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    cutItem:= getItemByIndex(i);

    if cutItem.name = aName then begin
      result:= i;
      exit;
    end;

  end;

end;

end.
