unit clsDebug;

interface
uses
  syncObjs,
  windows,
  sysUtils,

  clsSingleton;

type
  cDebug = class
  private
    fEnabled    : boolean;
    fCS         : tCriticalSection;
    procedure         internalWrite(const aMessage: string; aArgs: array of const);
  public
    constructor       create;
    destructor        destroy; override;

    class function    getInstance: cDebug;

    procedure         setEnabled(aValue: boolean);

    class procedure   write(const aMessage: string; aArgs: array of const); overload;
    class procedure   write(const aMessage: string); overload;
  end;

implementation

{ cDebugger }

constructor cDebug.create;
begin
  fCS:= tCriticalSection.create;
  inherited create;
end;

destructor cDebug.destroy;
begin
  if assigned(fCS) then begin
    freeAndNil(fCS);
  end;


  inherited;
end;

class function cDebug.getInstance: cDebug;
begin
  result:= cSingleton.getInstance<cDebug>(stLogsAndDebug);
end;

//base
procedure cDebug.internalWrite(const aMessage: string; aArgs: array of const);
var
  debugMessage: string;
begin
  if (not fEnabled) then begin
    exit;
  end;

  fCS.enter;
  try
    debugMessage:= '';

    if length(aArgs) = 0 then begin
      debugMessage:= aMessage
    end else begin
      debugMessage:= format(aMessage, aArgs);
    end;

    outputDebugString(@debugMessage[1]);
  finally
    fCS.leave;
  end;
end;

procedure cDebug.setEnabled(aValue: boolean);
begin
  fEnabled:= aValue;
end;

class procedure cDebug.write(const aMessage: string; aArgs: array of const);
begin
  {$ifndef DEBUG}
  exit;
  {$endif}

  cDebug.getInstance.internalWrite(aMessage, aArgs);
end;

class procedure cDebug.write(const aMessage: string);
begin
  write(aMessage, []);
end;

end.
