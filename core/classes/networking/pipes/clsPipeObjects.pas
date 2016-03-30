unit clsPipeObjects;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Messages,
  Dialogs,
  TypInfo,

  generics.collections,

  activex,

  clsAbstractIOObject,
  clsMemory,
  clsPipes,
  clsLists,
  clsMessageBox,
  clsStringUtils,
  clsMemoryUtils,
  clsCRC32,
  clsClassKit;

const
  MAX_PACKET_SIZE = 1024;

type
  tPropType = (ptString, ptInt, ptDword, ptBool, ptDateTime, ptStream, ptEnum);

  tPacketType = (pckHead, pckRaw, pckTail);

  tReadState = (rsNameSize, rsNameValue, rsDataSize, rsDataValue);

  {$M+}
  cProperty = class
  private
    fProperty: ansiString;
    fPropType: tPropType;
  public
    constructor create(const aName: ansiString; const aPropType: tPropType);
  published
    property    name: ansiString read fProperty;
    property    propType: tPropType read fPropType;
  end;

  cBinaryTypes = class
    public
      const
        btInt    = 'btInt';
        btString = 'btString';
        btStream = 'btStream';
  end;
  {$M-}

  tOnValueReadProc = procedure(const aVarName: ansiString; const aBuf: pointer; const aSize: integer) of object;
  tCustomWriteBufferProc = procedure(const aContextStream: cAbstractIOObject; const aValue: pointer; const aSize: integer) of object;

  cBinaryContext = class
  private
    class function  write(const aVarName: ansiString; const aPValue: pointer; const aSize: integer; const aContextStream: cAbstractIOObject; aCustomWriteCallback: tCustomWriteBufferProc=nil):boolean;
    class function  read(const aInStream: cAbstractIOObject; aCallbackReader: tOnValueReadProc):boolean;

    class procedure customWriteStream(const aContextStream: cAbstractIOObject; const aValue: pointer; const aSize: integer);
  public
    class function  writeString(const aVarName: ansiString; const aValue: ansiString; const aContextStream: cAbstractIOObject): boolean;
    class function  writeInt(const aVarName: ansiString; const aValue: integer; const aContextStream: cAbstractIOObject): boolean;
    class function  writeDword(const aVarName: ansiString; const aValue: dword; const aContextStream: cAbstractIOObject): boolean;
    class function  writeDateTime(const aVarName: ansiString; const aValue: tDateTime; const aContextStream: cAbstractIOObject): boolean;
    class function  writeBool(const aVarName: ansiString; const aValue: boolean; const aContextStream: cAbstractIOObject): boolean;
    class function  writeStream(const aVarName: ansiString; const aValue: cAbstractIOObject; const aContextStream: cAbstractIOObject): boolean;
  end;

  sPacketHeader = record
    size      : integer;
    crc32     : dword;
    className : ansiString;
    name      : ansiString;
  end;

  sPacketTail = packed record
    size  : integer;
    crc32 : dword;
    name  : array[0..255] of ansiChar;
  end;


  {$M+}
  cAbstractPipeObject = class
  private
    fRegisteredProperties: tObjectDictionary<ansiString,cProperty>;
    fId: ansiString;

    procedure   readProc(const aVarName: ansiString; const aBuf: pointer;const aSize: integer);//service function for properties serializer

    function    initialize: boolean;
    function    unInitialize: boolean;
  protected
    procedure   registerProperties; virtual;

    function    registerProperty(aName: ansiString; aType: tPropType): boolean;


    function    getRegisteredProperties: tDictionary<ansiString,cProperty>;
  public
    constructor create;
    destructor  destroy; override;

    function    crc32: dword;

    function    serialize(aStream: cMemory): dword;
    function    unSerialize(aStream: cAbstractIOObject): boolean;
  published
    property    id: ansiString read fId write fId;
  end;

  cPipePacket = class(cAbstractPipeObject)
  private
    fCrc32: dword;
    fPacketIndex: integer;
    fClassName: ansiString;
    fPacketType: tPacketType;
    fTimeStamp: tDateTime;
    fDataSize: integer;
    fStream: cMemory;
  protected
    procedure   registerProperties; override;
  public
    constructor create;
    destructor  destroy; override;
  published
    property    id;

    property    packetIndex: integer read fPacketIndex write fPacketIndex;
    property    className: ansiString read fClassName write fClassName;
    property    timeStamp: tDateTime read fTimeStamp write fTimeStamp;
    property    dataSize: integer read fDataSize write fDataSize;
    property    crc32: dword read fCrc32 write fCrc32;
    property    packetType: tPacketType read fPacketType write fPacketType;

    property    data: cMemory read fStream write fStream;
  end;


  tMessageType = (mtExecute, mtReturn);
  cPipeMessage = class(cAbstractPipeObject)
  private
    fMessage: ansiString;
    fMessageType: tMessageType;
    fUserId: ansiString;
  protected
    procedure registerProperties; override;
  published
    property  id;

    property  userId: ansiString read fUserId write fUserId;
    property  messageType: tMessageType read fMessageType write fMessageType;
    property  message: ansiString read fMessage write fMessage;
  end;
  {$M-}


  sPipeInfo = record
    name  : ansiString;
    server: ansiString;
  end;

  cPipeObjectFactory = class
  private
    fHead: cPipePacket;
    fTail: cPipePacket;
    fMaxPacketSize: integer;

    fList: cList;

    fClientPipe: tPipeClient;
    fObjectId: ansiString;

    function    getItem(aIndex: integer): cPipePacket;
    procedure   setItem(aIndex: integer; const aValue: cPipePacket);

    function    getRealPacketSize: integer;


    procedure   setPipeObject(const aValue: cAbstractPipeObject);
    function    getPipeObject: cAbstractPipeObject;

    function    check: boolean;

    property    clientPipe: tPipeClient read fClientPipe;
  protected
    procedure   add(aItem: cPipePacket);
  public
    constructor create;
    destructor  destroy;override;

    procedure   clear;

    procedure   sendObject(aPipeInfo: sPipeInfo);

    property    objectId: ansiString read fObjectId write fObjectId;

    property    pipeObject: cAbstractPipeObject read getPipeObject write setPipeObject;
    property    head: cPipePacket read fHead write fHead;
    property    tail: cPipePacket read fTail write fTail;
    property    packets[aIndex: integer]: cPipePacket read getItem; default;

    property    maxPacketSize: integer read fMaxPacketSize;
    property    realPacketSize: integer read getRealPacketSize;
  end;

  cPipeObjectCollection = class
  private
    fList: cList;

    function     getItem(index: integer): cAbstractPipeObject;
    procedure    setItem(index: integer; const aValue: cAbstractPipeObject);
  protected
    procedure    add(aItem: cAbstractPipeObject);
  public
    constructor create;
    destructor  destroy;override;

    procedure   clear;

    property    objects[index: integer]: cAbstractPipeObject read getItem write setItem; default;
  end;


  cPipeObjectFactoryCollection = class
  private
    fObjectsHash: tObjectDictionary<ansiString,cPipeObjectFactory>;

    function    getItemById(aId: ansiString): cPipeObjectFactory;
  protected
    procedure   add(aItem: cPipeObjectFactory);
    procedure   remove(aId: ansiString);
  public
    constructor create;
    destructor  destroy;override;

    procedure   clear;

    property    objects[aId: ansiString]: cPipeObjectFactory read getItemById;
  end;

  tPipeCollectCompletedEvent = procedure(aFactory: cPipeObjectFactory; var aCreatedObject: cAbstractPipeObject) of object;

  cPipeObjectCollector = class
  private
    fCollected: cPipeObjectFactoryCollection;
    fObjectCollectCompleted: tPipeCollectCompletedEvent;

    property    collected: cPipeObjectFactoryCollection read fCollected;
  public
    constructor create;
    destructor  destroy; override;

    procedure   addPacket(aItem: cPipePacket);

  published
    property    onObjectCollectCompleted: tPipeCollectCompletedEvent read fObjectCollectCompleted write fObjectCollectCompleted;
  end;

var
  strPacketType: array[low(tPacketType)..high(tPacketType)] of ansiString = ('pckHead', 'pckRaw', 'pckTail');

implementation

{ cAbstractPipeObject }

procedure cAbstractPipeObject.registerProperties;
begin
  registerProperty('id', ptString);
end;

function cAbstractPipeObject.registerProperty(aName: ansiString; aType: tPropType): boolean;
var
  prop: cProperty;
begin
  result:= true;
  try
    if not fRegisteredProperties.containsKey(aName) then begin
      prop:= cProperty.create(aName, aType);
      fRegisteredProperties.add(aName, prop);
    end else begin
      result:= false;
      cMessageBox.critical('Ошибка', 'Ошибка', format('Возникло предупреждение при попытке регистрации свойств объекта, метод: %s, код: %s', ['cAbstractPipeObject.registerProperty', 'свойство уже существует!!!']));
    end;
  except
    on e: exception do begin
      result:= false;
      cMessageBox.critical('Ошибка', 'Ошибка', format('Возникла ошибка при попытке регистрации свойств объекта, метод: %s, код: %s', ['cAbstractPipeObject.registerProperty', e.message]));
    end;
  end;
end;

constructor cAbstractPipeObject.create;
begin
  inherited create;

  initialize;

  registerProperties;
end;

destructor cAbstractPipeObject.destroy;
begin
  unInitialize;

  inherited;
end;

function cAbstractPipeObject.getRegisteredProperties: tDictionary<ansiString, cProperty>;
begin
  result:= fRegisteredProperties;
end;

function cAbstractPipeObject.initialize: boolean;
begin
  result:= true;
  try
    fRegisteredProperties:= tObjectDictionary<ansiString,cProperty>.create([doOwnsValues]);

    fId:= cStringUtils.getNewGUID;
  except
    on e: exception do begin
      result:= false;
      cMessageBox.critical('Ошибка', 'Ошибка', format('Возникла ошибка при попытке инициализации объекта, метод: %s, код: %s', ['cAbstractPipeObject.initialize', e.message]));
    end;
  end;
end;

function cAbstractPipeObject.unInitialize: boolean;
begin
  result:= true;
  try
    if assigned(fRegisteredProperties) then begin
      freeAndNil(fRegisteredProperties);
    end;
  except
    on e: exception do begin
      result:= false;
      cMessageBox.critical('Ошибка', 'Ошибка', format('Возникла ошибка при попытке деинициализации объекта, метод: %s, код: %s', ['cAbstractPipeObject.unInitialize', e.message]));
    end;
  end;
end;

procedure cAbstractPipeObject.readProc(const aVarName: ansiString; const aBuf: pointer; const aSize: integer);
var
  curProp: cProperty;
begin
  if not getRegisteredProperties.containsKey(aVarName) then begin
    cMessageBox.critical('Ошибка', 'Ошибка', format('Возникло предупреждение при попытке чтения свойства(%s) объекта, метод: %s, код: %s', [aVarName, 'cAbstractPipeObject.readProc', 'свойство не существует!!!']));
    exit;
  end;

  curProp:= getRegisteredProperties.items[aVarName];
  if assigned(curProp) then begin
    case curProp.propType of
      ptString: begin
          cClassKit.setObjectProperty(self, curProp.name, cPointers.readBufAsStr(aBuf, aSize));
      end;
      ptInt: begin
          cClassKit.setObjectProperty(self, curProp.name, cPointers.readBufAsInt(aBuf));
      end;
      ptDword: begin
          cClassKit.setObjectProperty(self, curProp.name, cPointers.readBufAsDword(aBuf));
      end;
      ptDateTime: begin
          cClassKit.setObjectProperty(self, curProp.name, cPointers.readBufAsDateTime(aBuf));
      end;
      ptBool: begin
          cClassKit.setObjectProperty(self, curProp.name, cPointers.readBufAsInt(aBuf));
      end;
      ptStream: begin
          cPointers.readBufToStream(aBuf, aSize, cAbstractIOObject(cClassKit.getObjectPropertyObject(self, curProp.name)));
      end;
      ptEnum: begin
          cClassKit.setObjectProperty(self, curProp.name, cPointers.readBufAsInt(aBuf)); ///?????? enum
      end;
    end;

  end;
end;

function cAbstractPipeObject.serialize(aStream: cMemory): dword;
var
  curPropPair: tPair<ansiString,cProperty>;
  curProp: cProperty;
begin
  result:= 0;
  try
    aStream.clear;

    for curPropPair in getRegisteredProperties do begin
      curProp:= curPropPair.value;
      if assigned(curProp) then begin
        case curProp.propType of
          ptString: begin
            cBinaryContext.writeString(curProp.name, cClassKit.getObjectProperty(self, curProp.name).value, aStream);
          end;
          ptInt: begin
            cBinaryContext.writeInt(curProp.name, cClassKit.getObjectProperty(self, curProp.name).value, aStream);
          end;
          ptDateTime: begin
            cBinaryContext.writeDateTime(curProp.name, cClassKit.getObjectProperty(self, curProp.name).value, aStream);
          end;
          ptDword: begin
            cBinaryContext.writeDword(curProp.name, cClassKit.getObjectProperty(self, curProp.name).value, aStream);
          end;
          ptEnum: begin
            cBinaryContext.writeInt(curProp.name, cClassKit.getObjectProperty(self, curProp.name, false).value, aStream);
          end;
          ptBool: begin
            cBinaryContext.writeBool(curProp.name, cClassKit.getObjectProperty(self, curProp.name).value, aStream);
          end;
          ptStream: begin
            cBinaryContext.writeStream(curProp.name, cAbstractIOObject(cClassKit.getObjectPropertyObject(self, curProp.name)), aStream);
          end;
        end;

      end;
    end;
    result:= cCheckSum.crc32(aStream);
    aStream.seek(0, soFromBeginning);
  except
    on e: exception do begin
      result:= 0;
      cMessageBox.critical('Ошибка', 'Ошибка', format('Возникла ошибка при попытке сериализации объекта, метод: %s, код: %s', ['tBasePipeObject.serialize', e.message]));
    end;
  end;
end;


function cAbstractPipeObject.unSerialize(aStream: cAbstractIOObject): boolean;
begin
  result:= true;
  try
    aStream.seek(0, soFromBeginning);
    cBinaryContext.read(aStream, readProc);
  except
    on e: exception do begin
      result:= false;
      cMessageBox.critical('Ошибка', 'Ошибка', format('Возникла ошибка при попытке десериализации объекта, метод: %s, код: %s', ['tBasePipeObject.serialize', e.message]));
    end;
  end;
end;


function cAbstractPipeObject.crc32: dword;
var
  stream: cMemory;
begin
  result:= 0;
  stream:= cMemory.Create;
  try
    serialize(stream);
    try
      stream.seek(0, soFromBeginning);
      result:= cCheckSum.crc32(stream);
    except
      on e: exception do begin
        result:= 0;
        cMessageBox.critical('Ошибка', 'Ошибка', format('Возникла ошибка при попытке получить crc32 объекта, метод: %s, код: %s', ['tBasePipeObject.crc32', e.message]));
      end;
    end;
  finally
    stream.free;
  end;
end;

{ cBinaryContext }

class function cBinaryContext.read(const aInStream: cAbstractIOObject; aCallbackReader: tOnValueReadProc): boolean;
var
  buf: pointer;

  varName: ansiString;
  readSize: integer;

  readState: tReadState;

  allocSize: integer;
begin
  result:= true;
  try
    aInStream.seek(0, soFromBeginning);

    varName:= emptyStr;
    readState:= rsNameSize;

    readSize:= sizeOf(integer); // get first size   size data size data.....
    allocSize:= readSize;
    getMem(buf, readSize);
    while aInStream.position<=aInStream.size do begin
      aInStream.read(buf^, readSize);
      case readState of
        rsNameSize: begin

          readSize:= integer(buf^);
          readState:= rsNameValue;

          freeMem(buf, allocSize);
          allocSize:= readSize;

          getMem(buf, readSize);
        end;
        rsNameValue: begin

          varName:= cPointers.readBufAsStr(buf, readSize);

          readState:= rsDataSize;
          readSize:= sizeOf(integer);

          freeMem(buf, allocSize);
          allocSize:= readSize;

          getMem(buf, readSize);
        end;
        rsDataSize: begin
          readSize:= integer(buf^);
          readState:= rsDataValue;

          freeMem(buf, allocSize);
          allocSize:= readSize;

          getMem(buf, readSize);
        end;
        rsDataValue: begin
          if assigned(aCallbackReader) then
            aCallbackReader(varName, buf, readSize);

          readState:= rsNameSize;
          readSize:= sizeOf(integer);

          freeMem(buf, allocSize);
          allocSize:= readSize;

          //////
          if aInStream.position>=aInStream.size then break; //eof
          ///


          getMem(buf, readSize);
        end;
      end;
    end;

  except
    on e: exception do begin
      result:= false;
      cMessageBox.critical('Ошибка', 'Ошибка', format('Возникла ошибка при попытке выполнить чтение, метод: %s, код: %s', ['cBinaryContext.read', e.message]));
    end;
  end;
end;

class function cBinaryContext.write(const aVarName: ansiString; const aPValue: pointer; const aSize: integer; const aContextStream: cAbstractIOObject; aCustomWriteCallback: tCustomWriteBufferProc): boolean;
var
  varNameLength: integer;
begin
  result:= true;
  try
    varNameLength:= length(aVarName);

    result:= aContextStream.write(varNameLength, sizeof(varNameLength))<>0;       //size
    result:= aContextStream.write(aVarName[1], varNameLength)<>0;       //value

    result:= aContextStream.write(aSize, sizeof(aSize))<>0;  //size
    if assigned(aCustomWriteCallback) then
      aCustomWriteCallback(aContextStream, aPValue, aSize)
    else
      result:= aContextStream.write(aPValue^, aSize)<>0;       //value
  except
    on e: exception do begin
      result:= false;
      cMessageBox.critical('Ошибка', 'Ошибка', format('Возникла ошибка при попытке выполнить запись, метод: %s, код: %s', ['cBinaryContext.write', e.message]));
    end;
  end;
end;

class function cBinaryContext.writeBool(const aVarName: ansiString; const aValue: boolean; const aContextStream: cAbstractIOObject): boolean;
var
  intVal: integer;
begin
  intVal:= 0;
  if aValue then intVal:= 1;

  result:= true;
  try
    cBinaryContext.writeInt(aVarName, intVal, aContextStream);
  except
    result:= false;
  end;
end;

class function cBinaryContext.writeDateTime(const aVarName: ansiString; const aValue: tDateTime; const aContextStream: cAbstractIOObject): boolean;
begin
  result:= true;
  try
    cBinaryContext.write(aVarName, @aValue, sizeof(aValue), aContextStream);
  except
    result:= false;
  end;
end;

class function cBinaryContext.writeDword(const aVarName: ansiString; const aValue: dword; const aContextStream: cAbstractIOObject): boolean;
begin
  result:= true;
  try
    cBinaryContext.write(aVarName, @aValue, sizeof(aValue), aContextStream);
  except
    result:= false;
  end;
end;

class function cBinaryContext.writeInt(const aVarName: ansiString; const aValue: integer; const aContextStream: cAbstractIOObject): boolean;
begin
  result:= true;
  try
    cBinaryContext.write(aVarName, @aValue, sizeof(aValue), aContextStream);
  except
    result:= false;
  end;
end;

class procedure cBinaryContext.customWriteStream(const aContextStream: cAbstractIOObject; const aValue: pointer; const aSize: integer);
var
  stream: cAbstractIOObject;
  buf: tByteArray;
  readed: int64;
begin
  stream:= cAbstractIOObject(aValue^);

  stream.seek(0, soFromBeginning);

  while stream.position<stream.size do begin
    readed:= stream.read(buf, sizeOf(buf));

    aContextStream.write(buf, readed);
  end;
end;

class function cBinaryContext.writeStream(const aVarName: ansiString; const aValue, aContextStream: cAbstractIOObject): boolean;
begin
  result:= true;
  try
    aValue.seek(0, soFromBeginning);
    cBinaryContext.write(aVarName, @aValue, aValue.size, aContextStream, cBinaryContext.customWriteStream);
  except
    result:= false;
  end;
end;

class function cBinaryContext.writeString(const aVarName, aValue: ansiString; const aContextStream: cAbstractIOObject): boolean;
begin
  result:= true;
  try
    cBinaryContext.write(aVarName, @aValue[1], length(aValue), aContextStream);
  except
    result:= false;
  end;
end;

{ cProperty }

constructor cProperty.create(const aName: ansiString; const aPropType: tPropType);
begin
  inherited create;

  fProperty:= aName;
  fPropType:= aPropType;
end;

{ cPipePacket }

constructor cPipePacket.create;
begin
  inherited create;

  data:= cMemory.create;
end;

destructor cPipePacket.destroy;
begin
  if assigned(data) then
    data.free;

  inherited;
end;

procedure cPipePacket.registerProperties;
begin
  inherited;

  registerProperty('packetIndex', ptInt);
  registerProperty('className', ptString);
  registerProperty('timeStamp', ptDateTime);
  registerProperty('dataSize', ptInt);
  registerProperty('crc32', ptDword);
  registerProperty('packetType', ptEnum);

  registerProperty('data', ptStream);
end;

{ cPipeObjectFactory }

procedure cPipeObjectFactory.add(aItem: cPipePacket);
begin
  fList.add(aItem);
end;

procedure cPipeObjectFactory.clear;
begin
  if assigned(fHead) then begin
    freeAndNil(fHead);
  end;

  if assigned(fTail) then begin
    freeAndNil(fTail);
  end;

  fList.freeInternalObjects;
  fList.clear;
end;

constructor cPipeObjectFactory.create;
begin
  inherited create;

  fList:= cList.create;

  fClientPipe:= tPipeClient.create(nil);

  fMaxPacketSize:= MAX_PACKET_SIZE;//*1024;
end;

destructor cPipeObjectFactory.destroy;
begin
  clear;

  if assigned(fList) then begin
    freeAndNil(fList);
  end;


  if assigned(fClientPipe) then begin
    freeAndNil(fClientPipe);
  end;

  inherited;
end;

function cPipeObjectFactory.getItem(aIndex: integer): cPipePacket;
begin
  result:= fList.items[aIndex];
end;

procedure cPipeObjectFactory.sendObject(aPipeInfo: sPipeInfo);
var
  i: integer;
  serStream: cMemory;
  curPacket: cPipePacket;
begin
  if not check then exit;


  if not clientPipe.connected then begin
    clientPipe.pipeName:= aPipeInfo.name;
    clientPipe.serverName:= aPipeInfo.server;
  end;


  if not clientPipe.connect then begin
    cMessageBox.critical('Ошибка', 'Ошибка',
      format('Не удается подключится к pipe[name=%s, server=%s], метод: %s, код: %s',
        [clientPipe.pipeName,  clientPipe.serverName, 'cPipeObjectFactory.getPipeObject', 'ошибка']
      )
    );
    exit;
  end;

  serStream:= cMemory.create;
  try
    //////head//////
    serStream.clear;
    fHead.serialize(serStream);
    if not (clientPipe.write(serStream.memory^, serStream.size)) then begin
      cMessageBox.critical('Ошибка', 'Ошибка',
        format('Ошибка при отправке заголовка, метод: %s, код: %s',
          ['cPipeObjectFactory.sendObject', 'ошибка']
        )
      );
      exit;
    end; //rewind to 0 position
    ////////////////

    //////head//////
    for i:= 0 to fList.count - 1 do begin
      serStream.clear;
      curPacket:= packets[i];
      curPacket.serialize(serStream); //rewind to 0 position
      if not clientPipe.write(serStream.memory^, serStream.size) then begin
        cMessageBox.critical('Ошибка', 'Ошибка',
          format('Ошибка при отправке пакета #%d, метод: %s, код: %s',
            [curPacket.packetIndex, 'cPipeObjectFactory.sendObject', 'ошибка']
          )
        );

        exit;
      end;
    end;
    ////////////////

    //////tail//////
    serStream.clear;
    fTail.serialize(serStream);
    if not clientPipe.write(serStream.memory^, serStream.size) then begin
        cMessageBox.critical('Ошибка', 'Ошибка',
          format('Ошибка при отправке хвоста, метод: %s, код: %s',
            ['cPipeObjectFactory.sendObject', 'ошибка']
          )
        );

        exit;
    end; //rewind to 0 position
    ////////////////
  finally
    serStream.free;
  end;
end;

procedure cPipeObjectFactory.setItem(aIndex: integer; const aValue: cPipePacket);
begin
  fList.items[aIndex]:= aValue;
end;


function cPipeObjectFactory.check: boolean;
begin
  result:= true;
  if lowerCase(fHead.fClassName)= lowerCase(cAbstractPipeObject.className) then begin
    cMessageBox.critical('Ошибка', 'Ошибка',
      format('Передан базовый класс вместо конкретного, метод: %s, код: %s',
        ['cPipeObjectFactory.getPipeObject', 'ошибка']
      )
    );
    result:= false;
    exit;
  end;

  if fList.count=0 then begin
    cMessageBox.critical('Ошибка', 'Ошибка',
      format('Счетчик пакетов=0, метод: %s, код: %s',
        ['cPipeObjectFactory.getPipeObject', 'ошибка']
      )
    );

    result:= false;
    exit;
  end;

  if (fList.count=0) and (assigned(fHead)) then begin
    cMessageBox.critical('Ошибка', 'Ошибка',
      format('Счетчик пакетов=0, а заголовок присутстует, метод: %s, код: %s',
        ['cPipeObjectFactory.getPipeObject', 'ошибка']
      )
    );
    result:= false;
    exit;
  end;

  if (fList.count=0) and (assigned(fTail)) then begin
    cMessageBox.critical('Ошибка', 'Ошибка',
      format('Счетчик пакетов=0, а хвост присутстует, метод: %s, код: %s',
        ['cPipeObjectFactory.getPipeObject', 'ошибка']
      )
    );
    result:= false;
    exit;
  end;

  if (fList.count<>0) and (assigned(fHead)) and not(assigned(fTail)) then begin
    cMessageBox.critical('Ошибка', 'Ошибка',
      format('Счетчик пакетов<>0, заголовок присутствует, а хвост отсутствует, метод: %s, код: %s',
        ['cPipeObjectFactory.getPipeObject', 'ошибка']
      )
    );
    result:= false;
    exit;
  end;

  if (fList.count<>0) and not (assigned(fHead)) and (assigned(fTail)) then begin
    cMessageBox.critical('Ошибка', 'Ошибка',
      format('Счетчик пакетов<>0, заголовок отсутствует, а хвост присутствует, метод: %s, код: %s',
        ['cPipeObjectFactory.getPipeObject', 'ошибка']
      )
    );
    result:= false;
    exit;
  end;
end;

function cPipeObjectFactory.getPipeObject: cAbstractPipeObject;

  function packetsToStream(aDataStream: cAbstractIOObject): boolean;
  var
    i: integer;
    curPacket: cPipePacket;
  begin
      result:= true;


      if (not check) then exit;


      //////////////grab packets to stream
      aDataStream.seek(0, soFromBeginning);
      for i := 0 to fList.count - 1 do begin
        curPacket:= packets[i];
        if (curPacket.crc32<>cCheckSum.crc32(curPacket.data)) then begin
          cMessageBox.critical('Ошибка', 'Ошибка',
            format('Контрольная сумма пакета #[%d], метод: %s, код: %s',
              [curPacket.packetIndex, 'cPipeObjectFactory.getPipeObject', 'ошибка']
            )
          );
          result:= false;
          exit;
        end;

        //
        curPacket.data.seek(0, soFromBeginning);
        aDataStream.write(curPacket.data.memory^, curPacket.fDataSize);
      end;


      if not (assigned(fTail) and (fTail.packetIndex = fList.count + 1)) then begin  //+head+tail+count
        cMessageBox.critical('Ошибка', 'Ошибка',
          format('Не совпадает переданное кол-во пакетов, метод: %s, код: %s',
            ['cPipeObjectFactory.getPipeObject', 'ошибка']
          )
        );
        result:= false;
        exit;
      end;
      //////////////////////////////////
  end;

var
  dataStream: cMemory;
begin
  result:= nil;
  dataStream:= cMemory.create;
  try

    if not packetsToStream(dataStream) then exit;


    if lowerCase(fHead.fClassName) = lowerCase(cPipeMessage.className) then begin //handling!!!!
      result:= cPipeMessage.create;

      result.unSerialize(dataStream);
    end;

  finally
    dataStream.free;
  end;
end;

function cPipeObjectFactory.getRealPacketSize: integer;
begin
  result:= fMaxPacketSize div 2;
end;

procedure cPipeObjectFactory.setPipeObject(const aValue: cAbstractPipeObject);
var
  packet: cPipePacket;

  dataStream: cMemory;
  serSize: integer;

  packetIndex: integer;
  readed: integer;

  buffer: pointer;

  crc32: dword;
begin
  packetIndex:= 0;

  if not assigned(aValue) then begin
    cMessageBox.critical('Ошибка', 'Ошибка',
      format('Не передан объект для сереализации, метод: %s, код: %s',
        ['cPipeObjectFactory.setPipeObject', 'ошибка']
      )
    );
    exit;
  end;

  dataStream:= cMemory.create;
  try
    crc32:= aValue.serialize(dataStream);

    if (crc32=0) then begin
      cMessageBox.critical('Ошибка', 'Ошибка',
        format('crc32 потока сереализации=0, метод: %s, код: %s',
          ['cPipeObjectFactory.setPipeObject', 'ошибка']
        )
      );
      exit;
    end;

    serSize:= dataStream.size;
    if serSize<>0 then begin
      dataStream.seek(0, soFromBeginning);     //serialized object


      clear; //clear all packets

      /////////////head////////////
      fHead:= cPipePacket.create;
      fHead.id:= aValue.id;
      fHead.crc32:= crc32;
      fHead.packetIndex:= 0;
      fHead.className:= aValue.className;
      fHead.timeStamp:= now;
      fHead.packetType:= pckHead;
      /////////////////////////////


      while dataStream.position<=serSize do begin
        inc(packetIndex);


        try
          getMem(buffer, realPacketSize);
          readed:= dataStream.read(buffer^, realPacketSize);

          if readed<>0 then begin

            packet:= cPipePacket.create;
            packet.id:= aValue.id;
            packet.packetIndex:= packetIndex;
            packet.className:= aValue.className;
            packet.timeStamp:= now;
            packet.data.write(buffer^, realPacketSize);
            packet.crc32:= cCheckSum.crc32(packet.data);
            packet.packetType:= pckRaw;
            packet.dataSize:= readed;

            ////////////
            add(packet);
            ////////////

          end else begin
            dec(packetIndex);
            break;
          end;

          if (dataStream.position = serSize) then break;


        finally
          freeMem(buffer);
          buffer:= nil;
        end;


      end;
      /////////////tail////////////
      fTail:= cPipePacket.create;
      fTail.id:= aValue.id;
      fTail.crc32:= 0; //dont need check
      fTail.packetIndex:= packetIndex+1;
      fTail.className:= aValue.className;
      fTail.timeStamp:= now;
      fTail.packetType:= pckTail;
      /////////////////////////////


    end else begin
      cMessageBox.critical('Ошибка', 'Ошибка',
        format('Размер потока сереализации=0, метод: %s, код: %s',
          ['cPipeObjectFactory.setPipeObject', 'ошибка']
        )
      );
    end;
  finally
    dataStream.free;
  end;


end;

{ cPipeMessage }

procedure cPipeMessage.registerProperties;
begin
  inherited;

  registerProperty('userId', ptString);

  registerProperty('messageType', ptEnum);
  registerProperty('message', ptString);
end;

{ cPipeObjectCollection }

procedure cPipeObjectCollection.add(aItem: cAbstractPipeObject);
begin
  fList.add(aItem);
end;

procedure cPipeObjectCollection.clear;
begin
  fList.freeInternalObjects;
  fList.clear;
end;

constructor cPipeObjectCollection.create;
begin
  inherited create;
end;

destructor cPipeObjectCollection.destroy;
begin
  inherited;
end;

function cPipeObjectCollection.getItem(index: integer): cAbstractPipeObject;
begin
  result:= fList.items[index];
end;

procedure cPipeObjectCollection.setItem(index: integer; const aValue: cAbstractPipeObject);
begin
  fList.items[index]:= aValue;
end;

{ cPipeObjectFactoryCollection }

procedure cPipeObjectFactoryCollection.add(aItem: cPipeObjectFactory);
begin
  fObjectsHash.add(aItem.objectId, aItem);
end;

procedure cPipeObjectFactoryCollection.clear;
begin
  fObjectsHash.clear;
end;

constructor cPipeObjectFactoryCollection.create;
begin
  inherited create;

  fObjectsHash:= tObjectDictionary<ansiString,cPipeObjectFactory>.create([doOwnsValues]);
end;

destructor cPipeObjectFactoryCollection.destroy;
begin
  if assigned(fObjectsHash) then begin
    freeAndNil(fObjectsHash);
  end;

  inherited;
end;

function cPipeObjectFactoryCollection.getItemById(aId: ansiString): cPipeObjectFactory;
begin
  result:= nil;
  if fObjectsHash.containsKey(aId) then begin
    result:= fObjectsHash.items[aId];
  end;
end;


procedure cPipeObjectFactoryCollection.remove(aId: ansiString);
begin
  if fObjectsHash.containsKey(aId) then begin
    fObjectsHash.remove(aId);
  end;

end;

{ cPipeObjectCollector }

procedure cPipeObjectCollector.addPacket(aItem: cPipePacket);
var
  item: cPipeObjectFactory;

  newFactory: cPipeObjectFactory;

  createdObject: cAbstractPipeObject;
begin
  item:= fCollected.objects[aItem.id];

  if item<>nil then begin
    case aItem.fPacketType of
      pckRaw  : item.add(aItem); //head cannot be here
      pckTail : begin
        item.tail:= aItem;
        try
          if assigned(fObjectCollectCompleted) then begin
            createdObject:= item.pipeObject;
            fObjectCollectCompleted(item, createdObject);
          end;
        finally
          fCollected.remove(item.objectId);
        end;
      end;
    end;
  end else begin
    newFactory:= cPipeObjectFactory.create;
    newFactory.objectId:= aItem.id;
    newFactory.head:= aItem;

    fCollected.add(newFactory);
  end;
end;

constructor cPipeObjectCollector.create;
begin
  inherited create;
  fCollected:= cPipeObjectFactoryCollection.create;
end;

destructor cPipeObjectCollector.destroy;
begin
  if assigned(fCollected) then begin
    freeAndNil(fCollected);
  end;

  inherited;
end;

end.
