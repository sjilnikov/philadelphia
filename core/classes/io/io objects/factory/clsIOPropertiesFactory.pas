unit clsIOPropertiesFactory;

interface
uses
  clsAbstractIOObject,
  uIODrivers;

type
  cIOPropertiesFactory = class
  public
    class function createNew(aDriver: tIODriver): cAbstractIOOProperties;
  end;

implementation
uses
  clsIOPropertiesXML,
  clsIOPropertiesIni,
  clsIOPropertiesStdOut;

{ cIOPropertiesFactory }

class function cIOPropertiesFactory.createNew(aDriver: tIODriver): cAbstractIOOProperties;
begin
  result:= nil;

  case aDriver of
    drvSTDOUT : result:= cIOPropertiesStdOut.create;
    drvINI    : result:= cIOPropertiesIni.create;
    drvXML    : result:= cIOPropertiesXML.create;
  end;
end;

end.
