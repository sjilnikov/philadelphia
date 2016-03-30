unit clsAbstractSQLCommandsBuilder;

interface
uses
  sysUtils,

  uModels,
  clsException,
  clsStringUtils;

type
  {$REGION 'Documentation'}
  ///	<summary>
  ///	  ���������, ����������� ������� ������� ��� CTE �����������
  ///	</summary>
  {$ENDREGION}
  sSQLCTEWorkTableParams = record

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  SQL ������, ���������� ������� select
    ///	</summary>
    {$ENDREGION}
    selectCommand : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ������� ��� where
    ///	</summary>
    ///	<example>
    ///	  1=1
    ///	</example>
    {$ENDREGION}
    condition     : string;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  ���������, ����������� ������� - ���������� � CTE �����������
  ///	</summary>
  {$ENDREGION}
  sSQLCTEIntermediateTableParams = record
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  SQL ������, ���������� ������� select
    ///	</summary>
    {$ENDREGION}
    selectCommand : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ������� ��� where
    ///	</summary>
    ///	<example>
    ///	  1=1
    ///	</example>
    {$ENDREGION}
    condition     : string;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  ���������, ����������� �������������� ������� � CTE �����������
  ///	</summary>
  {$ENDREGION}
  sSQLCTEResultTableParams = record
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  SQL ������, ���������� ������� select
    ///	</summary>
    {$ENDREGION}
    selectCommand : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ������� ��� where
    ///	</summary>
    ///	<example>
    ///	  1=1
    ///	</example>
    {$ENDREGION}
    condition     : string;
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ���� ����������� � ����������
    ///	</summary>
    {$ENDREGION}
    order         : string;
  end;

  cAbstractSQLCommandsBuilder = class;

  tSetSelectCommandEvent = function(aCommandBuilder: cAbstractSQLCommandsBuilder; const aSelectCommand: string; const aCondition: string; const aOrder: string): string of object;
  tGetSelectCommandLimitedEvent = function(const aSelectCommand: string; aLimit: integer; aOffset: integer): string of object;

  tAbstractSQLCommandsBuilderConditionOperators = (coAnd, coOr);

  eAbstractSQLCommandsBuilder = class(cException);

  ///	<summary>
  ///	  ����������� ����� ���������� SQL ������
  ///	</summary>
  cAbstractSQLCommandsBuilder = class
  private
    const
    METHOD_NOT_SUPPORTED          = 'method not supported';
  protected
    procedure    raiseMethodNotSupported;
  public
    const

    COUNT_STATEMENT                 = 'count';
    SUM_STATEMENT                   = 'sum';
    AVERAGE_STATEMENT               = 'avg';

    SELECT_STATEMENT                = 'select';
    DISTINCT_STATEMENT              = 'distinct';
    FROM_STATEMENT                  = 'from';
    RETURNING_CLAUSE                = 'returning';

    PURE_SELECT_COMMAND_TEMPLATE    = SELECT_STATEMENT + ' %s from %s';
    SELECT_COMMAND_TEMPLATE         = '%s where %s';
    ORDER_BY_COMMAND_TEMPLATE       = 'order by %s';
    INSERT_COMMAND_TEMPLATE         = 'insert into %s(%s) values(%s)';
    DEFAULT_INSERT_COMMAND_TEMPLATE = 'insert into %s default values';
    UPDATE_COMMAND_TEMPLATE         = 'update %s set %s where %s';
    DELETE_COMMAND_TEMPLATE         = 'delete from %s where %s';

  public
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL insert �������
    ///	</summary>
    ///	<param name="aTable">
    ///	  ������� � ��
    ///	</param>
    ///	<param name="aFields">
    ///	  ������ ����� ����� ","
    ///	</param>
    ///	<param name="aValues">
    ///	  ������ �������� ��� ����� ����� ","
    ///	</param>
    ///	<param name="aReturningFields">
    ///	  ������ �����, �������� ������� ����� ���������� ����� ��������� SQL
    ///	  �������
    ///	</param>
    ///	<remarks>
    ///	  ���������� ����� ������ ��������� � ����������� �������� ���������� �
    ///	  �����
    ///	</remarks>
    ///	<example>
    ///	  getInsertCommand('table', 'name', '''���''', 'id');
    ///	</example>
    {$ENDREGION}
    function    getInsertCommand(const aTable: string; const aFields: string; const aValues: string; const aReturningFields: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL insert ������� �� ���������, �.�. ����� ��
    ///	  ������� �� ��������� ������� ����
    ///	</summary>
    ///	<param name="aTable">
    ///	  ������� � ��
    ///	</param>
    ///	<param name="aReturningFields">
    ///	  ������ �����, �������� ������� ����� ���������� ����� ��������� SQL
    ///	  �������
    ///	</param>
    ///	<remarks>
    ///	  getDefaultInsertCommand('table', 'id');
    ///	</remarks>
    {$ENDREGION}
    function    getDefaultInsertCommand(const aTable: string; const aReturningFields: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL�update �������
    ///	</summary>
    ///	<param name="aTable">
    ///	  ������� � ��
    ///	</param>
    ///	<param name="aFieldValues">
    ///	  ����� � �������� �����, ����������� "="
    ///	</param>
    ///	<param name="aCondition">
    ///	  ������� ��� where
    ///	</param>
    ///	<example>
    ///	  getUpdateCommand('table', 'name=''test''', 'id=10')
    ///	</example>
    {$ENDREGION}
    function    getUpdateCommand(const aTable: string; const aFieldValues: string; const aCondition: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL�delete �������
    ///	</summary>
    ///	<param name="aTable">
    ///	  ������� � ��
    ///	</param>
    ///	<param name="aCondition">
    ///	  ������� ��� where
    ///	</param>
    ///	<example>
    ///	  getDeleteCommand('table', 'id=10');
    ///	</example>
    {$ENDREGION}
    function    getDeleteCommand(const aTable: string; const aCondition: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL�select �������
    ///	</summary>
    ///	<param name="aTable">
    ///	  ������� � ��
    ///	</param>
    ///	<param name="aFields">
    ///	  ������ ����� ����� ","
    ///	</param>
    ///	<param name="aCondition">
    ///	  ������� ��� where
    ///	</param>
    ///	<param name="aOrder">
    ///	  ������ �����, ����������� � ����������
    ///	</param>
    ///	<example>
    ///	  getSelectCommand('table', 'id,name', 'id&gt;10', 'name');
    ///	</example>
    {$ENDREGION}
    function    getSelectCommand(const aTable: string; const aFields: string; const aCondition: string; const aOrder: string): string; overload; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL select �������
    ///	</summary>
    ///	<param name="aSelectCommand">
    ///	  SQL select �������,��� "where"
    ///	</param>
    ///	<param name="aCondition">
    ///	  ������� ��� where
    ///	</param>
    ///	<param name="aOrder">
    ///	  ������ �����, ����������� � ����������
    ///	</param>
    ///	<example>
    ///	  getSelectCommand('select id,name', 'id&gt;0', 'name');
    ///	</example>
    {$ENDREGION}
    function    getSelectCommand(const aSelectCommand: string; const aCondition: string; const aOrder: string): string; overload; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL select �������, ������������ ��������� ��������
    ///	  � ����������� ���������� �����
    ///	</summary>
    ///	<param name="aSelectCommand">
    ///	  SQL select �������
    ///	</param>
    ///	<param name="aLimit">
    ///	  10
    ///	</param>
    ///	<param name="aOffset">
    ///	  0
    ///	</param>
    ///	<example>
    ///	  getSelectCommandLimited('select * from clients', 10, 0);
    ///	</example>
    {$ENDREGION}
    function    getSelectCommandLimited(const aSelectCommand: string; aLimit: integer; aOffset: integer): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL select �������, ����������������� ����������
    ///	  ����� � SQL select �������
    ///	</summary>
    ///	<param name="aCommand">
    ///	  SQL select �������
    ///	</param>
    ///	<example>
    ///	  getCountCommand('select * from clients');
    ///	</example>
    {$ENDREGION}
    function    getCountCommand(const aCommand: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL select �������, ������� �������� ����������
    ///	  �������������������� ����� � ���������� �����, ��� ���������� SQL
    ///	  ��������
    ///	</summary>
    ///	<param name="aCommand">
    ///	  SQL �������, �� ������� ���������� ��������� ���������� �������
    ///	</param>
    ///	<param name="aFieldNames">
    ///	  ������ �����, ������� ����� ����������� � ���������
    ///	</param>
    ///	<param name="aAggregateFieldsType">
    ///	  ������ ���������� ����� ��� �����
    ///	</param>
    ///	<remarks>
    ///	  ���������� ���������� ����� ������ ��������� � ����������� ���������
    ///	  � ������� ���������� �����
    ///	</remarks>
    ///	<example>
    ///	  getAggregateCommand('select id,name from clients', 'id', [aftCount]);
    ///	</example>
    {$ENDREGION}
    function    getAggregateCommand(const aCommand: string; const aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL select �������, ���������� �������������� ����,�
    ///	  ������� ����������� ������� SQL �������.�
    ///	</summary>
    ///	<param name="aCommand">
    ///	  SQL select �������
    ///	</param>
    ///	<param name="aField">
    ///	  ����������� ����
    ///	</param>
    ///	<example>
    ///	  addFieldToSelectBefore('select name from clients', 'id');
    ///	</example>
    {$ENDREGION}
    function    addFieldToSelectBefore(const aCommand: string; const aField: string): string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL select �������, � ������� ������� �����������
    ///	  ������ ������� � ������������ ������ ����������
    ///	</summary>
    ///	<param name="aBaseCondition">
    ///	  ������ ������������
    ///	</param>
    ///	<param name="aAddingCondition">
    ///	  ������ ������������
    ///	</param>
    ///	<param name="aOperator">
    ///	  �������� ����������� �������
    ///	</param>
    ///	<example>
    ///	  addToCondition('id&gt;0', 'name = ''client1''', coAnd);
    ///	</example>
    {$ENDREGION}
    function    addToCondition(const aBaseCondition: string; const aAddingCondition: string; aOperator: tAbstractSQLCommandsBuilderConditionOperators): string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL select �������, � ������� ��� ������� ������
    ///	  �����
    ///	</summary>
    ///	<param name="aCommand">
    ///	  SQL select �������
    ///	</param>
    ///	<param name="aReplaceString">
    ///	  ������ �����, �� ������� ����� ������� ������ ����� � ������������
    ///	  SQL select �������
    ///	</param>
    ///	<example>
    ///	  replaceFieldInSelectCommand('select id,name from clients', 'name');
    ///	</example>
    {$ENDREGION}
    function    replaceFieldInSelectCommand(const aCommand: string; const aReplaceString: string): string; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� SQL select �������, ������� �������� CTE �����������
    ///	</summary>
    ///	<param name="aCTEName">
    ///	  ��� CTE �����������
    ///	</param>
    ///	<param name="aWorkTableParams">
    ///	  ��������� ���������� ���������� � ������� �������
    ///	</param>
    ///	<param name="aIntermediateTableParams">
    ///	  ��������� ���������� ���������� �������� - ����������
    ///	</param>
    ///	<param name="aResultTableParams">
    ///	  ��������� ���������� ���������� � �������������� �������
    ///	</param>
    ///	<example>
    ///	  <para>
    ///	    workTable.selectCommand:= 'select�tree.id, tree.parent_id,
    ///	    tree.name�from tree';
    ///	  </para>
    ///	  <para>
    ///	    workTable.condition:= 'tree.id&gt;0';
    ///	  </para>
    ///	  <para>
    ///	    intermediateTable.selectCommand:= 'select tree.id, tree.parent_id,
    ///	    tree.name from tree inner join cte on tree.parent_id = cte.id';
    ///	  </para>
    ///	  <para>
    ///	    intermediateTable.condition:= 'tree.id&gt;0';
    ///	  </para>
    ///	  <para>
    ///	    resultTable.selectCommand:= 'select distinct * from cte';
    ///	  </para>
    ///	  <para>
    ///	    resultTable.condition:= 'cte.parent_id = 0';
    ///	  </para>
    ///	  <para>
    ///	    resultTable.order:= 'cte.name';
    ///	  </para>
    ///	  <para>
    ///	    �getCTESelectCommand('cte', workTable, intermediateTable,
    ///	    resultTable);
    ///	  </para>
    ///	</example>
    {$ENDREGION}
    function    getCTESelectCommand(const aCTEName: string; aWorkTableParams: sSQLCTEWorkTableParams; aIntermediateTableParams: sSQLCTEIntermediateTableParams; aResultTableParams: sSQLCTEResultTableParams): string; virtual; abstract;
  end;

const
  SQLCommandsBuilderConditionOperatorsArr: array[low(tAbstractSQLCommandsBuilderConditionOperators)..high(tAbstractSQLCommandsBuilderConditionOperators)] of string = (
  'and',
  'or'
  );

implementation

{ cAbstractSQLCommandsBuilder }

function cAbstractSQLCommandsBuilder.addFieldToSelectBefore(const aCommand, aField: string): string;

  function getSelectCommandWithNewField(const aSelectCommand: string): string;
  var
    selectDistinctTemplate: string;
    selectTemplate: string;

    replaceTemplate: string;
  begin

    selectTemplate:= SELECT_STATEMENT;

    selectDistinctTemplate:=
      format('%s %s',
        [
          SELECT_STATEMENT,
          DISTINCT_STATEMENT
        ]
      );

    if (pos(selectDistinctTemplate, aSelectCommand) <> 0) then begin
      replaceTemplate:= selectDistinctTemplate;
    end else begin
      replaceTemplate:= selectTemplate;
    end;


    result:= stringReplace(
      aSelectCommand,
      replaceTemplate,
      format('%s %s,',
        [
          replaceTemplate,
          aField
        ]
      ), [rfIgnoreCase]);
  end;

var
  foundClosedIndex: integer;
  beforeSelect: string;
  selectCommand: string;
begin
  result:= '';
  if (pos(SELECT_STATEMENT, aCommand) = 1) then begin
    result:= getSelectCommandWithNewField(aCommand);
  end else begin
    foundClosedIndex:= cStringUtils.findClosingParenthesis(aCommand);
    if (foundClosedIndex <> 0) then begin
      beforeSelect:= copy(aCommand, 1, foundClosedIndex);

      selectCommand:= copy(aCommand, foundClosedIndex + 1, maxInt);
      selectCommand:= getSelectCommandWithNewField(selectCommand);

      result:= format('%s%s', [beforeSelect, selectCommand]);
    end;
  end;
end;

function cAbstractSQLCommandsBuilder.addToCondition(const aBaseCondition,  aAddingCondition: string; aOperator: tAbstractSQLCommandsBuilderConditionOperators): string;
begin
  result:= aBaseCondition;
  if (aBaseCondition = '') then begin
    result:= aAddingCondition;
  end else begin
    result:= format('(%s) %s (%s)', [aAddingCondition, SQLCommandsBuilderConditionOperatorsArr[aOperator], aBaseCondition]);
  end;
end;

function cAbstractSQLCommandsBuilder.getSelectCommand(const aTable, aFields, aCondition: string; const aOrder: string): string;
begin
  result:= getSelectCommand(format(PURE_SELECT_COMMAND_TEMPLATE, [aFields, aTable]), aCondition, aOrder);
end;

procedure cAbstractSQLCommandsBuilder.raiseMethodNotSupported;
begin
  raise eAbstractSQLCommandsBuilder.create(METHOD_NOT_SUPPORTED);
end;

function cAbstractSQLCommandsBuilder.replaceFieldInSelectCommand(const aCommand: string; const aReplaceString: string): string;
var
  selectStartIndex: integer;
  selectEndIndex: integer;

  selectCount: integer;

  i: integer;
  commandLength: integer;

  selectLen: integer;
  fromLen: integer;

  selectStmt: string;
  fromStmt: string;
begin
  result:= aCommand;

  selectStmt:= format('%s ', [SELECT_STATEMENT]);
  fromStmt:= format('%s ', [FROM_STATEMENT]);

  selectLen:= length(selectStmt);
  fromLen:= length(fromStmt);

  selectStartIndex:= -1;
  selectEndIndex:= -1;
  selectCount:= 0;

  commandLength:= length(aCommand);
  for i:= 1 to commandLength do begin

    if (copy(aCommand, i, selectLen) = selectStmt) then begin
      inc(selectCount);

      if (selectStartIndex = -1) then begin
        selectStartIndex:= i + selectLen;
      end;
    end;

    if (copy(aCommand, i, fromLen) = fromStmt) then begin
      dec(selectCount);

      if (selectCount = 0) and (selectEndIndex = -1) then begin
        selectEndIndex:= i - 1;
        break;
      end;
    end;
  end;

  if (selectStartIndex = -1) or (selectEndIndex = -1) then begin
    exit;
  end;

  delete(result, selectStartIndex, selectEndIndex - selectStartIndex);
  insert(aReplaceString, result, selectStartIndex);
end;

end.

