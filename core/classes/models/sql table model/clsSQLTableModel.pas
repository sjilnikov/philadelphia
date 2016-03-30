unit clsSQLTableModel;

interface
uses
  db,
  classes,
  variants,
  typInfo,
  sysUtils,
  zConnection,
  zAbstractRODataset,
  zAbstractDataset,
  zDataset,
  generics.collections,

  uModels,
  uSQLDrivers,

  clsException,
  clsClassKit,


  clsDBTypeConversion,
  clsDynamicalObject,
  clsLists,
  clsStringUtils,
  clsAbstractTableModel,
  clsAbstractSQLConnection,
  clsAbstractSQLCommand,
  clsAbstractSQLQuery,
  clsAbstractSQLCommandsBuilder,
  clsAbstractSQLDataBuilder,
  clsVariantConversion;

type
  eSQLTableModel = class(cException);
  eSQLTableRow = class(cException);

  cSQLTableRow = class(cAbstractTableRow)
  private
    const
    OWNER_NOT_ASSIGNED      = 'type: activeRecord, cannot set connection, owner not assigned';
  public
    procedure   setConnection(aConnection: cAbstractSQLConnection);
  end;

  cSQLStdTableRow = class(cSQLTableRow)
  public
    procedure   afterConstruction; override;
    procedure   setPropertyData(aName: string; const aValue: variant); override;
  end;

  cSQLTableModel = class;

  tRowActionProc = function(aFieldName: string; aValue: variant; aType: tDataType): string of object;

  cSQLRelations = class;

  cSQLRelation = class(cRelation)
  private
    fTableModel         : cSQLTableModel;

    fOwner              : cSQLRelations;

    fTableName          : string;
    fSchema             : string;
    fKeyColumnName      : string;
    fDisplayColumnName  : string;
    fSortDirection      : tTableFieldSortDirection;

    fDisplayValuesDict  : tDictionary<int64, variant>;

    procedure   createModel;
    procedure   removeModel;
    procedure   setupModel;

    procedure   setOwner(aOwner: cSQLRelations);

    procedure   loadData;
  public
    procedure   update; override;

    function    getDisplayValueFieldIndex: integer; override;
    function    getDisplayValueByKey(aKey: int64): variant; override;
    function    getTableModel: cAbstractTableModel; override;

    function    getTableName: string;
    function    getSchema: string;
    function    getKeyColumnName: string;
    function    getDisplayColumnName: string;

    constructor create(aTableName: string; aSchema: string; aKeyColumnName: string; aDisplayColumnName: string; aSortDirection: tTableFieldSortDirection = sdAsc);
    destructor  destroy; override;
  end;

  cSQLRelations = class
  private
    fList       : tDictionary<cTableField, cSQLRelation>;
    fOwner      : cSQLTableModel;

    function    getOwner: cSQLTableModel;

    procedure   setupFieldsEvents;
    procedure   disconnectFieldEvents;
  public
    procedure   add(aTableField: cTableField; aSQLRelation: cSQLRelation);
    function    getRelation(aTableField: cTableField): cSQLRelation;

    constructor create(aOwner: cSQLTableModel);
    destructor  destroy; override;

  published
    //SLOTS
    procedure   fieldRemoving(aSender: cTableFields; aField: cTableField);
  end;

  cSQLTableModel = class(cAbstractTableModel)
  private
    const

    ROW_ACTIONPROC_NOT_ASSIGNED  = 'row actionProc not assigned';
    FIELD_CACHE_COUNT_ERROR      = 'field count: %d not equal field count: %d';
    FETCH_ROW_ERROR              = 'fetch rows error, fetched: %d';
    CANNOT_MODIFY_KEY_COL        = 'cannot modify key col';
    CANNOT_COPY_FROM_OTHER_CLASS = 'cannot copy from other class';
    CONNECTION_NOT_ASSIGNED      = 'connection not assigned';
    TABLE_MODEL_NOT_ASSIGNED     = 'table model not assigned';
  private
    fSQLRelations   : cSQLRelations;

    fQuery          : cAbstractSQLQuery;
    fCommand        : cAbstractSQLCommand;
    fCommandBuilder : cAbstractSQLCommandsBuilder;
    fDataBuilder    : cAbstractSQLDataBuilder;
    fConnection     : cAbstractSQLConnection;

    fKeyField       : string;
    fSchema         : string;
    fSelectCommand  : string;

    procedure   setupEvents;
    procedure   disconnectEvents;
    procedure   createRelations;
    procedure   removeRelations;

    function    getCommandWithSelectorField(aCommand: string): string;

    function    canContinueFetch: boolean;
    procedure   checkConnection;

  protected
    function    collectRowData(aRowActionProc: tRowActionProc; aRow: cAbstractTableRow; aFieldNames: string; aConcatString: string = cTableFields.DEFAULT_FIELDS_DELIMITER): string;

    function    insertRowProc(aFieldName: string; aValue: variant; aType: tDataType): string;
    function    updateRowProc(aFieldName: string; aValue: variant; aType: tDataType): string;
    function    getFieldsOrderByProc(aSender: cTableFields; aField: cTableField): string;

    function    copyDataFromTable(aSourceTable: cAbstractTableModel; aSourceRow: integer; aDestTable: cAbstractTableModel; aDestRow: integer): boolean; override;

    function    insert(aRow: cAbstractTableRow; aId: int64 = NEW_KEY_ID): int64; override;
    function    update(aRow: cAbstractTableRow; aId: int64 = USE_RECORD_ID; aUpdatingFieldNames: string = ''): integer; override;
    function    delete(aRow: cAbstractTableRow): integer; override;

    procedure   createDependsObjects;
    procedure   destroyDependsObjects;

    procedure   updateRowCount; override;
  public
    procedure   addRelation(aFieldIndex: integer; aTableName: string; aSchema: string; aKeyColumnName: string; aDisplayColumnName: string; aSortDirection: tTableFieldSortDirection = sdAsc); overload;
    procedure   addRelation(aFieldName: string; aTableName: string; aSchema: string; aKeyColumnName: string; aDisplayColumnName: string; aSortDirection: tTableFieldSortDirection = sdAsc); overload;

    function    getRelation(aFieldIndex: integer): cRelation; override;

    procedure   prepare;
    function    getCommand: cAbstractSQLCommand;
    function    getCommandBuilder: cAbstractSQLCommandsBuilder;
    function    getDataBuilder: cAbstractSQLDataBuilder;
    function    getQuery: cAbstractSQLQuery;

    function    getAggregateCommand(aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes; aUserCondition: string = ''): string; override;


    function    getFullRowCountWithoutLimits: integer; override;

    function    getInsertCommand(aFieldNames: string; aValues: string; aReturningFields: string): string;
    function    getUpdateCommand(aFieldValues: string; const aCondition: string): string;
    function    getDeleteCommand(const aCondition: string): string;

    //defined by user

    function    getSchema: string;
    procedure   setSchema(aSchema: string);

    function    getSelectCommand: string;
    procedure   setSelectCommand(aSelectCommand: string);

    function    loadRowData(aRowIndex: integer; aRow: cAbstractTableRow): boolean; overload; override;

    function    createActiveRecord: cAbstractTableRow; override;
    function    createIteratorRow: cAbstractTableRow; override;

    procedure   moveToRow(aRow: integer); override;

    function    getFieldType(aCol: integer): tDataType; override;

    function    getFieldData(aCol: integer; aRow: integer; aGetDataRole: tTableModelDataRole = drUseRelation): variant; overload; override;
    function    getFieldData(aName: string; aRow: integer; aGetDataRole: tTableModelDataRole = drUseRelation): variant; overload; override;


    procedure   setCacheFieldData(aCol: integer; aRow: integer; const aValue: variant); override;

    //synchronized with db
    //todo: make cSQLStdRow editable!!!
    procedure   setFieldData(aCol: integer; aRow: integer; const aValue: variant); override;

    function    appendRow(aId: int64 = NEW_KEY_ID): integer; override;
    function    appendRowToCache: integer; override;

    procedure   deleteRow(aRow: integer); override;
    procedure   deleteRowFromCache(aRow: integer); override;
    //

    function    getRowKey(aRow: integer): int64; override;


    function    getTableNameWithSchema: string;

    function    getOrderByFields: string;

    function    getConnection: cAbstractSQLConnection;
    procedure   setConnection(aSQLConnection: cAbstractSQLConnection); virtual;

    function    rawFetch(const aCommand: string): integer; override;

    function    fetch(const aCondition: string = '1=1'; aLimit: integer = NO_CONSIDER_LIMIT; aOffset: integer = NO_CONSIDER_OFFSET): integer; overload; override;
    function    fetch(aId: int64): integer; overload; override;

    function    reload(aRow: integer): integer; overload; override;

    procedure   copyFrom(aTableModel: cAbstractTableModel); override;

    constructor create; override;
    destructor  destroy; override;

  published
    property    command: cAbstractSQLCommand read getCommand;
    property    commandBuilder: cAbstractSQLCommandsBuilder read getCommandBuilder;
    property    dataBuilder: cAbstractSQLDataBuilder read getDataBuilder;

  published
    //SLOTS
    procedure   fieldSortDirectionChanged(aSender: cTableFields; aField: cTableField; aOldDirection: tTableFieldSortDirection);
  end;

const
  SQL_TABLE_FIELD_SORT_DIRECTION : array[low(tTableFieldSortDirection)..high(tTableFieldSortDirection)] of string = ('', 'ASC', 'DESC');


implementation
uses
  clsMulticastEvents,
  clsSQLCommandsFactory,
  clsSQLQueryFactory,
  clsSQLCommandsBuildersFactory,
  clsSQLDataBuildersFactory;

{ cSQLTableRow }

procedure cSQLTableRow.setConnection(aConnection: cAbstractSQLConnection);
begin
  if (rowType = rtActiveRecord) then begin

    if (assigned(owner)) then begin
      (owner as cSQLTableModel).setConnection(aConnection);
    end else begin
      raise eSQLTableRow.create(OWNER_NOT_ASSIGNED);
    end;

  end else begin
    raise eSQLTableRow.create(OPERATION_NOT_PERMITED);
  end;
end;

{ cSQLTableModel }

constructor cSQLTableModel.create;
begin
  inherited create;

  createRelations;

  fQuery          := nil;
  fCommand        := nil;
  fCommandBuilder := nil;
  fDataBuilder    := nil;

  setupEvents;
end;

function cSQLTableModel.createActiveRecord: cAbstractTableRow;
begin
  result:= getRowClass.createActiveRecord(self, cSQLTableModel);
end;

destructor cSQLTableModel.destroy;
begin
  removeRelations;

  disconnectEvents;

  destroyDependsObjects;

  inherited;
end;

function cSQLTableModel.getRelation(aFieldIndex: integer): cRelation;
begin
  inherited getRelation(aFieldIndex);
  result:= fSQLRelations.getRelation(getFields.items[aFieldIndex]);
end;

function cSQLTableModel.getRowKey(aRow: integer): int64;
var
  field: tField;
begin
  result:= inherited getRowKey(aRow);

  field:= fQuery.getField(getFields.getKeyFieldIndex, aRow);

  if not assigned(field) then begin
    result:= NOT_VALID_KEY_ID;
  end else begin
    result:= field.asInteger;
  end;

end;

function cSQLTableModel.getTableNameWithSchema: string;
begin
  if (getSchema = '') then begin
    result:= getTableName;
    exit;
  end;

  result:= format('%s.%s', [getSchema, getTableName]);
end;

function cSQLTableModel.appendRowToCache: integer;
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

function cSQLTableModel.canContinueFetch: boolean;
var
  cacheFldList: tStringList;
  fldList: tStringList;

  i: integer;
begin
  result:= true;

  if (fQuery.fields.count = getFields.count) then begin
    exit;
  end;

  fldList:= tStringList.create;
  try
  cacheFldList:= tStringList.create;
  try

    for i := 0 to getFields.count - 1 do begin
      fldList.add(getFields.items[i].name);
    end;

    for i := 0 to fQuery.fields.count - 1 do begin
      cacheFldList.add(fQuery.fields[i].displayName);
    end;

    for i := 0 to cacheFldList.count - 1 do begin
      if (fldList.indexOf(cacheFldList.strings[i]) = -1) then begin
        result:= false;
        exit;
      end;
    end;


  finally
    freeAndNil(cacheFldList);
  end;
  finally
    freeAndNil(fldList);
  end;
end;

function cSQLTableModel.collectRowData(aRowActionProc: tRowActionProc; aRow: cAbstractTableRow; aFieldNames: string; aConcatString: string): string;
var
  fieldsArr: tArguments;
  curField: string;

  processedResult: string;

  rowData: sPropertyData;
begin
  result:= '';

  if (not(assigned(aRowActionProc))) then begin
    raise eSQLTableModel.create(ROW_ACTIONPROC_NOT_ASSIGNED);
  end;

  fieldsArr:= cStringUtils.explode(aFieldNames, cTableFields.DEFAULT_FIELDS_DELIMITER);
  for curField in fieldsArr do begin

    if (aRow is cSQLStdTableRow) then begin
      if aRow.propertyExists(curField) then begin
        rowData:= aRow.getPropertyData(curField);
      end;
    end else begin
      rowData:= aRow.getPropertyData(curField);
    end;

    processedResult:= aRowActionProc(curField, rowData.value, rowData.dataType);
    if (processedResult = '') then begin
      continue;
    end;

    result:= result + aConcatString + processedResult;
  end;

  system.delete(result, 1, length(aConcatString));
end;

function cSQLTableModel.copyDataFromTable(aSourceTable: cAbstractTableModel; aSourceRow: integer; aDestTable: cAbstractTableModel; aDestRow: integer): boolean;
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
      raise eSQLTableModel.createFmt(FIELD_CACHE_COUNT_ERROR, [sourceFieldCount, destFieldCount]);
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

procedure cSQLTableModel.copyFrom(aTableModel: cAbstractTableModel);
var
  i: integer;
  curField: cTableField;

  sqlTableModel: cSQLTableModel;
  findedField: cTableField;
  findedFieldIndex: integer;
begin
  if not (aTableModel is cSQLTableModel) then begin
    raise eSQLTableModel.create(CANNOT_COPY_FROM_OTHER_CLASS);
  end;

  sqlTableModel:= cSQLTableModel(aTableModel);

  setRowClass(sqlTableModel.getRowClass);

  setSchema(sqlTableModel.getSchema);
  setTableName(sqlTableModel.getTableName);
  setSelectCommand(sqlTableModel.getSelectCommand);

  if (sqlTableModel.getFields.getSelectorFieldIndex <> -1) then begin
    enableSelector(true);
  end;

  for i := 0 to sqlTableModel.getFields.count - 1 do begin
    curField:= sqlTableModel.getFields.items[i];

    if curField.isSelector then continue;

    findedFieldIndex:= getFields.indexOfName(curField.name);
    if (findedFieldIndex <> -1) then begin
      findedField:= getFields.items[findedFieldIndex];

      findedField.readOnly:= curField.readOnly;
      findedField.sortDirection:= curField.sortDirection;

      continue;
    end;

    addField(curField.name, curField.title, curField.readOnly, curField.sortDirection);
  end;

  setKeyField(sqlTableModel.getFields.getKeyField.name);

  setConnection(sqlTableModel.getConnection);
end;

function cSQLTableModel.insertRowProc(aFieldName: string; aValue: variant; aType: tDataType): string;
begin
  result:= getDataBuilder.variantToFieldValue(aValue, aType);
end;

procedure cSQLTableModel.updateRowCount;
begin
  setRowCount(fQuery.getRowCount);

  inherited updateRowCount;
end;

function cSQLTableModel.updateRowProc(aFieldName: string; aValue: variant; aType: tDataType): string;
begin
  if getFields.isFieldNameSelector(aFieldName) then begin
    result:= '';
    exit;
  end;


  if (not isIdEditable) and (aFieldName = DEFAULT_KEY_FIELD_NAME) then begin
    result:= '';
    exit;
  end;

  result:= format('%s=%s',
    [
      aFieldName,
      getDataBuilder.variantToFieldValue(aValue, aType)
    ]
  );
end;

procedure cSQLTableModel.setupEvents;
begin
  connect(getFields, 'onSortDirectionChanged', self, 'fieldSortDirectionChanged');
end;

procedure cSQLTableModel.disconnectEvents;
begin
  disconnect(getFields, 'onSortDirectionChanged', self, 'fieldSortDirectionChanged');
end;

function cSQLTableModel.fetch(aId: int64): integer;
begin
  result:= fetch(getKeyCondition(aId), NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);
end;

procedure cSQLTableModel.fieldSortDirectionChanged(aSender: cTableFields; aField: cTableField; aOldDirection: tTableFieldSortDirection);
begin
  if (aField.sortDirection = aOldDirection) then exit;

  reload;
end;

function cSQLTableModel.rawFetch(const aCommand: string): integer;
begin
  result:= 0;

  inherited rawFetch(aCommand);

  if (tmsConditionSetting in getStates) then exit;

  setFetchCommand(aCommand);

  beginDataChanging;
  try
    beginDataFetching;
    try

      setFetchCommand(
        fCommandBuilder.getSelectCommandLimited(
          getCommandWithSelectorField(aCommand),
          getLimit,
          getOffset
        )
      );

      fQuery.setSQL(getFetchCommand);
      fQuery.open;

      if (not canContinueFetch) then begin
        raise eSQLTableModel.createFmt(FIELD_CACHE_COUNT_ERROR, [getFields.count, fQuery.fields.count]);
      end;

      if not assigned(nativeIteratorRow) then begin
        raise eSQLTableModel.create(cAbstractTableModel.ITERATOR_ROW_NOT_ASSIGNED);
      end;

      updateRowCount;

      result:= getRowCount;
    finally
      endDataFetching;
    end;

  finally
    endDataChanging(ctTableFetch);
  end;
end;

function cSQLTableModel.fetch(const aCondition: string; aLimit: integer; aOffset: integer): integer;
begin
  result:= inherited fetch(aCondition, aLimit, aOffset);

  checkConnection;

  result:= rawFetch(
    commandBuilder.getSelectCommand(
      getSelectCommand,
      getCondition,
      getOrderByFields
    )
  );
end;

procedure cSQLTableModel.checkConnection;
begin
  if not assigned(fConnection) then begin
    raise eSQLTableModel.create(CONNECTION_NOT_ASSIGNED);
  end;
end;

function cSQLTableModel.getFieldData(aCol, aRow: integer; aGetDataRole: tTableModelDataRole): variant;
var
  field: tField;
  SQLRelation: cSQLRelation;

  fieldValue: variant;
begin
  fieldValue:= NULL;

  try
    field:= fQuery.getField(aCol, aRow);
    if assigned(field) then begin
      fieldValue:= field.asVariant;

      if (getFields.getSelectorFieldIndex = aCol) then begin
        fieldValue:= cVariantConversion.varToBool(fieldValue);
      end;

      if (fieldValue = NULL) then begin
        fieldValue:= cVariantConversion.getDefaultVarValueForDataType(getFieldType(aCol));
      end;

    end;

    if aGetDataRole = drRawData then begin
      exit;
    end;

    SQLRelation:= fSQLRelations.getRelation(getFields.items[aCol]);
    if (assigned(SQLRelation)) and (fieldValue <> NULL) then begin
      fieldValue:= SQLRelation.getDisplayValueByKey(fieldValue);
    end;

  finally
    fieldDataGetting(aCol, aRow, fieldValue);
    result:= fieldValue;
  end;
end;


function cSQLTableModel.getFieldData(aName: string; aRow: integer; aGetDataRole: tTableModelDataRole): variant;
begin
  result:= getFieldData(getFields.indexOfName(aName), aRow, aGetDataRole);
end;

function cSQLTableModel.getFieldsOrderByProc(aSender: cTableFields; aField: cTableField): string;
begin
  result:= '';

  if (aField.isSelector) then begin
    exit;
  end;

  if (aField.containsStates([fsSortable])) then begin
    result:= format('%s %s', [aField.name, SQL_TABLE_FIELD_SORT_DIRECTION[aField.sortDirection]]);
  end;
end;

function cSQLTableModel.getFieldType(aCol: integer): tDataType;
begin
  if getFields.items[aCol].isSelector then begin
    result:= dtBoolean;
  end else begin
    result:= cDBTypeConversion.fieldTypeToDataType(fQuery.getFieldType(aCol));
  end;
end;

function cSQLTableModel.getFullRowCountWithoutLimits: integer;
var
  countCommand: string;
begin
  countCommand:= fCommandBuilder.getCountCommand(

    commandBuilder.getSelectCommand(
      getSelectCommand,
      getCondition,
      ''
    )

  );

  result:= fCommand.execute(countCommand, true).returning;
end;

function cSQLTableModel.getOrderByFields: string;
begin
  result:= getFields.collectFieldInfo(getFieldsOrderByProc);
end;

function cSQLTableModel.getSchema: string;
begin
  result:= fSchema;
end;

function cSQLTableModel.getSelectCommand: string;
begin
  result:= fSelectCommand;
end;

function cSQLTableModel.getAggregateCommand(aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes; aUserCondition: string): string;
begin
  if (aUserCondition <> '') then begin
    result:= fCommandBuilder.getAggregateCommand(
      commandBuilder.getSelectCommand(
        getSelectCommand,
        aUserCondition,
        ''
      )
      ,
      aFieldNames,
      aAggregateFieldsType
    );
  end else begin
    result:= fCommandBuilder.getAggregateCommand(getFetchCommand, aFieldNames, aAggregateFieldsType);
  end;
end;

function cSQLTableModel.getCommand: cAbstractSQLCommand;
begin
  result:= fCommand;
end;

function cSQLTableModel.getCommandBuilder: cAbstractSQLCommandsBuilder;
begin
  result:= fCommandBuilder;
end;

function cSQLTableModel.getCommandWithSelectorField(aCommand: string): string;
var
  selectorField: cTableField;
begin
  result:= aCommand;
  selectorField:= getFields.getSelectorField;
  if assigned(selectorField) then begin
    result:=
      fCommandBuilder.addFieldToSelectBefore(
        result,
        fDataBuilder.getNamedFieldValue(fDataBuilder.castValue(false, dtBoolean), selectorField.name)
      );
  end;
end;

function cSQLTableModel.getDataBuilder: cAbstractSQLDataBuilder;
begin
  result:= fDataBuilder;
end;

function cSQLTableModel.getConnection: cAbstractSQLConnection;
begin
  result:= fConnection;
end;

function cSQLTableModel.getQuery: cAbstractSQLQuery;
begin
  result:= fQuery;
end;

procedure cSQLTableModel.createDependsObjects;
var
  SQLDriver: tSQLDriver;
begin
  SQLDriver:= fConnection.connectionInfo.driver;

  destroyDependsObjects;

  fQuery          := cSQLQueryFactory.createNew(SQLDriver);
  fCommand        := cSQLCommandsFactory.createNew(SQLDriver);
  fCommandBuilder := cSQLCommandsBuilderFactory.createNew(SQLDriver);
  fDataBuilder    := cSQLDataBuildersFactory.createNew(SQLDriver);

  fQuery.setConnection(fConnection);
  fCommand.setConnection(fConnection);
end;

function cSQLTableModel.createIteratorRow: cAbstractTableRow;
begin
  result:= getRowClass.create(self);
end;

procedure cSQLTableModel.createRelations;
begin
  fSQLRelations   := cSQLRelations.create(self);
end;

procedure cSQLTableModel.destroyDependsObjects;
begin
  if assigned(fQuery) then begin
    freeAndNil(fQuery);
  end;

  if assigned(fCommand) then begin
    freeAndNil(fCommand);
  end;

  if assigned(fCommandBuilder) then begin
    freeAndNil(fCommandBuilder);
  end;

  if assigned(fDataBuilder) then begin
    freeAndNil(fDataBuilder);
  end;
end;

function cSQLTableModel.getInsertCommand(aFieldNames: string; aValues: string; aReturningFields: string): string;
begin
  result:= fCommandBuilder.getInsertCommand(getTableName, aFieldNames, aValues, aReturningFields);
end;

function cSQLTableModel.getUpdateCommand(aFieldValues: string; const aCondition: string): string;
begin
  result:= fCommandBuilder.getUpdateCommand(getTableName, aFieldValues, aCondition);
end;

function cSQLTableModel.getDeleteCommand(const aCondition: string): string;
begin
  result:= fCommandBuilder.getDeleteCommand(getTableName, aCondition);
end;

function cSQLTableModel.insert(aRow: cAbstractTableRow; aId: int64): int64;
var
  idEditable: boolean;
  oldIdEditable: boolean;
begin
  beginDataChanging;
  try

    oldIdEditable:= isIdEditable;

    idEditable:= false;
    if (aId <> NEW_KEY_ID) then begin
      aRow.id:= aId;
      idEditable:= true;
    end;

    setIdEditable(idEditable);
    try

      if (getRowClass = cSQLStdTableRow) then begin
        result:= fCommand.execute(
          fCommandBuilder.getDefaultInsertCommand(
            getTableNameWithSchema,
            DEFAULT_KEY_FIELD_NAME
          ),
          true
        ).returning;
      end else begin
        result:= fCommand.execute(
          fCommandBuilder.getInsertCommand(
            getTableNameWithSchema,
            getFieldNames,     //<- only editable, not selector
            collectRowData(insertRowProc, aRow, getFieldNames),
            DEFAULT_KEY_FIELD_NAME
          ),
          true
        ).returning;
      end;

    finally
      setIdEditable(oldIdEditable);
    end;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cSQLTableModel.update(aRow: cAbstractTableRow; aId: int64; aUpdatingFieldNames: string): integer;
var
  updatingId: int64;

  oldIdEditable: boolean;

  updatingFieldNames: string;
begin
  beginDataChanging;
  try
    oldIdEditable:= isIdEditable;

    if (aId = USE_RECORD_ID) then begin
      updatingId:= aRow.id
    end else begin
      updatingId:= aId;
      setIdEditable(true);
    end;

    //update whole table except not editable cols
    updatingFieldNames:= aUpdatingFieldNames;
    begin
      if (updatingFieldNames = '') then begin
    end;
      updatingFieldNames:= getFieldNames;
    end;


    try
      result:= fCommand.execute(
        fCommandBuilder.getUpdateCommand(
          getTableNameWithSchema,
          collectRowData(updateRowProc, aRow, updatingFieldNames),
          getKeyCondition(updatingId)
        )
      ).rowsAffected;
    finally
      setIdEditable(oldIdEditable);
    end;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

function cSQLTableModel.delete(aRow: cAbstractTableRow): integer;
begin
  beginDataChanging;
  try

    result:= fCommand.execute(
      fCommandBuilder.getDeleteCommand(
        getTableNameWithSchema,
        getKeyCondition(aRow.id)
      )
    ).rowsAffected;

  finally
    endDataChanging(ctTableCRUID);
  end;
end;

procedure cSQLTableModel.deleteRow(aRow: integer);
var
  deletingKey: int64;
  activeRecord: cAbstractTableRow;
begin
  inherited deleteRow(aRow);

  beginDataChanging;
  try
    deletingKey:= getRowKey(aRow);

    deleteRowFromCache(aRow);

    activeRecord:= createActiveRecord;
    try
      activeRecord.fetch(deletingKey);

      activeRecord.delete;
    finally
      freeAndNil(activeRecord);
    end;

    updateRowCount;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;

procedure cSQLTableModel.deleteRowFromCache(aRow: integer);
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

function cSQLTableModel.loadRowData(aRowIndex: integer; aRow: cAbstractTableRow): boolean;
var
  i: integer;
begin
  result:= false;

  moveToRow(aRowIndex);
  for i:= 0 to fQuery.fields.count - 1 do begin
    aRow.setPropertyData(getFields.items[i].name, fQuery.fields[i].asVariant);
  end;

  result:= true;
end;

procedure cSQLTableModel.moveToRow(aRow: integer);
begin
  fQuery.moveTo(aRow);
end;

procedure cSQLTableModel.prepare;
begin
  fetch('1=-1', NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);
end;

function cSQLTableModel.reload(aRow: integer): integer;
var
  table: cAbstractTableModel;
begin
  result:= inherited reload(aRow);

  table:= cSQLTableModel.create;
  try
    table.copyFrom(self);

    result:= table.fetch(getRowKey(aRow));

    if (result = 1) then begin
      copyDataFromTable(table, 0, self, aRow);
    end else begin
      deleteRowFromCache(aRow);
    end;

    rowReloaded(aRow);
  finally
    freeAndNil(table);
  end;
end;

procedure cSQLTableModel.removeRelations;
begin
  if assigned(fSQLRelations) then begin
    freeAndNil(fSQLRelations);
  end;
end;

procedure cSQLTableModel.setFieldData(aCol, aRow: integer; const aValue: variant);
var
  activeRecord: cAbstractTableRow;

  updatingField: cTableField;
  fieldValue: variant;
begin
  fieldValue:= aValue;

  fieldDataSetting(aCol, aRow, fieldValue);

  inherited setFieldData(aCol, aRow, fieldValue);

  beginDataChanging;
  try

    if not (colCanEdit(aCol)) then begin
      raise eSQLTableModel.create(CANNOT_MODIFY_KEY_COL);
    end;

    updatingField:= getFields.items[aCol];

    if (not updatingField.readOnly) then begin
      setCacheFieldData(aCol, aRow, fieldValue);
    end;

    if (updatingField.isSelector) or (updatingField.readOnly) then begin
      exit;
    end;

    activeRecord:= createActiveRecord;
    try
      if loadRowData(aRow, activeRecord) then begin
        activeRecord.flushUpdates;

        //update only updatingField.name
        activeRecord.setPropertyData(updatingField.name, fieldValue);
        activeRecord.update;

        if not (tmsModelChanging in getStates) then begin
          reload(aRow);
        end;
      end;
    finally
      freeAndNil(activeRecord);
    end;


  finally
    endDataChanging(ctTableCRUID);
  end;
end;

procedure cSQLTableModel.setSchema(aSchema: string);
begin
  fSchema:= aSchema;
end;

procedure cSQLTableModel.setSelectCommand(aSelectCommand: string);
begin
  fSelectCommand:= aSelectCommand;
end;

procedure cSQLTableModel.setCacheFieldData(aCol, aRow: integer; const aValue: variant);
begin
  inherited setCacheFieldData(aCol, aRow, aValue);
  fQuery.setFieldData(aCol, aRow, aValue);
end;

procedure cSQLTableModel.setConnection(aSQLConnection: cAbstractSQLConnection);
begin
  fConnection:= aSQLConnection;
  createDependsObjects;
end;

procedure cSQLTableModel.addRelation(aFieldIndex: integer; aTableName, aSchema, aKeyColumnName, aDisplayColumnName: string; aSortDirection: tTableFieldSortDirection);
begin
  fSQLRelations.add(getFields.items[aFieldIndex], cSQLRelation.create(aTableName, aSchema, aKeyColumnName, aDisplayColumnName, aSortDirection));
end;

procedure cSQLTableModel.addRelation(aFieldName, aTableName, aSchema, aKeyColumnName, aDisplayColumnName: string; aSortDirection: tTableFieldSortDirection);
begin
  addRelation(getFields.indexOfName(aFieldName), aTableName, aSchema, aKeyColumnName, aDisplayColumnName, aSortDirection);
end;

function cSQLTableModel.appendRow(aId: int64): integer;
var
  appendedKey: int64;
  activeRecord: cAbstractTableRow;
begin
  result:= inherited appendRow;

  beginDataChanging;
  try
    result:= appendRowToCache;

    //synchronize with cache
    activeRecord:= createActiveRecord;
    try
      appendedKey:= activeRecord.insert(aId);

      if (getFields.getKeyFieldIndex <> -1) then begin
        setCacheFieldData(getFields.getKeyFieldIndex, result, appendedKey);
      end;

      if (getFields.getSelectorFieldIndex <> -1) then begin
        setCacheFieldData(getFields.getSelectorFieldIndex, result, false);
      end;

      addAppendedKey(appendedKey);

      insertDynamicData(appendedKey);

    finally
      freeAndNil(activeRecord);
    end;

    reload(result);

    updateRowCount;
  finally
    endDataChanging(ctTableCRUID);
  end;
end;


{ cSQLRelation }

constructor cSQLRelation.create(aTableName: string; aSchema: string; aKeyColumnName, aDisplayColumnName: string; aSortDirection: tTableFieldSortDirection);
begin
  inherited create;

  fOwner:= nil;

  fSortDirection:= aSortDirection;

  fTableName:= aTableName;
  fSchema:= aSchema;

  fKeyColumnName:= aKeyColumnName;
  fDisplayColumnName:= aDisplayColumnName;

  fDisplayValuesDict:= tDictionary<int64, variant>.create;

  createModel;
end;

destructor cSQLRelation.destroy;
begin
  if assigned(fDisplayValuesDict) then begin
    freeAndNil(fDisplayValuesDict);
  end;

  removeModel;
  inherited;
end;

function cSQLRelation.getDisplayColumnName: string;
begin
  result:= fDisplayColumnName;
end;

function cSQLRelation.getDisplayValueByKey(aKey: int64): variant;
begin
  if fDisplayValuesDict.containsKey(aKey) then begin
    result:= fDisplayValuesDict.items[aKey];
  end else begin
    result:= '';
  end;
end;

function cSQLRelation.getDisplayValueFieldIndex: integer;
begin
  result:= fTableModel.getFields.indexOfName(fDisplayColumnName);
end;

function cSQLRelation.getKeyColumnName: string;
begin
  result:= fKeyColumnName;
end;

function cSQLRelation.getSchema: string;
begin
  result:= fSchema;
end;

function cSQLRelation.getTableModel: cAbstractTableModel;
begin
  result:= fTableModel;
end;

function cSQLRelation.getTableName: string;
begin
  result:= fTableName;
end;

procedure cSQLRelation.loadData;
var
  i: integer;
  displayColumnIndex: integer;
begin
  fDisplayValuesDict.clear;

  displayColumnIndex:= fTableModel.getFields.indexOfName(fDisplayColumnName);

  fTableModel.fetch;

  for i:= 0 to fTableModel.getRowCount - 1 do begin
    fDisplayValuesDict.add(fTableModel.getRowKey(i), fTableModel.getFieldData(displayColumnIndex, i));
  end;
end;

procedure cSQLRelation.createModel;
begin
  fTableModel:= cSQLTableModel.create;
end;

procedure cSQLRelation.removeModel;
begin
  if assigned(fTableModel) then begin
    freeAndNil(fTableModel);
  end;
end;

procedure cSQLRelation.setOwner(aOwner: cSQLRelations);
begin
  fOwner:= aOwner;

  setupModel;
  loadData;
end;

procedure cSQLRelation.setupModel;
begin
  fTableModel.setRowClass(cSQLStdTableRow);

  fTableModel.setSchema(fSchema);
  fTableModel.setTableName(fTableName);
  fTableModel.setSelectCommand(format('select %s, %s from %s.%s', [fKeyColumnName, fDisplayColumnName, fSchema, fTableName]));

  fTableModel.addField(fKeyColumnName      , fKeyColumnName      , true);
  fTableModel.addField(fDisplayColumnName  , fDisplayColumnName  , false, fSortDirection);

  fTableModel.setKeyField(fKeyColumnName);

  fTableModel.setConnection(fOwner.getOwner.getConnection);
end;

procedure cSQLRelation.update;
begin
  loadData;
end;

{ cSQLRelations }

constructor cSQLRelations.create(aOwner: cSQLTableModel);
begin
  inherited create;
  fOwner:= aOwner;

  flist:= tDictionary<cTableField, cSQLRelation>.create;

  setupFieldsEvents;
end;

destructor cSQLRelations.destroy;
var
  pair: tPair<cTableField, cSQLRelation>;
  relation: cSQLRelation;
begin
  for pair in fList do begin
    relation:= pair.value;
    freeAndNil(relation);
  end;

  disconnectFieldEvents;

  if assigned(fList) then begin
    freeAndNil(fList);
  end;

  inherited;
end;

procedure cSQLRelations.disconnectFieldEvents;
begin
  disconnect(fOwner.getFields, 'onFieldRemoving', self, 'fieldRemoving');
end;

procedure cSQLRelations.add(aTableField: cTableField; aSQLRelation: cSQLRelation);
begin
  aSQLRelation.setOwner(self);

  fList.add(aTableField, aSQLRelation);
end;

function cSQLRelations.getOwner: cSQLTableModel;
begin
  result:= fOwner;
end;

function cSQLRelations.getRelation(aTableField: cTableField): cSQLRelation;
begin
  result:= nil;
  if fList.containsKey(aTableField) then begin
    result:= fList.items[aTableField];
  end;
end;

procedure cSQLRelations.setupFieldsEvents;
begin
  connect(fOwner.getFields, 'onFieldRemoving', self, 'fieldRemoving');
end;

//SLOTS
procedure cSQLRelations.fieldRemoving(aSender: cTableFields; aField: cTableField);
begin
  fList.remove(aField);
end;

{ cSQLStdTableRow }

procedure cSQLStdTableRow.afterConstruction;
begin
  inherited;
  setType(dotFullDynamic);
end;

procedure cSQLStdTableRow.setPropertyData(aName: string; const aValue: variant);
begin
  inherited setPropertyData(aName, aValue);
  if (aName = cAbstractTableModel.DEFAULT_KEY_FIELD_NAME) or (aName = cAbstractTableModel.DEFAULT_SELECTOR_FIELD_NAME) then begin
    cClassKit.setObjectProperty(self, aName, aValue);
  end;
end;

end.
