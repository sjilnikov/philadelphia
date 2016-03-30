unit clsStringListModel;

interface
uses
  classes,
  db,
  variants,
  typInfo,
  sysUtils,
  math,

  uModels,
  uSQLDrivers,

  clsException,
  clsClassKit,

  clsAutoIncGenerator,

  clsMemory,
  clsAbstractIOObject,
  clsDBTypeConversion,
  clsDynamicalObject,
  clsLists,
  clsStringUtils,
  clsAbstractTableModel,
  clsAbstractSQLQuery,
  clsVariantConversion;

type
  eStringListModel = class(cException);


  cStringListRow = class(cAbstractTableRow)
    //STUB
  end;

  cStringListModel = class(cAbstractTableModel)
  private
    const

    ROW_ACTIONPROC_NOT_ASSIGNED     = 'row actionProc not assigned';
    FIELD_CACHE_COUNT_ERROR         = 'field count: %d not equal field count: %d';
    FETCH_ROW_ERROR                 = 'fetch rows error, fetched: %d';
    CANNOT_MODIFY_KEY_COL           = 'cannot modify key col';
    METHOD_NOT_IMPLEMENTED          = 'method not implemented';

    DEFAULT_STRING_LIST_FIELD_NAME  = 'title';
    DEFAUKT_STRING_LIST_FIELD_TITLE = 'title';
  private
    fStringList        : tStringList;

    procedure   setupEvents;
    procedure   disconnectEvents;

  protected

    function    copyDataFromTable(aSourceTable: cAbstractTableModel; aSourceRow: integer; aDestTable: cAbstractTableModel; aDestRow: integer): boolean; override;

    function    insert(aRow: cAbstractTableRow; aId: int64 = NEW_KEY_ID): int64; override;
    function    update(aRow: cAbstractTableRow; aId: int64 = USE_RECORD_ID; aUpdatingFieldNames: string = ''): integer; override;
    function    delete(aRow: cAbstractTableRow): integer; override;

    procedure   updateRowCount; override;

  public
    procedure   setStringList(aStringList: tStringList);
    function    getStringList: tStringList;

    procedure   sort(aSortDirection: tTableFieldSortDirection);

    function    getAggregateCommand(aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes; aUserCondition: string = ''): string; override;
    function    getFullRowCountWithoutLimits: integer; override;

    //defined by user
    function    loadRowData(aRowIndex: integer; aRow: cAbstractTableRow): boolean; override;

    function    createActiveRecord: cAbstractTableRow; override;

    procedure   moveToRow(aRow: integer); override;

    function    getFieldData(aCol: integer; aRow: integer; aGetDataRole: tTableModelDataRole = drUseRelation): variant; overload; override;
    function    getFieldData(aName: string; aRow: integer; aGetDataRole: tTableModelDataRole = drUseRelation): variant; overload; override;


    procedure   setCacheFieldData(aCol: integer; aRow: integer; const aValue: variant); override;

    procedure   enableSelector(aValue: boolean); override;
    function    getFieldType(aCol: integer): tDataType; override;
    procedure   setFieldData(aCol: integer; aRow: integer; const aValue: variant); override;
    function    appendRow(aId: int64 = NEW_KEY_ID): integer; override;
    function    appendRowToCache: integer; override;

    procedure   deleteRow(aRow: integer); override;
    procedure   deleteRowFromCache(aRow: integer); override;

    function    getRowKey(aRow: integer): int64; override;

    function    rawFetch(const aCommand: string): integer; override;
    function    fetch(const aCondition: string; aLimit: integer; aOffset: integer): integer; overload; override;
    function    fetch(aId: int64): integer; overload; override;

    function    reload(aRow: integer): integer; overload; override;

    constructor create; override;
    destructor  destroy; override;
  published
    //SLOTS
    procedure   fieldSortDirectionChanged(aSender: cTableFields; aField: cTableField; aOldDirection: tTableFieldSortDirection);
  end;


implementation
uses
  clsMulticastEvents,
  clsSQLQueryFactory;


{ cStringListModel }

constructor cStringListModel.create;
begin
  inherited create;

  setRowClass(cStringListRow);

  setupEvents;

  addField(DEFAULT_STRING_LIST_FIELD_NAME, DEFAUKT_STRING_LIST_FIELD_TITLE, false, sdNone);
end;

function cStringListModel.createActiveRecord: cAbstractTableRow;
begin
  result:= nil;
  raise eStringListModel.create(METHOD_NOT_IMPLEMENTED);
end;

destructor cStringListModel.destroy;
begin
  disconnectEvents;

  inherited;
end;

function cStringListModel.getRowKey(aRow: integer): int64;
begin
  result:= NOT_VALID_KEY_ID;
end;

function cStringListModel.appendRowToCache: integer;
begin
  beginDataChanging;
  try
    result:= fStringList.add('');

    setLastAppededRow(result);

    inherited appendRowToCache;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cStringListModel.copyDataFromTable(aSourceTable: cAbstractTableModel; aSourceRow: integer; aDestTable: cAbstractTableModel; aDestRow: integer): boolean;
var
  sourceFieldCount, destFieldCount: integer;
  i: integer;
begin
  beginDataChanging;
  try
    result:= false;

    sourceFieldCount:= aSourceTable.getFields.count;
    destFieldCount:= aDestTable.getFields.count;

    if (sourceFieldCount <> destFieldCount) then begin
      raise eStringListModel.createFmt(FIELD_CACHE_COUNT_ERROR, [sourceFieldCount, destFieldCount]);
    end;

    for i:= 0 to sourceFieldCount - 1 do begin
      setCacheFieldData(i, aDestRow, aSourceTable.getFieldData(i, aSourceRow));
    end;

    result:= true;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

procedure cStringListModel.updateRowCount;
begin
  setRowCount(fStringList.count);

  inherited updateRowCount;
end;

procedure cStringListModel.sort(aSortDirection: tTableFieldSortDirection);
var
  foundIndex: integer;
  foundField: cTableField;
begin
  foundIndex:= getFields.indexOfName(DEFAULT_STRING_LIST_FIELD_NAME);
  if (foundIndex = -1) then begin
    exit;
  end;

  getFields.items[foundIndex].sortDirection:= aSortDirection;
end;

procedure cStringListModel.setupEvents;
begin
  connect(getFields, 'onSortDirectionChanged', self, 'fieldSortDirectionChanged');
end;

procedure cStringListModel.disconnectEvents;
begin
  disconnect(getFields, 'onSortDirectionChanged', self, 'fieldSortDirectionChanged');
end;

procedure cStringListModel.enableSelector(aValue: boolean);
begin
  raise eStringListModel.create(METHOD_NOT_IMPLEMENTED);
end;

function cStringListModel.fetch(aId: int64): integer;
begin
  result:= fetch(getKeyCondition(aId), NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);
end;

function cStringListModel.rawFetch(const aCommand: string): integer;
begin
  result:= 0;
  if (tmsConditionSetting in getStates) then exit;

  setFetchCommand(aCommand);

  beginDataChanging;
  try

    if not assigned(nativeIteratorRow) then begin
      raise eStringListModel.create(cAbstractTableModel.ITERATOR_ROW_NOT_ASSIGNED);
    end;

    updateRowCount;

    result:= getRowCount;

  finally
    endDataChanging(ctTableFetch);
  end;
end;

function cStringListModel.fetch(const aCondition: string; aLimit: integer; aOffset: integer): integer;
begin
  result:= inherited fetch(aCondition, aLimit, aOffset);

  result:= rawFetch(aCondition);
end;

function cStringListModel.getFieldData(aCol, aRow: integer; aGetDataRole: tTableModelDataRole): variant;
var
  fieldValue: variant;
begin
  fieldValue:= null;
  try
    if (getRowCount = 0) then begin
      exit;
    end;

    fieldValue:= fStringList.strings[aRow];
  finally
    fieldDataGetting(aCol, aRow, fieldValue);
    result:= fieldValue;
  end;
end;

function cStringListModel.getFieldData(aName: string; aRow: integer; aGetDataRole: tTableModelDataRole): variant;
begin
  result:= null;
  raise eStringListModel.create(METHOD_NOT_IMPLEMENTED);
end;

function cStringListModel.getFieldType(aCol: integer): tDataType;
begin
  result:= dtString;
end;

function cStringListModel.getFullRowCountWithoutLimits: integer;
begin
  result:= fStringList.count;
end;

function cStringListModel.getAggregateCommand(aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes; aUserCondition: string): string;
begin
  result:= '';
  raise eStringListModel.create(METHOD_NOT_IMPLEMENTED);
end;

function cStringListModel.insert(aRow: cAbstractTableRow; aId: int64): int64;
begin
  result:= NOT_VALID_KEY_ID;
  raise eStringListModel.create(METHOD_NOT_IMPLEMENTED);
end;

function cStringListModel.update(aRow: cAbstractTableRow; aId: int64; aUpdatingFieldNames: string): integer;
begin
  result:= 0;
  raise eStringListModel.create(METHOD_NOT_IMPLEMENTED);
end;

function cStringListModel.delete(aRow: cAbstractTableRow): integer;
begin
  result:= 0;
  raise eStringListModel.create(METHOD_NOT_IMPLEMENTED);
end;

procedure cStringListModel.deleteRow(aRow: integer);
var
  deletingKey: int64;
begin
  inherited deleteRow(aRow);

  beginDataChanging;
  try
    deletingKey:= getRowKey(aRow);

    deleteRowFromCache(aRow);

    updateRowCount;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

procedure cStringListModel.deleteRowFromCache(aRow: integer);
begin
  beginDataChanging;
  try
    rowDeleting(aRow);

    fStringList.delete(aRow);
    inherited deleteRowFromCache(aRow);
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cStringListModel.loadRowData(aRowIndex: integer; aRow: cAbstractTableRow): boolean;
begin
  //stub
  result:= false;
end;

procedure cStringListModel.moveToRow(aRow: integer);
begin
  //stub
end;

function cStringListModel.reload(aRow: integer): integer;
begin
  result:= inherited reload(aRow);

  beginRowsReloading;
  try
    setFieldData(DEFAULT_STRING_LIST_FIELD_NAME, aRow, fStringList.strings[aRow]);
    result:= 1;
  finally
    endRowsReloading;
  end;

end;

procedure cStringListModel.setFieldData(aCol, aRow: integer; const aValue: variant);
var
  updatingKey: int64;
  activeRecord: cAbstractTableRow;

  updatingField: cTableField;

  fieldValue: variant;
begin
  fieldValue:= aValue;

  fieldDataSetting(aCol, aRow, fieldValue);

  inherited setFieldData(aCol, aRow, fieldValue);


  beginDataChanging;
  try

    {if (not isIdEditable) and (aCol = getFields.getKeyFieldIndex) then begin
      raise eStringListModel.create(CANNOT_MODIFY_KEY_COL);
    end;}

    updatingField:= getFields.items[aCol];

    if (not updatingField.readOnly) then begin
      setCacheFieldData(aCol, aRow, fieldValue);
    end;

    if (updatingField.readOnly) then begin
      exit;
    end;

  finally
    endDataChanging(ctTableCRUID);
  end;
end;

procedure cStringListModel.setStringList(aStringList: tStringList);
begin
  fStringList:= aStringList;

  if assigned(fStringList) then begin
    fetch('1=1', NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);
  end;
end;

function cStringListModel.getStringList: tStringList;
begin
  result:= fStringList;
end;

procedure cStringListModel.setCacheFieldData(aCol, aRow: integer; const aValue: variant);
begin
  beginDataChanging;
  try
    inherited setCacheFieldData(aCol, aRow, aValue);

    fStringList.strings[aRow]:= aValue;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cStringListModel.appendRow(aId: int64): integer;
var
  appendedKey: int64;
begin
  result:= inherited appendRow;
  beginDataChanging;
  try
    result:= appendRowToCache;

    if (aId <> NEW_KEY_ID) then begin
      setFieldData(getFields.getKeyFieldIndex, result, aId);
    end;

    updateRowCount;

    appendedKey:= getRowKey(result);

    addAppendedKey(appendedKey);

    insertDynamicData(appendedKey);

  finally
    endDataChanging(ctTableCRUID);
  end;
end;

//SLOTS
procedure cStringListModel.fieldSortDirectionChanged(aSender: cTableFields; aField: cTableField; aOldDirection: tTableFieldSortDirection);
begin
  if (aField.sortDirection = aOldDirection) then exit;

  case aField.sortDirection of
    sdAsc : fStringList.customSort(cStringListSortAlghoritms.compareStringsAsc);
    sdDesc: fStringList.customSort(cStringListSortAlghoritms.compareStringsDesc);
  end;
end;

end.

