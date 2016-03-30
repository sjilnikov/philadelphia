unit clsAbstractAggregateModel;

interface
uses
  sysUtils,
  classes,
  syncObjs,

  uModels,

  clsVariantConversion,
  clsLists,
  clsMulticastEvents,

  clsScriptEngine,
  clsException,
  clsAbstractTableModel;

type
  cAggregateField = class
  private
    fTitle         : string;
    fName          : string;
    fValue         : currency;
    fValueFormat   : string;
    fFormula       : string;
    fAggregateType : tAggregateFieldType;
  public
    procedure   setFormula(aValue: string);
    procedure   setValue(aValue: currency);
    procedure   setTitle(aTitle: string);
    procedure   setName(aName: string);
    procedure   setValueFormat(aFormat: string);
    procedure   setAggregateType(aAggregateFieldType: tAggregateFieldType);

    function    getTitle: string;
    function    getName: string;
    function    getFormula: string;
    function    getAggregateType: tAggregateFieldType;
    function    getValue: currency;
    function    getFormatedValue: variant;
    function    getValueFormat: string;

    constructor create(aName: string; aTitle: string; aAggregateType: tAggregateFieldType; aValueFormat: string);

  published
    property    title: string read getTitle write setTitle;
    property    name: string read getName write setName;
    property    formula: string read getFormula write setFormula;

    property    value: currency read getValue;
    property    formatedValue: variant read getFormatedValue;
    property    valueFormat: string read getValueFormat write setValueFormat;
  end;

  cAggregateFields = class
  private
    fList : cList;
  public
    function    getDelimitedNames(aWithCalcFields: boolean = false; aDelimiter: string = ','): string;
    function    getAggregateTypes(aWithCalcFields: boolean = false): cAggregateFieldTypes;

    procedure   clear;
    procedure   delete(aIndex: integer);
    function    indexOfName(aName: string): integer;

    procedure   add(aItem: cAggregateField);

    function    getItemByIndex(aIndex: integer): cAggregateField;
    function    getItemByName(aName: string): cAggregateField;
    function    getCount: integer;

    constructor create;
    destructor  destroy; override;

  public
    property    count: integer read getCount;

    property    items[aIndex: integer]: cAggregateField read getItemByIndex; default;
    property    items[aName: string]: cAggregateField read getItemByName; default;
  end;

  cAbstractAggregateModel = class;


  cAbstractAggregateModel = class(cAbstractTableModel)
  private
    fTableModel               : cAbstractTableModel;
    fAggregateFields          : cAggregateFields;
    fBusy                     : boolean;
    fEnabled                  : boolean;
    fScriptEngine             : cScriptEngine;
    fCS                       : tCriticalSection;

    procedure   createModelFields;
    procedure   destroyModelFields;

    procedure   setupTableModelEvents;
    procedure   disconnectTableModelEvents;

    procedure   clearAggregate;

  protected
    procedure   beginCalc;
    procedure   endCalc;

    procedure   updateCalcFields;

    procedure   updateAggregateValues; virtual; abstract;
    function    getAggregateField(aName: string): cAggregateField; overload;
    function    getAggregateField(aIndex: integer): cAggregateField; overload;

    function    internalGetFieldData(aCol: integer; aRow: integer): variant;
  public
    //table model
    function    getFieldData(aCol: integer; aRow: integer; aGetDataRole: tTableModelDataRole = drUseRelation): variant; overload; override;
    function    getFieldData(aName: string; aRow: integer; aGetDataRole: tTableModelDataRole = drUseRelation): variant; overload; override;

    procedure   setFieldFormula(aName: string; aValue: string);

    procedure   setFieldData(aCol: integer; aRow: integer; const aValue: variant); overload; override;

    function    getFieldType(aCol: integer): tDataType; override;
    //

    function    getAggregateFieldCount: integer;
    procedure   deleteAggregateField(aName: string);

    procedure   addAggregateField(aName: string; aTitle: string; aAggregateType: tAggregateFieldType = aftSum; aValueFormat: string = '%m');

    function    getAggregateFieldDelimitedNames(aDelimiter: string = ','): string;
    function    getAggregateFieldTypes: cAggregateFieldTypes;

    function    isBusy: boolean;
    function    isEnabled: boolean;
    function    getTableModel: cAbstractTableModel;

    procedure   setEnabled(aValue: boolean);

    procedure   setModel(aModel: cAbstractTableModel);

    constructor create;
    destructor  destroy; override;
  published
    property    tableModel: cAbstractTableModel read getTableModel;
  published
    //SLOTS
    procedure   tableModelChanged(aModel: cAbstractTableModel);
  end;

implementation
uses
  clsAbstractSQLConnection,
  clsSQLConnectionsFactory;

{ cAggregateModel }

constructor cAbstractAggregateModel.create;
begin
  fCS:= tCriticalSection.create;
  inherited create;
  fAggregateFields:= cAggregateFields.create;
  fScriptEngine:= cScriptEngine.create;

  fBusy:= false;
  fEnabled:= true;

  setRowCount(1);
end;

destructor cAbstractAggregateModel.destroy;
begin
  if assigned(fAggregateFields) then begin
    freeAndNil(fAggregateFields);
  end;

  if assigned(fScriptEngine) then begin
    freeAndNil(fScriptEngine);
  end;

  if assigned(fCS) then begin
    freeAndNil(fCS);
  end;

  inherited;
end;

procedure cAbstractAggregateModel.addAggregateField(aName: string; aTitle: string; aAggregateType: tAggregateFieldType; aValueFormat: string);
begin
  fCS.enter;
  try
    fAggregateFields.add(cAggregateField.create(aName, aTitle, aAggregateType, aValueFormat));
  finally
    fCS.leave;
  end;
end;

procedure cAbstractAggregateModel.beginCalc;
begin
  fBusy:= true;
end;

procedure cAbstractAggregateModel.clearAggregate;
begin
  fAggregateFields.clear;
end;

procedure cAbstractAggregateModel.deleteAggregateField(aName: string);
var
  foundIndex: integer;
begin
  fCS.enter;
  try
    foundIndex:= fAggregateFields.indexOfName(aName);
    if (foundIndex = - 1) then begin
      exit;
    end;

    fAggregateFields.delete(foundIndex);
  finally
    fCS.leave;
  end;
end;

function cAbstractAggregateModel.getAggregateField(aName: string): cAggregateField;
begin
  result:= fAggregateFields.items[aName];
end;

function cAbstractAggregateModel.getAggregateField(aIndex: integer): cAggregateField;
begin
  result:= fAggregateFields.items[aIndex];
end;

function cAbstractAggregateModel.getAggregateFieldCount: integer;
begin
  fCS.enter;
  try
    result:= fAggregateFields.count;
  finally
    fCS.leave;
  end;
end;

function cAbstractAggregateModel.getAggregateFieldDelimitedNames(aDelimiter: string): string;
begin
  fCS.enter;
  try
    result:= fAggregateFields.getDelimitedNames(false, aDelimiter);
  finally
    fCS.leave;
  end;
end;

function cAbstractAggregateModel.getAggregateFieldTypes: cAggregateFieldTypes;
begin
  fCS.enter;
  try
    result:= fAggregateFields.getAggregateTypes;
  finally
    fCS.leave;
  end;
end;

function cAbstractAggregateModel.getFieldData(aCol, aRow: integer; aGetDataRole: tTableModelDataRole): variant;
var
  fieldValue: variant;
begin
  fCS.enter;
  try
    fieldValue:= internalGetFieldData(aCol, aRow);

    fieldDataGetting(aCol, aRow, fieldValue);

    result:= fieldValue;
  finally
    fCS.leave;
  end;
end;

function cAbstractAggregateModel.getFieldData(aName: string; aRow: integer; aGetDataRole: tTableModelDataRole): variant;
var
  foundIndex: integer;
  fieldValue: variant;
begin
  fCS.enter;
  try
    result:= '';

    foundIndex:= fAggregateFields.indexOfName(aName);

    if (foundIndex = -1) then begin
      exit;
    end;

    fieldValue:= internalGetFieldData(foundIndex, aRow);

    fieldDataGetting(foundIndex, aRow, fieldValue);

    result:= fieldValue;
  finally
    fCS.leave;
  end;
end;

function cAbstractAggregateModel.getFieldType(aCol: integer): tDataType;
begin
  result:= dtString;
end;

function cAbstractAggregateModel.getTableModel: cAbstractTableModel;
begin
  result:= fTableModel;
end;

function cAbstractAggregateModel.internalGetFieldData(aCol, aRow: integer): variant;
begin
  result:= '';

  if (aCol < getAggregateFieldCount) then begin
    result:= getAggregateField(aCol).getFormatedValue;
  end;
end;

function cAbstractAggregateModel.isBusy: boolean;
begin
  result:= fBusy;
end;

function cAbstractAggregateModel.isEnabled: boolean;
begin
  result:= fEnabled;
end;

procedure cAbstractAggregateModel.setEnabled(aValue: boolean);
begin
  fEnabled:= aValue;
  if (fEnabled) then begin
    updateAggregateValues;
  end;
end;

procedure cAbstractAggregateModel.setFieldData(aCol, aRow: integer; const aValue: variant);
var
  foundField: cAggregateField;
  fieldValue: variant;
begin
  fieldValue:= aValue;

  fieldDataSetting(aCol, aRow, fieldValue);

  inherited setFieldData(aCol, aRow, fieldValue);

  fCS.enter;
  try
    foundField:= getAggregateField(aCol);
    if not assigned(foundField) then begin
      exit;
    end;

    foundField.setValue(fieldValue);
  finally
    fCS.leave;
  end;
end;

procedure cAbstractAggregateModel.setFieldFormula(aName: string; aValue: string);
var
  foundIndex: integer;
begin
  fCS.enter;
  try
    foundIndex:= fAggregateFields.indexOfName(aName);

    if (foundIndex = -1) then exit;

    fAggregateFields.items[foundIndex].formula:= aValue;
  finally
    fCS.leave;
  end;
end;

procedure cAbstractAggregateModel.setModel(aModel: cAbstractTableModel);
begin
  disconnectTableModelEvents;

  destroyModelFields;

  fTableModel:= aModel;

  createModelFields;

  setupTableModelEvents;
end;

procedure cAbstractAggregateModel.createModelFields;
var
  i: integer;
  curAggregateField: cAggregateField;
begin
  if not assigned(fTableModel) then begin
    exit;
  end;

  for i:= 0 to getAggregateFieldCount - 1 do begin
    curAggregateField:= getAggregateField(i);

    addField(curAggregateField.getName, curAggregateField.getTitle, true);
  end;

end;

procedure cAbstractAggregateModel.destroyModelFields;
var
  i: integer;
  curAggregateField: cAggregateField;
begin
  if not assigned(fTableModel) then begin
    exit;
  end;

  getFields.clear;
end;

procedure cAbstractAggregateModel.setupTableModelEvents;
begin
  if not assigned(fTableModel) then begin
    exit;
  end;

  connect(fTableModel, 'onDataChanged', self, 'tableModelChanged');
end;

procedure cAbstractAggregateModel.disconnectTableModelEvents;
begin
  if not assigned(fTableModel) then begin
    exit;
  end;

  disconnect(fTableModel, 'onDataChanged', self, 'tableModelChanged');
end;

procedure cAbstractAggregateModel.endCalc;
begin
  try
    updateCalcFields;
  finally
    fBusy:= false;
  end;
end;

//SLOTS
procedure cAbstractAggregateModel.tableModelChanged(aModel: cAbstractTableModel);
begin
  updateAggregateValues;
end;

procedure cAbstractAggregateModel.updateCalcFields;
var
  i: integer;
  curField: cAggregateField;
  calcValue: currency;
begin
  for i:= 0 to fAggregateFields.count - 1 do begin
    curField:= fAggregateFields.items[i];

    try
      if (curField.getAggregateType <> aftFormula) then begin
        fScriptEngine.addConst(curField.name, curField.value);
        continue;
      end else begin
        calcValue:= fScriptEngine.evaluate(curField.formula);
      end;
    except
      calcValue:= 0;
    end;

    curField.setValue(calcValue);
  end;
end;

{ cAggregateFields }

constructor cAggregateFields.create;
begin
  inherited create;
  fList:= cList.create;
end;

destructor cAggregateFields.destroy;
begin
  if assigned(fList) then begin
    clear;
    freeAndNil(fList);
  end;

  inherited;
end;

procedure cAggregateFields.add(aItem: cAggregateField);
begin
  fList.add(aItem);
end;

procedure cAggregateFields.clear;
begin
  fList.freeInternalObjects;
  fList.clear;
end;

procedure cAggregateFields.delete(aIndex: integer);
begin
  fList.freeInternalObject(aIndex);
  fList.delete(aIndex);
end;

function cAggregateFields.getAggregateTypes(aWithCalcFields: boolean): cAggregateFieldTypes;
var
  i: integer;
  curField: cAggregateField;
begin
  setLength(result, count);

  for i:= 0 to count - 1 do begin
    curField:= items[i];

    if (not aWithCalcFields) and (curField.fAggregateType = aftFormula) then begin
      setLength(result, length(result) - 1);
      continue;
    end;

    result[i]:= curField.getAggregateType;
  end;

end;

function cAggregateFields.getCount: integer;
begin
  result:= fList.count;
end;

function cAggregateFields.getDelimitedNames(aWithCalcFields: boolean; aDelimiter: string): string;
var
  i: integer;
  curField: cAggregateField;
begin
  result:= '';
  for i:= 0 to count - 1 do begin
    curField:= items[i];

    if (not aWithCalcFields) and (curField.fAggregateType = aftFormula) then continue;

    result:= result + aDelimiter + curField.name;
  end;

  system.delete(result, 1, length(aDelimiter));
end;

function cAggregateFields.getItemByIndex(aIndex: integer): cAggregateField;
begin
  result:= fList.items[aIndex];
end;

function cAggregateFields.getItemByName(aName: string): cAggregateField;
var
  foundIndex: integer;
begin
  result:= nil;
  foundIndex:= indexOfName(aName);
  if (foundIndex = -1) then begin
    exit;
  end;

  result:= items[foundIndex];
end;

function cAggregateFields.indexOfName(aName: string): integer;
var
  i: integer;
  curField: cAggregateField;
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

{ cAggregateField }

constructor cAggregateField.create(aName: string; aTitle: string; aAggregateType: tAggregateFieldType; aValueFormat: string);
begin
  inherited create;
  fName:= aName;
  fTitle:= aTitle;
  fValueFormat:= aValueFormat;
  fAggregateType:= aAggregateType;
  fFormula:= '';
end;

function cAggregateField.getAggregateType: tAggregateFieldType;
begin
  result:= fAggregateType;
end;

function cAggregateField.getFormatedValue: variant;
begin
  result:= format(fValueFormat, [fValue]);
end;

function cAggregateField.getFormula: string;
begin
  result:= fFormula;
end;

function cAggregateField.getName: string;
begin
  result:= fName;
end;

function cAggregateField.getTitle: string;
begin
  result:= fTitle;
end;

function cAggregateField.getValue: currency;
begin
  result:= fValue;
end;

function cAggregateField.getValueFormat: string;
begin
  result:= fValueFormat;
end;

procedure cAggregateField.setAggregateType(aAggregateFieldType: tAggregateFieldType);
begin
  fAggregateType:= aAggregateFieldType;
end;

procedure cAggregateField.setFormula(aValue: string);
begin
  fFormula:= aValue;
end;

procedure cAggregateField.setName(aName: string);
begin
  fName:= aName;
end;

procedure cAggregateField.setTitle(aTitle: string);
begin
  fTitle:= aTitle;
end;

procedure cAggregateField.setValue(aValue: currency);
begin
  fValue:= aValue;
end;

procedure cAggregateField.setValueFormat(aFormat: string);
begin
  fValueFormat:= aFormat;
end;

end.
