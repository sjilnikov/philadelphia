unit clsAbstractIOObject;

interface
uses
  classes,
  sysUtils,
  syncObjs,

  clsStringUtils,
  clsException,
  clsVariantConversion,
  clsClassKit;

type
  eAbstractIOOProperties = class(cException);


  //thread-safe
  cAbstractIOObject = class(tStream)
  private
    fCS          : tCriticalSection;

  public
    function     isEmpty: boolean;

    procedure    fromBytes(const aBytes: tBytesArray);
    function     toBytes: tBytesArray;

    function     readAtOffset(aOffset: int64; aOrigin: tSeekOrigin; var aBuffer; aCount: integer): longint;
    function     writeAtOffset(aOffset: int64; aOrigin: tSeekOrigin; const aBuffer; aCount: integer): longint;

    function     readAnsiString(var aValue: ansiString): longint;
    function     writeAnsiString(aValue: ansiString): longint;

    function     readBytesArray(var aValue: tBytesArray): longint;
    function     writeBytesArray(aValue: tBytesArray): longint;

    function     readUnicodeString(var aValue: string): longint;
    function     writeUnicodeString(aValue: string): longint;

    function     readInteger(var aValue: integer): longint; overload;
    function     readInteger(var aValue: int64): longint; overload;

    function     writeInteger(aValue: int64): longint; overload;
    function     writeInteger(aValue: integer): longint; overload;

    function     readBool(var aValue: boolean): longint;
    function     writeBool(aValue: boolean): longint;

    function     writeEnum(const aValue): longint;
    function     readEnum(var aValue): longint;

    function     readStream(aStream: cAbstractIOObject): longint;
    function     writeStream(aStream: cAbstractIOObject): longint;

    procedure    lock;
    procedure    unlock;

    constructor  create; virtual;
    destructor   destroy; override;
  end;


  tSectionsIteratorProc = reference to procedure(aSection: string; aIndex: integer);

  cAbstractIOOProperties = class
  private
    fUpdating   : boolean;
  protected
    procedure   commit; virtual; abstract;
  public
    const

    ITERATOR_PROC_NOT_ASSIGNED = 'iterator proc not assigned';
    METHOD_NOT_REALIZED        = 'method not realized';
  public
    procedure   clear; virtual; abstract;

    procedure   saveToStream(aStream: tStream); virtual; abstract;
    procedure   loadFromStream(aStream: tStream); virtual; abstract;

    procedure   save; virtual;
    procedure   load; virtual; abstract;

    procedure   beginUpdate;
    procedure   endUpdate;

    procedure   iterateSections(aIteratorProc: tSectionsIteratorProc); virtual;

    function    getSectionCount: integer;
    function    isEmtpy: boolean;

    function    exists(aSection: string): boolean; virtual; abstract;

    function    read(aSection: string; aType: tDataType; aName: string; const aDefaultValue: variant): variant; virtual; abstract;
    procedure   write(aSection: string; aType: tDataType; aName: string; const aValue: variant); virtual; abstract;
  end;

implementation

{ cAbstractIOObject }

constructor cAbstractIOObject.create;
begin
  inherited create;

  fCS := tCriticalSection.create;
end;

destructor cAbstractIOObject.destroy;
begin
  if (assigned(fCS)) then begin
    freeAndNil(fCS);
  end;

  inherited;
end;

procedure cAbstractIOObject.fromBytes(const aBytes: tBytesArray);
var
  arrSize: integer;
begin
  arrSize:= length(aBytes);
  setSize(arrSize);

  seek(0, soBeginning);

  write(aBytes[1], arrSize);

  seek(0, soBeginning);
end;

function cAbstractIOObject.isEmpty: boolean;
begin
  result:= size = 0;
end;

procedure cAbstractIOObject.lock;
begin
  fCS.enter;
end;

function cAbstractIOObject.readStream(aStream: cAbstractIOObject): longint;
var
  streamSize: int64;

  readBytes: tBytesArray;
begin
  aStream.seek(0, soBeginning);

  result:= read(streamSize, sizeOf(streamSize));

  if (result <> sizeOf(streamSize)) then begin
    aStream.setSize(0);
    exit;
  end;


  setLength(readBytes, streamSize);
  result:= result + read(readBytes[1], streamSize);

  aStream.setSize(streamSize);
  aStream.fromBytes(readBytes);
end;

function cAbstractIOObject.readAnsiString(var aValue: ansiString): longint;
var
  strLen: integer;
begin
  result:= read(strLen, sizeOf(strLen));

  if (result <> sizeOf(strLen)) then begin
    setLength(aValue, 0);
    exit;
  end;


  setLength(aValue, strLen);
  result:= result + read(aValue[1], strLen);
end;

function cAbstractIOObject.readUnicodeString(var aValue: string): longint;
var
  strLen: integer;
begin
  result:= read(strLen, sizeOf(strLen));

  if (result <> sizeOf(strLen)) then begin
    setLength(aValue, 0);
    exit;
  end;


  setLength(aValue, strLen div sizeOf(aValue[1]));
  result:= result + read(aValue[1], strLen);
end;

function cAbstractIOObject.readAtOffset(aOffset: int64; aOrigin: tSeekOrigin; var aBuffer; aCount: integer): longint;
begin
  result:= -1;
  lock;
  try
    seek(aOffset, aOrigin);
    result:= read(aBuffer, aCount);
  finally
    unlock;
  end;
end;

function cAbstractIOObject.readBool(var aValue: boolean): longint;
begin
  result:= read(aValue, sizeOf(aValue));
end;

function cAbstractIOObject.readBytesArray(var aValue: tBytesArray): longint;
begin
  result:= readAnsiString(ansiString(aValue));
end;

function cAbstractIOObject.readEnum(var aValue): longint;
var
  val: byte;
begin
  val:= byte(aValue);
  result:= read(val, sizeOf(val));

  byte(aValue):= val;
end;

function cAbstractIOObject.writeEnum(const aValue): longint;
var
  val: byte;
begin
  val:= byte(aValue);
  result:= write(val, sizeOf(val));
end;

function cAbstractIOObject.readInteger(var aValue: integer): longint;
begin
  result:= read(aValue, sizeOf(aValue));
end;

function cAbstractIOObject.readInteger(var aValue: int64): longint;
begin
  result:= read(aValue, sizeOf(aValue));
end;

function cAbstractIOObject.toBytes: tBytesArray;
var
  arrSize: integer;
begin
  seek(0, soBeginning);

  arrSize:= getSize;
  setLength(result, arrSize);

  read(result[1], arrSize);
end;

procedure cAbstractIOObject.unlock;
begin
  fCS.leave;
end;


function cAbstractIOObject.writeStream(aStream: cAbstractIOObject): longint;
var
  streamSize: int64;

  writeBytes: tBytesArray;
begin
  writeBytes:= aStream.toBytes;

  streamSize:= aStream.size;

  result:= write(streamSize, sizeOf(streamSize));
  result:= result + write(writeBytes[1], streamSize);
end;

function cAbstractIOObject.writeAnsiString(aValue: ansiString): longint;
var
  strLen: integer;
begin
  strLen:= length(aValue) * sizeOf(aValue[1]);

  result:= write(strLen, sizeOf(strLen));
  result:= result + write(aValue[1], strLen);
end;

function cAbstractIOObject.writeUnicodeString(aValue: string): longint;
var
  strLen: integer;
begin
  strLen:= length(aValue) * sizeOf(aValue[1]);

  result:= write(strLen, sizeOf(strLen));
  result:= result + write(aValue[1], strLen);
end;

function cAbstractIOObject.writeAtOffset(aOffset: int64; aOrigin: tSeekOrigin; const aBuffer; aCount: integer): longint;
begin
  result:= -1;
  lock;
  try
    seek(aOffset, aOrigin);
    result:= write(aBuffer, aCount);
  finally
    unlock;
  end;
end;

function cAbstractIOObject.writeBool(aValue: boolean): longint;
begin
  result:= write(aValue, sizeOf(aValue));
end;

function cAbstractIOObject.writeBytesArray(aValue: tBytesArray): longint;
begin
  result:= writeAnsiString(aValue);
end;

function cAbstractIOObject.writeInteger(aValue: integer): longint;
begin
  result:= write(aValue, sizeOf(aValue));
end;

function cAbstractIOObject.writeInteger(aValue: int64): longint;
begin
  result:= write(aValue, sizeOf(aValue));
end;

{ cAbstractIOOProperties }

procedure cAbstractIOOProperties.beginUpdate;
begin
  fUpdating:= true;
end;

procedure cAbstractIOOProperties.endUpdate;
begin
  try
    commit;
  finally
    fUpdating:= false;
  end;
end;

function cAbstractIOOProperties.isEmtpy: boolean;
begin
  result:= getSectionCount = 0;
end;

procedure cAbstractIOOProperties.iterateSections(aIteratorProc: tSectionsIteratorProc);
begin
  if (not assigned(aIteratorProc)) then begin
    raise eAbstractIOOProperties.create(ITERATOR_PROC_NOT_ASSIGNED);
  end;
end;

procedure cAbstractIOOProperties.save;
begin
  commit;
end;

function cAbstractIOOProperties.getSectionCount: integer;
var
  count: integer;
begin
  result:= 0;

  count:= 0;
  iterateSections(
    procedure(aSection: string; aIndex: integer)
    begin
      inc(count);
    end
  );

  result:= count;
end;

end.
