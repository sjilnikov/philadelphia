unit clsMemoryTableModel;

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
  eMemoryTableModel = class(cException);


  cMemoryTableRow = class(cAbstractTableRow)
    //STUB
  end;

  cMemoryTableModelAutoIncGenerator = class(cAutoIncGenerator)
  private
    fField      : cTableField;
  public
    procedure   setField(aField: cTableField);
    function    getField: cTableField;

    constructor create(aStartValue: int64; aField: cTableField);
  end;

  cMemoryTableModelAutoIncGenerators = class
  private
    fList     : cList;
  public
    function    saveToStream(aStream: cAbstractIOObject): boolean;
    function    loadFromStream(aStream: cAbstractIOObject): boolean;

    function    indexOfField(aField: cTableField): integer;

    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cMemoryTableModelAutoIncGenerator;
    function    getItemByField(aField: cTableField): cMemoryTableModelAutoIncGenerator;
    procedure   add(aGenerator: cMemoryTableModelAutoIncGenerator);

    constructor create;
    destructor  destroy; override;

    property    items[aIndex: integer]: cMemoryTableModelAutoIncGenerator read getItemByIndex; default;
    property    items[aField: cTableField]: cMemoryTableModelAutoIncGenerator read getItemByField; default;

    property    count: integer read getCount;
  end;


  cMemoryTableModel = class(cAbstractTableModel)
  private
    const

    ROW_ACTIONPROC_NOT_ASSIGNED  = 'row actionProc not assigned';
    FIELD_CACHE_COUNT_ERROR      = 'field count: %d not equal field count: %d';
    FETCH_ROW_ERROR              = 'fetch rows error, fetched: %d';
    CANNOT_MODIFY_KEY_COL        = 'cannot modify key col';
    METHOD_NOT_IMPLEMENTED       = 'method not implemented';
  private
    fQuery             : cAbstractSQLQuery;

    fAutoIncFields     : cTableFields;
    fAutoIncGenerators : cMemoryTableModelAutoIncGenerators;

    procedure   setupEvents;
    procedure   disconnectEvents;

    procedure   createIndexes(aField: cTableField);
  protected
    function    copyDataFromTable(aSourceTable: cAbstractTableModel; aSourceRow: integer; aDestTable: cAbstractTableModel; aDestRow: integer): boolean; override;

    function    insert(aRow: cAbstractTableRow; aId: int64 = NEW_KEY_ID): int64; override;
    function    update(aRow: cAbstractTableRow; aId: int64 = USE_RECORD_ID; aUpdatingFieldNames: string = ''): integer; override;
    function    delete(aRow: cAbstractTableRow): integer; override;

    procedure   createDependsObjects;
    procedure   destroyDependsObjects;

    procedure   updateRowCount; override;
    procedure   resort;

  public
    function    getAutoIncFields: cTableFields;

    procedure   sort(aFieldName: string; aSortDirection: tTableFieldSortDirection);

    function    saveToStream(aStream: cAbstractIOObject): boolean;
    function    loadFromStream(aStream: cAbstractIOObject): boolean;

    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray);

    function    getQuery: cAbstractSQLQuery;

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
    function    addField(aName, aTitle: string; aType: tDataType; aSize: integer; aAutoInc: boolean; aReadOnly: boolean; aSortDirection: tTableFieldSortDirection = sdNone): cTableField;

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

    property    autoIncFields: cTableFields read getAutoIncFields;
  published
    //SLOTS
    procedure   fieldSortDirectionChanged(aSender: cTableFields; aField: cTableField; aOldDirection: tTableFieldSortDirection);
    procedure   rowAppended(aSender: cAbstractSQLQuery; aRow: integer);
  end;


implementation
uses
  clsMulticastEvents,
  clsSQLQueryFactory;


{ cMemoryTableModel }

constructor cMemoryTableModel.create;
begin
  inherited create;

  fAutoIncFields:= cTableFields.create(false);
  fAutoIncGenerators:= cMemoryTableModelAutoIncGenerators.create;

  setRowClass(cMemoryTableRow);

  createDependsObjects;

  setupEvents;
end;

function cMemoryTableModel.createActiveRecord: cAbstractTableRow;
begin
  result:= nil;
  raise eMemoryTableModel.create(METHOD_NOT_IMPLEMENTED);
end;

destructor cMemoryTableModel.destroy;
begin
  disconnectEvents;

  if assigned(fAutoIncGenerators) then begin
    freeAndNil(fAutoIncGenerators);
  end;

  if assigned(fAutoIncFields) then begin
    freeAndNil(fAutoIncFields);
  end;

  destroyDependsObjects;

  inherited;
end;

function cMemoryTableModel.getRowKey(aRow: integer): int64;
begin
  result:= fQuery.getField(getFields.getKeyFieldIndex, aRow).asInteger;
end;

function cMemoryTableModel.appendRowToCache: integer;
var
  selectorIndex: integer;
begin
  beginDataChanging;
  try
    result:= fQuery.appendRow;

    selectorIndex:= getFields.getSelectorFieldIndex;
    if (selectorIndex <> -1) then begin
      setCacheFieldData(selectorIndex, result, false);
    end;

    setLastAppededRow(result);

    inherited appendRowToCache;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cMemoryTableModel.copyDataFromTable(aSourceTable: cAbstractTableModel; aSourceRow: integer; aDestTable: cAbstractTableModel; aDestRow: integer): boolean;
var
  sourceFieldCount, destFieldCount: integer;
  i: integer;

  selectorFieldIndex: integer;
begin
  beginDataChanging;
  try
    result:= false;

    selectorFieldIndex:= getFields.getSelectorFieldIndex;

    sourceFieldCount:= aSourceTable.getFields.count;
    destFieldCount:= aDestTable.getFields.count;

    if (sourceFieldCount <> destFieldCount) then begin
      raise eMemoryTableModel.createFmt(FIELD_CACHE_COUNT_ERROR, [sourceFieldCount, destFieldCount]);
    end;

    for i:= 0 to sourceFieldCount - 1 do begin

      if (i = selectorFieldIndex) then begin
        continue;
      end;

      setCacheFieldData(i, aDestRow, aSourceTable.getFieldData(i, aSourceRow));
    end;

    result:= true;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

procedure cMemoryTableModel.updateRowCount;
begin
  setRowCount(fQuery.getRowCount);

  inherited updateRowCount;
end;

procedure cMemoryTableModel.setupEvents;
begin
  connect(getFields, 'onSortDirectionChanged', self, 'fieldSortDirectionChanged');

  connect(getQuery, 'onRowAppended', self, 'rowAppended');
end;

procedure cMemoryTableModel.sort(aFieldName: string; aSortDirection: tTableFieldSortDirection);
var
  foundIndex: integer;
  foundField: cTableField;
begin
  foundIndex:= getFields.indexOfName(aFieldName);
  if (foundIndex = -1) then begin
    exit;
  end;

  getFields.items[foundIndex].sortDirection:= aSortDirection;
end;

procedure cMemoryTableModel.disconnectEvents;
begin
  disconnect(getFields, 'onSortDirectionChanged', self, 'fieldSortDirectionChanged');
  disconnect(getQuery, 'onRowAppended', self, 'rowAppended');
end;

procedure cMemoryTableModel.enableSelector(aValue: boolean);
const
  DEFAULT_SELECTOR_INDEX = 0;

begin
  inherited enableSelector(aValue);

  if (aValue) then begin
    fQuery.insertField(DEFAULT_SELECTOR_INDEX, DEFAULT_SELECTOR_FIELD_NAME, '', dtBoolean, 0);
  end else begin
    fQuery.deleteField(DEFAULT_SELECTOR_FIELD_NAME);
  end;
end;

function cMemoryTableModel.fetch(aId: int64): integer;
begin
  result:= fetch(getKeyCondition(aId), NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);
end;

procedure cMemoryTableModel.createIndexes(aField: cTableField);
const
  INDEX_DESC_FORMAT = 'idx_desc_%s';
  INDEX_ASC_FORMAT  = 'idx_asc_%s';
var
  indexDefs: tIndexDefs;
  indexOptions: tIndexOptions;

  foundIndex: integer;
  indexName: string;

  curField: cTableField;
  i: integer;
begin
  indexDefs:= fQuery.getIndexFields;

  if (not assigned(indexDefs)) then begin
    exit;
  end;

  fQuery.setIndexFieldsNames('');
  fQuery.setIndexFieldName('');
  indexDefs.clear;

  for i:= 0 to getFields.count - 1 do begin
    curField:= getFields.items[i];

    if (curField = aField) then begin
      if (curField.sortDirection = sdNone) then begin
        exit;
      end;

      continue;
    end;

    curField.sortDirection:= sdNone;
  end;

  indexDefs.beginUpdate;
  try

    if (aField.sortDirection = sdDesc) then begin
      indexName:= format(INDEX_DESC_FORMAT, [aField.name]);
    end else begin
      indexName:= format(INDEX_ASC_FORMAT, [aField.name]);
    end;

    indexOptions:= [ixCaseInsensitive];
    if (aField.sortDirection = sdDesc) then begin
      include(indexOptions, ixDescending);
    end;

    fQuery.addIndex(indexName, aField.name, indexOptions, aField.name);
    indexDefs.update;

    fQuery.setIndexFieldName(indexName);
    If (aField.sortDirection <> sdDesc) then begin
      fQuery.setIndexFieldsNames(aField.name);
    end;

  finally
    indexDefs.endUpDate;
  end;

end;

function cMemoryTableModel.rawFetch(const aCommand: string): integer;
begin
  result:= 0;
  if (tmsConditionSetting in getStates) then exit;

  setFetchCommand(aCommand);

  beginDataChanging;
  try

    beginDataFetching;
    try
      //auto fiilter by command
      fQuery.setSQL(aCommand);
      fQuery.open;
    finally
      endDataFetching;
    end;

    resort;


    if (fQuery.fields.count <> getFields.count) then begin
      raise eMemoryTableModel.createFmt(FIELD_CACHE_COUNT_ERROR, [getFields.count, fQuery.fields.count]);
    end;

    if not assigned(nativeIteratorRow) then begin
      raise eMemoryTableModel.create(cAbstractTableModel.ITERATOR_ROW_NOT_ASSIGNED);
    end;

    updateRowCount;

    result:= getRowCount;

  finally
    endDataFetching;
    endDataChanging(ctTableFetch);
  end;
end;

function cMemoryTableModel.fetch(const aCondition: string; aLimit: integer; aOffset: integer): integer;
begin
  result:= inherited fetch(aCondition, aLimit, aOffset);

  result:= rawFetch(aCondition);
end;

function cMemoryTableModel.getFieldData(aCol, aRow: integer; aGetDataRole: tTableModelDataRole): variant;
var
  fieldValue: variant;
begin
  fieldValue:= null;
  try
    if (getRowCount = 0) then begin
      exit;
    end;

    fieldValue:= fQuery.getField(aCol, aRow).asVariant;
  finally
    fieldDataGetting(aCol, aRow, fieldValue);
    result:= fieldValue;
  end;
end;

function cMemoryTableModel.getFieldData(aName: string; aRow: integer; aGetDataRole: tTableModelDataRole): variant;
var
  fieldValue: variant;
begin
  if (getRowCount = 0) then begin
    result:= null;
    exit;
  end;

  fieldValue:= fQuery.getField(aName, aRow).asVariant;

  fieldDataGetting(getFields.indexOfName(aName), aRow, fieldValue);

  result:= fieldValue;
end;

function cMemoryTableModel.getFieldType(aCol: integer): tDataType;
begin
  result:= cDBTypeConversion.fieldTypeToDataType(fQuery.getFieldType(aCol));
end;

function cMemoryTableModel.getFullRowCountWithoutLimits: integer;
begin
  result:= fQuery.getRowCount;
end;

function cMemoryTableModel.getAggregateCommand(aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes; aUserCondition: string): string;
begin
  result:= '';
  raise eMemoryTableModel.create(METHOD_NOT_IMPLEMENTED);
end;

function cMemoryTableModel.getAutoIncFields: cTableFields;
begin
  result:= fAutoIncFields;
end;

function cMemoryTableModel.getQuery: cAbstractSQLQuery;
begin
  result:= fQuery;
end;

procedure cMemoryTableModel.createDependsObjects;
begin
  destroyDependsObjects;

  fQuery:= cSQLQueryFactory.createNew(drvMemory);
end;

procedure cMemoryTableModel.destroyDependsObjects;
begin
  if assigned(fQuery) then begin
    freeAndNil(fQuery);
  end;
end;

function cMemoryTableModel.insert(aRow: cAbstractTableRow; aId: int64): int64;
var
  idEditable: boolean;
  oldIdEditable: boolean;
begin
  beginDataChanging;
  try

    oldIdEditable:= isIdEditable;

    idEditable:= false;
    if (aId <> NEW_KEY_ID) then begin
      idEditable:= true;
    end;

    setIdEditable(idEditable);
    try

      if (aId <> NEW_KEY_ID) then begin
        result:= aId;
        fQuery.setFieldData(getFields.getKeyFieldIndex, fQuery.appendRow, result);
      end else begin
        result:= fQuery.getField(getFields.getKeyFieldIndex, fQuery.appendRow).asLargeInt;
      end;

    finally
      setIdEditable(oldIdEditable);
    end;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cMemoryTableModel.update(aRow: cAbstractTableRow; aId: int64; aUpdatingFieldNames: string): integer;
var
  updatingId: int64;

  oldIdEditable: boolean;

  i: integer;

  fieldsCount: integer;
  curField: cTableField;
begin
  result:= 0;
  beginDataChanging;
  try
    oldIdEditable:= isIdEditable;

    if (aId = USE_RECORD_ID) then begin
      updatingId:= aRow.id
    end else begin
      updatingId:= aId;
      setIdEditable(true);
    end;

    try
      if (fQuery.locate(getFields.getKeyField.name, aId)) then begin

        fieldsCount:= getFields.count;
        for i := 0 to  fieldsCount - 1 do begin
          curField:= getFields.items[i];

          fQuery.fields[i].asVariant:= aRow.getFieldData(curField.name);
        end;

        result:= 1;
      end;

    finally
      setIdEditable(oldIdEditable);
    end;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cMemoryTableModel.delete(aRow: cAbstractTableRow): integer;
begin
  result:= 0;
  beginDataChanging;
  try
    if (fQuery.locate(getFields.getKeyField.name, aRow.id)) then begin
      fQuery.deleteCurrentRow;
      result:= 1;
    end;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

procedure cMemoryTableModel.deleteRow(aRow: integer);
var
  deletingKey: int64;
  activeRecord: cAbstractTableRow;
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

procedure cMemoryTableModel.deleteRowFromCache(aRow: integer);
begin
  beginDataChanging;
  try
    rowDeleting(aRow);

    fQuery.deleteRow(aRow);
    inherited deleteRowFromCache(aRow);
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cMemoryTableModel.loadFromStream(aStream: cAbstractIOObject): boolean;
var
  dataStream: cMemory;
  dataResult: boolean;
  autoIncStream: cMemory;
  autoIncResult: boolean;
begin
  result:= false;

  if (aStream.size <= 0) then begin
    exit;
  end;

  beginDataFetching;
  try

    dataStream:= cMemory.create;
    try
      aStream.readStream(dataStream);

      dataResult:= fQuery.loadFromStream(dataStream);

      autoIncStream:= cMemory.create;
      try
        aStream.readStream(autoIncStream);
        autoIncResult:= fAutoIncGenerators.loadFromStream(autoIncStream);

        result:= dataResult and autoIncResult;
      finally
        freeAndNil(autoIncStream);
      end;


    finally
      freeAndNil(dataStream);
    end;

    setRowsSelected(false);
    updateRowCount;
  finally
    endDataFetching
  end;
end;

function cMemoryTableModel.loadRowData(aRowIndex: integer; aRow: cAbstractTableRow): boolean;
var
  i: integer;
begin
  result:= false;

  moveToRow(aRowIndex);
  for i:= 0 to getFields.count - 1 do begin
    aRow.setPropertyData(getFields.items[i].name, fQuery.fields[i].asVariant);
  end;

  result:= true;
end;

procedure cMemoryTableModel.moveToRow(aRow: integer);
begin
  fQuery.moveTo(aRow);
end;

function cMemoryTableModel.reload(aRow: integer): integer;
begin
  result:= 1;
  inherited reload(aRow);
end;

procedure cMemoryTableModel.resort;
var
  i: integer;
  curField: cTableField;
begin
  for i:= 0 to getFields.count - 1 do begin
    curField:= getFields.items[i];

    if (curField.sortDirection <> sdNone) then begin
      createIndexes(curField);
      exit;
    end;
  end;
end;

procedure cMemoryTableModel.restoreState(const aState: tBytesArray);
var
  memStream: cMemory;
begin
  memStream:= cMemory.create;
  try
    memStream.fromBytes(aState);

    loadFromStream(memStream);
  finally
    freeAndNil(memStream);
  end;
end;

procedure cMemoryTableModel.setFieldData(aCol, aRow: integer; const aValue: variant);
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
      raise eMemoryTableModel.create(CANNOT_MODIFY_KEY_COL);
    end;}

    updatingField:= getFields.items[aCol];

    if (not updatingField.readOnly) then begin
      setCacheFieldData(aCol, aRow, fieldValue);
    end;

    if (updatingField.isSelector) or (updatingField.readOnly) then begin
      exit;
    end;

  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cMemoryTableModel.saveState: tBytesArray;
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

function cMemoryTableModel.saveToStream(aStream: cAbstractIOObject): boolean;
var
  dataStream: cMemory;
  dataResult: boolean;
  autoIncStream: cMemory;
  autoIncResult: boolean;
begin
  result:= false;

  dataStream:= cMemory.create;
  try

    dataResult:= fQuery.saveToStream(dataStream);

    autoIncStream:= cMemory.create;
    try
       autoIncResult:= fAutoIncGenerators.saveToStream(autoIncStream);

       aStream.writeStream(dataStream);
       aStream.writeStream(autoIncStream);

       result:= dataResult and autoIncResult;
    finally
      freeAndNil(autoIncStream);
    end;

  finally
    freeAndNil(dataStream);
  end;
end;

procedure cMemoryTableModel.setCacheFieldData(aCol, aRow: integer; const aValue: variant);
begin
  beginDataChanging;
  try
    inherited setCacheFieldData(aCol, aRow, aValue);

    fQuery.setFieldData(aCol, aRow, aValue);
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cMemoryTableModel.addField(aName, aTitle: string; aType: tDataType; aSize: integer; aAutoInc, aReadOnly: boolean; aSortDirection: tTableFieldSortDirection): cTableField;
begin
  result:= inherited addField(aName, aTitle, aReadOnly, aSortDirection);
  fQuery.addField(aName, aTitle, aType, aSize);

  if (aAutoInc) then begin
    fAutoIncFields.add(result);

    fAutoIncGenerators.add(cMemoryTableModelAutoIncGenerator.create(0, result));
  end;
end;

function cMemoryTableModel.appendRow(aId: int64): integer;
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

    //solve sorting issue
    result:= fQuery.getCurrentRow;

    appendedKey:= getRowKey(result);

    addAppendedKey(appendedKey);

    insertDynamicData(appendedKey);

  finally
    endDataChanging(ctTableCRUID);
  end;
end;

//SLOTS
procedure cMemoryTableModel.fieldSortDirectionChanged(aSender: cTableFields; aField: cTableField; aOldDirection: tTableFieldSortDirection);
begin
  if (aField.sortDirection = aOldDirection) then exit;

  createIndexes(aField);
end;

procedure cMemoryTableModel.rowAppended(aSender: cAbstractSQLQuery; aRow: integer);
var
  i: integer;
  fieldIndex: integer;
begin
  for i := 0 to getAutoIncFields.count - 1 do begin
    fieldIndex:= getFields.indexOf(getAutoIncFields.items[i]);

    if (fieldIndex <> -1) then begin
      setFieldData(fieldIndex, aRow, fAutoIncGenerators.items[getAutoIncFields.items[i]].getNextValue);
    end;
  end;
end;

{ cAutoIncGenerator }

constructor cMemoryTableModelAutoIncGenerator.create(aStartValue: int64; aField: cTableField);
begin
  inherited create(aStartValue);

  setCurrentValue(aStartValue);
  setField(aField);
end;

function cMemoryTableModelAutoIncGenerator.getField: cTableField;
begin
  result:= fField;
end;

procedure cMemoryTableModelAutoIncGenerator.setField(aField: cTableField);
begin
  fField:= aField;
end;


{ cAutoIncGenerators }

procedure cMemoryTableModelAutoIncGenerators.add(aGenerator: cMemoryTableModelAutoIncGenerator);
begin
  fList.add(aGenerator);
end;

constructor cMemoryTableModelAutoIncGenerators.create;
begin
  inherited create;
  fList:= cList.create;
end;

destructor cMemoryTableModelAutoIncGenerators.destroy;
begin
  if assigned(fList) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

function cMemoryTableModelAutoIncGenerators.getCount: integer;
begin
  result:= fList.count;
end;

function cMemoryTableModelAutoIncGenerators.getItemByField(aField: cTableField): cMemoryTableModelAutoIncGenerator;
var
  foundIndex: integer;
begin
  result:= nil;
  foundIndex:= indexOfField(aField);

  if (foundIndex = -1) then begin
    exit;
  end;

  result:= items[foundIndex];
end;

function cMemoryTableModelAutoIncGenerators.getItemByIndex(aIndex: integer): cMemoryTableModelAutoIncGenerator;
begin
  result:= fList.items[aIndex];
end;

function cMemoryTableModelAutoIncGenerators.indexOfField(aField: cTableField): integer;
var
  i: integer;
begin
  result:= -1;
  for i := 0 to count - 1 do begin
    if (items[i].getField = aField) then begin
      result:= i;
      exit;
    end;
  end;
end;

function cMemoryTableModelAutoIncGenerators.loadFromStream(aStream: cAbstractIOObject): boolean;
var
  i: integer;
  curItem: cMemoryTableModelAutoIncGenerator;
  startValue: int64;
begin
  result:= false;

  try
    aStream.seek(0, soBeginning);

    for i:= 0 to count - 1 do begin
      curItem:= items[i];

      aStream.readInteger(startValue);
      curItem.setCurrentValue(startValue);
    end;
    result:= true;
  except
    result:= false;
  end;
end;

function cMemoryTableModelAutoIncGenerators.saveToStream(aStream: cAbstractIOObject): boolean;
var
  i: integer;
  curItem: cMemoryTableModelAutoIncGenerator;
begin
  result:= false;

  try
    aStream.seek(0, soBeginning);

    for i:= 0 to count - 1 do begin
      curItem:= items[i];

      aStream.writeInteger(curItem.getCurrentValue);
    end;

    result:= true;
  except
    result:= false;
  end;

end;

end.

