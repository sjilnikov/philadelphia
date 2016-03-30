unit clsTime;

interface
uses
  windows,
  sysUtils,

  uMetrics;

type

  cTime = class
  private
    fStartedTime  : cardinal;
    fHours        : word;
    fMinutes      : word;
    fSeconds      : word;
    fMilliseconds : word;

    procedure     updateTime;

    //dummy
  public
    procedure     start;
    procedure     restart;
    function      elapsed: cardinal;

    function      now: tTime;

    function      hours: word;
    function      minutes: word;
    function      seconds: word;
    function      milliseconds: word;

    constructor   create;
    destructor    destroy; override;
  end;

implementation

{ cTime }

constructor cTime.create;
begin
  inherited create;
end;

destructor cTime.destroy;
begin
  inherited;
end;

function cTime.elapsed: cardinal;
begin
  result:= getTickCount - fStartedTime;
end;

function cTime.hours: word;
begin
  updateTime;
  result:= fHours;
end;

function cTime.minutes: word;
begin
  updateTime;
  result:= fMinutes;
end;

function cTime.seconds: word;
begin
  updateTime;
  result:= fSeconds;
end;

function cTime.milliseconds: word;
begin
  updateTime;
  result:= fMilliseconds;
end;


function cTime.now: tTime;
begin
  result:= getTime;
end;

procedure cTime.restart;
begin
  start;
end;

procedure cTime.start;
begin
  fStartedTime:= getTickCount;
end;

procedure cTime.updateTime;
begin
  decodeTime(now, fHours, fMinutes, fSeconds, fMilliseconds);
end;

end.
