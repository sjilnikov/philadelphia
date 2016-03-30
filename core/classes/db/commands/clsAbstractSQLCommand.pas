unit clsAbstractSQLCommand;

interface
uses
  clsAbstractSQLConnection;

type
  ///	<summary>
  ///	  Структура, хранящая результат, возвращаемый SQL командой
  ///	</summary>
  sSQLCommandReturningInfo = record

    ///	<summary>
    ///	  Количество обработанных строк
    ///	</summary>
    rowsAffected : integer;

    ///	<summary>
    ///	  Возвращаемое значение
    ///	</summary>
    returning    : variant;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Абстрактный класс SQL команды
  ///	</summary>
  ///	<remarks>
  ///	  При наследовании необходимо переопределить следующие методы:
  ///	  executeForReturning, setConnection
  ///	</remarks>
  {$ENDREGION}
  cAbstractSQLCommand = class
  private
    fConnection : cAbstractSQLConnection;
  protected
    ///	<summary>
    ///	  Метод для внутреннего использования, который выполняет SQL команду и возвращает результат выполнения
    ///	</summary>
    ///	<param name="aCommand">
    ///	  Выполняемая SQL команда
    ///	</param>
    function    executeForReturning(const aCommand: string): sSQLCommandReturningInfo; virtual;
  public
    ///	<summary>
    ///	  Метод устанавливает соединение для SQL команды
    ///	</summary>
    ///	<param name="aConnection">
    ///	  SQL соединение
    ///	</param>
    procedure   setConnection(aConnection: cAbstractSQLConnection); virtual;

    ///	<summary>
    ///	  <para>
    ///	    Метод выполняет SQL команду и возвращает результат в случае, если
    ///	    параметр aUseReturning установлен в true, в противном случае
    ///	    результат будет иметь следующий вид:
    ///	  </para>
    ///	  <para>
    ///	    result.rowsAffected := 0;
    ///	  </para>
    ///	  <para>
    ///	    result.returning := NOT_VALID_RETURNING;
    ///	  </para>
    ///	</summary>
    ///	<param name="aCommand">
    ///	  Выполняемая SQL команда
    ///	</param>
    ///	<param name="aUseReturning">
    ///	  Возвращать результат или нет
    ///	</param>
    function    execute(const aCommand: string; aUseReturning: boolean = false): sSQLCommandReturningInfo;

    ///	<summary>
    ///	  Конструктор класса
    ///	</summary>
    constructor create;

    const

    NOT_VALID_RETURNING = -1;
  published
    ///	<value>
    ///	  Вызвращает текущее SQL соединение
    ///	</value>
    property    connection: cAbstractSQLConnection read fConnection;
  end;

implementation
uses
  clsDebug;

{ cAbstractSQLCommand }

constructor cAbstractSQLCommand.create;
begin
  inherited create;
  fConnection:= nil;
end;

function cAbstractSQLCommand.execute(const aCommand: string; aUseReturning: boolean): sSQLCommandReturningInfo;
begin
  cDebug.write('cAbstractSQLCommand.execute: executing SQL command: %s', [aCommand]);

  result.rowsAffected := 0;
  result.returning    := NOT_VALID_RETURNING;

  if not assigned(fConnection) then exit;

  if aUseReturning then begin
    result:= executeForReturning(aCommand);
  end else begin
    //fast execute
    result.rowsAffected:= fConnection.execute(aCommand);
  end;
end;

function cAbstractSQLCommand.executeForReturning(const aCommand: string): sSQLCommandReturningInfo;
begin
  cDebug.write('cAbstractSQLCommand.executeForReturning: executing SQL command: %s', [aCommand]);
end;

procedure cAbstractSQLCommand.setConnection(aConnection: cAbstractSQLConnection);
begin
  fConnection:= aConnection;
end;

end.
