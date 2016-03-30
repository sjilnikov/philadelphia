unit clsCRC32;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Messages,
  Dialogs,

  SZCRC32;

type

  cCheckSum = class
    public
      class function crc32(aStream: tStream): dword;overload;
      class function crc32(aPointer: pointer; aSize: integer): dword;overload;
  end;



implementation


{ cCheckSum }

class function cCheckSum.crc32(aStream: tStream): dword;
begin
  aStream.seek(0, soFromBeginning);
  result:= SZCRC32FullStream(aStream);
end;

class function cCheckSum.crc32(aPointer: pointer; aSize: integer): dword;
begin
  result:= SZCRC32Full(aPointer, aSize);
end;

end.