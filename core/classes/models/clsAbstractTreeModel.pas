unit clsAbstractTreeModel;

interface
uses
  generics.collections,
  sysUtils,
  variants,
  strUtils,

  uModels,

  clsAbstractModel,
  clsIntegerList,
  clsMulticastEvents,

  clsAbstractTableModel,
  clsException,
  clsLists;

type
  eAbstractTreeModel = class(cException);

  eTreeCursor = class(cException);

  cAbstractTreeModel = class;

  cTreeModelItem = class;

  cTreeModelItems = class;

  tTreeModelItemDestroyEvent = procedure(aItem: cTreeModelItem) of object;
  tTreeModelItemDataChangedEvent = procedure(aItem: cTreeModelItem) of object;


  cTreeModelItem = class
  private
    const
    DEFAULT_ROOT_TITLE = 'root';
  private
    fOwner            : cAbstractTreeModel;
    fParent           : cTreeModelItem;
    fChilds           : cTreeModelItems;

    fSelected         : boolean;
    fId               : int64;
    fParentId         : int64;
    fTitle            : string;
    fData             : pointer;
    fTableRow         : cAbstractTableRow;

    fNextSibling      : cTreeModelItem;
    fPrevSibling      : cTreeModelItem;
    fExpanded         : boolean;

    fOnDestroy        : tTreeModelItemDestroyEvent;
    fOnDataChanged    : tTreeModelItemDataChangedEvent;

    procedure   setPrevSibling(aItem: cTreeModelItem);
    procedure   setNextSibling(aItem: cTreeModelItem);

    procedure   dataChanged;

    procedure   setId(aId: int64);
    procedure   setParentId(aParentId: int64);
    procedure   setSelected(aSelected: boolean);
    procedure   setTitle(aTitle: string);
    procedure   setData(const Value: pointer);
  public
    procedure   setTableRow(aRow: cAbstractTableRow);
    function    getTableRow: cAbstractTableRow;
    procedure   setExpanded(aValue: boolean);
    function    isExpanded: boolean;

    function    getObjectId: string;

    procedure   setParent(aParent: cTreeModelItem);

    function    getParent: cTreeModelItem;
    function    getChilds: cTreeModelItems;

    function    getPrevSibling: cTreeModelItem;
    function    getNextSibling: cTreeModelItem;

    constructor create(aTreeModel: cAbstractTreeModel);
    procedure   beforeDestruction; override;
    destructor  destroy; override;


  public
    property    data: pointer read fData write setData;
  published
    property    owner: cAbstractTreeModel read fOwner;
    property    parent: cTreeModelItem read getParent write setParent;
    property    childs: cTreeModelItems read getChilds;
    property    tableRow: cAbstractTableRow read getTableRow write setTableRow;

    property    objectId: string read getObjectId;

    property    selected: boolean read fSelected write setSelected;
    property    id: int64 read fId write setId;
    property    parentId: int64 read fParentId write setParentId;
    property    title: string read fTitle write setTitle;
  published
    //EVENTS
    property    onDestroy: tTreeModelItemDestroyEvent read fOnDestroy write fOnDestroy;
    property    onDataChanged: tTreeModelItemDataChangedEvent read fOnDataChanged write fOnDataChanged;
  end;

  cTreeModelItems = class
  private
    fList          : cList;

    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cTreeModelItem;
  public
    procedure   clear;

    procedure   addChild(aItem: cTreeModelItem);
    procedure   delete(aItem: cTreeModelItem);
    procedure   remove(aItem: cTreeModelItem);

    function    getLast: cTreeModelItem;
    function    getFirst: cTreeModelItem;


    procedure   deleteAllRecurse;
    procedure   deleteRecurse(aItem: cTreeModelItem); overload;


    constructor create;
    destructor  destroy; override;

    property    items[aIndex: integer]: cTreeModelItem read getItemByIndex;
    property    count: integer read getCount;
  end;


  cTreeCursor = class
  private
    const

    MOVE_NEXT_NOT_CALLED = 'cannot get current row, moveNext was not called';
  private
    fItemIndex   : integer;
    fTree        : cAbstractTreeModel;
    fCurrentItem : cTreeModelItem;

    procedure   setCurrentItem(aCurrentItem : cTreeModelItem);

    function    getItemsFetched: integer;
  public

    function    getCurrent: cTreeModelItem; inline;
    function    moveNext: boolean;

    property    current: cTreeModelItem read getCurrent;

    property    itemsFetched: integer read getItemsFetched;

    constructor create(aTree: cAbstractTreeModel);
  end;

  tAbstractTreeModelSelectedItemsConditionCheckProc = reference to function (aItem: cTreeModelItem): boolean;
  tAbstractTreeModelSelectedItemsAddProc = reference to function (aItem: cTreeModelItem): string;

  tAbstractTreeModelDataChangedType = (ctTreeFetch, ctTreeCRUID);

  tAbstractTreeModelItemReloadedEvent = procedure(aModel: cAbstractTreeModel; aItem: cTreeModelItem) of object;
  tAbstractTreeModelItemDeletingEvent = procedure(aModel: cAbstractTreeModel; aItem: cTreeModelItem) of object;
  tAbstractTreeModelItemDeletingRecurseEvent = procedure(aModel: cAbstractTreeModel; aItem: cTreeModelItem) of object;
  tAbstractTreeModelItemAppendedEvent = procedure(aModel: cAbstractTreeModel; aItem: cTreeModelItem; aParentItem: cTreeModelItem) of object;

  tAbstractTreeModelItemMovedToEvent = procedure(aModel: cAbstractTreeModel; aFrom: cTreeModelItem; aTo: cTreeModelItem) of object;
  tAbstractTreeModelItemExpandedEvent = procedure(aModel: cAbstractTreeModel; aItem: cTreeModelItem) of object;
  tAbstractTreeModelDataFetchingEvent = procedure(aModel: cAbstractTreeModel; const aCondition: string; var aLimit: integer; var aOffset: integer) of object;
  tAbstractTreeModelDataFetchedEvent = procedure(aModel: cAbstractTreeModel; const aCommand: string) of object;
  tAbstractTreeModelDataChangedEvent = procedure(aModel: cAbstractTreeModel; aType: tAbstractTreeModelDataChangedType) of object;
  tAbstractTreeModelConditionSettingEvent = procedure(aModel: cAbstractTreeModel; var aCondition: string) of object;

  tAbstractTreeModelBeginItemsAppending = procedure(aModel: cAbstractTreeModel) of object;
  tAbstractTreeModelEndItemsAppending = procedure(aModel: cAbstractTreeModel) of object;

  tAbstractTreeModelBeginItemsDeleting = procedure(aModel: cAbstractTreeModel) of object;
  tAbstractTreeModelEndItemsDeleting = procedure(aModel: cAbstractTreeModel) of object;

  tAbstractTreeModelBeginItemsReloading = procedure(aModel: cAbstractTreeModel) of object;
  tAbstractTreeModelEndItemsReloading = procedure(aModel: cAbstractTreeModel) of object;

  tAbstractTreeModelItemSettingFromTableModelEvent = procedure(aModel: cAbstractTreeModel; aItem: cTreeModelItem; aTableModelRow: cAbstractTableRow) of object;

  tAbstractTreeModelItemDestroyingEvent = procedure(aModel: cAbstractTreeModel; aItem: cTreeModelItem) of object;

  tAbstractTreeModelItemFilterProc = function (aModel: cAbstractTreeModel; aItem: cTreeModelItem): boolean of object;
  tAbstractTreeModelLocateCompareProc = reference to function (aItem: cTreeModelItem; aValue: variant): boolean;


  cTreeModelItemsList = class
  private
    fList       : cList;
  public
    procedure   add(aItem: cTreeModelItem);
    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cTreeModelItem;

    constructor create;
    destructor  destroy; override;

    property    items[aIndex: integer]: cTreeModelItem read getItemByIndex;
    property    count: integer read getCount;
  end;

  tTreeModelState = (tmsDataFetching, tmsDataChanging, tmsModelChanging, tmsConditionSetting, tmsItemsAppending, tmsItemsDeleting, tmsItemsReloading);

  tTreeModelStates = set of tTreeModelState;

  //lazy tree
  cAbstractTreeModel = class(cAbstractModel)
  private
    fRootItem                     : cTreeModelItem;
    fTableModel                   : cAbstractTableModel;

    fCondition                    : string;
    fLimit                        : integer;
    fOffset                       : integer;
    fLastAppendedItem             : cTreeModelItem;
    fFetchCommand                 : string;
    fOldCondition                 : string;
    fOldLimit                     : integer;
    fOldOffset                    : integer;

    fDeleting                     : boolean;
    fDeletedItems                 : cList;

    fStates                       : tTreeModelStates;

    fSelectorEnabled              : boolean;

    fOnItemReloaded               : tAbstractTreeModelItemReloadedEvent;
    fOnItemAppended               : tAbstractTreeModelItemAppendedEvent;
    fOnItemDeleting               : tAbstractTreeModelItemDeletingEvent;
    fOnItemDeletingRecurse        : tAbstractTreeModelItemDeletingRecurseEvent;
    fOnItemSettingFromTableModel  : tAbstractTreeModelItemSettingFromTableModelEvent;
    fOnDataFetching               : tAbstractTreeModelDataFetchingEvent;
    fOnDataFetched                : tAbstractTreeModelDataFetchedEvent;
    fOnDataChanged                : tAbstractTreeModelDataChangedEvent;

    fOnBeginItemsAppending        : tAbstractTreeModelBeginItemsAppending;
    fOnEndItemsAppending          : tAbstractTreeModelEndItemsAppending;

    fOnBeginItemsDeleting         : tAbstractTreeModelBeginItemsDeleting;
    fOnEndItemsDeleting           : tAbstractTreeModelEndItemsDeleting;

    fOnBeginItemsReloading        : tAbstractTreeModelBeginItemsReloading;
    fOnEndItemsReloading          : tAbstractTreeModelEndItemsReloading;
    fOnItemDestroying             : tAbstractTreeModelItemDestroyingEvent;



    fOnItemMovedTo                : tAbstractTreeModelItemMovedToEvent;
    fOnItemExpanded               : tAbstractTreeModelItemExpandedEvent;
    fOnConditionSetting           : tAbstractTreeModelConditionSettingEvent;

    procedure   setupTableModelEvents;
    procedure   disconnectTableModelEvents;

    procedure   beginDelete;
    procedure   endDelete;
    //
  protected
    procedure   itemReloaded(aModel: cAbstractTreeModel; aItem: cTreeModelItem);
    procedure   itemDeleting(aModel: cAbstractTreeModel; aItem: cTreeModelItem);
    procedure   itemDeletingRecurse(aModel: cAbstractTreeModel; aItem: cTreeModelItem);
    procedure   itemAppended(aModel: cAbstractTreeModel; aItem: cTreeModelItem; aParentItem: cTreeModelItem);
    procedure   itemMoved(aModel: cAbstractTreeModel; aFrom: cTreeModelItem; aTo: cTreeModelItem);


    procedure   removeRootItem;
    procedure   createRootItem;

    procedure   beginDataChanging;
    procedure   endDataChanging(aType: tAbstractTreeModelDataChangedType);
    procedure   dataChanged(aModel: cAbstractTreeModel; aType: tAbstractTreeModelDataChangedType);

    procedure   loadItemDataFromTableRow(aItem: cTreeModelItem; aTableModelRow: cAbstractTableRow);

    procedure   beginDataFetching;
    procedure   endDataFetching;
    procedure   dataFetched;

    procedure   setLastAppendedItem(aItem: cTreeModelItem);
    function    getLastAppendedItem: cTreeModelItem;

    procedure   setLimit(aLimit: integer);
    function    getLimit: integer;

    procedure   setOffset(aOffset: integer);
    function    getOffset: integer;

    procedure   setCondition(const aCondition: string);
    function    getCondition: string;
    procedure   conditionSetting(var aCondition: string);

    function    getFetchCommand: string;
    procedure   setFetchCommand(const aCommand: string);

    function    createItem(aParentItem: cTreeModelItem; aTableModelRow: cAbstractTableRow; aId: int64; aTitle: string): cTreeModelItem; virtual;


    procedure   internalDeleteItemsForFilter(aFilterProc: tAbstractTreeModelItemFilterProc; aDeleteOnlyFromCache: boolean);
  public
    const

    DEFAULT_PARENT_ID_FIELD_NAME = 'parent_id';
    DEFAULT_TITLE_FIELD_NAME     = 'title';
  public
    function    getSelectedItemsCheckProc(aItem: cTreeModelItem): boolean;
    function    getSelectedItemsIdsAddProc(aItem: cTreeModelItem): string;

    function    locate(aLocateCompareProc: tAbstractTreeModelLocateCompareProc; aValue: variant; aStartNode: cTreeModelItem; aSearchDirection: tModelSearchDirection = sdForward; aSearchPosition: tModelSearchPosition = spFirst): cTreeModelItem; overload;
    function    locate(aValue: variant; aStartNode: cTreeModelItem; aSearchDirection: tModelSearchDirection = sdForward; aSearchPosition: tModelSearchPosition = spFirst): cTreeModelItem; overload;

    function    locateByTitleEqualProc(aItem: cTreeModelItem; aValue: variant): boolean;
    function    locateByTitlePartProc(aItem: cTreeModelItem; aValue: variant): boolean;

    function    locateByIdEqualProc(aItem: cTreeModelItem; aValue: variant): boolean;
    //load level 0 items
    function    fetch(const aCondition: string; aLimit: integer; aOffset: integer): integer; overload; virtual;
    function    fetch(aId: int64): integer; overload; virtual;
    //

    function    reload(aItem: cTreeModelItem): integer; overload; virtual;
    function    reload(aItems: cTreeModelItemsList): integer; overload; virtual;
    function    reload: integer; overload; virtual;
    function    getInternalTableModel: cAbstractTableModel; virtual; abstract;

    function    deleteSelectedlItemsFilterProc(aModel: cAbstractTreeModel; aModelItem: cTreeModelItem): boolean;

    procedure   deleteForFilter(aFilterProc: tAbstractTreeModelItemFilterProc);
    procedure   deleteFromCacheForFilter(aFilterProc: tAbstractTreeModelItemFilterProc);

    procedure   deleteSelectedItems;
    procedure   deleteSelectedItemsFromCache;


    procedure   beginItemsAppending;
    procedure   endItemsAppending;

    procedure   beginItemsDeleting;
    procedure   endItemsDeleting;

    procedure   beginItemsReloading;
    procedure   endItemsReloading;

    procedure   beginModelChanging;
    procedure   endModelChanging;

    function    getIterator: cTreeCursor;

    function    getSelectedItemsIds(aDelimiter: string = ','): string;
    function    getSelectedItems: cTreeModelItems;

    function    getSelectedItemsData(aAddProc: tAbstractTreeModelSelectedItemsAddProc; aDelimiter: string; aQuote: string; aConditionCheckProc: tAbstractTreeModelSelectedItemsConditionCheckProc): string;
    procedure   setItemsSelected(aValue: boolean); overload;
    procedure   setItemsSelected(aIds: string; aValue: boolean); overload;
    procedure   setItemSelected(aItem: cTreeModelItem; aValue: boolean);

    function    getSelectedItemsCount: integer;

    function    getRootItem: cTreeModelItem;

    //root item is not included
    function    getItemLevel(aCurrentItem: cTreeModelItem): integer;

    function    getTableModel: cAbstractTableModel;
    procedure   setTableModel(aTableModel: cAbstractTableModel); virtual;

    function    appendToCache(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem; virtual;

    function    append(aParentItem: cTreeModelItem; aTitle: string): cTreeModelItem; overload; virtual;
    function    append(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem; overload; virtual;
    function    append: cTreeModelItem; overload; virtual;
    function    append(aParentItem: cTreeModelItem): cTreeModelItem; overload; virtual;

    function    addDataPortion(aParentItem: cTreeModelItem; aCondition: string; aLimit: integer; aOffset: integer): boolean; overload; virtual;
    function    addDataPortion(aParentItem: cTreeModelItem; aId: int64): boolean; overload; virtual;
    function    fetchMore(aParentItem: cTreeModelItem): boolean; virtual;

    procedure   update(aItem: cTreeModelItem); virtual; abstract;


    function    getFirstParentItem(aCurrentItem: cTreeModelItem; aExcludeRoot: boolean = true): cTreeModelItem;
    function    getNextItem(aCurrentItem: cTreeModelItem): cTreeModelItem;
    function    getPrevItem(aCurrentItem: cTreeModelItem): cTreeModelItem;
    function    getFirstItem(aCurItem: cTreeModelItem): cTreeModelItem;
    function    getLastItem(aCurItem: cTreeModelItem): cTreeModelItem;

    procedure   moveTo(aFrom: cTreeModelItem; aTo: cTreeModelItem); virtual;

    //lazy load item
    procedure   expand(aItem: cTreeModelItem); virtual;

    procedure   delete(aItem: cTreeModelItem); virtual;
    procedure   deleteRecurse(aItem: cTreeModelItem); virtual;

    procedure   deleteFromCache(aItem: cTreeModelItem); virtual;
    procedure   deleteRecurseFromCache(aItem: cTreeModelItem); virtual;

    procedure   enableSelector(aValue: boolean); virtual;
    function    isSelectorEnabled: boolean;

    constructor create;
    destructor  destroy; override;

    property    rootItem: cTreeModelItem read getRootItem;
    property    tableModel: cAbstractTableModel read getTableModel;
  published
    //SLOTS
    procedure   itemDestroying(aItem: cTreeModelItem); virtual;

  published
    //EVENTS
    property    onConditionSetting: tAbstractTreeModelConditionSettingEvent read fOnConditionSetting write fOnConditionSetting;

    property    onItemReloaded: tAbstractTreeModelItemReloadedEvent read fOnItemReloaded write fOnItemReloaded;
    property    onItemAppended: tAbstractTreeModelItemAppendedEvent read fOnItemAppended write fOnItemAppended;

    property    onItemDeleting: tAbstractTreeModelItemDeletingEvent read fOnItemDeleting write fOnItemDeleting;
    property    onItemDeletingRecurse: tAbstractTreeModelItemDeletingRecurseEvent read fOnItemDeletingRecurse write fOnItemDeletingRecurse;

    property    onBeginItemsAppending: tAbstractTreeModelBeginItemsAppending read fOnBeginItemsAppending write fOnBeginItemsAppending;
    property    onEndItemsAppending: tAbstractTreeModelEndItemsAppending read fOnEndItemsAppending write fOnEndItemsAppending;

    property    onBeginItemsDeleting: tAbstractTreeModelBeginItemsDeleting read fOnBeginItemsDeleting write fOnBeginItemsDeleting;
    property    onEndItemsDeleting: tAbstractTreeModelEndItemsDeleting read fOnEndItemsDeleting write fOnEndItemsDeleting;

    property    onBeginItemsReloading: tAbstractTreeModelBeginItemsReloading read fOnBeginItemsReloading write fOnBeginItemsReloading;
    property    onEndItemsReloading: tAbstractTreeModelEndItemsReloading read fOnEndItemsReloading write fOnEndItemsReloading;


    property    onDataFetched: tAbstractTreeModelDataFetchedEvent read fOnDataFetched write fOnDataFetched;
    property    onDataFetching: tAbstractTreeModelDataFetchingEvent read fOnDataFetching write fOnDataFetching;
    property    onDataChanged: tAbstractTreeModelDataChangedEvent read fOnDataChanged write fOnDataChanged;

    property    onItemMovedTo: tAbstractTreeModelItemMovedToEvent read fOnItemMovedTo write fOnItemMovedTo;
    property    onItemExpanded: tAbstractTreeModelItemExpandedEvent read fOnItemExpanded write fOnItemExpanded;

    property    onItemSettingFromTableModel: tAbstractTreeModelItemSettingFromTableModelEvent read fOnItemSettingFromTableModel write fOnItemSettingFromTableModel;
    property    onItemDestroying: tAbstractTreeModelItemDestroyingEvent read fOnItemDestroying write fOnItemDestroying;
  end;

implementation

{ cTreeModelItems }

procedure cTreeModelItems.addChild(aItem: cTreeModelItem);
var
  addingItem: cTreeModelItem;
  lastItem: cTreeModelItem;
begin
  addingItem:= aItem;
  lastItem:= getLast;

  if assigned(lastItem) then begin
    addingItem.setPrevSibling(lastItem);
    addingItem.setNextSibling(nil);

    lastItem.setNextSibling(addingItem);
  end else begin
    addingItem.setPrevSibling(nil);
    addingItem.setNextSibling(nil);
  end;

  fList.add(aItem);

end;

procedure cTreeModelItems.clear;
begin
  fList.freeInternalObjects;
  fList.clear;
end;

constructor cTreeModelItems.create;
begin
  inherited  create;

  fList:= cList.create;
end;


procedure cTreeModelItems.delete(aItem: cTreeModelItem);
begin
  remove(aItem);
  freeAndNil(aItem);
end;

procedure cTreeModelItems.deleteAllRecurse;
var
  curItem: cTreeModelItem;
begin
  while (count > 0) do begin
    curItem:= items[count - 1];

    deleteRecurse(curItem);
  end;
end;

procedure cTreeModelItems.deleteRecurse(aItem: cTreeModelItem);
begin
  if (aItem.childs.count <> 0) then begin
    aItem.childs.deleteAllRecurse;
  end;

  delete(aItem);
end;

destructor cTreeModelItems.destroy;
begin
  if (assigned(fList)) then begin
    clear;
    freeAndNil(fList);
  end;

  inherited;
end;

procedure cTreeModelItems.remove(aItem: cTreeModelItem);
var
  removingItem: cTreeModelItem;
  removingPrev: cTreeModelItem;
  removingNext: cTreeModelItem;
begin
  removingItem:= aItem;
  removingPrev:= removingItem.getPrevSibling;
  removingNext:= removingItem.getNextSibling;

  if assigned(removingPrev) then begin
    removingPrev.setNextSibling(removingNext);
  end;

  if assigned(removingNext) then begin
    removingNext.setPrevSibling(removingPrev);
  end;

  fList.remove(aItem);
end;

function cTreeModelItems.getCount: integer;
begin
  result:= fList.count;
end;

function cTreeModelItems.getFirst: cTreeModelItem;
begin
  result:= nil;

  if (count = 0) then begin
    exit;
  end;

  result:= items[0];
end;

function cTreeModelItems.getItemByIndex(aIndex: integer): cTreeModelItem;
begin
  result:= fList.items[aIndex];
end;

function cTreeModelItems.getLast: cTreeModelItem;
begin
  result:= nil;

  if (count = 0) then begin
    exit;
  end;

  result:= items[count - 1];
end;

{ cTreeModelItem }

procedure cTreeModelItem.beforeDestruction;
begin
  if (assigned(fOnDestroy)) then begin
    fOnDestroy(self);
  end;

  inherited beforeDestruction;
end;

constructor cTreeModelItem.create(aTreeModel: cAbstractTreeModel);
begin
  inherited create;

  fOwner          := aTreeModel;
  fChilds         := cTreeModelItems.create;
  fParent         := nil;


  fPrevSibling    := nil;
  fNextSibling    := nil;
  fSelected       := false;
  fId             := -1;
  fParentId       := -1;
  fTitle          := '';
  fData           := nil;
  fTableRow       := nil;
  fExpanded       := false;
end;

procedure cTreeModelItem.dataChanged;
begin
  if assigned(fOnDataChanged) then begin
    fOnDataChanged(self);
  end;
end;

destructor cTreeModelItem.destroy;
begin
  if (assigned(fTableRow)) then begin
    freeAndNil(fTableRow);
  end;

  if (assigned(fChilds)) then begin
    freeAndNil(fChilds);
  end;

  disconnect(self);

  inherited;
end;

function cTreeModelItem.getChilds: cTreeModelItems;
begin
  result:= fChilds;
end;

function cTreeModelItem.getNextSibling: cTreeModelItem;
begin
  result:= fNextSibling;
end;

function cTreeModelItem.getObjectId: string;
var
  activeRecord: cAbstractTableRow;
begin
  result:= '';
  activeRecord:= fOwner.getInternalTableModel.createActiveRecord;
  try
    if (activeRecord.fetch(id) <> 0) then begin
      result:= activeRecord.getObjectId;
    end;
  finally
    freeAndNil(activeRecord);
  end;
end;

function cTreeModelItem.getParent: cTreeModelItem;
begin
  result:= fParent;
end;

function cTreeModelItem.getPrevSibling: cTreeModelItem;
begin
  result:= fPrevSibling;
end;

function cTreeModelItem.getTableRow: cAbstractTableRow;
begin
  result:= fTableRow;
end;

function cTreeModelItem.isExpanded: boolean;
begin
  result:= fExpanded;
end;

procedure cTreeModelItem.setData(const Value: pointer);
begin
  fData := Value;

  dataChanged;
end;

procedure cTreeModelItem.setExpanded(aValue: boolean);
begin
  fExpanded:= aValue;
end;

procedure cTreeModelItem.setId(aId: int64);
begin
  fId := aId;

  if assigned(fTableRow) then begin
    fTableRow.setPropertyData(cAbstractTableModel.DEFAULT_KEY_FIELD_NAME, aId);
  end;

  dataChanged;
end;

procedure cTreeModelItem.setNextSibling(aItem: cTreeModelItem);
begin
  fNextSibling:= aItem;
end;

procedure cTreeModelItem.setParent(aParent: cTreeModelItem);
begin
  if (assigned(fParent)) then begin
    fParent.childs.remove(self);
  end;

  if (assigned(aParent)) then begin
    aParent.childs.addChild(self);
  end;

  fParent:= aParent;

  if assigned(fParent) then begin
    fParentId:= fParent.id;
  end else begin
    fParentId:= 0;
  end;
end;

procedure cTreeModelItem.setParentId(aParentId: int64);
begin
  fParentId := aParentId;

  if assigned(fTableRow) then begin
    fTableRow.setPropertyData(cAbstractTreeModel.DEFAULT_PARENT_ID_FIELD_NAME, aParentId);
  end;

  dataChanged;
end;

procedure cTreeModelItem.setPrevSibling(aItem: cTreeModelItem);
begin
  fPrevSibling:= aItem;
end;

procedure cTreeModelItem.setSelected(aSelected: boolean);
begin
  fSelected := aSelected;

  if assigned(fTableRow) then begin
    fTableRow.setPropertyData(cAbstractTableModel.DEFAULT_SELECTOR_FIELD_NAME, aSelected);
  end;

  dataChanged;
end;

procedure cTreeModelItem.setTableRow(aRow: cAbstractTableRow);
begin
  if assigned(fTableRow) then begin
    freeAndNil(fTableRow);
  end;

  fTableRow := aRow;
end;

procedure cTreeModelItem.setTitle(aTitle: string);
begin
  fTitle := aTitle;

  if assigned(fTableRow) then begin
    fTableRow.setPropertyData(cAbstractTreeModel.DEFAULT_TITLE_FIELD_NAME, aTitle);
  end;

  dataChanged;
end;

{ cAbstractTreeModel }

constructor cAbstractTreeModel.create;
begin
  inherited create;

  fStates         := [];
  fDeletedItems   := nil;

  fTableModel     := nil;
  fSelectorEnabled:= true;
end;

function cAbstractTreeModel.createItem(aParentItem: cTreeModelItem; aTableModelRow: cAbstractTableRow; aId: int64; aTitle: string): cTreeModelItem;
begin
  result:= cTreeModelItem.create(self);

  result.id:= aId;
  result.title:= aTitle;

  result.setParent(aParentItem);

  loadItemDataFromTableRow(result, aTableModelRow);

  connect(result, 'onDestroy', self, 'itemDestroying');
end;

procedure cAbstractTreeModel.loadItemDataFromTableRow(aItem: cTreeModelItem; aTableModelRow: cAbstractTableRow);
var
  tableRow: cAbstractTableRow;
begin
  tableRow:= nil;

  if assigned(aTableModelRow) then begin
    tableRow:= aTableModelRow.getOwner.createIteratorRow;
    tableRow.copyFrom(aTableModelRow);
  end else begin
    if assigned(fTableModel) then begin
      tableRow:= fTableModel.createIteratorRow;
      tableRow.setPropertyData(cAbstractTableRow.DEFAULT_ID_PROPERTY, NEW_KEY_ID);
      tableRow.setPropertyData(DEFAULT_PARENT_ID_FIELD_NAME, aItem.parentId);
      tableRow.setPropertyData(DEFAULT_TITLE_FIELD_NAME, aItem.title);
    end;
  end;

  aItem.setTableRow(tableRow); //automatically free if assigned

  if assigned(fOnItemSettingFromTableModel) then begin
    fOnItemSettingFromTableModel(self, aItem, aTableModelRow);
  end;
end;

function cAbstractTreeModel.locate(aLocateCompareProc: tAbstractTreeModelLocateCompareProc; aValue: variant; aStartNode: cTreeModelItem; aSearchDirection: tModelSearchDirection; aSearchPosition: tModelSearchPosition): cTreeModelItem;
var
  curItem: cTreeModelItem;

  startItem: cTreeModelItem;
begin
  result:= nil;

  startItem:= nil;
  case aSearchPosition of

    spFirst:
    begin
      startItem:= getFirstItem(getRootItem);
    end;

    spCurrent:
    begin
      startItem:= aStartNode;
    end;

    spNextFromCurrent:
    begin
      startItem:= getNextItem(aStartNode);
    end;

    spPrevFromCurrent:
    begin
      startItem:= getPrevItem(aStartNode);
    end;

    spLast:
    begin
      startItem:= getLastItem(getRootItem);
    end;
  end;


  curItem:= startItem;
  while assigned(curItem) do begin

    if aLocateCompareProc(curItem, aValue) then begin
      result:= curItem;

      exit;
    end;

    if (aSearchDirection = sdForward) then begin
      curItem:= getNextItem(curItem);
    end else begin
      curItem:= getPrevItem(curItem);
    end;

  end;
end;

function cAbstractTreeModel.locate(aValue: variant; aStartNode: cTreeModelItem; aSearchDirection: tModelSearchDirection; aSearchPosition: tModelSearchPosition): cTreeModelItem;
begin
  result:= locate(locateByTitleEqualProc, aValue, aStartNode, aSearchDirection, aSearchPosition);
end;

function cAbstractTreeModel.locateByIdEqualProc(aItem: cTreeModelItem; aValue: variant): boolean;
begin
  result:= (aItem.id = aValue);
end;

function cAbstractTreeModel.locateByTitleEqualProc(aItem: cTreeModelItem; aValue: variant): boolean;
begin
  result:= (aItem.title = varToStr(aValue));
end;

function cAbstractTreeModel.locateByTitlePartProc(aItem: cTreeModelItem; aValue: variant): boolean;
begin
  result:= containsText(aItem.title, varToStr(aValue));
end;

procedure cAbstractTreeModel.createRootItem;
begin
  removeRootItem;
  fRootItem:= createItem(nil, nil, 0, cTreeModelItem.DEFAULT_ROOT_TITLE);
end;

destructor cAbstractTreeModel.destroy;
begin
  disconnectTableModelEvents;

  removeRootItem;

  inherited;
end;

procedure cAbstractTreeModel.expand(aItem: cTreeModelItem);
begin
  if assigned(fOnItemExpanded) then begin
    fOnItemExpanded(self, aItem);
  end;
end;

function cAbstractTreeModel.fetch(const aCondition: string; aLimit, aOffset: integer): integer;
begin
  result:= 0;

  createRootItem;

  fOldCondition:= aCondition;
  fOldLimit:= aLimit;
  fOldOffset:= aOffset;

  setCondition(aCondition);

  setLimit(aLimit);
  setOffset(aOffset);
end;

procedure cAbstractTreeModel.endDataFetching;
begin
  try
    dataFetched;
  finally
    exclude(fStates, tmsDataFetching);
  end;
end;

procedure cAbstractTreeModel.beginDataFetching;
var
  newLimit: integer;
  newOffset: integer;
begin
  include(fStates, tmsDataFetching);

  if assigned(fOnDataFetching) then begin
    newLimit:= getLimit;
    newOffset:= getOffset;

    fOnDataFetching(self, getCondition, newLimit, newOffset);

    setLimit(newLimit);
    setOffset(newOffset);
  end;
end;

procedure cAbstractTreeModel.beginDataChanging;
begin
  include(fStates, tmsDataChanging);
end;

procedure cAbstractTreeModel.enableSelector(aValue: boolean);
begin
  fSelectorEnabled:= aValue;
end;

procedure cAbstractTreeModel.endDataChanging(aType: tAbstractTreeModelDataChangedType);
begin
  try
    dataChanged(self, aType);
  finally
    exclude(fStates, tmsDataChanging);
  end;
end;

procedure cAbstractTreeModel.dataChanged(aModel: cAbstractTreeModel; aType: tAbstractTreeModelDataChangedType);
begin
  if assigned(fOnDataChanged) then begin
    fOnDataChanged(self, aType);
  end;
end;

procedure cAbstractTreeModel.dataFetched;
begin
  if assigned(fOnDataFetched) then begin
    fOnDataFetched(self, getFetchCommand);
  end;
end;

function cAbstractTreeModel.fetch(aId: int64): integer;
begin
  result:= fetch(getInternalTableModel.getKeyCondition(aId), NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);
end;

function cAbstractTreeModel.addDataPortion(aParentItem: cTreeModelItem; aCondition: string; aLimit, aOffset: integer): boolean;
var
  i: integer;
  titleFieldIndex: integer;
begin
  result:= false;

  if (getTableModel.fetch(aCondition, aLimit, aOffset) = 0) then exit;

  titleFieldIndex:= getTableModel.getFields.indexOfName(DEFAULT_TITLE_FIELD_NAME);

  for i:= 0 to getTableModel.getRowCount - 1 do begin
    appendToCache(aParentItem, getTableModel.getRowKey(i), getTableModel.getFieldData(titleFieldIndex, i));
  end;

  result:= true;
end;

function cAbstractTreeModel.fetchMore(aParentItem: cTreeModelItem): boolean;
begin
  result:= false;
  if (fLimit = NO_CONSIDER_LIMIT) or (fOffset = NO_CONSIDER_OFFSET) then exit;

  setOffset(fLimit + fOffset);

  result:= addDataPortion(aParentItem, getCondition, fLimit, getOffset);
end;

function cAbstractTreeModel.addDataPortion(aParentItem: cTreeModelItem; aId: int64): boolean;
begin
  result:= addDataPortion(aParentItem, fTableModel.getKeyCondition(aId), NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);
end;

function cAbstractTreeModel.append: cTreeModelItem;
begin
  result:= append(getRootItem, '');
end;

function cAbstractTreeModel.append(aParentItem: cTreeModelItem): cTreeModelItem;
begin
  result:= append(aParentItem, '');
end;

function cAbstractTreeModel.append(aParentItem: cTreeModelItem; aTitle: string): cTreeModelItem;
begin
  result:= append(aParentItem, NEW_KEY_ID, aTitle);
end;

function cAbstractTreeModel.append(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem;
begin
  result:= nil;
  expand(aParentItem);
end;

function cAbstractTreeModel.appendToCache(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem;
begin
  result:= nil;
end;

procedure cAbstractTreeModel.deleteRecurse(aItem: cTreeModelItem);
begin
  deleteRecurseFromCache(aItem);
  //user logic in descendant classes
end;

procedure cAbstractTreeModel.deleteRecurseFromCache(aItem: cTreeModelItem);
begin
  beginDataChanging;
  try
    if (not(assigned(aItem))) then exit;


    if (aItem = fRootItem) then begin
      freeAndNil(fRootItem);

      exit;
    end;


    if (not(assigned(aItem.parent))) then exit;


    itemDeletingRecurse(self, aItem);
    aItem.parent.childs.deleteRecurse(aItem);

  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

procedure cAbstractTreeModel.delete(aItem: cTreeModelItem);
begin
  deleteFromCache(aItem);
  //user logic in descendant classes
end;

procedure cAbstractTreeModel.deleteFromCache(aItem: cTreeModelItem);
begin
  beginDataChanging;
  try
    if (not(assigned(aItem))) then exit;


    if (aItem = fRootItem) then begin
      freeAndNil(fRootItem);

      exit;
    end;


    if (not(assigned(aItem.parent))) then exit;

    itemDeleting(self, aItem);
    aItem.parent.childs.delete(aItem);
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

function cAbstractTreeModel.getCondition: string;
begin
  result:= fCondition;
end;

function cAbstractTreeModel.getFetchCommand: string;
begin
  result:= fFetchCommand;
end;

function cAbstractTreeModel.getFirstItem(aCurItem: cTreeModelItem): cTreeModelItem;
begin
  result:= nil;
  if not assigned(aCurItem) then exit;


  expand(aCurItem);
  result:= aCurItem;

  if (result.childs.count <> 0) then begin
    result:= result.childs.items[0];
  end;
end;

function cAbstractTreeModel.getFirstParentItem(aCurrentItem: cTreeModelItem; aExcludeRoot: boolean): cTreeModelItem;
var
  parentItem: cTreeModelItem;
begin
  result:= nil;

  if not assigned(aCurrentItem) then begin
    exit;
  end;

  parentItem:= aCurrentItem.getParent;
  if aExcludeRoot then begin
    if parentItem = fRootItem then exit;
  end;

  while assigned(parentItem) do begin
    result:= parentItem;

    parentItem:= parentItem.getParent;

    if aExcludeRoot then begin
      if parentItem = fRootItem then exit;
    end;

  end;

end;

procedure cAbstractTreeModel.deleteForFilter(aFilterProc: tAbstractTreeModelItemFilterProc);
begin
  internalDeleteItemsForFilter(aFilterProc, false);
end;

procedure cAbstractTreeModel.deleteFromCacheForFilter(aFilterProc: tAbstractTreeModelItemFilterProc);
begin
  internalDeleteItemsForFilter(aFilterProc, true);
end;

procedure cAbstractTreeModel.internalDeleteItemsForFilter(aFilterProc: tAbstractTreeModelItemFilterProc; aDeleteOnlyFromCache: boolean);
var
  curModelItem: cTreeModelItem;
  treeCursor: cTreeCursor;

  deletingItems: cList;
  i: integer;
begin
  beginDataChanging;
  try
    beginItemsDeleting;
    try


      deletingItems:= cList.create;
      try

        treeCursor:= getIterator;
        try

          while (treeCursor.moveNext) do begin
            curModelItem:= treeCursor.getCurrent;

            if aFilterProc(self, curModelItem) then begin
              deletingItems.add(curModelItem);
            end;

          end;


        finally
          freeAndNil(treeCursor);
        end;


        beginDelete;
        try

          for i:= 0 to deletingItems.count - 1 do begin

            if (fDeletedItems.indexOf(deletingItems.items[i]) <> -1) then continue;

            if aDeleteOnlyFromCache then begin
              deleteRecurseFromCache(deletingItems.items[i]);
            end else begin
              deleteRecurse(deletingItems.items[i]);
            end;

          end;

        finally
          endDelete;
        end;

      finally
        freeAndNil(deletingItems);
      end;
    finally
      endItemsDeleting;
    end;
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

function cAbstractTreeModel.isSelectorEnabled: boolean;
begin
  result:= fSelectorEnabled;
end;

procedure cAbstractTreeModel.itemAppended(aModel: cAbstractTreeModel; aItem, aParentItem: cTreeModelItem);
begin
  if assigned(fOnItemAppended) then begin
    fOnItemAppended(self, getLastAppendedItem, aParentItem);
  end;
end;

procedure cAbstractTreeModel.itemDeleting(aModel: cAbstractTreeModel; aItem: cTreeModelItem);
begin
  if assigned(fOnItemDeleting) then begin
    fOnItemDeleting(self, aItem);
  end;
end;

procedure cAbstractTreeModel.itemDeletingRecurse(aModel: cAbstractTreeModel; aItem: cTreeModelItem);
begin
  if assigned(fOnItemDeletingRecurse) then begin
    fOnItemDeletingRecurse(self, aItem);
  end;
end;

procedure cAbstractTreeModel.itemMoved(aModel: cAbstractTreeModel; aFrom, aTo: cTreeModelItem);
begin
  if assigned(fOnItemMovedTo) then begin
    fOnItemMovedTo(self, aFrom, aTo);
  end;
end;

procedure cAbstractTreeModel.itemReloaded(aModel: cAbstractTreeModel; aItem: cTreeModelItem);
begin
  if assigned(fOnItemReloaded) then begin
    fOnItemReloaded(self, aItem);
  end;
end;

procedure cAbstractTreeModel.beginDelete;
begin
  fDeletedItems:= cList.create;
  fDeleting:= true;
end;

procedure cAbstractTreeModel.beginItemsAppending;
begin
  include(fStates, tmsItemsAppending);

  if assigned(fOnBeginItemsAppending) then begin
    fOnBeginItemsAppending(self);
  end;
end;

procedure cAbstractTreeModel.beginItemsDeleting;
begin
  include(fStates, tmsItemsDeleting);
  if assigned(fOnBeginItemsDeleting) then begin
    fOnBeginItemsDeleting(self);
  end;
end;

procedure cAbstractTreeModel.beginItemsReloading;
begin
  include(fStates, tmsItemsReloading);
  if assigned(fOnBeginItemsReloading) then begin
    fOnBeginItemsReloading(self);
  end;
end;

procedure cAbstractTreeModel.beginModelChanging;
begin
  include(fStates, tmsModelChanging);
end;

procedure cAbstractTreeModel.endDelete;
begin
  freeAndNil(fDeletedItems);
  fDeleting:= false;
end;

procedure cAbstractTreeModel.endItemsAppending;
begin
  try
    if assigned(fOnEndItemsAppending) then begin
      fOnEndItemsAppending(self);
    end;
  finally
    exclude(fStates, tmsItemsAppending);
  end;
end;

procedure cAbstractTreeModel.endItemsDeleting;
begin
  try
    if assigned(fOnEndItemsDeleting) then begin
      fOnEndItemsDeleting(self);
    end;
  finally
    exclude(fStates, tmsItemsDeleting);
  end;
end;

procedure cAbstractTreeModel.endItemsReloading;
begin
  try
    if assigned(fOnEndItemsReloading) then begin
      fOnEndItemsReloading(self);
    end;
  finally
    exclude(fStates, tmsItemsReloading);
  end;
end;

procedure cAbstractTreeModel.endModelChanging;
begin
  exclude(fStates, tmsModelChanging);

  reload;
end;

procedure cAbstractTreeModel.deleteSelectedItems;
begin
  deleteForFilter(deleteSelectedlItemsFilterProc);
end;

function cAbstractTreeModel.deleteSelectedlItemsFilterProc(aModel: cAbstractTreeModel; aModelItem: cTreeModelItem): boolean;
begin
  result:= aModelItem.selected;
end;

procedure cAbstractTreeModel.deleteSelectedItemsFromCache;
begin
  deleteFromCacheForFilter(deleteSelectedlItemsFilterProc);
end;

function cAbstractTreeModel.getItemLevel(aCurrentItem: cTreeModelItem): integer;
var
  parent: cTreeModelItem;
begin
  result:= 0;

  if not assigned(aCurrentItem) then exit;

  parent:= aCurrentItem.getParent;
  while assigned(parent) and (parent <> getRootItem) do begin
    inc(result);

    parent:= parent.getParent;
  end;

end;

function cAbstractTreeModel.getIterator: cTreeCursor;
begin
  result:= cTreeCursor.create(self);
end;

function cAbstractTreeModel.getLastItem(aCurItem: cTreeModelItem): cTreeModelItem;
var
  i: integer;
  curItem: cTreeModelItem;
begin
  result:= nil;
  if not assigned(aCurItem) then exit;

  expand(aCurItem);
  result:= aCurItem;

  for i:= 0 to result.childs.count - 1 do begin
    curItem:= result.childs.items[i];

    result:= getLastItem(curItem);
  end;
end;

function cAbstractTreeModel.getLimit: integer;
begin
  result:= fLimit;
end;

function cAbstractTreeModel.getSelectedItemsIds(aDelimiter: string): string;
begin
  result:= getSelectedItemsData(getSelectedItemsIdsAddProc, ',', '', getSelectedItemsCheckProc);
end;

function cAbstractTreeModel.getNextItem(aCurrentItem: cTreeModelItem): cTreeModelItem;
var
  parentItem: cTreeModelItem;
  parentNextItem: cTreeModelItem;
begin
  result:= nil;

  if not assigned(aCurrentItem) then begin
    exit;
  end;

  expand(aCurrentItem);

  if (aCurrentItem.childs.count = 0) then begin
    result:= aCurrentItem.getNextSibling;

    if assigned(result) then begin
      exit;
    end;

    parentItem:= aCurrentItem.getParent;
    while assigned(parentItem) do begin
      parentNextItem:= parentItem.getNextSibling;

      if assigned(parentNextItem) then begin
        result:= parentNextItem;
        exit;
      end;

      parentItem:= parentItem.getParent;
    end;


  end else begin
    result:= getFirstItem(aCurrentItem);
  end;

end;

function cAbstractTreeModel.getOffset: integer;
begin
  result:= fOffset;
end;

function cAbstractTreeModel.getPrevItem(aCurrentItem: cTreeModelItem): cTreeModelItem;
var
  prevItem: cTreeModelItem;
begin
  result:= nil;

  if not assigned(aCurrentItem) then exit;

  prevItem:= aCurrentItem.getPrevSibling;
  expand(prevItem);

  if (prevItem.childs.count = 0) then begin
    result:= prevItem;
  end else begin
    result:= getLastItem(prevItem);
  end;

end;

function cAbstractTreeModel.getRootItem: cTreeModelItem;
begin
  result:= fRootItem;
end;

function cAbstractTreeModel.getSelectedItems: cTreeModelItems;
begin
  result:= nil;
end;

function cAbstractTreeModel.getSelectedItemsCount: integer;
var
  curModelItem: cTreeModelItem;

  iterator: cTreeCursor;
begin
  result:= 0;

  iterator:= getIterator;
  try
    while iterator.moveNext do begin
      curModelItem:= iterator.getCurrent;

      if curModelItem.selected then begin
        inc(result);
      end;
    end;

  finally
    freeAndNil(iterator);
  end;
end;

function cAbstractTreeModel.getSelectedItemsData(aAddProc: tAbstractTreeModelSelectedItemsAddProc; aDelimiter, aQuote: string; aConditionCheckProc: tAbstractTreeModelSelectedItemsConditionCheckProc): string;
var
  curModelItem: cTreeModelItem;

  iterator: cTreeCursor;
begin
  result:= '';

  iterator:= getIterator;
  try
    while iterator.moveNext do begin
      curModelItem:= iterator.getCurrent;

      if not aConditionCheckProc(curModelItem) then begin
        continue;
      end;

      result:= result + aDelimiter + aQuote + aAddProc(curModelItem) + aQuote;
    end;

  finally
    freeAndNil(iterator);
  end;

  system.delete(result, 1, length(aDelimiter));
end;

function cAbstractTreeModel.getSelectedItemsCheckProc(aItem: cTreeModelItem): boolean;
begin
  result:= aItem.selected;
end;

function cAbstractTreeModel.getSelectedItemsIdsAddProc(aItem: cTreeModelItem): string;
begin
  result:= intToStr(aItem.id);
end;

function cAbstractTreeModel.getTableModel: cAbstractTableModel;
begin
  result:= fTableModel;
end;

procedure cAbstractTreeModel.moveTo(aFrom, aTo: cTreeModelItem);
begin
  if not assigned(aFrom) then exit;

  if (not aTo.isExpanded) then expand(aTo);

  aFrom.setParent(aTo);

  itemMoved(self, aFrom, aTo);
  //user logic in decendant classes
end;

function cAbstractTreeModel.reload(aItem: cTreeModelItem): integer;
begin
  result:= 0;
end;

function cAbstractTreeModel.reload: integer;
begin
  result:= fetch(fOldCondition, fOldLimit, fOldOffset);
end;

function cAbstractTreeModel.reload(aItems: cTreeModelItemsList): integer;
var
  i: integer;
begin
  result:= 0;
  beginItemsReloading;
  try
    for i:= 0 to aItems.count - 1 do begin
      reload(aItems.items[i]);
    end;
  finally
    endItemsReloading;
  end;
end;

procedure cAbstractTreeModel.removeRootItem;
begin
  if (assigned(fRootItem)) then begin
    freeAndNil(fRootItem);
  end;
end;

procedure cAbstractTreeModel.setupTableModelEvents;
begin
end;

procedure cAbstractTreeModel.disconnectTableModelEvents;
begin
end;

procedure cAbstractTreeModel.setCondition(const aCondition: string);
var
  newCondition: string;
begin
  newCondition:= aCondition;

  conditionSetting(newCondition);
  fCondition:= newCondition;
end;

procedure cAbstractTreeModel.conditionSetting(var aCondition: string);
begin
  include(fStates, tmsConditionSetting);
  try
    if assigned(fOnConditionSetting) then begin
      fOnConditionSetting(self, aCondition);
    end;
  finally
    exclude(fStates, tmsConditionSetting);
  end;
end;

procedure cAbstractTreeModel.setFetchCommand(const aCommand: string);
begin
  fFetchCommand:= aCommand;
end;

procedure cAbstractTreeModel.setItemSelected(aItem: cTreeModelItem; aValue: boolean);
var
  reloading: boolean;
begin
  if not assigned(aItem) then exit;

  reloading:= (tmsItemsReloading in fStates);

  if not (reloading) then begin
    beginItemsReloading;
  end;
  try
    aItem.selected:= aValue;
    itemReloaded(self, aItem);
  finally
    if not (reloading) then begin
      endItemsReloading;
    end;
  end;
end;

procedure cAbstractTreeModel.setItemsSelected(aIds: string; aValue: boolean);
var
  idsList: cIntegerList;
  i: integer;
  curId: int64;

  findedItem: cTreeModelItem;
begin
  idsList:= cIntegerList.create;
  try
    idsList.addItemsByDelimitedString(aIds);

    beginItemsReloading;
    try
      for i:= 0 to idsList.count - 1 do begin
        curId:= idsList.items[i];

        findedItem:= locate(locateByIdEqualProc, curId, getRootItem);
        if assigned(findedItem) then begin
          setItemSelected(findedItem, aValue);
        end;

      end;
    finally
      endItemsReloading;
    end;

  finally
    freeAndNil(idsList);
  end;
end;

procedure cAbstractTreeModel.setItemsSelected(aValue: boolean);
var
  iterator: cTreeCursor;
  curItem: cTreeModelItem;
begin
  beginItemsReloading;
  try
    iterator:= getIterator;
    try
      while iterator.moveNext do begin
        curItem:= iterator.getCurrent;

        setItemSelected(curItem, aValue);
      end;
    finally
      freeAndNil(iterator);
    end;
  finally
    endItemsReloading;
  end;
end;

function cAbstractTreeModel.getLastAppendedItem: cTreeModelItem;
begin
  result:= fLastAppendedItem;
end;

procedure cAbstractTreeModel.setLastAppendedItem(aItem: cTreeModelItem);
begin
  fLastAppendedItem:= aItem;
end;

procedure cAbstractTreeModel.setLimit(aLimit: integer);
begin
  fLimit:= aLimit;
end;

procedure cAbstractTreeModel.setOffset(aOffset: integer);
begin
  fOffset:= aOffset;
end;

procedure cAbstractTreeModel.setTableModel(aTableModel: cAbstractTableModel);
begin
  disconnectTableModelEvents;

  fTableModel:= aTableModel;

  setupTableModelEvents;

  //user logic in decendant classes
end;

//SLOTS
procedure cAbstractTreeModel.itemDestroying(aItem: cTreeModelItem);
begin
  disconnect(aItem, 'onDestroy', self, 'itemDestroying');

  if assigned(fDeletedItems) then begin
    fDeletedItems.add(aItem);
  end;

  if assigned(fOnItemDestroying) then begin
    fOnItemDestroying(self, aItem);
  end;

end;

{ cTreeCursor }

constructor cTreeCursor.create(aTree: cAbstractTreeModel);
begin
  inherited create;
  fTree:= aTree;
  fCurrentItem:= fTree.getRootItem;
  fItemIndex := -1;
end;

function cTreeCursor.getCurrent: cTreeModelItem;
begin
  if (fItemIndex = -1) then begin
    raise eTreeCursor.create(MOVE_NEXT_NOT_CALLED);
  end;

  result:= fCurrentItem;
end;

function cTreeCursor.getItemsFetched: integer;
begin
  result:= fItemIndex + 1;
end;

function cTreeCursor.moveNext: boolean;
var
  nextItem: cTreeModelItem;
begin
  result:= false;
  if (not assigned(fTree)) then begin
    exit;
  end;

  nextItem:= fTree.getNextItem(fCurrentItem);
  setCurrentItem(nextItem);
  inc(fItemIndex);

  result:= assigned(nextItem);
end;

procedure cTreeCursor.setCurrentItem(aCurrentItem: cTreeModelItem);
begin
  fCurrentItem:= aCurrentItem;
end;

{ cTreeModelItemsList }

constructor cTreeModelItemsList.create;
begin
  inherited create;
  fList:= cList.create;
end;

destructor cTreeModelItemsList.destroy;
begin
  if assigned(fList) then begin
    freeAndNil(fList);
  end;

  inherited;
end;

procedure cTreeModelItemsList.add(aItem: cTreeModelItem);
begin
  fList.add(aItem);
end;

function cTreeModelItemsList.getCount: integer;
begin
  result:= fList.count;
end;

function cTreeModelItemsList.getItemByIndex(aIndex: integer): cTreeModelItem;
begin
  result:= fList.items[aIndex];
end;

end.
