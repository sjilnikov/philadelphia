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
  ///	  Структура, описывающая рабочую таблицу для CTE конструкции
  ///	</summary>
  {$ENDREGION}
  sSQLCTEWorkTableParams = record

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  SQL запрос, содержащий команду select
    ///	</summary>
    {$ENDREGION}
    selectCommand : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  условие без where
    ///	</summary>
    ///	<example>
    ///	  1=1
    ///	</example>
    {$ENDREGION}
    condition     : string;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Структура, описывабщая таблицу - посредника в CTE конструкции
  ///	</summary>
  {$ENDREGION}
  sSQLCTEIntermediateTableParams = record
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  SQL запрос, содержащий команду select
    ///	</summary>
    {$ENDREGION}
    selectCommand : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  условие без where
    ///	</summary>
    ///	<example>
    ///	  1=1
    ///	</example>
    {$ENDREGION}
    condition     : string;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Структура, описывающая результирующую таблицу в CTE конструкции
  ///	</summary>
  {$ENDREGION}
  sSQLCTEResultTableParams = record
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  SQL запрос, содержащий команду select
    ///	</summary>
    {$ENDREGION}
    selectCommand : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  условие без where
    ///	</summary>
    ///	<example>
    ///	  1=1
    ///	</example>
    {$ENDREGION}
    condition     : string;
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Поля участвующие в сортировке
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
  ///	  Абстрактный класс построения SQL команд
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
    ///	  Метод возвращает SQL insert команду
    ///	</summary>
    ///	<param name="aTable">
    ///	  Таблица в БД
    ///	</param>
    ///	<param name="aFields">
    ///	  Список полей через ","
    ///	</param>
    ///	<param name="aValues">
    ///	  Список значений для полей через ","
    ///	</param>
    ///	<param name="aReturningFields">
    ///	  Список полей, значения которых будут возвращены после выполения SQL
    ///	  запроса
    ///	</param>
    ///	<remarks>
    ///	  Количество полей должно совпадать с количеством значений переданных в
    ///	  метод
    ///	</remarks>
    ///	<example>
    ///	  getInsertCommand('table', 'name', '''имя''', 'id');
    ///	</example>
    {$ENDREGION}
    function    getInsertCommand(const aTable: string; const aFields: string; const aValues: string; const aReturningFields: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL insert команду по умолчанию, т.е. когда во
    ///	  вставке не участвуют никакие поля
    ///	</summary>
    ///	<param name="aTable">
    ///	  Таблица в БД
    ///	</param>
    ///	<param name="aReturningFields">
    ///	  Список полей, значения которых будут возвращены после выполения SQL
    ///	  запроса
    ///	</param>
    ///	<remarks>
    ///	  getDefaultInsertCommand('table', 'id');
    ///	</remarks>
    {$ENDREGION}
    function    getDefaultInsertCommand(const aTable: string; const aReturningFields: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL update команду
    ///	</summary>
    ///	<param name="aTable">
    ///	  Таблица в БД
    ///	</param>
    ///	<param name="aFieldValues">
    ///	  Имена и значения полей, разделенные "="
    ///	</param>
    ///	<param name="aCondition">
    ///	  Условие без where
    ///	</param>
    ///	<example>
    ///	  getUpdateCommand('table', 'name=''test''', 'id=10')
    ///	</example>
    {$ENDREGION}
    function    getUpdateCommand(const aTable: string; const aFieldValues: string; const aCondition: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL delete команду
    ///	</summary>
    ///	<param name="aTable">
    ///	  Таблица в БД
    ///	</param>
    ///	<param name="aCondition">
    ///	  Условие без where
    ///	</param>
    ///	<example>
    ///	  getDeleteCommand('table', 'id=10');
    ///	</example>
    {$ENDREGION}
    function    getDeleteCommand(const aTable: string; const aCondition: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL select команду
    ///	</summary>
    ///	<param name="aTable">
    ///	  Таблица в БД
    ///	</param>
    ///	<param name="aFields">
    ///	  Список полей через ","
    ///	</param>
    ///	<param name="aCondition">
    ///	  Условие без where
    ///	</param>
    ///	<param name="aOrder">
    ///	  Список полей, участвующих в сортировке
    ///	</param>
    ///	<example>
    ///	  getSelectCommand('table', 'id,name', 'id&gt;10', 'name');
    ///	</example>
    {$ENDREGION}
    function    getSelectCommand(const aTable: string; const aFields: string; const aCondition: string; const aOrder: string): string; overload; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL select команду
    ///	</summary>
    ///	<param name="aSelectCommand">
    ///	  SQL select команда, до "where"
    ///	</param>
    ///	<param name="aCondition">
    ///	  Условие без where
    ///	</param>
    ///	<param name="aOrder">
    ///	  Список полей, участвующих в сортировке
    ///	</param>
    ///	<example>
    ///	  getSelectCommand('select id,name', 'id&gt;0', 'name');
    ///	</example>
    {$ENDREGION}
    function    getSelectCommand(const aSelectCommand: string; const aCondition: string; const aOrder: string): string; overload; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL select команду, ограниченную начальной позицией
    ///	  и количеством выбираемых строк
    ///	</summary>
    ///	<param name="aSelectCommand">
    ///	  SQL select команда
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
    ///	  Метод возвращает SQL select команду, которая вычисляет количество
    ///	  строк в SQL select команде
    ///	</summary>
    ///	<param name="aCommand">
    ///	  SQL select команда
    ///	</param>
    ///	<example>
    ///	  getCountCommand('select * from clients');
    ///	</example>
    {$ENDREGION}
    function    getCountCommand(const aCommand: string): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL select команду, которая содержит агрегатные
    ///	  выражения переданных полей и агрегатных типов, для переданной SQL
    ///	  команды 
    ///	</summary>
    ///	<param name="aCommand">
    ///	  SQL команда, по которой необходимо построить агрегатную команду
    ///	</param>
    ///	<param name="aFieldNames">
    ///	  Список полей, которые будут участвовать в агрегации
    ///	</param>
    ///	<param name="aAggregateFieldsType">
    ///	  Массив агрегатных типов для полей
    ///	</param>
    ///	<remarks>
    ///	  Количество переданных полей должно совпадать с количеством элементов
    ///	  в массиве агрегатных типов
    ///	</remarks>
    ///	<example>
    ///	  getAggregateCommand('select id,name from clients', 'id', [aftCount]);
    ///	</example>
    {$ENDREGION}
    function    getAggregateCommand(const aCommand: string; const aFieldNames: string; aAggregateFieldsType: cAggregateFieldTypes): string; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL select команду, содержащую дополнительное поле, 
    ///	  которое добавляется вначало SQL команды. 
    ///	</summary>
    ///	<param name="aCommand">
    ///	  SQL select команда
    ///	</param>
    ///	<param name="aField">
    ///	  Добавляемое поле
    ///	</param>
    ///	<example>
    ///	  addFieldToSelectBefore('select name from clients', 'id');
    ///	</example>
    {$ENDREGION}
    function    addFieldToSelectBefore(const aCommand: string; const aField: string): string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL select команду, в условие которой добавляется
    ///	  другое условие и объединяется нужным оператором
    ///	</summary>
    ///	<param name="aBaseCondition">
    ///	  Первый набор условий
    ///	</param>
    ///	<param name="aAddingCondition">
    ///	  Второй набор условий
    ///	</param>
    ///	<param name="aOperator">
    ///	  Оператор объединения условий
    ///	</param>
    ///	<example>
    ///	  addToCondition('id&gt;0', 'name = ''client1''', coAnd);
    ///	</example>
    {$ENDREGION}
    function    addToCondition(const aBaseCondition: string; const aAddingCondition: string; aOperator: tAbstractSQLCommandsBuilderConditionOperators): string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL select команду, в которой был заменен список
    ///	  полей
    ///	</summary>
    ///	<param name="aCommand">
    ///	  SQL select команда
    ///	</param>
    ///	<param name="aReplaceString">
    ///	  Список полей, на которые будет заменен список полей в существующей
    ///	  SQL select команде
    ///	</param>
    ///	<example>
    ///	  replaceFieldInSelectCommand('select id,name from clients', 'name');
    ///	</example>
    {$ENDREGION}
    function    replaceFieldInSelectCommand(const aCommand: string; const aReplaceString: string): string; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает SQL select команду, которая содержит CTE конструкцию
    ///	</summary>
    ///	<param name="aCTEName">
    ///	  Имя CTE конструкции
    ///	</param>
    ///	<param name="aWorkTableParams">
    ///	  Структура содержащая информацию о рабочей таблице
    ///	</param>
    ///	<param name="aIntermediateTableParams">
    ///	  Структура содержащая информацию о таблице - посреднике
    ///	</param>
    ///	<param name="aResultTableParams">
    ///	  Структура содержащая информацию о результирующей таблице
    ///	</param>
    ///	<example>
    ///	  <para>
    ///	    workTable.selectCommand:= 'select tree.id, tree.parent_id,
    ///	    tree.name from tree';
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
    ///	     getCTESelectCommand('cte', workTable, intermediateTable,
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

