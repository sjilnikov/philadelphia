unit clsMemory;

interface
uses
  classes,
  windows,
  sysUtils,

  uMetrics,
  clsException,
  clsStringUtils,
  clsClassKit,
  clsAbstractIOObject;

type
  eMemory = class(cException);

  cMemory = class(cAbstractIOObject)
  private
    fMemory   : pointer;
    fSize     : longInt;
    fPosition : longInt;
    fCapacity   : longint;
  private
    procedure   setCapacity(aNewCapacity: longint);
  protected
    procedure   setPointer(aPtr: pointer; aSize: longInt);
    function    realloc(var aNewCapacity: longint): pointer; virtual;
  public
    const

    OUT_OF_MEMORY = 'Out of memory while expanding memory stream';
  public
    procedure   setSize(aNewSize: longint); override;

    function    write(const aBuffer; aCount: longint): longint; override;
    function    read(var aBuffer; aCount: longint): longint; override;
    function    seek(aOffset: longint; aOrigin: word): longint; override;

    function    toBinaryString: ansiString;
    procedure   fromBinaryString(const aString: ansiString);

    procedure   saveToStream(aStream: tStream);
    procedure   saveToFile(const aFileName: string);

    procedure   loadFromStream(aStream: tStream);
    procedure   loadFromFile(const aFileName: string);

    procedure   clear;

    destructor  destroy; override;

    property    memory: pointer read fMemory;
    property    capacity: longint read fCapacity write setCapacity;
  end;

const
  MEMORY_DELTA = 8 * KBYTE; { must be a power of 2 }


implementation
uses
  clsFile;

{ cMemory }

procedure cMemory.fromBinaryString(const aString: ansiString);
begin
  fromBytes(cStringUtils.stringToBytesArray(aString));
end;

function cMemory.read(var aBuffer; aCount: Integer): longint;
begin
  if (fPosition >= 0) and (aCount >= 0) then
  begin
    result := fSize - fPosition;
    if result > 0 then begin
      if result > aCount then begin
        result := aCount;
      end;

      move(pointer(longint(fMemory) + fPosition)^, aBuffer, result);
      inc(fPosition, result);
      exit;
    end;
  end;
  result := 0;
end;

procedure cMemory.saveToFile(const aFileName: string);
var
  stream: cFile;
begin
  stream := cFile.create(aFileName, fmCreate);
  try
    saveToStream(stream);
  finally
    freeAndNil(stream);
  end;
end;

procedure cMemory.saveToStream(aStream: tStream);
begin
  if (fSize <> 0) then begin
    aStream.writeBuffer(fMemory^, fSize);
  end;
end;

function cMemory.seek(aOffset: longInt; aOrigin: word): longInt;
begin
  case aOrigin of
    soFromBeginning : fPosition := aOffset;
    soFromCurrent   : inc(fPosition, aOffset);
    soFromEnd       : fPosition := fSize + aOffset;
  end;
  result := fPosition;
end;

procedure cMemory.setPointer(aPtr: pointer; aSize: Integer);
begin
  fMemory := aPtr;
  fSize   := aSize;
end;

function cMemory.toBinaryString: ansiString;
begin
  result:= cStringUtils.bytesArrayToString(toBytes);
end;

{ ÒMemory }

destructor cMemory.destroy;
begin
  clear;
  inherited;
end;

procedure cMemory.clear;
begin
  setCapacity(0);
  fSize := 0;
  fPosition := 0;
end;

procedure cMemory.loadFromFile(const aFileName: string);
var
  stream: cFile;
begin
  stream := cFile.create(aFileName, fmOpenRead or fmShareDenyWrite);
  try
    loadFromStream(stream);
  finally
    freeAndNil(stream);
  end;
end;

procedure cMemory.loadFromStream(aStream: tStream);
var
  count: longint;
begin
  aStream.position := 0;
  count:= aStream.size;
  setSize(count);
  if (count <> 0) then begin
    aStream.readBuffer(fMemory^, count);
  end;
end;

function cMemory.realloc(var aNewCapacity: Integer): pointer;
begin
  if (aNewCapacity > 0) and (aNewCapacity <> fSize) then
    aNewCapacity := (aNewCapacity + (MEMORY_DELTA - 1)) and not (MEMORY_DELTA - 1);
  result := memory;
  if aNewCapacity <> fCapacity then begin
    if aNewCapacity = 0 then begin
      freeMem(memory);
      result := nil;
    end else begin
      if capacity = 0 then begin
        getMem(result, aNewCapacity)
      end else begin
        reallocMem(result, aNewCapacity);
      end;

      if not assigned(result) then begin
        raise eMemory.create(OUT_OF_MEMORY);
      end;
    end;
  end;
end;

procedure cMemory.setCapacity(aNewCapacity: longInt);
begin
  setPointer(realloc(aNewCapacity), fSize);
  fCapacity := aNewCapacity;
end;

procedure cMemory.setSize(aNewSize: longInt);
var
  oldPosition: longint;
begin
  oldPosition := fPosition;
  setCapacity(aNewSize);
  fSize := aNewSize;
  if (oldPosition > aNewSize) then begin
    seek(0, soFromEnd);
  end;
end;

function cMemory.write(const aBuffer; aCount: longInt): longint;
var
  pos: longint;
begin
  if (fPosition >= 0) and (aCount >= 0) then begin
    pos := fPosition + aCount;
    if (pos > 0) then begin
      if (pos > fSize) then begin
        if (pos > fCapacity) then begin
          setCapacity(pos);
        end;

        fSize := pos;
      end;

      system.move(aBuffer, pointer(longint(fMemory) + fPosition)^, aCount);
      fPosition := pos;
      result := aCount;

      exit;
    end;
  end;

  result := 0;
end;

end.
