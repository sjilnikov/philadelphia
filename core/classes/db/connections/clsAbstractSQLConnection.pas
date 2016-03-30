unit clsAbstractSQLConnection;

interface
uses
  types,
  classes,
  uSQLDrivers,

  clsDebug;

type
  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Структура, хранящая в себе информацию о SQL соединении
  ///	</summary>
  {$ENDREGION}
  sSQLConnectionInfo = record

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Драйвер
    ///	</summary>
    {$ENDREGION}
    driver   : tSQLDriver;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Имя базы данных
    ///	</summary>
    {$ENDREGION}
    database : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Имя пользователя
    ///	</summary>
    {$ENDREGION}
    userName : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Пароль
    ///	</summary>
    {$ENDREGION}
    password : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Хост
    ///	</summary>
    {$ENDREGION}
    host     : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Порт
    ///	</summary>
    {$ENDREGION}
    port     : word;
  end;

  cAbstractSQLConnection = class;

  tAbstractSQLConnectionDisconnectedEvent = procedure (aSender: cAbstractSQLConnection) of object;
  tAbstractSQLConnectionConnectedEvent = procedure (aSender: cAbstractSQLConnection) of object;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Класс, описывающий абстрактное SQL соединение
  ///	</summary>
  {$ENDREGION}
  cAbstractSQLConnection = class
  private
    fConnectionInfo  : sSQLConnectionInfo;
    fName            : string;
    fLastError       : string;

    fOnDisconnected  : tAbstractSQLConnectionDisconnectedEvent;
    fOnConnected     : tAbstractSQLConnectionConnectedEvent;

  protected
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод устанавливает SQL драйвер
    ///	</summary>
    ///	<param name="aSQLDriver">
    ///	  SQL драйвер
    ///	</param>
    {$ENDREGION}
    procedure   setDriver(aSQLDriver: tSQLDriver);
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод устанавливает описание последней ошибки
    ///	</summary>
    ///	<param name="aValue">
    ///	  Строка - описание последней ошибки
    ///	</param>
    {$ENDREGION}
    procedure   setLastError(aValue: string);

    //for events
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод - слот, вызывается когда установлено соединение с БД
    ///	</summary>
    {$ENDREGION}
    procedure   connected;
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод - слот, вызывается когда соединение с БД разъединено
    ///	</summary>
    {$ENDREGION}
    procedure   disconnected;
  public
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод тестирует соединение с БД. В случае неудачи ответственность за
    ///	  дальнейшие действия берет на себя производный класс
    ///	</summary>
    {$ENDREGION}
    function    testConnection: boolean; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод возвращает описание последней ошибки
    ///	</summary>
    {$ENDREGION}
    function    getLastError: string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод начинает транзакцию в БД, если это позволяет драйвер, в
    ///	  противном случае никаких действий не происходит
    ///	</summary>
    {$ENDREGION}
    procedure   beginTransaction; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод завершает транзакцию в БД, если это позволяет драйвер, в
    ///	  противном случае никаких действий не происходит
    ///	</summary>
    {$ENDREGION}
    procedure   commitTransaction; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод откатывает начатую транзакцию в БД, если это позволяет драйвер,
    ///	  в противном случае никаких действий не происходит
    ///	</summary>
    {$ENDREGION}
    procedure   rollbackTransaction; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод заполняет переданный stringList значениями - каталогами (базами)
    ///	</summary>
    ///	<param name="aList">
    ///	  StringList который будет заполнен значениями
    ///	</param>
    {$ENDREGION}
    procedure   getCatalogNames(aList: tStrings); virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод заполняет переданный stringList значениями - схемами текущей
    ///	  базы
    ///	</summary>
    ///	<param name="aList">
    ///	  StringList который будет заполнен значениями
    ///	</param>
    {$ENDREGION}
    procedure   getSchemaNames(aList: tStrings); virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод заполняет переданный stringList значениями - таблицами текущей
    ///	  базы для заданного шаблона имен таблиц
    ///	</summary>
    ///	<param name="aPattern">
    ///	  Шаблон для таблиц
    ///	</param>
    ///	<param name="aList">
    ///	  StringList который будет заполнен значениями
    ///	</param>
    {$ENDREGION}
    procedure   getTableNames(const aPattern: string; aList: tStrings); overload; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод заполняет переданный stringList значениями - таблицами текущей
    ///	  базы для заданного шаблона имен таблиц и схемы
    ///	</summary>
    ///	<param name="aTablePattern">
    ///	  Шаблон для таблиц
    ///	</param>
    ///	<param name="aSchemaPattern">
    ///	  Шаблон для схем
    ///	</param>
    ///	<param name="aList">
    ///	  StringList который будет заполнен значениями
    ///	</param>
    {$ENDREGION}
    procedure   getTableNames(const aTablePattern: string; const aSchemaPattern: string; aList: tStrings); overload; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод заполняет переданный stringList значениями - таблицами текущей
    ///	  базы для заданного шаблона имен таблиц, схемы и типов
    ///	</summary>
    ///	<param name="aTablePattern">
    ///	  Шаблон для таблиц
    ///	</param>
    ///	<param name="aSchemaPattern">
    ///	  Шаблон для схем
    ///	</param>
    ///	<param name="aTypes">
    ///	  Типы (например: 'TABLE', 'VIEW', 'INDEX', 'SEQUENCE')
    ///	</param>
    ///	<param name="aList">
    ///	  StringList который будет заполнен значениями
    ///	</param>
    {$ENDREGION}
    procedure   getTableNames(const aTablePattern:string; const aSchemaPattern: string; aTypes: tStringDynArray; aList: tStrings); overload; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод заполняет переданный stringList значениями - колонками для
    ///	  переданной таблицы
    ///	</summary>
    ///	<param name="aTablePattern">
    ///	  Шаблон для таблиц
    ///	</param>
    ///	<param name="aList">
    ///	  StringList который будет заполнен значениями
    ///	</param>
    {$ENDREGION}
    procedure   getColumnNames(const aTablePattern: string; aList: tStrings); overload; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод заполняет переданный stringList значениями - колонками для
    ///	  переданной таблицы и шаблоном для колонок
    ///	</summary>
    ///	<param name="aTablePattern">
    ///	  Шаблон для таблиц
    ///	</param>
    ///	<param name="aColumnPattern">
    ///	  Шаблон для колонок
    ///	</param>
    ///	<param name="aList">
    ///	  StringList который будет заполнен значениями
    ///	</param>
    {$ENDREGION}
    procedure   getColumnNames(const aTablePattern: string; const aColumnPattern: string; aList: tStrings); overload; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод заполняет переданный stringList значениями - именами хранимых
    ///	  процедур для заданного шаблона
    ///	</summary>
    ///	<param name="aPattern">
    ///	  Шаблон для имен процедур
    ///	</param>
    ///	<param name="aList">
    ///	  StringList который будет заполнен значениями
    ///	</param>
    {$ENDREGION}
    procedure   getStoredProcNames(const aPattern: string; aList: tStrings); virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод копирует свойства передданого SQL соединения
    ///	</summary>
    ///	<param name="aConnection">
    ///	  SQL соединение
    ///	</param>
    {$ENDREGION}
    procedure   assign(aConnection: cAbstractSQLConnection); virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Метод открывает SQL соединение
    ///	</summary>
    {$ENDREGION}
    function    open: boolean; virtual; abstract;
    function    close: boolean; virtual; abstract;

    //returns rowsAffected
    function    execute(const aCommand: string): integer; virtual;
    function    isConnected: boolean; virtual; abstract;

    function    getDataBaseName: string;

    procedure   setDatabase(aDatabase: string);
    procedure   setUserName(aUserName: string);
    procedure   setPassword(aPassword: string);
    procedure   setPort(aPort: word);
    procedure   setHost(aHost: string);

    function    getName: string;

    procedure   addOption(aOption: string); virtual; abstract;
    function    getOptions: tStrings; virtual; abstract;
    procedure   clearOptions; virtual; abstract;

    constructor create(aName: string);

  published
    property    connectionInfo: sSQLConnectionInfo read fConnectionInfo;

    property    onConnected: tAbstractSQLConnectionConnectedEvent read fOnConnected write fOnConnected;
    property    onDisconnected: tAbstractSQLConnectionDisconnectedEvent read fOnDisconnected write fOnDisconnected;
  end;

implementation

{ cAbstractSQLConnection }

procedure cAbstractSQLConnection.assign(aConnection: cAbstractSQLConnection);
var
  i: integer;
begin
  if (not assigned(aConnection)) then begin
    exit;
  end;

  setDriver(aConnection.connectionInfo.driver);

  setDatabase(aConnection.connectionInfo.database);
  setUserName(aConnection.connectionInfo.userName);
  setPassword(aConnection.connectionInfo.password);
  setPort(aConnection.connectionInfo.port);
  setHost(aConnection.connectionInfo.host);

  clearOptions;
  for i:= 0 to aConnection.getOptions.count - 1 do begin
    addOption(aConnection.getOptions[i]);
  end;
end;

procedure cAbstractSQLConnection.connected;
begin
  if assigned(fOnConnected) then begin
    fOnConnected(self);
  end;
end;

constructor cAbstractSQLConnection.create(aName: string);
begin
  inherited create;
  fName:= aName;

  fConnectionInfo.userName:= '';
  fConnectionInfo.password:= '';
  fConnectionInfo.host:= '';
  fConnectionInfo.port:= 0;
end;

procedure cAbstractSQLConnection.disconnected;
begin
  if assigned(fOnDisconnected) then begin
    fOnDisconnected(self);
  end;
end;

function cAbstractSQLConnection.execute(const aCommand: string): integer;
begin
  cDebug.write('cSQLConnectionBase.execute: executing SQL command: %s', [aCommand]);
end;

procedure cAbstractSQLConnection.getColumnNames(const aTablePattern: string; aList: tStrings);
begin
  getColumnNames(aTablePattern, '', aList);
end;

function cAbstractSQLConnection.getName: string;
begin
  result:= fName;
end;

procedure cAbstractSQLConnection.getTableNames(const aPattern: string; aList: tStrings);
begin
  getTableNames('', aPattern, nil, aList);
end;

procedure cAbstractSQLConnection.getTableNames(const aTablePattern, aSchemaPattern: string; aList: tStrings);
begin
  getTableNames(aTablePattern, aSchemaPattern, nil, aList);
end;

procedure cAbstractSQLConnection.setDatabase(aDatabase: string);
begin
  fConnectionInfo.database:= aDatabase;
end;

procedure cAbstractSQLConnection.setDriver(aSQLDriver: tSQLDriver);
begin
  fConnectionInfo.driver:= aSQLDriver;
end;

procedure cAbstractSQLConnection.setHost(aHost: string);
begin
  fConnectionInfo.host:= aHost;
end;

procedure cAbstractSQLConnection.setLastError(aValue: string);
begin
  fLastError:= aValue;
end;

procedure cAbstractSQLConnection.setPassword(aPassword: string);
begin
  fConnectionInfo.password:= aPassword;
end;

procedure cAbstractSQLConnection.setPort(aPort: word);
begin
  fConnectionInfo.port:= aPort;
end;

procedure cAbstractSQLConnection.setUserName(aUserName: string);
begin
  fConnectionInfo.userName:= aUserName;
end;

function cAbstractSQLConnection.getLastError: string;
begin
  result:= fLastError;
end;

function cAbstractSQLConnection.getDataBaseName: string;
begin
  result:= fConnectionInfo.database;
end;

end.
