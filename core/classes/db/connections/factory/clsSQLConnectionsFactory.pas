unit clsSQLConnectionsFactory;

interface

uses
  db,
  classes,
  uSQLDrivers,
  clsAbstractSQLConnection;

type
  cSQLConnectionFactory = class
  public
    class function createNew(aDriver: tSQLDriver; aName: string): cAbstractSQLConnection;
  end;

implementation
uses
  clsPGSQLConnection,
  clsSQLiteConnection;

{ cSQLConnectionFactory }

class function cSQLConnectionFactory.createNew(aDriver: tSQLDriver; aName: string): cAbstractSQLConnection;
begin
  result:= nil;
  case aDriver of
    drvMSSQL: raise eDatabaseError.create(MSSQL_DRIVER_NOT_SUPPORTED);
    drvMYSQL: raise eDatabaseError.create(MYSQL_DRIVER_NOT_SUPPORTED);
    drvSQLite: begin
      result:= cSQLiteConnection.create(aName);
    end;
    drvPGSQL: begin
      result:= cPGSQLConnection.create(aName);
    end;
  end;

end;

end.
