unit clsObjectSerializer;

interface
uses
  classes,
  windows,
  sysUtils,
  typInfo,
  variants,

  clsStringUtils,
  clsDynamicalObject,
  clsVariantConversion,
  clsException,
  clsClassKit,
  clsAbstractIOObject,
  clsMemory;

type
  eObjectSerializer = class(cException);
  eObjectSerializerIO = class(cException);

  cObjectSerializerIO = class
  private
    fIOProperties : cAbstractIOOProperties;

    procedure   checkIOProperties;
    procedure   checkObjectId(aObjectId: string);
  public
    const

    IO_PROPERTIES_NOT_ASSIGNED = 'io properties not assigned';

    CANNOT_FIND_OBJECT_FORMAT  = 'cannot find object: %s';
  public
    function    objectExists(aObject: cDynamicalObject): boolean;
    procedure   clear;

    procedure   beginUpdate;
    procedure   endUpdate;

    procedure   setIOProperties(aIOProperties: cAbstractIOOProperties);
    function    getIOProperties: cAbstractIOOProperties;

    procedure   iteratePropertesSections(aIteratorProc: tSectionsIteratorProc);

    function    getPropertiesSectionCount: integer;
    function    isPropertiesSectionsEmtpy: boolean;

    function    read(aObject: cDynamicalObject; aObjectId: string; aName: string; aDefaultValue: variant): variant;
    procedure   write(aObject: cDynamicalObject; aName: string; aValue: variant);

    constructor create;
    destructor  destroy; override;
  end;

  cObjectSerializer = class
  private
    fSerializerIO           : cObjectSerializerIO;
    fDeserializingObjectId  : string;

    procedure   serializePropertiesProc(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo);
    procedure   deserializePropertiesProc(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo);
  public
    const

    ANY_CLASS_NAME = '';
  public
    procedure   clear;
    function    obectExists(aObject: cDynamicalObject): boolean;

    procedure   iterateObjects(aIteratorProc: tSectionsIteratorProc; aClassName: string = ANY_CLASS_NAME);
    function    propertiesSectionCount: integer;

    procedure   serialize(aObject: cDynamicalObject);
    procedure   deserialize(aObject: cDynamicalObject; aId: variant);
    procedure   deserializeByObjectId(aObject: cDynamicalObject; aObjectId: variant);

    procedure   setSerializerIO(aIO: cAbstractIOOProperties);
    function    getSerializerIO: cAbstractIOOProperties;

    constructor create;
    destructor  destroy; override;
  end;

implementation

{ cObjectSerializer }

procedure cObjectSerializer.serializePropertiesProc(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo);
begin
  fSerializerIO.write(aSender as cDynamicalObject, aPropInfo^.name, cClassKit.getObjectProperty(aSender, aPropInfo^.name).value);
end;

procedure cObjectSerializer.deserializePropertiesProc(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo);
var
  readedValue: variant;
begin
  readedValue:= fSerializerIO.read(aSender as cDynamicalObject, fDeserializingObjectId, aPropInfo^.name, varToStr(null));
  if (readedValue = null) then begin
    exit;
  end;

  cClassKit.setObjectProperty(aSender, aPropInfo^.name, readedValue);
end;

destructor cObjectSerializer.destroy;
begin
  if assigned(fSerializerIO) then begin
    freeAndNil(fSerializerIO);
  end;

  inherited;
end;

function cObjectSerializer.getSerializerIO: cAbstractIOOProperties;
begin
  result:= fSerializerIO.getIOProperties;
end;

procedure cObjectSerializer.iterateObjects(aIteratorProc: tSectionsIteratorProc; aClassName: string);
var
  sectionArr: tArguments;
  objectClassName: string;
  i: integer;
begin
  if (aClassName = ANY_CLASS_NAME) then begin
    fSerializerIO.iteratePropertesSections(aIteratorProc);
    exit;
  end;


  i:= 0;
  fSerializerIO.iteratePropertesSections(
    procedure (aSection: string; aIndex: integer)
    begin
      sectionArr:= cStringUtils.explode(aSection, '.');
      if (length(sectionArr) <> 2) then begin
        exit;
      end;

      objectClassName:= sectionArr[0];

      if (objectClassName = aClassName) then begin
        aIteratorProc(aSection, i);
        inc(i);
      end;

    end
  );
end;

function cObjectSerializer.obectExists(aObject: cDynamicalObject): boolean;
begin
  result:= fSerializerIO.objectExists(aObject);
end;

function cObjectSerializer.propertiesSectionCount: integer;
begin
  result:= fSerializerIO.getPropertiesSectionCount;
end;

procedure cObjectSerializer.clear;
begin
  fSerializerIO.clear;
end;

constructor cObjectSerializer.create;
begin
  inherited create;

  fSerializerIO:= cObjectSerializerIO.create;
end;

procedure cObjectSerializer.deserialize(aObject: cDynamicalObject; aId: variant);
begin
  fDeserializingObjectId:= format(cDynamicalObject.OBJECT_ID_FORMAT, [aObject.className, varToStr(aId)]);
  aObject.iterateProperties(deserializePropertiesProc);
end;

procedure cObjectSerializer.deserializeByObjectId(aObject: cDynamicalObject; aObjectId: variant);
begin
  fDeserializingObjectId:= varToStr(aObjectId);
  aObject.iterateProperties(deserializePropertiesProc);
end;

procedure cObjectSerializer.serialize(aObject: cDynamicalObject);
begin
  if obectExists(aObject) then begin
    exit;
  end;


  fSerializerIO.beginUpdate;
  try
    aObject.iterateProperties(serializePropertiesProc);
  finally
    fSerializerIO.endUpdate;
  end;
end;

procedure cObjectSerializer.setSerializerIO(aIO: cAbstractIOOProperties);
begin
  fSerializerIO.setIOProperties(aIO);
end;

{ cObjectSerializerIO }

procedure cObjectSerializerIO.checkObjectId(aObjectId: string);
begin
  if (not fIOProperties.exists(aObjectId)) then begin
    raise eObjectSerializerIO.createFmt(CANNOT_FIND_OBJECT_FORMAT, [aObjectId]);
  end;
end;

procedure cObjectSerializerIO.clear;
begin
  checkIOProperties;

  if (getPropertiesSectionCount <> 0) then begin
    fIOProperties.clear;
  end;
end;

procedure cObjectSerializerIO.beginUpdate;
begin
  checkIOProperties;
  fIOProperties.beginUpdate;
end;

procedure cObjectSerializerIO.checkIOProperties;
begin
  if not assigned(fIOProperties) then begin
    raise eObjectSerializerIO.create(IO_PROPERTIES_NOT_ASSIGNED);
  end;
end;

constructor cObjectSerializerIO.create;
begin
   inherited create;

   fIOProperties:= nil;
end;

destructor cObjectSerializerIO.destroy;
begin
  if assigned(fIOProperties) then begin
    freeAndNil(fIOProperties);
  end;

  inherited;
end;

procedure cObjectSerializerIO.endUpdate;
begin
  checkIOProperties;
  fIOProperties.endUpdate;
end;

function cObjectSerializerIO.getIOProperties: cAbstractIOOProperties;
begin
  result:= fIOProperties;
end;

function cObjectSerializerIO.getPropertiesSectionCount: integer;
begin
  result:= 0;
  checkIOProperties;

  result:= fIOProperties.getSectionCount;
end;

function cObjectSerializerIO.isPropertiesSectionsEmtpy: boolean;
begin
  result:= true;
  checkIOProperties;
  result:= fIOProperties.isEmtpy;
end;

procedure cObjectSerializerIO.iteratePropertesSections(aIteratorProc: tSectionsIteratorProc);
begin
  checkIOProperties;
  fIOProperties.iterateSections(aIteratorProc);
end;

function cObjectSerializerIO.objectExists(aObject: cDynamicalObject): boolean;
begin
  result:= false;
  checkIOProperties;
  result:= fIOProperties.exists(aObject.getObjectId);
end;

function cObjectSerializerIO.read(aObject: cDynamicalObject; aObjectId: string; aName: string; aDefaultValue: variant): variant;
begin
  checkIOProperties;

  checkObjectId(aObjectId);

  result:= fIOProperties.read(aObjectId, aObject.getPropertyData(aName).dataType, aName, aDefaultValue);
end;

procedure cObjectSerializerIO.write(aObject: cDynamicalObject; aName: string; aValue: variant);
begin
  checkIOProperties;

  fIOProperties.write(aObject.getObjectId, aObject.getPropertyData(aName).dataType, aName, aValue);
end;

procedure cObjectSerializerIO.setIOProperties(aIOProperties: cAbstractIOOProperties);
begin
  fIOProperties:= aIOProperties;
end;


end.
