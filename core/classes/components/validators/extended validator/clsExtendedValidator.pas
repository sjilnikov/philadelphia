unit clsExtendedValidator;

interface
uses
  math,
  sysUtils,
  variants,
  clsStringUtils,
  clsAbstractValidator;

type
  cExtendedValidator = class (cAbstractValidator)
  private
    fBottom     : extended;
    fTop        : extended;
  public
    function    getValidBoundsValue(aValue: extended): extended;

    function    fixup(aValue: variant): variant; override;
    function    validateSingleValue(aWholeData: variant; aNewValue: variant): tValidState; override;
    function    validate(var aValue: variant; var aPos: integer): tValidState; override;

    constructor create; overload;
    constructor create(aBottom, aTop: extended); overload;

    destructor  destroy; override;
  end;


implementation

{ cExtendedValidator }

constructor cExtendedValidator.create(aBottom, aTop: extended);
begin
  inherited create;

  fBottom:= aBottom;
  fTop:= aTop;
end;

constructor cExtendedValidator.create;
begin
  create(minComp, maxComp);
end;

destructor cExtendedValidator.destroy;
begin
  inherited;
end;

function cExtendedValidator.fixup(aValue: variant): variant;
var
  strValue: string;
  strLen: integer;

  firstChar, lastChar: char;

  validValue: extended;
begin
  result:= aValue;
  strValue:= varToStr(aValue);
  strLen:= length(strValue);

  if (strLen = 0) then begin
    result:= 0;
    exit;
  end;

  firstChar:= strValue[1];
  lastChar:= strValue[strLen];

  if ((firstChar in ['-', '+']) and (strLen = 1)) then begin
    result:= 0;
    exit;
  end;

  if ((lastChar in [decimalSeparator]) and (strLen <> 1)) then begin

    if tryStrToFloat(copy(strValue, 1, strLen - 1), validValue) then begin
      result:= validValue;
    end;

  end;
  result:= getValidBoundsValue(result);
end;

function cExtendedValidator.getValidBoundsValue(aValue: extended): extended;
begin
  result:= aValue;

  if (aValue > fTop) then begin
    result:= fTop;
    exit;
  end;

  if (aValue < fBottom) then begin
    result:= fBottom;
    exit;
  end;
end;

function cExtendedValidator.validate(var aValue: variant; var aPos: integer): tValidState;
var
  strValue: string;
  strLen: integer;

  firstChar, lastChar: char;

  validValue: extended;
  boundedValue: extended;
begin
  result:= vsAcceptable;

  strValue:= varToStr(aValue);

  strLen:= length(strValue);

  if (strLen = 0) then begin
    aValue:= 0;
    aPos:= 1;
    result:= vsIntermediate;
    exit;
  end;

  firstChar:= strValue[1];
  lastChar:= strValue[strLen];

  if ((firstChar in ['-', '+']) and (strLen = 1)) then begin
    result:= vsIntermediate;
    exit;
  end;

  if (cStringUtils.getOccurrencesCount(decimalSeparator, strValue) > 1) then begin
    aValue:= 0;
    result:= vsInvalid;
    exit;
  end;

  if ((lastChar in [decimalSeparator]) and (strLen > 1)) then begin
    result:= vsIntermediate;
    exit;
  end;

  if tryStrToFloat(strValue, validValue) then begin

    boundedValue:= getValidBoundsValue(validValue);
    if (validValue <> boundedValue) then begin
      aValue:= boundedValue;
      result:= vsIntermediate;
      exit;
    end;

    result:= vsAcceptable;
    exit;
  end else begin
    aValue:= 0;
    result:= vsInvalid;
    exit;
  end;

end;

function  cExtendedValidator.validateSingleValue(aWholeData: variant; aNewValue: variant): tValidState;
var
  strValue: string;
  wholeData: string;
  curChar: char;
  strLen: integer;
begin
  result:= vsAcceptable;
  wholeData:= varToStr(aWholeData);
  strValue:= varToStr(aNewValue);
  strLen:= length(strValue);

  if (strLen = 0) then begin
    result:= vsIntermediate;
    exit;
  end;

  curChar:= strValue[1];

  if not (curChar in ['-', '+', #8, '0'..'9', decimalSeparator]) then begin
    result:= vsInvalid;
    exit;
  end else begin

    if ((curChar in ['-', '+', decimalSeparator]) and (pos(curChar, wholeData) > 0)) then begin
      result:= vsIntermediate;
      exit;
    end;

  end;
end;

end.
