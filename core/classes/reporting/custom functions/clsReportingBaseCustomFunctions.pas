unit clsReportingBaseCustomFunctions;

interface
uses
  sysUtils,
  classes,
  fs_iinterpreter,

  clsStringUtils;

type

  cReportingBaseCustomFunctions = class(tFsRTTIModule)
  private
    const

    CATEGORY_NAME = 'basic functions';
  private
    function    callMethod(aInstance: tObject; aClassType: tClass; const aMethodName: string; var aParams: variant): variant;
  public
    constructor create(aScript: tFsScript); override;
  end;

implementation
uses
  clsReporting;

{ cReportingBaseCustomFunctions }

constructor cReportingBaseCustomFunctions.create(aScript: tFsScript);
begin
  inherited create(aScript);
  with aScript do begin
    addMethod('function getCurrencyStringRepresentation(aValue: currency): string', callMethod, CATEGORY_NAME, 'ѕеревод денежного значени€ в строковое представление');
    addMethod('function getAmountStringRepresentation(aNum : extended; aMask : string; aPad : word; aRod1, aRod2 : Word; aDpl : word; aN1, aN2, aN3, aD1, aD2, aD3 : string): string', callMethod, CATEGORY_NAME, 'ѕеревод числового значени€ в строковое представление');
    addMethod('function getCondition: string', callMethod, CATEGORY_NAME, 'ѕолучить текущее условие');
  end;
end;

function cReportingBaseCustomFunctions.callMethod(aInstance: tObject; aClassType: tClass; const aMethodName: string; var aParams: variant): variant;
begin
  if ansiSameText(aMethodName, 'getCurrencyStringRepresentation') then begin
    result:= cStringUtils.getCurrencyStringRepresentation(aParams[0]);
    exit;
  end;

  if ansiSameText(aMethodName, 'getAmountStringRepresentation') then begin
    result:= cStringUtils.numeralStr(
      aParams[0],
      aParams[1],
      aParams[2],
      aParams[3],
      aParams[4],
      aParams[5],
      aParams[6],
      aParams[7],
      aParams[8],
      aParams[9],
      aParams[10],
      aParams[10]
    );
    exit;
  end;

  if ansiSameText(aMethodName, 'getCondition') then begin
    result:= cReporting.getInstance.getCondition;
    exit;
  end;
end;

initialization
  fsRTTIModules.add(cReportingBaseCustomFunctions);
end.

