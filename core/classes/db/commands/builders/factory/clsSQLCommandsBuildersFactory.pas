unit clsSQLCommandsBuildersFactory;

interface
uses
  db,
  uSQLDrivers,
  clsAbstractSQLCommandsBuilder;

type
  cSQLCommandsBuilderFactory = class
  public
    class function createNew(aDriver: tSQLDriver): cAbstractSQLCommandsBuilder;
  end;

implementation
uses
  clsPGSQLCommandsBuilder,
  clsSQLiteCommandsBuilder;

{ cSQLCommandsBuilderFactory }

class function cSQLCommandsBuilderFactory.createNew(aDriver: tSQLDriver): cAbstractSQLCommandsBuilder;
begin
  result:= nil;
  case aDriver of
    drvMSSQL: raise eDatabaseError.create(MSSQL_DRIVER_NOT_SUPPORTED);
    drvMYSQL: raise eDatabaseError.create(MYSQL_DRIVER_NOT_SUPPORTED);
    drvSQLite: begin
      result:= cSQLiteCommandsBuilder.create;
    end;
    drvPGSQL: begin
      result:= cPGSQLCommandsBuilder.create;
    end;
  end;

end;

end.
