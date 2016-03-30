unit clsPGSQLReport;

interface
uses
  classes,
  sysUtils,

  uReportTypes,


  clsSQLDatapoints,

  clsPGSQLQuery,

  clsMemory,
  clsStringUtils,
  clsAbstractReport;


type
  cPGSQLReport = class(cAbstractReport)
  private
    fSQL        : string;

    fPGSQLQuery : cPGSQLQuery;

    class constructor create;
  public
    const

    CONDITION_PARAM        = '%CONDITION%';
  public
    procedure   prepare; override;

    function    getType: tReportType; override;

    function    saveState: tBytesArray; override;
    procedure   restoreState(const aState: tBytesArray); override;

    procedure   setSQL(aSQL: string);
    function    getSQL: string;

    constructor create; override;
    destructor  destroy; override;
  end;

implementation

{ cPGSQLReport }

constructor cPGSQLReport.create;
begin
  inherited create;

  fPGSQLQuery:= cPGSQLQuery.create;
  fPGSQLQuery.setConnection(cSQLDatapoints.getInstance.getCurrentConnection);

  setNativeDataset(fPGSQLQuery.getNativeDataSet);
end;

class constructor cPGSQLReport.create;
begin
  registerClass(cPGSQLReport);
end;

destructor cPGSQLReport.destroy;
begin
  if assigned(fPGSQLQuery) then begin
    freeAndNil(fPGSQLQuery);
  end;

  inherited;
end;

function cPGSQLReport.getSQL: string;
begin
  result:= fSQL;
end;

function cPGSQLReport.getType: tReportType;
begin
  result:= rtPGSQL;
end;

procedure cPGSQLReport.prepare;
var
  execCommand: string;
begin
  execCommand:= stringReplace(fSQL, CONDITION_PARAM, getCondition, [rfReplaceAll]);

  needReplaceParameters(execCommand);

  if (execCommand <> '') then begin
    fPGSQLQuery.setSQL(execCommand);

    //reopen if was opened
    fPGSQLQuery.open;
  end;

  inherited prepare;
end;

procedure cPGSQLReport.restoreState(const aState: tBytesArray);
var
  data: cMemory;

  name: string;
  filePath: string;
  SQL: string;
begin
  data:= cMemory.create;
  try
    data.fromBytes(aState);

    data.readUnicodeString(name);
    data.readUnicodeString(SQL);

    setName(name);
    setSQL(SQL);
  finally
    freeAndNil(data);
  end;
end;

function cPGSQLReport.saveState: tBytesArray;
var
  data: cMemory;
begin
  data:= cMemory.create;
  try
    data.writeUnicodeString(getName);
    data.writeUnicodeString(getSQL);

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

procedure cPGSQLReport.setSQL(aSQL: string);
begin
  fSQL:= aSQL;
end;

end.
