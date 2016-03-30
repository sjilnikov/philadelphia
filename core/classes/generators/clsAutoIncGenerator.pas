unit clsAutoIncGenerator;

interface
uses
  classes,
  sysUtils,

  clsAbstractIOObject,
  clsMemory;

type
  cAutoIncGenerator = class
  private
    fValue      : int64;
  public
    function    saveToStream(aStream: cAbstractIOObject): boolean;
    function    loadFromStream(aStream: cAbstractIOObject): boolean;

    procedure   setCurrentValue(aValue: int64);

    function    getCurrentValue: int64;
    function    getNextValue: int64;

    constructor create(aStartValue: int64);
  end;
implementation

{ cAutoIncGenerator }

constructor cAutoIncGenerator.create(aStartValue: int64);
begin
  inherited create;
  setCurrentValue(aStartValue);
end;

function cAutoIncGenerator.getNextValue: int64;
begin
  inc(fValue);
  result:= fValue;
end;

function cAutoIncGenerator.getCurrentValue: int64;
begin
  result:= fValue;
end;

function cAutoIncGenerator.loadFromStream(aStream: cAbstractIOObject): boolean;
begin
  result:= false;
  try
    aStream.writeInteger(getCurrentValue);

    result:= true;
  except
    result:= false;
  end;
end;

function cAutoIncGenerator.saveToStream(aStream: cAbstractIOObject): boolean;
var
  startValue: int64;
begin
  result:= false;
  try
    aStream.readInteger(startValue);

    result:= true;
  except
    result:= false;
  end;
end;

procedure cAutoIncGenerator.setCurrentValue(aValue: int64);
begin
  fValue:= aValue;
end;

end.
