unit clsIntegerList;

interface
uses
  classes,
  sysUtils,

  clsLists,
  clsStringUtils;

type
  cInt64 = class
  public
    value: int64;

    constructor create(aValue: int64);
  end;

  cIntegerList = class
  private
    fList       : cList;

    function    getItem(aIndex: integer): cInt64;

    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): int64;
  public
    function    indexOf(aValue: int64): integer;

    procedure   clear;

    procedure   add(aValue: int64);
    procedure   delete(aIndex: integer);
    procedure   insert(aIndex: integer; aValue: int64);

    procedure   addItemsByDelimitedString(const aValue: string);
    procedure   deleteItemsByDelimitedString(const aValue: string);

    function    getDelimitedText(aDelimiter: string = ','; aQuote: string = ''): string;

    procedure   sort(aDirection: tListSortDirection);

    constructor create;
    destructor  destroy; override;

    property    count: integer read getCount;
    property    items[aIndex: integer]: int64 read getItemByIndex;
  end;

  cIntegerListSorters = class
  private
    class function sortAsc(aItem1, aItem2: pointer): integer; static;
    class function sortDesc(aItem1, aItem2: pointer): integer; static;
  end;

implementation

{ cIntegerList }

procedure cIntegerList.add(aValue: int64);
begin
  fList.add(cInt64.create(aValue));
end;

procedure cIntegerList.addItemsByDelimitedString(const aValue: string);
var
  values: tArguments;
  curValue: string;
begin
  if (aValue = '') then exit;


  values:= cStringUtils.explode(aValue, ',');

  for curValue in values do begin
    add(strToInt64(curValue));
  end;
end;

procedure cIntegerList.clear;
begin
  fList.freeInternalObjects;
  fList.clear;
end;

constructor cIntegerList.create;
begin
  inherited create;
  fList:= cList.create;
end;

procedure cIntegerList.delete(aIndex: integer);
begin
  fList.freeInternalObject(aIndex);
  fList.delete(aIndex);
end;

procedure cIntegerList.deleteItemsByDelimitedString(const aValue: string);
var
  values: tArguments;
  curValue: string;
begin
  values:= cStringUtils.explode(aValue, ',');

  for curValue in values do begin
    delete(indexOf(strToInt64(curValue)));
  end;
end;

destructor cIntegerList.destroy;
begin
  if assigned(fList) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

function cIntegerList.getCount: integer;
begin
  result:= fList.count;
end;

function cIntegerList.getDelimitedText(aDelimiter, aQuote: string): string;
var
  i: integer;

  curValue: integer;
begin
  result:= '';
  for i := 0 to count - 1 do begin
    curValue:= items[i];

    result:= result + aDelimiter + aQuote + intToStr(curValue) + aQuote;
  end;

  system.delete(result, 1, length(aDelimiter));
end;

function cIntegerList.getItem(aIndex: integer): cInt64;
begin
  result:= fList.items[aIndex];
end;

function cIntegerList.getItemByIndex(aIndex: integer): int64;
begin
  result:= getItem(aIndex).value;
end;

function cIntegerList.indexOf(aValue: int64): integer;
var
  i: integer;

  curItem: cInt64;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= getItem(i);

    if (curItem.value = aValue) then begin
      result:= i;
      exit;
    end;
  end;
end;

procedure cIntegerList.insert(aIndex: integer; aValue: int64);
begin
  fList.insert(aIndex, cInt64.create(aValue));
end;

procedure cIntegerList.sort(aDirection: tListSortDirection);
begin
  case aDirection of
    sdAsc:
    begin
      fList.sort(cIntegerListSorters.sortAsc);
    end;
    sdDesc:
    begin
      fList.sort(cIntegerListSorters.sortDesc);
    end;
  end;
end;

{ cIntegerListSorters }

class function cIntegerListSorters.sortAsc(aItem1, aItem2: pointer): integer;
begin
  result:= cInt64(aItem1).value - cInt64(aItem2).value;
end;

class function cIntegerListSorters.sortDesc(aItem1, aItem2: pointer): integer;
begin
  result:= cInt64(aItem2).value - cInt64(aItem1).value;
end;

{ cInt64 }

constructor cInt64.create(aValue: int64);
begin
  inherited create;

  value:= aValue;
end;

end.
