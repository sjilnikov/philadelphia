unit clsClassKit;

interface
uses
  windows,
  objAuto,
  variants,
  typInfo,
  sysUtils,
  rtti,
  activeX,

  clsException,
  clsVariantConversion;

type
  eClassError = class(exception);
  eTypeError = class(exception);

  sPropertyData = record
    value     : variant;
    dataType  : tDataType;

    class function  make(const aValue: variant; aDataType: tDataType): sPropertyData; static;
  end;

  tPropertiesIteratorProc = reference to procedure(aSender: tObject; aIndex: integer; aPropInfo: pPropInfo);


  sMethodRedirectionInfo = packed record
    address : pointer;
    bytes   : array[0..4] of byte;
  end;


  eDispatchProxy = class(cException);

  tEnumIteratorProc = reference to procedure(aEnumItem: integer);


  eMethodProxy = class(cException);
  cMethodProxy = class
  private
    const

    SELF_FIELD_NOT_FOUND = 'self field not found!';
  public
    class function makeMethod(const aMethReference): tMethod;
  end;


  cDispatchProxy = class(tInterfacedObject, iDispatch)
  private
    fInvokingName : string;

    fObject       : tObject;
  private
    function    getTypeInfoCount(out aCount: integer): hResult; virtual; stdcall;
    function    getTypeInfo(aIndex, aLocaleID: integer; out aTypeInfo): hResult; virtual; stdcall;
    function    getIDsOfNames(const aIID: tGUID; aNames: pointer; aNameCount, aLocaleID: integer; aDispIDs: pointer): hResult; virtual; stdcall;
    function    invoke(aDispID: integer; const aIID: tGUID; aLocaleID: integer; aFlags: word; var aParams; aVarResult, aExcepInfo, aArgErr: pointer): hResult; virtual; stdcall;
  public
    const

    CANNOT_INVOKE_FORMAT = 'cannot invoke: %s, object class name: %s';
  public
    constructor create(aObject: tObject);
    destructor  destroy; override;
  end;

  cClassKit = class
  private

    const

    PROPERTY_NOT_EXISTS = 'object class: %s, property: %s does not exists';
    UNKNOWN_TYPE        = 'unknown type: %s';

  private
  public
    class function  enumToString(const aTypeInfo: pTypeInfo; aIndex: integer): string;

    class procedure enumIterate(const aTypeInfo: pTypeInfo; aIteratorProc: tEnumIteratorProc);

    class procedure iterateObjectProperties(aObject: tObject; aIteratorProc: tPropertiesIteratorProc);

    class function  getObjectProperty(aObject: tObject; aProperty: string; aPreferStringsInterpretation: boolean = true): sPropertyData;

    class function  createObjectInstance(aObjectClass: tClass;  const aArgs: array of tValue) : tObject; overload;
    class function  createObjectInstance(aObjectClass: tClass) : tObject; overload;

    class function  getObjectPropertyObject(aObject: tObject; aProperty: string) : tObject;
    class function  getObjectPropertyOrd(aObject: tObject; aProperty: string) : integer; overload;
    class function  getObjectPropertyOrd(aObject: tObject; aPropInfo: pPropInfo) : integer; overload;

    class procedure setObjectProperty(aObject: tObject; aProperty: string; const aValue: variant); overload;
    class procedure setObjectProperty(aObject: tObject; aPropInfo: pPropInfo; const aValue: variant); overload;


    class function  getObjectPropertyInfo(aObject: tObject; aProperty: string; aFailIfNotExists: boolean = true): pPropInfo;

    class function  getObjectMethodAddress(aObject: tObject; aMethod: string): pointer;
    class function  getObjectMethod(aObject: tObject; aMethod: string): tMethod;

    class function  getClassMethodAddress(aClass: tClass; aMethod: string): pointer;
    class function  getClassMethod(aClass: tClass; aMethod: string): tMethod;

    class function  getObjectPropertyMethod(aObject: tObject; aProperty: string): tMethod;
    class procedure setObjectPropertyMethod(aObject: tObject; aMethod: string; aValue: tMethod);


    class function  propertyExists(aObject: tObject; aProperty: string): boolean;
    class function  methodExists(aObject: tObject; aMethod: string): boolean;

    class function  propertyAssigned(aObject: tObject; aProperty: string): boolean;

    class function  makeMethod(aSender: tObject; aMethodAddr: pointer): tMethod; overload;
    class function  makeMethod(aClass: tClass; aMethodAddr: pointer): tMethod; overload;

    class function  isMethodEquals(aMethod1: tMethod; aMethod2:tMethod): boolean;
    class function  getEmptyMethod: tMethod;

    class function  getVirtualMethodEntry(aObject: tObject; aVirtualMethodAddress: pointer): pPointer;
    class function  unProtectMemoryBlock(aProtectedBlock: pointer; aBlockSize: dWord; var aOldProtectedFlag: dWord): boolean;
    class function  protectMemoryBlock(aProtectedBlock: pointer; aBlockSize: dWord; aProtectFlag: dWord): boolean;

    class function  redirectMethod(aFromAddress, aToAddress: pointer): sMethodRedirectionInfo;
    class procedure undoRedirectMethod(const aSaveRedirection: sMethodRedirectionInfo);

    class procedure invokeMethod(aMethod: tMethod; aParams: pParameters; aStackSize: integer); overload;
    class function  invokeMethod(aMethod: tMethod; const aParams: array of variant): variant; overload;

    class function  createMethodPointerDelegation(const aDynamicInvokeEvent: tDynamicInvokeEvent; aSender: tObject; aMethod: string): tMethod; overload;
    class function  createMethodPointerDelegation(const aMethodHandler: iMethodHandler; aSender: tObject; aMethod: string): tMethod; overload;
    class procedure destroyMethodPointerDelegation(aMethodStub: tMethod);
  end;


implementation
uses
  clsMemory;
{ cClassKit }

class function cClassKit.getObjectMethodAddress(aObject: tObject; aMethod: string): pointer;
begin
  result:= aObject.methodAddress(aMethod);
end;

class function cClassKit.createMethodPointerDelegation(const aDynamicInvokeEvent: tDynamicInvokeEvent; aSender: tObject; aMethod: string): tMethod;
var
  propInfo: pPropInfo;
begin
  propInfo := getObjectPropertyInfo(aSender, aMethod);
  result   := objAuto.createMethodPointer(aDynamicInvokeEvent, getTypeData(propInfo^.propType^));
end;

class function cClassKit.createMethodPointerDelegation(const aMethodHandler: iMethodHandler; aSender: tObject; aMethod: string): tMethod;
var
  propInfo: pPropInfo;
begin
  propInfo := getObjectPropertyInfo(aSender, aMethod);
  result   := objAuto.createMethodPointer(aMethodHandler, getTypeData(propInfo^.propType^));
end;

class function cClassKit.createObjectInstance(aObjectClass: tClass): tObject;
begin
  result:= createObjectInstance(aObjectClass, []);
end;

class function cClassKit.createObjectInstance(aObjectClass: tClass;  const aArgs: array of tValue): tObject;
var
  rttiContext: tRttiContext;
  objectType: tRttiType;
  constructorMethod: tRttiMethod;
begin
  result:= nil;
  objectType:= rttiContext.getType(aObjectClass);
  if not assigned(objectType) then begin
    exit;
  end;


  constructorMethod:= objectType.getMethod('create');

  if not assigned(constructorMethod) then begin
    exit;
  end;

  result:= constructorMethod.invoke(objectType.asInstance.metaclassType, aArgs).asObject;
end;

class procedure cClassKit.destroyMethodPointerDelegation(aMethodStub: tMethod);
begin
  objAuto.releaseMethodPointer(aMethodStub);
end;

class function cClassKit.getClassMethod(aClass: tClass; aMethod: string): tMethod;
begin
  result:= makeMethod(aClass, getClassMethodAddress(aClass, aMethod));
end;

class function cClassKit.getClassMethodAddress(aClass: tClass; aMethod: string): pointer;
begin
  result:= aClass.methodAddress(aMethod);
end;

class function cClassKit.getEmptyMethod: tMethod;
begin
  result.code:= nil;
  result.data:= nil;
end;

class function cClassKit.getObjectMethod(aObject: tObject; aMethod: string): tMethod;
begin
  result:= makeMethod(aObject, getObjectMethodAddress(aObject, aMethod));
end;

class function cClassKit.getObjectProperty(aObject: tObject; aProperty: string; aPreferStringsInterpretation: boolean): sPropertyData;
var
  propInfo: pPropInfo;
  propType: shortString;
begin
  result.value      := null;
  result.dataType   := dtNotSupported;

  propInfo          := getPropInfo(aObject, aProperty);

  if (assigned(propInfo)) then begin
    result.value    := getPropValue(aObject, propInfo, aPreferStringsInterpretation);

    propType:= propInfo^.propType^^.name;

    case propInfo^.propType^^.kind of
      tkEnumeration:
      begin
        result.dataType := dtString;

        if (propType = 'Boolean') then begin
          result.dataType := dtBoolean;
          exit;
        end;

      end else begin


        if (propType = 'TDateTime') then begin
          result.dataType := dtDateTime;
          exit;
        end;

        if (propType = 'Currency') then begin
          result.dataType := dtCurrency;
          exit;
        end;

        if (propType = 'Word') then begin
          result.dataType := dtWord;
          exit;
        end;

        if (propType = 'Byte') then begin
          result.dataType := dtByte;
          exit;
        end;

        if (propType = 'AnsiString') then begin
          result.dataType := dtByteArray;
          exit;
        end;

        result.dataType := cVariantConversion.varTypeToDataType(result.value);

      end;

    end;

  end else begin
    raise eClassError.createFmt(PROPERTY_NOT_EXISTS, [quotedStr(aObject.className), quotedStr(aProperty)]);
  end;
end;

class function cClassKit.getObjectPropertyObject(aObject: tObject; aProperty: string) : tObject;
var
  propInfo : pPropInfo;

  Method: TRttiMethod;

begin
  result   := nil;
  propInfo := getObjectPropertyInfo(aObject, aProperty);
  if (assigned(propInfo) and (propInfo^.propType^^.kind = tkClass)) then
    result := tObject(getObjectPropertyOrd(aObject, propInfo));
end;

class function cClassKit.getObjectPropertyOrd(aObject: tObject; aPropInfo: pPropInfo): integer;
begin
  result:= getOrdProp(aObject, aPropInfo);
end;

class function cClassKit.getVirtualMethodEntry(aObject: tObject; aVirtualMethodAddress: pointer): pPointer;
CONST
  MAX_ENTRIES = 100;
var
  vmtStart: pPointer;
  curEntry: pPointer;
  i: integer;
begin
  result:= nil;
  {$POINTERMATH ON}
  try
    vmtStart:= pointer(aObject.classType);

    curEntry:= vmtStart;
    for i:= 0 to MAX_ENTRIES - 1 do begin
      if (pointer(curEntry^) = aVirtualMethodAddress) then begin
        result:= curEntry;
        exit;
      end;

      dec(curEntry);
    end;
  finally
  {$POINTERMATH OFF}
  end;
end;

class function cClassKit.getObjectPropertyOrd(aObject: tObject; aProperty: string): integer;
begin
  result:= getObjectPropertyOrd(aObject, aProperty);
end;

class function cClassKit.getObjectPropertyInfo(aObject: tObject; aProperty: string; aFailIfNotExists: boolean): pPropInfo;
begin
  result:= getPropInfo(aObject, aProperty);
  if (not assigned(result)) and (aFailIfNotExists) then begin
    raise eClassError.createFmt(PROPERTY_NOT_EXISTS, [quotedStr(aObject.className), quotedStr(aProperty)]);
  end;
end;

class function cClassKit.getObjectPropertyMethod(aObject: tObject; aProperty: string): tMethod;
begin
  result:= getMethodProp(aObject, aProperty);
end;

class procedure cClassKit.enumIterate(const aTypeInfo: pTypeInfo; aIteratorProc: tEnumIteratorProc);
var
  typeData: pTypeData;

  i: integer;
begin
  typeData:= getTypeData(aTypeInfo);
  for i:= typeData^.minValue to typeData^.maxValue do begin
    if (assigned(aIteratorProc)) then begin
      aIteratorProc(i);
    end;
  end;
end;

class function cClassKit.enumToString(const aTypeInfo: pTypeInfo; aIndex: integer): string;
begin
  result:= getEnumName(aTypeInfo, aIndex) ;
end;

class procedure cClassKit.iterateObjectProperties(aObject: tObject; aIteratorProc: tPropertiesIteratorProc);
var
  propList  : pPropList;
  propCount : integer;
  i: integer;
begin
  propCount:= getPropList(aObject, propList);
  try

    for i:= 0 to propCount - 1 do begin

      if assigned(aIteratorProc) then begin
        aIteratorProc(aObject, i, propList^[i]);
      end;

    end;

  finally
    freeMem(propList);
  end;
end;

class function cClassKit.makeMethod(aSender: tObject; aMethodAddr: pointer): tMethod;
begin
  result.data:= aSender;
  result.code:= aMethodAddr;
end;

class function cClassKit.invokeMethod(aMethod: tMethod; const aParams: array of variant): variant;
var
  rttiContext: tRttiContext;
  rttiMethod : tRttiMethod;

  i: integer;
  methodValue: pointer;

  methodParams: tArray<tRttiParameter>;
  methodParamsCount: integer;
  methodValues: tArray<tValue>;

  sender: tObject;

  resultValue: tValue;
begin
  result:= unassigned;

  sender:= tObject(aMethod.data);

  rttiMethod:= rttiContext.getType(sender.classType).getMethod(sender.methodName(aMethod.code));

  methodParams:= rttiMethod.getParameters;
  methodParamsCount:= length(methodParams);

  setLength(methodValues, methodParamsCount);

  for i:= 0 to methodParamsCount - 1 do begin

    if (tVarData(aParams[i]).vType  = varByRef) then begin
      methodValue:= @tVarData(aParams[i]).vPointer;
    end else begin
      methodValue:= tVarData(aParams[i]).vPointer;
    end;

    tValue.make(methodValue, methodParams[i].paramType.handle, methodValues[i]);
  end;

  resultValue:= rttiMethod.invoke(sender, methodValues);

  for i:= 0 to methodParamsCount - 1 do begin
    if not (pfVar in methodParams[i].flags) then continue;

    move(methodValues[i].getReferenceToRawData^, tVarData(aParams[i]).vPointer^, methodParams[i].paramType.typeSize);
  end;

  resultValue.tryAsType<variant>(result);
end;

class function cClassKit.isMethodEquals(aMethod1, aMethod2: tMethod): boolean;
begin
  result:= (aMethod1.data = aMethod2.data) and (aMethod1.code = aMethod2.code);
end;

class function cClassKit.makeMethod(aClass: tClass; aMethodAddr: pointer): tMethod;
begin
  result.data:= aClass;
  result.code:= aMethodAddr;
end;

class function cClassKit.methodExists(aObject: tObject; aMethod: string): boolean;
begin
  result:= assigned(getObjectMethodAddress(aObject, aMethod));
end;

class function cClassKit.propertyAssigned(aObject: tObject; aProperty: string): boolean;
begin
  result:= not isMethodEquals(getObjectPropertyMethod(aObject, aProperty), getEmptyMethod);
end;

class function cClassKit.propertyExists(aObject: tObject; aProperty: string): boolean;
begin
  result:= assigned(getObjectPropertyInfo(aObject, aProperty, false));
end;

class function cClassKit.protectMemoryBlock(aProtectedBlock: pointer; aBlockSize: dWord; aProtectFlag: dWord): boolean;
var
  oldProtectStub: dWord;
begin
  result:= virtualProtect(aProtectedBlock, aBlockSize, aProtectFlag, oldProtectStub);
end;

class procedure cClassKit.setObjectProperty(aObject: tObject; aProperty: string; const aValue: variant);
begin
  setObjectProperty(aObject, getObjectPropertyInfo(aObject, aProperty), aValue);
end;

class procedure cClassKit.setObjectPropertyMethod(aObject: tObject; aMethod: string; aValue: tMethod);
begin
  setMethodProp(aObject, aMethod, aValue);
end;

class procedure cClassKit.setObjectProperty(aObject: tObject; aPropInfo: pPropInfo; const aValue: variant);
begin
  cVariantConversion.storeNullStrictValue;
  try
    cVariantConversion.setNullStrictValue(false);

    if assigned(aPropInfo^.setProc) then begin
      setPropValue(aObject, aPropInfo, aValue);
    end;

  finally
    cVariantConversion.restoreNullStrictValue;
  end;
end;

class procedure cClassKit.invokeMethod(aMethod: tMethod; aParams: pParameters; aStackSize: integer);
const
  STACK_BYTES_ALIGNING_SIZE = sizeOf(pointer);
var
  alignedStackSize: integer;

  remainder: integer;
begin
  remainder:= aStackSize mod STACK_BYTES_ALIGNING_SIZE;
  alignedStackSize:= STACK_BYTES_ALIGNING_SIZE * (aStackSize div STACK_BYTES_ALIGNING_SIZE);
  if (remainder <> 0) then inc(alignedStackSize, STACK_BYTES_ALIGNING_SIZE);


  // check to see if there is anything on the stack.
  if alignedStackSize > 0 then
    asm
      // if there are items on the stack, allocate the space there and
      // move that data over.
      MOV ECX, alignedStackSize
      SUB ESP, ECX
      MOV EDX, ESP
      MOV EAX, aParams
      LEA EAX, [EAX].tParameters.stack[8] //skip 8 byte!!!
      CALL system.move
    end;
  asm
    // now we need to load up the registers. EDX and ECX may have some data
    // so load them on up.
    MOV EAX, aParams
    MOV EDX, [EAX].tParameters.registers.dWord[0]
    MOV ECX, [EAX].tParameters.registers.dWord[4]
    // EAX is always "self" and it changes on a per method pointer instance, so
    // grab it out of the method data.
    MOV EAX, aMethod.data
    // now we call the method. This depends on the fact that the called method
    // will clean up the stack if we did any manipulations above.
    CALL aMethod.code
  end;
end;

class function cClassKit.redirectMethod(aFromAddress, aToAddress: pointer): sMethodRedirectionInfo;
const
  X86_JUMP_INSTRUCTION = $E9;
var
  oldProtect: cardinal;
  newCode: packed record
    jmp: byte;
    distance: integer;
  end;
begin
  if not virtualProtect(aFromAddress, sizeOf(result.bytes), PAGE_EXECUTE_READWRITE, oldProtect) then begin
    raiseLastOSError;
  end;
  try

    result.address := aFromAddress;
    move(aFromAddress^, result.bytes, sizeOf(result.bytes));

    newCode.jmp := X86_JUMP_INSTRUCTION;
    newCode.distance := pByte(aToAddress) - pByte(aFromAddress) - sizeOf(result.bytes);

    move(newCode, aFromAddress^, sizeOf(result.bytes));
  finally

    if not virtualProtect(aFromAddress, sizeOf(result.bytes), oldProtect, oldProtect) then begin
      raiseLastOSError;
    end;

  end;
end;

class procedure cClassKit.undoRedirectMethod(const aSaveRedirection: sMethodRedirectionInfo);
var
  oldProtect: cardinal;
begin
  if not virtualProtect(aSaveRedirection.address, sizeOf(aSaveRedirection.bytes), PAGE_EXECUTE_READWRITE, oldProtect) then begin
    raiseLastOSError;
  end;

  move(aSaveRedirection.Bytes, aSaveRedirection.address^, sizeOf(aSaveRedirection.bytes));
  if not virtualProtect(aSaveRedirection.address, sizeOf(aSaveRedirection.bytes), oldProtect, oldProtect) then begin
    raiseLastOSError;
  end;
end;

class function cClassKit.unProtectMemoryBlock(aProtectedBlock: pointer; aBlockSize: dWord; var aOldProtectedFlag: dWord): boolean;
begin
  result:= virtualProtect(aProtectedBlock, aBlockSize, PAGE_READWRITE, aOldProtectedFlag);
end;

{ cDispatchProxy }

constructor cDispatchProxy.create(aObject: tObject);
begin
  inherited create;

  fObject:= aObject;
end;

destructor cDispatchProxy.destroy;
begin

  inherited;
end;

function cDispatchProxy.getIDsOfNames(const aIID: tGUID; aNames: pointer; aNameCount, aLocaleID: integer; aDispIDs: pointer): hResult;
begin
  result:= 0;

  fInvokingName:= strPas(pWideChar(aNames^));
end;

function cDispatchProxy.getTypeInfo(aIndex, aLocaleID: integer; out aTypeInfo): hResult;
begin
  result:= E_NOTIMPL;
end;

function cDispatchProxy.getTypeInfoCount(out aCount: integer): hResult;
begin
  result:= E_NOTIMPL;
end;

function cDispatchProxy.invoke(aDispID: integer; const aIID: tGUID; aLocaleID: integer; aFlags: word; var aParams; aVarResult, aExcepInfo, aArgErr: pointer): hResult;
type
  tValues = array of tValue;

  function getParams(aDispParams: pDispParams; aMethodParams: tArray<tRttiParameter>): tValues;
  var
    paramsCount: integer;
    paramValue: variant;
    i: integer;

    value: tValue;

    dateTimeStub: tDateTime;
    dateTypeInfo: pTypeInfo;
  begin
    paramsCount:= aDispParams^.cArgs;

    setLength(result, paramsCount);
    for i:= paramsCount - 1 downto 0 do begin
      paramValue:= variant(aDispParams^.rgvarg^[i]);

      case aMethodParams[paramsCount - i - 1].paramType.typeKind of
        tkEnumeration: begin
          tValue.make(@tVarData(paramValue).vByte, aMethodParams[paramsCount - i - 1].paramType.handle, value);
        end;
        tkFloat: begin
          dateTypeInfo:= typeInfo(tDateTime);

          if (aMethodParams[paramsCount - i - 1].paramType.name = dateTypeInfo.name) then begin
            dateTimeStub:= paramValue;
            value:= tValue.from<tDateTime>(dateTimeStub);
          end else begin
            value:= tValue.fromVariant(paramValue);
          end;

        end else begin
          value:= tValue.fromVariant(paramValue);
        end;
      end;

      result[paramsCount - i - 1]:= value;
    end;
  end;

var
  rttiType : tRttiType;
  rttiProperty: tRttiProperty;
  rttiMethod : tRttiMethod;
  rttiContext: tRttiContext;

  dispParams: pDispParams;

  resultValue: variant;
begin
  result:= S_FALSE;

  dispParams:= @aParams;

  rttiType:= rttiContext.getType(fObject.classType);

  if not assigned(rttiType) then begin
    raise eDispatchProxy.createFmt(CANNOT_INVOKE_FORMAT, [fInvokingName, fObject.className]);
  end;



  if (aFlags and ((DISPATCH_PROPERTYGET) or (DISPATCH_METHOD)) <> 0) then begin

    rttiProperty:= rttiType.getProperty(fInvokingName);
    if (dispParams^.cArgs = 0) and (assigned(rttiProperty)) then begin

      resultValue:= rttiProperty.getValue(fObject).asVariant;
      variant(aVarResult^):= resultValue;

    end else begin
      rttiMethod:= rttiType.getMethod(fInvokingName);
      if (not assigned(rttiMethod)) then begin
        raise eDispatchProxy.createFmt(CANNOT_INVOKE_FORMAT, [fInvokingName, fObject.className]);
      end;


      if assigned(rttiMethod.returnType) then begin
        resultValue:= rttiMethod.invoke(fObject, getParams(dispParams, rttiMethod.getParameters)).asVariant;
        variant(aVarResult^):= resultValue;
      end else begin
        rttiMethod.invoke(fObject, getParams(dispParams, rttiMethod.getParameters));
      end;
    end;

    result:= S_OK;
    exit;
  end;



  if (aFlags and DISPATCH_PROPERTYPUT <> 0) then begin

    if (dispParams^.cArgs = 1) then begin

      rttiProperty:= rttiType.getProperty(fInvokingName);
      if (not assigned(rttiProperty)) then begin
        raise eDispatchProxy.createFmt(CANNOT_INVOKE_FORMAT, [fInvokingName, fObject.className]);
      end;

      rttiProperty.setValue(fObject, tValue.from(variant(dispParams^.rgvarg^[0])));

    end else begin
      raise eDispatchProxy.createFmt(CANNOT_INVOKE_FORMAT, [fInvokingName, fObject.className]);
    end;

    result:= S_OK;
    exit;
  end;
end;

{cMethodProxy}

class function cMethodProxy.makeMethod(const aMethReference): tMethod;
const
  INVOKE_INTERFACE_INDEX = 3;
type
  tVtable = array[0..INVOKE_INTERFACE_INDEX] of pointer;
  pVtable = ^tVtable;
  pPVtable = ^pVtable;
var
  intf: iInterface;
  obj: tObject;
begin
  intf:= PUnknown(@aMethReference)^;
  obj := intf as tObject;

  result.code := pPVtable(aMethReference)^^[INVOKE_INTERFACE_INDEX];
  result.data := pointer(obj);
end;


{ sPropertyData }

class function sPropertyData.make(const aValue: variant; aDataType: tDataType): sPropertyData;
begin
  result.value:= aValue;
  result.dataType:= aDataType;
end;

end.
