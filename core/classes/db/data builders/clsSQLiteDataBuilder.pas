unit clsSQLiteDataBuilder;

interface
uses
  sysUtils,

  clsDateUtils,
  clsAbstractSQLDataBuilder,
  clsVariantConversion,
  clsStringUtils;

type
  cSQLiteDataBuilder = class(cAbstractSQLDataBuilder)
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

    function    castAsBytesArray(aValue: string): string; override;
    function    castAsString(aValue: string): string; override;
    function    castAsInteger(aValue: string): string; override;
    function    castAsDateTime(aValue: string): string; override;
    function    castAsExtended(aValue: string): string; override;
    function    castAsCurrency(aValue: string): string; override;
    function    castAsBoolean(aValue: string): string; override;

    procedure   setDateFormat(aDateFormat: string);
    function    getDateFormat: string;

    constructor create;

  const
    DEFAULT_DATE_FORMAT   = 'DD.MM.YYYY hh24:mi:ss';
  end;

implementation

{ cSQLiteDataBuilder }

function cSQLiteDataBuilder.castAsBoolean(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'boolean']);
end;

function cSQLiteDataBuilder.castAsCurrency(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'float']);
end;

function cSQLiteDataBuilder.castAsDateTime(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'timestamp']);
end;

function cSQLiteDataBuilder.castAsExtended(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'real']);
end;

function cSQLiteDataBuilder.castAsInteger(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'integer']);
end;

function cSQLiteDataBuilder.castAsBytesArray(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'blob']);
end;

function cSQLiteDataBuilder.castAsString(aValue: string): string;
begin
  result:= format(CAST_STATEMENT_FORMAT, [aValue, 'varchar']);
end;

constructor cSQLiteDataBuilder.create;
begin
  inherited create;
  setDateFormat(DEFAULT_DATE_FORMAT);
end;

function cSQLiteDataBuilder.getEscapedString(aValue: string): string;
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

function cSQLiteDataBuilder.getBooleanFieldValue(aValue: boolean): string;
begin
  result:= boolToStr(aValue, false);
end;

function cSQLiteDataBuilder.getCurrencyFieldValue(aValue: currency): string;
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

function cSQLiteDataBuilder.getDateTimeFieldValue(aValue: tDateTime): string;
begin
  if (aValue < cDateUtils.MIN_UNIX_TIME) then begin
    aValue:= cDateUtils.MIN_UNIX_TIME;
  end;

  result:= quotedStr(dateTimeToStr(aValue));
end;

function cSQLiteDataBuilder.getExtendedFieldValue(aValue: extended): string;
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

function cSQLiteDataBuilder.getIntegerFieldVaue(aValue: int64): string;
begin
  result:= format('%d', [aValue]);
end;

function cSQLiteDataBuilder.getLowerCaseField(aValue: string): string;
begin
  result:= format('lower(%s)', [aValue]);
end;

function cSQLiteDataBuilder.getNullFieldValue: string;
begin
  result:= 'null';
end;

function cSQLiteDataBuilder.getBytesArrayFieldValue(aValue: tBytesArray): string;
begin
  result:= format('X%s', [quotedStr(cStringUtils.bytesArrayToHex(aValue))]);
end;

function cSQLiteDataBuilder.getStringFieldValue(aValue: string): string;
begin
  result:= getEscapedString(aValue);
end;

function cSQLiteDataBuilder.getDateFormat: string;
begin
  result:= fDateFormat;
end;

procedure cSQLiteDataBuilder.setDateFormat(aDateFormat: string);
begin
  fDateFormat:= aDateFormat;
end;

procedure cSQLiteDataBuilder.storeDecimalSeparator;
begin
  fOldDecimalSeparator:= decimalSeparator;
end;

procedure cSQLiteDataBuilder.restoreDecimalSeparator;
begin
  decimalSeparator:= fOldDecimalSeparator;
end;

end.
