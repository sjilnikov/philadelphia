unit clsMemoryTreeModel;

interface
uses
  sysUtils,

  uModels,

  clsAbstractIOObject,

  clsMulticastEvents,

  clsMemory,
  clsStringUtils,

  clsAutoIncGenerator,
  clsClassKit,
  clsException,
  clsAbstractTreeModel,
  clsAbstractTableModel,
  clsMemoryTableModel,
  clsAbstractSQLCommandsBuilder,
  clsAbstractSQLDataBuilder;

type
  eMemoryTreeModel = class(cException);

  tMemoryTreeModelItemDataSaveToStreamProc = reference to procedure(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject);
  tMemoryTreeModelItemDataLoadFromStreamProc = reference to procedure(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject);

  tMemoryTreeModelSaveToStreamProc = reference to procedure(aSender: cAbstractTreeModel; aStream: cAbstractIOObject);
  tMemoryTreeModelLoadFromStreamProc = reference to procedure(aSender: cAbstractTreeModel; aStream: cAbstractIOObject);

  cMemoryTreeModel = class(cAbstractTreeModel)
  private
    const

    METHOD_NOT_IMPLEMENTED       = 'method not implemented';
  private
    fAutoIncGenerator           : cAutoIncGenerator;
    fItemDataSaveToStreamProc   : tMemoryTreeModelItemDataSaveToStreamProc;
    fItemDataLoadFromStreamProc : tMemoryTreeModelItemDataLoadFromStreamProc;

    fSaveToStreamProc           : tMemoryTreeModelSaveToStreamProc;
    fLoadFromStreamProc         : tMemoryTreeModelLoadFromStreamProc;

    function    getInternalTableModel: cAbstractTableModel; override;
    procedure   setTableModel(aTableModel: cAbstractTableModel); override;
    function    reload(aItem: cTreeModelItem): integer; overload; override;
  protected
    procedure   savingItemToStream(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject); virtual;
    procedure   loadingItemFromStream(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject); virtual;

    procedure   savingToStream(aSender: cAbstractTreeModel; aStream: cAbstractIOObject); virtual;
    procedure   loadingFromStream(aSender: cAbstractTreeModel; aStream: cAbstractIOObject); virtual;
  public
    procedure   setItemDataSaveToStreamProc(aProc: tMemoryTreeModelItemDataSaveToStreamProc);
    procedure   setItemDataLoadFromStreamProc(aProc: tMemoryTreeModelItemDataLoadFromStreamProc);

    procedure   setSaveToStreamProc(aProc: tMemoryTreeModelSaveToStreamProc);
    procedure   setLoadFromStreamProc(aProc: tMemoryTreeModelLoadFromStreamProc);

    procedure   clear;

    function    saveToStream(aStream: cAbstractIOObject): boolean;
    function    loadFromStream(aStream: cAbstractIOObject): boolean;

    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray);

    function    fetch(const aCondition: string = '1=1'; aLimit: integer = NO_CONSIDER_LIMIT; aOffset: integer = NO_CONSIDER_OFFSET): integer; override;

    function    append(aParentItem: cTreeModelItem; aTitle: string; aData: pointer = nil): cTreeModelItem; overload;
    function    append(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem; overload; override;

    function    appendToCache(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem; override;
    procedure   update(aItem: cTreeModelItem); override;
    procedure   moveTo(aFrom: cTreeModelItem; aTo: cTreeModelItem); override;

    procedure   expand(aItem: cTreeModelItem); override;

    procedure   delete(aItem: cTreeModelItem); override;
    procedure   deleteRecurse(aItem: cTreeModelItem); override;

    constructor create;
    destructor  destroy; override;
  published
    {$REGION 'SLOTS'}
    procedure   itemDataChanged(aItem: cTreeModelItem);
    {$ENDREGION}
  end;

implementation

{ cMemoryTreeModel }

function cMemoryTreeModel.append(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem;
begin
  beginDataChanging;
  try
    result:= inherited append(aParentItem, aId, aTitle);
    result:= appendToCache(aParentItem, aId, aTitle);

    connect(result, 'onDataChanged', self, 'itemDataChanged');
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;


function cMemoryTreeModel.append(aParentItem: cTreeModelItem; aTitle: string; aData: pointer): cTreeModelItem;
var
  newId: int64;
begin
  beginDataChanging;
  try
    newId:= fAutoIncGenerator.getNextValue;

    result:= inherited append(aParentItem, newId, aTitle);
    result:= appendToCache(aParentItem, newId, aTitle);
    result.data:= aData;

    connect(result, 'onDataChanged', self, 'itemDataChanged');
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

function cMemoryTreeModel.appendToCache(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem;
begin
  result:= inherited appendToCache(aParentItem, aId, aTitle);

  beginDataChanging;
  try

    result:= createItem(aParentItem, nil, aId, aTitle);
    setLastAppendedItem(result);

    itemAppended(self, getLastAppendedItem, aParentItem);
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

procedure cMemoryTreeModel.clear;
begin
  deleteRecurse(getRootItem);

  beginItemsAppending;
  try
    createRootItem;
  finally
    endItemsAppending;
  end;
end;

constructor cMemoryTreeModel.create;
begin
  inherited create;

  fAutoIncGenerator:= cAutoIncGenerator.create(0);
end;

destructor cMemoryTreeModel.destroy;
begin
  if assigned(fAutoIncGenerator) then begin
    freeAndNil(fAutoIncGenerator);
  end;

  inherited;
end;

procedure cMemoryTreeModel.delete(aItem: cTreeModelItem);
begin
  beginDataChanging;
  try
    inherited delete(aItem);
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

procedure cMemoryTreeModel.deleteRecurse(aItem: cTreeModelItem);
begin
  beginDataChanging;
  try
    inherited deleteRecurse(aItem);
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

procedure cMemoryTreeModel.expand(aItem: cTreeModelItem);
begin
  if not assigned(aItem) then exit;

//  if (aItem.isExpanded) then exit;

  aItem.setExpanded(true);

  inherited expand(aItem);
end;

function cMemoryTreeModel.fetch(const aCondition: string; aLimit, aOffset: integer): integer;
begin
  result:= 0;
  beginDataChanging;
  try
    beginDataFetching;
    try
      result:= inherited fetch(aCondition, aLimit, aOffset);
    finally
      endDataFetching;
    end;

  finally
    endDataChanging(ctTreeFetch);
  end;
end;

procedure cMemoryTreeModel.moveTo(aFrom, aTo: cTreeModelItem);
begin
  inherited moveTo(aFrom, aTo);
end;

function cMemoryTreeModel.reload(aItem: cTreeModelItem): integer;
begin
  raise eMemoryTreeModel.create(METHOD_NOT_IMPLEMENTED);
end;

procedure cMemoryTreeModel.restoreState(const aState: tBytesArray);
var
  memStream: cMemory;
begin
  memStream:= cMemory.create;
  try
    memStream.fromBytes(aState);

    if (memStream.size = 0) then exit;

    loadFromStream(memStream);
  finally
    freeAndNil(memStream);
  end;
end;

function cMemoryTreeModel.getInternalTableModel: cAbstractTableModel;
begin
  result:= nil;
end;

procedure cMemoryTreeModel.itemDataChanged(aItem: cTreeModelItem);
begin
  beginDataChanging;
  try

  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

function cMemoryTreeModel.loadFromStream(aStream: cAbstractIOObject): boolean;

procedure loadModelItems(aModelItem: cTreeModelItem; aChildCount: integer);
var
  childCount: integer;
  i: integer;
  id: int64;
  title: string;

  modelItem: cTreeModelItem;
begin
  for i:= 0 to aChildCount - 1 do begin
    aStream.readInteger(id);
    aStream.readUnicodeString(title);

    modelItem:= append(aModelItem, id, title);
    loadingItemFromStream(self, modelItem, aStream);


    aStream.readInteger(childCount);

    if (childCount > 0) then begin
      loadModelItems(modelItem, childCount);
    end;

  end;
end;

var
  lastAutoIncValue: int64;
  rootChildCount: integer;
begin
  clear;

  result:= false;
  try
    aStream.readInteger(lastAutoIncValue);

    loadingFromStream(self, aStream);

    fAutoIncGenerator.setCurrentValue(lastAutoIncValue);
    aStream.readInteger(rootChildCount);

    beginItemsAppending;
    try
      createRootItem;
      loadModelItems(getRootItem, rootChildCount);
    finally
      endItemsAppending;
    end;

    result:= true;
  except
    result:= false;
  end;
end;

procedure cMemoryTreeModel.loadingFromStream(aSender: cAbstractTreeModel; aStream: cAbstractIOObject);
begin
  if assigned(fLoadFromStreamProc) then begin
    fLoadFromStreamProc(self, aStream);
  end;
end;

procedure cMemoryTreeModel.loadingItemFromStream(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject);
begin
  if assigned(fItemDataLoadFromStreamProc) then begin
    fItemDataLoadFromStreamProc(self, aTreeModelItem, aStream);
  end;
end;

function cMemoryTreeModel.saveState: tBytesArray;
var
  memStream: cMemory;
begin
  result:= '';
  memStream:= cMemory.create;
  try
    saveToStream(memStream);

    result:= memStream.toBytes;
  finally
    freeAndNil(memStream);
  end;
end;

function cMemoryTreeModel.saveToStream(aStream: cAbstractIOObject): boolean;

procedure saveModelItems(aModelItem: cTreeModelItem);
var
  i: integer;
begin
  if not assigned(aModelItem) then exit;

  if (aModelItem <> getRootItem) then begin
    aStream.writeInteger(aModelItem.id);
    aStream.writeUnicodeString(aModelItem.title);

    savingItemToStream(self, aModelItem, aStream);
  end;

  aStream.writeInteger(aModelItem.childs.count);

  for i:= 0 to aModelItem.childs.count - 1 do begin
    saveModelItems(aModelItem.childs.items[i]);
  end;
end;

begin
  result:= false;
  try

    //save autoinc generator value
    aStream.writeInteger(fAutoIncGenerator.getCurrentValue);

    savingToStream(self, aStream);

    //save items
    saveModelItems(getRootItem);

    result:= true;
  except
    result:= false;
  end;
end;

procedure cMemoryTreeModel.savingItemToStream(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject);
begin
  if assigned(fItemDataSaveToStreamProc) then begin
    fItemDataSaveToStreamProc(self, aTreeModelItem, aStream);
  end;
end;

procedure cMemoryTreeModel.savingToStream(aSender: cAbstractTreeModel; aStream: cAbstractIOObject);
begin
  if assigned(fSaveToStreamProc) then begin
    fSaveToStreamProc(self, aStream);
  end;
end;

procedure cMemoryTreeModel.setItemDataLoadFromStreamProc(aProc: tMemoryTreeModelItemDataLoadFromStreamProc);
begin
  fItemDataLoadFromStreamProc:= aProc;
end;

procedure cMemoryTreeModel.setItemDataSaveToStreamProc(aProc: tMemoryTreeModelItemDataSaveToStreamProc);
begin
  fItemDataSaveToStreamProc:= aProc;
end;

procedure cMemoryTreeModel.setLoadFromStreamProc(
  aProc: tMemoryTreeModelLoadFromStreamProc);
begin

end;

procedure cMemoryTreeModel.setSaveToStreamProc(
  aProc: tMemoryTreeModelSaveToStreamProc);
begin

end;

procedure cMemoryTreeModel.setTableModel(aTableModel: cAbstractTableModel);
begin
  raise eMemoryTreeModel.create(METHOD_NOT_IMPLEMENTED);
end;

procedure cMemoryTreeModel.update(aItem: cTreeModelItem);
begin
  //do nothing
end;

end.
