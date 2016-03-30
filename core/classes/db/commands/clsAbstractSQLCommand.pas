unit clsAbstractSQLCommand;

interface
uses
  clsAbstractSQLConnection;

type
  ///	<summary>
  ///	  ���������, �������� ���������, ������������ SQL ��������
  ///	</summary>
  sSQLCommandReturningInfo = record

    ///	<summary>
    ///	  ���������� ������������ �����
    ///	</summary>
    rowsAffected : integer;

    ///	<summary>
    ///	  ������������ ��������
    ///	</summary>
    returning    : variant;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  ����������� ����� SQL �������
  ///	</summary>
  ///	<remarks>
  ///	  ��� ������������ ���������� �������������� ��������� ������:
  ///	  executeForReturning, setConnection
  ///	</remarks>
  {$ENDREGION}
  cAbstractSQLCommand = class
  private
    fConnection : cAbstractSQLConnection;
  protected
    ///	<summary>
    ///	  ����� ��� ����������� �������������, ������� ��������� SQL ������� � ���������� ��������� ����������
    ///	</summary>
    ///	<param name="aCommand">
    ///	  ����������� SQL �������
    ///	</param>
    function    executeForReturning(const aCommand: string): sSQLCommandReturningInfo; virtual;
  public
    ///	<summary>
    ///	  ����� ������������� ���������� ��� SQL �������
    ///	</summary>
    ///	<param name="aConnection">
    ///	  SQL ����������
    ///	</param>
    procedure   setConnection(aConnection: cAbstractSQLConnection); virtual;

    ///	<summary>
    ///	  <para>
    ///	    ����� ��������� SQL ������� � ���������� ��������� � ������, ����
    ///	    �������� aUseReturning ���������� � true, � ��������� ������
    ///	    ��������� ����� ����� ��������� ���:
    ///	  </para>
    ///	  <para>
    ///	    result.rowsAffected := 0;
    ///	  </para>
    ///	  <para>
    ///	    result.returning := NOT_VALID_RETURNING;
    ///	  </para>
    ///	</summary>
    ///	<param name="aCommand">
    ///	  ����������� SQL �������
    ///	</param>
    ///	<param name="aUseReturning">
    ///	  ���������� ��������� ��� ���
    ///	</param>
    function    execute(const aCommand: string; aUseReturning: boolean = false): sSQLCommandReturningInfo;

    ///	<summary>
    ///	  ����������� ������
    ///	</summary>
    constructor create;

    const

    NOT_VALID_RETURNING = -1;
  published
    ///	<value>
    ///	  ���������� ������� SQL ����������
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
