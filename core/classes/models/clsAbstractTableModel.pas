unit clsAbstractTableModel;

interface
uses
  windows,
  sysUtils,
  db,
  math,
  variants,
  generics.collections,
  strUtils,

  uModels,

  clsAbstractModel,
  clsClassKit,
  clsIntegerList,

  clsVariantConversion,
  clsStringUtils,
  clsException,
  clsDynamicalObject,
  clsLists;

type
  eAbstractTableModel = class(cException);
  eAbstractTableRow = class(cException);

  cAbstractTableModel = class;
  tTableModelClass = class of cAbstractTableModel;

  cAbstractTableRow = class;
  tTableRowClass = class of cAbstractTableRow;

  tTableFieldState = (fsReadOnly, fsEditable, fsSortable);

  tTableFieldStates = set of tTableFieldState;

  tTableFieldSortDirection = (sdNone, sdAsc, sdDesc);

  cTableField = class;

  tTableFieldSortDirectionChangedEvent = procedure(aSender: cTableField; aOldDirection: tTableFieldSortDirection) of object;

  cRelation = class
  public
    procedure   update; virtual; abstract;

    function    getDisplayValueFieldIndex: integer; virtual; abstract;
    function    getDisplayValueByKey(aKey: int64): variant; virtual; abstract;
    function    getTableModel: cAbstractTableModel; virtual; abstract;
  end;


  cTableField = class
  private
    fName                   : string;
    fTitle                  : string;
    fReadOnly               : boolean;
    fIsKey                  : boolean;
    fIsSelector             : boolean;
    fStates                 : tTableFieldStates;
    fSortDirection          : tTableFieldSortDirection;
    fData                   : variant;

    fOnSortDirectionChanged : tTableFieldSortDirectionChangedEvent;

    function    getStates: tTableFieldStates;
    procedure   setSortDirection(aValue: tTableFieldSortDirection);
  public
    procedure   setData(aValue: variant);
    procedure   setKey(aValue: boolean);
    procedure   setSelector(aValue: boolean);
    function    containsStates(aStates: tTableFieldStates): boolean;

    constructor create(aName, aTitle: string; aReadOnly: boolean; aSortDirection: tTableFieldSortDirection = sdNone);
    destructor  destroy; override;

    property    name: string read fName;
    property    title: string read fTitle write fTitle;
    property    readOnly: boolean read fReadOnly write fReadOnly;
    property    isKey: boolean read fIsKey;
    property    isSelector: boolean read fIsSelector;
    property    sortDirection: tTableFieldSortDirection read fSortDirection write setSortDirection;
    property    data: variant read fData write setData;

    property    states: tTableFieldStates read getStates;

  published
    //EVENTS
    property    onSortDirectionChanged: tTableFieldSortDirectionChangedEvent read fOnSortDirectionChanged write fOnSortDirectionChanged;
  end;

  cTableFields = class;

  tTableFieldsActionProc = function (aSender: cTableFields; aField: cTableField): string of object;

  tTableFieldsSortDirectionChangedEvent = procedure(aSender: cTableFields; aField: cTableField; aOldDirection: tTableFieldSortDirection) of object;

  tTableFieldsFieldAddedEvent = procedure(aSender: cTableFields; aField: cTableField) of object;
  tTableFieldsFieldRemovingEvent = procedure(aSender: cTableFields; aField: cTableField) of object;

  eTableFields = class(cException);

  cTableFields = class
  public
    const

    DEFAULT_FIELDS_DELIMITER   = ',';
    SELECTOR_SUPPORTS_ONLY_FOR_FIRST_FIELD = 'selector supports only for first field';
  private
    fList                   : cList;
    fKeyIndex               : integer;
    fSelectorIndex          : integer;
    fOwnFields              : boolean;


    fOnSortDirectionChanged : tTableFieldsSortDirectionChangedEvent;

    fOnFieldAdded           : tTableFieldsFieldAddedEvent;
    fOnFieldRemoving        : tTableFieldsFieldRemovingEvent;

    procedure   rebuildFields;

    function    getCount: integer;
    function    getFieldByIndex(aIndex: integer): cTableField;


    function    collectEditableFieldsProc(aSender: cTableFields; aField: cTableField): string;

    procedure   updateKeyIndex(aNewIndex: integer);
    procedure   updateSelectorIndex(aNewIndex: integer);

    function    searchSelectorFieldIndex: integer;
    function    searchKeyFieldIndex: integer;
  public
    procedure   clearSort;
    procedure   clear;

    function    collectFieldInfo(aActionProc: tTableFieldsActionProc; aConcatString: string = DEFAULT_FIELDS_DELIMITER): string;

    function    isFieldNameSelector(aFieldName: string): boolean;
    procedure   setKeyField(aFieldName: string);
    procedure   setSelectorField(aFieldName: string);
    procedure   setFieldTitle(aFieldName: string; aTitle: string);


    function    getSelectorFieldIndex: integer;
    function    getKeyFieldIndex: integer;

    function    getSelectorField: cTableField;
    function    getKeyField: cTableField;

    procedure   add(aField: cTableField);
    procedure   insert(aField: cTableField; aIndex: integer);
    procedure   delete(aIndex: integer);

    function    getEditableFields: string;

    function    indexOfName(aName: string): integer;
    function    indexOf(aField: cTableField): integer;

    constructor create(aOwnFields: boolean = true);
    destructor  destroy; override;


    property    items[aIndex: integer]: cTableField read getFieldByIndex;
    property    count: integer read getCount;

  published
    //SLOTS
    procedure   sortDirectionChanged(aSender: cTableField; aOldDirection: tTableFieldSortDirection);

  published
    //EVENTS
    property    onSortDirectionChanged: tTableFieldsSortDirectionChangedEvent read fOnSortDirectionChanged write fOnSortDirectionChanged;

    property    onFieldAdded: tTableFieldsFieldAddedEvent read fOnFieldAdded write fOnFieldAdded;
    property    onFieldRemoving: tTableFieldsFieldRemovingEvent read fOnFieldRemoving write fOnFieldRemoving;
  end;





  cTableCursor = class;


  //base class contains common logic, default key field is id (int64), other fields must be implemented in published section
  tRowType = (rtIterator, rtActiveRecord);
  //in case
  cAbstractTableRow = class(cDynamicalObject)
  private
    fId                   : int64;
    fSelected             : boolean;
    fOwner                : cAbstractTableModel;
    fRowType              : tRowType;

    fOwnerCreatedManually : boolean;

    fChangedFields  : tDictionary<string,boolean>;

    procedure   initialize;
  protected
    const

    OPERATION_NOT_PERMITED  = 'type: iterator, operation not permited';
  public
    procedure   setPropertyData(aName: string; const aValue: variant); override;

    procedure   flushUpdates;

    function    getFieldData(aFieldName: string): variant;
    function    getRowType: tRowType;
    function    getOwner: cAbstractTableModel;

    function    insert(aId: int64 = NEW_KEY_ID): int64;
    function    update(aId: int64 = USE_RECORD_ID): integer;
    function    delete: integer;

    //fetch first satisfying condition
    function    fetch(const aCondition: string): integer; overload;
    function    fetch(aId: int64): integer; overload;

    //create have 2 entry point (constructor)
    //1 - when row created directly from table - owner
    //2 - when row is independent (active record), in this case user must define owner table class
    constructor create(aTable: cAbstractTableModel); overload;
    constructor createActiveRecord(aTable: cAbstractTableModel; aTableClass: tTableModelClass); overload;
    constructor createActiveRecord(aTableClass: tTableModelClass); overload;
    constructor createActiveRecord(aTable: cAbstractTableModel); overload;

    destructor  destroy; override;

  published
    property    selected: boolean read fSelected write fSelected;
    property    id: int64 read fId write fId;

    //fChangedFields must not contains this fields!!!
    property    owner: cAbstractTableModel read getOwner;
    property    rowType: tRowType read getRowType;
  end;



  cTableCursor = class
  private
    const

    MOVE_NEXT_NOT_CALLED = 'cannot get current row, moveNext was not called';
  private
    fRowIndex    : integer;
    fTable       : cAbstractTableModel;

    function    getRowsFetched: integer;
  public
    function    getCurrent: cAbstractTableRow; inline;
    function    moveNext: boolean;

    property    current: cAbstractTableRow read getCurrent;

    property    rowsFetched: integer read getRowsFetched;

    constructor create(aTable: cAbstractTableModel);
    destructor  destroy; override;
  end;

  tAbstractTableModelDataChangedType = (ctTableFetch, ctTableCRUID);

  tAbstractTableModelSelectedRowsConditionCheckProc = reference to function (aRow: integer): boolean;
  tAbstractTableModelSelectedRowsAddProc = reference to function (aRow: integer): string;

  tAbstractTableModelDataFetchedEvent = procedure(aModel: cAbstractTableModel; const aCommand: string; const aCondition: string; aLimit: integer; aOffset: integer) of object;
  tAbstractTableModelDataFetchingEvent = procedure(aModel: cAbstractTableModel; var aCommand: string; var aLimit: integer; var aOffset: integer) of object;
  tAbstractTableModelConditionSettedEvent = procedure(aModel: cAbstractTableModel; const aCondition: string) of object;
  tAbstractTableModelConditionSettingEvent = procedure(aModel: cAbstractTableModel; var aCondition: string) of object;
  tAbstractTableModelDataChangedEvent = procedure(aModel: cAbstractTableModel; aType: tAbstractTableModelDataChangedType) of object;


  tAbstractTableModelBeginRowsAppending = procedure(aModel: cAbstractTableModel) of object;
  tAbstractTableModelEndRowsAppending = procedure(aModel: cAbstractTableModel) of object;

  tAbstractTableModelBeginRowsDeleting = procedure(aModel: cAbstractTableModel) of object;
  tAbstractTableModelEndRowsDeleting = procedure(aModel: cAbstractTableModel) of object;

  tAbstractTableModelBeginRowsReloading = procedure(aModel: cAbstractTableModel) of object;
  tAbstractTableModelEndRowsReloading = procedure(aModel: cAbstractTableModel) of object;

  tAbstractTableModelRowReloadedEvent = procedure(aModel: cAbstractTableModel; aRow: integer) of object;
  tAbstractTableModelRowReloadingEvent = procedure(aModel: cAbstractTableModel; aRow: integer; aId: int64) of object;

  tAbstractTableModelRowDeletedEvent = procedure(aModel: cAbstractTableModel; aRow: integer) of object;
  tAbstractTableModelRowDeletingEvent = procedure(aModel: cAbstractTableModel; aRow: integer) of object;

  tAbstractTableModelFieldDataSettingEvent = procedure(aModel: cAbstractTableModel; aCol: integer; aRow: integer; var aValue: variant) of object;
  tAbstractTableModelFieldDataGettingEvent = procedure(aModel: cAbstractTableModel; aCol: integer; aRow: integer; var aValue: variant) of object;

  tAbstractTableModelRowAppendedEvent = procedure(aModel: cAbstractTableModel; aRow: integer) of object;
  tAbstractTableModelRowAppendingEvent = procedure(aModel: cAbstractTableModel; aId: int64) of object;

  tAbstractTableModelRowCountChangedEvent = procedure(aModel: cAbstractTableModel) of object;

  tTableModelState = (tmsDataFetching, tmsDataChanging, tmsModelChanging, tmsConditionSetting, tmsRowsAppending, tmsRowsDeleting, tmsRowsReloading);

  tTableModelStates = set of tTableModelState;

  tAbstractTableModelRowFilterProc = reference to function (aModel: cAbstractTableModel; aModelRow: integer): boolean;

  tAbstractTableModelLocateCompareProc = reference to function (aCol: integer; aRow: integer; aValue: variant): boolean;

  tTableModelDataRole = (drRawData, drUseRelation);

  cAbstractTableModel = class (cAbstractModel)
  private
    fFields                   : cTableFields;
    fRowCount                 : integer;

    //for quick access we use tDictionary
    fAppendedKeys             : tDictionary<int64, boolean>; //boolean is stub

    fRowClass                 : tTableRowClass;
    fNativeIteratorRow        : cAbstractTableRow;
    fOnDataFetching           : tAbstractTableModelDataFetchingEvent;
    fOnDataFetched            : tAbstractTableModelDataFetchedEvent;
    fOnConditionSetting       : tAbstractTableModelConditionSettingEvent;
    fOnConditionSetted        : tAbstractTableModelConditionSettedEvent;
    fOnDataChanged            : tAbstractTableModelDataChangedEvent;

    fOnRowReloaded            : tAbstractTableModelRowReloadedEvent;
    fOnRowReloading           : tAbstractTableModelRowReloadingEvent;
    fOnRowAppended            : tAbstractTableModelRowAppendedEvent;
    fOnRowAppending           : tAbstractTableModelRowAppendingEvent;
    fOnRowDeleted             : tAbstractTableModelRowDeletedEvent;
    fOnRowDeleting            : tAbstractTableModelRowDeletingEvent;

    fOnBeginRowsAppending     : tAbstractTableModelBeginRowsAppending;
    fOnEndRowsAppending       : tAbstractTableModelEndRowsAppending;

    fOnBeginRowsDeleting      : tAbstractTableModelBeginRowsDeleting;
    fOnEndRowsDeleting        : tAbstractTableModelEndRowsDeleting;

    fOnBeginRowsReloading     : tAbstractTableModelBeginRowsReloading;
    fOnEndRowsReloading       : tAbstractTableModelEndRowsReloading;

    fOnRowCountChanged        : tAbstractTableModelRowCountChangedEvent;
    fOnFieldDataSetting       : tAbstractTableModelFieldDataSettingEvent;
    fOnFieldDataGetting       : tAbstractTableModelFieldDataGettingEvent;

    fTableName                : string;

    fCondition                : string;
    fLimit                    : integer;
    fOffset                   : integer;
    fFetchMoreLimit           : integer;
    fFetchMoreOffset          : integer;

    fFetchCommand             : string;

    fIdEditable               : boolean;

    fStates                   : tTableModelStates;
    fLastAppendedRow          : integer;
    fLastIteratorRowIndex     : integer;

    fOldCondition             : string;
    fOldLimit                 : integer;
    fOldOffset                : integer;

    fConditionSettedHandled   : boolean;


  protected
    const

    ITERATOR_ROW_NOT_ASSIGNED         = 'iterator row not assigned';
    FIELD_NAME_ALREADY_EXISTS_FORMAT  = 'field name: %s, already exists';
  protected
    procedure   fieldDataSetting(aCol: integer; aRow: integer; var aValue: variant);
    procedure   fieldDataGetting(aCol: integer; aRow: integer; var aValue: variant);

    procedure   clearIteratorRowIndex;
    procedure   setLastIteratorRowIndex(aRow: integer);

    procedure   setLastAppededRow(aRow: integer);
    function    getLastAppendedRow: integer;

    procedure   setLimit(aLimit: integer);
    function    getLimit: integer;

    procedure   setOffset(aOffset: integer);
    function    getOffset: integer;

    procedure   setCondition(const aCondition: string);
    function    getCondition: string;
    procedure   conditionSetting(var aCondition: string); virtual;

    function    getFetchCommand: string;
    procedure   setFetchCommand(aCommand: string);

    function    getRowClass: tTableRowClass;
    function    getTableClass: tTableModelClass;

    function    getNativeIteratorRow: cAbstractTableRow;
    procedure   seNativetIteratorRow(aIteratorRow: cAbstractTableRow);

    procedure   setRowCount(aCount: integer);
    procedure   updateRowCount; virtual;

    function    copyDataFromTable(aSourceTable: cAbstractTableModel; aSourceRow: integer; aDestTable: cAbstractTableModel; aDestRow: integer): boolean; virtual; abstract;

    //independent function
    function    insert(aRow: cAbstractTableRow; aId: int64 = NEW_KEY_ID): int64; virtual; abstract;
    //returns rows affected
    function    update(aRow: cAbstractTableRow; aId: int64 = USE_RECORD_ID; aUpdatingFieldNames: string = ''): integer; virtual; abstract;
    function    delete(aRow: cAbstractTableRow): integer; virtual; abstract;
    //

    procedure   dataFetched;
    procedure   beginDataFetching;
    procedure   dataFetching(var aCommand: string; var aLimit: integer; var aOffset: integer); virtual;
    procedure   endDataFetching;

    procedure   beginRowsAppending;
    procedure   endRowsAppending;

    procedure   beginRowsDeleting;
    procedure   endRowsDeleting;

    procedure   beginRowsReloading;
    procedure   endRowsReloading;

    procedure   beginDataChanging;
    procedure   endDataChanging(aType: tAbstractTableModelDataChangedType);

    property    nativeIteratorRow: cAbstractTableRow read getNativeIteratorRow;

    procedure   setSelectorField(aFieldName: string);

    procedure   internalDeleteRowsForFilter(aFilterProc: tAbstractTableModelRowFilterProc; aDeleteOnlyFromCache: boolean);

    procedure   rowReloading(aRow: integer; aId: int64); virtual;
    procedure   rowReloaded(aRow: integer); virtual;

    procedure   rowDeleting(aRow: integer); virtual;
    procedure   rowDeleted(aRow: integer); virtual;

    procedure   addAppendedKey(aValue: int64);
    procedure   clearAppendedKeys;
    function    appendedKeyExists(aValue: int64): boolean;
  public
    const

    DEFAULT_KEY_FIELD_NAME       = 'id';
    DEFAULT_SELECTOR_FIELD_NAME  = 'selected';
    FIRST_ROW                    = 0;
  public
    function    colCanEdit(aCol: integer): boolean;

    function    getSelectedRowsCheckProc(aRow: integer): boolean;
    function    getSelectedRowsIdsAddProc(aRow: integer): string;
    function    getSelectedRowsIndexesAddProc(aRow: integer): string;

    function    getRowsCheckProc(aRow: integer): boolean;
    function    getRowsIdsAddProc(aRow: integer): string;


    function    getRelation(aFieldIndex: integer): cRelation; overload; virtual;
    function    getRelation(aFieldName: string): cRelation; overload; virtual;

    function    locate(aLocateCompareProc: tAbstractTableModelLocateCompareProc; aValue: variant; aCol: integer; aStartRow: integer; aSearchDirection: tModelSearchDirection = sdForward; aSearchPosition: tModelSearchPosition = spFirst): integer; overload;
    function    locate(aValue: variant; aCol: integer; aStartRow: integer = FIRST_ROW; aSearchDirection: tModelSearchDirection = sdForward; aSearchPosition: tModelSearchPosition = spFirst): integer; overload;

    function    locateByValueEqualProc(aCol: integer; aRow: integer; aValue: variant): boolean;
    function    locateByValuePartProc(aCol, aRow: integer; aValue: variant): boolean;

    //temporary stub for dynamic queries
    procedure   createDynamicData(const aCondition: string; aLimit: integer; aOffset: integer); virtual;
    procedure   updateDynamicData(aId: int64); virtual;
    procedure   deleteDynamicData(aId: int64); virtual;
    procedure   insertDynamicData(aId: int64); virtual;
    //

    procedure   beginModelChanging;
    procedure   endModelChanging;

    procedure   setRowClass(aRowClass: tTableRowClass);

    procedure   deleteRowsFromCacheForFilter(aFilterProc: tAbstractTableModelRowFilterProc);

    function    deleteSelectedRowsFilterProc(aModel: cAbstractTableModel; aRow: integer): boolean;
    procedure   deleteRowsForFilter(aFilterProc: tAbstractTableModelRowFilterProc);

    procedure   deleteSelectedRows;
    procedure   deleteSelectedRowsFromCache;

    function    getAggregateCommand(aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes; aUserCondition: string = ''): string; virtual; abstract;

    function    getStates: tTableModelStates;

    procedure   setIdEditable(aValue: boolean);
    function    isIdEditable: boolean;

    function    getTableName: string;
    procedure   setTableName(aTableName: string);

    function    getFullRowCountWithoutLimits: integer; virtual; abstract;

    function    getSelectedRowsIndexes(aDelimiter: string = ','): string;
    function    getSelectedRowsIds(aDelimiter: string = ','): string;
    function    getRowsIds(aDelimiter: string = ','): string;

    //default delimiter ','
    procedure   setSelectedRowsIds(aIds: string; aValue: boolean);

    function    isSelectionEmpty: boolean;

    function    getRowsDataForCondition(aAddProc: tAbstractTableModelSelectedRowsAddProc; aDelimiter: string; aQuote: string; aConditionCheckProc: tAbstractTableModelSelectedRowsConditionCheckProc): string;
    procedure   setRowsSelected(aValue: boolean);
    procedure   setRowSelected(aRow: integer; aValue: boolean);

    procedure   attachIteratorRow(aIteratorRow: cAbstractTableRow);
    procedure   detachIteratorRow(aIteratorRow: cAbstractTableRow);

    function    getIteratorRow(aRowIndex: integer): cAbstractTableRow;
    function    getIterator: cTableCursor;

    function    rawFetch(const aCommand: string): integer; overload; virtual;

    function    fetch(const aCondition: string; aLimit: integer; aOffset: integer): integer; overload; virtual;
    function    fetch(aLimit: integer; aOffset: integer): integer; overload; virtual;
    function    fetch(aId: int64): integer; overload; virtual; abstract;

    function    loadRowData(aRowIndex: integer; aRow: cAbstractTableRow): boolean; overload; virtual; abstract;
    function    loadRowData(aRowIndex: integer): boolean; overload; virtual;

    procedure   moveToRow(aRow: integer); virtual; abstract;

    function    addField(aName, aTitle: string; aReadOnly: boolean; aSortDirection: tTableFieldSortDirection = sdNone): cTableField; virtual;
    function    insertField(aIndex: integer; aName, aTitle: string; aReadOnly: boolean; aSortDirection: tTableFieldSortDirection = sdNone): cTableField; virtual;

    procedure   setKeyField(aFieldName: string);
    procedure   enableSelector(aValue: boolean); virtual;
    function    isSelectorEnabled: boolean;

    function    getFieldNames: string;

    function    getFieldType(aCol: integer): tDataType; virtual; abstract;

    function    getFieldData(aCol: integer; aRow: integer; aGetDataRole: tTableModelDataRole = drUseRelation): variant; overload; virtual; abstract;
    function    getFieldData(aName: string; aRow: integer; aGetDataRole: tTableModelDataRole = drUseRelation): variant; overload; virtual; abstract;

    procedure   setFieldData(aCol: integer; aRow: integer; const aValue: variant); overload; virtual;
    procedure   setFieldData(aName: string; aRow: integer; const aValue: variant); overload; virtual;

    procedure   setCacheFieldData(aCol: integer; aRow: integer; const aValue: variant); overload; virtual;
    procedure   setCacheFieldData(aName: string; aRow: integer; const aValue: variant); overload; virtual;

    function    reload: integer; overload; virtual;
    function    reload(aRow: integer): integer; overload; virtual;
    function    reload(aRows: string): integer; overload; virtual;
    function    reload(aRowsList: cIntegerList): integer; overload; virtual;

    function    addDataPortion(const aCondition: string; aLimit: integer; aOffset: integer): boolean; overload; virtual;
    function    addDataPortion(aId: int64): boolean; overload; virtual;
    function    fetchMore: boolean; virtual;

    function    appendRow(aId: int64 = NEW_KEY_ID): integer; virtual;
    function    appendRowToCache: integer; virtual;

    procedure   deleteRow(aRow: integer); virtual;
    procedure   deleteRowFromCache(aRow: integer); virtual;

    function    getRowKey(aRow: integer): int64; virtual;
    function    getKeyCondition(aId: int64): string;

    function    getFields: cTableFields;

    function    getRowCount: integer;
    function    getSelectedRowCount: integer;

    function    createActiveRecord: cAbstractTableRow; virtual; abstract;
    function    createIteratorRow: cAbstractTableRow; virtual; abstract;

    procedure   copyFrom(aTableModel: cAbstractTableModel); virtual; abstract;

    constructor create; virtual;
    destructor  destroy; override;
  public
    const

    HEADER_ROW_INDEX = -1;
  published
    property    onFieldDataSetting: tAbstractTableModelFieldDataSettingEvent read fOnFieldDataSetting write fOnFieldDataSetting;
    property    onFieldDataGetting: tAbstractTableModelFieldDataGettingEvent read fOnFieldDataGetting write fOnFieldDataGetting;

    property    onRowReloaded: tAbstractTableModelRowReloadedEvent read fOnRowReloaded write fOnRowReloaded;
    property    onRowReloading: tAbstractTableModelRowReloadingEvent read fOnRowReloading write fOnRowReloading;
    property    onRowAppending: tAbstractTableModelRowAppendingEvent read fOnRowAppending write fOnRowAppending;
    property    onRowAppended: tAbstractTableModelRowAppendedEvent read fOnRowAppended write fOnRowAppended;
    property    onRowDeleted: tAbstractTableModelRowDeletedEvent read fOnRowDeleted write fOnRowDeleted;
    property    onRowDeleting: tAbstractTableModelRowDeletingEvent read fOnRowDeleting write fOnRowDeleting;

    property    onBeginRowsAppending: tAbstractTableModelBeginRowsAppending read fOnBeginRowsAppending write fOnBeginRowsAppending;
    property    onEndRowsAppending: tAbstractTableModelEndRowsAppending read fOnEndRowsAppending write fOnEndRowsAppending;

    property    onBeginRowsDeleting: tAbstractTableModelBeginRowsDeleting read fOnBeginRowsDeleting write fOnBeginRowsDeleting;
    property    onEndRowsDeleting: tAbstractTableModelEndRowsDeleting read fOnEndRowsDeleting write fOnEndRowsDeleting;

    property    onBeginRowsReloading: tAbstractTableModelBeginRowsReloading read fOnBeginRowsReloading write fOnBeginRowsReloading;
    property    onEndRowsReloading: tAbstractTableModelEndRowsReloading read fOnEndRowsReloading write fOnEndRowsReloading;

    property    onDataChanged: tAbstractTableModelDataChangedEvent read fOnDataChanged write fOnDataChanged;
    property    onDataFetched: tAbstractTableModelDataFetchedEvent read fOnDataFetched write fOnDataFetched;
    property    onDataFetching: tAbstractTableModelDataFetchingEvent read fOnDataFetching write fOnDataFetching;
    property    onConditionSetting: tAbstractTableModelConditionSettingEvent read fOnConditionSetting write fOnConditionSetting;
    property    onConditionSetted: tAbstractTableModelConditionSettedEvent read fOnConditionSetted write fOnConditionSetted;

    property    onRowCountChanged: tAbstractTableModelRowCountChangedEvent read fOnRowCountChanged write fOnRowCountChanged;
  end;

implementation
uses
  clsAbstractSQLCommandsBuilder,
  clsMulticastEvents;


{ cTableFields }

procedure cTableFields.add(aField: cTableField);
begin
  fList.add(aField);
  connect(aField, 'onSortDirectionChanged', self, 'sortDirectionChanged');

  if assigned(fOnFieldAdded) then begin
    fOnFieldAdded(self, aField);
  end;
end;

constructor cTableFields.create(aOwnFields: boolean);
begin
  inherited create;
  fList:= cList.create;

  fOwnFields:= aOwnFields;

  fKeyIndex:= -1;
  fSelectorIndex:= -1;
end;

procedure cTableFields.delete(aIndex: integer);
begin
  if assigned(fOnFieldRemoving) then begin
    fOnFieldRemoving(self, items[aIndex]);
  end;

  disconnect(items[aIndex], 'onSortDirectionChanged', self, 'sortDirectionChanged');
  if (fOwnFields) then begin
    fList.freeInternalObject(aIndex);
  end;
  fList.delete(aIndex);
  if (fSelectorIndex = aIndex) then begin
    fSelectorIndex:= -1;
  end;

  rebuildFields;
end;

destructor cTableFields.destroy;
begin
  if assigned(fList) then begin
    clear;
    freeAndNil(fList);
  end;

  inherited;
end;

function cTableFields.getCount: integer;
begin
  result:= fList.count;
end;

procedure cTableFields.clear;
var
  i: integer;
begin
  for i:= 0 to count - 1 do begin
    disconnect(items[i]);
  end;

  if (fOwnFields) then begin
    fList.freeInternalObjects;
  end;

  fList.clear;
end;

procedure cTableFields.clearSort;
var
  i: integer;
  curField: cTableField;
begin
  for i := 0 to count - 1 do begin
    curField:= items[i];

    curField.sortDirection:= sdNone;
  end;
end;

function cTableFields.collectEditableFieldsProc(aSender: cTableFields; aField: cTableField): string;
begin
  result:= '';

  if aField.isSelector then begin
    exit;
  end;

  if (aField.containsStates([fsEditable])) then begin
    result:= aField.name;
  end;
end;

function cTableFields.getEditableFields: string;
begin
  result:= collectFieldInfo(collectEditableFieldsProc);
end;

function cTableFields.collectFieldInfo(aActionProc: tTableFieldsActionProc; aConcatString: string): string;
var
  i: integer;
  curField: cTableField;

  procResult: string;
begin
  result:= '';
  for i:= 0 to count - 1 do begin
    curField:= items[i];

    if (assigned(aActionProc)) then begin
      procResult:= aActionProc(self, curField);
      if (procResult <> '') then
        result:= result + aConcatString + procResult;
    end;
  end;

  system.delete(result, 1, length(aConcatString));
end;

function cTableFields.getFieldByIndex(aIndex: integer): cTableField;
begin
  result:= fList.items[aIndex];
end;

function cTableFields.getKeyField: cTableField;
var
  foundIndex: integer;
begin
  result:= nil;
  foundIndex:= getKeyFieldIndex;
  if (foundIndex = -1) then begin
    exit;
  end;

  result:= items[foundIndex];
end;

function cTableFields.getKeyFieldIndex: integer;
begin
  result:= fKeyIndex;
end;

function cTableFields.getSelectorField: cTableField;
var
  foundIndex: integer;
begin
  result:= nil;
  foundIndex:= getSelectorFieldIndex;
  if (foundIndex = -1) then begin
    exit;
  end;

  result:= items[foundIndex];
end;

function cTableFields.getSelectorFieldIndex: integer;
begin
  result:= fSelectorIndex;
end;

function cTableFields.indexOf(aField: cTableField): integer;
begin
  result:= fList.indexOf(aField);
end;

function cTableFields.indexOfName(aName: string): integer;
var
  i: integer;
  curField: cTableField;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curField:= items[i];
    if (curField.name = aName) then begin
      result:= i;
      exit;
    end;
  end;
end;

procedure cTableFields.insert(aField: cTableField; aIndex: integer);
begin
  fList.insert(aIndex, aField);

  rebuildFields;
end;

function cTableFields.isFieldNameSelector(aFieldName: string): boolean;
var
  foundSelectorField: cTableField;
begin
  foundSelectorField:= getSelectorField;
  result:= false;

  if (assigned(foundSelectorField) and (aFieldName = foundSelectorField.name)) then begin
    result:= true;
    exit;
  end;
end;

procedure cTableFields.rebuildFields;
begin
  fKeyIndex:= searchKeyFieldIndex;
  fSelectorIndex:= searchSelectorFieldIndex;
end;

function cTableFields.searchKeyFieldIndex: integer;
var
  i: integer;
  curField: cTableField;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curField:= items[i];
    if (curField.isKey) then begin
      result:= i;
      exit;
    end;
  end;
end;

function cTableFields.searchSelectorFieldIndex: integer;
var
  i: integer;
  curField: cTableField;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curField:= items[i];
    if (curField.isSelector) then begin
      result:= i;
      exit;
    end;
  end;
end;

procedure cTableFields.setFieldTitle(aFieldName: string; aTitle: string);
var
  foundIndex: integer;
  foundField: cTableField;
begin
  foundIndex:= indexOfName(aFieldName);
  if (foundIndex = -1) then begin
    exit;
  end;


  if (foundIndex <> 0) then begin
    raise eTableFields.create(SELECTOR_SUPPORTS_ONLY_FOR_FIRST_FIELD);
  end;


  foundField:= items[foundIndex];
  foundField.title:= aTitle;
end;

procedure cTableFields.setKeyField(aFieldName: string);
var
  foundIndex: integer;
  foundField: cTableField;
begin
  foundIndex:= indexOfName(aFieldName);
  if (foundIndex = -1) then begin
    exit;
  end;

  foundField:= items[foundIndex];
  foundField.setKey(true);

  updateKeyIndex(foundIndex);
end;

procedure cTableFields.setSelectorField(aFieldName: string);
var
  foundIndex: integer;
  foundField: cTableField;
begin
  foundIndex:= indexOfName(aFieldName);
  if (foundIndex = -1) then begin
    exit;
  end;


  if (foundIndex <> 0) then begin
    raise eTableFields.create(SELECTOR_SUPPORTS_ONLY_FOR_FIRST_FIELD);
  end;


  foundField:= items[foundIndex];
  foundField.setSelector(true);
  updateSelectorIndex(foundIndex);
end;

procedure cTableFields.sortDirectionChanged(aSender: cTableField; aOldDirection: tTableFieldSortDirection);
begin
  if (assigned(fOnSortDirectionChanged)) then
    fOnSortDirectionChanged(self, aSender, aOldDirection);
end;

procedure cTableFields.updateKeyIndex(aNewIndex: integer);
var
  oldKeyIndex: integer;
begin
  if (aNewIndex = -1) then begin
    exit;
  end;

  oldKeyIndex:= getKeyFieldIndex;

  if (oldKeyIndex <> -1) then begin
    items[oldKeyIndex].setKey(false);
    fKeyIndex:= -1;
  end;
  items[aNewIndex].setKey(true);
  fKeyIndex:= aNewIndex;
end;

procedure cTableFields.updateSelectorIndex(aNewIndex: integer);
var
  oldSelectorIndex: integer;
begin
  if (aNewIndex = -1) then begin
    exit;
  end;

  oldSelectorIndex:= getSelectorFieldIndex;

  if (oldSelectorIndex <> -1) then begin
    items[oldSelectorIndex].setSelector(false);

    fSelectorIndex:= -1;
  end;

  items[aNewIndex].setSelector(true);
  fSelectorIndex:= aNewIndex;
end;

{ cTableField }

constructor cTableField.create(aName, aTitle: string; aReadOnly: boolean; aSortDirection: tTableFieldSortDirection);
begin
  inherited create;

  fName:= aName;
  fTitle:= aTitle;
  fReadOnly:= aReadOnly;
  fIsKey:= false;
  fIsSelector:= false;

  fSortDirection:= aSortDirection;
end;

destructor cTableField.destroy;
begin
  inherited;
end;

function cTableField.getStates: tTableFieldStates;
begin
  result:= [];

  if (fReadOnly) then
    result:= result + [fsReadOnly]
  else
    result:= result + [fsEditable];

  if (fSortDirection <> sdNone) then
    result:= result + [fsSortable];

end;

procedure cTableField.setData(aValue: variant);
begin
  fData := aValue;
end;

procedure cTableField.setKey(aValue: boolean);
begin
  fIsKey:= aValue;
end;

procedure cTableField.setSelector(aValue: boolean);
begin
  fIsSelector:= aValue;
end;

procedure cTableField.setSortDirection(aValue: tTableFieldSortDirection);
var
  aOldValue: tTableFieldSortDirection;
begin
  aOldValue:= fSortDirection;

  fSortDirection := aValue;

  if (assigned(fOnSortDirectionChanged)) then begin
    fOnSortDirectionChanged(self, aOldValue);
  end;
end;

function cTableField.containsStates(aStates: tTableFieldStates): boolean;
begin
  result:= (aStates * getStates) <> [];
end;


{ cTableModel }

function cAbstractTableModel.addField(aName, aTitle: string; aReadOnly: boolean; aSortDirection: tTableFieldSortDirection): cTableField;
var
  foundIndex: integer;
begin
  result:= nil;
  foundIndex:= fFields.indexOfName(aName);

  if (foundIndex <> -1) then begin
    raise eTableFields.createFmt(FIELD_NAME_ALREADY_EXISTS_FORMAT, [aName]);
  end;


  result:= cTableField.create(aName, aTitle, aReadOnly, aSortDirection);
  fFields.add(result);
end;

function cAbstractTableModel.appendedKeyExists(aValue: int64): boolean;
begin
  result:= fAppendedKeys.containsKey(aValue);
end;

function cAbstractTableModel.appendRow(aId: int64): integer;
begin
  result:= 0;
  clearIteratorRowIndex;

  if assigned(fOnRowAppending) then begin
    fOnRowAppending(self, aId);
  end;

end;

procedure cAbstractTableModel.addAppendedKey(aValue: int64);
begin
  fAppendedKeys.add(aValue, true);
end;

function cAbstractTableModel.addDataPortion(aId: int64): boolean;
begin
  result:= addDataPortion(getKeyCondition(aId), NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);
end;

function cAbstractTableModel.appendRowToCache: integer;
var
  appendedRow: integer;
begin
  clearIteratorRowIndex;
  updateRowCount;

  appendedRow:= getLastAppendedRow;

  if assigned(fOnRowAppended) then begin
    fOnRowAppended(self, appendedRow);
  end;
end;

procedure cAbstractTableModel.attachIteratorRow(aIteratorRow: cAbstractTableRow);
begin
  if (fNativeIteratorRow = aIteratorRow) then exit;

  seNativetIteratorRow(aIteratorRow);
end;

constructor cAbstractTableModel.create;
begin
  inherited create;

  clearIteratorRowIndex;

  fLastAppendedRow          := -1;

  fFetchCommand             := '';
  fConditionSettedHandled   := false;

  fFields                   := cTableFields.create;
  fRowCount                 := 0;
  fNativeIteratorRow        := nil;

  fStates                   := [];

  fLimit                    := NO_CONSIDER_LIMIT;
  fOffset                   := NO_CONSIDER_OFFSET;
  fCondition                := '1=-1';

  fOldLimit                 := fLimit;
  fOldOffset                := fOffset;
  fOldCondition             := fCondition;

  fAppendedKeys             := tDictionary<int64, boolean>.create;
end;

procedure cAbstractTableModel.createDynamicData(const aCondition: string; aLimit: integer; aOffset: integer);
begin

end;

procedure cAbstractTableModel.beginDataChanging;
begin
  include(fStates, tmsDataChanging);
end;

procedure cAbstractTableModel.endDataFetching;
begin
  try
    dataFetched;
  finally
    exclude(fStates, tmsDataFetching);
  end;
end;

procedure cAbstractTableModel.endModelChanging;
begin
  exclude(fStates, tmsModelChanging);

  reload;
end;

procedure cAbstractTableModel.endRowsAppending;
begin
  exclude(fStates, tmsRowsAppending);

  if assigned(fOnEndRowsAppending) then begin
    fOnEndRowsAppending(self);
  end;
end;

procedure cAbstractTableModel.endRowsDeleting;
begin
  exclude(fStates, tmsRowsDeleting);

  if assigned(fOnEndRowsDeleting) then begin
    fOnEndRowsDeleting(self);
  end;
end;

procedure cAbstractTableModel.endRowsReloading;
begin
  exclude(fStates, tmsRowsReloading);

  if assigned(fOnEndRowsReloading) then begin
    fOnEndRowsReloading(self);
  end;
end;

procedure cAbstractTableModel.beginDataFetching;
var
  newLimit: integer;
  newOffset: integer;
  newFetchCommand: string;
begin
  include(fStates, tmsDataFetching);

  newLimit:= getLimit;
  newOffset:= getOffset;
  newFetchCommand:= getFetchCommand;

  dataFetching(newFetchCommand, newLimit, newOffset);

  setFetchCommand(newFetchCommand);
  setLimit(newLimit);
  setOffset(newOffset);
end;

procedure cAbstractTableModel.dataFetching(var aCommand: string; var aLimit: integer; var aOffset: integer);
begin
  if assigned(fOnDataFetching) then begin
    fOnDataFetching(self, aCommand, aLimit, aOffset);
  end;
end;

procedure cAbstractTableModel.beginModelChanging;
begin
  include(fStates, tmsModelChanging);
end;

procedure cAbstractTableModel.beginRowsAppending;
begin
  include(fStates, tmsRowsAppending);

  if assigned(fOnBeginRowsAppending) then begin
    fOnBeginRowsAppending(self);
  end;
end;

procedure cAbstractTableModel.beginRowsDeleting;
begin
  include(fStates, tmsRowsDeleting);

  if assigned(fOnBeginRowsDeleting) then begin
    fOnBeginRowsDeleting(self);
  end;
end;

procedure cAbstractTableModel.beginRowsReloading;
begin
  include(fStates, tmsRowsReloading);

  if assigned(fOnBeginRowsReloading) then begin
    fOnBeginRowsReloading(self);
  end;
end;

procedure cAbstractTableModel.dataFetched;
begin
  if assigned(fOnDataFetched) then begin
    fOnDataFetched(self, getFetchCommand, getCondition, getLimit, getOffset);
  end;
end;

procedure cAbstractTableModel.deleteDynamicData(aId: int64);
begin

end;

procedure cAbstractTableModel.deleteRow(aRow: integer);
begin
  clearIteratorRowIndex;
  deleteDynamicData(getRowKey(aRow));
end;

procedure cAbstractTableModel.deleteRowFromCache(aRow: integer);
begin
  clearIteratorRowIndex;

  updateRowCount;

  rowDeleted(aRow);
end;

function cAbstractTableModel.getKeyCondition(aId: int64): string;
begin
  result:= format('%s.%s = %d', [getTableName, getFields.items[getFields.getKeyFieldIndex].name, aId]);
end;

destructor cAbstractTableModel.destroy;
begin
  if assigned(fNativeIteratorRow) then begin
    freeAndNil(fNativeIteratorRow);
  end;

  if assigned(fFields) then begin
    freeAndNil(fFields);
  end;

  if assigned(fAppendedKeys) then begin
    freeAndNil(fAppendedKeys);
  end;


  inherited;
end;

procedure cAbstractTableModel.detachIteratorRow(aIteratorRow: cAbstractTableRow);
begin
  if (aIteratorRow = fNativeIteratorRow) then begin
    fNativeIteratorRow:= nil;
  end;
end;

procedure cAbstractTableModel.enableSelector(aValue: boolean);
const
  DEFAULT_SELECTOR_INDEX = 0;
var
  foundIndex: integer;
begin
  foundIndex:= getFields.indexOfName(DEFAULT_SELECTOR_FIELD_NAME);


  if (aValue) then begin
    if (foundIndex = -1) then begin
      insertField(DEFAULT_SELECTOR_INDEX, DEFAULT_SELECTOR_FIELD_NAME, ' ', false);
    end;

    setSelectorField(DEFAULT_SELECTOR_FIELD_NAME);
  end else begin

    if (foundIndex <> -1) then begin
      getFields.delete(foundIndex);
    end;

  end;
end;

procedure cAbstractTableModel.endDataChanging(aType: tAbstractTableModelDataChangedType);
begin
  try
    if assigned(fOnDataChanged) then begin
      fOnDataChanged(self, aType);
    end;
  finally
    exclude(fStates, tmsDataChanging);
  end;
end;

function cAbstractTableModel.fetch(const aCondition: string; aLimit, aOffset: integer): integer;
begin
  result:= 0;

  clearIteratorRowIndex;

  if (tmsConditionSetting in fStates) then exit;

  fFetchMoreLimit:= aLimit;
  fFetchMoreOffset:= aOffset;

  fOldCondition:= aCondition;
  fOldLimit:= aLimit;
  fOldOffset:= aOffset;
  createDynamicData(aCondition, aLimit, aOffset);

  setCondition(aCondition);
  setLimit(aLimit);
  setOffset(aOffset);
end;

function cAbstractTableModel.getFetchCommand: string;
begin
  result:= fFetchCommand;
end;

function cAbstractTableModel.getFieldNames: string;
begin
  result:= fFields.getEditableFields;
end;

function cAbstractTableModel.getFields: cTableFields;
begin
  result:= fFields;
end;

function cAbstractTableModel.getIterator: cTableCursor;
begin
  result:= cTableCursor.create(self);

  if not assigned(fNativeIteratorRow) then begin
    raise eDatabaseError.create(ITERATOR_ROW_NOT_ASSIGNED);
  end;
end;

function cAbstractTableModel.getNativeIteratorRow: cAbstractTableRow;
begin
  result:= fNativeIteratorRow;
end;

function cAbstractTableModel.getOffset: integer;
begin
  result:= fOffset;
end;

function cAbstractTableModel.getIteratorRow(aRowIndex: integer): cAbstractTableRow;
begin
  if (fLastIteratorRowIndex <> aRowIndex) then begin
    loadRowData(aRowIndex, fNativeIteratorRow);
  end;

  setLastIteratorRowIndex(aRowIndex);
  result:= fNativeIteratorRow;
end;

function cAbstractTableModel.getLastAppendedRow: integer;
begin
  result:= fLastAppendedRow;
end;

function cAbstractTableModel.getLimit: integer;
begin
  result:= fLimit;
end;

function cAbstractTableModel.getRowCount: integer;
begin
  result:= fRowCount;
end;

function cAbstractTableModel.getRelation(aFieldIndex: integer): cRelation;
begin
  result:= nil;
end;

function cAbstractTableModel.getRelation(aFieldName: string): cRelation;
begin
  result:= getRelation(getFields.indexOfName(aFieldName));
end;

function cAbstractTableModel.getRowClass: tTableRowClass;
begin
  result:= fRowClass;
end;

function cAbstractTableModel.getRowKey(aRow: integer): int64;
begin
  result:= NOT_VALID_KEY_ID;
end;

function cAbstractTableModel.getRowsDataForCondition(aAddProc: tAbstractTableModelSelectedRowsAddProc; aDelimiter: string; aQuote: string; aConditionCheckProc: tAbstractTableModelSelectedRowsConditionCheckProc): string;
var
  i: integer;
  rowCount: integer;
begin
  result:= '';

  rowCount:= getRowCount;
  for i := 0 to rowCount - 1 do begin
    if not aConditionCheckProc(i) then begin
      continue;
    end;

    result:= result + aDelimiter + aQuote + aAddProc(i) + aQuote;
  end;

  system.delete(result, 1, length(aDelimiter));

end;

function cAbstractTableModel.getRowsIds(aDelimiter: string): string;
begin
  result:= getRowsDataForCondition(getRowsIdsAddProc, aDelimiter, '', getRowsCheckProc);
end;

function cAbstractTableModel.getRowsIdsAddProc(aRow: integer): string;
var
  keyFieldIndex: integer;
begin
  result:= '';
  keyFieldIndex:= getFields.getKeyFieldIndex;

  if (keyFieldIndex = -1) then begin
    exit;
  end;

  result:= getFieldData(keyFieldIndex, aRow);
end;

function cAbstractTableModel.getRowsCheckProc(aRow: integer): boolean;
begin
  result:= true;
end;

function cAbstractTableModel.getSelectedRowsIds(aDelimiter: string): string;
begin
  result:= getRowsDataForCondition(getSelectedRowsIdsAddProc, aDelimiter, '', getSelectedRowsCheckProc);
end;

function cAbstractTableModel.getSelectedRowsIndexes(aDelimiter: string): string;
begin
  result:= getRowsDataForCondition(getSelectedRowsIndexesAddProc, aDelimiter, '', getSelectedRowsCheckProc);
end;

function cAbstractTableModel.getSelectedRowsIndexesAddProc(aRow: integer): string;
begin
  result:= intToStr(aRow);
end;

function cAbstractTableModel.getSelectedRowsIdsAddProc(aRow: integer): string;
var
  keyFieldIndex: integer;
begin
  result:= '';
  keyFieldIndex:= getFields.getKeyFieldIndex;

  if (keyFieldIndex = -1) then begin
    exit;
  end;

  result:= getFieldData(keyFieldIndex, aRow);
end;

function cAbstractTableModel.getSelectedRowCount: integer;
var
  i: integer;

  selectorIndex: integer;
  selected: boolean;
begin
  result:= 0;
  selectorIndex:= getFields.getSelectorFieldIndex;

  if (selectorIndex = -1) then exit;

  for i := 0 to getRowCount - 1 do begin
    selected:= getFieldData(selectorIndex, i);
    if selected then begin
      inc(result);
    end;
  end;
end;

function cAbstractTableModel.getSelectedRowsCheckProc(aRow: integer): boolean;
var
  selectorFieldIndex: integer;
begin
  result:= false;
  selectorFieldIndex:= getFields.getSelectorFieldIndex;

  if (selectorFieldIndex = -1) then begin
    exit;
  end;

  result:= getFieldData(selectorFieldIndex, aRow);
end;

procedure cAbstractTableModel.insertDynamicData(aId: int64);
begin

end;

function cAbstractTableModel.insertField(aIndex: integer; aName, aTitle: string; aReadOnly: boolean; aSortDirection: tTableFieldSortDirection): cTableField;
var
  foundIndex: integer;
begin
  result:= nil;
  foundIndex:= fFields.indexOfName(aName);

  if (foundIndex <> -1) then begin
    raise eTableFields.createFmt(FIELD_NAME_ALREADY_EXISTS_FORMAT, [aName]);
  end;


  result:= cTableField.create(aName, aTitle, aReadOnly, aSortDirection);
  fFields.insert(result, aIndex);
end;

procedure cAbstractTableModel.internalDeleteRowsForFilter(aFilterProc: tAbstractTableModelRowFilterProc; aDeleteOnlyFromCache: boolean);
var
  i: integer;
  curRow: integer;
  rowCount: integer;

  rowForDelete: integer;

  deletingRowsIndexes: cIntegerList;
begin
  rowCount:= getRowCount;

  beginRowsDeleting;
  try
    if (rowCount = 0) then begin
      exit;
    end;

    deletingRowsIndexes:= cIntegerList.create;
    try

      for i:=0 to rowCount - 1 do begin
        if not aFilterProc(self, i) then begin
          continue;
        end;

        deletingRowsIndexes.add(i);
      end;

      if (deletingRowsIndexes.count = 0) then begin
        exit;
      end;

      deletingRowsIndexes.sort(clsLists.sdAsc);

      for i:=0 to deletingRowsIndexes.count - 1 do begin
        curRow:= deletingRowsIndexes.items[i];
        rowForDelete:= curRow - i;


        if (aDeleteOnlyFromCache) then begin
          deleteRowFromCache(rowForDelete);
        end else begin
          deleteRow(rowForDelete);
        end;

      end;


    finally
      freeAndNil(deletingRowsIndexes);
    end;
  finally
    endRowsDeleting;
  end;
end;

procedure cAbstractTableModel.deleteRowsForFilter(aFilterProc: tAbstractTableModelRowFilterProc);
begin
  internalDeleteRowsForFilter(aFilterProc, false);
end;

procedure cAbstractTableModel.deleteRowsFromCacheForFilter(aFilterProc: tAbstractTableModelRowFilterProc);
begin
  internalDeleteRowsForFilter(aFilterProc, true);
end;

function cAbstractTableModel.deleteSelectedRowsFilterProc(aModel: cAbstractTableModel; aRow: integer): boolean;
begin
  result:= getFieldData(getFields.getSelectorFieldIndex, aRow);
end;

procedure cAbstractTableModel.deleteSelectedRows;
begin
  deleteRowsForFilter(deleteSelectedRowsFilterProc);
end;

procedure cAbstractTableModel.deleteSelectedRowsFromCache;
begin
  deleteRowsFromCacheForFilter(deleteSelectedRowsFilterProc);
end;

function cAbstractTableModel.getStates: tTableModelStates;
begin
  result:= fStates;
end;

function cAbstractTableModel.getTableClass: tTableModelClass;
begin
  result:= tTableModelClass(self.classType);
end;

function cAbstractTableModel.getTableName: string;
begin
  result:= fTableName;
end;

procedure cAbstractTableModel.setTableName(aTableName: string);
begin
  fTableName:= aTableName;
end;

procedure cAbstractTableModel.updateDynamicData(aId: int64);
begin

end;

procedure cAbstractTableModel.updateRowCount;
begin
  if assigned(fOnRowCountChanged) then begin
    fOnRowCountChanged(self);
  end;
end;

function cAbstractTableModel.isIdEditable: boolean;
begin
  result:= fIdEditable;
end;

function cAbstractTableModel.isSelectionEmpty: boolean;
begin
  result:= getSelectedRowsIds = '';
end;

function cAbstractTableModel.isSelectorEnabled: boolean;
begin
  result:= getFields.getSelectorFieldIndex <> -1;
end;

function cAbstractTableModel.loadRowData(aRowIndex: integer): boolean;
begin
  result:= loadRowData(aRowIndex, nativeIteratorRow);
end;

function cAbstractTableModel.locate(aLocateCompareProc: tAbstractTableModelLocateCompareProc; aValue: variant; aCol, aStartRow: integer; aSearchDirection: tModelSearchDirection; aSearchPosition: tModelSearchPosition): integer;
var
  startModelRow: integer;
  curModelRow: integer;

  rowCount: integer;
begin
  result:= -1;

  rowCount:= getRowCount;

  case aSearchPosition of

    spFirst:
    begin
      startModelRow:= 0;
    end;

    spCurrent:
    begin
      startModelRow:= aStartRow;
    end;

    spNextFromCurrent:
    begin
      startModelRow:= min(rowCount - 1, aStartRow + 1);
    end;

    spPrevFromCurrent:
    begin
      startModelRow:= max(0, aStartRow - 1);
    end;

    spLast:
    begin
      startModelRow:= rowCount - 1;
    end;
  end;

  curModelRow:= startModelRow;
  while (curModelRow < rowCount) or (curModelRow < 0) do begin
    if (aLocateCompareProc(aCol, curModelRow, aValue)) then begin
      result:= curModelRow;

      exit;
    end;


    if aSearchDirection = sdForward then begin
      inc(curModelRow);
    end else begin
      dec(curModelRow);
    end;

  end;

end;

function cAbstractTableModel.locate(aValue: variant; aCol, aStartRow: integer; aSearchDirection: tModelSearchDirection; aSearchPosition: tModelSearchPosition): integer;
begin
  result:= locate(locateByValueEqualProc, aValue, aCol, aStartRow, aSearchDirection, aSearchPosition);
end;

function cAbstractTableModel.locateByValueEqualProc(aCol, aRow: integer; aValue: variant): boolean;
begin
  result:= (getFieldData(aCol, aRow) = aValue);
end;

function cAbstractTableModel.locateByValuePartProc(aCol, aRow: integer; aValue: variant): boolean;
begin
  result:= containsText(varToStr(getFieldData(aCol, aRow)), varToStr(aValue));
end;

function cAbstractTableModel.reload(aRow: integer): integer;
var
  reloadingKey: int64;
begin
  result:= 0;

  clearIteratorRowIndex;

  reloadingKey:= getRowKey(aRow);
  updateDynamicData(reloadingKey);
  rowReloading(aRow, reloadingKey);
end;

function cAbstractTableModel.reload(aRows: string): integer;
var
  rowList: cIntegerList;
begin
  result:= 0;

  rowList:= cIntegerList.create;
  try
    rowList.addItemsByDelimitedString(aRows);

    result:= reload(rowList);
  finally
    freeAndNil(rowList);
  end;
end;

function cAbstractTableModel.rawFetch(const aCommand: string): integer;
begin
  clearIteratorRowIndex;
  clearAppendedKeys;
end;

function cAbstractTableModel.reload(aRowsList: cIntegerList): integer;
var
  i: integer;
begin
  result:= 0;

  beginRowsReloading;
  try
    for i := 0 to aRowsList.count - 1 do begin
      inc(result, reload(aRowsList.items[i]));
    end;
  finally
    endRowsReloading;
  end;
end;

procedure cAbstractTableModel.rowDeleted(aRow: integer);
begin
  if assigned(fOnRowDeleted) then begin
    fOnRowDeleted(self, aRow);
  end;
end;

procedure cAbstractTableModel.rowDeleting(aRow: integer);
begin
  if assigned(fOnRowDeleting) then begin
    fOnRowDeleting(self, aRow);
  end;
end;

procedure cAbstractTableModel.rowReloaded(aRow: integer);
begin
  if assigned(fOnRowReloaded) then begin
    fOnRowReloaded(self, aRow);
  end;
end;

procedure cAbstractTableModel.rowReloading(aRow: integer; aId: int64);
begin
  if assigned(fOnRowReloading) then begin
    fOnRowReloading(self, aRow, aId);
  end;
end;

function cAbstractTableModel.reload: integer;
begin
  result:= fetch(fOldCondition, fOldLimit, fOldOffset);
end;

procedure cAbstractTableModel.seNativetIteratorRow(aIteratorRow: cAbstractTableRow);
begin
  if assigned(fNativeIteratorRow) then begin
    freeAndNil(fNativeIteratorRow);
  end;

  fNativeIteratorRow:= aIteratorRow;
end;

procedure cAbstractTableModel.setRowCount(aCount: integer);
begin
  fRowCount:= aCount;
end;


procedure cAbstractTableModel.setRowClass(aRowClass: tTableRowClass);
begin
  fRowClass:= aRowClass;

  seNativetIteratorRow(fRowClass.create(self));
end;

procedure cAbstractTableModel.setRowSelected(aRow: integer; aValue: boolean);
var
  selectorFieldIndex: integer;
begin
  selectorFieldIndex:= getFields.getSelectorFieldIndex;

  if (selectorFieldIndex = -1) then begin
    exit;
  end;

  setFieldData(selectorFieldIndex, aRow, aValue);
end;

procedure cAbstractTableModel.setRowsSelected(aValue: boolean);
var
  i: integer;
  rowCount: integer;
begin
  rowCount:= getRowCount;
  for i := 0 to rowCount - 1 do begin
    setRowSelected(i, aValue);
  end;
end;

procedure cAbstractTableModel.setSelectedRowsIds(aIds: string; aValue: boolean);
var
  i: integer;
  curId: int64;
  idsList: cIntegerList;
  selectorIndex: integer;
  idIndex: integer;

  foundRowIndex: integer;

begin
  idsList:= cIntegerList.create;
  try
    idsList.addItemsByDelimitedString(aIds);

    selectorIndex:= getFields.getSelectorFieldIndex;
    idIndex:= getFields.getKeyFieldIndex;

    for i:= 0 to idsList.count - 1 do begin
      curId:= idsList.items[i];

      foundRowIndex:= locate(locateByValueEqualProc, curId, idIndex, FIRST_ROW);
      if (foundRowIndex = -1) then continue;

      setFieldData(selectorIndex, foundRowIndex, aValue);
    end;

  finally
    freeAndNil(idsList);
  end;
end;

procedure cAbstractTableModel.setSelectorField(aFieldName: string);
begin
  getFields.setSelectorField(aFieldName);
end;

procedure cAbstractTableModel.setFetchCommand(aCommand: string);
begin
  fFetchCommand:= aCommand;
end;

procedure cAbstractTableModel.setFieldData(aCol, aRow: integer; const aValue: variant);
var
  key: int64;
begin
  clearIteratorRowIndex;

  if (aCol = getFields.getKeyFieldIndex) then begin
    key:= aValue;
  end else begin
    key:= getRowKey(aRow);
  end;


  updateDynamicData(key);
end;

procedure cAbstractTableModel.setFieldData(aName: string; aRow: integer; const aValue: variant);
begin
  setFieldData(getFields.indexOfName(aName), aRow, aValue);
end;

procedure cAbstractTableModel.setIdEditable(aValue: boolean);
begin
  fIdEditable:= aValue;
  if fIdEditable then begin
    getFields.getKeyField.readOnly:= false;
  end else begin
    getFields.getKeyField.readOnly:= true;
  end;
end;

procedure cAbstractTableModel.setKeyField(aFieldName: string);
begin
  getFields.setKeyField(aFieldName);
end;

procedure cAbstractTableModel.setCacheFieldData(aName: string; aRow: integer; const aValue: variant);
begin
  setCacheFieldData(getFields.indexOfName(aName), aRow, aValue);
end;

procedure cAbstractTableModel.setLastAppededRow(aRow: integer);
begin
  fLastAppendedRow:= aRow;
end;

procedure cAbstractTableModel.setLastIteratorRowIndex(aRow: integer);
begin
  fLastIteratorRowIndex:= aRow;
end;

procedure cAbstractTableModel.setLimit(aLimit: integer);
begin
  fLimit:= aLimit;
end;

procedure cAbstractTableModel.setOffset(aOffset: integer);
begin
  fOffset:= aOffset;
end;

procedure cAbstractTableModel.setCacheFieldData(aCol, aRow: integer; const aValue: variant);
begin
  clearIteratorRowIndex;
end;

procedure cAbstractTableModel.setCondition(const aCondition: string);
var
  oldCondition: string;
  newCondition: string;
begin
  oldCondition:= getCondition;
  newCondition:= aCondition;

  conditionSetting(newCondition);

  fCondition:= newCondition;

  if assigned(fOnConditionSetted) and ((not fConditionSettedHandled) or (newCondition <> oldCondition)) then begin
    fConditionSettedHandled:= true;
    fOnConditionSetted(self, newCondition);
  end;
end;

procedure cAbstractTableModel.clearAppendedKeys;
begin
  fAppendedKeys.clear;
end;

procedure cAbstractTableModel.clearIteratorRowIndex;
begin
  setLastIteratorRowIndex(-1);
end;

function cAbstractTableModel.colCanEdit(aCol: integer): boolean;
begin
  if (aCol = getFields.getKeyFieldIndex) then begin
    result:= isIdEditable;
    exit;
  end else begin
    result:= not getFields.items[aCol].readOnly;
    exit;
  end;
end;

procedure cAbstractTableModel.conditionSetting(var aCondition: string);
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

function cAbstractTableModel.getCondition: string;
begin
  result:= fCondition;
end;


{ cAbstractTableRow }

constructor cAbstractTableRow.create(aTable: cAbstractTableModel);
begin
  inherited create;

  fOwner:= aTable;
  fOwnerCreatedManually:= false;
  fRowType:= rtIterator;
  initialize;
end;

constructor cAbstractTableRow.createActiveRecord(aTable: cAbstractTableModel; aTableClass: tTableModelClass);
begin
  inherited create;

  fRowType:= rtActiveRecord;
  fOwner:= cAbstractTableModel(aTableClass.create);
  fOwnerCreatedManually:= true;
  fOwner.copyFrom(aTable);

  initialize;

  fOwner.attachIteratorRow(self);
end;

constructor cAbstractTableRow.createActiveRecord(aTableClass: tTableModelClass);
begin
  inherited create;

  fRowType:= rtActiveRecord;
  fOwner:= aTableClass.create;
  fOwnerCreatedManually:= true;

  initialize;

  fOwner.attachIteratorRow(self);
end;

destructor cAbstractTableRow.destroy;
begin
  if assigned(fChangedFields) then begin
    freeAndNil(fChangedFields);
  end;


  if ((fRowType = rtActiveRecord) and (assigned(fOwner))) then begin
    fOwner.detachIteratorRow(self);
    if (fOwnerCreatedManually) then begin
      freeAndNil(fOwner);
    end;
  end;

  inherited;
end;

function cAbstractTableRow.fetch(const aCondition: string): integer;
const
  FIRST_ROW_INDEX = 0;
begin
  result:= 0;

  if (fRowType = rtIterator) then begin
    raise eDatabaseError.create(OPERATION_NOT_PERMITED);
  end;

  result:= fOwner.fetch(aCondition, NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);

  fOwner.loadRowData(FIRST_ROW_INDEX);

  flushUpdates;
end;

function cAbstractTableRow.fetch(aId: int64): integer;
const
  FIRST_ROW_INDEX = 0;
begin
  result:= 0;

  if (fRowType = rtIterator) then begin
    raise eDatabaseError.create(OPERATION_NOT_PERMITED);
  end;

  result:= fOwner.fetch(aId);
  fOwner.loadRowData(FIRST_ROW_INDEX);

  flushUpdates;
end;

procedure cAbstractTableRow.flushUpdates;
begin
  fChangedFields.clear;
end;

function cAbstractTableRow.getFieldData(aFieldName: string): variant;
begin
  result:= getPropertyData(aFieldName).value;
end;

function cAbstractTableRow.getOwner: cAbstractTableModel;
begin
  result:= fOwner;
end;

function cAbstractTableRow.getRowType: tRowType;
begin
  result:= fRowType;
end;

procedure cAbstractTableRow.initialize;
begin
  fId:= -1;
  fSelected:= false;

  fChangedFields:= tDictionary<string, boolean>.create;
end;

function cAbstractTableRow.insert(aId: int64): int64;
begin
  if (fRowType <> rtActiveRecord) then begin
    raise eDatabaseError.create(OPERATION_NOT_PERMITED);
  end;

  result:= fOwner.insert(self, aId);
  id:= result;
end;

procedure cAbstractTableRow.setPropertyData(aName: string; const aValue: variant);
begin
  inherited setPropertyData(aName, aValue);

  if not fChangedFields.containsKey(aName) then begin
    fChangedFields.add(aName, true);
  end;
end;

function cAbstractTableRow.update(aId: int64): integer;
  function getUpdatingFieldNames: string;
  var
    curPair: tPair<string, boolean>;
  begin
    result:= '';

    for curPair in fChangedFields do begin
      if (lowerCase(curPair.key) = lowerCase('owner')) or (lowerCase(curPair.key) = lowerCase('rowType')) then continue;

      result:= result + ',' + curPair.key;
    end;

    system.delete(result, 1, 1);
  end;
begin
  if (fRowType <> rtActiveRecord) then begin
    raise eDatabaseError.create(OPERATION_NOT_PERMITED);
  end;

  result:= fOwner.update(self, aId, getUpdatingFieldNames);

  flushUpdates;
end;

constructor cAbstractTableRow.createActiveRecord(aTable: cAbstractTableModel);
begin
  inherited create;

  fRowType:= rtActiveRecord;
  fOwner:= aTable.getTableClass.create;
  fOwnerCreatedManually:= true;

  initialize;

  fOwner.attachIteratorRow(self);
end;

function cAbstractTableRow.delete: integer;
begin
  if (fRowType <> rtActiveRecord) then begin
    raise eDatabaseError.create(OPERATION_NOT_PERMITED);
  end;

  result:= fOwner.delete(self);
end;


{ cTableCursor }

constructor cTableCursor.create(aTable: cAbstractTableModel);
begin
  inherited create;
  fTable        := aTable;
  fRowIndex     := -1;
end;

destructor cTableCursor.destroy;
begin

  inherited;
end;

function cTableCursor.getCurrent: cAbstractTableRow;
begin
  result:= nil;

  if (fRowIndex = -1) then begin
    raise eDatabaseError.create(MOVE_NEXT_NOT_CALLED);
  end;

  result:= fTable.getIteratorRow(fRowIndex);
end;

function cTableCursor.getRowsFetched: integer;
begin
  result:= fRowIndex + 1;
end;

function cTableCursor.moveNext: boolean;
begin
  inc(fRowIndex);

  result := not (fTable.getRowCount = fRowIndex);

  if (not result) then begin
    dec(fRowIndex);
  end;
end;

function cAbstractTableModel.fetch(aLimit, aOffset: integer): integer;
begin
  result:= fetch(getCondition, aLimit, aOffset);
end;

function cAbstractTableModel.fetchMore: boolean;
begin
  result:= false;

  if (fLimit = NO_CONSIDER_LIMIT) or (fOffset = NO_CONSIDER_OFFSET) then exit;

  inc(fFetchMoreOffset, fFetchMoreLimit);

  result:= addDataPortion(getCondition, fFetchMoreLimit, fFetchMoreOffset);

  setLimit(fLimit + fFetchMoreLimit);

  fOldLimit:= getLimit;
end;


function cAbstractTableModel.addDataPortion(const aCondition: string; aLimit, aOffset: integer): boolean;
var
  table: cAbstractTableModel;
  i: integer;

  appededRowIndex: integer;
begin
  result:= false;

  //todo: check this for huge object
  table:= getTableClass.create;
  try
    table.copyFrom(self);

    if (table.fetch(aCondition, aLimit, aOffset) <> 0) then begin

      beginRowsAppending;
      try
        for i:= 0 to table.getRowCount - 1 do begin
          appededRowIndex:= appendRowToCache;

          if appendedKeyExists(table.getRowKey(i)) then continue;

          copyDataFromTable(table, i, self, appededRowIndex);
        end;
      finally
        endRowsAppending;
      end;

      result:= true;
    end;

  finally
    freeAndNil(table);
  end;
end;

procedure cAbstractTableModel.fieldDataGetting(aCol, aRow: integer; var aValue: variant);
begin
  if assigned(fOnFieldDataGetting) then begin
    fOnFieldDataGetting(self, aCol, aRow, aValue);
  end;
end;

procedure cAbstractTableModel.fieldDataSetting(aCol, aRow: integer; var aValue: variant);
begin
  if assigned(fOnFieldDataSetting) then begin
    fOnFieldDataSetting(self, aCol, aRow, aValue);
  end;
end;

end.


