unit clsSQLTreeModel;

interface
uses
  sysUtils,

  uSQLDrivers,
  uModels,

  clsClassKit,
  clsException,
  clsAbstractSQLConnection,
  clsAbstractTreeModel,
  clsAbstractTableModel,
  clsSQLTableModel,
  clsAbstractSQLCommandsBuilder,
  clsAbstractSQLDataBuilder;

type
  eSQLTreeModel = class(cException);

  cSQLTreeModel = class;

  tSQLTreeModelExpandConditionSettingEvent = procedure(aModel: cAbstractTreeModel; var aCondition: string) of object;

  cSQLTreeModel = class(cAbstractTreeModel)
  private
    const
    CONNECTION_IN_TABLE_MODEL_NOT_ASSIGNED = 'connection in table model not assigned';
    UNSUPPORTED_TABLE_MODEL_CLASS          = 'table model class: %s not supported';
    TABLE_MODEL_NOT_ASSIGNED               = 'table model not assigned';

  private
    fOnExpandConditionSetting : tSQLTreeModelExpandConditionSettingEvent;


    fCommandBuilder           : cAbstractSQLCommandsBuilder;
    fDataBuilder              : cAbstractSQLDataBuilder;
    fInternalTableModel       : cSQLTableModel;

    fIdFieldName              : string;
    fParentIdFieldName        : string;
    fTitleFieldName           : string;
    fOrderField               : string;

    procedure   createDependsObjects;
    procedure   destroyDependsObjects;

    function    getCastedTableModel: cSQLTableModel;
    procedure   loadItemsForModel(aItem: cTreeModelItem);

    function    internalAppend(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem;

    procedure   checkTableModelAssigned;
  protected
    function    getCastedInternalTableModel: cSQLTableModel;
  public
    const

    DEFAULT_CTE_NAME             = 'cte';
  public
    //load level 0 items
    function    fetch(const aCondition: string = '1=1'; aLimit: integer = NO_CONSIDER_LIMIT; aOffset: integer = NO_CONSIDER_OFFSET): integer; override;
    //

    function    getInternalTableModel: cAbstractTableModel; override;

    procedure   setIdFieldName(aName: string);
    procedure   setParentIdFieldName(aName: string);
    procedure   setTitleFieldName(aName: string);

    function    getIdFieldName: string;
    function    getParentIdFieldName: string;
    function    getTitleFieldName: string;


    procedure   setOrderField(aName: string);
    function    getOrderField: string;

    procedure   setTableModel(aTableModel: cAbstractTableModel); override;


    function    append(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem; overload; override;

    function    appendToCache(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem; override;
    procedure   update(aItem: cTreeModelItem); override;
    procedure   moveTo(aFrom: cTreeModelItem; aTo: cTreeModelItem); override;

    function    reload(aItem: cTreeModelItem): integer; overload; override;


    //lazy load item
    procedure   expand(aItem: cTreeModelItem); override;

    procedure   delete(aItem: cTreeModelItem); override;
    procedure   deleteRecurse(aItem: cTreeModelItem); override;

    constructor create;
    destructor  destroy; override;
  published
    {$REGION 'EVENTS'}
    property onExpandConditionSetting: tSQLTreeModelExpandConditionSettingEvent read fOnExpandConditionSetting write fOnExpandConditionSetting;
    {$ENDREGION}
  end;

implementation
uses
  clsSQLCommandsBuildersFactory,
  clsSQLDataBuildersFactory;


{ cSQLTreeModel }

procedure cSQLTreeModel.checkTableModelAssigned;
begin
  if (not(assigned(tableModel))) then begin
    raise eSQLTreeModel.create(TABLE_MODEL_NOT_ASSIGNED);
  end;
end;

function cSQLTreeModel.append(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem;
begin
  beginDataChanging;
  try
    result:= inherited append(aParentItem, aId, aTitle);
    result:= internalAppend(aParentItem, aId, aTitle);
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

function cSQLTreeModel.appendToCache(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem;
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

constructor cSQLTreeModel.create;
begin
  inherited create;

  fInternalTableModel:= nil;
  fCommandBuilder:= nil;
  fDataBuilder:= nil;

  setIdFieldName(cAbstractTableModel.DEFAULT_KEY_FIELD_NAME);
  setParentIdFieldName(DEFAULT_PARENT_ID_FIELD_NAME);
  setTitleFieldName(DEFAULT_TITLE_FIELD_NAME);

  setOrderField(getTitleFieldName);
end;

destructor cSQLTreeModel.destroy;
begin
  destroyDependsObjects;
  inherited;
end;

procedure cSQLTreeModel.createDependsObjects;
var
  SQLDriver: tSQLDriver;
  SQLTableModel: cSQLTableModel;
  SQLConnection: cAbstractSQLConnection;
begin
  checkTableModelAssigned;

  SQLTableModel:= getCastedTableModel;

  SQLConnection:= SQLTableModel.getConnection;

  if (not(assigned(SQLConnection))) then begin
    raise eSQLTreeModel.create(CONNECTION_IN_TABLE_MODEL_NOT_ASSIGNED);
  end;



  SQLDriver:= SQLConnection.connectionInfo.driver;

  destroyDependsObjects;

  fInternalTableModel := cSQLTableModel.create;
  fInternalTableModel.copyFrom(getTableModel);




  fCommandBuilder     := cSQLCommandsBuilderFactory.createNew(SQLDriver);
  fDataBuilder        := cSQLDataBuildersFactory.createNew(SQLDriver);
end;

procedure cSQLTreeModel.destroyDependsObjects;
begin
  if assigned(fInternalTableModel) then begin
    freeAndNil(fInternalTableModel);
  end;

  if assigned(fCommandBuilder) then begin
    freeAndNil(fCommandBuilder);
  end;

  if assigned(fDataBuilder) then begin
    freeAndNil(fDataBuilder);
  end;
end;

procedure cSQLTreeModel.delete(aItem: cTreeModelItem);
var
  SQLTableModel: cSQLTableModel;

  SQLConnection: cAbstractSQLConnection;
begin
  SQLTableModel:= getCastedInternalTableModel;


  SQLConnection:= SQLTableModel.getConnection;

  if (not(assigned(SQLConnection))) then begin
    raise eSQLTreeModel.create(CONNECTION_IN_TABLE_MODEL_NOT_ASSIGNED);
  end;


  beginDataChanging;
  try

    SQLConnection.execute(
      fCommandBuilder.getDeleteCommand(SQLTableModel.getTableNameWithSchema,
        format('%s = %d',
          [
            getIdFieldName,
            aItem.id

          ]
        )
      )
    );

    inherited delete(aItem);
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;


procedure cSQLTreeModel.deleteRecurse(aItem: cTreeModelItem);
var
  workTableParams: sSQLCTEWorkTableParams;
  intermediateTableParams: sSQLCTEIntermediateTableParams;
  resultTableParams: sSQLCTEResultTableParams;

  SQLTableModel: cSQLTableModel;

  SQLConnection: cAbstractSQLConnection;

  CTESQLCommand: string;
begin
  SQLTableModel:= getCastedInternalTableModel;


  SQLConnection:= SQLTableModel.getConnection;

  if (not(assigned(SQLConnection))) then begin
    raise eSQLTreeModel.create(CONNECTION_IN_TABLE_MODEL_NOT_ASSIGNED);
  end;





  workTableParams.selectCommand:= SQLTableModel.getSelectCommand;
  workTableParams.condition:= format('%s.%s = %d', [SQLTableModel.getTableName, getIdFieldName, aItem.id]);

  intermediateTableParams.selectCommand:= format(

    '%s inner join %s on %s.%s = %s.%s',
    [
      SQLTableModel.getSelectCommand,

      DEFAULT_CTE_NAME,
      SQLTableModel.getTableName,
      getParentIdFieldName,
      DEFAULT_CTE_NAME,
      getIdFieldName
    ]
  );


  intermediateTableParams.condition:= '1=1';


  resultTableParams.selectCommand:= format('select %s from %s',
    [
      getIdFieldName,

      DEFAULT_CTE_NAME
    ]
  );

  resultTableParams.condition:= '1=1';
  resultTableParams.order:= '';

  CTESQLCommand:= fCommandBuilder.getCTESelectCommand(DEFAULT_CTE_NAME, workTableParams, intermediateTableParams, resultTableParams);

  beginDataChanging;
  try

    SQLConnection.execute(
      fCommandBuilder.getDeleteCommand(SQLTableModel.getTableNameWithSchema,
        format('%s in(%s)',
          [
            getIdFieldName,
            CTESQLCommand
          ]
        )
      )
    );

    inherited deleteRecurse(aItem);
  finally
    endDataChanging(ctTreeCRUID);
  end;
end;

procedure cSQLTreeModel.expand(aItem: cTreeModelItem);
var
  SQLTableModel: cSQLTableModel;

  fetchCommand: string;

  expandCondition: string;
begin
  checkTableModelAssigned;

  if not assigned(aItem) then exit;

  if (aItem.isExpanded) then begin
    inherited expand(aItem);
    exit;
  end;

  SQLTableModel:= getCastedInternalTableModel;

  if (aItem = getRootItem) then begin
    fetchCommand:= getFetchCommand;
  end else begin
    expandCondition:= format('%s = %d', [getParentIdFieldName, aItem.id]);

    if assigned(fOnExpandConditionSetting) then begin
      fOnExpandConditionSetting(self, expandCondition);
    end;

    fetchCommand:=
      fCommandBuilder.getSelectCommand(
        SQLTableModel.getSelectCommand,
        expandCondition,
        getOrderField
      );
  end;


  aItem.setExpanded(true);

  if (SQLTableModel.rawFetch(fetchCommand) = 0) then exit;

  loadItemsForModel(aItem);

  inherited expand(aItem);
end;

function cSQLTreeModel.fetch(const aCondition: string; aLimit, aOffset: integer): integer;
var
  workTableParams: sSQLCTEWorkTableParams;
  intermediateTableParams: sSQLCTEIntermediateTableParams;
  resultTableParams: sSQLCTEResultTableParams;

  SQLTableModel: cSQLTableModel;
begin
  checkTableModelAssigned;

  inherited fetch(aCondition, aLimit, aOffset);

  SQLTableModel:= getCastedInternalTableModel;

  getCastedTableModel.createDynamicData(aCondition, aLimit, aOffset);

  workTableParams.selectCommand:= SQLTableModel.getSelectCommand;
  workTableParams.condition:= getCondition;

  intermediateTableParams.selectCommand:= format(

    '%s inner join %s on %s.%s = %s.%s',
    [
      SQLTableModel.getSelectCommand,

      DEFAULT_CTE_NAME,
      SQLTableModel.getTableName,
      getIdFieldName,
      DEFAULT_CTE_NAME,
      getParentIdFieldName
    ]
  );
  intermediateTableParams.condition:= '1=1';


  resultTableParams.selectCommand:= format('select distinct *  from %s',
    [
      DEFAULT_CTE_NAME
    ]
  );

  resultTableParams.condition:= format('%s = 0', [getParentIdFieldName]);
  resultTableParams.order:= getOrderField;

  beginDataChanging;
  try

    beginDataFetching;
    try
      setFetchCommand(
        fCommandBuilder.getSelectCommandLimited(
          fCommandBuilder.getCTESelectCommand(DEFAULT_CTE_NAME, workTableParams, intermediateTableParams, resultTableParams),
          getLimit,
          getOffset
        )
      );

      result:= SQLTableModel.rawFetch(getFetchCommand);
      if (result = 0) then begin
        exit;
      end;

    finally
      endDataFetching;
    end;

  finally
    endDataChanging(ctTreeFetch);
  end;
end;

procedure cSQLTreeModel.loadItemsForModel(aItem: cTreeModelItem);
var
  SQLTableModel: cSQLTableModel;

  iterator: cTableCursor;
  curRow: cAbstractTableRow;
begin
  SQLTableModel:= getCastedInternalTableModel;

  iterator:= SQLTableModel.getIterator;
  try
    while iterator.moveNext do begin

      curRow:= iterator.current;

      createItem(
        aItem,
        curRow,
        curRow.getFieldData(getIdFieldName),
        curRow.getFieldData(getTitleFieldName)
      )

    end;
  finally
    freeAndNil(iterator);
  end;
end;

procedure cSQLTreeModel.moveTo(aFrom, aTo: cTreeModelItem);
begin
  inherited moveTo(aFrom, aTo);

  update(aFrom);
end;

function cSQLTreeModel.reload(aItem: cTreeModelItem): integer;
var
  activeRecord: cAbstractTableRow;
begin
  result:= inherited reload(aItem);

  if (not(assigned(tableModel))) then exit;

  if not assigned(aItem) then exit;

  getCastedTableModel.updateDynamicData(aItem.id);

  activeRecord:= getInternalTableModel.createActiveRecord;
  try

    result:= activeRecord.fetch(aItem.id);

    if (result > 0) then begin
      beginDataChanging;
      try

        aItem.parentId:= activeRecord.getFieldData(cSQLTreeModel.DEFAULT_PARENT_ID_FIELD_NAME);
        aItem.title:= activeRecord.getFieldData(cSQLTreeModel.DEFAULT_TITLE_FIELD_NAME);

        loadItemDataFromTableRow(aItem, activeRecord);

      finally
        endDataChanging(ctTreeCRUID);
      end;

    end else begin
      deleteRecurseFromCache(aItem);
    end;

    itemReloaded(self, aItem);
  finally
    freeAndNil(activeRecord);
  end;
end;

function cSQLTreeModel.getCastedTableModel: cSQLTableModel;
begin
  result:= nil;
  if (not (tableModel is cSQLTableModel)) then begin
    raise eSQLTreeModel.createFmt(UNSUPPORTED_TABLE_MODEL_CLASS, [tableModel.className]);
  end;

  result:= cSQLTableModel(tableModel);
end;

function cSQLTreeModel.getCastedInternalTableModel: cSQLTableModel;
begin
  result:= nil;
  if (not (fInternalTableModel is cSQLTableModel)) then begin
    raise eSQLTreeModel.createFmt(UNSUPPORTED_TABLE_MODEL_CLASS, [fInternalTableModel.className]);
  end;

  result:= cSQLTableModel(fInternalTableModel);
end;

function cSQLTreeModel.getIdFieldName: string;
begin
  result:= fIdFieldName;
end;

function cSQLTreeModel.getInternalTableModel: cAbstractTableModel;
begin
  result:= fInternalTableModel;
end;

function cSQLTreeModel.getOrderField: string;
begin
  result:= fOrderField;
end;

function cSQLTreeModel.getParentIdFieldName: string;
begin
  result:= fParentIdFieldName;
end;

function cSQLTreeModel.getTitleFieldName: string;
begin
  result:= fTitleFieldName;
end;

function cSQLTreeModel.internalAppend(aParentItem: cTreeModelItem; aId: int64; aTitle: string): cTreeModelItem;
var
  SQLTableModel: cSQLTableModel;

  activeRecord: cAbstractTableRow;
begin
  result:= appendToCache(aParentItem, aId, aTitle);

  SQLTableModel:= getCastedInternalTableModel;

  activeRecord:= SQLTableModel.createActiveRecord;
  activeRecord.setPropertyData(getParentIdFieldName, result.parentId);
  activeRecord.setPropertyData(getTitleFieldName, result.title);

  activeRecord.insert(aId);

  result.id:= activeRecord.id;

  result.setTableRow(activeRecord);
end;

procedure cSQLTreeModel.setIdFieldName(aName: string);
begin
  fIdFieldName:= aName;
end;

procedure cSQLTreeModel.setOrderField(aName: string);
begin
  fOrderField:= aName;
end;

procedure cSQLTreeModel.setParentIdFieldName(aName: string);
begin
  fParentIdFieldName:= aName;
end;

procedure cSQLTreeModel.setTableModel(aTableModel: cAbstractTableModel);
begin
  inherited setTableModel(aTableModel);
  createDependsObjects;
end;

procedure cSQLTreeModel.setTitleFieldName(aName: string);
begin
  fTitleFieldName:= aName;
end;

procedure cSQLTreeModel.update(aItem: cTreeModelItem);
var
  SQLTableModel: cSQLTableModel;

  activeRecord: cAbstractTableRow;
begin
  beginDataChanging;
  try

    SQLTableModel:= getCastedInternalTableModel;

    activeRecord:= SQLTableModel.createActiveRecord;
    try
      activeRecord.copyFrom(aItem.getTableRow);

      activeRecord.setPropertyData(getIdFieldName, aItem.id);
      activeRecord.setPropertyData(getParentIdFieldName, aItem.parentId);
      activeRecord.setPropertyData(getTitleFieldName, aItem.title);
      activeRecord.update;
    finally
      freeAndNil(activeRecord);
    end;

  finally
    endDataChanging(ctTreeCRUID);
  end;

end;

end.
