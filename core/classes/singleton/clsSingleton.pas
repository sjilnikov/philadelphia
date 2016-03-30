unit clsSingleton;

interface
uses
  windows,
  syncObjs,
  sysUtils,
  generics.collections,
  clsLists;

type
  tSingletonType = (stQueue=2, stFirstInQueue=1, stLastInQueue=3, stAfterAll=4, stFinal=5, stLogsAndDebug=6);

  cInstance = class
  public
    instance      : tObject;
    instanceType  : tSingletonType;

    constructor create(aInstance: tObject; aInstanceType: tSingletonType);
  end;

  cInstances = class
  private
    fList       : cList;

    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cInstance;
    procedure   freeInstances;
  public
    procedure   clear;

    procedure   add(aValue: cInstance);
    procedure   delete(aIndex: integer);

    constructor create;
    destructor  destroy; override;

    property    count: integer read getCount;
    property    items[aIndex: integer]: cInstance read getItemByIndex;
  end;

  cSingleton = class
  private
    class var

    fMappings         : tDictionary<tClass, tObject>;
    fInstances        : cInstances;
    fCS               : tCriticalSection;
  private
    class constructor create;
    class destructor  destroy;
  public
    class function    getInstance<T: class, constructor>(aType: tSingletonType = stQueue): T; static;
  end;



  cInstancesSorters = class
  private
    class function sortByType(aItem1, aItem2: pointer): integer; static;
  end;

implementation

{ cSingleton }

class constructor cSingleton.create;
begin
  fMappings  := tDictionary<tClass, tObject>.create(4);
  fInstances := cInstances.create;
  fCS        := tCriticalSection.create;
end;

class destructor cSingleton.destroy;
begin
  if assigned(fInstances) then begin
    freeAndNil(fInstances);
  end;

  if assigned(fMappings) then begin
    freeAndNil(fMappings);
  end;

  if assigned(fCS) then begin
    freeAndNil(fCS);
  end;
end;

class function cSingleton.getInstance<T>(aType: tSingletonType): T;
begin
  fCS.enter;
  try
    if not fMappings.tryGetValue(T, tObject(result)) then begin
      result := T.create;
      fMappings.add(T, result);
      fInstances.add(cInstance.create(tObject(result), aType));
    end;
  finally
    fCS.leave;
  end;
end;


{ cInstance }

constructor cInstance.create(aInstance: tObject; aInstanceType: tSingletonType);
begin
  inherited create;

  instance:= aInstance;
  instanceType:= aInstanceType;
end;

{ cInstances }

constructor cInstances.create;
begin
  inherited create;

  fList:= cList.create;
end;

destructor cInstances.destroy;
begin
  if assigned(fList) then begin
    freeInstances;
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

procedure cInstances.freeInstances;
var
  i: integer;
  curInstance: cInstance;
begin
  for i := 0 to count - 1 do begin
    curInstance:= items[i];

    if assigned(curInstance.instance) then begin
      freeAndNil(curInstance.instance);
    end;
  end;
end;

procedure cInstances.add(aValue: cInstance);
begin
  fList.add(aValue);

  fList.sort(cInstancesSorters.sortByType);
end;

procedure cInstances.clear;
begin
  fList.freeInternalObjects;
  fList.clear;
end;

procedure cInstances.delete(aIndex: integer);
begin
  fList.freeInternalObject(aIndex);
  fList.delete(aIndex);
end;

function cInstances.getCount: integer;
begin
  result:= fList.count;
end;

function cInstances.getItemByIndex(aIndex: integer): cInstance;
begin
  result:= fList.items[aIndex];
end;

{ cInstancesSorters }

class function cInstancesSorters.sortByType(aItem1, aItem2: pointer): integer;
begin
  result:= ord(cInstance(aItem1).instanceType) - ord(cInstance(aItem2).instanceType);
end;

end.
