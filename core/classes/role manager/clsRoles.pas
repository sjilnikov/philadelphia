unit clsRoles;

interface
uses
  classes,
  sysUtils,

  clsMemory,
  clsLists,
  clsStringUtils;

type
  cRole = class
  var
    fName         : string;
    fDescription  : string;

    procedure   initialize;
  public
    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray);

    function    getName: string;
    procedure   setName(aName: string);

    function    getDescription: string;
    procedure   setDescription(aDescription: string);

    constructor create; overload;
    constructor create(aName: string; aDescription: string); overload;

    destructor  destroy; override;
  end;

  cRoles = class
  private
    fList       : cList;
    fOwnedItems : boolean;
  public
    procedure   clear;

    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray; aSourceRoles: cRoles = nil);

    function    getItemByIndex(aIndex: integer): cRole;
    function    indexOf(aRole: cRole): integer;
    function    indexOfName(aRoleName: string): integer;

    procedure   delete(aIndex: integer);
    procedure   add(aRole: cRole); overload;
    procedure   add(aRoles: cRoles); overload;

    function    getCount: integer;

    function    getDelimitedString: string;

    constructor create(aOwnedItems : boolean);
    destructor  destroy; override;

    property    count: integer read getCount;
    property    items[aIndex: integer]: cRole read getItemByIndex;
  end;

implementation

{ cRole }

constructor cRole.create;
begin
  inherited create;

  initialize;
end;

constructor cRole.create(aName, aDescription: string);
begin
  inherited create;

  setName(aName);
  setDescription(aDescription);

  initialize;
end;

destructor cRole.destroy;
begin
  inherited;
end;

function cRole.getDescription: string;
begin
  result:= fDescription;
end;

function cRole.getName: string;
begin
  result:= fName;
end;

procedure cRole.initialize;
begin

end;

procedure cRole.setDescription(aDescription: string);
begin
  fDescription:= aDescription;
end;

procedure cRole.setName(aName: string);
begin
  fName:= aName;
end;

procedure cRole.restoreState(const aState: tBytesArray);
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

    setName(name);
    setDescription(description);
  finally
    freeAndNil(data);
  end;
end;

function cRole.saveState: tBytesArray;
var
  data: cMemory;
begin
  data:= cMemory.create;
  try
    data.writeUnicodeString(getName);
    data.writeUnicodeString(getDescription);

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

{ cRoles }

procedure cRoles.add(aRoles: cRoles);
var
  curRole: cRole;
  i: integer;
begin
  for i:= 0 to aRoles.count - 1 do begin
    curRole:= aRoles.items[i];

    add(curRole);
  end;
end;

constructor cRoles.create(aOwnedItems : boolean);
begin
  inherited create;

  fOwnedItems:= aOwnedItems;

  fList:= cList.create;
end;

destructor cRoles.destroy;
begin
  if assigned(fList) then begin
    if fOwnedItems then fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

procedure cRoles.add(aRole: cRole);
begin
  fList.add(aRole);
end;

procedure cRoles.delete(aIndex: integer);
begin
  fList.delete(aIndex);
end;

function cRoles.getCount: integer;
begin
  result:= fList.count;
end;

function cRoles.getDelimitedString: string;
const
  ROLE_DELIMITER = ',';
var
  i: integer;
  curRole: cRole;
begin
  result:= '';
  for i:= 0 to count - 1 do begin
    curRole:= items[i];

    result:= result + ROLE_DELIMITER + curRole.getName;
  end;

  system.delete(result, 1, 1);
end;

function cRoles.getItemByIndex(aIndex: integer): cRole;
begin
  result:= fList.items[aIndex];
end;

function cRoles.indexOf(aRole: cRole): integer;
begin
  result:= fList.indexOf(aRole);
end;

function cRoles.indexOfName(aRoleName: string): integer;
var
  i: integer;
  curItem: cRole;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];
    if (curItem.getName = aRoleName) then begin
      result:= i;
      exit;
    end;
  end;
end;

procedure cRoles.clear;
begin
  if fOwnedItems then fList.freeInternalObjects;
  fList.clear;
end;

procedure cRoles.restoreState(const aState: tBytesArray; aSourceRoles: cRoles);
var
  i: integer;

  roleCount: integer;
  curRole: cRole;

  name: string;
  description: string;
  foundRoleIndex: integer;

  data: cMemory;
  dataCursor: tBytesArray;
begin
  data:= cMemory.create;
  try
    data.fromBytes(aState);

    data.readInteger(roleCount);

    for i:= 0 to roleCount - 1 do begin
      try
        data.readBytesArray(dataCursor);
      except
        continue;
      end;

      if assigned(aSourceRoles) then begin
          curRole:= cRole.create;
          try
            curRole.restoreState(dataCursor);

            foundRoleIndex:= aSourceRoles.indexOfName(curRole.getName);
            if (foundRoleIndex <> -1) then begin
              add(aSourceRoles.items[foundRoleIndex]);
            end;

          finally
            freeAndNil(curRole);
          end;

      end else begin
        try
          curRole:= cRole.create;
          curRole.restoreState(dataCursor);

          add(curRole);
        except
          freeAndNil(curRole);
        end;
      end;
    end;

  finally
    freeAndNil(data);
  end;
end;

function cRoles.saveState: tBytesArray;
var
  i: integer;

  roleCount: integer;
  curRole: cRole;

  data: cMemory;
begin
  result:= '';

  roleCount:= count;

  data:= cMemory.create;
  try
    data.writeInteger(roleCount);

    for i:= 0 to count - 1 do begin
      curRole:= items[i];

      data.writeBytesArray(curRole.saveState);
    end;

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

end.

