unit clsMemoryQuery;

interface
uses
  db,
  sysUtils,
  classes,
  dbClient,

  math,

  clsAbstractIOObject,
  clsDBTypeConversion,
  clsVariantConversion,
  clsAbstractSQLConnection,
  clsAbstractSQLQuery;

type

  cMemoryQuery = class(cAbstractSQLQuery)
  private
    fDataSet    : tClientDataSet;
  protected
    function    getFields: tFields; override;
    procedure   setFieldData(aField: tField; const aValue: variant); override;

    procedure   setFieldsEditable;
  public
    procedure   setSQL(const aCommand: string); override;

    function    saveToStream(aStream: cAbstractIOObject): boolean; override;
    function    loadFromStream(aStream: cAbstractIOObject): boolean; override;

    function    getNativeDataSet: tDataSet; override;

    function    locate(const aKeyFields: string; const aKeyValues: variant;  aOptions: tLocateOptions): boolean; override;

    procedure   setIndexFieldsNames(aFields: string); override;
    function    getIndexFieldsNames: string; override;
    function    getFieldType(aCol: integer): tFieldType; override;

    procedure   setIndexFieldName(aField: string); override;
    function    getIndexFieldName: string; override;

    procedure   addIndex(const aName, aFields: string; aOptions: tIndexOptions; const aDescFields: string; aCaseInsFields: string; const aGroupingLevel: integer); override;

    function    getIndexFields: tIndexDefs; override;

    procedure   addField(aName: string; aTitle: string; aType: tDataType; aSize: integer); override;
    procedure   insertField(aIndex: integer; aName: string; aTitle: string; aType: tDataType; aSize: integer); override;
    procedure   deleteField(aName: string); override;

    function    getRowsAffected: integer; override;

    function    appendRow: integer; override;
    procedure   deleteRow(aRow: integer); override;
    procedure   deleteCurrentRow; override;
    function    getCurrentRow: integer; override;

    function    open: boolean; override;
    function    close: boolean; override;

    procedure   exec; override;

    function    isOpened: boolean; override;
    function    isEof: boolean; override;
    function    isBof: boolean; override;
    procedure   first; override;
    procedure   next; override;
    procedure   prev; override;
    function    moveTo(aRow: integer): boolean; override;
    function    isEmpty: boolean; override;
    function    getRowCount: integer; override;

    constructor create;
    destructor  destroy; override;

  published
    property    connection;
    property    fields;
    property    rowsAffected;
  end;

implementation
uses
  clsDebug,
  clsPGSQLConnection;

{ cPGSQLDataReader }

constructor cMemoryQuery.create;
begin
  inherited create;

  fDataSet:= tClientDataSet.create(nil);
end;

procedure cMemoryQuery.deleteCurrentRow;
begin
  if not assigned(fDataSet) then exit;
  fDataSet.delete;
end;

procedure cMemoryQuery.deleteField(aName: string);
var
  foundIndex: integer;
begin
  if not assigned(fDataSet) then exit;

  foundIndex:= fDataSet.fieldDefs.indexOf(aName);
  if (foundIndex = -1) then begin
    exit;
  end;

  fDataSet.fieldDefs.delete(foundIndex);
end;

procedure cMemoryQuery.deleteRow(aRow: integer);
begin
  if not assigned(fDataSet) then exit;

  moveTo(aRow);
  fDataSet.delete;
end;

destructor cMemoryQuery.destroy;
begin
  if assigned(fDataSet) then begin
    freeAndNil(fDataSet);
  end;

  inherited;
end;

procedure cMemoryQuery.exec;
begin
  inherited exec;

  if not assigned(fDataSet) then exit;

  //nothing to do
end;

function cMemoryQuery.close: boolean;
begin
  result:= false;

  inherited close;

  if not assigned(fDataSet) then exit;

  fDataSet.close;
  result:= not isOpened;
end;


procedure cMemoryQuery.first;
begin
  inherited;

  if not assigned(fDataSet) then exit;
  fDataSet.first;
end;

function cMemoryQuery.getCurrentRow: integer;
begin
  result:= -1;
  if not assigned(fDataSet) then exit;

  result:= fDataSet.recNo - 1;
end;

function cMemoryQuery.getFields: tFields;
begin
  result:= nil;
  if not assigned(fDataSet) then exit;
  result:= fDataSet.fields;
end;

function cMemoryQuery.getFieldType(aCol: integer): tFieldType;
begin
  result:= fDataSet.fieldDefs.items[aCol].dataType;
end;

function cMemoryQuery.getIndexFieldName: string;
begin
  result:= '';
  if not assigned(fDataSet) then exit;
  result:= fDataSet.indexName;
end;

function cMemoryQuery.getIndexFields: tIndexDefs;
begin
  result:= nil;
  if not assigned(fDataSet) then exit;
  result:= fDataSet.indexDefs;
end;

function cMemoryQuery.getIndexFieldsNames: string;
begin
  result:= '';
  if not assigned(fDataSet) then exit;
  result:= fDataSet.indexFieldNames;
end;

function cMemoryQuery.getNativeDataSet: tDataSet;
begin
  result:= fDataSet;
end;

function cMemoryQuery.getRowCount: integer;
begin
  result:= 0;
  if not assigned(fDataSet) then exit;
  result:= fDataSet.recordCount;
end;

function cMemoryQuery.getRowsAffected: integer;
begin
  result:= 0;
end;

procedure cMemoryQuery.addField(aName, aTitle: string; aType: tDataType; aSize: integer);
var
  newDef: tFieldDef;
begin
  if not assigned(fDataSet) then exit;

  newDef:= fDataSet.fieldDefs.addFieldDef;
  newDef.name:= aName;
  newDef.displayName:= aTitle;
  newDef.dataType:= cDBTypeConversion.dataTypeToFieldType(aType);
  newDef.size:= aSize;
//  newDef.createField(fDataSet);
end;

procedure cMemoryQuery.addIndex(const aName, aFields: string; aOptions: tIndexOptions; const aDescFields: string; aCaseInsFields: string; const aGroupingLevel: integer);
begin
  if not assigned(fDataSet) then exit;

  fDataSet.addIndex(aName, aFields, aOptions, aDescFields, aCaseInsFields, aGroupingLevel);
end;

function cMemoryQuery.appendRow: integer;
begin
  result:= -1;
  if not assigned(fDataSet) then exit;
  fDataSet.append;
  fDataSet.post;

  rowAppended(getCurrentRow);

  result:= getCurrentRow;
end;

procedure cMemoryQuery.insertField(aIndex: integer; aName, aTitle: string; aType: tDataType; aSize: integer);
var
  newDef: tFieldDef;
begin
  if not assigned(fDataSet) then exit;

  newDef:= fDataSet.fieldDefs.addFieldDef;
  newDef.name:= aName;
  newDef.displayName:= aTitle;
  newDef.dataType:= cDBTypeConversion.dataTypeToFieldType(aType);
  newDef.size:= aSize;
  newDef.index:= aIndex;
//  newDef.createField(fDataSet);
end;

function cMemoryQuery.isBof: boolean;
begin
  result:= true;
  if not assigned(fDataSet) then exit;
  result:= fDataSet.bof;
end;

function cMemoryQuery.isEmpty: boolean;
begin
  result:= true;
  if not assigned(fDataSet) then exit;
  result:= fDataSet.isEmpty;
end;

function cMemoryQuery.isEof: boolean;
begin
  result:= true;
  if not assigned(fDataSet) then exit;
  result:= fDataSet.eof;
end;

function cMemoryQuery.isOpened: boolean;
begin
  result:= false;

  if not assigned(fDataSet) then exit;

  result:= fDataSet.active;
end;

function cMemoryQuery.moveTo(aRow: integer): boolean;
begin
  result:= false;

  if not assigned(fDataSet) then exit;

  fDataSet.recNo:= min(aRow + 1, getRowCount);
  result:= true;
end;

procedure cMemoryQuery.next;
begin
  inherited;

  if not assigned(fDataSet) then exit;
  fDataSet.next;
end;

function cMemoryQuery.open: boolean;
var
  tick: cardinal;
  preparedSQL: string;
begin
  result:= false;

  inherited open;

  if not assigned(fDataSet) then exit;

  if (isOpened) then begin
    exit;
  end;


  fDataSet.filtered:= false;

  preparedSQL:= getPreparedSQL;
  if (preparedSQL = '') then exit;

  fDataSet.filter:= preparedSQL;
  fDataSet.filtered:= true;

  fDataSet.createDataSet;
  fDataSet.open;

  setFieldsEditable;

  result:= isOpened;

  cDebug.write('cMemoryQuery.open');
end;

procedure cMemoryQuery.prev;
begin
  inherited;

  if not assigned(fDataSet) then exit;
  fDataSet.prior;
end;

function cMemoryQuery.loadFromStream(aStream: cAbstractIOObject): boolean;
begin
  result:= false;
  if not assigned(fDataSet) then exit;
  try
    fDataSet.loadFromStream(aStream);
    result:= true;
  except
    result:= false;
  end;
end;

function cMemoryQuery.locate(const aKeyFields: string; const aKeyValues: variant; aOptions: tLocateOptions): boolean;
begin
  result:= false;
  if not assigned(fDataSet) then exit;
  result:= fDataSet.locate(aKeyFields, aKeyValues, aOptions);
end;

function cMemoryQuery.saveToStream(aStream: cAbstractIOObject): boolean;
begin
  result:= false;
  if not assigned(fDataSet) then exit;

  try
    aStream.seek(0, soBeginning);
    fDataSet.saveToStream(aStream);
    result:= true;
  except
    result:= false;
  end;
end;

procedure cMemoryQuery.setFieldData(aField: tField; const aValue: variant);
begin
  if not assigned(fDataSet) then exit;

  fDataSet.edit;
  try

    aField.value:= aValue;

  finally
    fDataSet.post;
  end;
end;

procedure cMemoryQuery.setFieldsEditable;
var
  i: integer;
begin
  for i:= 0 to fDataSet.fields.count - 1 do begin
    fDataSet.fields[i].readOnly:= false;
  end;
end;


procedure cMemoryQuery.setIndexFieldName(aField: string);
begin
  if not assigned(fDataSet) then exit;
  fDataSet.indexName:= aField;
end;

procedure cMemoryQuery.setIndexFieldsNames(aFields: string);
begin
  if not assigned(fDataSet) then exit;
  fDataSet.indexFieldNames:= aFields;
end;

procedure cMemoryQuery.setSQL(const aCommand: string);
begin
  inherited setSQL(aCommand);
end;

end.
