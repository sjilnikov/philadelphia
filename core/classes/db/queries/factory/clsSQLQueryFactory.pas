unit clsSQLQueryFactory;

interface

uses
  db,
  classes,
  uSQLDrivers,
  clsAbstractSQLQuery;

type
  cSQLQueryFactory = class
  public
    class function createNew(aDriver: tSQLDriver): cAbstractSQLQuery;
  end;

implementation
uses
  clsPGSQLQuery,
  clsSQLiteQuery,
  clsMemoryQuery;

{ cSQLQueryFactory }

class function cSQLQueryFactory.createNew(aDriver: tSQLDriver): cAbstractSQLQuery;
begin
  result:= nil;
  case aDriver of
    drvMSSQL: raise eDatabaseError.create(MSSQL_DRIVER_NOT_SUPPORTED);
    drvMYSQL: raise eDatabaseError.create(MYSQL_DRIVER_NOT_SUPPORTED);
    drvSQLite: begin
      result:= cSQLiteQuery.create;
    end;
    drvPGSQL: begin
      result:= cPGSQLQuery.create;
    end;
    drvMemory: begin
      result:= cMemoryQuery.create;
    end;
  end;

end;

end.
