unit clsTimer;

interface
uses
  windows,
  messages,
  classes,
  sysUtils,
  syncObjs,
  asyncCalls,

  clsObjectHelper,
  clsApplication,
  clsMulticastEvents,
  clsDebug,
  clsTime;

type
  cTimer = class;

  tTimerTickEvent = procedure(aTimer: cTimer) of object;

  cTimer = class
  private
    fWindowHandle             : hWnd;

    fActive                   : boolean;
    fInterval                 : cardinal;
    fOnTick                   : tTimerTickEvent;
    fSingleShot               : boolean;
    fDestroying               : boolean;


    procedure   createTimer;
    procedure   destroyTimer;

    procedure   tick;

    procedure   wndProc(var aMsg: tMessage);
  public
    procedure   setSingleShot(aValue: boolean);

    procedure   singleShot(aMsec: cardinal; aReceiver: tObject; aHandlerName: string);

    procedure   setInterval(aInterval: cardinal);
    function    getInterval: cardinal;

    procedure   start;
    procedure   stop;
    procedure   restart;

    function    isActive: boolean;
    function    isSingleShot: boolean;


    constructor create(aInterval: cardinal); overload;
    constructor create; overload;

    destructor  destroy; override;
  published
    property    onTick: tTimerTickEvent read fOnTick write fOnTick;
  end;


implementation


constructor cTimer.create(aInterval: cardinal);
begin
  inherited create;

  fActive := false;
  fInterval := aInterval;
end;

destructor cTimer.destroy;
begin
  disconnect(self);

  stop;

  inherited destroy;
end;

function cTimer.isActive: boolean;
begin
  result:= fActive;
end;

function cTimer.isSingleShot: boolean;
begin
  result:= fSingleShot;
end;

constructor cTimer.create;
begin
  inherited create;

  fActive := false;
end;

procedure cTimer.createTimer;
begin
  fDestroying:= false;

{$IFDEF MSWINDOWS}
  fWindowHandle := classes.allocateHWnd(wndProc);
{$ENDIF}
{$IFDEF LINUX}
  fWindowHandle := winUtils.allocateHWnd(wndProc);
{$ENDIF}

  if (setTimer(fWindowHandle, 1, fInterval, nil) = 0) then begin
    raise eOutOfResources.create('cannot create timer');
  end;
end;


procedure cTimer.destroyTimer;
begin
  fDestroying:= true;

  killTimer(fWindowHandle, 1);
{$IFDEF MSWINDOWS}
  classes.deallocateHWnd(fWindowHandle);
{$ENDIF}
{$IFDEF LINUX}
  winUtils.deallocateHWnd(fWindowHandle);
{$ENDIF}
end;

procedure cTimer.wndProc(var aMsg: tMessage);
begin
  with aMsg do begin
    if (msg = WM_TIMER) then begin
      tick;
    end else begin
      result := defWindowProc(fWindowHandle, msg, wParam, lParam);
    end;
  end;
end;

function cTimer.getInterval: cardinal;
begin
  result:= fInterval;
end;

procedure cTimer.restart;
begin
  stop;
  start;
end;

procedure cTimer.setInterval(aInterval: cardinal);
var
  oldActive: boolean;
begin
  oldActive:= fActive;

  stop;
  fInterval:= aInterval;

  if oldActive then start;
end;

procedure cTimer.setSingleShot(aValue: boolean);
begin
  fSingleShot:= aValue;
end;

procedure cTimer.singleShot(aMsec: cardinal; aReceiver: tObject; aHandlerName: string);
begin
  disconnect(self);
  setInterval(aMsec);
  setSingleShot(true);
  connect(self, 'onTick', aReceiver, aHandlerName);
  restart;
end;

procedure cTimer.start;
begin
  if fActive then exit;

  createTimer;

  fActive:= true;
end;

procedure cTimer.stop;
begin
  if fActive then begin
    fActive:= false;
    destroyTimer;
  end;
end;

procedure cTimer.tick;
begin
  try
    if (fDestroying) or (not fActive) then exit;

    if assigned(fOnTick) then begin
      fOnTick(self);
    end;
  finally
    if isSingleShot then begin
      disconnect(self);
      stop;
    end;
  end;
end;

end.
