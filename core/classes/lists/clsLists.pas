(*
 * Lists
 * Version: 1.1
 *
 * Features:
 *
 * Usage:
 *
 * Author: Sergei Jilnikov
 *
 * Send bugs/comments to s.jilnikov@gmail.com
 *)

unit clsLists;

interface

uses
  sysUtils,
  windows,
  classes,
  generics.collections,
  contnrs;


type

  { cList class }

  pPointerList = ^tPointerList;
  tPointerList = array[0..maxListSize - 1] of pointer;

  tListItemSortCompareProc = function(aItem1, aItem2: pointer): integer;

  tItemsIteratorProc = reference to function(aItem: pointer; aIndex: integer; aArgs: array of const): boolean;

  tListSortDirection = (sdAsc, sdDesc);

  cList = class
  private
    fList     : pPointerList;
    fCount    : integer;
    fCapacity : integer;
  protected
    function        get(index: Integer): Pointer;
    procedure       grow; virtual;
    procedure       put(index: integer; item: pointer);
    procedure       setCapacity(newCapacity: integer);
    procedure       setCount(newCount: integer);
  public
    constructor     create;
    destructor      destroy; override;

    procedure       freeInternalObjects;
    procedure       freeInternalObject(index: integer);

    function        add(item: pointer): integer;
    procedure       clear; dynamic;
    procedure       delete(index: integer);
    class procedure error(const msg: string; data: integer); virtual;
    procedure       exchange(index1, index2: integer);
    function        expand: cList;
    function        first: pointer;
    function        indexOf(item: pointer): integer;
    procedure       insert(index: integer; item: pointer);
    function        last: pointer;
    procedure       move(curIndex, newIndex: integer);
    function        remove(item: pointer): integer;
    procedure       pack;
    procedure       sort(compare: tListItemSortCompareProc);

    procedure       shuffle(aStartindex: integer = 0);
    function        iterateItems(aActionProc: tItemsIteratorProc; aArgs: array of const): pointer;

    property        capacity: integer read fCapacity write setCapacity;
    property        count: integer read fCount write setCount;
    property        items[index: Integer]: Pointer read get write put; default;
    property        list: pPointerList read fList;

    const

    INDEX_OUT_OF_BOUNDS = 'list index: %d out of bounds';
    CAPACITY_EXCEEDED   = 'capacity: %d exceeded';
  end;


  //every thread safe class have cThread prefix and have his own realization with lock
  cThreadList = class
  private
    fList       : cList;
    fLock       : tRTLCriticalSection;
  public
    procedure   add(item: pointer);
    procedure   delete(aIndex: integer);

    function    first: pointer;
    function    count: integer;


    procedure   clear;
    function    lockList: cList;
    procedure   unlockList;

    procedure   remove(item: pointer);

    procedure   freeInternalObjects;

    constructor create;
    destructor  destroy; override;
  end;


  cListSorters = class
  public
    class procedure quickSort(sortList: pPointerList; l, r: integer; sCompare: tListItemSortCompareProc); static;
  end;

implementation

uses
  consts,
  typInfo;

{cList}

constructor cList.create;
begin
  inherited;
  fCapacity := 0;
  fCount := 0;
end;

destructor cList.destroy;
begin
  clear;
  inherited;
end;

function cList.add(item: pointer): integer;
begin
  result:= fCount;
  if result = fCapacity then
    grow;
  fList^[result] := item;
  inc(fCount);
end;

procedure cList.clear;
begin
  setCount(0);
  setCapacity(0);
end;

procedure cList.delete(index: integer);
begin
  if (index < 0) or (index >= fCount) then error(INDEX_OUT_OF_BOUNDS, index);
  dec(fCount);
  if index < fCount then  system.move(fList^[index + 1], fList^[index],  (fCount - index) * sizeOf(pointer));
end;

class procedure cList.error(const msg: string; data: integer);

  function returnAddr: pointer;
  asm
          MOV     EAX,[EBP+4]
  end;

begin
  raise eListError.createFmt(msg, [data]) at returnAddr;
end;

procedure cList.exchange(index1, index2: integer);
var
  item: pointer;
begin
  if (index1 < 0) or (index1 >= fCount) then
    error(INDEX_OUT_OF_BOUNDS, index1);
  if (index2 < 0) or (index2 >= fCount) then
    error(INDEX_OUT_OF_BOUNDS, index2);
  item := fList^[index1];
  fList^[index1] := fList^[index2];
  fList^[index2] := item;
end;

function cList.expand: cList;
begin
  if fCount = fCapacity then
    grow;
  result := self;
end;

function cList.first: pointer;
begin
  result:= nil;
  if (count = 0) then begin
    exit;
  end;

  result := get(0);
end;

procedure cList.freeInternalObject(index: integer);
var
  item: tObject;
begin
  item:= items[index];
  if assigned(item) then begin
    freeAndNil(item);
  end;
end;

procedure cList.freeInternalObjects;
var
  i: integer;
  item: tObject;
begin
  //free internal objects
  for i := 0 to count - 1 do begin
    item:= items[i];
    if assigned(item) then begin
      freeAndNil(item);
    end;
  end;
end;

function cList.get(index: integer): pointer;
begin
  if (index < 0) or (index >= fCount) then
    error(INDEX_OUT_OF_BOUNDS, index);
  result := fList^[index];
end;

procedure cList.grow;
begin
  if fCapacity < 64 then
    setCapacity(fCapacity + 8)
  else if fCapacity < 256 then
    setCapacity(fCapacity + 32)
  else if fCapacity < 1024 then
    setCapacity(fCapacity + 64)
  else
    setCapacity(fCapacity + 128);
end;

function cList.indexOf(item: pointer): integer;
begin
  result := 0;
  while (result < fCount) and (fList^[result] <> item) do
    inc(result);
  if result = fCount then
    result := -1;
end;

procedure cList.insert(index: integer; item: pointer);
begin
  if (index < 0) or (index > fCount) then
    error(INDEX_OUT_OF_BOUNDS, index);
  if fCount = fCapacity then
    grow;
  if index < fCount then
    system.move(fList^[index], fList^[index + 1], (fCount - index) * sizeOf(pointer));
  fList^[index] := item;
  inc(fCount);
end;

function cList.iterateItems(aActionProc: tItemsIteratorProc; aArgs: array of const): pointer;
var
  i: integer;

  curItem: pointer;
begin
  result:= nil;
  for i := 0 to count - 1 do begin
    curItem:= items[i];

    if aActionProc(curItem, i, aArgs) then begin
      result:= curItem;

      break;
    end;
  end;
end;

function cList.last: pointer;
begin
  result:= nil;
  if (count = 0) then begin
    exit;
  end;

  result := get(fCount - 1);
end;

procedure cList.move(curIndex, newIndex: integer);
var
  item: pointer;
begin
  if curIndex <> newIndex then begin
    if (newIndex < 0) or (newIndex >= fCount) then
      error(INDEX_OUT_OF_BOUNDS, newIndex);
    item := get(curIndex);
    delete(curIndex);
    insert(newIndex, item);
  end;
end;

procedure cList.put(index: integer; item: pointer);
begin
  if (index < 0) or (index >= fCount) then
    error(INDEX_OUT_OF_BOUNDS, index);
  fList^[index] := item;
end;

function cList.remove(item: pointer): integer;
begin
  result := indexOf(item);
  if result <> -1 then
    delete(result);
end;

procedure cList.pack;
var
  i: integer;
begin
  for i := count - 1 downto 0 do
    if not assigned(items[i]) then
      delete(i);
end;

procedure cList.setCapacity(newCapacity: integer);
begin
  if (newCapacity < fCount) or (newCapacity > maxListSize) then
    error(CAPACITY_EXCEEDED, newCapacity);
  if newCapacity <> fCapacity then begin
    reallocMem(fList, newCapacity * sizeOf(pointer));
    fCapacity := newCapacity;
  end;
end;

procedure cList.setCount(newCount: integer);
begin
  if (newCount < 0) or (newCount > maxListSize) then
    error(INDEX_OUT_OF_BOUNDS, newCount);
  if newCount > fCapacity then
    setCapacity(newCount);
  if newCount > fCount then
    fillChar(fList^[fCount], (newCount - fCount) * sizeOf(pointer), 0);
  fCount := newCount;
end;

procedure cList.sort(compare: tListItemSortCompareProc);
begin
  if (assigned(fList)) and (count > 1) then
    cListSorters.quickSort(fList, 0, count - 1, compare);
end;

procedure cList.shuffle(aStartindex: integer);
const
  MIN_ITEMS_FOR_SHUFFLE = 2;
var
  i: integer;
  amount: integer;
begin
  if count < MIN_ITEMS_FOR_SHUFFLE then exit;

  if aStartindex >= count - 1 then exit;

  amount := (count - 1) - aStartindex;
  for i := aStartindex to count - 1 do
    move(i, aStartindex + random(amount + 1));
end;

{ cThreadList }

constructor cThreadList.create;
begin
  inherited create;
  initializeCriticalSection(fLock);
  fList := cList.create;
end;

procedure cThreadList.delete(aIndex: integer);
begin
  lockList;
  try
    fList.delete(aIndex);
  finally
    unlockList;
  end;
end;

destructor cThreadList.destroy;
begin
  //make sure nobody else is inside the list.
  lockList;
  try
    fList.free;
    inherited destroy;
  finally
    unlockList;
    deleteCriticalSection(fLock);
  end;
end;

function cThreadList.first: pointer;
begin
  result:= nil;
  lockList;
  try
    result:= fList.first;
  finally
    unlockList;
  end;
end;

procedure cThreadList.freeInternalObjects;
begin
  lockList;
  try
    fList.freeInternalObjects;
  finally
    unlockList;
  end;
end;

procedure cThreadList.add(item: pointer);
begin
  lockList;
  try
    fList.add(item)
  finally
    unlockList;
  end;
end;

procedure cThreadList.clear;
begin
  lockList;
  try
    fList.clear;
  finally
    unlockList;
  end;
end;

function cThreadList.count: integer;
begin
  result:= 0;
  lockList;
  try
    result:= fList.count;
  finally
    unlockList;
  end;
end;

function  cThreadList.lockList: cList;
begin
  enterCriticalSection(fLock);
  result := fList;
end;

procedure cThreadList.remove(item: pointer);
begin
  lockList;
  try
    fList.remove(item);
  finally
    unlockList;
  end;
end;

procedure cThreadList.unlockList;
begin
  leaveCriticalSection(fLock);
end;



{cListSorters}
class procedure cListSorters.quickSort(sortList: pPointerList; l, r: integer; sCompare: tListItemSortCompareProc);
var
  i, j: integer;
  p, t: pointer;
begin
  repeat
    i := l;
    j := r;
    p := sortList^[(l + r) shr 1];
    repeat
      while sCompare(sortList^[I], p) < 0 do
        inc(i);
      while sCompare(sortList^[j], p) > 0 do
        dec(j);
      if i <= j then begin
        t := sortList^[i];
        sortList^[i] := sortList^[j];
        sortList^[j] := t;
        inc(i);
        dec(j);
      end;
    until i > j;
    if l < j then
      quickSort(sortList, l, j, sCompare);
    l := i;
  until i >= r;
end;

end.


