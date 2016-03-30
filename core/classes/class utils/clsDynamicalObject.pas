unit clsDynamicalObject;

interface
uses
  sysUtils,
  typInfo,

  generics.collections,

  clsException,
  clsVariantConversion,
  clsClassKit;

type
  cAnyObject = type pointer;

  tDynamicalOjectType = (dotFullDynamic, dotWithProperties);

  eDynamicalObject = class(cException);

  cDynamicalObject = class
  private
    const

    METHOD_NOT_IMPLEMENTED = 'method not implemented for this type of dynamical object';
  private
    fValues     : tDictionary<string,variant>;
    fDataTypes  : tDictionary<string,tDataType>;

    fType       : tDynamicalOjectType;
  public
    const

    DEFAULT_ID_PROPERTY = 'id';
    OBJECT_ID_FORMAT    = '%s.%s';

    CANNOT_COPY_OBJECT_DATA_CLASSES_ARE_DIFFERENT_FORMAT = 'cannot copy object data, classes are different, got: %s, expected: %s';
  public
    procedure   setType(aType: tDynamicalOjectType);

    procedure   copyFrom(aObject: cDynamicalObject); virtual;

    function    getObjectId: string; virtual;

    procedure   iterateProperties(aIteratorProc: tPropertiesIteratorProc);

    procedure   setPropertyData(aName: string; const aValue: variant); virtual;
    function    getPropertyData(aName: string): sPropertyData; virtual;

    function    propertyExists(aName: string): boolean; virtual;

    function    getPropertyObject(aName: string) : tObject; virtual;

    constructor create;
    destructor  destroy; override;
  end;


implementation

{ cDynamicalObject }

procedure cDynamicalObject.copyFrom(aObject: cDynamicalObject);
begin
  if (aObject.className <> className) then begin
    raise eTypeError.createFmt(CANNOT_COPY_OBJECT_DATA_CLASSES_ARE_DIFFERENT_FORMAT, [aObject.ClassName, className]);
  end;

  iterateProperties(
    procedure(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo)
    begin
      setPropertyData(aPropInfo^.name, aObject.getPropertyData(aPropInfo^.name).value);
    end
  );
end;

constructor cDynamicalObject.create;
begin
  inherited create;

  fValues:= tDictionary<string,variant>.create;
  fDataTypes:= tDictionary<string,tDataType>.create;

  setType(dotWithProperties);
end;

destructor cDynamicalObject.destroy;
begin
  if assigned(fValues) then begin
    freeAndNil(fValues);
  end;

  if assigned(fDataTypes) then begin
    freeAndNil(fDataTypes);
  end;

  inherited;
end;

function cDynamicalObject.getObjectId: string;
begin
  result:= '';
  if propertyExists(DEFAULT_ID_PROPERTY) then begin
    //classname.id
    result:= format(OBJECT_ID_FORMAT, [className, getPropertyData(DEFAULT_ID_PROPERTY).value])
  end;
end;

function cDynamicalObject.getPropertyData(aName: string): sPropertyData;
begin
  case fType of
    dotFullDynamic:
    begin
      result.value:= fValues.items[aName];
      result.dataType:= fDataTypes.items[aName];
    end;

    dotWithProperties:
    begin
      result:= cClassKit.getObjectProperty(self, aName);
    end;
  end;
end;

function cDynamicalObject.getPropertyObject(aName: string): tObject;
begin
  case fType of
    dotFullDynamic:
    begin
      raise eDynamicalObject.create(METHOD_NOT_IMPLEMENTED);
    end;

    dotWithProperties:
    begin
      result:= cClassKit.getObjectPropertyObject(self, aName);
    end;
  end;
end;

procedure cDynamicalObject.iterateProperties(aIteratorProc: tPropertiesIteratorProc);
begin
  case fType of
    dotFullDynamic:
    begin
      raise eDynamicalObject.create(METHOD_NOT_IMPLEMENTED);
    end;

    dotWithProperties:
    begin
      cClassKit.iterateObjectProperties(self, aIteratorProc);
    end;
  end;
end;

function cDynamicalObject.propertyExists(aName: string): boolean;
begin
  case fType of
    dotFullDynamic:
    begin
      result:= fValues.containsKey(aName);
    end;

    dotWithProperties:
    begin
      result:= cClassKit.propertyExists(self, aName);
    end;
  end;
end;

procedure cDynamicalObject.setPropertyData(aName: string; const aValue: variant);
begin
  case fType of
    dotFullDynamic:
    begin
      fValues.addOrSetValue(aName, aValue);

      if not fDataTypes.containsKey(aName) then begin
        fDataTypes.addOrSetValue(aName, cVariantConversion.varTypeToDataType(aValue));
      end;

    end;

    dotWithProperties:
    begin
      cClassKit.setObjectProperty(self, aName, aValue);
    end;
  end;
end;

procedure cDynamicalObject.setType(aType: tDynamicalOjectType);
begin
  fType:= aType;
end;

end.
