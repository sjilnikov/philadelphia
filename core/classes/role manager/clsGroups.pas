unit clsGroups;

interface
uses
  classes,
  sysUtils,

  clsMemory,
  clsRoles,
  clsLists,
  clsStringUtils;

type
  cGroup = class
  var
    fRoles        : cRoles;

    fName         : string;
    fDescription  : string;

    fRolesState   : tBytesArray;

    procedure   initialize;
  public
    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray);

    procedure   restorRolesState(aRoles: cRoles);

    function    getRoles: cRoles;
    procedure   addRole(aRole: cRole);

    function    getName: string;
    procedure   setName(aName: string);

    function    getDescription: string;
    procedure   setDescription(aDescription: string);

    constructor create(aName: string; aDescription: string); overload;
    constructor create; overload;
    destructor  destroy; override;
  end;

  cGroups = class
  private
    fList       : cList;
    fOwnedItems : boolean;
    fRoles      : cRoles;
  public
    procedure   clear;

    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray; aSourceGroups: cGroups = nil);
    procedure   restoreRolesState(aRoles: cRoles);

    function    getItemByIndex(aIndex: integer): cGroup;
    function    indexOf(aGroup: cGroup): integer;
    function    indexOfName(aGroupName: string): integer;

    procedure   delete(aIndex: integer);
    procedure   add(aGroup: cGroup);
    function    getCount: integer;
    function    getRoles: cRoles;

    constructor create(aOwnedItems: boolean);
    destructor  destroy; override;

    property    count: integer read getCount;
    property    items[aIndex: integer]: cGroup read getItemByIndex;
  end;

implementation

{ cGroup }

procedure cGroup.addRole(aRole: cRole);
begin
  fRoles.add(aRole);
end;

constructor cGroup.create(aName: string; aDescription: string);
begin
  inherited create;

  setName(aName);
  setDescription(aDescription);

  initialize;
end;

constructor cGroup.create;
begin
  inherited create;
  initialize;
end;

destructor cGroup.destroy;
begin
  if assigned(fRoles) then begin
    freeAndNil(fRoles);
  end;

  inherited;
end;

function cGroup.getDescription: string;
begin
  result:= fDescription;
end;

function cGroup.getName: string;
begin
  result:= fName;
end;

function cGroup.getRoles: cRoles;
begin
  result:= fRoles;
end;

procedure cGroup.initialize;
begin
  fRoles:= cRoles.create(false);
end;

procedure cGroup.setDescription(aDescription: string);
begin
  fDescription:= aDescription;
end;

procedure cGroup.setName(aName: string);
begin
  fName:= aName;
end;

procedure cGroup.restoreState(const aState: tBytesArray);
var
  data: cMemory;

  name: string;
  description: string;
begin
  data:= cMemory.create;
  try
    data.fromBytes(aState);

    data.readUnicodeString(name);
    data.readUnicodeString(description);
    data.readBytesArray(fRolesState);

    setName(name);
    setDescription(description);
  finally
    freeAndNil(data);
  end;
end;

procedure cGroup.restorRolesState(aRoles: cRoles);
begin
  getRoles.restoreState(fRolesState, aRoles);
end;

function cGroup.saveState: tBytesArray;
var
  data: cMemory;
begin
  data:= cMemory.create;
  try
    data.writeUnicodeString(getName);
    data.writeUnicodeString(getDescription);

    data.writeBytesArray(getRoles.saveState);

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

{ cGroups }

constructor cGroups.create(aOwnedItems: boolean);
begin
  inherited create;

  fOwnedItems:= aOwnedItems;

  fList:= cList.create;

  fRoles:= cRoles.create(false);
end;

destructor cGroups.destroy;
begin
  if assigned(fList) then begin
    if fOwnedItems then fList.freeInternalObjects;

    freeAndNil(fList);
  end;

  if assigned(fRoles) then begin
    freeAndNil(fRoles);
  end;

  inherited;
end;

procedure cGroups.add(aGroup: cGroup);
begin
  fList.add(aGroup);
end;

procedure cGroups.delete(aIndex: integer);
begin
  fList.delete(aIndex);
end;

function cGroups.getCount: integer;
begin
  result:= fList.count;
end;

function cGroups.getItemByIndex(aIndex: integer): cGroup;
begin
  result:= fList.items[aIndex];
end;

function cGroups.getRoles: cRoles;
var
  i: integer;
  curItem: cGroup;
begin
  fRoles.clear;

  for i:= 0 to count - 1 do begin
    curItem:= items[i];

    fRoles.add(curItem.getRoles);
  end;

  result:= fRoles;
end;

function cGroups.indexOfName(aGroupName: string): integer;
var
  i: integer;
  curItem: cGroup;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];
    if (curItem.getName = aGroupName) then begin
      result:= i;
      exit;
    end;
  end;
end;

function cGroups.indexOf(aGroup: cGroup): integer;
begin
  result:= fList.indexOf(aGroup);
end;

procedure cGroups.clear;
begin
  if fOwnedItems then fList.freeInternalObjects;
  fList.clear;
end;

procedure cGroups.restoreRolesState(aRoles: cRoles);
var
  i: integer;
  curGroup: cGroup;
begin
  for i:= 0 to count - 1 do begin
    curGroup:= items[i];

    curGroup.restorRolesState(aRoles);
  end;

end;

procedure cGroups.restoreState(const aState: tBytesArray; aSourceGroups: cGroups);
var
  i: integer;

  groupCount: integer;
  curGroup: cGroup;

  name: string;
  description: string;

  curRole: cRole;

  data: cMemory;
  dataCursor: tBytesArray;

  foundGroupIndex: integer;
begin
  data:= cMemory.create;
  try
    data.fromBytes(aState);

    data.readInteger(groupCount);

    for i:= 0 to groupCount - 1 do begin

      try
        data.readBytesArray(dataCursor);
      except
        continue;
      end;

      if assigned(aSourceGroups) then begin
          curGroup:= cGroup.create;
          try
            curGroup.restoreState(dataCursor);

            foundGroupIndex:= aSourceGroups.indexOfName(curGroup.getName);
            if (foundGroupIndex <> -1) then begin
              add(aSourceGroups.items[foundGroupIndex]);
            end;

          finally
            freeAndNil(curGroup);
          end;

      end else begin
        try
          curGroup:= cGroup.create;
          curGroup.restoreState(dataCursor);

          add(curGroup);
        except
          freeAndNil(curGroup);
        end;
      end;

    end;

  finally
    freeAndNil(data);
  end;
end;

function cGroups.saveState: tBytesArray;
var
  i: integer;

  groupCount: integer;
  curGroup: cGroup;

  data: cMemory;
begin
  result:= '';
  groupCount:= count;

  data:= cMemory.create;
  try
    data.writeInteger(groupCount);

    for i:= 0 to count - 1 do begin
      curGroup:= items[i];

      data.writeBytesArray(curGroup.saveState);
    end;

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

end.

