unit clsPGSQLCommand;

interface
uses
  sysUtils,
  zAbstractRODataset,
  zAbstractDataset,
  zDataset,

  clsPGSQLQuery,
  clsAbstractSQLConnection,
  clsAbstractSQLCommand;

type
  ///	<summary>
  ///	  Класс, реализующий SQL команды для СУБД PostgreSQL
  ///	</summary>
  cPGSQLCommand = class(cAbstractSQLCommand)
  private
    fQuery : cPGSQLQuery;
  protected
    function    executeForReturning(const aCommand: string): sSQLCommandReturningInfo; override;

  public
    procedure   setConnection(aConnection: cAbstractSQLConnection); override;

    constructor create;
    destructor  destroy; override;
  published
    property    connection;
  end;

implementation
uses
  clsPGSQLConnection;
{ cPGSQLCommand }

constructor cPGSQLCommand.create;
begin
  inherited create;
  fQuery:= cPGSQLQuery.create;
end;

destructor cPGSQLCommand.destroy;
begin
  if assigned(fQuery) then begin
    freeAndNil(fQuery);
  end;

  inherited;
end;

function cPGSQLCommand.executeForReturning(const aCommand: string): sSQLCommandReturningInfo;
var
  pgSQLConnection: cPGSQLConnection;
begin
  inherited executeForReturning(aCommand);

  result.rowsAffected := 0;
  result.returning    := NOT_VALID_RETURNING;

  pgSQLConnection:= connection as cPGSQLConnection;

  fQuery.close;
  fQuery.setSQL(aCommand);
  fQuery.open;

  result.returning:= fQuery.fields[0].asVariant;
  result.rowsAffected:= fQuery.rowsAffected;
  fQuery.close;
end;

procedure cPGSQLCommand.setConnection(aConnection: cAbstractSQLConnection);
begin
  inherited;

  fQuery.setConnection(aConnection);
end;

end.
