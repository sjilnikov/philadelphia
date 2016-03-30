unit clsAbstractSQLDataBuilder;

interface
uses
  variants,
  sysUtils,

  uModels,

  clsStringUtils,
  clsVariantConversion;

type
  cAbstractSQLDataBuilder = class
  public
    function getNullFieldValue: string; virtual; abstract;
    function getStringFieldValue(aValue: string): string; virtual; abstract;
    function getBytesArrayFieldValue(aValue: tBytesArray): string; virtual; abstract;
    function getIntegerFieldVaue(aValue: int64): string; virtual; abstract;
    function getDateTimeFieldValue(aValue: tDateTime): string; virtual; abstract;
    function getExtendedFieldValue(aValue: extended): string; virtual; abstract;
    function getCurrencyFieldValue(aValue: currency): string; virtual; abstract;
    function getBooleanFieldValue(aValue: boolean): string; virtual; abstract;

    function getLowerCaseField(aValue: string): string; virtual; abstract;

    function castAsString(aValue: string): string; virtual; abstract;
    function castAsBytesArray(aValue: string): string; virtual; abstract;
    function castAsInteger(aValue: string): string; virtual; abstract;
    function castAsDateTime(aValue: string): string; virtual; abstract;
    function castAsExtended(aValue: string): string; virtual; abstract;
    function castAsCurrency(aValue: string): string; virtual; abstract;
    function castAsBoolean(aValue: string): string; virtual; abstract;

    function castValue(aValue: variant; aType: tDataType): string;
    function variantToFieldValue(const aValue: variant; aType: tDataType): string;
    function getNamedFieldValue(aValue: string; aName: string): string;
    function getAggregateNamedField(aName: string; aAggregateFieldType: tAggregateFieldType): string;

  const
    AGGREGATE_STATEMENT_FIELD_FORMAT = '%s(%s)';
    CAST_STATEMENT_FORMAT = 'cast(%s as %s)';
    FIELD_NAME_STATEMENT_FORMAT = '%s as %s';
  end;

implementation
uses
  clsAbstractSQLCommandsBuilder;

{ cAbstractDataBuilder }

function cAbstractSQLDataBuilder.castValue(aValue: variant; aType: tDataType): string;
begin
  result:= '';
  case aType of
    dtNotSupported  : begin
      exit;
    end;

    dtBoolean       : begin
      result:= castAsBoolean(getBooleanFieldValue(aValue));
    end;

    dtInteger       : begin
      result:= castAsInteger(getIntegerFieldVaue(aValue));
    end;

    dtInt64         : begin
      result:= castAsInteger(getIntegerFieldVaue(aValue));
    end;

    dtExtended      : begin
      result:= castAsExtended(getExtendedFieldValue(aValue));
    end;

    dtDateTime      : begin
      result:= castAsDateTime(getDateTimeFieldValue(aValue));
    end;

    dtCurrency      : begin
      result:= castAsCurrency(getCurrencyFieldValue(aValue));
    end;

    dtString        : begin
      result:= castAsString(getStringFieldValue(aValue));
    end;

    dtByteArray     : begin
      result:= castAsBytesArray(getBytesArrayFieldValue(aValue));
    end;
  end;
end;

function cAbstractSQLDataBuilder.getAggregateNamedField(aName: string; aAggregateFieldType: tAggregateFieldType): string;
const
  aggregateFieldTypeStrArr: array[low(tAggregateFieldType)..high(tAggregateFieldType)] of string = (
    cAbstractSQLCommandsBuilder.COUNT_STATEMENT,
    cAbstractSQLCommandsBuilder.SUM_STATEMENT,
    cAbstractSQLCommandsBuilder.AVERAGE_STATEMENT,
    ''
  );
begin
  result:= format(AGGREGATE_STATEMENT_FIELD_FORMAT, [aggregateFieldTypeStrArr[aAggregateFieldType], aName]);
  result:= getNamedFieldValue(result, aName)
end;

function cAbstractSQLDataBuilder.getNamedFieldValue(aValue: string; aName: string): string;
begin
  result:= format(FIELD_NAME_STATEMENT_FORMAT, [aValue, aName]);
end;

function cAbstractSQLDataBuilder.variantToFieldValue(const aValue: variant; aType: tDataType): string;
begin
  result:= getNullFieldValue;

  if (aValue = null) then exit;

  case aType of
    dtNotSupported  : exit;

    dtBoolean       : begin
      result:= getBooleanFieldValue(aValue);
    end;

    dtInteger       : begin
      result:= getIntegerFieldVaue(aValue);
    end;

    dtByte       : begin
      result:= getIntegerFieldVaue(aValue);
    end;

    dtWord       : begin
      result:= getIntegerFieldVaue(aValue);
    end;

    dtInt64         : begin
      result:= getIntegerFieldVaue(aValue);
    end;

    dtExtended      : begin
      result:= getExtendedFieldValue(aValue);
    end;

    dtDateTime      : begin
      result:= getDateTimeFieldValue(aValue);
    end;

    dtCurrency      : begin
      result:= getCurrencyFieldValue(aValue);
    end;

    dtString        : begin
      result:= getStringFieldValue(aValue);
    end;

    dtByteArray     : begin
      result:= getBytesArrayFieldValue(aValue);
    end;
  end;

end;

end.
