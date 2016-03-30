unit clsAbstractConfig;

interface

uses
  rtti,
  variants,
  sysUtils,
  typInfo,
  dialogs,
  iniFiles,
  syncObjs,

  clsMemory,
  clsException,
  clsAbstractIOObject,
  clsVariantConversion,
  clsLists,
  clsStringUtils,
  clsClassKit,
  clsDynamicalObject;

type
  eConfig = class(cException);
  eAbstractSectionIO = class(cException);

  cAbstractConfigSection = class;

  cConfigSections = class;

  cAbstractConfig = class;

  tSectionActionProc = function(aSection: cAbstractConfigSection; aIndex: integer): string of object;

  cAbstractConfigSection = class(cDynamicalObject)
  private
    const

    SECTION_PARENTS_CYCLE_DETECTED = 'cycle detected while traversing parents';
  private
    fParent     : cAbstractConfigSection;
    fName       : string;

    function    collectSectionParentsData(aProc: tSectionActionProc; aConcatString: string): string;

  protected
    procedure   loadDefaults; virtual; abstract;
  public
    function    getParents(aProc: tSectionActionProc; aConcatString: string): string;

    function    getParent: cAbstractConfigSection;
    procedure   setParent(aParent: cAbstractConfigSection);

    function    getName: string;
    procedure   setName(aValue: string);

    constructor create(aName: string = ''; aParent: cAbstractConfigSection = nil);
    destructor  destroy; override;

    property    name: string read getName write setName;
    property    parent: cAbstractConfigSection read getParent write setParent;
    //fields

  end;

  cConfigSections = class
  private
    fList       : cList;

    function    getItemByIndex(aIndex: integer): cAbstractConfigSection;
    function    getItemByName(aName: string): cAbstractConfigSection;
  public
    function    indexOfName(aName: string): integer;

    procedure   add(aItem: cAbstractConfigSection; aParent: cAbstractConfigSection = nil);

    function    getCount: integer;

    constructor create;
    destructor  destroy; override;

    property    items[aIndex: integer]: cAbstractConfigSection read getItemByIndex;
    property    count: integer read getCount;
  end;

  //singleton
  //thread-safe
  tConfigLoadedEvent = procedure(aSender: tObject) of object;

  cAbstractConfig = class(cDynamicalObject)
  private
    const

    SECTION_IO_NOT_ASSIGNED = 'section IO not assigned';
  private
    fSections   : cConfigSections;
    fSectionIO  : cAbstractIOOProperties;
    fCS         : tCriticalSection;
    fReadOnly   : boolean;

    fOnLoaded   : tConfigLoadedEvent;

    procedure   loadSectionProc(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo);
    procedure   saveSectionProc(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo);

    procedure   lock;
    procedure   unlock;
  public

    procedure   setReadOnly(aValue: boolean);
    function    isReadOnly: boolean;

    procedure   beginIO;
    procedure   endIO;


    procedure   load; virtual;
    procedure   save; virtual;

    procedure   setSectionIO(aIO: cAbstractIOOProperties);
    function    getSectionIO: cAbstractIOOProperties;

    function    readSection(aSection: cAbstractConfigSection; aItemName: string; const aDefValue: variant): variant; overload;
    procedure   writeSection(aSection: cAbstractConfigSection; aItemName: string; const aValue: variant); overload;

    function    readSection(aSectionName: string; aDataType: tDataType; aItemName: string; const aDefValue: variant): variant; overload;
    procedure   writeSection(aSectionName: string; aDataType: tDataType; aItemName: string; const aValue: variant); overload;

    constructor create; virtual;
    destructor  destroy; override;

    property    sections: cConfigSections read fSections;

  published
    property    onLoaded: tConfigLoadedEvent read fOnLoaded write fOnLoaded;

  end;

implementation

{ cAbstractConfig }

procedure cAbstractConfig.beginIO;
begin
  lock;
end;

constructor cAbstractConfig.create;
begin
  inherited create;
  fCS:= tCriticalSection.create;

  fSections:= cConfigSections.create;

  setReadOnly(false);
end;

destructor cAbstractConfig.destroy;
begin
  if (not isReadOnly) then begin
    save;
  end;

  if assigned(fSections) then begin
    freeAndNil(fSections);
  end;

  if assigned(fCS) then begin
    freeAndNil(fCS);
  end;

  if assigned(fSectionIO) then begin
    freeAndNil(fSectionIO);
  end;

  inherited;
end;

procedure cAbstractConfig.endIO;
begin
  unlock;
end;

function cAbstractConfig.getSectionIO: cAbstractIOOProperties;
begin
  result:= fSectionIO;
end;

//recurse
procedure cAbstractConfig.loadSectionProc(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo);
var
  iteratingSection: cAbstractConfigSection;

  sectionObject: tObject;
  section: cAbstractConfigSection;
  itemName: string;

  propValue: variant;
  sectionValue: variant;
begin
  if not(aSender is cAbstractConfigSection) then exit;

  iteratingSection:= cAbstractConfigSection(aSender);
  itemName:= aPropInfo^.name;

  //if section
  sectionObject:= iteratingSection.getPropertyObject(itemName);
  if ((assigned(sectionObject)) and (sectionObject is cAbstractConfigSection)) then begin

    section := cAbstractConfigSection(sectionObject);

    section.iterateProperties(loadSectionProc);

  end else begin

    propValue:= iteratingSection.getPropertyData(itemName).value;
    sectionValue:= readSection(iteratingSection, itemName, propValue);

    iteratingSection.setPropertyData(itemName, sectionValue);

  end;
end;

function cAbstractConfig.isReadOnly: boolean;
begin
  result:= fReadOnly;
end;

procedure cAbstractConfig.setReadOnly(aValue: boolean);
begin
  fReadOnly:= aValue;
end;

procedure cAbstractConfig.lock;
begin
  fCS.enter;
end;

function cAbstractConfig.readSection(aSectionName: string; aDataType: tDataType; aItemName: string; const aDefValue: variant): variant;
begin
  result:= fSectionIO.read(aSectionName, aDataType, aItemName, aDefValue);
end;

function cAbstractConfig.readSection(aSection: cAbstractConfigSection; aItemName: string; const aDefValue: variant): variant;
begin
  result:= readSection(aSection.name, aSection.getPropertyData(aItemName).dataType, aItemName, aDefValue);
end;

procedure cAbstractConfig.load;
var
  i: integer;
  curSection: cAbstractConfigSection;
begin
  beginIO;
  try
    if (not assigned(fSectionIO)) then begin
      raise eConfig.create(SECTION_IO_NOT_ASSIGNED);
    end;

    for i:= 0 to fSections.count - 1 do begin
      curSection:= fSections.items[i];

      curSection.iterateProperties(loadSectionProc);
    end;
  finally
    endIO;
  end;

  if assigned(fOnLoaded) then begin
    fOnLoaded(self);
  end;

end;

procedure cAbstractConfig.save;
var
  i: integer;
  curSection: cAbstractConfigSection;
begin
  beginIO;
  try
    if (not assigned(fSectionIO)) then begin
      raise eConfig.create(SECTION_IO_NOT_ASSIGNED);
    end;

    for i:= 0 to fSections.count - 1 do begin
      curSection:= fSections.items[i];

      fSectionIO.beginUpdate;
      try
        curSection.iterateProperties(saveSectionProc);
      finally
        fSectionIO.endUpdate;
      end;
    end;
  finally
    endIO;
  end;
end;

procedure cAbstractConfig.saveSectionProc(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo);
var
  iteratingSection: cAbstractConfigSection;

  sectionObject: tObject;
  section: cAbstractConfigSection;
  itemName: string;
begin
  if not(aSender is cAbstractConfigSection) then exit;

  iteratingSection:= cAbstractConfigSection(aSender);
  itemName:= aPropInfo^.name;

  //if section
  sectionObject:= iteratingSection.getPropertyObject(itemName);
  if ((assigned(sectionObject)) and (sectionObject is cAbstractConfigSection)) then begin

    section := cAbstractConfigSection(sectionObject);

    section.iterateProperties(saveSectionProc);

  end else begin

    writeSection(iteratingSection, itemName, iteratingSection.getPropertyData(itemName).value);

  end;
end;

procedure cAbstractConfig.setSectionIO(aIO: cAbstractIOOProperties);
begin
  fSectionIO:= aIO;
end;

procedure cAbstractConfig.unlock;
begin
  fCS.leave;
end;

procedure cAbstractConfig.writeSection(aSectionName: string; aDataType: tDataType; aItemName: string; const aValue: variant);
begin
  fSectionIO.write(aSectionName, aDataType, aItemName, aValue);
end;

procedure cAbstractConfig.writeSection(aSection: cAbstractConfigSection; aItemName: string; const aValue: variant);
begin
  writeSection(aSection.name, aSection.getPropertyData(aItemName).dataType, aItemName, aValue);
end;

{ cAbstractConfigSection }

function cAbstractConfigSection.collectSectionParentsData(aProc: tSectionActionProc; aConcatString: string): string;
var
  i: integer;
  curSection: cAbstractConfigSection;

  parentsArr: tArguments;
begin
  result:= '';
  curSection:= self;
  i:= 0;
  while (assigned(curSection)) do begin
    if assigned(aProc) then begin
      result:= result + aConcatString + aProc(curSection, i);
    end;

    if (curSection = curSection.parent) then begin
      raise eConfig.create(SECTION_PARENTS_CYCLE_DETECTED);
    end;


    curSection:= curSection.parent;

    inc(i);
  end;
  system.delete(result, 1, length(aConcatString));

  if (result = '') then exit;

  parentsArr:= cStringUtils.explode(result, aConcatString);
  result:= cStringUtils.implode(parentsArr, aConcatString, true);
end;

constructor cAbstractConfigSection.create(aName: string; aParent: cAbstractConfigSection);
begin
  inherited create;
  fName:= aName;
  fParent:= aParent;

  loadDefaults;
end;

destructor cAbstractConfigSection.destroy;
begin
  inherited;
end;

function cAbstractConfigSection.getName: string;
const
  CUT_POS = 2;
begin
  if (fName = '') then begin
    result:= copy(self.className, CUT_POS, maxInt);
  end else begin
    result:= fName;
  end;
end;

function cAbstractConfigSection.getParent: cAbstractConfigSection;
begin
  result:= fParent;
end;

function cAbstractConfigSection.getParents(aProc: tSectionActionProc; aConcatString: string): string;
begin
  result:= collectSectionParentsData(aProc, aConcatString);
end;

procedure cAbstractConfigSection.setName(aValue: string);
begin
  fName:= aValue;
end;

procedure cAbstractConfigSection.setParent(aParent: cAbstractConfigSection);
begin
  fParent:= aParent;
end;

{ cConfigSections }

procedure cConfigSections.add(aItem: cAbstractConfigSection; aParent: cAbstractConfigSection);
begin
  aItem.setParent(aParent);
  fList.add(aItem);
end;

constructor cConfigSections.create;
begin
  inherited create;
  fList:= cList.create;
end;

destructor cConfigSections.destroy;
begin
  if assigned(fList) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

function cConfigSections.getCount: integer;
begin
  result:= fList.count;
end;

function cConfigSections.getItemByIndex(aIndex: integer): cAbstractConfigSection;
begin
  result:= fList.items[aIndex];
end;

function cConfigSections.getItemByName(aName: string): cAbstractConfigSection;
var
  foundIndex: integer;
begin
  result:= nil;

  foundIndex:= indexOfName(aName);
  if (foundIndex = -1) then begin
    exit;
  end;

  result:= items[foundIndex];
end;

function cConfigSections.indexOfName(aName: string): integer;
var
  i: integer;
  curSection: cAbstractConfigSection;
begin
  result:= -1;

  for i:= 0 to count - 1 do begin
    curSection:= items[i];

    if (curSection.name = aName) then begin
      result:= i;
      exit;
    end;


  end;
end;

end.
