unit clsDBTypeConversion;

interface
uses
  db,
  clsVariantConversion;

type

  cDBTypeConversion = class
  public
    class function dataTypeToFieldType(aDataType: tDataType): tFieldType;
    class function fieldTypeToDataType(aFieldType: tFieldType): tDataType;
  end;

implementation

class function cDBTypeConversion.fieldTypeToDataType(aFieldType: tFieldType): tDataType;
begin
  result:= dtNotSupported;
  case aFieldType of
    ftUnknown      : result:= dtNotSupported;
    ftString       : result:= dtString;
    ftMemo         : result:= dtString;
    ftSmallint     : result:= dtInteger;
    ftInteger      : result:= dtInteger;
    ftWord         : result:= dtInteger;
    ftBoolean      : result:= dtBoolean;
    ftFloat        : result:= dtExtended;
    ftCurrency     : result:= dtCurrency;
    ftBCD          : result:= dtCurrency;
    ftDate         : result:= dtDateTime;
    ftTime         : result:= dtDateTime;
    ftDateTime     : result:= dtDateTime;
    ftWideString   : result:= dtString;
    ftLargeint     : result:= dtInt64;
    ftShortint     : result:= dtInteger;
    ftExtended     : result:= dtExtended;
    ftSingle       : result:= dtExtended;
  end;
end;

class function cDBTypeConversion.dataTypeToFieldType(aDataType: tDataType): tFieldType;
begin
  result:= ftUnknown;
  case aDataType of
    dtNotSupported      : result:= ftUnknown;
    dtString            : result:= ftString;
    dtInteger           : result:= ftInteger;
    dtBoolean           : result:= ftBoolean;
    dtExtended          : result:= ftFloat;
    dtCurrency          : result:= ftCurrency;
    dtDateTime          : result:= ftDate;
    dtInt64             : result:= ftLargeint;
  end;
end;

end.
