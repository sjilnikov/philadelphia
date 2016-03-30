unit clsUsers;

interface
uses
  classes,
  sysUtils,

  clsMemory,
  clsLists,
  clsStringUtils,
  clsGroups,
  clsRoles;

type
  cUser = class
  var
    fRoles        : cRoles;
    fGroups       : cGroups;

    fName         : string;
    fDescription  : string;
    fProfile      : tBytesArray;

    fGroupsState  : tBytesArray;
    fRolesState   : tBytesArray;

    procedure   initialize;
  public
    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray);

    procedure   restoreGroupsState(aSourceGroups: cGroups);
    procedure   restoreRolesState(aSourceRoles: cRoles);

    function    getRoles: cRoles;
    procedure   addRole(aRole: cRole);

    function    getGroups: cGroups;
    procedure   addToGroup(aGroup: cGroup);

    function    getName: string;
    procedure   setName(aName: string);

    function    getDescription: string;
    procedure   setDescription(aDescription: string);

    function    getProfile: tBytesArray;
    procedure   setProfile(aProfile: tBytesArray);

    constructor create(aName: string; aDescription: string; const aProfile: tBytesArray); overload;
    constructor create; overload;

    destructor  destroy; override;
  end;

  cUsers = class
  private
    fList       : cList;
    fOwnedItems : boolean;
  public
    procedure   clear;

    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray; aSourceUsers: cUsers = nil);
    procedure   restoreGroupsState(aGroups: cGroups);
    procedure   restoreRolesState(aRoles: cRoles);

    function    getItemByIndex(aIndex: integer): cUser;
    function    indexOf(aUser: cUser): integer;
    function    indexOfName(aUserName: string): integer;

    procedure   delete(aIndex: integer);
    procedure   add(aUser: cUser);
    function    getCount: integer;

    constructor create(aOwnedItems: boolean);
    destructor  destroy; override;

    property    count: integer read getCount;
    property    items[aIndex: integer]: cUser read getItemByIndex;
  end;

implementation

{ cUser }

constructor cUser.create(aName: string; aDescription: string; const aProfile: tBytesArray);
begin
  inherited create;

  setName(aName);
  setDescription(aDescription);
  setProfile(aProfile);

  initialize;
end;

destructor cUser.destroy;
begin
  if assigned(fRoles) then begin
    freeAndNil(fRoles);
  end;

  if assigned(fGroups) then begin
    freeAndNil(fGroups);
  end;

  inherited;
end;

procedure cUser.addRole(aRole: cRole);
begin
  fRoles.add(aRole);
end;

procedure cUser.addToGroup(aGroup: cGroup);
begin
  fGroups.add(aGroup);
end;

constructor cUser.create;
begin
  inherited create;
  initialize;
end;

function cUser.getDescription: string;
begin
  result:= fDescription;
end;

function cUser.getGroups: cGroups;
begin
  result:= fGroups;
end;

function cUser.getName: string;
begin
  result:= fName;
end;

function cUser.getProfile: tBytesArray;
begin
  result:= fProfile;
end;

function cUser.getRoles: cRoles;
begin
  result:= fRoles;
end;

procedure cUser.initialize;
begin
  fRoles:= cRoles.create(false);
  fGroups:= cGroups.create(false);
end;

procedure cUser.setDescription(aDescription: string);
begin
  fDescription:= aDescription;
end;

procedure cUser.setName(aName: string);
begin
  fName:= aName;
end;

procedure cUser.setProfile(aProfile: tBytesArray);
begin
  fProfile:= aProfile;
end;

procedure cUser.restoreGroupsState(aSourceGroups: cGroups);
begin
  getGroups.restoreState(fGroupsState, aSourceGroups);
end;

procedure cUser.restoreRolesState(aSourceRoles: cRoles);
begin
  getRoles.restoreState(fRolesState, aSourceRoles);
end;

procedure cUser.restoreState(const aState: tBytesArray);
var
  data: cMemory;

  name: string;
  description: string;
  profile: tBytesArray;
begin
  data:= cMemory.create;
  try
    data.fromBytes(aState);

    data.readUnicodeString(name);
    data.readUnicodeString(description);
    data.readBytesArray(profile);

    data.readBytesArray(fGroupsState);
    data.readBytesArray(fRolesState);

    setName(name);
    setDescription(description);
    setProfile(profile);
  finally
    freeAndNil(data);
  end;
end;

function cUser.saveState: tBytesArray;
var
  data: cMemory;
begin
  data:= cMemory.create;
  try
    data.writeUnicodeString(getName);
    data.writeUnicodeString(getDescription);
    data.writeBytesArray(getProfile);

    data.writeBytesArray(getGroups.saveState);
    data.writeBytesArray(getRoles.saveState);

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

{ cUsers }

constructor cUsers.create(aOwnedItems: boolean);
begin
  inherited create;

  fOwnedItems:= aOwnedItems;

  fList:= cList.create;
end;

destructor cUsers.destroy;
begin
  if assigned(fList) then begin
    if fOwnedItems then fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

procedure cUsers.add(aUser: cUser);
begin
  fList.add(aUser);
end;

procedure cUsers.delete(aIndex: integer);
begin
  fList.delete(aIndex);
end;

function cUsers.getCount: integer;
begin
  result:= fList.count;
end;

function cUsers.getItemByIndex(aIndex: integer): cUser;
begin
  result:= fList.items[aIndex];
end;

function cUsers.indexOf(aUser: cUser): integer;
begin
  result:= fList.indexOf(aUser);
end;

function cUsers.indexOfName(aUserName: string): integer;
var
  i: integer;
  curItem: cUser;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];
    if (curItem.getName = aUserName) then begin
      result:= i;
      exit;
    end;
  end;
end;

procedure cUsers.clear;
begin
  if fOwnedItems then fList.freeInternalObjects;
  fList.clear;
end;

procedure cUsers.restoreGroupsState(aGroups: cGroups);
var
  i: integer;

  curUser: cUser;
begin
  for i:= 0 to count - 1 do begin
    curUser:= items[i];
    curUser.restoreGroupsState(aGroups);
  end;
end;

procedure cUsers.restoreRolesState(aRoles: cRoles);
var
  i: integer;

  curUser: cUser;
begin
  for i:= 0 to count - 1 do begin
    curUser:= items[i];
    curUser.restoreRolesState(aRoles);
  end;
end;

procedure cUsers.restoreState(const aState: tBytesArray; aSourceUsers: cUsers);
var
  i: integer;

  userCount: integer;
  curUser: cUser;

  name: string;
  description: string;
  profile: tBytesArray;

  curRole: cRole;

  data: cMemory;
  dataCursor: tBytesArray;

  foundUserIndex: integer;
begin
  data:= cMemory.create;
  try
    data.fromBytes(aState);

    data.readInteger(userCount);

    for i:= 0 to userCount - 1 do begin

      try
        data.readBytesArray(dataCursor);
      except
        continue;
      end;

      if assigned(aSourceUsers) then begin
          curUser:= cUser.create;
          try
            curUser.restoreState(dataCursor);

            foundUserIndex:= aSourceUsers.indexOfName(curUser.getName);
            if (foundUserIndex <> -1) then begin
              add(aSourceUsers.items[foundUserIndex]);
            end;

          finally
            freeAndNil(curUser);
          end;

      end else begin
        try
          curUser:= cUser.create;
          curUser.restoreState(dataCursor);

          add(curUser);
        except
          freeAndNil(curUser);
        end;
      end;

    end;

  finally
    freeAndNil(data);
  end;
end;


function cUsers.saveState: tBytesArray;
var
  i: integer;

  userCount: integer;
  curUser: cUser;

  data: cMemory;
begin
  result:= '';

  userCount:= count;

  data:= cMemory.create;
  try
    data.writeInteger(userCount);

    for i:= 0 to count - 1 do begin
      curUser:= items[i];

      data.writeBytesArray(curUser.saveState);
    end;

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

end.
