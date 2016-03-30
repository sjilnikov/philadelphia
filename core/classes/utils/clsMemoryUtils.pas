unit clsMemoryUtils;

interface

uses Windows, Classes, SysUtils;

//todo: attach iterator?
type
  cPointers = class
  public
    class function shift(aP: pointer; aShift: integer):pointer;
    class function copyBufToPChar(aSrc: pointer; var aDst: pAnsiChar; aSize: integer): boolean;

    class function readBufAsStr(aSrc: pointer; aLength: integer): ansiString;
    class function readBufAsInt(aSrc: pointer): integer;
    class function readBufAsDword(aSrc: pointer): dword;
    class function readBufAsDateTime(aSrc: pointer): tDateTime;
    class function readBufToStream(aSrc: pointer; aSize: integer;
      aStream: tStream): boolean;
  end;



implementation

{ cPointers }

class function cPointers.copyBufToPChar(aSrc: pointer; var aDst: pAnsiChar; aSize: integer): boolean;
begin
  result:= true;
  try
    move(aSrc^, aDst^, aSize);
    ansiChar(cPointers.shift(aDst, aSize)^):= #0;
  except
    result:= false;
  end;
end;

class function cPointers.readBufAsInt(aSrc: pointer): integer;
begin
  result:= integer(aSrc^);
end;

class function cPointers.readBufAsDword(aSrc: pointer): dword;
begin
  result:= dword(aSrc^);
end;

class function cPointers.readBufAsDateTime(aSrc: pointer): tDateTime;
begin
  result:= tDateTime(aSrc^);
end;

class function cPointers.readBufAsStr(aSrc: pointer; aLength: integer): ansiString;
var
  tmpVar: pAnsiChar;
begin
  result:= emptyStr;

  tmpVar:= nil;
  try
    getMem(tmpVar, aLength+1);

    cPointers.copyBufToPChar(aSrc, tmpVar, aLength);

    result:= strPas(tmpVar);
  finally
    freeMem(tmpVar, aLength+1);
    pointer(tmpVar):= nil;
  end;
end;

class function cPointers.readBufToStream(aSrc: pointer;
  aSize: integer; aStream: tStream): boolean;
begin
  result:= true;
  try
    aStream.Write(aSrc^, aSize);
  except
    result:= false;
  end;
end;

class function cPointers.shift(aP: pointer; aShift: integer): pointer;
begin
  result:= pointer(integer(aP)+aShift);
end;

end.
