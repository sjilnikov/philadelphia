unit clsVariantConversion;

interface
uses
  sysUtils,
  variants;

type
  tDataType = (dtNotSupported, dtBoolean, dtInteger, dtInt64, dtWord, dtByte, dtExtended, dtDateTime, dtCurrency, dtString, dtByteArray);

type
  pBytes = ^tBytes;

  cVariantConversion = class
  private
    class var fOldNullStrictConversion: boolean;
  public
    class function  varToBool(aValue: variant): boolean; static;

    class procedure storeNullStrictValue; static;
    class procedure setNullStrictValue(aValue: boolean); static;
    class procedure restoreNullStrictValue; static;

    class function  varTypeToDataType(aType: tVarType): tDataType; overload; static;
    class function  varTypeToDataType(const aValue: variant): tDataType; overload; static;

    class function  getDefaultVarValueForDataType(aDataType: tDataType): variant;

    class function  varToValue(const aValue: variant; const aDataType: tDataType): variant; static;
  end;

implementation

{ cVariantConversion }

class function cVariantConversion.getDefaultVarValueForDataType(aDataType: tDataType): variant;
begin
  result:= varToValue('', aDataType);
end;

class procedure cVariantConversion.restoreNullStrictValue;
begin
  nullStrictConvert:= fOldNullStrictConversion;
end;

class procedure cVariantConversion.setNullStrictValue(aValue: boolean);
begin
  nullStrictConvert:= aValue;
end;

class procedure cVariantConversion.storeNullStrictValue;
begin
  fOldNullStrictConversion:= nullStrictConvert;
end;

class function cVariantConversion.varToBool(aValue: variant): boolean;
begin
  result:= false;
  if (aValue = null) then begin
    exit;
  end;
  result:= tVarData(aValue).vBoolean;
end;

class function cVariantConversion.varToValue(const aValue: variant; const  aDataType: tDataType): variant;
begin
  result:= aValue;

  case aDataType of
    dtDateTime  : result:= strToDateDef(result, minDateTime);
    dtCurrency  : result:= strToCurrDef(result, 0);
    dtBoolean   : result:= strToBoolDef(result, false);
    dtInteger   : result:= strToIntDef(result, 0);
    dtInt64     : result:= strToInt64Def(result, int64(0));
    dtExtended  : result:= strToFloatDef(result, 0E+01);
    dtByteArray : result:= '';
  end;
end;

class function cVariantConversion.varTypeToDataType(const aValue: variant): tDataType;
begin
  result:= varTypeToDataType(varType(aValue));
end;

class function cVariantConversion.varTypeToDataType(aType: tVarType): tDataType;
const
  VAR_BYTE_ARRAY = varArray or varByte;
begin
  result:= dtNotSupported;
  case aType of
    varSmallint    : result:= dtInteger;
    varInteger     : result:= dtInteger;
    varSingle      : result:= dtExtended;
    varDouble      : result:= dtExtended;
    varCurrency    : result:= dtCurrency;
    varDate        : result:= dtDateTime;
    varBoolean     : result:= dtBoolean;
    varShortInt    : result:= dtInteger;
    varInt64       : result:= dtInt64;
    varWord        : result:= dtWord;
    varByte        : result:= dtByte;
    varLongWord    : result:= dtInt64;
    varUInt64      : result:= dtInt64;
    varString      : result:= dtByteArray;
    varUString     : result:= dtString;
  end;
end;



end.
