unit clsCron;

interface

uses
  Windows,
  SysUtils,
  Classes;

type
   tMinutes     = 0..59;
   tHours       = 0..23;
   tWeekdays    = 0..6;
   tDaysOfMonth = 1..31;
   tMonths      = 1..12;
   tStringArray = array of string;
   tByteSet     = set of byte;


{
   Splits a string by separator (must be a single character), and return it as an
   array of strings, or a set of bytes
}

type
  cStringTokenizer = class
  public
     // Calls the overloaded version with no max tokens
    class function tokenize(aStrInput, aStrSeparator : string): tStringArray; overload;
     // Splits a string into an array of strings.
     // Tokens above iMaxTokens are included as part of the last token.
    class function tokenize(aStrInput, aStrSeparator : string; aMaxTokens : integer): tStringArray; overload;
     // Expects eg "1,2-5,9,10,35-40" and returns a set from this, if strSeparator is ","
    class function tokenizeToSet(aStrInput, aStrSeparator : string): tByteSet;
     // Expects eg "23-25" and returns a set with values [ 23, 24, 25 ]
    class function rangeToSet(aStrInput: string) : tByteSet;
  end;

{
   Represents a line of the cron file
}
type
  sCurrentDateStamp = record
    dayOfWeek  : word;
    year       : word;
    month      : word;
    day        : word;
    hour       : word;
    min        : word;
    sec        : word;
    mSec       : word;
  end;

type
  cCron = class;

  tExceptionEvent = procedure(aCron: cCron; aExcception: exception) of object;

  cCron = class
  private
    // These are set by the constructor, and checked by checkMatch
    fMinutes    : set of tMinutes;
    fHours      : set of tHours;
    fWeekdays   : set of tWeekdays;
    fDaysOfMonth: set of tDaysOfMonth;
    fMonths     : set of tMonths;

    fCronLine   : string;

    fOnException: tExceptionEvent;
  public
    // Expects a line in the format of unix crontab line, eg
    //          10,12-13 4,5 * * *
    // where the fields are "minutes, hours, weekday, day of month, month, string to execute"
    // So the above will call execute.bat at 4:10, 4:12, 4:13 and 5:10, 5:12, 5:13 every day
    // * signifies all times
    // Days of the week are 0 based, where 0 is Sunday
    constructor create(aCronLine : string);
    // Check the passed in date/time against the stored values in the above private sets
    function checkMatch(aMinute, aHour, aWeekday, aDayOfMonth, aMonth: integer) : boolean; overload;
    function checkMatch(aCurrentDateStamp: sCurrentDateStamp) : boolean; overload;

  published
    property onException: tExceptionEvent read fOnException write fOnException;
  end;

implementation


{ Tokenize a string into an array of strings, no maximum number of tokens }
class function cStringTokenizer.tokenize(aStrInput, aStrSeparator : string): tStringArray;
begin
  result:= cStringTokenizer.tokenize(aStrInput, aStrSeparator, -1);
end;

{ Tokenize a string into an array of strings }
class function cStringTokenizer.tokenize(aStrInput, aStrSeparator : string; aMaxTokens : integer): tStringArray;
var
  i               : integer;
  strCurrentToken : string;
  saTokens        : tStringArray;
  tokensCount    : integer;
begin
  setLength(result, 0);
  // This is always about twice as large as it could possibly be - a little wasteful
  setLength(saTokens, length(aStrInput));
  tokensCount:=0;
  // Go through character by character, checking for matches to strSeparator
  for i:=1 to length(aStrInput) do begin
    if ((aStrInput[i]=aStrSeparator) and not ((aMaxTokens<>-1) and (tokensCount=aMaxTokens))) then begin
      saTokens[ tokensCount ]:=strCurrentToken;
      inc(tokensCount);
      strCurrentToken:='';
    end else begin
      strCurrentToken:=strCurrentToken+aStrInput[i];
    end;
  end;

  // Don't forget the last token
  saTokens[ tokensCount ]:=strCurrentToken;
  inc(tokensCount);

  // Trim array down to correct size, and send it back
  result:= copy(saTokens, 0, tokensCount);
end;


class function cStringTokenizer.tokenizeToSet(aStrInput, aStrSeparator : string): tByteSet;
var
  stringArray: tStringArray;
  i          : integer;
  setCurrent : tByteSet;
begin
  // Set to the empty set
  setCurrent:=[];

  stringArray:=cStringTokenizer.tokenize(aStrInput, aStrSeparator);
  for i:=0 to high(stringArray) do begin
    // Okay, there should be a better way of checking whether the string's valid...
    if (stringArray[i]<>'*') then begin
      if (pos('-', stringArray[i])>0) then begin
        setCurrent:= setCurrent + cStringTokenizer.rangeToSet( stringArray[i])
      end else begin
        setCurrent:= setCurrent + [ strToInt(stringArray[i]) ];
      end;
    end;
  end;

  result:= setCurrent;
end;

{ Convert a string of the form 1-12 to a set containing all the number in between (inclusive) }
class function cStringTokenizer.rangeToSet(aStrInput : string) : tByteSet;
var
  strLeft, strRight: string;
  i, iLeft, iRight, iSwap : integer;
  setCurrent: tByteSet;
begin
  setCurrent:=[ ];
  strLeft:=copy(aStrInput, 0, pos('-', aStrInput)-1);
  strRight:=copy(aStrInput, pos('-',aStrInput)+1, length(aStrInput)-pos(aStrInput, '-')-1);

  iLeft:=strToInt(strLeft);
  iRight:=strToInt(strRight);
  if (iLeft>iRight) then begin
    iSwap:=iLeft; iLeft:=iRight; iRight:=iSwap;
  end;

  for i:=iLeft to iRight do begin
    setCurrent:=setCurrent + [ i ];
  end;

  result:= setCurrent;
end;

{cCron}

{ Create the cronline - expects a string of the form "1,4 5 * * something.bat" }
function cCron.checkMatch(aCurrentDateStamp: sCurrentDateStamp): boolean;
begin
  result:= checkMatch(aCurrentDateStamp.min, aCurrentDateStamp.hour, aCurrentDateStamp.dayOfWeek, aCurrentDateStamp.day, aCurrentDateStamp.month);
end;

constructor cCron.create(aCronLine : string);
var
  stringArray : tStringArray;
begin
  try
    stringArray:= cStringTokenizer.tokenize(aCronLine, ' ', 4);

    if (high(stringArray)<>4) then begin
      raise exception.create('cron format not valid');

      exit;
    end;

    fMinutes:= cStringTokenizer.tokenizeToSet(stringArray[0], ',');
    fHours:= cStringTokenizer.tokenizeToSet(stringArray[1], ',');
    fWeekdays:= cStringTokenizer.tokenizeToSet(stringArray[2], ',');
    fDaysOfMonth:= cStringTokenizer.tokenizeToSet(stringArray[3], ',');
    fMonths:= cStringTokenizer.tokenizeToSet(stringArray[4], ',');
  except
    on e: exception do begin
      if assigned(fOnException) then begin
        fOnException(self, e);
      end;
    end;
  end;
end;

{ Does the CronLine object match to the conditions being passed in? }
function cCron.checkMatch(aMinute, aHour, aWeekday, aDayOfMonth, aMonth : integer) : boolean;
begin
  if (((fMinutes=[]) or (aMinute in fMinutes))
    and ((fHours=[]) or (aHour in fHours))
    and ((fWeekdays=[]) or (aWeekday in fWeekdays))
    and ((fDaysOfMonth=[]) or (aDayOfMonth in fDaysOfMonth))
    and ((fMonths=[]) or (aMonth in fMonths))) then
  begin
     result:= true;
  end else begin
    result:= false;
  end;
end;


end.
