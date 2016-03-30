unit clsSQLDatapoints;

interface
uses
  windows,
  sysUtils,
  syncObjs,

  uSQLDrivers,

  clsException,
  clsLists,
  clsSQLConnectionsFactory,
  clsAbstractSQLConnection;

type

  eSQLDataPoints = class(cException);

  //singleton
  //thread-safe

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Singleton класс, хранящий в себе абстрактные точки данных - соединения
  ///	  с БД. В классе существует текущее выбранное соединение, которое может
  ///	  быть использовано в проекте.
  ///	</summary>
  ///	<example>
  ///	  <para>
  ///	    var
  ///	  </para>
  ///	  <para>
  ///	      SQLDatapoints: cSQLDatapoints
  ///	  </para>
  ///	  <para>
  ///	    begin
  ///	  </para>
  ///	  <para>
  ///	      SQLDatapoints:= cSQLDatapoints.getInstance;
  ///	  </para>
  ///	  <para>
  ///	      demoDB:= SQLDatapoints.createConnection(drvPGSQL, 'demo');
  ///	  </para>
  ///	  <para>
  ///	      demoDB.setDatabase('demo');
  ///	  </para>
  ///	  <para>
  ///	      demoDB.setHost('127.0.0.1');
  ///	  </para>
  ///	  <para>
  ///	      demoDB.setPort(5432);
  ///	  </para>
  ///	  <para>
  ///	      demoDB.setUserName('user');
  ///	  </para>
  ///	  <para>
  ///	      demoDB.setPassword('password');
  ///	  </para>
  ///	  <para>
  ///	      demoDB.open;
  ///	  </para>
  ///	  <para>
  ///	    end;
  ///	  </para>
  ///	</example>
  {$ENDREGION}
  cSQLDatapoints = class
  private
    const
    CONNECTION_ALREADY_EXISTS = 'connection with name: %s already exists';
  private
    fCS                : tCriticalSection;
    fCurrentConnection : cAbstractSQLConnection;

    fList               : cList;

    procedure   add(aItem: cAbstractSQLConnection);
    function    indexOfName(aName: string): integer;

    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cAbstractSQLConnection;

    property    items[aIndex: integer]: cAbstractSQLConnection read getItemByIndex;

  public
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает текущий экземпляр класса.
    ///	</summary>
    {$ENDREGION}
    class function  getInstance: cSQLDatapoints;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод устанавливает текущее соединение. В метод в качестве параметра
    ///	  можно передать экземпляр класса SQL соединения, которое было создано
    ///	  через метод createConnection
    ///	</summary>
    ///	<param name="aItem">
    ///	  Экземпляр класса SQL соединения
    ///	</param>
    {$ENDREGION}
    procedure   setCurrentConnection(aItem: cAbstractSQLConnection);

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает текущее SQL соединение
    ///	</summary>
    {$ENDREGION}
    function    getCurrentConnection: cAbstractSQLConnection;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод проверяет было ли создано SQL соединения с заданным именем
    ///	</summary>
    ///	<param name="aName">
    ///	  Имя SQL соединения
    ///	</param>
    {$ENDREGION}
    function    exists(aName: string): boolean;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод создает и добавляет SQL соединение в свой список для заданного 
    ///	  SQL драйвера, с заданным  именем. Для созданного SQL соединения нет
    ///	  необходимости явно вызывать деструктор, он будет вызван автоматически
    ///	  во время разрушения экземпляра класса cSQLDatapoints. При вызове
    ///	  этого метода, после создания SQL соединения текущим будет созданное
    ///	  SQL соединение.
    ///	</summary>
    {$ENDREGION}
    function    createConnection(aDriver: tSQLDriver; aName: string): cAbstractSQLConnection;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает ранее созданное SQL соединение с заданным именем.
    ///	  Если для заданного имени SQL соединение не найдено, метод вернет nil.
    ///	</summary>
    {$ENDREGION}
    function    getConnection(aName: string): cAbstractSQLConnection;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Конструктор класса
    ///	</summary>
    {$ENDREGION}
    constructor create;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Деструктор класса
    ///	</summary>
    {$ENDREGION}
    destructor  destroy; override;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает количество созданных точек данных
    ///	</summary>
    {$ENDREGION}
    property    count: integer read getCount;
  end;

implementation
uses
  clsSingleton;

{ cSQLDatapoints }

constructor cSQLDatapoints.create;
begin
  inherited create;
  fCS   := tCriticalSection.create;

  fList := cList.create;
end;

destructor cSQLDatapoints.destroy;
begin
  if (assigned(fList)) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  if (assigned(fCS)) then begin
    freeAndNil(fCS);
  end;

  inherited;
end;

procedure cSQLDatapoints.add(aItem: cAbstractSQLConnection);
begin
  fList.add(aItem);

  setCurrentConnection(aItem);
end;

function cSQLDatapoints.createConnection(aDriver: tSQLDriver; aName: string): cAbstractSQLConnection;
begin
  result:= nil;

  if (exists(aName)) then begin
    raise eSQLDataPoints.createFmt(CONNECTION_ALREADY_EXISTS, [aName]);
  end;

  fCS.enter;
  try
    result:= cSQLConnectionFactory.createNew(aDriver, aName);
    add(result);
  finally
    fCS.leave;
  end;
end;

function cSQLDatapoints.exists(aName: string): boolean;
begin
  result:= false;

  fCS.enter;
  try
    result:= indexOfName(aName) <> -1;
  finally
    fCS.leave;
  end;
end;

function cSQLDatapoints.getConnection(aName: string): cAbstractSQLConnection;
var
  foundIndex: integer;
begin
  result:= nil;

  fCS.enter;
  try

    foundIndex:= indexOfName(aName);

    if (foundIndex = -1) then begin
      exit;
    end;

    result:= items[foundIndex];

  finally
    fCS.leave;
  end;
end;

function cSQLDatapoints.getCount: integer;
begin
  result:= fList.count;
end;

function cSQLDatapoints.getCurrentConnection: cAbstractSQLConnection;
begin
  result:= fCurrentConnection;
end;

class function cSQLDatapoints.getInstance: cSQLDatapoints;
begin
  result:= cSingleton.getInstance<cSQLDatapoints>;
end;

function cSQLDatapoints.getItemByIndex(aIndex: integer): cAbstractSQLConnection;
begin
  result:= fList.items[aIndex];
end;

function cSQLDatapoints.indexOfName(aName: string): integer;
var
  i: integer;
begin
  result:= -1;

  for i:= 0 to count - 1 do begin
    if (lowerCase(items[i].getName) = lowerCase(aName)) then begin
      result:= i;
      exit;
    end;

  end;

end;

procedure cSQLDatapoints.setCurrentConnection(aItem: cAbstractSQLConnection);
begin
  fCurrentConnection:= aItem;
end;

end.
