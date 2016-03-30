unit clsPGSQLDataBuilder;

interface
uses
  sysUtils,

  clsDateUtils,
  clsAbstractSQLDataBuilder,
  clsVariantConversion,

  clsStringUtils;

type
  cPGSQLDataBuilder = class(cAbstractSQLDataBuilder)
  private
    fDateFormat           : string;
    fOldDecimalSeparator  : char;

    procedure   storeDecimalSeparator;
    procedure   restoreDecimalSeparator;
  public
    function    getEscapedString(aValue: string): string;

    function    getNullFieldValue: string; override;
    function    getBytesArrayFieldValue(aValue: tBytesArray): string; override;
    function    getStringFieldValue(aValue: string): string; override;
    function    getIntegerFieldVaue(aValue: int64): string; override;
    function    getDateTimeFieldValue(aValue: tDateTime): string; override;
    function    getExtendedFieldValue(aValue: extended): string; override;
    function    getCurrencyFieldValue(aValue: currency): string; override;
    function    getBooleanFieldValue(aValue: boolean): string; override;

    function    getLowerCaseField(aValue: string): string; override;

    function    castAsString(aValue: string): string; override;
    function    castAsInteger(aValue: string): string; override;
    function    castAsDateTime(aValue: string): string; override;
    function    castAsExtended(aValue: string): string; override;
    function    castAsCurrency(aValue: string): string; override;
    function    castAsBoolean(aValue: string): string; override;
    function    castAsBytesArray(aValue: string): string; override;

    procedure   setDateFormat(aDateFormat: string);
    function    getDateFormat: string;

    constructor create;

  const
    DEFAULT_DATE_FORMAT   = 'DD.MM.YYYY hh24:mi:ss';
  end;

implementation

{ cPGSQLDataBuilder }

function cPGSQLDataBuilder.castAsBoolean(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'boolean']);
end;

function cPGSQLDataBuilder.castAsCurrency(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'numeric(18,2)']);
end;

function cPGSQLDataBuilder.castAsDateTime(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'timestamp(0) without time zone']);
end;

function cPGSQLDataBuilder.castAsExtended(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'double precision']);
end;

function cPGSQLDataBuilder.castAsInteger(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'integer']);
end;

function cPGSQLDataBuilder.castAsString(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'string']);
end;

function cPGSQLDataBuilder.castAsBytesArray(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'bytea']);
end;

constructor cPGSQLDataBuilder.create;
begin
  inherited create;
  setDateFormat(DEFAULT_DATE_FORMAT);
end;

function cPGSQLDataBuilder.getEscapedString(aValue: string): string;
var
  i: integer;
  srcLength, destLength: integer;
  srcBuffer, destBuffer: pChar;
begin
  srcLength := length(aValue);
  srcBuffer := pChar(aValue);
  destLength := 2;
  for i := 1 to srcLength do begin
    if srcBuffer^ in [#0, '''', '\'] then
      inc(destLength, 4)
    else
      inc(destLength);
    inc(srcBuffer);
  end;

  srcBuffer := pChar(aValue);
  setLength(result, destLength);
  destBuffer := pChar(result);
  destBuffer^ := '''';
  inc(destBuffer);

  for i := 1 to srcLength do begin
    if srcBuffer^ in [#0, '''', '\'] then begin
      destBuffer[0] := '\';
      destBuffer[1] := char(Ord('0') + (byte(srcBuffer^) shr 6));
      destBuffer[2] := char(Ord('0') + ((byte(srcBuffer^) shr 3) and $07));
      destBuffer[3] := char(Ord('0') + (byte(srcBuffer^) and $07));
      inc(destBuffer, 4);
    end else begin
      destBuffer^ := srcBuffer^;
      inc(destBuffer);
    end;
    inc(srcBuffer);
  end;
  destBuffer^ := '''';
end;

function cPGSQLDataBuilder.getBooleanFieldValue(aValue: boolean): string;
begin
  result:= boolToStr(aValue, true);
end;

function cPGSQLDataBuilder.getCurrencyFieldValue(aValue: currency): string;
begin
  result:= '0';

  storeDecimalSeparator;
  try
    decimalSeparator:= '.';

    result:= format('%f', [aValue]);
  finally
    restoreDecimalSeparator;
  end;
end;

function cPGSQLDataBuilder.getDateTimeFieldValue(aValue: tDateTime): string;
begin
  if (aValue < cDateUtils.MIN_UNIX_TIME) then begin
    aValue:= cDateUtils.MIN_UNIX_TIME;
  end;

  result:= format('to_timestamp(%s, %s)', [quotedStr(dateTimeToStr(aValue)), quotedStr(getDateFormat)]);
end;

function cPGSQLDataBuilder.getExtendedFieldValue(aValue: extended): string;
begin
  result:= '0';
  storeDecimalSeparator;
  try
    decimalSeparator:= '.';

    result:= format('%e', [aValue]);
  finally
    restoreDecimalSeparator;
  end;
end;

function cPGSQLDataBuilder.getIntegerFieldVaue(aValue: int64): string;
begin
  result:= format('%d', [aValue]);
end;

function cPGSQLDataBuilder.getLowerCaseField(aValue: string): string;
begin
  result:= format('lower(%s)', [aValue]);
end;

function cPGSQLDataBuilder.getNullFieldValue: string;
begin
  result:= 'null';
end;

function cPGSQLDataBuilder.getStringFieldValue(aValue: string): string;
begin
  result:= getEscapedString(aValue);
end;

function cPGSQLDataBuilder.getBytesArrayFieldValue(aValue: tBytesArray): string;
begin
  result:= quotedStr(format('\\x%s', [cStringUtils.bytesArrayToHex(aValue)]));
end;

function cPGSQLDataBuilder.getDateFormat: string;
begin
  result:= fDateFormat;
end;

procedure cPGSQLDataBuilder.setDateFormat(aDateFormat: string);
begin
  fDateFormat:= aDateFormat;
end;

procedure cPGSQLDataBuilder.storeDecimalSeparator;
begin
  fOldDecimalSeparator:= decimalSeparator;
end;

procedure cPGSQLDataBuilder.restoreDecimalSeparator;
begin
  decimalSeparator:= fOldDecimalSeparator;
end;

end.
