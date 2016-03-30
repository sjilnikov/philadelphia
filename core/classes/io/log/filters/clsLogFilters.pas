unit clsLogFilters;

interface
uses
  classes,
  windows,
  sysUtils,
  clsLog,
  clsAbstractIOObject;

type
  repositoryLogFilters = class
  private
    class function common(aLogIO: cAbstractIOObject; aMessage: string; aLogType: tLogType): boolean;
  public
    //atomic log filters, log only 1 type
    class function warning(aLogIO: cAbstractIOObject; aMessage: string; aLogType: tLogType): boolean;
    class function error(aLogIO: cAbstractIOObject; aMessage: string; aLogType: tLogType): boolean;
    class function debug(aLogIO: cAbstractIOObject; aMessage: string; aLogType: tLogType): boolean;

    //todo: composite log filters, set of atomic filters
  end;

implementation

{ repositoryLogFilters }

class function repositoryLogFilters.common(aLogIO: cAbstractIOObject; aMessage: string; aLogType: tLogType): boolean;
var
  outText: ansiString;
begin
  result:= false;
  outText:= '';
  if ((aLogIO.size)<>0) then outText:= outText + #13#10;

  outText:= outText + ansiString(aMessage);

  aLogIO.writeAtOffset(0, soEnd, outText[1], length(outText));
  result:= true;
end;

class function repositoryLogFilters.debug(aLogIO: cAbstractIOObject; aMessage: string; aLogType: tLogType): boolean;
begin
  result:= false;
  if (aLogType <> ltDebug) then exit;

  result:= common(aLogIO, aMessage, aLogType);
end;

class function repositoryLogFilters.error(aLogIO: cAbstractIOObject; aMessage: string; aLogType: tLogType): boolean;
begin
  result:= false;
  if (aLogType <> ltError) then exit;

  result:= common(aLogIO, aMessage, aLogType);
end;

class function repositoryLogFilters.warning(aLogIO: cAbstractIOObject; aMessage: string; aLogType: tLogType): boolean;
begin
  result:= false;
  if (aLogType <> ltWarning) then exit;

  result:= common(aLogIO, aMessage, aLogType);
end;

end.
