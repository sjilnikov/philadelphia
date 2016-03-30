unit clsScriptEngine;

interface
uses
  classes,
  sysUtils,
  rtti,
  activeX,
  typInfo,
  generics.collections,


  atScript,
  atPascal,

  clsClassKit,

  clsLists,

  clsException,
  clsFile,
  clsMulticastEvents;

type
  eScriptEngine = class(cException);


  tMachineProcRef = reference to procedure(aMachine : tAtVirtualMachine);

  cInternalScriptMachineProcProxy = class
  private
    fMachineProc: tMachineProcRef;
    procedure   handlerStub(aMachine : tAtVirtualMachine);
  public
    constructor create(aMachineProc: tMachineProcRef);
    function    getMethod: tMethod;
  end;

  cInternalScriptMethodsProxy = class
  private
    fList: cList;
  public
    procedure   add(aProxy: tObject);

    constructor create;
    destructor  destroy; override;
  end;

  cDispatchVar = class
  private
    fObject        : tObject;
    fName          : string;
  public
    function    getDispatchProxy: variant;
    function    getName: string;

    constructor create(aObject: tObject; aName: string);
    destructor  destroy; override;

    property    name: string read getName;
  end;

  cScriptEngine = class
  private
    fPSScript          : tAtPascalScripter;
    fExtensions        : tStringList;

    fMethodsProxy      : cInternalScriptMethodsProxy;

    fOldScriptCode     : string;

    procedure   setupEvents;
    procedure   disconnectEvents;

    function    getExtensionsCode: string;


    procedure   internalExecute(aSourceCode: string);
    function    internalEvaluate(aSourceCode: string): variant;
  public
    const

    COMPILE_ERROR_FORMAT  = 'compile error, message: %s';
    EXECUTE_ERROR_FORMAT  = 'execute error, message: %s';
    EVALUATE_ERROR_FORMAT = 'evaluate error, message: %s';
  public
    procedure   setScriptText(aValue: string);
    function    getScriptText: string;

    function    isSubroutineExists(aName: string): boolean;

    function    executeSubroutine(aName:string; aArg: variant ): variant; overload;
    function    executeSubroutine(aName:string ): variant; overload;
    function    executeSubroutine(aName:string; aArg: array of const ): variant; overload;

    function    defineClass(aClass: tClass): tAtClass;
    function    defineMethod(aName: string; aArgCount: integer; aResultDataType: tAtTypeKind; aResultClass: tClass; aProc: tMachineProcRef; aIsClassMethod: boolean = false; aDefArgCount: integer = 0): tAtMethod;

    procedure   addEnumeration(aTypeInfo: pTypeInfo);
    procedure   addObject(aName: string; aObject: tObject);
    procedure   addVariable(aName: string; var aValue: variant);
    procedure   addConst(aName: string; const aValue: variant);

    procedure   clearExtensions;
    procedure   addExtension(aExtensionName: string; aExtensionCode: string);
    procedure   addExtensionFromFile(aExtensionName: string; aExtensionFileName: string);

    function    getExtension(aExtensionName: string): string; overload;
    function    getExtension(aExtensionIndex: integer): string; overload;
    function    getExtensionCount: integer;

    function    evaluate(aExpression: string): variant;
    procedure   execute(aExpression: string);

    procedure   compile;
    function    isCompiled: boolean;

    constructor create;
    destructor  destroy; override;
  published
    //SLOTS
  end;

implementation

constructor cScriptEngine.create;
begin
  inherited create;

  fMethodsProxy:= cInternalScriptMethodsProxy.create;

  fExtensions:= tStringList.create;

  fExtensions.delimiter:= char(0);
  fExtensions.lineBreak:= char(0);
  fExtensions.quoteChar:= char(0);

  fPSScript:= tAtPascalScripter.create(nil);
  fPSScript.optionExplicit:= true;

  setupEvents;
end;

function cScriptEngine.defineClass(aClass: tClass): tAtClass;
begin
  result:= fPSScript.defineClass(aClass);
end;

function cScriptEngine.defineMethod(aName: string; aArgCount: integer; aResultDataType: tAtTypeKind; aResultClass: tClass; aProc: tMachineProcRef; aIsClassMethod: boolean; aDefArgCount: integer): tAtMethod;
var
  machineMethodProxy: cInternalScriptMachineProcProxy;
  method: tMethod;
begin
  machineMethodProxy:= cInternalScriptMachineProcProxy.create(aProc);
  method:= machineMethodProxy.getMethod;

  fMethodsProxy.add(machineMethodProxy);

  result:= fPSScript.defineMethod(aName, aArgCount, aResultDataType, aResultClass, tMachineProc(method), aIsClassMethod, aDefArgCount);
end;

destructor cScriptEngine.destroy;
begin
  disconnectEvents;

  if assigned(fPSScript) then begin
    freeAndNil(fPSScript);
  end;

  if assigned(fExtensions) then begin
    freeAndNil(fExtensions);
  end;

  if assigned(fMethodsProxy) then begin
    freeAndNil(fMethodsProxy);
  end;

  inherited;
end;

procedure cScriptEngine.setScriptText(aValue: string);
var
  scriptCode: string;
  i: integer;
begin
  scriptCode:= getExtensionsCode;

  scriptCode:= scriptCode + aValue;

  if (scriptCode = fOldScriptCode) then exit;

  fOldScriptCode:= scriptCode;

  fPSScript.sourceCode.text:= scriptCode;

  fPSScript.compile;
end;

procedure cScriptEngine.setupEvents;
begin
end;

procedure cScriptEngine.disconnectEvents;
begin
end;

function cScriptEngine.evaluate(aExpression: string): variant;
begin
  result:= internalEvaluate(aExpression);
end;

procedure cScriptEngine.execute(aExpression: string);
begin
  internalExecute(aExpression);
end;

function cScriptEngine.executeSubroutine(aName: string; aArg: variant): variant;
begin
  result:= fPSScript.executeSubroutine(aName, aArg);
end;

function cScriptEngine.executeSubroutine(aName: string): variant;
begin
  result:= fPSScript.executeSubroutine(aName);
end;

function cScriptEngine.executeSubroutine(aName: string; aArg: array of const): variant;
begin
  result:= fPSScript.executeSubroutine(aName, aArg);
end;

function cScriptEngine.getExtension(aExtensionName: string): string;
begin
  result:= fExtensions.values[aExtensionName]
end;

function cScriptEngine.getExtension(aExtensionIndex: integer): string;
begin
  result:= fExtensions.valueFromIndex[aExtensionIndex];
end;

function cScriptEngine.getExtensionCount: integer;
begin
  result:= fExtensions.count;
end;

function cScriptEngine.getExtensionsCode: string;
const
  DELIMITER = #10#13;
var
  i: integer;
begin
  result:= '';
  for i:= 0 to getExtensionCount - 1 do begin

    result:= result + DELIMITER + getExtension(i);
  end;

  delete(result, 1, length(DELIMITER));
end;

function cScriptEngine.getScriptText: string;
begin
  result:= fPSScript.sourceCode.text;
end;

procedure cScriptEngine.addConst(aName: string; const aValue: variant);
begin
  fPSScript.addConstant(aName, aValue);
end;

procedure cScriptEngine.addEnumeration(aTypeInfo: pTypeInfo);
begin
  fPSScript.addEnumeration(aTypeInfo);
end;

procedure cScriptEngine.addExtension(aExtensionName: string; aExtensionCode: string);
begin
  fExtensions.values[aExtensionName]:= aExtensionCode;
end;

procedure cScriptEngine.addExtensionFromFile(aExtensionName: string; aExtensionFileName: string);
var
  extFile: cFile;

  fileContent: ansiString;
begin
  extFile:= cFile.create(aExtensionFileName, fmOpenRead or fmShareDenyNone);
  try
    setLength(fileContent, extFile.size);


    extFile.read(fileContent[1], extFile.size);

    addExtension(aExtensionName, fileContent);

  finally
    freeAndNil(extFile);
  end;
end;

procedure cScriptEngine.addObject(aName: string; aObject: tObject);
begin
  fPSScript.addObject(aName, aObject);
end;

procedure cScriptEngine.addVariable(aName: string; var aValue: variant);
begin
  fPSScript.addVariable(aName, aValue);
end;

function cScriptEngine.internalEvaluate(aSourceCode: string): variant;
begin
  result:= '';
  try

    if (aSourceCode = '') then begin
      exit;
    end;


    setScriptText(format('result:=%s;', [aSourceCode]));

    result:= fPSScript.execute;
  except
    on e: exception do begin
      raise eScriptEngine.createFmt(EVALUATE_ERROR_FORMAT, [e.message]);
    end;
  end;
end;

procedure cScriptEngine.internalExecute(aSourceCode: string);
begin
  try
    if (aSourceCode = '') then begin
      exit;
    end;

    setScriptText(aSourceCode);

    fPSScript.execute;
  except
    on e: exception do begin
      raise eScriptEngine.createFmt(EXECUTE_ERROR_FORMAT, [e.message]);
    end;
  end;
end;

function cScriptEngine.isCompiled: boolean;
begin
  result:= fPSScript.compiled;
end;

function cScriptEngine.isSubroutineExists(aName: string): boolean;
var
  routineInfo: tAtRoutineInfo;
begin
  routineInfo:= fPSScript.scriptInfo.routineByName(aName);
  result:= assigned(routineInfo);
end;

procedure cScriptEngine.clearExtensions;
begin
  fExtensions.clear;
end;

procedure cScriptEngine.compile;
begin
  fPSScript.compile;
end;

{ cDispatchVar }

constructor cDispatchVar.create(aObject: tObject; aName: string);
begin
  inherited create;

  fObject:= aObject;
  fName:= aName;
end;

destructor cDispatchVar.destroy;
begin
  inherited;
end;

function cDispatchVar.getDispatchProxy: variant;
begin
  result:= (cDispatchProxy.create(fObject)) as iDispatch;
end;

function cDispatchVar.getName: string;
begin
  result:= fName;
end;


{ cMethodsProxy }

constructor cInternalScriptMethodsProxy.create;
begin
  inherited create;
  fList:= cList.create;
end;

destructor cInternalScriptMethodsProxy.destroy;
begin
  if assigned(fList) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

procedure cInternalScriptMethodsProxy.add(aProxy: tObject);
begin
  fList.add(aProxy);
end;

{ cInternalScriptMachineProcProxy }

constructor cInternalScriptMachineProcProxy.create(aMachineProc: tMachineProcRef);
begin
  inherited create;
  fMachineProc:= aMachineProc;
end;

function cInternalScriptMachineProcProxy.getMethod: tMethod;
begin
  result.code:= @cInternalScriptMachineProcProxy.handlerStub;
  result.data:= self;
end;

procedure cInternalScriptMachineProcProxy.handlerStub(aMachine: tAtVirtualMachine);
begin
  fMachineProc(aMachine);
end;

end.

