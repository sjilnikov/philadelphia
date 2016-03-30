unit clsLog;

interface
uses
  windows,
  classes,
  sysUtils,
  syncObjs,
  clsClassKit,
  clsLists,
  clsAbstractIOObject,
  clsFile;

type
  tLogType = (ltWarning, ltError, ltDebug);
const
  LOG_TYPE : array[low(tLogType)..high(tLogType)] of string = ('warning', 'error', 'debug');

type
  tLogFilterProc = function(aLogIO: cAbstractIOObject; aMessage: string; aLogType: tLogType): boolean of object;

  cLogFilter = class
  private
    fFilterProc : tLogFilterProc;
  public
    constructor create(aFilterProc: tLogFilterProc);

    property    filterProc: tLogFilterProc read fFilterProc;
  end;

  cLogFilters = class
  private
    fList       : cList;

    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cLogFilter;


  public
    function    indexOfFilter(aFilter: cLogFilter): integer;
    function    indexOfFilterProc(aFilterProc: tLogFilterProc): integer;

    procedure   add(aFilter: cLogFilter);
    procedure   delete(aIndex: integer); overload;
    procedure   delete(aFilter: cLogFilter); overload;
    procedure   delete(aFilterProc: tLogFilterProc); overload;

    constructor create;
    destructor  destroy; override;

    property    items[aIndex: integer]: cLogFilter read getItemByIndex;
    property    count: integer read getCount;
  end;


  //singleton
  //thread-safe
  cLog = class
  private
    const

    LOG_FILTER_ALREADY_EXISTS = 'log filter already exists';

  private
    fCS         : tCriticalSection;
    fLogIO      : cAbstractIOObject;
    fFilters    : cLogFilters;

    procedure   append(aMessage: string; aLogType: tLogType);

    function    getFilterCount: integer;

    procedure   destroyLogIO;


  public
    class function  getInstance: cLog;


    //base
    procedure   write(aSender: string; aMessage: string; aArgs: array of const; aLogType: tLogType); overload;
    //

    procedure   write(aSender: tObject; aMessage: string; aArgs: array of const; aLogType: tLogType); overload;
    procedure   write(aSender: tClass; aMessage: string; aArgs: array of const; aLogType: tLogType); overload;

    procedure   write(aSender: tObject; aMessage: string; aLogType: tLogType); overload;
    procedure   write(aSender: tClass; aMessage: string; aLogType: tLogType); overload;
    procedure   write(aSender: string; aMessage: string; aLogType: tLogType); overload;

    procedure   addFilter(aFilterProc: tLogFilterProc);
    procedure   deleteFilter(aFilterProc: tLogFilterProc);

    procedure   setLogIO(aLogIO: cAbstractIOObject);
    function    getLogIO: cAbstractIOObject;

    constructor create;
    destructor  destroy; override;

    property    filterCount: integer read getFilterCount;
  public
    const

    LOG_OUT_FORMAT = '[%s][%s], sender: %s, message: %s';
  end;





implementation
uses
  clsSingleton;

{ cLogFilters }

procedure cLogFilters.add(aFilter: cLogFilter);
begin
  fList.add(aFilter);
end;

constructor cLogFilters.create;
begin
  inherited create;

  fList:= cList.create;
end;

procedure cLogFilters.delete(aIndex: integer);
var
  filter: cLogFilter;
begin
  filter:= items[aIndex];
  freeAndNil(filter);
  fList.delete(aIndex);
end;

procedure cLogFilters.delete(aFilter: cLogFilter);
var
  foundIndex: integer;
begin
  foundIndex:= indexOfFilter(aFilter);
  if (foundIndex <> -1) then begin
    delete(foundIndex);
  end;
end;

destructor cLogFilters.destroy;
begin
  if (assigned(fList)) then begin
    flist.freeInternalObjects;
    freeAndNil(flist);
  end;

  inherited;
end;

function cLogFilters.getCount: integer;
begin
  result:= fList.count;
end;

function cLogFilters.getItemByIndex(aIndex: integer): cLogFilter;
begin
  result:= fList.items[aIndex];
end;

function cLogFilters.indexOfFilter(aFilter: cLogFilter): integer;
begin
  result:= fList.indexOf(aFilter);
end;

function cLogFilters.indexOfFilterProc(aFilterProc: tLogFilterProc): integer;
var
  i: integer;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    if (cClassKit.isMethodEquals(tMethod(items[i].filterProc), tMethod(aFilterProc))) then begin
      result:= i;
      exit;
    end;
  end;
end;

procedure cLogFilters.delete(aFilterProc: tLogFilterProc);
var
  foundIndex: integer;
begin
  foundIndex:= indexOfFilterProc(aFilterProc);
  if (foundIndex <> -1) then begin
    delete(foundIndex);
  end;
end;

{ cLog }

procedure cLog.addFilter(aFilterProc: tLogFilterProc);
var
  existsIndex: integer;
begin
  fCS.enter;
  try

    existsIndex:= fFilters.indexOfFilterProc(aFilterProc);

    if (existsIndex = -1) then begin
      fFilters.add(cLogFilter.create(aFilterProc));
    end else begin
      raise eListError.create(LOG_FILTER_ALREADY_EXISTS);
    end;

  finally
    fCS.leave;
  end;
end;

procedure cLog.append(aMessage: string; aLogType: tLogType);
var
  i: integer;
begin
  if (assigned(fLogIO)) then begin
    for i:= 0 to fFilters.count - 1 do begin
      if (fFilters.items[i].filterProc(fLogIO, aMessage, aLogType)) then begin
        break;
      end;
    end;
  end;
end;

constructor cLog.create;
begin
  inherited create;
  fCS       := tCriticalSection.create;

  fLogIO    := nil;
  fFilters  := cLogFilters.create;
end;

procedure cLog.destroyLogIO;
begin
  if (assigned(fLogIO)) then begin
    freeAndNil(fLogIO);
  end;
end;

procedure cLog.deleteFilter(aFilterProc: tLogFilterProc);
begin
  fCS.enter;
  try
    fFilters.delete(aFilterProc);
  finally
    fCS.leave;
  end;
end;

destructor cLog.destroy;
begin
  destroyLogIO;

  if (assigned(fFilters)) then begin
    freeAndNil(fFilters);
  end;

  if (assigned(fCS)) then begin
    freeAndNil(fCS);
  end;

  inherited;
end;

function cLog.getFilterCount: integer;
begin
  result:= fFilters.count;
end;

class function cLog.getInstance: cLog;
begin
  result:= cSingleton.getInstance<cLog>(stLogsAndDebug);
end;

function cLog.getLogIO: cAbstractIOObject;
begin
  result:= nil;
  fCS.enter;
  try
    result:= fLogIO;
  finally
    fCS.leave;
  end;
end;

procedure cLog.setLogIO(aLogIO: cAbstractIOObject);
begin
  fCS.enter;
  try
    destroyLogIO;

    fLogIO:= aLogIO;
  finally
    fCS.leave;
  end;
end;

procedure cLog.write(aSender, aMessage: string; aArgs: array of const; aLogType: tLogType);
var
  logMessage: string;
  resMessage: string;


  curTime: tDateTime;
  hour, min, sec, mSec: word;
begin
  curTime:= time;
  decodeTime(curTime, hour, min, sec, msec);

  logMessage:= '';
  if length(aArgs) = 0 then
    logMessage:= aMessage
  else
    logMessage:= format(aMessage, aArgs);

  resMessage:= format(LOG_OUT_FORMAT,
    [
      format('%s %s.%d', [dateToStr(now), timeToStr(now), mSec]),

      LOG_TYPE[aLogType],

      aSender,

      logMessage
    ]
  );

  append(resMessage, aLogType);
end;

procedure cLog.write(aSender: tClass; aMessage: string; aArgs: array of const; aLogType: tLogType);
begin
  write(aSender.className, aMessage, aArgs, aLogType);
end;

procedure cLog.write(aSender: tObject; aMessage: string; aArgs: array of const; aLogType: tLogType);
begin
  write(aSender.className, aMessage, aArgs, aLogType);
end;

procedure cLog.write(aSender, aMessage: string; aLogType: tLogType);
begin
  write(aSender, aMessage, [], aLogType);
end;

procedure cLog.write(aSender: tClass; aMessage: string; aLogType: tLogType);
begin
  write(aSender.className, aMessage, [], aLogType);
end;

procedure cLog.write(aSender: tObject; aMessage: string; aLogType: tLogType);
begin
  write(aSender.className, aMessage, [], aLogType);
end;

{ cLogFilter }

constructor cLogFilter.create(aFilterProc: tLogFilterProc);
begin
  inherited create;
  fFilterProc:= aFilterProc;
end;

end.
