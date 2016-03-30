unit clsSQLDataBuildersFactory;

interface

uses
  db,
  classes,
  uSQLDrivers,
  clsAbstractSQLDataBuilder;

type
  cSQLDataBuildersFactory = class
  public
    class function createNew(aDriver: tSQLDriver): cAbstractSQLDataBuilder;
  end;

implementation
uses
  clsSQLiteDataBuilder,
  clsPGSQLDataBuilder;

{ cSQLDataBuildersFactory }

class function cSQLDataBuildersFactory.createNew(aDriver: tSQLDriver): cAbstractSQLDataBuilder;
begin
  result:= nil;
  case aDriver of
    drvMSSQL: raise eDatabaseError.create(MSSQL_DRIVER_NOT_SUPPORTED);
    drvMYSQL: raise eDatabaseError.create(MYSQL_DRIVER_NOT_SUPPORTED);
    drvSQLite: begin
      result:= cSQLiteDataBuilder.create;
    end;
    drvPGSQL: begin
      result:= cPGSQLDataBuilder.create;
    end;
  end;

end;

end.
