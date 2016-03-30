unit clsRichEditHelper;

interface
uses
  sysUtils,
  richEdit,
  comCtrls,
  commCtrl,
  windows,

  clsMemory;

type
  cRichEditHelper = class helper for tRichEdit
  public
    procedure appendRTF(const aRawRTF: string);
    function  getRawRTF: string;
    procedure setRawRTF(const aRawRTF: string);
  end;

implementation

{ cRichEditHelper }

function cRichEditHelper.getRawRTF: string;
var
  stream: cMemory;
begin
  stream:= cMemory.create;
  try
    lines.saveToStream(stream);
    result:= stream.toBinaryString;
  finally
    freeAndNil(stream);
  end;
end;

procedure cRichEditHelper.setRawRTF(const aRawRTF: string);
var
  stream: cMemory;
begin
  if (aRawRTF = '') then exit;


  stream:= cMemory.create;
  try
    stream.fromBinaryString(aRawRTF);
    lines.loadFromStream(stream);

  finally
    freeAndNil(stream);
  end;
end;

procedure cRichEditHelper.appendRTF(const aRawRTF: string);
var
  memStream: cMemory;
  RTFStream: tEditStream;


  function editStreamReader(dwCookie: DWORD; pBuff: pointer; cb: longInt; pcb: pLongInt): DWORD; stdcall;
  begin
    result := $0000;
    try
      pcb^:= cMemory(dwCookie).read(pBuff^, cb);
    except
      result := $FFFF;
    end;
  end;

begin
   if (aRawRTF = '') then exit;

   memStream := cMemory.create;
   try
    memStream.fromBinaryString(aRawRTF);

    rtfStream.dwCookie := DWORD(memStream) ;
    rtfStream.dwError := $0000;
    rtfStream.pfnCallback := @editStreamReader;
    try
      selStart:= length(text);

      perform(
        EM_STREAMIN,
        SFF_SELECTION or SF_RTF or SFF_PLAINRTF, LPARAM(@RTFStream)
      );

      if (rtfStream.dwError <> $0000) then begin
        raise exception.create('errorAppendingRTFData');
      end;

    except
      on e: exception do
       // do nothing
    end;
  finally
    freeAndNil(memStream);
  end;
end;

end.
