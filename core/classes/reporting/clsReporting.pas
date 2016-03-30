unit clsReporting;

interface

uses
  sysUtils,
  classes,
  variants,
  generics.collections,


  clsClassKit,
  clsSingleton,

  clsException,

  uReportTypes,

  clsFile,

  clsAbstractIOObject,
  clsMemoryTreeModel,
  clsAbstractTreeModel,

  clsLists,
  clsMemory,
  clsStringUtils,
  clsAbstractReport,
  clsMulticastEvents,

  clsPGSqlReport;

type
  eReporting = class(cException);

  cReporting = class;

  tReportingExitedFromReportEvent = procedure(aSender: cReporting; aReport: cAbstractReport) of object;

  cReporting = class(cMemoryTreeModel)
  private
    fReportsPath            : string;
    fCondition              : string;
    fParamsDict             : tDictionary<string,string>;
    fOnExitedFromReport     : tReportingExitedFromReportEvent;

    function    isUnique(aName: string): boolean;
    procedure   checkUnique(aName: string);
    function    getItemByReportName(aName: string): cTreeModelItem;

    procedure   savingItemToStream(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject); override;
    procedure   loadingItemFromStream(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject); override;

    procedure   savingToStream(aSender: cAbstractTreeModel; aStream: cAbstractIOObject); override;
    procedure   loadingFromStream(aSender: cAbstractTreeModel; aStream: cAbstractIOObject); override;
  private
    const

    NAME_ALREADY_EXISTS_FORMAT = 'report name: %s already exists!';
  public
    procedure   setParameterValue(aName: string; aValue: variant);

    procedure   setCondition(aCondition: string);
    function    getCondition: string;

    procedure   setReportForTreeModelItem(aTreeModelItem: cTreeModelItem; aReport: cAbstractReport);
    function    getReportForTreeModelItem(aTreeModelItem: cTreeModelItem): cAbstractReport;

    procedure   saveToFile(aFileName: string);
    procedure   loadFromFile(aFileName: string);

    procedure   setReportsPath(aPath: string);
    function    getReportsPath: string;

    function    addReport(aReport: cAbstractReport; aName: string): cTreeModelItem;
    function    addFolder(aName: string): cTreeModelItem;
    procedure   deleteReport(aName: string);

    function    getReport(aName: string): cAbstractReport;

    function    getReportCount: integer;
    function    reportExists(aName: string): boolean;

    class function getInstance: cReporting;

    constructor create;
    destructor  destroy; override;
  published
    {$REGION 'EVENTS'}
    property    onExitedFromReport: tReportingExitedFromReportEvent read fOnExitedFromReport write fOnExitedFromReport;
    {$ENDREGION}
  published
    {$REGION 'SLOTS'}
    procedure   itemDestroying(aItem: cTreeModelItem); override;
    procedure   reportNeedReplaceParameters(aSender: cAbstractReport; var aReportData: string);
    procedure   reportExitedFromReport(aSender: cAbstractReport);
    {$ENDREGION}
  end;

implementation

{ cReporting }

procedure cReporting.checkUnique(aName: string);
begin
  if not isUnique(aName) then begin
    raise eReporting.createFmt(NAME_ALREADY_EXISTS_FORMAT, [aName]);
  end;
end;

constructor cReporting.create;
begin
  inherited create;

  fParamsDict:= tDictionary<string,string>.create;

  fetch;
end;

destructor cReporting.destroy;
begin
  if assigned(fParamsDict) then begin
    freeAndNil(fParamsDict);
  end;

  inherited;
end;

function cReporting.addFolder(aName: string): cTreeModelItem;
begin
  result:= append(getRootItem, aName);
end;

function cReporting.addReport(aReport: cAbstractReport; aName: string): cTreeModelItem;
begin
  result:= append(getRootItem, aName);
  setReportForTreeModelItem(result, aReport);
  aReport.setFilePath(getReportsPath);
end;

procedure cReporting.deleteReport(aName: string);
var
  findedItem: cTreeModelItem;
  report: cAbstractReport;
begin
  findedItem:= getItemByReportName(aName);
  if not assigned(findedItem) then exit;

  report:= getReportForTreeModelItem(findedItem);

  disconnect(report);

  freeAndNil(report);
end;

function cReporting.getCondition: string;
begin
  result:= fCondition;
end;

class function cReporting.getInstance: cReporting;
begin
  result := cSingleton.getInstance<cReporting>(stFirstInQueue);
end;

function cReporting.getReport(aName: string): cAbstractReport;
var
  findedItem: cTreeModelItem;
begin
  result:= nil;

  findedItem:= getItemByReportName(aName);
  if not assigned(findedItem) then exit;

  result:= getReportForTreeModelItem(findedItem);
end;

function cReporting.getItemByReportName(aName: string): cTreeModelItem;
begin
  result:= locate(
    function (aItem: cTreeModelItem; aValue: variant): boolean
    begin
      result:= false;
      if aItem = getRootItem then exit;

      if not assigned(aItem.data) then exit;


      result:= getReportForTreeModelItem(aItem).getName = aValue;
    end,
    aName,
    getRootItem
  );
end;

function cReporting.getReportCount: integer;
var
  iterator: cTreeCursor;
begin
  result:= 0;

  iterator:= getIterator;
  try
    while iterator.moveNext do begin
      inc(result);
    end;
  finally
    freeAndNil(iterator);
  end;
end;

function cReporting.getReportForTreeModelItem(aTreeModelItem: cTreeModelItem): cAbstractReport;
begin
  result:= aTreeModelItem.data;
end;

function cReporting.getReportsPath: string;
begin
  result:= fReportsPath;
end;

function cReporting.isUnique(aName: string): boolean;
var
  findedItem: cTreeModelItem;
begin
  findedItem:= getItemByReportName(aName);
  result:= not assigned(findedItem);
end;

procedure cReporting.loadFromFile(aFileName: string);
var
  dataFile: cFile;
begin
  dataFile:= cFile.create(aFileName, fmOpenRead);
  try
    restoreState(dataFile.toBytes);
  finally
    freeAndNil(dataFile);
  end;
end;

procedure cReporting.loadingFromStream(aSender: cAbstractTreeModel; aStream: cAbstractIOObject);
begin
  inherited loadingFromStream(aSender, aStream);
end;

procedure cReporting.loadingItemFromStream(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject);
var
  newReport: cAbstractReport;
  reportState: tBytesArray;

  reportType: string;
  isFolder: boolean;
begin
  if aTreeModelItem = getRootItem then exit;

  aStream.readBool(isFolder);

  if not isFolder then begin

    aStream.readUnicodeString(reportType);
    aStream.readBytesArray(reportState);

    newReport:= cAbstractReport(cClassKit.createObjectInstance(getClass(reportType)));
    if assigned(newReport) then begin
      setReportForTreeModelItem(aTreeModelItem, newReport);
      newReport.setFilePath(getReportsPath);

      newReport.restoreState(reportState);
    end;
  end;

  inherited loadingItemFromStream(aSender, aTreeModelItem, aStream);
end;

function cReporting.reportExists(aName: string): boolean;
var
  foundReport: cAbstractReport;
begin
  foundReport:= getReport(aName);
  result:= assigned(foundReport);
end;

procedure cReporting.saveToFile(aFileName: string);
var
  dataFile: cFile;
begin
  dataFile:= cFile.create(aFileName, fmCreate);
  try
    dataFile.fromBytes(saveState);
  finally
    freeAndNil(dataFile);
  end;
end;

procedure cReporting.savingItemToStream(aSender: cAbstractTreeModel; aTreeModelItem: cTreeModelItem; aStream: cAbstractIOObject);
var
  curReport: cAbstractReport;
  reportType: string;

  isFolder: boolean;
begin
  if aTreeModelItem = getRootItem then exit;

  curReport:= getReportForTreeModelItem(aTreeModelItem);

  isFolder:= true;
  if assigned(curReport) then begin
    isFolder:= false;
  end;

  aStream.writeBool(isFolder);

  if not isFolder then begin
    reportType:= curReport.className;
    aStream.writeUnicodeString(reportType);

    aStream.writeBytesArray(curReport.saveState);
  end;

  inherited savingItemToStream(aSender, aTreeModelItem, aStream);
end;

procedure cReporting.savingToStream(aSender: cAbstractTreeModel; aStream: cAbstractIOObject);
begin
  inherited savingToStream(aSender, aStream);
end;

procedure cReporting.setCondition(aCondition: string);
var
  iterator: cTreeCursor;
  curReport: cAbstractReport;
  curItem: cTreeModelItem;
begin
  fCondition:= aCondition;

  iterator:= getIterator;
  try
    while iterator.moveNext do begin
      curItem:= iterator.getCurrent;
      curReport:= getReportForTreeModelItem(curItem);
      if not assigned(curReport) then continue;

      curReport.setCondition(aCondition);
    end;

  finally
    freeAndNil(iterator);
  end;
end;

procedure cReporting.setParameterValue(aName: string; aValue: variant);
begin
  fParamsDict.addOrSetValue(aName, varToStr(aValue));
end;

procedure cReporting.setReportForTreeModelItem(aTreeModelItem: cTreeModelItem; aReport: cAbstractReport);
begin
  aTreeModelItem.data:= aReport;

  connect(aReport, 'onNeedReplaceParameters', self, 'reportNeedReplaceParameters');
  connect(aReport, 'onExitedFromReport', self, 'reportExitedFromReport');
end;

procedure cReporting.setReportsPath(aPath: string);
begin
  fReportsPath:= aPath;
end;

{$REGION 'SLOTS'}
procedure cReporting.itemDestroying(aItem: cTreeModelItem);
var
  curReport: cAbstractReport;
begin
  curReport:= getReportForTreeModelItem(aItem);
  if assigned(curReport) then begin
    disconnect(curReport);
    freeAndNil(curReport);
  end;

  inherited itemDestroying(aItem);
end;

procedure cReporting.reportNeedReplaceParameters(aSender: cAbstractReport; var aReportData: string);
var
  curPair: tPair<string,string>;
begin
  for curPair in fParamsDict do begin
    aReportData:= stringReplace(aReportData, '%' + curPair.key + '%', curPair.value, [rfReplaceAll]);
  end;
end;

procedure cReporting.reportExitedFromReport(aSender: cAbstractReport);
begin
  if assigned(fOnExitedFromReport) then begin
    fOnExitedFromReport(self, aSender);
  end;
end;

{$ENDREGION}
end.
