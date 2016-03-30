unit clsSQLiteQuery;

interface
uses
  db,
  sysUtils,
  zAbstractRODataset,
  zAbstractDataset,
  zDataset,

  math,

  clsVariantConversion,
  clsAbstractSQLConnection,
  clsAbstractSQLQuery;

type

  cSQLiteQuery = class(cAbstractSQLQuery)
  private
    fDataSet    : tZQuery;
  protected
    function    getFields: tFields; override;
    procedure   setFieldData(aField: tField; const aValue: variant); override;

    procedure   setFieldsEditable;
  public
    function    getNativeDataSet: tDataSet; override;

    procedure   setConnection(aConnection: cAbstractSQLConnection); override;

    function    locate(const aKeyFields: string; const aKeyValues: variant; aOptions: tLocateOptions): boolean; override;

    function    getIndexFields: tIndexDefs; override;
    procedure   setIndexFieldsNames(aFields: string); override;
    function    getIndexFieldsNames: string; override;

    function    getFieldType(aCol: integer): tFieldType; override;

    procedure   setIndexFieldName(aField: string); override;
    function    getIndexFieldName: string; override;

    procedure   setSQL(const aCommand: string); override;
    function    getRowsAffected: integer; override;

    function    appendRow: integer; override;
    procedure   deleteRow(aRow: integer); override;
    procedure   deleteCurrentRow; override;

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
  clsSQLiteConnection;

{ cSQLiteQuery }

constructor cSQLiteQuery.create;
begin
  inherited create;

  fDataSet:= tZQuery.create(nil);
  fDataSet.cachedUpdates:= true;
end;

procedure cSQLiteQuery.deleteCurrentRow;
begin
  if not assigned(fDataSet) then exit;

  if not isOpened then exit;

  fDataSet.delete;
end;

procedure cSQLiteQuery.deleteRow(aRow: integer);
begin
  if not assigned(fDataSet) then exit;

  if not isOpened then exit;

  moveTo(aRow);
  fDataSet.delete;
end;

destructor cSQLiteQuery.destroy;
begin
  if assigned(fDataSet) then begin
    freeAndNil(fDataSet);
  end;

  inherited;
end;

procedure cSQLiteQuery.exec;
begin
  inherited exec;

  if not assigned(fDataSet) then exit;

  fDataSet.SQL.text:= getPreparedSQL;

  fDataSet.execSQL;
end;

function cSQLiteQuery.close: boolean;
begin
  result:= false;

  inherited close;

  if not assigned(fDataSet) then exit;

  fDataSet.close;
  result:= not isOpened;
end;


procedure cSQLiteQuery.first;
begin
  inherited;

  if not assigned(fDataSet) then exit;
  fDataSet.first;
end;

function cSQLiteQuery.getFields: tFields;
begin
  result:= nil;
  if not assigned(fDataSet) then exit;
  result:= fDataSet.fields;
end;

function cSQLiteQuery.getFieldType(aCol: integer): tFieldType;
begin
  result:= fDataSet.fieldDefs.items[aCol].dataType;
end;

function cSQLiteQuery.getIndexFieldName: string;
begin
  result:= '';
end;

function cSQLiteQuery.getIndexFields: tIndexDefs;
begin
  result:= nil;
end;

function cSQLiteQuery.getIndexFieldsNames: string;
begin
  result:= '';
  if not assigned(fDataSet) then exit;
  result:= fDataSet.indexFieldNames;
end;

function cSQLiteQuery.getNativeDataSet: tDataSet;
begin
  result:= fDataSet;
end;

function cSQLiteQuery.getRowCount: integer;
begin
  result:= 0;
  if not assigned(fDataSet) then exit;
  if not isOpened then exit;

  result:= fDataSet.recordCount;
end;

function cSQLiteQuery.getRowsAffected: integer;
begin
  result:= 0;
  if not assigned(fDataSet) then exit;
  if not isOpened then exit;
  result:= fDataSet.rowsAffected;
end;

function cSQLiteQuery.appendRow: integer;
begin
  result:= -1;
  if not assigned(fDataSet) then exit;
  if not isOpened then exit;

  fDataSet.append;
  fDataSet.post;

  result:= fDataSet.recNo - 1;

  rowAppended(result);
end;

function cSQLiteQuery.isBof: boolean;
begin
  result:= true;
  if not assigned(fDataSet) then exit;
  if not isOpened then exit;
  result:= fDataSet.bof;
end;

function cSQLiteQuery.isEmpty: boolean;
begin
  result:= true;
  if not assigned(fDataSet) then exit;
  if not isOpened then exit;

  result:= fDataSet.isEmpty;
end;

function cSQLiteQuery.isEof: boolean;
begin
  result:= true;
  if not assigned(fDataSet) then exit;
  if not isOpened then exit;
  result:= fDataSet.eof;
end;

function cSQLiteQuery.isOpened: boolean;
begin
  result:= false;

  if not assigned(fDataSet) then exit;

  result:= fDataSet.active;
end;

function cSQLiteQuery.locate(const aKeyFields: string; const aKeyValues: variant; aOptions: tLocateOptions): boolean;
begin
  result:= false;
  if not assigned(fDataSet) then exit;
  if not isOpened then exit;
  result:= fDataSet.locate(aKeyFields, aKeyValues, aOptions);
end;

function cSQLiteQuery.moveTo(aRow: integer): boolean;
begin
  result:= false;

  if not assigned(fDataSet) then exit;
  if not isOpened then exit;

  fDataSet.recNo:= min(aRow + 1, getRowCount);
  result:= true;
end;

procedure cSQLiteQuery.next;
begin
  inherited;

  if not assigned(fDataSet) then exit;
  if not isOpened then exit;

  fDataSet.next;
end;

function cSQLiteQuery.open: boolean;
begin
  result:= false;

  inherited open;

  close;

  if not assigned(fDataSet) then exit;

  fDataSet.SQL.text:= getPreparedSQL;

  fDataSet.open;

  setFieldsEditable;

  result:= isOpened;

  cDebug.write('cSQLiteQuery.open: SQL command: %s', [fDataSet.SQL.text]);
end;

procedure cSQLiteQuery.prev;
begin
  inherited;

  if not assigned(fDataSet) then exit;
  if not isOpened then exit;

  fDataSet.prior;
end;

procedure cSQLiteQuery.setConnection(aConnection: cAbstractSQLConnection);
var
  SQLiteConnection: cSQLiteConnection;
begin
  inherited setConnection(aConnection);

  if not assigned(fDataSet) then exit;
  close;
  SQLiteConnection:= aConnection as cSQLiteConnection;
  fDataSet.connection:= SQLiteConnection.getInternalConnection;
end;

procedure cSQLiteQuery.setFieldData(aField: tField; const aValue: variant);
begin
  if not assigned(fDataSet) then exit;
  if not assigned(aField) then exit;

  fDataSet.edit;
  try

    aField.value:= aValue;

  finally
    fDataSet.post;
  end;
end;

procedure cSQLiteQuery.setFieldsEditable;
var
  i: integer;
begin
  for i:= 0 to fDataSet.fields.count - 1 do begin
    fDataSet.fields[i].readOnly:= false;
  end;
end;

procedure cSQLiteQuery.setIndexFieldName(aField: string);
begin

end;

procedure cSQLiteQuery.setIndexFieldsNames(aFields: string);
begin
  if not assigned(fDataSet) then exit;
  fDataSet.indexFieldNames:= aFields;
end;

procedure cSQLiteQuery.setSQL(const aCommand: string);
begin
  inherited setSQL(aCommand);
end;

end.
