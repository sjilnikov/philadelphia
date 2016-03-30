unit clsStringUtils;

interface

uses
  sysutils,
  classes,
  windows,
  variants,
  activeX,
  encdDecd,
  numeralDate,

  clsLists,
  uMetrics;

const
  STR_UTF8BOM = chr($EF) + chr($BB) + chr($BF);
  CRLF        = chr($0D) + chr($0A);
  CHRNULL     = #0;

  TEN_NUMBERS: array[0..9] of string =
  ('десять ', 'одинадцать ', 'двенадцать ', 'тринадцать ', 'четырнадцать ',
    'пятнадцать ', 'шестнадцать ', 'семнадцать ', 'восемнадцать ',
    'девятнадцать ');

type
  tArguments = array of string;
  tBytesArray = type ansiString;

  tCurrencyKind = (ctRubles, ctDollars);

  sTextCharacteristicResult = record
    words   : integer;
    length  : integer;
  end;

  cStringUtils = class
  private
  public
    class function  isDelimitedStringInDelimitedString(aCandidate: string; aString: string): boolean;
    class function  setToOrdString(const aAnySet; aSetSize: integer; aDelimiter: string = ','): string;

    class function  trimCRLF(const aString: string): string;

    class function  extractParameterFromFunction(const aFunctionBody: string; aParameterIndex: integer): string;

    class function  bytesArrayToString(const aBytesArray: tBytesArray): ansiString;
    class function  stringToBytesArray(const aString: ansiString): tBytesArray;
    class function  bytesToString(const aBytes: tBytes): ansiString;

    class function  bytesArrayToHex(const aBytesArray: tBytesArray): ansiString;
    class function  hexToBytesArray(const aHexData: tBytesArray): tBytesArray;
    class procedure insertString(var aString: string; const aSubstring: string; aOffset, aCount: integer);
    class function  findClosingParenthesis(const aStr: string; aOffset: integer = 1): integer;
    class function  lowerCaseFirstChar(const aStr: string): string;
    class function  lowerCaseChar(const aStr: string; aIndex: integer): string;
    class function  upperCaseChar(const aStr: string; aIndex: integer): string;
    class function  upperCaseFirstChar(const aStr: string): string;
    class function  getWordsCount(const aString: string; aWordLen: integer = 0): integer;

    class procedure deleteLastChar(var aStr: string);

    class function  getCloseTagPosition(const aString: string; aOffset: integer; const aOpenTag: string; const aCloseTag: string): integer;

    class function  getOccurrencesCount(aSubstr, aStr: string): integer;
    class function  explode(aStr: string; aSeparator: string = '&'): tArguments;
    class function  getArgumentValueByName(const aArguments: tArguments; aName: string; aSeparator: string = '='): string;
    class function  getArgumentIndexByName(const aArguments: tArguments; aName: string; aSeparator: string = '='): integer;
    class procedure deleteArgument(var aArguments: tArguments; aIndex: integer);

    class function  implode(const aArgs: tArguments; aSeparator: string = '&'; aUseReverse: boolean = false): string;
    class function  concat(const aStrings: array of const; aSeparator: string = ','; aConcatOnlyNotEmtpy: boolean = true): string;

    class function  getNewGUID: string;
    class function  getObfuscatedDate: string;

    class function  getCurrencyStringRepresentation(aValue: currency; aCurrencyType: tCurrencyKind = ctRubles): string;
    class function  getAmountStringRepresentation(aValue: integer): string;

    class function  numeralStr(aNum : extended; aMask : string; aPad : word; aRod1, aRod2 : Word; aDpl : word; aN1, aN2, aN3, aD1, aD2, aD3 : string): string;

    class function  getDeclination(aValue: integer; const aForms:array of string):string;
    class function  getConcatDeclination(aValue: integer; const aForms:array of string; aFormat: string = '%d %s'):string;

    class function  getTextCharacteristic(aTextArray: array of string): sTextCharacteristicResult;
  end;

  cStringListHelper = class helper for tStringList
  public
    procedure addUnique(const aValue: string);
  end;

  cStringListSortAlghoritms = class
  public
    class function compareStringsDesc(aList: tStringList; aIndex1, aIndex2: integer): integer; static;
    class function compareStringsAsc(aList: tStringList; aIndex1, aIndex2: integer): integer; static;
  end;
implementation

class function cStringUtils.findClosingParenthesis(const aStr: string; aOffset: integer): integer;
begin
  result:= getCloseTagPosition(aStr, aOffset, '(', ')');
end;

class function cStringUtils.implode(const aArgs: tArguments; aSeparator: string; aUseReverse: boolean): string;
var
  curItem: string;
  argsLength: integer;
  i: integer;
begin
  result:= '';

  argsLength:= length(aArgs);

  if aUseReverse then begin

    for i:= argsLength - 1 downto 0 do begin
      curItem:= aArgs[i];
      result:= result + aSeparator + curItem;
    end;

  end else begin

    for i:= 0 to argsLength - 1  do begin
      curItem:= aArgs[i];
      result:= result + aSeparator + curItem;
    end;

  end;


  system.delete(result, 1, 1);
end;

class function cStringUtils.lowerCaseChar(const aStr: string; aIndex: integer): string;
begin
  result:= aStr;
  result[aIndex]:= wideChar(charLower(pWideChar(aStr[1])));
end;

class function cStringUtils.upperCaseChar(const aStr: string; aIndex: integer): string;
begin
  result:= aStr;
  result[aIndex]:= wideChar(charUpper(pWideChar(aStr[1])));
end;

class function cStringUtils.lowerCaseFirstChar(const aStr: string): string;
begin
  result:= lowerCaseChar(aStr, 1);
end;

class function cStringUtils.numeralStr(aNum: extended; aMask: string; aPad, aRod1, aRod2, aDpl: word; aN1, aN2, aN3, aD1, aD2, aD3: string): string;
begin
  result:= numeralDate.numeralStr(aNum, aMask, aPad, aRod1, aRod2, aDpl, aN1, aN2, aN3, aD1, aD2, aD3);
end;

class function cStringUtils.upperCaseFirstChar(const aStr: string): string;
begin
  result:= upperCaseChar(aStr, 1);
end;

class function cStringUtils.getNewGUID: string;
var
  guid: tGuid;
begin
  result:= '';
  coInitialize(nil);
  try
    coCreateGuid(guid);

    result:= GUIDToString(guid);
  finally
    coUninitialize;
  end;
end;

class function cStringUtils.getObfuscatedDate: string;
begin
  result:= stringReplace(dateTimeToStr(now), '.', '', [rfReplaceAll]);
  result:= stringReplace(result, ' ', '', [rfReplaceAll]);
  result:= stringReplace(result, ':', '', [rfReplaceAll]);
end;

class function cStringUtils.getOccurrencesCount(aSubstr, aStr : string): integer;
var
  cnt, p : integer;
begin
  result:= 0;
  cnt := 0;
  while aStr <> '' do begin
    p := pos(aSubstr, aStr);
    if p > 0 then inc(cnt) else p := 1;
    delete(aStr, 1, (p + length(aSubstr)-1));
  end;
  result := cnt;
end;

class function cStringUtils.bytesArrayToHex(const aBytesArray: tBytesArray): ansiString;
var
  i: integer;
begin
  result:= '';
  for i := 1 to length(aBytesArray) do begin
    result:= result + IntToHex(ord(aBytesArray[i]), 2);
  end;
end;

class function cStringUtils.bytesArrayToString(const aBytesArray: tBytesArray): ansiString;
begin
  result:= encodeString(aBytesArray);
end;

class function cStringUtils.bytesToString(const aBytes: tBytes): ansiString;
var
  bytesArrLen: integer;
begin
  bytesArrLen:= length(aBytes);

  setLength(result, bytesArrLen);
  move(aBytes[0], result[1], bytesArrLen);
end;

class function cStringUtils.stringToBytesArray(const aString: ansiString): tBytesArray;
begin
  result:= decodeString(aString);
end;

class function cStringUtils.trimCRLF(const aString: string): string;
var
  crLfLen: integer;
  strLen: integer;
begin
  crLfLen:= length(CRLF);
  strLen:= length(aString);

  result:= aString;


  if (copy(aString, 1, crLfLen) = CRLF) then begin
    delete(result, 1, crLfLen);
  end;

  if (copy(aString, strLen - crLfLen + 1, crLfLen) = CRLF) then begin
    delete(result, strLen - crLfLen + 1, crLfLen);
  end;
end;

class function cStringUtils.getWordsCount(const aString: string; aWordLen: integer): integer;
const
  WORDS_DELIMITERS = [' '];
var
  i, t1, t2, len: integer;
begin
  result:= 0;

  len:= length(aString);

  if (len = 0) then exit;


  t1:= 0;
  t2:= 0;
  for i:= 1 to len do begin
    if (aString[i] in WORDS_DELIMITERS) then begin
      if (t1 >= aWordLen) then begin
        inc(t2);
      end;
      t1:= 0;
    end else begin
      inc(t1);
    end;
  end;

  if (t1 >= aWordLen) then begin
    inc(t2);
  end;

  result:= t2;
end;


class function cStringUtils.hexToBytesArray(const aHexData: tBytesArray): tBytesArray;
var
  i: integer;
begin
  result:= '';
  for i := 1 to length(aHexData) div 2 do begin
    result:= result + ansiChar(strToInt('$' + copy(aHexData, (i-1) * 2 + 1, 2)));
  end;
end;

class function cStringUtils.getTextCharacteristic(aTextArray: array of string): sTextCharacteristicResult;
var
  i: integer;
  curItem: string;
begin
  result.words:= 0;
  result.length:= 0;

  for i:= low(aTextArray) to high(aTextArray) do begin
    //|blah, |
    curItem:= trimRight(aTextArray[i]);

    inc(result.words, cStringUtils.getWordsCount(curItem));
    inc(result.length, length(curItem));
  end;
end;

class function cStringUtils.concat(const aStrings: array of const; aSeparator: string; aConcatOnlyNotEmtpy: boolean): string;
var
  i: integer;
  curValue: string;
begin
  result:= '';
  for i:= low(aStrings) to high(aStrings) do begin
    curValue:= string(tVarRec(aStrings[i]).vPWideChar);

    if (aConcatOnlyNotEmtpy) and (curValue = '') then continue;
    result:= result + aSeparator + curValue;
  end;

  system.delete(result, 1, length(aSeparator));
end;

class procedure cStringUtils.deleteArgument(var aArguments: tArguments; aIndex: integer);
var
  arrLength: integer;
  tailElements: integer;
begin
  arrLength:= length(aArguments);

  assert(arrLength > 0);
  assert(aIndex < arrLength);
  finalize(aArguments[aIndex]);

  tailElements := arrLength - aIndex;
  if tailElements > 0 then move(aArguments[aIndex + 1], aArguments[aIndex], sizeOf(aArguments[0]) * tailElements);

  initialize(aArguments[arrLength - 1]);
  setLength(aArguments, arrLength - 1);
end;

class procedure cStringUtils.deleteLastChar(var aStr: string);
begin
  delete(aStr, length(aStr), 1);
end;

class function cStringUtils.explode(aStr: string; aSeparator: string): tArguments;
var
  previousLen, separatorIndex, separatorLen: integer;
begin
  if (aStr = '') then begin
    setlength(result, 0);
    exit;
  end;

  separatorLen:= length(aSeparator);

  if pos(aSeparator, aStr) = 0 then begin
    setlength(result, 1);
    result[0] := aStr;
    exit;
  end;

  previousLen := 1;
  while (length(aStr) > 0) do begin

    setlength(result, previousLen);

    separatorIndex := pos(aSeparator, aStr);
    if separatorIndex <> 0 then begin
      result[previousLen - 1] := copy(aStr, 1, separatorIndex - 1);
      delete(aStr, 1, separatorIndex + separatorLen - 1);
    end else begin
      result[previousLen - 1] := aStr;
      break;
    end;

    inc(previousLen);
  end;

end;







class function cStringUtils.extractParameterFromFunction(const aFunctionBody: string; aParameterIndex: integer): string;
const
  TRANSIENT_START = '(';
  TRANSIENT_END = ')';
  PARAMETER_DELIMITER = ',';
var
  transientStartIndex: integer;
  bodyStartIndex: integer;
  functionBodyLen: integer;
  curBuf: string;

  i: integer;
  paramIndex: integer;
begin
  result:= '';
  transientStartIndex:= pos(TRANSIENT_START, aFunctionBody);
  if (transientStartIndex = 0) then exit;

  bodyStartIndex:= transientStartIndex + 1;

  functionBodyLen:= length(aFunctionBody);

  curBuf:= '';
  paramIndex:= -1;
  for i:= bodyStartIndex to functionBodyLen do begin
    if aFunctionBody[i] in [TRANSIENT_END, PARAMETER_DELIMITER] then begin
      inc(paramIndex);

      if (paramIndex = aParameterIndex) then begin
        result:= trim(curBuf);
        exit;
      end;

      curBuf:= '';
      continue;
    end;
    curBuf:= curBuf + aFunctionBody[i];

  end;
end;

class function cStringUtils.getAmountStringRepresentation(aValue: integer): string;
const
  C: array[0..8, 0..9] of string = (
    ('', 'одна ', 'две ', 'три ', 'четыре ', 'пять ', 'шесть ', 'семь ',
      'восемь ', 'девять '),
    ('', '', 'двадцать ', 'тридцать ', 'сорок ', 'пятьдесят ', 'шестьдесят ',
      'семьдесят ', 'восемьдесят ', 'девяносто '),
    ('', 'сто ', 'двести ', 'триста ', 'четыреста ', 'пятьсот ', 'шестьсот ',
      'семьсот ', 'восемьсот ', 'девятьсот '),
    ('тысячь ', 'одна тысяча ', 'две тысячи ', 'три тысячи ', 'четыре тысячи ',
      'пять тысяч ', 'шесть тысяч ', 'семь тысяч ', 'восемь тысяч ',
      'девять тысяч '),
    ('', '', 'двадцать ', 'тридцать ', 'сорок ', 'пятьдесят ', 'шестьдесят ',
      'семьдесят ', 'восемьдесят ', 'девяносто '),
    ('', 'сто ', 'двести ', 'триста ', 'четыреста ', 'пятьсот ', 'шестьсот ',
      'семьсот ', 'восемьсот ', 'девятьсот '),
    ('миллионов ', 'один миллион ', 'два миллиона ', 'три миллиона ',
      'четыре миллиона ', 'пять миллионов ', 'шесть миллионов ', 'семь миллионов ',
      'восемь миллионов ', 'девять миллионов '),
    ('', '', 'двадцать ', 'тридцать ', 'сорок ', 'пятьдесят ', 'шестьдесят ',
      'семьдесят ', 'восемьдесят ', 'девяносто '),
    ('', 'сто ', 'двести ', 'триста ', 'четыреста ', 'пятьсот ', 'шестьсот ',
      'семьсот ', 'восемьсот ', 'девятьсот '));
var
  s, t: string;
  p, pp, i, k: integer;
begin
  s := intToStr(aValue);
  if s = '0' then
    t := 'Ноль '
  else begin
    p := length(s);
    pp := p;
    if p > 1 then
      if (s[p - 1] = '1') and (s[p] > '0') then begin
        t := TEN_NUMBERS[strToInt(s[p])];
        pp := pp - 2;
      end;
    i := pp;
    while i > 0 do begin
      if (i = p - 3) and (p > 4) then
        if s[p - 4] = '1' then begin
          t := TEN_NUMBERS[strToInt(s[p - 3])] + 'тысяча ' + t;
          i := i - 2;
        end;
      if (i = p - 6) and (p > 7) then
        if s[p - 7] = '1' then begin
          t := TEN_NUMBERS[strToInt(s[p - 6])] + 'миллионов ' + t;
          i := i - 2;
        end;
      if i > 0 then begin
        k := strToInt(s[i]);
        t := C[p - i, k] + t;
        i := i - 1;
      end;
    end;
  end;
  result := t;
end;

class function cStringUtils.getArgumentValueByName(const aArguments: tArguments; aName: string; aSeparator: string): string;
const
  VALUE_INDEX = 1;
var
  curArg: string;
  foundIndex: integer;
begin
  result:= '';

  foundIndex:= getArgumentIndexByName(aArguments, aName);
  if foundIndex = -1 then begin
    exit;
  end;

  curArg:= aArguments[foundIndex];
  result:= explode(curArg, aSeparator)[VALUE_INDEX];
end;

class function cStringUtils.getArgumentIndexByName(const aArguments: tArguments; aName: string; aSeparator: string): integer;
const
  NAME_INDEX = 0;
var
  i: integer;
  curArg: string;
  argsLen: integer;
begin
  result:= -1;

  argsLen:= length(aArguments);

  for i:= 0 to argsLen - 1 do begin
    curArg:= aArguments[i];

    if explode(curArg, aSeparator)[NAME_INDEX] = aName then begin
      result:= i;

      exit;
    end;
  end;
end;

class function cStringUtils.getCurrencyStringRepresentation(aValue: currency; aCurrencyType: tCurrencyKind): string;

  procedure getToStr(value: string; var hi, lo: string);
  var
    p: integer;
  begin
    p := pos(',', value);
    lo := '';
    hi := '';
    if p = 0 then
      p := pos('.', value);
    if p <> 0 then
      delete(value, p, 1);
    if p = 0 then
    begin
      hi := value;
      lo := '00';
      exit;
    end;
    if p > length(value) then
    begin
      hi := value;
      lo := '00';
      exit;
    end;
    if p = 1 then
    begin
      hi := '0';
      lo := value;
      exit;
    end;
    begin
      hi := copy(value, 1, p - 1);
      lo := copy(value, p, length(value));
      if length(lo) < 2 then
        lo := lo + '0';
    end;
  end;

  function sumToString(Value: string): string;
  const
    A: array[0..8, 0..9] of string = (
      ('', 'один ', 'два ', 'три ', 'четыре ', 'пять ', 'шесть ', 'семь ',
        'восемь ', 'девять '),
      ('', '', 'двадцать ', 'тридцать ', 'сорок ', 'пятьдесят ', 'шестьдесят ',
        'семьдесят ', 'восемьдесят ', 'девяносто '),
      ('', 'сто ', 'двести ', 'триста ', 'четыреста ', 'пятьсот ', 'шестьсот ',
        'семьсот ', 'восемьсот ', 'девятьсот '),
      ('тысяч ', 'одна тысяча ', 'две тысячи ', 'три тысячи ', 'четыре тысячи ',
        'пять тысяч ', 'шесть тысяч ', 'семь тысяч ', 'восемь тысяч ',
        'девять тысяч '),
      ('', '', 'двадцать ', 'тридцать ', 'сорок ', 'пятьдесят ', 'шестьдесят ',
        'семьдесят ', 'восемьдесят ', 'девяносто '),
      ('', 'сто ', 'двести ', 'триста ', 'четыреста ', 'пятьсот ', 'шестьсот ',
        'семьсот ', 'восемьсот ', 'девятьсот '),
      ('миллионов ', 'один миллион ', 'два миллиона ', 'три миллиона ',
        'четыре миллиона ', 'пять миллионов ', 'шесть миллионов ', 'семь миллионов ',
        'восемь миллионов ', 'девять миллионов '),
      ('', '', 'двадцать ', 'тридцать ', 'сорок ', 'пятьдесят ', 'шестьдесят ',
        'семьдесят ', 'восемьдесят ', 'девяносто '),
      ('', 'сто ', 'двести ', 'триста ', 'четыреста ', 'пятьсот ', 'шестьсот ',
        'семьсот ', 'восемьсот ', 'девятьсот '));
  var
    s, t: string;
    p, pp, i, k: integer;
  begin
    s := value;
    if s = '0' then
      t := 'Ноль '
    else
    begin
      p := length(s);
      pp := p;
      if p > 1 then
        if (s[p - 1] = '1') and (s[p] >= '0') then
        begin
          t := TEN_NUMBERS[strToInt(s[p])];
          pp := pp - 2;
        end;
      i := pp;
      while i > 0 do
      begin
        if (i = p - 3) and (p > 4) then
          if s[p - 4] = '1' then
          begin
            t := TEN_NUMBERS[strToInt(s[p - 3])] + 'тысяч ' + t;
            i := i - 2;
          end;
        if (i = p - 6) and (p > 7) then
          if s[p - 7] = '1' then
          begin
            t := TEN_NUMBERS[strToInt(s[p - 6])] + 'миллионов ' + t;
            i := i - 2;
          end;
        if i > 0 then
        begin
          k := strToInt(s[i]);
          t := A[p - i, k] + t;
          i := i - 1;
        end;
      end;
    end;
    result := t;
  end;

var
  hi, lo, valut, loval: string;
  pr, er: integer;
begin
  getToStr(currToStr(aValue), hi, lo);
  if (hi = '') or (lo = '') then begin
    result := '';
    exit;
  end;

  val(hi, pr, er);
  if (er <> 0) then begin
    result := '';
    exit;
  end;

  if (aCurrencyType = ctRubles) then begin
    if hi[length(hi)] = '1' then
      valut := 'рубль ';
    if (hi[length(hi)] >= '2') and (hi[length(hi)] <= '4') then
      valut := 'рубля ';
    if (hi[length(hi)] = '0') or (hi[length(hi)] >= '5') or ((strToInt(copy(hi, length(hi) - 1, 2)) > 10) and (strToInt(copy(hi, length(hi) - 1, 2)) < 15)) then
      valut := 'рублей ';
    if (lo[length(lo)] = '0') or (lo[length(lo)] >= '5') then
      loval := ' копеек';
    if lo[length(lo)] = '1' then
      loval := ' копейка';
    if (lo[length(lo)] >= '2') and (lo[length(lo)] <= '4') then
      loval := ' копейки';
  end else begin
    if (hi[length(hi)] = '0') or (hi[length(hi)] >= '5') then
      valut := 'долларов ';
    if hi[length(hi)] = '1' then
      valut := 'доллар ';
    if (hi[length(hi)] >= '2') and (hi[length(hi)] <= '4') then
      valut := 'доллара ';
    if (lo[length(lo)] = '0') or (lo[length(lo)] >= '5') then
      loval := ' центов';
    if lo[length(lo)] = '1' then
      loval := ' цент';
    if (lo[length(lo)] >= '2') and (lo[length(lo)] <= '4') then
      loval := ' цента';
  end;

  hi := sumToString(intToStr(pr)) + valut;
  if (lo <> '00') then begin
    val(lo, pr, er);
    if er <> 0 then begin
      result := '';
      exit;
    end;
    lo := intToStr(pr);
  end;
  if length(lo) < 2 then
    lo := '0' + lo;
  lo := lo + loval;
  hi[1] := ansiUpperCase(hi[1])[1];
  result := hi + lo;
end;

class function cStringUtils.getDeclination(aValue: integer; const aForms:array of string):string;
const
  FORMS_TABLE: array[0..9] of integer = (2, 0, 1, 1, 1, 2, 2, 2, 2, 2);
begin
  if (aValue < 0) then begin
    aValue:= -aValue;
  end;

  result:= aForms[FORMS_TABLE[ord((aValue mod 100) div 10 <> 1) * (aValue mod 10)]];
end;

class procedure cStringUtils.insertString(var aString: string; const aSubstring: string; aOffset: integer; aCount: integer);
begin
  delete(aString, aOffset, aCount);
  insert(aSubstring, aString, aOffset);
end;

class function cStringUtils.isDelimitedStringInDelimitedString(aCandidate, aString: string): boolean;
var
  candidateArgs: tArguments;
  curStrCandidate: string;

  candidateLen: integer;

  baseArgs: tArguments;
  curStrBase: string;

  candidatesCount: integer;
begin
  result:= false;
  candidateArgs:= cStringUtils.explode(aCandidate, ',');
  baseArgs:= cStringUtils.explode(aString, ',');

  candidatesCount:= 0;
  candidateLen:= length(candidateArgs);
  for curStrCandidate in candidateArgs do begin
    for curStrBase in baseArgs do begin
      if curStrCandidate = curStrBase then begin
        inc(candidatesCount);
        break;
      end;
    end;

    if (candidatesCount = candidateLen) then begin
      result:= true;
      exit;
    end;

  end;
end;

class function cStringUtils.getCloseTagPosition(const aString: string; aOffset: integer; const aOpenTag: string; const aCloseTag: string): integer;
var
  curCount: integer;
  i: integer;
  strLen: integer;
  openTagFound: boolean;
begin
  result:= 0;
  curCount:= 0;
  openTagFound:= false;

  strLen:= length(aString);
  for i:= aOffset to strLen do begin

    if aString[i] = aOpenTag then begin
      openTagFound:= true;
      inc(curCount);
    end;

    if aString[i] = aCloseTag then begin
      dec(curCount);
    end;

    if (openTagFound) and (curCount = 0) then begin
      result:= i;
      exit;
    end;
  end;
end;

class function cStringUtils.getConcatDeclination(aValue: integer; const aForms: array of string; aFormat: string): string;
begin
  result:= format(aFormat, [aValue, getDeclination(aValue, aForms)]);
end;

class function cStringUtils.setToOrdString(const aAnySet; aSetSize: integer; aDelimiter: string): string;
var
  pointerToSet: pointer;
  curBitIsOn: boolean;
  i: integer;
begin
  result:= '';
  pointerToSet:= @aAnySet;
  for i:= 0 to aSetSize * BITS_IN_BYTE - 1 do begin
    curBitIsOn:= (pByte(pointerToSet)[i div BITS_IN_BYTE] shr (i mod BITS_IN_BYTE) and 1) = 1;

    if curBitIsOn then begin
      result:= result + aDelimiter + intToStr(i);
    end;
  end;

  delete(result, 1, length(aDelimiter));
end;
{ cStringListHelper }

procedure cStringListHelper.addUnique(const aValue: string);
begin
  if (self.indexOf(aValue) <> -1) then exit;

  self.add(aValue);
end;

{ cStringListSortAlghoritms }

class function cStringListSortAlghoritms.compareStringsAsc(aList: tStringList; aIndex1, aIndex2: integer): integer;
begin
  if aList.caseSensitive then
    result:= ansiCompareStr(aList.strings[aIndex1], aList.strings[aIndex2])
  else
    result:= ansiCompareText(aList.strings[aIndex1], aList.strings[aIndex2]);
end;

class function cStringListSortAlghoritms.compareStringsDesc(aList: tStringList; aIndex1, aIndex2: integer): integer;
begin
  if aList.caseSensitive then
    result:= ansiCompareStr(aList.strings[aIndex2], aList.strings[aIndex1])
  else
    result:= ansiCompareText(aList.strings[aIndex2], aList.strings[aIndex1]);
end;

end.

