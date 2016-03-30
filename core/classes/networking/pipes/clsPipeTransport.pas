unit clsPipeTransport;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Messages,
  Dialogs,

  clsAbstractIOObject,
  clsPipeObjects,
  clsPipes,
  clsLists,
  clsMulticastEvents;

type
  cPipeMessageClient = class
  private
    fFactory: cPipeObjectFactory;
    fPipeName: string;
    fPipeHost: string;

  public
    constructor create;
    destructor  destroy; override;

    procedure   setPipeName(aName: string);
    procedure   setPipeHost(aHost: string);

    procedure   send(aObject: cAbstractPipeObject);
  end;

  cPipeMessageServer = class;

  tPipeMessageServerObjectReceivedEvent = procedure(aSender: cPipeMessageServer; var aPipeObject: cAbstractPipeObject) of object;

  cPipeMessageServer = class
  private
    fCollector: cPipeObjectCollector;
    fOnPipeObjectReceived : tPipeMessageServerObjectReceivedEvent;
    fPipeServer : tPipeServer;

    procedure   setupEvents;
    procedure   disconnectEvents;
  public
    procedure   start;
    procedure   stop;
    function    isStopped: boolean;

    procedure   setPipeName(aName: string);
    function    getPipeName: string;

    constructor create;
    destructor  destroy; override;
  published
   {$REGION 'EVENTS'}
    property    onPipeObjectReceived: tPipeMessageServerObjectReceivedEvent read fOnPipeObjectReceived write fOnPipeObjectReceived;
   {$ENDREGION}
  published
   {$REGION 'SLOTS'}
    procedure   pipePacketReceived(aSender: tObject; aPipe: HPIPE; aStream: cAbstractIOObject);
    procedure   objectReceived(aFactory: cPipeObjectFactory; var aCreatedObject: cAbstractPipeObject);
   {$ENDREGION}
  end;

implementation


{ cPipeMessageClient }

constructor cPipeMessageClient.create;
begin
  inherited create;

  fFactory:= cPipeObjectFactory.create;
end;

destructor cPipeMessageClient.destroy;
begin
  if assigned(fFactory) then begin
    freeAndNil(fFactory);
  end;

  inherited;
end;

procedure cPipeMessageClient.send(aObject: cAbstractPipeObject);
var
  pipeInfo: sPipeInfo;
begin
  fFactory.pipeObject:= aObject;
  pipeInfo.name:= fPipeName;
  pipeInfo.server:= fPipeHost;

  fFactory.sendObject(pipeInfo);
end;

procedure cPipeMessageClient.setPipeHost(aHost: string);
begin
  fPipeHost:= aHost;
end;

procedure cPipeMessageClient.setPipeName(aName: string);
begin
  fPipeName:= aName;
end;


{ cPipeMessageServer }
constructor cPipeMessageServer.create;
begin
  inherited create;

  fPipeServer:= tPipeServer.create;
  fCollector:= cPipeObjectCollector.create;

  setupEvents;
end;

destructor cPipeMessageServer.destroy;
begin
  disconnectEvents;

  if assigned(fCollector) then begin
    freeAndNil(fCollector);
  end;

  if assigned(fPipeServer) then begin
    freeAndNil(fPipeServer);
  end;

  inherited;
end;

procedure cPipeMessageServer.setupEvents;
begin
  connect(fPipeServer, 'onPipeMessage', self, 'pipePacketReceived');
  connect(fCollector, 'onObjectCollectCompleted', self, 'objectReceived');
end;

procedure cPipeMessageServer.disconnectEvents;
begin
  disconnect(self);

  disconnect(fPipeServer, 'onPipeMessage', self, 'pipePacketReceived');
  disconnect(fCollector, 'onObjectCollectCompleted', self, 'objectReceived');
end;

function cPipeMessageServer.getPipeName: string;
begin
  result:= fPipeServer.pipeName;
end;

function cPipeMessageServer.isStopped: boolean;
begin
  result:= not fPipeServer.active;
end;

procedure cPipeMessageServer.setPipeName(aName: string);
begin
  fPipeServer.pipeName:= aName;
end;

procedure cPipeMessageServer.start;
begin
  fPipeServer.start;
end;

procedure cPipeMessageServer.stop;
begin
  fPipeServer.stop;
end;

{$REGION 'SLOTS'}
procedure cPipeMessageServer.objectReceived(aFactory: cPipeObjectFactory; var aCreatedObject: cAbstractPipeObject);
begin
  if assigned(aCreatedObject) then begin
    try
      if lowerCase(aCreatedObject.className) = lowerCase(cPipeMessage.className) then begin
        if assigned(fOnPipeObjectReceived) then begin
          fOnPipeObjectReceived(self, aCreatedObject);
        end;
      end;
    finally
      freeAndNil(aCreatedObject);
    end;
  end;
end;

procedure cPipeMessageServer.pipePacketReceived(aSender: tObject; aPipe: HPIPE; aStream: cAbstractIOObject);
var
  pipePacket: cPipePacket;
begin
  pipePacket:= cPipePacket.create;
  try
    pipePacket.unSerialize(aStream);

    fCollector.addPacket(pipePacket);
  except
    on e: exception do begin
      freeAndNil(pipePacket);
    end;
  end;
end;
{$ENDREGION}

end.
