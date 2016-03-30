unit clsSQLCommandsFactory;

interface

uses
  db,
  classes,
  uSQLDrivers,
  clsAbstractSQLCommand;

type
  ///	<summary>
  ///	  ‘абрика классов, котора€ создает конкретный экземпл€р класса SQL
  ///	  команды†по заданному SQL драйверу
  ///	</summary>
  cSQLCommandsFactory = class
  public
    ///	<summary>
    ///	  ћетод создает экземпл€р класса SQL команды по заданному SQL драйверу
    ///	</summary>
    ///	<param name="aDriver">
    ///	  SQL драйвер
    ///	</param>
    class function createNew(aDriver: tSQLDriver): cAbstractSQLCommand;
  end;

implementation
uses
  clsSQLiteCommand,
  clsPGSQLCommand;

{ cSQLCommandsFactory }

class function cSQLCommandsFactory.createNew(aDriver: tSQLDriver): cAbstractSQLCommand;
begin
  result:= nil;
  case aDriver of
    drvMSSQL: raise eDatabaseError.create(MSSQL_DRIVER_NOT_SUPPORTED);
    drvMYSQL: raise eDatabaseError.create(MYSQL_DRIVER_NOT_SUPPORTED);
    drvSQLite: begin
      result:= cSQLiteCommand.create;
    end;
    drvPGSQL: begin
      result:= cPGSQLCommand.create;
    end;
  end;

end;

end.
