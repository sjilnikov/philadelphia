unit clsApplication;

interface
uses
  windows,
  classes,
  messages,
  sysUtils,
  forms,
  math,
  syncObjs,

  uMetrics,
  clsLists,
  clsMulticastEvents,
  clsException;

type
  eApplication = class(cException);

  cApplication = class;

  tApplicationInitializedEvent = procedure(aSender: cApplication) of object;
  tApplicationUnInitializingEvent = procedure(aSender: cApplication) of object;
  tApplicationExceptionEvent = procedure(aSender: tObject; aE: exception) of object;

  tApplicationDestructingEvent = procedure(aSender: cApplication) of object;

  tApplicationDeletingObjectLaterProc = reference to procedure(aSender: tObject);

  //singleton
  cApplication = class
  private
    const

    DELETE_PENDING_QUEUE_CHECK_INTERVAL = 1 * SECOND;
  private
    fStartPath             : string;

    fIsInitialized         : boolean;

    fOnInitialized         : tApplicationInitializedEvent;
    fOnUnInitializing      : tApplicationUnInitializingEvent;
    fOnMessage             : tMessageEvent;
    fOnDestructing         : tApplicationDestructingEvent;
    fOnException           : tApplicationExceptionEvent;
    fDestroyPendingObjects : clist;
    fCS                    : tCriticalSection;
    fLastTick              : cardinal;

    procedure   setStartPath(aPath: string);

    procedure   setupEvents;
    procedure   disconnectEvents;

    procedure   processDestroyPendingQueue;
  protected
    procedure   beforeDestruction; override;
  public
    class function  getInstance: cApplication;

    function    getMainFormClientRect(aWithoutScrollbars: boolean = true): tRect;

    function    initialize: boolean;
    function    unInitialize: boolean;

    procedure   deleteLater(aObject: tObject);

    procedure   setDecimalSeparator(aValue: char);

    procedure   terminate;
    function    terminating: boolean;

    function    getMainForm: tForm;
    function    createForm<T: tForm>: T;
    function    createDataModule<T: tDataModule>: T;
    procedure   run;

    class function  getStartPath: string; static;
    class function  getStartFile: string; static;
    class function  getTemporaryPath: string; static;

    function    isInitialized: boolean;

    constructor create;
    destructor  destroy; override;
  published
  //EVENTS
    property    onDestructing: tApplicationDestructingEvent read fOnDestructing write fOnDestructing;
    property    onInitialized: tApplicationInitializedEvent read fOnInitialized write fOnInitialized;
    property    onUnInitializing: tApplicationUnInitializingEvent read fOnUnInitializing write fOnUnInitializing;
    property    onMessage: tMessageEvent read fOnMessage write fOnMessage;
    property    onException: tApplicationExceptionEvent read fOnException write fOnException;
  published
  //SLOTS
    procedure   incomingMessage(var aMsg: tMsg; var aHandled: boolean);
    procedure   idle(aObject: tObject; var aDone: boolean);
    procedure   exceptionRaised(aSender: tObject; aE: exception);
  end;

  //global visibility
  function buildPath(aRelPath: string; aPath: string = ''): string;
  function buildRelPath(aFullPath: string; aPath: string = ''): string;

implementation
uses
  clsSingleton,
  clsLog;

{ cApplication }

function buildPath(aRelPath: string; aPath: string): string;
const
  SLASH = '\';
  ABS_PATH_IDENTIFICATION = ':';
var
  pathLen: integer;
begin
  if (aPath = '') then aPath:= cApplication.getInstance.getStartPath;

  if (pos(ABS_PATH_IDENTIFICATION, aRelPath)<>0) then begin
    result:= aRelPath;
    exit;
  end;


  result:= aPath;
  pathLen:= length(aPath);
  if pathLen<>0 then begin

  if (aPath[pathLen]<>SLASH) then
    result:= result+SLASH

  end else begin
    result:= '';
  end;

  result:= result + aRelPath;
end;

function buildRelPath(aFullPath: string; aPath: string): string;
begin
  if (aPath = '') then aPath:= cApplication.getInstance.getStartPath;

  result:= aFullPath;

  if (copy(aFullPath, 1, length(aPath)) = aPath) then begin
    delete(result, 1, length(aPath));
  end;
end;




procedure cApplication.beforeDestruction;
begin
  cLog.getInstance.write(self, '-----------------------------------------------------------', ltDebug);

  if assigned(fOnDestructing) then begin
    fOnDestructing(self);
  end;

  unInitialize;
end;

constructor cApplication.create;
begin
  inherited create;
  fCS:= tCriticalSection.create;
  fDestroyPendingObjects:= cList.create;

  setupEvents;

  fIsInitialized:= false;
  fLastTick:= 0;
end;

function cApplication.createDataModule<T>: T;
begin
  application.createForm(tComponentClass(T), result);
end;

function cApplication.createForm<T>: T;
begin
  application.createForm(tComponentClass(T), result);
end;

procedure cApplication.deleteLater(aObject: tObject);
begin
  fCS.enter;
  try
    fDestroyPendingObjects.add(aObject);
  finally
    fCS.leave;
  end;
end;

destructor cApplication.destroy;
begin
  processDestroyPendingQueue;

  disconnectEvents;

  if assigned(fDestroyPendingObjects) then begin
    freeAndNil(fDestroyPendingObjects);
  end;

  if assigned(fCS) then begin
    freeAndNil(fCS);
  end;

  inherited;
end;

procedure cApplication.setupEvents;
begin
  application.onIdle:= idle;
  application.onMessage:= incomingMessage;
  application.onException:= exceptionRaised;
end;

procedure cApplication.terminate;
begin
  application.terminate;
end;

function cApplication.terminating: boolean;
begin
  result:= application.terminated;
end;

procedure cApplication.disconnectEvents;
begin
end;

class function cApplication.getInstance: cApplication;
begin
  result:= cSingleton.getInstance<cApplication>(stAfterAll);
end;

function cApplication.getMainForm: tForm;
begin
  result:= application.mainForm;
end;

class function cApplication.getStartFile: string;
const
  MODULE_FULL_PATH_INDEX = 0;
begin
  result:= paramStr(MODULE_FULL_PATH_INDEX);
end;

class function cApplication.getStartPath: string;
begin
  result:= extractFilePath(getStartFile);
end;

class function cApplication.getTemporaryPath: string;
var
  tempFolder: array[0..MAX_PATH] of char;
begin
  getTempPath(MAX_PATH, @tempFolder);
  result:= includeTrailingPathDelimiter(strPas(tempFolder));
end;

procedure cApplication.setDecimalSeparator(aValue: char);
begin
  decimalSeparator := aValue;
  application.updateFormatSettings := true;
end;

procedure cApplication.setStartPath(aPath: string);
begin
  fStartPath:= aPath;
end;

function cApplication.unInitialize: boolean;
begin
  cLog.getInstance.write(self, 'unInitialize:: terminating process', ltDebug);
  cLog.getInstance.write(self, 'unInitialize:: terminating main thread [id: %d]', [mainThreadID], ltDebug);

  if assigned(fOnUnInitializing) then begin
    fOnUnInitializing(self);
  end;

  cLog.getInstance.write(self, 'unInitialize:: successfully unInitialized', ltDebug);
end;

function cApplication.initialize: boolean;
begin
  result:= false;

  //delphi standard app
  application.initialize;

  application.mainFormOnTaskbar := true;

  setPrecisionMode(pmExtended);

  if assigned(fOnInitialized) then begin
    fOnInitialized(self);
  end;

  fIsInitialized:= true;

  cLog.getInstance.write(self, 'initialize:: successfully initialized', ltDebug);

  result:= true;
end;

function cApplication.isInitialized: boolean;
begin
  result:= fIsInitialized;
end;

procedure cApplication.processDestroyPendingQueue;
begin
  if fDestroyPendingObjects.count = 0 then exit;

  fCS.enter;
  try
    fDestroyPendingObjects.freeInternalObjects;
    fDestroyPendingObjects.clear;
  finally
    fCS.leave;
  end;
end;

procedure cApplication.run;
begin
  application.run;
end;

function cApplication.getMainFormClientRect(aWithoutScrollbars: boolean): tRect;
var
  mainHwnd: HWND;
  windowStyle: integer;
begin
  mainHwnd:= cApplication.getInstance.getMainForm.clientHandle;
  windows.getClientRect(cApplication.getInstance.getMainForm.clientHandle, result);

  windowStyle:= getWindowLong(mainHwnd, GWL_STYLE);

  if (windowStyle and WS_HSCROLL) <> 0 then begin
    result.bottom:= result.bottom + getSystemMetrics(SM_CXHSCROLL);
  end;

  if (windowStyle and WS_VSCROLL) <> 0 then begin
    result.right:= result.right + getSystemMetrics(SM_CXVSCROLL);
  end;

end;

{$REGION 'SLOTS'}
procedure cApplication.idle(aObject: tObject; var aDone: boolean);
begin
  if (getTickCount - fLastTick > DELETE_PENDING_QUEUE_CHECK_INTERVAL)  then begin
    processDestroyPendingQueue;
  end;
end;

procedure cApplication.exceptionRaised(aSender: tObject; aE: exception);
begin
  if assigned(fOnException) then begin
    fOnException(aSender, aE);
  end;
end;

procedure cApplication.incomingMessage(var aMsg: tMsg; var aHandled: boolean);
begin
  //delete panding objects

  //


  if assigned(fOnMessage) then begin
    fOnMessage(aMsg, aHandled);
  end;
end;

{$ENDREGION}

end.
