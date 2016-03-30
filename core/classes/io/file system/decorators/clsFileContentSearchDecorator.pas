unit clsFileContentSearchDecorator;

interface
uses
  windows,
  sysUtils,
  classes,

  uMetrics,
  clsFile,
  clsAbstractFileDecorator;

type
  cFileContentSearchDecorator = class(cAbstractFileDecorator)
  private
    function BMFind(szSubStr, buf: PAnsiChar; iBufSize: integer; wholeword_only: boolean): integer;
  public
    function isContainsSubstring(aSubstring: ansistring; aWhole: boolean): boolean;
  end;

implementation

{ cContentSearchDecorator }

function cFileContentSearchDecorator.isContainsSubstring(aSubstring: ansistring; aWhole: boolean): boolean;
const
   BUFF_SIZE = 8 * KBYTE;
var
   numRead: longint;
   buffer: array [0..BUFF_SIZE - 1] of ansiChar;
   findBuffer: array [0..255] of ansiChar;
   found: boolean;
begin
  strPCopy(findBuffer, aSubstring);
  found:= false;
  repeat
    numRead:= getFile.read(Buffer, BUFF_SIZE);
    if BMFind(findBuffer, buffer, numRead, aWhole) >= 0 then begin
      found := true
    end else begin
      // more to scan
      if (numRead = BUFF_SIZE) then begin
        getFile.position := getFile.position - (length(aSubstring) - 1);
      end;
    end;
  until found or (numRead < BUFF_SIZE);
  result := found;
end;

//Boyer-Moore search: http://en.wikipedia.org/wiki/Boyer%E2%80%93Moore_string_search_algorithm
function cFileContentSearchDecorator.BMFind(szSubStr, buf: PAnsiChar; iBufSize: integer; wholeword_only: boolean): integer;
{ Returns -1 if substring not found, or zero-based index into buffer if substring found }
var
  iSubStrLen: integer;
  skip: array [ansiChar] of integer;
  found: boolean;
  iMaxSubStrIdx: integer;
  iSubStrIdx: integer;
  iBufIdx: integer;
  iScanSubStr: integer;
  mismatch: boolean;
  iBufScanStart: integer;
  ch: ansiChar;
begin
  found := False;
  Result := -1;
  iSubStrLen := StrLen(szSubStr);
  if iSubStrLen = 0 then
  begin
    Result := 0;
    Exit
  end;
   iMaxSubStrIdx := iSubStrLen - 1;
  { Initialize the skip table }
  for ch := Low(skip) to High(skip) do skip[ch] := iSubStrLen;
  for iSubStrIdx := 0 to (iMaxSubStrIdx - 1) do
    skip[szSubStr[iSubStrIdx]] := iMaxSubStrIdx - iSubStrIdx;
   { Scan the buffer, starting comparisons at the end of the substring }
  iBufScanStart := iMaxSubStrIdx;
  while (not found) and (iBufScanStart < iBufSize) do
  begin
    iBufIdx := iBufScanStart;
    iScanSubStr := iMaxSubStrIdx;
    repeat
      mismatch := (szSubStr[iScanSubStr] <> buf[iBufIdx]);
      if not mismatch then
        if iScanSubStr > 0 then
        begin // more characters to scan
          Dec(iBufIdx); Dec(iScanSubStr)
        end
        else
          found := True;
    until mismatch or found;
    if found and wholeword_only then
    begin
      if (iBufIdx > 0) then
        found := not IsCharAlphaA(buf[iBufIdx - 1]);
      if found then
        if iBufScanStart < (iBufSize - 1) then
          found := not IsCharAlphaA(buf[iBufScanStart + 1]);
    end;
    if found then
      Result := iBufIdx
    else
      iBufScanStart := iBufScanStart + skip[buf[iBufScanStart]];
  end;
end;
end.
