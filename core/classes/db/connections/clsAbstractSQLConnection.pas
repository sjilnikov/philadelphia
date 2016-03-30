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
  ///	  ���������, �������� � ���� ���������� � SQL ����������
  ///	</summary>
  {$ENDREGION}
  sSQLConnectionInfo = record

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  �������
    ///	</summary>
    {$ENDREGION}
    driver   : tSQLDriver;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ��� ���� ������
    ///	</summary>
    {$ENDREGION}
    database : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ��� ������������
    ///	</summary>
    {$ENDREGION}
    userName : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ������
    ///	</summary>
    {$ENDREGION}
    password : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����
    ///	</summary>
    {$ENDREGION}
    host     : string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����
    ///	</summary>
    {$ENDREGION}
    port     : word;
  end;

  cAbstractSQLConnection = class;

  tAbstractSQLConnectionDisconnectedEvent = procedure (aSender: cAbstractSQLConnection) of object;
  tAbstractSQLConnectionConnectedEvent = procedure (aSender: cAbstractSQLConnection) of object;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  �����, ����������� ����������� SQL ����������
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
    ///	  ����� ������������� SQL �������
    ///	</summary>
    ///	<param name="aSQLDriver">
    ///	  SQL �������
    ///	</param>
    {$ENDREGION}
    procedure   setDriver(aSQLDriver: tSQLDriver);
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ������������� �������� ��������� ������
    ///	</summary>
    ///	<param name="aValue">
    ///	  ������ - �������� ��������� ������
    ///	</param>
    {$ENDREGION}
    procedure   setLastError(aValue: string);

    //for events
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� - ����, ���������� ����� ����������� ���������� � ��
    ///	</summary>
    {$ENDREGION}
    procedure   connected;
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� - ����, ���������� ����� ���������� � �� �����������
    ///	</summary>
    {$ENDREGION}
    procedure   disconnected;
  public
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� ���������� � ��. � ������ ������� ��������������� ��
    ///	  ���������� �������� ����� �� ���� ����������� �����
    ///	</summary>
    {$ENDREGION}
    function    testConnection: boolean; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ���������� �������� ��������� ������
    ///	</summary>
    {$ENDREGION}
    function    getLastError: string;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� �������� ���������� � ��, ���� ��� ��������� �������, �
    ///	  ��������� ������ ������� �������� �� ����������
    ///	</summary>
    {$ENDREGION}
    procedure   beginTransaction; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  �������������� ���������� � ��, ���� ��� ��������� �������, �
    ///	  ��������� ������ ������� �������� �� ����������
    ///	</summary>
    {$ENDREGION}
    procedure   commitTransaction; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ��������������� ������������������ � ��, ���� ��� ��������� �������,
    ///	  � ��������� ������ ������� �������� �� ����������
    ///	</summary>
    {$ENDREGION}
    procedure   rollbackTransaction; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� ���������� stringList ���������� - ���������� (������)
    ///	</summary>
    ///	<param name="aList">
    ///	  StringList ������� ����� �������� ����������
    ///	</param>
    {$ENDREGION}
    procedure   getCatalogNames(aList: tStrings); virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� ���������� stringList ���������� - ������� �������
    ///	  ����
    ///	</summary>
    ///	<param name="aList">
    ///	  StringList ������� ����� �������� ����������
    ///	</param>
    {$ENDREGION}
    procedure   getSchemaNames(aList: tStrings); virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� ���������� stringList ���������� -���������� �������
    ///	  ���� ��� ��������� ������� ���� ������
    ///	</summary>
    ///	<param name="aPattern">
    ///	  ������ ��� ������
    ///	</param>
    ///	<param name="aList">
    ///	  StringList ������� ����� �������� ����������
    ///	</param>
    {$ENDREGION}
    procedure   getTableNames(const aPattern: string; aList: tStrings); overload; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� ���������� stringList ���������� - ��������� �������
    ///	  ���� ��� ��������� ������� ���� ������ � �����
    ///	</summary>
    ///	<param name="aTablePattern">
    ///	  ������ ��� ������
    ///	</param>
    ///	<param name="aSchemaPattern">
    ///	  ������ ��� ����
    ///	</param>
    ///	<param name="aList">
    ///	  StringList ������� ����� �������� ����������
    ///	</param>
    {$ENDREGION}
    procedure   getTableNames(const aTablePattern: string; const aSchemaPattern: string; aList: tStrings); overload; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� ���������� stringList ���������� - ��������� �������
    ///	  ������������������ ������� ���� ������, ����� � �����
    ///	</summary>
    ///	<param name="aTablePattern">
    ///	  ������ ��� ������
    ///	</param>
    ///	<param name="aSchemaPattern">
    ///	  ������ ��� ����
    ///	</param>
    ///	<param name="aTypes">
    ///	  ���� (��������: 'TABLE', 'VIEW', 'INDEX', 'SEQUENCE')
    ///	</param>
    ///	<param name="aList">
    ///	  StringList ������� ����� �������� ����������
    ///	</param>
    {$ENDREGION}
    procedure   getTableNames(const aTablePattern:string; const aSchemaPattern: string; aTypes: tStringDynArray; aList: tStrings); overload; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� ���������� stringList ���������� -���������� ���
    ///	  ���������� �������
    ///	</summary>
    ///	<param name="aTablePattern">
    ///	  ������ ��� ������
    ///	</param>
    ///	<param name="aList">
    ///	  StringList ������� ����� �������� ����������
    ///	</param>
    {$ENDREGION}
    procedure   getColumnNames(const aTablePattern: string; aList: tStrings); overload; virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� ���������� stringList ���������� - ��������� ���
    ///	  ���������� ������� � �������� ��� �������
    ///	</summary>
    ///	<param name="aTablePattern">
    ///	  ������ ��� ������
    ///	</param>
    ///	<param name="aColumnPattern">
    ///	  ������ ��� �������
    ///	</param>
    ///	<param name="aList">
    ///	  StringList ������� ����� �������� ����������
    ///	</param>
    {$ENDREGION}
    procedure   getColumnNames(const aTablePattern: string; const aColumnPattern: string; aList: tStrings); overload; virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� ���������� stringList ���������� - ������� ��������
    ///	  �������� ��� ��������� �������
    ///	</summary>
    ///	<param name="aPattern">
    ///	  ������ ��� ���� ��������
    ///	</param>
    ///	<param name="aList">
    ///	  StringList ������� ����� �������� ����������
    ///	</param>
    {$ENDREGION}
    procedure   getStoredProcNames(const aPattern: string; aList: tStrings); virtual; abstract;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� �������� �������� ����������� SQL ����������
    ///	</summary>
    ///	<param name="aConnection">
    ///	  SQL ����������
    ///	</param>
    {$ENDREGION}
    procedure   assign(aConnection: cAbstractSQLConnection); virtual;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  ����� ��������� SQL ����������
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
