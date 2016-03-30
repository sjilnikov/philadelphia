unit clsCodeBlocks;

interface
uses
  classes,
  sysUtils,

  clsMemory,
  clsRoles,
  clsLists,
  clsStringUtils;

type
  cCodeBlock = class
  var
    fRoles        : cRoles;

    fName         : string;

    fRolesState   : tBytesArray;

    procedure   initialize;
  public
    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray);

    procedure   restorRolesState(aRoles: cRoles);

    function    getRoles: cRoles;
    procedure   addRole(aRole: cRole);
    procedure   addRoles(aRoles: cRoles);

    function    getName: string;
    procedure   setName(aName: string);

    constructor create(aName: string); overload;
    constructor create; overload;
    destructor  destroy; override;
  end;

  cCodeBlocks = class
  private
    fList       : cList;
    fOwnedItems : boolean;
  public
    procedure   clear;

    function    saveState: tBytesArray;
    procedure   restoreState(const aState: tBytesArray; aSourceCodeBlocks: cCodeBlocks = nil);
    procedure   restoreRolesState(aRoles: cRoles);

    function    getItemByIndex(aIndex: integer): cCodeBlock;
    function    indexOf(aCodeBlock: cCodeBlock): integer;
    function    indexOfName(aCodeBlockName: string): integer;

    procedure   delete(aIndex: integer);
    procedure   add(aCodeBlock: cCodeBlock);
    function    getCount: integer;

    constructor create(aOwnedItems: boolean);
    destructor  destroy; override;

    property    count: integer read getCount;
    property    items[aIndex: integer]: cCodeBlock read getItemByIndex;
  end;

implementation

{ cCodeBlock }

procedure cCodeBlock.addRole(aRole: cRole);
begin
  fRoles.add(aRole);
end;

constructor cCodeBlock.create(aName: string);
begin
  inherited create;

  setName(aName);

  initialize;
end;

procedure cCodeBlock.addRoles(aRoles: cRoles);
var
  i: integer;
  curRole: cRole;
begin
  for i:= 0 to aRoles.count - 1 do begin
    curRole:= aRoles.items[i];
    addRole(curRole);
  end;
end;

constructor cCodeBlock.create;
begin
  inherited create;
  initialize;
end;

destructor cCodeBlock.destroy;
begin
  if assigned(fRoles) then begin
    freeAndNil(fRoles);
  end;

  inherited;
end;

function cCodeBlock.getName: string;
begin
  result:= fName;
end;

function cCodeBlock.getRoles: cRoles;
begin
  result:= fRoles;
end;

procedure cCodeBlock.initialize;
begin
  fRoles:= cRoles.create(false);
end;

procedure cCodeBlock.setName(aName: string);
begin
  fName:= aName;
end;

procedure cCodeBlock.restoreState(const aState: tBytesArray);
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

procedure cCodeBlock.restorRolesState(aRoles: cRoles);
begin
  getRoles.restoreState(fRolesState, aRoles);
end;

function cCodeBlock.saveState: tBytesArray;
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

{ cCodeBlocks }

procedure cCodeBlocks.clear;
begin
  if fOwnedItems then fList.freeInternalObjects;
  fList.clear;
end;

constructor cCodeBlocks.create(aOwnedItems: boolean);
begin
  inherited create;

  fOwnedItems:= aOwnedItems;

  fList:= cList.create;
end;

destructor cCodeBlocks.destroy;
begin
  if assigned(fList) then begin
    clear;

    freeAndNil(fList);
  end;

  inherited;
end;

procedure cCodeBlocks.add(aCodeBlock: cCodeBlock);
begin
  fList.add(aCodeBlock);
end;

procedure cCodeBlocks.delete(aIndex: integer);
begin
  fList.delete(aIndex);
end;

function cCodeBlocks.getCount: integer;
begin
  result:= fList.count;
end;

function cCodeBlocks.getItemByIndex(aIndex: integer): cCodeBlock;
begin
  result:= fList.items[aIndex];
end;

function cCodeBlocks.indexOfName(aCodeBlockName: string): integer;
var
  i: integer;
  curItem: cCodeBlock;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];
    if (curItem.getName = aCodeBlockName) then begin
      result:= i;
      exit;
    end;
  end;
end;

function cCodeBlocks.indexOf(aCodeBlock: cCodeBlock): integer;
begin
  result:= fList.indexOf(aCodeBlock);
end;

procedure cCodeBlocks.restoreRolesState(aRoles: cRoles);
var
  i: integer;
  curCodeBlock: cCodeBlock;
begin
  for i:= 0 to count - 1 do begin
    curCodeBlock:= items[i];

    curCodeBlock.restorRolesState(aRoles);
  end;

end;

procedure cCodeBlocks.restoreState(const aState: tBytesArray; aSourceCodeBlocks: cCodeBlocks);
var
  i: integer;

  codeBlockCount: integer;
  curCodeBlock: cCodeBlock;

  name: string;

  curRole: cRole;

  data: cMemory;
  dataCursor: tBytesArray;

  foundCodeBlockIndex: integer;
begin
  data:= cMemory.create;
  try
    data.fromBytes(aState);

    data.readInteger(codeBlockCount);

    for i:= 0 to codeBlockCount - 1 do begin

      try
        data.readBytesArray(dataCursor);
      except
        continue;
      end;

      if assigned(aSourceCodeBlocks) then begin
          curCodeBlock:= cCodeBlock.create;
          try
            curCodeBlock.restoreState(dataCursor);

            foundCodeBlockIndex:= aSourceCodeBlocks.indexOfName(curCodeBlock.getName);
            if (foundCodeBlockIndex <> -1) then begin
              add(aSourceCodeBlocks.items[foundCodeBlockIndex]);
            end;

          finally
            freeAndNil(curCodeBlock);
          end;

      end else begin
        try
          curCodeBlock:= cCodeBlock.create;
          curCodeBlock.restoreState(dataCursor);

          add(curCodeBlock);
        except
          freeAndNil(curCodeBlock);
        end;
      end;

    end;

  finally
    freeAndNil(data);
  end;
end;

function cCodeBlocks.saveState: tBytesArray;
var
  i: integer;

  codeBlockCount: integer;
  curCodeBlock: cCodeBlock;

  data: cMemory;
begin
  result:= '';
  codeBlockCount:= count;

  data:= cMemory.create;
  try
    data.writeInteger(codeBlockCount);

    for i:= 0 to count - 1 do begin
      curCodeBlock:= items[i];

      data.writeBytesArray(curCodeBlock.saveState);
    end;

    result:= data.toBytes;
  finally
    freeAndNil(data);
  end;
end;

end.

