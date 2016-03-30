unit clsSQLiteCommandsBuilder;

interface
uses
  windows,
  sysUtils,
  perlRegEx,


  uModels,

  clsException,
  clsStringUtils,
  clsAbstractSQLCommandsBuilder;

type
  eSQLiteCommandsBuilder = class(cException);

  cSQLiteCommandsBuilder = class(cAbstractSQLCommandsBuilder)
  public
    const
    METHOD_DOES_NOT_SUPPORTED = 'method does not supported';

    FIELDS_COUNT_AND_AGGREGATE_PARAMS_COUNT_NOT_MATCHED = 'fields count and aggregate params count not matched';
  public

    function    getInsertCommand(const aTable: string; const aFields: string; const aValues: string; const aReturningFields: string): string; override;
    function    getDefaultInsertCommand(const aTable: string; const aReturningFields: string): string; override;
    function    getUpdateCommand(const aTable: string; const aFieldValues: string; const aCondition: string): string; override;
    function    getDeleteCommand(const aTable: string; const aCondition: string): string; override;

    function    getSelectCommand(const aSelectCommand: string; const aCondition: string; const aOrder: string = ''): string; override;
    function    getSelectCommandLimited(const aSelectCommand: string; aLimit: integer; aOffset: integer): string; override;
    function    getCountCommand(const aCommand: string): string; override;
    function    getAggregateCommand(const aCommand: string; const aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes): string; override;
    function    clearLimitAndOffset(const aCommand: string): string;

    function    getCTESelectCommand(const aCTEName: string; aWorkTableParams: sSQLCTEWorkTableParams; aIntermediateTableParams: sSQLCTEIntermediateTableParams; aResultTableParams: sSQLCTEResultTableParams): string; override;
  end;

implementation
uses clsSQLiteDataBuilder;

{ cSQLiteCommandsBuilder }

function cSQLiteCommandsBuilder.clearLimitAndOffset(const aCommand: string): string;
const
  SEARCH_TEMPLATE = '(limit [0-9]*)([ ]*)(offset [0-9]*)?';
var
  regEx: tPerlRegEx;
begin
  result:= '';
  regEx:= tPerlRegEx.create;
  try
    regEx.regEx:= SEARCH_TEMPLATE;
    regEx.subject:= aCommand;
    regEx.replacement:= '';

    if regEx.match then regEx.replace;

    result:= regEx.subject;
  finally
    freeAndNil(regEx);
  end;
end;

function cSQLiteCommandsBuilder.getAggregateCommand(const aCommand: string; const aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes): string;
var
  i: integer;
  fiedlsCount: integer;
  fieldsArr: tArguments;
  fieldNames: string;

  curField: string;
  aggregateFieldType: tAggregateFieldType;

  aggregateSelectFieldsStatement: string;

  dataBuilder: cSQLiteDataBuilder;
begin
  result:= '';

  dataBuilder:= cSQLiteDataBuilder.create;
  try


    fieldNames:= stringReplace(afieldNames, ' ', '', [rfReplaceAll]);

    fieldsArr:= cStringUtils.explode(fieldNames, ',');
    fiedlsCount:= length(fieldsArr);

    if (fiedlsCount <> length(aAggregateFieldsType)) then begin
      raise eSQLiteCommandsBuilder.create(FIELDS_COUNT_AND_AGGREGATE_PARAMS_COUNT_NOT_MATCHED);
    end;

    if (fiedlsCount = 0) then begin
      exit;
    end;


    aggregateSelectFieldsStatement:= '';
    for i:= 0 to fiedlsCount - 1 do begin
      curField:= fieldsArr[i];

      aggregateFieldType:= tAggregateFieldType(aAggregateFieldsType[i]);


      aggregateSelectFieldsStatement:= aggregateSelectFieldsStatement + ',' + dataBuilder.getAggregateNamedField(curField, aggregateFieldType);
    end;

    system.delete(aggregateSelectFieldsStatement, 1, 1);

    result:=
      format(
        'select %s from (%s) as inh',
        [
          aggregateSelectFieldsStatement,
          aCommand
        ]
      );
  finally
    freeAndNil(dataBuilder);
  end;
end;

//use simple select withuot subquery
function cSQLiteCommandsBuilder.getCountCommand(const aCommand: string): string;
var
  i: integer;
  strLen: integer;

  selectPos: integer;
  fromPos: integer;

  delStartIndex: integer;
begin
  selectPos:= pos(SELECT_STATEMENT, aCommand);
  fromPos:= pos(FROM_STATEMENT, aCommand);

  if not ((selectPos <> 0) and (fromPos <> 0)) then begin
    result:= '';
    exit;
  end else begin
    result:= aCommand;
  end;


  delStartIndex:= selectPos + length(SELECT_STATEMENT);

  system.delete(result, delStartIndex, fromPos - delStartIndex);
  system.insert(format(' %s(1) ', [COUNT_STATEMENT]), result, delStartIndex);
end;

function cSQLiteCommandsBuilder.getCTESelectCommand(const aCTEName: string; aWorkTableParams: sSQLCTEWorkTableParams; aIntermediateTableParams: sSQLCTEIntermediateTableParams; aResultTableParams: sSQLCTEResultTableParams): string;
begin
  raise eSQLiteCommandsBuilder.create(METHOD_DOES_NOT_SUPPORTED);
end;

function cSQLiteCommandsBuilder.getDefaultInsertCommand(const aTable, aReturningFields: string): string;
begin
  result:= format(DEFAULT_INSERT_COMMAND_TEMPLATE, [aTable]);

  if (aReturningFields <> '') then begin
    result:= format('%s %s %s', [result, RETURNING_CLAUSE, aReturningFields]);
  end;

end;

function cSQLiteCommandsBuilder.getDeleteCommand(const aTable, aCondition: string): string;
begin
  result:= format(DELETE_COMMAND_TEMPLATE, [aTable, aCondition]);
end;

function cSQLiteCommandsBuilder.getInsertCommand(const aTable, aFields, aValues: string; const aReturningFields: string): string;
begin
  result:= format(INSERT_COMMAND_TEMPLATE, [aTable, aFields, aValues]);

  if (aReturningFields <> '') then begin
    result:= format('%s %s %s', [result, RETURNING_CLAUSE, aReturningFields]);
  end;

end;

function cSQLiteCommandsBuilder.getSelectCommand(const aSelectCommand: string; const aCondition: string; const aOrder: string): string;
var
  newCondition: string;
begin
  newCondition:= aCondition;

  if newCondition = '' then begin
    newCondition:= '1=1';
  end;


  result:= format(SELECT_COMMAND_TEMPLATE,
    [
      aSelectCommand,
      newCondition
    ]
  );

  if (aOrder <> '') then begin
    result:= format('%s %s', [result, format(ORDER_BY_COMMAND_TEMPLATE, [aOrder])]);
  end;
end;

function cSQLiteCommandsBuilder.getSelectCommandLimited(const aSelectCommand: string; aLimit, aOffset: integer): string;
begin
  result:= aSelectCommand;

  if (aLimit <> NO_CONSIDER_LIMIT) then
    result:= format('%s limit %d', [result, aLimit]);

  if (aOffset <> NO_CONSIDER_OFFSET) then
    result:= format('%s offset %d', [result, aOffset]);
end;

function cSQLiteCommandsBuilder.getUpdateCommand(const aTable, aFieldValues, aCondition: string): string;
begin
  result:= format('update %s set %s where %s', [aTable, aFieldValues, aCondition]);
end;

end.
