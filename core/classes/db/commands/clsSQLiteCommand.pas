///	<summary>
///	  Класс, реализующий SQL команды для СУБД SQLite
///	</summary>
unit clsSQLiteCommand;

interface
uses
  sysUtils,
  zAbstractRODataset,
  zAbstractDataset,
  zDataset,

  clsException,
  clsStringUtils,
  clsSQLiteQuery,
  clsAbstractSQLConnection,
  clsAbstractSQLCommand;

type

  eSQLiteCommand = class(cException);


  cSQLiteCommand = class(cAbstractSQLCommand)
  private
    const

    MORE_THAN_ONE_RETURNING_FIELD_DOES_NOT_SUPPORTED = 'more than one returning fileds does not supported';
  private
    fQuery : cSQLiteQuery;
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
  clsSQLiteConnection,
  clsSQLiteCommandsBuilder,
  clsAbstractSQLCommandsBuilder;
{ cSQLiteCommand }

constructor cSQLiteCommand.create;
begin
  inherited create;
  fQuery:= cSQLiteQuery.create;
end;

destructor cSQLiteCommand.destroy;
begin
  if assigned(fQuery) then begin
    freeAndNil(fQuery);
  end;

  inherited;
end;

function cSQLiteCommand.executeForReturning(const aCommand: string): sSQLCommandReturningInfo;
var
  SQLiteConnection: cSQLiteConnection;

  mainCommand: string;
  returningFields: string;
  returningPos: integer;

  SQLiteCommandsBuilder: cSQLiteCommandsBuilder;
begin
  inherited executeForReturning(aCommand);

  result.rowsAffected := 0;
  result.returning    := NOT_VALID_RETURNING;

  SQLiteConnection:= connection as cSQLiteConnection;

  mainCommand:= aCommand;
  returningFields:= '';

  returningPos:= pos(cAbstractSQLCommandsBuilder.RETURNING_CLAUSE, mainCommand);


  if (returningPos <> 0) then begin
    mainCommand:= copy(mainCommand, 1, returningPos - 1);
    returningFields:= copy(aCommand, returningPos + length(cAbstractSQLCommandsBuilder.RETURNING_CLAUSE) + 1, MaxInt);

    if (returningFields <> '') and (length(cStringUtils.explode(returningFields, ',')) > 1) then begin
      raise eSQLiteCommand.create(MORE_THAN_ONE_RETURNING_FIELD_DOES_NOT_SUPPORTED);
    end;

  end;


  fQuery.close;
  fQuery.setSQL(mainCommand);
  fQuery.open;

  if (returningFields <> '') then begin
    SQLiteCommandsBuilder:= cSQLiteCommandsBuilder.create;
    try
      fQuery.close;
      fQuery.setSQL(format('%s last_insert_rowid()', [SQLiteCommandsBuilder.SELECT_STATEMENT]));
      fQuery.open;
    finally
      freeAndNil(SQLiteCommandsBuilder);
    end;
  end;

  result.returning:= fQuery.fields[0].asVariant;
  result.rowsAffected:= fQuery.rowsAffected;
  fQuery.close;
end;

procedure cSQLiteCommand.setConnection(aConnection: cAbstractSQLConnection);
begin
  inherited;

  fQuery.setConnection(aConnection);
end;

end.
