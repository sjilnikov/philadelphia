unit clsRoleManager;

interface

uses
  windows,
  messages,
  graphics,
  sysUtils,
  controls,
  extCtrls,
  classes,

  clsStringUtils,

  clsException,

  clsFile,
  clsMemory,

  clsSingleton,
  clsUsers,
  clsGroups,
  clsRoles,
  clsViews,

  clsWinControlLockDecorator,

  clsCodeBlocks;

type
  eRoleManager = class(cException);

  cRoleManager = class
  private
    const

    RLM_HEADER = 'rlm';
    INVALID_RLM_HEADER = 'invalid rlm header';
  private
    fUsers          : cUsers;
    fGroups         : cGroups;
    fRoles          : cRoles;
    fCodeBlocks     : cCodeBlocks;
    fViews          : cViews;

    fCurrentUser    : cUser;

    fLockDecorator  : cWinControlLockDecorator;

  public
    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray);

    procedure   saveToFile(aFileName: string);
    procedure   loadFromFile(aFileName: string);

    function    getCurrentUser: cUser;

    procedure   setCurrentUser(aUser: cUser); overload;
    procedure   setCurrentUser(aUserName: string); overload;

    function    isCurrentUserInRoles(aRoles: string): boolean;
    function    isCodeBlockAccepted(aCodeBlockName: string): boolean;
    function    isViewAccepted(aViewName: string): boolean;
    procedure   restrictAccessToViews(aRootViewControl: tControl);

    procedure   addCodeBlock(aCodeBlockName: string);
    procedure   addView(aViewName: string);

    procedure   addRolesForCodeBlocks(aCodeBlocks: string; aRoles: string);
    procedure   addRolesForViews(aViews: string; aRoles: string);

    procedure   addRolesForUsers(aRoles: string; aUsers: string);
    procedure   addRolesForGroups(aRoles: string; aGroups: string);
    procedure   addUsersToGroups(aUsers: string; aGroups: string);

    procedure   addUser(aUserName: string; aDescription: string = ''; const aProfile: tBytesArray = '');
    procedure   addGroup(aGroupName: string; aDescription: string = '');
    procedure   addRole(aRoleName: string; aDescription: string = '');

    procedure   removeRolesForUsers(aRoles: string; aUsers: string);
    procedure   removeRolesForGroups(aRoles: string; aGroups: string);
    procedure   removeRolesForCodeBlocks(aRoles: string; aCodeBlocks: string);
    procedure   removeRolesForViews(aRoles: string; aViews: string);

    function    getUsers: cUsers;
    function    getGroups: cGroups;
    function    getRoles: cRoles;
    function    getCodeBlocks: cCodeBlocks;
    function    getViews: cViews;

    class function getInstance: cRoleManager;

    constructor create;
    destructor  destroy; override;
  end;

implementation

{ cRoleManager }

constructor cRoleManager.create;
begin
  inherited create;

  fUsers := cUsers.create(true);
  fGroups := cGroups.create(true);
  fRoles := cRoles.create(true);
  fCodeBlocks := cCodeBlocks.create(true);
  fViews := cViews.create(true);

  fLockDecorator:= cWinControlLockDecorator.create;
end;

destructor cRoleManager.destroy;
begin
  if assigned(fUsers) then begin
    freeAndNil(fUsers);
  end;

  if assigned(fGroups) then begin
    freeAndNil(fGroups);
  end;

  if assigned(fRoles) then begin
    freeAndNil(fRoles);
  end;

  if assigned(fCodeBlocks) then begin
    freeAndNil(fCodeBlocks);
  end;

  if assigned(fViews) then begin
    freeAndNil(fViews);
  end;

  if assigned(fLockDecorator) then begin
    freeAndNil(fLockDecorator);
  end;

  inherited;
end;

procedure cRoleManager.addCodeBlock(aCodeBlockName: string);
begin
  if (fCodeBlocks.indexOfName(aCodeBlockName) = -1) then begin
    fCodeBlocks.add(cCodeBlock.create(aCodeBlockName));
  end;
end;

procedure cRoleManager.addGroup(aGroupName, aDescription: string);
begin
  fGroups.add(cGroup.create(aGroupName, aDescription));
end;

procedure cRoleManager.addRole(aRoleName, aDescription: string);
begin
  fRoles.add(cRole.create(aRoleName, aDescription));
end;

procedure cRoleManager.addRolesForCodeBlocks(aCodeBlocks: string; aRoles: string);
var
  roleArgs: tArguments;
  curStrRole: string;
  curRole: cRole;

  codeBlockArgs: tArguments;
  curStrCodeBlock: string;
  curCodeBlock: cCodeBlock;

  foundCodeBlockIndex: integer;
  foundRoleIndex: integer;
begin
  codeBlockArgs := cStringUtils.explode(aCodeBlocks, ',');
  for curStrCodeBlock in codeBlockArgs do begin

    foundCodeBlockIndex := fCodeBlocks.indexOfName(curStrCodeBlock);
    if (foundCodeBlockIndex = -1) then begin
      continue;
    end;

    curCodeBlock := getCodeBlocks.items[foundCodeBlockIndex];
    roleArgs := cStringUtils.explode(aRoles, ',');
    for curStrRole in roleArgs do begin

      foundRoleIndex := getRoles.indexOfName(curStrRole);
      if (foundRoleIndex = -1) then begin
        continue;
      end;

      curRole := getRoles.items[foundRoleIndex];

      curCodeBlock.addRole(curRole);
    end;
  end;
end;

procedure cRoleManager.addRolesForGroups(aRoles, aGroups: string);
var
  roleArgs: tArguments;
  curStrRole: string;
  curRole: cRole;

  groupArgs: tArguments;
  curStrGroup: string;
  curGroup: cGroup;

  foundGroupIndex: integer;
  foundRoleIndex: integer;
begin
  groupArgs := cStringUtils.explode(aGroups, ',');
  for curStrGroup in groupArgs do
  begin

    foundGroupIndex := getGroups.indexOfName(curStrGroup);
    if (foundGroupIndex = -1) then begin
      continue;
    end;

    curGroup := getGroups.items[foundGroupIndex];
    roleArgs := cStringUtils.explode(aRoles, ',');
    for curStrRole in roleArgs do begin

      foundRoleIndex := getRoles.indexOfName(curStrRole);
      if (foundRoleIndex = -1) then begin
        continue;
      end;

      curRole := getRoles.items[foundRoleIndex];

      curGroup.addRole(curRole);
    end;
  end;
end;

procedure cRoleManager.addRolesForUsers(aRoles, aUsers: string);
var
  roleArgs: tArguments;
  curStrRole: string;
  curRole: cRole;

  userArgs: tArguments;
  curStrUser: string;
  curUser: cUser;

  foundUserIndex: integer;
  foundRoleIndex: integer;
begin
  userArgs := cStringUtils.explode(aUsers, ',');
  for curStrUser in userArgs do begin

    foundUserIndex := getUsers.indexOfName(curStrUser);
    if (foundUserIndex = -1) then begin
      continue;
    end;

    curUser := getUsers.items[foundUserIndex];
    roleArgs := cStringUtils.explode(aRoles, ',');
    for curStrRole in roleArgs do begin

      foundRoleIndex := getRoles.indexOfName(curStrRole);
      if (foundRoleIndex = -1) then begin
        continue;
      end;

      curRole := getRoles.items[foundRoleIndex];

      curUser.addRole(curRole);
    end;
  end;
end;

procedure cRoleManager.addRolesForViews(aViews, aRoles: string);
var
  roleArgs: tArguments;
  curStrRole: string;
  curRole: cRole;

  viewArgs: tArguments;
  curStrView: string;
  curView: cView;

  foundViewIndex: integer;
  foundRoleIndex: integer;
begin
  viewArgs := cStringUtils.explode(aViews, ',');
  for curStrView in viewArgs do begin

    foundViewIndex := fViews.indexOfName(curStrView);
    if (foundViewIndex = -1) then begin
      continue;
    end;

    curView := getViews.items[foundViewIndex];
    roleArgs := cStringUtils.explode(aRoles, ',');
    for curStrRole in roleArgs do begin

      foundRoleIndex := getRoles.indexOfName(curStrRole);
      if (foundRoleIndex = -1) then begin
        continue;
      end;

      curRole := getRoles.items[foundRoleIndex];

      curView.addRole(curRole);
    end;
  end;
end;

procedure cRoleManager.addUser(aUserName: string; aDescription: string; const aProfile: tBytesArray);
begin
  fUsers.add(cUser.create(aUserName, aDescription, aProfile));
end;

procedure cRoleManager.addUsersToGroups(aUsers: string; aGroups: string);
var
  userArgs: tArguments;
  curStrUser: string;
  curUser: cUser;

  groupArgs: tArguments;
  curStrGroup: string;
  curGroup: cGroup;

  foundUserIndex: integer;
  foundGroupIndex: integer;
begin
  userArgs := cStringUtils.explode(aUsers, ',');
  for curStrUser in userArgs do begin

    foundUserIndex := getUsers.indexOfName(curStrUser);
    if (foundUserIndex = -1) then begin
      continue;
    end;

    curUser := getUsers.items[foundUserIndex];

    groupArgs := cStringUtils.explode(aGroups, ',');
    for curStrGroup in groupArgs do begin

      foundGroupIndex := getGroups.indexOfName(curStrGroup);
      if (foundGroupIndex = -1) then begin
        continue;
      end;

      curGroup := getGroups.items[foundGroupIndex];

      curUser.addToGroup(curGroup);
    end;
  end;
end;

procedure cRoleManager.addView(aViewName: string);
begin
  if (fViews.indexOfName(aViewName) = -1) then begin
    fViews.add(cView.create(aViewName));
  end;
end;

function cRoleManager.getCurrentUser: cUser;
begin
  result := fCurrentUser;
end;

function cRoleManager.getGroups: cGroups;
begin
  result := fGroups;
end;

class function cRoleManager.getInstance: cRoleManager;
begin
  result := cSingleton.getInstance<cRoleManager>;
end;

function cRoleManager.getRoles: cRoles;
begin
  result := fRoles;
end;

function cRoleManager.getCodeBlocks: cCodeBlocks;
begin
  result := fCodeBlocks;
end;

function cRoleManager.getUsers: cUsers;
begin
  result := fUsers;
end;

function cRoleManager.getViews: cViews;
begin
  result:= fViews;
end;

function cRoleManager.isCodeBlockAccepted(aCodeBlockName: string): boolean;
var
  foundCodeBlockIndex: integer;
  curCodeBlock: cCodeBlock;
begin
  result:= false;
  foundCodeBlockIndex:= getCodeBlocks.indexOfName(aCodeBlockName);
  if (foundCodeBlockIndex = -1) then exit;

  curCodeBlock:= getCodeBlocks.items[foundCodeBlockIndex];

  result:= isCurrentUserInRoles(curCodeBlock.getRoles.getDelimitedString);
end;

function cRoleManager.isCurrentUserInRoles(aRoles: string): boolean;
const
  ROLE_DELIMITER = ',';
var
  resultRoles: string;
  userRoles: string;
  groupRoles: string;
  resultRolesLen: integer;
begin
  result := false;

  if not(assigned(fCurrentUser)) then exit;

  resultRoles := '';
  userRoles := fCurrentUser.getRoles.getDelimitedString;
  groupRoles := fCurrentUser.getGroups.getRoles.getDelimitedString;

  resultRoles := userRoles + ROLE_DELIMITER + groupRoles;
  // userRoles is empty
  if resultRoles[1] = ROLE_DELIMITER then begin
    delete(resultRoles, 1, 1);
  end;

  resultRolesLen := length(resultRoles);

  // groupRoles is empty
  if resultRoles[resultRolesLen] = ROLE_DELIMITER then begin
    delete(resultRoles, resultRolesLen, 1);
  end;

  result:= cStringUtils.isDelimitedStringInDelimitedString(resultRoles, aRoles);
end;

function cRoleManager.isViewAccepted(aViewName: string): boolean;
var
  foundViewIndex: integer;
  curView: cView;
begin
  result:= false;
  foundViewIndex:= getViews.indexOfName(aViewName);
  if (foundViewIndex = -1) then exit;

  curView:= getViews.items[foundViewIndex];

  result:= isCurrentUserInRoles(curView.getRoles.getDelimitedString);
end;

procedure cRoleManager.loadFromFile(aFileName: string);
var
  dataFile: cFile;
begin
  dataFile:= cFile.create(aFileName, fmOpenRead);
  try
    restoreState(dataFile.toBytes);
  finally
    freeAndNil(dataFile);
  end;
end;

procedure cRoleManager.removeRolesForGroups(aRoles, aGroups: string);
var
  roleArgs: tArguments;
  curStrRole: string;

  groupArgs: tArguments;
  curStrGroup: string;
  curGroup: cGroup;

  foundRoleIndex: integer;
  foundGroupIndex: integer;
begin
  groupArgs := cStringUtils.explode(aGroups, ',');
  for curStrGroup in groupArgs do begin

    foundGroupIndex := getGroups.indexOfName(curStrGroup);
    if (foundGroupIndex = -1) then begin
      continue;
    end;

    curGroup := getGroups.items[foundGroupIndex];

    roleArgs := cStringUtils.explode(aRoles, ',');
    for curStrRole in roleArgs do begin

      foundRoleIndex := curGroup.getRoles.indexOfName(curStrRole);
      if (foundRoleIndex = -1) then begin
        continue;
      end;

      curGroup.getRoles.delete(foundRoleIndex);
    end;
  end;
end;

procedure cRoleManager.removeRolesForCodeBlocks(aRoles, aCodeBlocks: string);
var
  roleArgs: tArguments;
  curStrRole: string;

  codeBlockArgs: tArguments;
  curStrCodeBlock: string;
  curCodeBlock: cCodeBlock;

  foundRoleIndex: integer;
  foundCodeBlockIndex: integer;
begin
  codeBlockArgs := cStringUtils.explode(aCodeBlocks, ',');
  for curStrCodeBlock in codeBlockArgs do begin

    foundCodeBlockIndex := getCodeBlocks.indexOfName(curStrCodeBlock);
    if (foundCodeBlockIndex = -1) then begin
      continue;
    end;

    curCodeBlock := getCodeBlocks.items[foundCodeBlockIndex];

    roleArgs := cStringUtils.explode(aRoles, ',');
    for curStrRole in roleArgs do begin

      foundRoleIndex := curCodeBlock.getRoles.indexOfName(curStrRole);
      if (foundRoleIndex = -1) then begin
        continue;
      end;

      curCodeBlock.getRoles.delete(foundRoleIndex);
    end;
  end;
end;

procedure cRoleManager.removeRolesForUsers(aRoles, aUsers: string);
var
  roleArgs: tArguments;
  curStrRole: string;

  userArgs: tArguments;
  curStrUser: string;
  curUser: cUser;

  foundRoleIndex: integer;
  foundUserIndex: integer;
begin
  userArgs := cStringUtils.explode(aUsers, ',');
  for curStrUser in userArgs do begin

    foundUserIndex := getUsers.indexOfName(curStrUser);
    if (foundUserIndex = -1) then begin
      continue;
    end;

    curUser := getUsers.items[foundUserIndex];

    roleArgs := cStringUtils.explode(aRoles, ',');
    for curStrRole in roleArgs do begin

      foundRoleIndex := curUser.getRoles.indexOfName(curStrRole);
      if (foundRoleIndex = -1) then begin
        continue;
      end;

      curUser.getRoles.delete(foundRoleIndex);
    end;
  end;
end;

procedure cRoleManager.removeRolesForViews(aRoles, aViews: string);
var
  roleArgs: tArguments;
  curStrRole: string;

  viewArgs: tArguments;
  curStrView: string;
  curView: cView;

  foundRoleIndex: integer;
  foundViewIndex: integer;
begin
  viewArgs := cStringUtils.explode(aViews, ',');
  for curStrView in viewArgs do begin

    foundViewIndex := getViews.indexOfName(curStrView);
    if (foundViewIndex = -1) then begin
      continue;
    end;

    curView := getViews.items[foundViewIndex];

    roleArgs := cStringUtils.explode(aRoles, ',');
    for curStrRole in roleArgs do begin

      foundRoleIndex := curView.getRoles.indexOfName(curStrRole);
      if (foundRoleIndex = -1) then begin
        continue;
      end;

      curView.getRoles.delete(foundRoleIndex);
    end;
  end;
end;

procedure cRoleManager.restoreState(const aState: tBytesArray);
var
  data: cMemory;

  users: tBytesArray;
  groups: tBytesArray;
  roles: tBytesArray;
  codeBlocks: tBytesArray;
  views: tBytesArray;

  rlmHeader: ansiString;
begin
  data := cMemory.create;
  try
    data.fromBytes(aState);

    data.readAnsiString(rlmHeader);
    if rlmHeader <> RLM_HEADER then begin
      raise eRoleManager.create(INVALID_RLM_HEADER);
    end;

    data.readBytesArray(users);
    data.readBytesArray(groups);
    data.readBytesArray(roles);
    data.readBytesArray(codeBlocks);
    data.readBytesArray(views);

    getUsers.restoreState(users);
    getGroups.restoreState(groups);
    getRoles.restoreState(roles);
    getCodeBlocks.restoreState(codeBlocks);
    getViews.restoreState(views);

    getUsers.restoreGroupsState(getGroups);
    getUsers.restoreRolesState(getRoles);

    getGroups.restoreRolesState(getRoles);
    getCodeBlocks.restoreRolesState(getRoles);

    getViews.restoreRolesState(getRoles);
  finally
    freeAndNil(data);
  end;
end;

procedure cRoleManager.restrictAccessToViews(aRootViewControl: tControl);
const
  VIEW_NAME_FORMAT = '%s.%s';
var
  i: integer;
  curControl: tControl;
begin
  for i:= 0 to aRootViewControl.componentCount - 1 do begin
    if not (aRootViewControl.components[i] is tControl) then continue;

    curControl:= aRootViewControl.components[i] as tControl;

    if not isViewAccepted(format(VIEW_NAME_FORMAT, [curControl.owner.className, curControl.name])) then begin
      curControl.enabled:= false;

      if curControl is tWinControl then begin
        fLockDecorator.setControl(tWinControl(curControl));
        fLockDecorator.lockControl;
      end;

    end;
  end;
end;

function cRoleManager.saveState: tBytesArray;
var
  data: cMemory;
begin
  data := cMemory.create;
  try
    data.writeAnsiString(RLM_HEADER);
    data.writeBytesArray(getUsers.saveState);
    data.writeBytesArray(getGroups.saveState);
    data.writeBytesArray(getRoles.saveState);
    data.writeBytesArray(getCodeBlocks.saveState);
    data.writeBytesArray(getViews.saveState);

    result := data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

procedure cRoleManager.saveToFile(aFileName: string);
var
  dataFile: cFile;
begin
  dataFile:= cFile.create(aFileName, fmCreate);
  try
    dataFile.fromBytes(saveState);
  finally
    freeAndNil(dataFile);
  end;
end;

procedure cRoleManager.setCurrentUser(aUserName: string);
var
  foundIndex: integer;
begin
  foundIndex := getUsers.indexOfName(aUserName);
  if (foundIndex = -1) then exit;

  fCurrentUser := getUsers.items[foundIndex];
end;

procedure cRoleManager.setCurrentUser(aUser: cUser);
begin
  fCurrentUser := nil;
  if (getUsers.indexOf(aUser) = -1) then exit;

  fCurrentUser := aUser;
end;

end.
