unit clsViews;

interface
uses
  classes,
  sysUtils,

  clsMemory,
  clsRoles,
  clsLists,
  clsStringUtils;

type
  cView = class
  var
    fRoles        : cRoles;

    fName         : string;

    fRolesState   : tBytesArray;

    procedure   initialize;
  public
    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray);

    procedure   restoreRolesState(aRoles: cRoles);

    function    getRoles: cRoles;
    procedure   addRole(aRole: cRole);
    procedure   addRoles(aRoles: cRoles);

    function    getName: string;
    procedure   setName(aName: string);

    constructor create(aName: string); overload;
    constructor create; overload;
    destructor  destroy; override;
  end;

  cViews = class
  private
    fList       : cList;
    fOwnedItems : boolean;
  public
    procedure   clear;

    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray; aSourceViews: cViews = nil);
    procedure   restoreRolesState(aRoles: cRoles);

    function    getItemByIndex(aIndex: integer): cView;
    function    indexOf(aView: cView): integer;
    function    indexOfName(aViewName: string): integer;

    procedure   delete(aIndex: integer);
    procedure   add(aView: cView);
    function    getCount: integer;

    constructor create(aOwnedItems: boolean);
    destructor  destroy; override;

    property    count: integer read getCount;
    property    items[aIndex: integer]: cView read getItemByIndex;
  end;

implementation

{ cView }

procedure cView.addRole(aRole: cRole);
begin
  fRoles.add(aRole);
end;

constructor cView.create(aName: string);
begin
  inherited create;

  setName(aName);

  initialize;
end;

procedure cView.addRoles(aRoles: cRoles);
var
  i: integer;
  curRole: cRole;
begin
  for i:= 0 to aRoles.count - 1 do begin
    curRole:= aRoles.items[i];
    addRole(curRole);
  end;
end;

constructor cView.create;
begin
  inherited create;
  initialize;
end;

destructor cView.destroy;
begin
  if assigned(fRoles) then begin
    freeAndNil(fRoles);
  end;

  inherited;
end;

function cView.getName: string;
begin
  result:= fName;
end;

function cView.getRoles: cRoles;
begin
  result:= fRoles;
end;

procedure cView.initialize;
begin
  fRoles:= cRoles.create(false);
end;

procedure cView.setName(aName: string);
begin
  fName:= aName;
end;

procedure cView.restoreState(const aState: tBytesArray);
var
  data: cMemory;

  name: string;
begin
  data:= cMemory.create;
  try
    data.fromBytes(aState);

    data.readUnicodeString(name);
    data.readBytesArray(fRolesState);

    setName(name);
  finally
    freeAndNil(data);
  end;
end;

procedure cView.restoreRolesState(aRoles: cRoles);
begin
  getRoles.restoreState(fRolesState, aRoles);
end;

function cView.saveState: tBytesArray;
var
  data: cMemory;
begin
  data:= cMemory.create;
  try
    data.writeUnicodeString(getName);

    data.writeBytesArray(getRoles.saveState);

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

{ cViews }

constructor cViews.create(aOwnedItems: boolean);
begin
  inherited create;

  fOwnedItems:= aOwnedItems;

  fList:= cList.create;
end;

destructor cViews.destroy;
begin
  if assigned(fList) then begin
    if fOwnedItems then fList.freeInternalObjects;

    freeAndNil(fList);
  end;

  inherited;
end;

procedure cViews.add(aView: cView);
begin
  fList.add(aView);
end;

procedure cViews.delete(aIndex: integer);
begin
  fList.delete(aIndex);
end;

function cViews.getCount: integer;
begin
  result:= fList.count;
end;

function cViews.getItemByIndex(aIndex: integer): cView;
begin
  result:= fList.items[aIndex];
end;

function cViews.indexOfName(aViewName: string): integer;
var
  i: integer;
  curItem: cView;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];
    if (curItem.getName = aViewName) then begin
      result:= i;
      exit;
    end;
  end;
end;

function cViews.indexOf(aView: cView): integer;
begin
  result:= fList.indexOf(aView);
end;

procedure cViews.clear;
begin
  if fOwnedItems then fList.freeInternalObjects;
  fList.clear;
end;

procedure cViews.restoreRolesState(aRoles: cRoles);
var
  i: integer;
  curView: cView;
begin
  for i:= 0 to count - 1 do begin
    curView:= items[i];

    curView.restoreRolesState(aRoles);
  end;

end;

procedure cViews.restoreState(const aState: tBytesArray; aSourceViews: cViews);
var
  i: integer;

  viewCount: integer;
  curView: cView;

  name: string;

  curRole: cRole;

  data: cMemory;
  dataCursor: tBytesArray;

  foundViewIndex: integer;
begin
  data:= cMemory.create;
  try
    data.fromBytes(aState);

    data.readInteger(viewCount);

    for i:= 0 to viewCount - 1 do begin

      try
        data.readBytesArray(dataCursor);
      except
        continue;
      end;

      if assigned(aSourceViews) then begin
          curView:= cView.create;
          try
            curView.restoreState(dataCursor);

            foundViewIndex:= aSourceViews.indexOfName(curView.getName);
            if (foundViewIndex <> -1) then begin
              add(aSourceViews.items[foundViewIndex]);
            end;

          finally
            freeAndNil(curView);
          end;

      end else begin
        try
          curView:= cView.create;
          curView.restoreState(dataCursor);

          add(curView);
        except
          freeAndNil(curView);
        end;
      end;

    end;

  finally
    freeAndNil(data);
  end;
end;

function cViews.saveState: tBytesArray;
var
  i: integer;

  viewCount: integer;
  curView: cView;

  data: cMemory;
begin
  result:= '';
  viewCount:= count;

  data:= cMemory.create;
  try
    data.writeInteger(viewCount);

    for i:= 0 to count - 1 do begin
      curView:= items[i];

      data.writeBytesArray(curView.saveState);
    end;

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

end.

