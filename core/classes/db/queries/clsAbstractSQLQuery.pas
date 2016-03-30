unit clsAbstractSQLQuery;

interface
uses
  sysUtils,
  db,
  generics.collections,

  clsException,
  clsAbstractIOObject,
  clsVariantConversion,

  clsSQLDataBuildersFactory,
  clsAbstractSQLDataBuilder,
  clsAbstractSQLConnection;

type
  eAbstractSQLQuery = class(cException);

  cAbstractSQLQuery = class;

  tAbstractSQLQueryRowAppendedEvent = procedure(aSender: cAbstractSQLQuery; aRow: integer) of object;

  cAbstractSQLQuery = class
  private
    const

    CONNECTION_WAS_CLOSED = 'connection was unexpectedly closed';
  private
    fConnection     : cAbstractSQLConnection;

    fOnRowAppended  : tAbstractSQLQueryRowAppendedEvent;
    fParametersDict : tDictionary<string, variant>;
    fSQL            : string;
    fExecutedQuery  : string;

    procedure   checkConnection;
  protected
    function    getFields: tFields; virtual; abstract;
    procedure   setFieldData(aField: tField; const aValue: variant); overload; virtual; abstract;

    procedure   rowAppended(aRow: integer);
    function    getPreparedSQL: string;
  public
    function    executedQuery: string;

    function    saveToStream(aStream: cAbstractIOObject): boolean; virtual; abstract;
    function    loadFromStream(aStream: cAbstractIOObject): boolean; virtual; abstract;

    function    getNativeDataSet: tDataSet; virtual; abstract;

    procedure   setConnection(aConnection: cAbstractSQLConnection); virtual;

    procedure   setIndexFieldsNames(aFields: string); virtual; abstract;
    function    getIndexFieldsNames: string; virtual; abstract;

    procedure   setIndexFieldName(aField: string); virtual; abstract;
    function    getIndexFieldName: string; virtual; abstract;

    procedure   addIndex(const aName, aFields: string; aOptions: tIndexOptions; const aDescFields: string = ''; aCaseInsFields: string = ''; const aGroupingLevel: integer = 0); virtual; abstract;

    function    getIndexFields: tIndexDefs; virtual; abstract;

    procedure   addField(aName: string; aTitle: string; aType: tDataType; aSize: integer); virtual; abstract;
    procedure   insertField(aIndex: integer; aName: string; aTitle: string; aType: tDataType; aSize: integer); virtual; abstract;
    procedure   deleteField(aName: string); virtual; abstract;

    procedure   bindValue(aParameterName: string; const aValue: variant);

    function    locate(const aKeyFields: string; const aKeyValues: variant; aOptions: tLocateOptions = []): boolean; virtual; abstract;

    procedure   setSQL(const aCommand: string); virtual;
    function    getRowsAffected: integer; virtual; abstract;

    procedure   exec; virtual;

    function    open: boolean; virtual;
    function    close: boolean; virtual;

    function    getFieldType(aCol: integer): tFieldType; virtual; abstract;
    function    getField(aCol: integer; aRow: integer): tField; overload;
    function    getField(aName: string; aRow: integer): tField; overload;

    function    appendRow: integer; virtual; abstract;

    procedure   deleteRow(aRow: integer); virtual; abstract;
    procedure   deleteCurrentRow; virtual; abstract;

    procedure   setFieldData(aCol: integer; aRow: integer; const aValue: variant); overload;

    function    isOpened: boolean; virtual; abstract;
    function    isEof: boolean; virtual; abstract;
    function    isBof: boolean; virtual; abstract;
    procedure   first; virtual; abstract;
    procedure   next; virtual; abstract;
    procedure   prev; virtual; abstract;
    function    moveTo(aRow: integer): boolean; virtual; abstract;
    function    isEmpty: boolean; virtual; abstract;
    function    getRowCount: integer; virtual; abstract;
    function    getCurrentRow: integer; virtual; abstract;

    constructor create;
    destructor  destroy; override;
  published
    property    connection: cAbstractSQLConnection read fConnection;
    property    fields: tFields read getFields;
    property    rowsAffected: integer read getRowsAffected;
  published
    //EVENTS
    property    onRowAppended: tAbstractSQLQueryRowAppendedEvent read fOnRowAppended write fOnRowAppended;
  end;

implementation

{ cAbstractSQLQuery }

procedure cAbstractSQLQuery.rowAppended(aRow: integer);
begin
  if assigned(fOnRowAppended) then begin
    fOnRowAppended(self, aRow);
  end;
end;

procedure cAbstractSQLQuery.bindValue(aParameterName: string; const aValue: variant);
begin
  fParametersDict.addOrSetValue(aParameterName, aValue);
end;

procedure cAbstractSQLQuery.checkConnection;
var
  testResult: boolean;
begin
  testResult:= true;
  if assigned(fConnection) then begin
    testResult:= fConnection.testConnection;
  end;

  if (not testResult) then begin
    raise eAbstractSQLQuery.create(CONNECTION_WAS_CLOSED);
  end;
end;

function cAbstractSQLQuery.close: boolean;
begin
  checkConnection;
end;

constructor cAbstractSQLQuery.create;
begin
  inherited create;
  fConnection:= nil;
  fParametersDict:= tDictionary<string, variant>.create;
end;

destructor cAbstractSQLQuery.destroy;
begin
  if assigned(fParametersDict) then begin
    freeAndNil(fParametersDict);
  end;

  inherited;
end;

function cAbstractSQLQuery.getField(aCol, aRow: integer): tField;
begin
  result:= nil;
  if (aRow < 0) or (getRowCount = 0) then begin
    exit;
  end;

  moveTo(aRow);
  result:= getFields[aCol];
end;


function cAbstractSQLQuery.getField(aName: string; aRow: integer): tField;
begin
  result:= nil;
  if (aRow < 0) or (getRowCount = 0) then begin
    exit;
  end;

  moveTo(aRow);
  result:= getFields.fieldByName(aName);
end;

function cAbstractSQLQuery.getPreparedSQL: string;
var
  curParameter: tPair<string, variant>;
  dataBuilder: cAbstractSQLDataBuilder;
begin
  result:= fSQL;

  if (fParametersDict.count = 0) then exit;

  if not assigned(fConnection) then exit;

  dataBuilder:= cSQLDataBuildersFactory.createNew(fConnection.connectionInfo.driver);
  try
    for curParameter in fParametersDict do begin
      result:= stringReplace(
        result,
        curParameter.key,
        dataBuilder.variantToFieldValue(curParameter.value, cVariantConversion.varTypeToDataType(curParameter.value)),
        [rfReplaceAll]
      );
    end;

    fExecutedQuery:= result;
  finally
    freeAndNil(dataBuilder);
  end;
end;

function cAbstractSQLQuery.open: boolean;
begin
  result:= false;

  checkConnection;
end;

procedure cAbstractSQLQuery.exec;
begin
  checkConnection;
end;

function cAbstractSQLQuery.executedQuery: string;
begin
  result:= fExecutedQuery;
end;

procedure cAbstractSQLQuery.setConnection(aConnection: cAbstractSQLConnection);
begin
  fConnection:= aConnection;
end;

procedure cAbstractSQLQuery.setFieldData(aCol, aRow: integer; const aValue: variant);
begin
  setFieldData(getField(aCol, aRow), aValue);
end;

procedure cAbstractSQLQuery.setSQL(const aCommand: string);
begin
  fSQL:= aCommand;
end;

end.
