unit clsPGSQLConnection;

interface
uses
  types,
  classes,
  sysUtils,
  zDbcPostgreSql,
  zPlainPostgreSqlDriver,
  zConnection,

  uSQLDrivers,
  clsAbstractSQLConnection;


type

  cPGSQLConnection = class(cAbstractSQLConnection)
  private
    const

    CONNECTION_ERROR = 'error while connecting to host: %s, port:%d, database: %s, message: %s';
  private
    fConnection         : tZConnection;

    fTransactionCount   : integer;

    procedure   setupEvents;

    procedure   internalConnectionConnected(aSender: tObject);
    procedure   internalConnectionDisconnected(aSender: tObject);
  public
    function    testConnection: boolean; override;

    procedure   beginTransaction; override;
    procedure   commitTransaction; override;
    procedure   rollbackTransaction; override;

    procedure   getCatalogNames(aList: tStrings); override;
    procedure   getSchemaNames(aList: tStrings); override;


    procedure   getTableNames(const aTablePattern: string; const aSchemaPattern: string; aTypes: tStringDynArray; aList: tStrings); override;

    procedure   getColumnNames(const aTablePattern: string; const aColumnPattern: string; aList: tStrings); override;

    procedure   getStoredProcNames(const aPattern: string; aList: tStrings); override;


    function    open: boolean; override;
    function    close: boolean; override;

    function    execute(const aCommand: string): integer; override;
    function    isConnected: boolean; override;

    function    getInternalConnection: tZConnection;

    procedure   addOption(aOption: string); override;
    function    getOptions: tStrings; override;
    procedure   clearOptions; override;

    constructor create(aName: string);
    destructor  destroy; override;
  end;


implementation
uses
  clsLog;

{ cPGSQLConnection }

procedure cPGSQLConnection.addOption(aOption: string);
begin
  fConnection.properties.add(aOption);
end;

procedure cPGSQLConnection.beginTransaction;
begin
  inc(fTransactionCount);

  if (fTransactionCount = 1) then begin
    execute('begin');
  end;
end;

procedure cPGSQLConnection.commitTransaction;
begin
  dec(fTransactionCount);

  if (fTransactionCount = 0) then begin
    execute('commit');
  end;
end;

procedure cPGSQLConnection.rollbackTransaction;
begin
  dec(fTransactionCount);

  if (fTransactionCount <> 0) then begin
    execute('rollback');
  end;
end;

procedure cPGSQLConnection.setupEvents;
begin
  fConnection.afterConnect:= internalConnectionConnected;
  fConnection.afterDisconnect:= internalConnectionDisconnected;
end;

procedure cPGSQLConnection.clearOptions;
begin
  getOptions.clear;
end;

function cPGSQLConnection.close: boolean;
begin
  result:= false;
  fConnection.disconnect;
  result:= not isConnected;
end;

function cPGSQLConnection.testConnection: boolean;
begin
  result:= assigned(fConnection.dbcConnection) and (fConnection.dbcConnection.pingServer = 0);

  if (not result) then begin
    fConnection.disconnect;
  end;
end;

constructor cPGSQLConnection.create(aName: string);
begin
  inherited create(aName);

  setDriver(drvPGSQL);

  fConnection:= tZConnection.create(nil);

  setupEvents;
end;

destructor cPGSQLConnection.destroy;
begin
  if (assigned(fConnection)) then begin
    freeAndNil(fConnection);
  end;

  inherited;
end;

function cPGSQLConnection.execute(const aCommand: string): integer;
begin
  result:= 0;

  inherited execute(aCommand);

  fConnection.executeDirect(aCommand, result);
end;

procedure cPGSQLConnection.getCatalogNames(aList: tStrings);
begin
  fConnection.getCatalogNames(aList);
end;

procedure cPGSQLConnection.getColumnNames(const aTablePattern, aColumnPattern: string; aList: tStrings);
begin
  fConnection.getColumnNames(aTablePattern, aColumnPattern, aList);
end;

function cPGSQLConnection.getInternalConnection: tZConnection;
begin
  result:= fConnection;
end;

function cPGSQLConnection.getOptions: tStrings;
begin
  result:= fConnection.properties;
end;

procedure cPGSQLConnection.getSchemaNames(aList: tStrings);
begin
  fConnection.getSchemaNames(aList);
end;

procedure cPGSQLConnection.getStoredProcNames(const aPattern: string; aList: tStrings);
begin
  fConnection.getStoredProcNames(aPattern, aList);
end;

procedure cPGSQLConnection.getTableNames(const aTablePattern:string; const aSchemaPattern: string; aTypes: tStringDynArray; aList: tStrings);
begin
  fConnection.getTableNames(aTablePattern, aSchemaPattern, aTypes, aList);
end;

procedure cPGSQLConnection.internalConnectionConnected(aSender: tObject);
begin
  connected;
end;

procedure cPGSQLConnection.internalConnectionDisconnected(aSender: tObject);
begin
  disconnected;
end;

function cPGSQLConnection.isConnected: boolean;
begin
  result:= fConnection.connected;
end;

function cPGSQLConnection.open: boolean;
begin
  result:= false;

  if isConnected then fConnection.disconnect;

  //todo: make prepare connection
  clearOptions;
  addOption('codepage=win1251');

  fConnection.protocol:= 'postgresql-9';
  fConnection.database:= connectionInfo.database;
  fConnection.hostName:= connectionInfo.host;
  fConnection.port:= connectionInfo.port;
  fConnection.user:= connectionInfo.userName;
  fConnection.password:= connectionInfo.password;

  try
    fConnection.connect;
  except
    on e: exception do begin
      cLog.getInstance.write(self, CONNECTION_ERROR,
        [
          fConnection.hostName,
          fConnection.port,
          fConnection.database,
          e.message
        ],
        ltError
      );

      setLastError(e.message);
    end;
  end;

  result:= isConnected;
end;

end.
