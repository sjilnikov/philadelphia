(*
 * Multicast events handling
 * Version: 1.2 (alpha)
 *
 * Features:
 *
 * Usage:
 *   connect(aSender: tObject; aSenderPropertyName: string; aReceiver: tObject; aReceiverMethodName: string);
 *   disconnect(aSender: tObject; aSenderPropertyName: string; aReceiver: tObject; aReceiverMethodName: string);
 *
 * Author: Sergei Jilnikov
 *
 * Send bugs/comments to s.jilnikov@gmail.com
 *)

unit clsMulticastEvents;

interface
uses
  windows,
  sysUtils,
  objAuto,
  syncObjs,
  generics.collections,
  rtti,

  uMetrics,

  clsException,
  clsClassKit,
  clsLists;

type
  eHandler = class(cException);
  eEvent = class(cException);
  eEventConnector = class(cException);

procedure connect(aSender: tObject; aEvent: string; aReceiver: tObject; aHandlerName: string); overload;
procedure connect(aSender: tObject; aEvent: string; aReceiver: tClass; aHandlerName: string); overload;

procedure disconnect(aSender: tObject; aEvent: string; aReceiver: tObject; aHandlerName: string); overload;
procedure disconnect(aSender: tObject; aEvent: string); overload;
procedure disconnect(aSender: tObject); overload;
procedure disconnectReceiver(aSender: tObject); overload;
procedure disconnectReceiver(aSender: tObject; aHandlerName: string); overload;

procedure debugDumpEvents(aReceiverFilter: tObject = nil);

implementation
uses
  clsDebug,
  clsSingleton;

type
  cHandler = class;
  cEvent = class;
  cSender = class;

  tHandlerDestructingEvent = procedure(aHandler: cHandler) of object;
  cHandler = class
  private
    const

    HANDLER_ALREADY_ASSIGNED = 'handler method for event: %s already assigned';
    HANDLER_NOT_ASSIGNED     = 'handler method for event: %s not assigned';
    HANDLER_NOT_METHOD       = 'handler is not method, may be class: %s method: %s not exists?';
  private
    fMethod         : tMethod;
    fOnDestructing  : tHandlerDestructingEvent;

    procedure   beforeDestruction; override;

  public
    function    getMethod: tMethod;

    constructor create(aMethod: tMethod);
    destructor  destroy; override;

    property    method: tMethod read getMethod;

  published
    property    onDestructing: tHandlerDestructingEvent read fOnDestructing write fOnDestructing;
  end;


  cHandlers = class
  private
    const

    INITIAL_CAPACITY = 10;
  private
    fList           : cList;

  public
    function    getItemByIndex(aIndex: integer): cHandler;
    function    getItemByHandlerMethod(aHandlerMethod: tMethod): cHandler;
    function    getCount: integer;

    procedure   add(aHandler: cHandler);
    procedure   delete(aHandler: cHandler); overload;
    procedure   delete(aIndex: integer); overload;
    function    indexOfHandlerMethod(aHandlerMethod: tMethod): integer;
    function    indexOf(aHandler: cHandler): integer;

    constructor create;
    destructor  destroy;override;

    property    items[aIndex: integer]: cHandler read getItemByIndex; default;
    property    items[aHandlerAddress: tMethod]: cHandler read getItemByHandlerMethod; default;


    property    count: integer read getCount;
  end;

  tEventState = (esIdle, esExecuting, esGotDestroyRequest, esPendingDestroy);


  tEventStateChangedEvent = procedure(aEvent: cEvent) of object;
  tEventHandlerDestructingEvent = procedure(aEvent: cEvent; aHandler: cHandler) of object;

  cEvent = class(tObject, iMethodHandler)
  private
    const

    EVENT_ALREADY_ASSIGNED = 'event: %s, for class: %s already assigned';
    EVENT_NOT_ASSIGNED     = 'event: %s, for class: %s not assigned';
  private
    fHandlers                : cHandlers;
    fName                    : string;
    fSender                  : tObject;

    fHandlerStub             : tMethod;
    fState                   : tEventState;

    //boolean is traversed trigger, tDictionary using for accessing fExecutionHelper for O(1)
    fExecutionHelper         : tDictionary<pointer, boolean>;
    fOnStateChanged          : tEventStateChangedEvent;
    fOnHandlerDestructing    : tEventHandlerDestructingEvent;

    procedure   rawEventsHandlerStub(aParams: pParameters; aStackSize: integer);

    //iMethodHandler realization
    function    execute(const aArgs: array of variant): variant;
    function    instanceToVariant(aInstance: tObject): variant;
    //

    procedure   updateConnection;

    //iInterface realization
    function    queryInterface(const aIID: tGUID; out aObj): hResult; stdcall;
    function    _addRef: integer; stdcall;
    function    _release: integer; stdcall;

    //

    procedure   clearSenderEventHandler;
    procedure   beforeDestruction; override;
  public
    procedure   setState(aState: tEventState);
    function    getState: tEventState;

    function    createHandler(aMethod: tMethod): cHandler;
    procedure   deleteHandler(aMethod: tMethod);

    function    getHandlers: cHandlers;

    function    getName: string;
    function    getSender: tObject;

    constructor create(aSender: tObject; aName: string);
    destructor  destroy; override;

    property    handlers: cHandlers read getHandlers;
    property    name: string read getName;
    property    sender: tObject read getSender;
  published
    property    onStateChanged: tEventStateChangedEvent read fOnStateChanged write fOnStateChanged;
    property    onHandlerDestructing: tEventHandlerDestructingEvent read fOnHandlerDestructing write fOnHandlerDestructing;
  published
    procedure   handlerDestructing(aHandler: cHandler);
  end;

  cEvents = class
  private
    const

    INITIAL_CAPACITY = 100;
  private
    fList                 : cList;

    function    getItemByIndex(aIndex: integer): cEvent;
    function    getItemByName(aName: string): cEvent;
    function    getCount: integer;
  public
    procedure   add(aEvent: cEvent);
    procedure   delete(aEvent: cEvent); overload;
    procedure   delete(aIndex: integer); overload;

    function    indexOfEventName(aName: string): integer;
    function    indexOf(aEvent: cEvent): integer;

    constructor create;
    destructor  destroy;override;

    property    items[aIndex: integer]: cEvent read getItemByIndex; default;
    property    items[aName: string]: cEvent read getItemByName; default;

    property    count: integer read getCount;
  published
    procedure   eventStateChanged(aEvent: cEvent);
  end;




  cSender = class
  private
    fEvents     : cEvents;

    fObject     : tObject;
  public
    //silent create add,delete event
    function    createEvent(aName: string): cEvent;
    procedure   deleteEvent(aName: string); overload;
    procedure   deleteEvent(aIndex: integer); overload;

    function    getEvents: cEvents;
    function    getObject: tObject;

    constructor create(aSender: tObject);
    destructor  destroy;override;

    property    events: cEvents read getEvents;
  end;




  cSenderEvents = class
  private
    fList       : tDictionary<pointer, cEvents>;

  public
    function    getEnumerator: tDictionary<pointer, cEvents>.tPairEnumerator;

    function    eventsExists(aObject: tObject): boolean;
    function    createEvents(aObject: tObject): cEvents;
    function    getEvents(aObject: tObject): cEvents;
    procedure   deleteEvents(aObject: tObject);

    function    getCount: integer;


    //if events exists
    function    createEvent(aObject: tObject; aName: string): cEvent;
    function    getEvent(aObject: tObject; aName: string): cEvent;

    procedure   deleteEvent(aObject: tObject; aName: string);


    constructor create;
    destructor  destroy; override;

    property    count: integer read getCount;
  end;





  cReceiverLookupItem = class
  public
    sender         : tObject;
    event          : string;
    receiverMethod : tMethod;

    constructor create(aSender: tObject; aEvent: string; aReceiverMethod: tMethod);
  end;

  cReceiverLookupItems = class
  private
    fList       : cList;
  public
    function    indexOf(aSender: tObject; aEvent: string; aReceiverMethod: tMethod): integer; overload;
    function    indexOf(aEvent: string; aReceiverMethod: tMethod): integer; overload;
    function    indexOf(aReceiverMethod: tMethod): integer; overload;

    procedure   delete(aIndex: integer);
    procedure   remove(aEvent: string; aReceiverMethod: tMethod); overload;
    procedure   remove(aSender: tObject; aEvent: string; aReceiverMethod: tMethod); overload;
    procedure   remove(aReceiverMethod: tMethod); overload;

    procedure   add(aItem: cReceiverLookupItem);
    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cReceiverLookupItem;

    constructor create;
    destructor  destroy; override;

    property    items[aIndex: integer]: cReceiverLookupItem read getItemByIndex;
    property    count: integer read getCount;
  end;

  //thread-safe
  cEventConnector = class
  private
    const

    NOT_ALL_EVENTS_DISCONNECTED = 'not all events have been disconnected, count: %d';
  private
    fSenderEvents         : cSenderEvents;
    fCS                   : tCriticalSection;
    fAutoDisconnect       : boolean;
    fPendingDestroyEvents : cList;
    //map receiver - to cList (events list)

    fReceiverLookup       : tObjectDictionary<tObject, cReceiverLookupItems>;

    function    getSenderEvents: cSenderEvents;


    procedure   connect(aSender: tObject; aEvent: string; aReceiverMethod: tMethod); overload;
    procedure   disconnect(aSender: tObject; aEvent: string; aReceiverMethod: tMethod); overload;

    procedure   destroyPendingEvents;
  public
    procedure   setAutoDisconnect(aValue: boolean);
    function    isAutoDisconnect: boolean;

    class function  getInstance: cEventConnector;

    procedure   disconnectLater(aEvent: cEvent);

    procedure   connect(aSender: tObject; aEvent: string; aReceiver: tObject; aHandlerName: string); overload;
    procedure   connect(aSender: tObject; aEvent: string; aReceiver: tClass; aHandlerName: string); overload;

    procedure   disconnect(aSender: tObject; aEvent: string; aReceiver: tObject; aHandlerName: string); overload;
    procedure   disconnect(aSender: tObject; aEvent: string; aReceiver: tClass; aHandlerName: string); overload;
    procedure   disconnect(aSender: tObject; aEvent: string); overload;
    procedure   disconnect(aSender: tObject); overload;

    procedure   disconnectReceiver(aReceiver: tObject; aHandlerName: string); overload;
    procedure   disconnectReceiver(aReceiver: tObject); overload;

    constructor create;
    destructor  destroy; override;
  published
    procedure   handlerDestroying(aEvent: cEvent; aHandler: cHandler);
  end;


  eObjectDestroyInterceptor = class(cException);
  cObjectDestroyInterceptor = class
  private
    const
    INTERCEPT_METHOD_NAME         = 'beforeDestruction';


    DESTRUCTOR_METHOD_NOT_FOUND   = 'destructor method not found in class: %s';
    SELF_NOT_ASSIGNED             = 'self not assigned';
    OBJECT_NOT_ASSIGNED           = 'object not assigned';
    OBJECT_TYPE_NOT_ASSIGNED      = 'object type not assigned';
    CANNOT_PATCH_VMT              = 'cannot patch vmt';
    CANNOT_FIND_DESTRUCTOR_IN_VMT = 'cannot find destructor in VMT';
  private
    class function    connectInterceptor(aObject: tObject): boolean;

    //stub
    procedure         interceptorDestructorStub;
  public
    class function    isInterceptorConnected(aObject: tObject): boolean;
    class procedure   setObject(aObject: tObject);
  end;

//global visibility
procedure connect(aSender: tObject; aEvent: string; aReceiver: tObject; aHandlerName: string);
begin
  cEventConnector.getInstance.connect(aSender, aEvent, aReceiver, aHandlerName);
end;

procedure connect(aSender: tObject; aEvent: string; aReceiver: tClass; aHandlerName: string);
begin
  cEventConnector.getInstance.connect(aSender, aEvent, aReceiver, aHandlerName);
end;

procedure disconnect(aSender: tObject; aEvent: string; aReceiver: tObject; aHandlerName: string); overload;
begin
  cEventConnector.getInstance.disconnect(aSender, aEvent, aReceiver, aHandlerName);
end;

procedure disconnect(aSender: tObject; aEvent: string); overload;
begin
  cEventConnector.getInstance.disconnect(aSender, aEvent);
end;

procedure disconnect(aSender: tObject); overload;
begin
  cEventConnector.getInstance.disconnect(aSender);
end;

procedure disconnectReceiver(aSender: tObject); overload;
begin
  cEventConnector.getInstance.disconnectReceiver(aSender);
end;

procedure disconnectReceiver(aSender: tObject; aHandlerName: string); overload;
begin
  cEventConnector.getInstance.disconnectReceiver(aSender, aHandlerName);
end;


procedure debugDumpEvents(aReceiverFilter: tObject);
  function pointerToString(aPointer: pointer): string;
  begin
    result:= format('$%s', [intToHex(cardinal(aPointer), 4)]);
  end;

var
  eventConnector: cEventConnector;

  senderEvents: cSenderEvents;
  curSender: tObject;

  events: cEvents;
  curEvent: cEvent;

  handlers: cHandlers;
  curHandler: cHandler;
  totalHandlers: integer;

  j, k: integer;

  pair: tPair<pointer, cEvents>;

  debug: cDebug;
begin
  eventConnector:= cEventConnector.getInstance;

  debug:= cDebug.getInstance;

  debug.write('dumping events...');
  debug.write('');
  debug.write('');
  debug.write('pending events count: %d', [eventConnector.fPendingDestroyEvents.count]);
  senderEvents:= eventConnector.getSenderEvents;

  totalHandlers:= 0;

  for pair in senderEvents do begin
    curSender:= pair.key;

    debug.write('(-)sender: %s [%s]',
      [
        pointerToString(pair.key),
        curSender.className
      ]
    );

    events:= pair.value;

    debug.write('-|');
    debug.write('-|-(-)total events for sender: %s [%s] - %d',
      [
        pointerToString(curSender),
        curSender.className,
        events.count
      ]
    );
    for j := 0 to events.count - 1 do begin
      curEvent:= events.items[j];

      handlers:= curEvent.handlers;

      debug.write('----|');
      debug.write('----|---(-)total handlers for event: %s - %d, isPendingDestroy: %d', [curEvent.getName, handlers.count, integer(curEvent.getState = esPendingDestroy)]);
      debug.write('----|----|');
      for k := 0 to handlers.count - 1 do begin
        curHandler:= handlers.items[k];

        if not (assigned(aReceiverFilter) and (curHandler.getMethod.data = pointer(aReceiverFilter))) then continue;

        debug.write('----|----|-sender: %s [%s], event: %s, handler: method(%s, %s [%s])',
          [
            pointerToString(curSender),
            curSender.className,

            curEvent.getName,

            pointerToString(curHandler.getMethod.code),
            pointerToString(curHandler.getMethod.data),
            tObject(curHandler.getMethod.data).className
          ]
        );

        inc(totalHandlers);
      end;
    end;
    debug.write('');
    debug.write('');
    debug.write('');
    debug.write('');
  end;
  debug.write('total senders - %d', [senderEvents.count]);
  debug.write('total handlers - %d', [totalHandlers]);
end;

{ cSenders }


constructor cSenderEvents.create;
begin
  inherited create;

  fList:= tDictionary<pointer, cEvents>.create;
end;


function cSenderEvents.getEnumerator: tDictionary<pointer, cEvents>.tPairEnumerator;
begin
  result:= fList.getEnumerator;
end;

function cSenderEvents.getEvent(aObject: tObject; aName: string): cEvent;
var
  eventFoundIndex: integer;
  events: cEvents;
begin
  result:= nil;

  events:= getEvents(aObject);

  eventFoundIndex:= events.indexOfEventName(aName);
  if (eventFoundIndex <> -1) then begin
    result:= events.items[eventFoundIndex];
  end;

end;

function cSenderEvents.getEvents(aObject: tObject): cEvents;
begin
  result:= nil;
  if (eventsExists(aObject)) then begin
    result:= fList.items[aObject];
  end;
end;

function cSenderEvents.createEvent(aObject: tObject; aName: string): cEvent;
var
  events: cEvents;
begin
  events:= getEvents(aObject);

  result:= cEvent.create(aObject, aName);
  events.add(result);
end;

function cSenderEvents.createEvents(aObject: tObject): cEvents;
begin
  result:= cEvents.create;
  fList.add(aObject, result);
end;

procedure cSenderEvents.deleteEvent(aObject: tObject; aName: string);
var
  eventFoundIndex: integer;
  events: cEvents;
begin
  events:= getEvents(aObject);

  eventFoundIndex:= events.indexOfEventName(aName);
  if (eventFoundIndex <> -1) then begin
    events.delete(eventFoundIndex);
  end;

end;

procedure cSenderEvents.deleteEvents(aObject: tObject);
var
  events: cEvents;
begin
  events:= fList.items[aObject];
  freeAndNil(events);

  fList.remove(aObject);
end;

destructor cSenderEvents.destroy;
begin
  if assigned(fList) then begin
    freeAndNil(fList);
  end;

  inherited;
end;


function cSenderEvents.eventsExists(aObject: tObject): boolean;
begin
  result:= fList.containsKey(aObject);
end;

function cSenderEvents.getCount: integer;
begin
  result:= fList.count;
end;

{ cSender }

constructor cSender.create(aSender: tObject);
begin
  inherited create;
  fEvents:= cEvents.create;

  fObject:= aSender;
end;

function cSender.createEvent(aName: string): cEvent;
var
  foundIndex: integer;
begin
  result:= nil;
  foundIndex:= fEvents.indexOfEventName(aName);

  if (foundIndex = -1) then begin
    result:= cEvent.create(self, aName);
    fEvents.add(result);

    exit;
  end;

  result:= fEvents.items[foundIndex];
end;

procedure cSender.deleteEvent(aName: string);
var
  foundIndex: integer;
begin
  foundIndex:= fEvents.indexOfEventName(aName);

  if (foundIndex <> -1) then begin
    fEvents.delete(foundIndex);
  end;
end;

procedure cSender.deleteEvent(aIndex: integer);
begin
  fEvents.delete(aIndex);
end;

destructor cSender.destroy;
begin
  if (assigned(fEvents)) then begin
    freeAndNil(fEvents);
  end;

  inherited;
end;

function cSender.getEvents: cEvents;
begin
  result:= fEvents;
end;

function cSender.getObject: tObject;
begin
  result:= fObject;
end;

{ cEvents }

procedure cEvents.add(aEvent: cEvent);
begin
  aEvent.onStateChanged:= eventStateChanged;
  fList.add(aEvent);
end;

constructor cEvents.create;
begin
  inherited create;

  fList:= cList.create;
  fList.capacity:= INITIAL_CAPACITY;
end;

procedure cEvents.delete(aEvent: cEvent);
var
  foundIndex: integer;
begin
  foundIndex:= indexOf(aEvent);

  if (foundIndex = -1) then exit;

  delete(foundIndex);
end;

procedure cEvents.delete(aIndex: integer);
var
  foundEvent: cEvent;
begin
  foundEvent:= items[aIndex];

  if foundEvent.getState = esIdle then begin
    freeAndNil(foundEvent);
  end else begin
    foundEvent.setState(esGotDestroyRequest);
  end;

  fList.delete(aIndex);
end;

destructor cEvents.destroy;
begin
  if (assigned(fList)) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

function cEvents.getCount: integer;
begin
  result:= fList.count;
end;

function cEvents.getItemByIndex(aIndex: integer): cEvent;
begin
  result:= fList.items[aIndex];
end;

function cEvents.getItemByName(aName: string): cEvent;
var
  foundIndex: integer;
begin
  result:= nil;

  foundIndex:= indexOfEventName(aName);
  if (foundIndex = -1) then exit;

  result:= items[foundIndex];
end;

function cEvents.indexOf(aEvent: cEvent): integer;
begin
  result:= fList.indexOf(cEvent);
end;

function cEvents.indexOfEventName(aName: string): integer;
var
  i: integer;
  curEvent: cEvent;
begin
  result:= -1;

  for i:= 0 to count - 1 do begin
    curEvent:= items[i];

    if (curEvent.getName = aName) then begin
      result:= i;
      exit;
    end;
  end;
end;

procedure cEvents.eventStateChanged(aEvent: cEvent);
begin
  if (aEvent.getState = esPendingDestroy) then begin
    cEventConnector.getInstance.disconnectLater(aEvent);
  end;
end;

{ cEvent }

procedure cEvent.beforeDestruction;
begin
  inherited beforeDestruction;
end;

procedure cEvent.clearSenderEventHandler;
begin
  if (fState <> esPendingDestroy) then begin
    cClassKit.setObjectPropertyMethod(fSender, fName, cClassKit.getEmptyMethod);
  end;
end;

constructor cEvent.create(aSender: tObject; aName: string);
begin
  inherited create;
  fHandlers:= cHandlers.create;
  fExecutionHelper:= tDictionary<pointer, boolean>.create;

  fSender:= aSender;
  fName:= aName;


  //use raw invoke, asm realization
  // fHandlerStub:= cClassKit.createMethodPointerDelegation(rawEventsHandlerStub, fSender, fName);


  //use native rtti invoke
  fHandlerStub:= cClassKit.createMethodPointerDelegation(self, fSender, fName);

  setState(esIdle);
end;

procedure cEvent.updateConnection;
begin
  if (fHandlers.count = 0) then begin
    exit;
  end;

  if (fHandlers.count = 1) then begin
    //connect directly
    cClassKit.setObjectPropertyMethod(fSender, fName, fHandlers.items[0].getMethod);
  end else begin
    //connect via stub
    cClassKit.setObjectPropertyMethod(fSender, fName, fHandlerStub);
  end;
end;

function cEvent._addRef: integer;
begin
  //stub
end;

function cEvent._release: integer;
begin
  //stub
end;

function cEvent.createHandler(aMethod: tMethod): cHandler;
begin
  result:= cHandler.create(aMethod);

  result.onDestructing:= handlerDestructing;

  fHandlers.add(result);

  if (fState = esExecuting) then begin
    fExecutionHelper.add(result, false);
  end;

  updateConnection;
end;

procedure cEvent.deleteHandler(aMethod: tMethod);
var
  foundIndex: integer;
  curHandler:cHandler;
begin
  foundIndex:= fHandlers.indexOfHandlerMethod(aMethod);

  if (foundIndex = -1) then begin
    exit;
    raise eHandler.createFmt(cHandler.HANDLER_NOT_ASSIGNED, [fName]);
  end;

  curHandler:= fHandlers.items[foundIndex];

  if assigned(fOnHandlerDestructing) then begin
    fOnHandlerDestructing(self, curHandler);
  end;

  if (fState = esExecuting) then begin
    fExecutionHelper.addOrSetValue(curHandler, true);
  end;

  fHandlers.delete(foundIndex);

  updateConnection;
end;

destructor cEvent.destroy;
begin
  cClassKit.destroyMethodPointerDelegation(fHandlerStub);

  clearSenderEventHandler;

  if (assigned(fHandlers)) then begin
    freeAndNil(fHandlers);
  end;

  if (assigned(fExecutionHelper)) then begin
    freeAndNil(fExecutionHelper);
  end;

  inherited;
end;

procedure cEvent.rawEventsHandlerStub(aParams: pParameters; aStackSize: integer);
var
  i: integer;
begin
  i:= 0;
  while (i < fHandlers.count) do begin
    cClassKit.invokeMethod(fHandlers.items[i].method, aParams, aStackSize);

    inc(i);
  end;
end;

procedure cEvent.setState(aState: tEventState);
begin
  fState:= aState;
  if assigned(fOnStateChanged) then begin
    fOnStateChanged(self);
  end;
end;

function cEvent.execute(const aArgs: array of variant): variant;
var
  curHandler: cHandler;
  curHandlerPair: tPair<pointer, boolean>;
  curHandlerTraversed: boolean;
  i: integer;
begin
  if (fState in [esGotDestroyRequest, esPendingDestroy]) then exit;


  //fill helper
  fExecutionHelper.clear;
  for i:= 0 to fHandlers.count - 1 do begin
    curHandler:= fHandlers.items[i];
    fExecutionHelper.add(curHandler, false);
  end;

  setState(esExecuting);
  try
    //volatile handlers traverse
    for curHandlerPair in fExecutionHelper do begin

      curHandler:= curHandlerPair.key;
      curHandlerTraversed:= curHandlerPair.value;

      if (not curHandlerTraversed) then begin
        //after invoke state can change to esGotDestroyRequest!!!
        cClassKit.invokeMethod(curHandler.getMethod, aArgs);
      end;

    end;
  finally

    case fState of
      esExecuting:
      begin
        setState(esIdle);
      end;

      esGotDestroyRequest:
      begin
        clearSenderEventHandler;
        setState(esPendingDestroy);
      end;
    end;
  end;
end;

function cEvent.instanceToVariant(aInstance: tObject): variant;
begin
  tVarData(result).vType    := varByRef;
  tVarData(result).vPointer := aInstance;
end;

function cEvent.queryInterface(const aIID: tGUID; out aObj): hResult;
begin
  //stub
end;

function cEvent.getHandlers: cHandlers;
begin
  result:= fHandlers;
end;

function cEvent.getName: string;
begin
  result:= fName;
end;

function cEvent.getSender: tObject;
begin
  result:= fSender;
end;

function cEvent.getState: tEventState;
begin
  result:= fState;
end;

procedure cEvent.handlerDestructing(aHandler: cHandler);
begin
  if assigned(fOnHandlerDestructing) then begin
    fOnHandlerDestructing(self, aHandler);
  end;
end;

{ cHandlers }

procedure cHandlers.add(aHandler: cHandler);
begin
  fList.add(aHandler);
end;

constructor cHandlers.create;
begin
  inherited create;

  fList:= cList.create;
  fList.capacity:= INITIAL_CAPACITY;
end;

procedure cHandlers.delete(aHandler: cHandler);
var
  foundIndex: integer;
begin
  foundIndex:= indexOf(aHandler);

  if (foundIndex = -1) then exit;

  delete(foundIndex);
end;

procedure cHandlers.delete(aIndex: integer);
var
  foundItem: cHandler;
begin
  foundItem:= items[aIndex];
  freeAndNil(foundItem);
  fList.delete(aIndex);
end;

destructor cHandlers.destroy;
begin
  if (assigned(fList)) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

function cHandlers.getCount: integer;
begin
  result:= fList.count;
end;

function cHandlers.getItemByHandlerMethod(aHandlerMethod: tMethod): cHandler;
var
  foundIndex: integer;
begin
  result:= nil;

  foundIndex:= indexOfHandlerMethod(aHandlerMethod);
  if (foundIndex = -1) then exit;

  result:= items[foundIndex];
end;

function cHandlers.getItemByIndex(aIndex: integer): cHandler;
begin
  result:= fList.items[aIndex];
end;

function cHandlers.indexOf(aHandler: cHandler): integer;
begin
  result:= fList.indexOf(aHandler);
end;

function cHandlers.indexOfHandlerMethod(aHandlerMethod: tMethod): integer;
var
  i: integer;
  curHandler: cHandler;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curHandler:= items[i];

    if (cClassKit.isMethodEquals(curHandler.getMethod, aHandlerMethod)) then begin
      result:= i;
      exit;
    end;
  end;
end;

{ cHandler }

procedure cHandler.beforeDestruction;
begin
  if assigned(fOnDestructing) then begin
    fOnDestructing(self);
  end;

  inherited beforeDestruction;
end;

constructor cHandler.create(aMethod: tMethod);
begin
  inherited create;

  fMethod:= aMethod;
end;

destructor cHandler.destroy;
begin
  inherited;
end;

function cHandler.getMethod: tMethod;
begin
  result:= fMethod;
end;

{ cEventsConnector }

procedure cEventConnector.connect(aSender: tObject; aEvent: string; aReceiverMethod: tMethod);
var
  events: cEvents;
  event: cEvent;
begin
  destroyPendingEvents;

  //auto disconnection
  if (fAutoDisconnect) and (not cObjectDestroyInterceptor.isInterceptorConnected(aSender))then begin
    cObjectDestroyInterceptor.setObject(aSender);
  end;


  events:= fSenderEvents.getEvents(aSender);
  if (not(assigned(events))) then begin
    events:= fSenderEvents.createEvents(aSender);
  end;


  event:= fSenderEvents.getEvent(aSender, aEvent);
  if (not(assigned(event))) then begin
    event:= fSenderEvents.createEvent(aSender, aEvent);
    event.onHandlerDestructing:= handlerDestroying;
  end;

  if (event.handlers.indexOfHandlerMethod(aReceiverMethod) <> -1) then begin
    raise eHandler.createFmt(cHandler.HANDLER_ALREADY_ASSIGNED, [aEvent]);
  end;

  event.createHandler(aReceiverMethod);


  //add to lookup
  if not fReceiverLookup.containsKey(aReceiverMethod.data) then begin
    fReceiverLookup.add(aReceiverMethod.data, cReceiverLookupItems.create);
  end;
  fReceiverLookup.items[aReceiverMethod.data].add(cReceiverLookupItem.create(aSender, aEvent, aReceiverMethod));
end;

procedure cEventConnector.disconnectLater(aEvent: cEvent);
begin
  fCS.enter;
  try
    fPendingDestroyEvents.add(aEvent);
  finally
    fCS.leave;
  end;
end;

procedure cEventConnector.disconnectReceiver(aReceiver: tObject; aHandlerName: string);
var
  lookupItems: cReceiverLookupItems;
  foundIndex: integer;
  curItem: cReceiverLookupItem;
  receiverMethod: tMethod;
begin
  fCS.enter;
  try
    if not fReceiverLookup.containsKey(aReceiver) then exit;

    receiverMethod:= cClassKit.getObjectMethod(aReceiver, aHandlerName);

    lookupItems:= fReceiverLookup.items[aReceiver];

    foundIndex:= lookupItems.indexOf(receiverMethod);
    if (foundIndex = -1) then exit;

    curItem:= lookupItems.items[foundIndex];

    disconnect(curItem.sender, curItem.event, curItem.receiverMethod);

  finally
    fCS.leave;
  end;
end;

procedure cEventConnector.disconnectReceiver(aReceiver: tObject);
var
  lookupItems: cReceiverLookupItems;
  curItem: cReceiverLookupItem;
begin
  fCS.enter;
  try
    if not fReceiverLookup.containsKey(aReceiver) then exit;

    lookupItems:= fReceiverLookup.items[aReceiver];
    while (lookupItems.count <> 0) do begin
      curItem:= lookupItems.items[0];
      disconnect(curItem.sender, curItem.event, curItem.receiverMethod);
    end;

  finally
    fCS.leave;
  end;
end;

procedure cEventConnector.connect(aSender: tObject; aEvent: string; aReceiver: tClass; aHandlerName: string);
var
  receiverMethod: tMethod;
begin
  fCS.enter;
  try
    receiverMethod:= cClassKit.getClassMethod(aReceiver, aHandlerName);
    if (not assigned(receiverMethod.code)) then begin
      raise eHandler.createFmt(cHandler.HANDLER_NOT_METHOD, [aReceiver.className, aHandlerName]);
    end;

    connect(aSender, aEvent, receiverMethod);
  finally
    fCS.leave;
  end;
end;

procedure cEventConnector.connect(aSender: tObject; aEvent: string; aReceiver: tObject; aHandlerName: string);
var
  receiverMethod: tMethod;
begin
  fCS.enter;
  try
    receiverMethod:= cClassKit.getObjectMethod(aReceiver, aHandlerName);
    if (not assigned(receiverMethod.code)) then begin
      raise eHandler.createFmt(cHandler.HANDLER_NOT_METHOD, [aReceiver.className, aHandlerName]);
    end;
    connect(aSender, aEvent, receiverMethod);
  finally
    fCS.leave;
  end;

end;

constructor cEventConnector.create;
begin
  inherited create;
  fCS:= tCriticalSection.create;

  fPendingDestroyEvents:= cList.create;

  fSenderEvents:= cSenderEvents.create;


  fReceiverLookup:= tObjectDictionary<tObject, cReceiverLookupItems>.create([doOwnsValues]);

  setAutoDisconnect(false);
end;

destructor cEventConnector.destroy;
begin
  if (fSenderEvents.count > 0) then begin
    debugDumpEvents;
    raise eEventConnector.createFmt(NOT_ALL_EVENTS_DISCONNECTED, [fSenderEvents.count])
  end;

  destroyPendingEvents;

  if (assigned(fPendingDestroyEvents)) then begin
    freeAndNil(fPendingDestroyEvents);
  end;

  if (assigned(fSenderEvents)) then begin
    freeAndNil(fSenderEvents);
  end;

  if assigned(fReceiverLookup) then begin
    freeAndNil(fReceiverLookup);
  end;


  if (assigned(fCS)) then begin
    freeAndNil(fCS);
  end;

  inherited;
end;

procedure cEventConnector.destroyPendingEvents;
begin
  if (fPendingDestroyEvents.count = 0) then exit;

  fPendingDestroyEvents.freeInternalObjects;
  fPendingDestroyEvents.clear;
end;

procedure cEventConnector.disconnect(aSender: tObject; aEvent: string);
var
  events: cEvents;
  event: cEvent;
begin
  fCS.enter;
  try

    events:= fSenderEvents.getEvents(aSender);
    if (not(assigned(events))) then begin
      exit;
    end;


    event:= fSenderEvents.getEvent(aSender, aEvent);
    if (not(assigned(event))) then begin
      exit;
    end;

    fSenderEvents.deleteEvent(aSender, aEvent);

    if (events.count = 0) then begin
      fSenderEvents.deleteEvents(aSender);
    end;

  finally
    fCS.leave;
  end;
end;

procedure cEventConnector.disconnect(aSender: tObject);
begin
  fCS.enter;
  try

    if (fSenderEvents.eventsExists(aSender)) then fSenderEvents.deleteEvents(aSender);

  finally
    fCS.leave;
  end;
end;

procedure cEventConnector.disconnect(aSender: tObject; aEvent: string; aReceiver: tClass; aHandlerName: string);
begin
  fCS.enter;
  try
    disconnect(aSender, aEvent, cClassKit.getClassMethod(aReceiver, aHandlerName));
  finally
    fCS.leave;
  end;
end;

procedure cEventConnector.disconnect(aSender: tObject; aEvent: string; aReceiver: tObject; aHandlerName: string);
begin
  fCS.enter;
  try
    disconnect(aSender, aEvent, cClassKit.getObjectMethod(aReceiver, aHandlerName));
  finally
    fCS.leave;
  end;
end;

procedure cEventConnector.disconnect(aSender: tObject; aEvent: string; aReceiverMethod: tMethod);
var
  events: cEvents;
  event: cEvent;
begin
  events:= fSenderEvents.getEvents(aSender);
  if (not(assigned(events))) then begin
    exit;
  end;


  event:= fSenderEvents.getEvent(aSender, aEvent);
  if (not(assigned(event))) then begin
    exit;
  end;


  event.deleteHandler(aReceiverMethod);

  if (event.handlers.count = 0) then begin
    fSenderEvents.deleteEvent(aSender, aEvent);
  end;

  if (events.count = 0) then begin
    fSenderEvents.deleteEvents(aSender);
  end;
end;

class function cEventConnector.getInstance: cEventConnector;
begin
  result:= cSingleton.getInstance<cEventConnector>(stFinal);
end;

function cEventConnector.getSenderEvents: cSenderEvents;
begin
  result:= fSenderEvents;
end;


procedure cEventConnector.handlerDestroying(aEvent: cEvent; aHandler: cHandler);
begin
  //delete from lookup
  if fReceiverLookup.containsKey(aHandler.method.data) then begin
    fReceiverLookup.items[aHandler.method.data].remove(aEvent.sender, aEvent.name, aHandler.method);
  end;
end;

function cEventConnector.isAutoDisconnect: boolean;
begin
  result:= fAutoDisconnect;
end;

procedure cEventConnector.setAutoDisconnect(aValue: boolean);
begin
  fAutoDisconnect:= aValue;
end;

{ cObjectDestroyInterceptor }

class function  cObjectDestroyInterceptor.connectInterceptor(aObject: tObject): boolean;
var
  rttiContext: tRttiContext;
  objectType: tRttiType;
  interceptionMethod: tRttiMethod;

  oldProtectedFlag: dWord;
  vmtEntry: pPointer;
begin
  result:= false;
  if not assigned(aObject) then begin
    raise eObjectDestroyInterceptor.create(OBJECT_NOT_ASSIGNED);
  end;

  objectType:= rttiContext.getType(aObject.classType);
  if not assigned(objectType) then begin
    raise eObjectDestroyInterceptor.create(OBJECT_TYPE_NOT_ASSIGNED);
  end;


  interceptionMethod:= objectType.getMethod(INTERCEPT_METHOD_NAME);

  if not assigned(interceptionMethod) then begin
    raise eObjectDestroyInterceptor.createFmt(DESTRUCTOR_METHOD_NOT_FOUND, [aObject.className]);
  end;


  if isInterceptorConnected(aObject) then begin
    exit;
  end;


  vmtEntry:= cClassKit.getVirtualMethodEntry(aObject, interceptionMethod.codeAddress);
  if not assigned(vmtEntry) then begin
    raise eObjectDestroyInterceptor.create(CANNOT_FIND_DESTRUCTOR_IN_VMT);
  end;

  cClassKit.unProtectMemoryBlock(vmtEntry, sizeOf(vmtEntry), oldProtectedFlag);
  try
    try
      vmtEntry^:= @cObjectDestroyInterceptor.interceptorDestructorStub;
    except
      raise eObjectDestroyInterceptor.create(CANNOT_PATCH_VMT);
    end;
  finally
    cClassKit.protectMemoryBlock(vmtEntry, sizeOf(vmtEntry), oldProtectedFlag);
  end;
end;

procedure cObjectDestroyInterceptor.interceptorDestructorStub;
type
  tInterceptionMethodBody = procedure of object;
var
  methodExecuter: tInterceptionMethodBody;
var
  rttiContext: tRttiContext;
  objectType: tRttiType;
  interceptionMethod: tRttiMethod;

  oldProtectedFlag: dWord;
begin
  //self contains destructing object

  if not assigned(self) then begin
    raise eObjectDestroyInterceptor.create(SELF_NOT_ASSIGNED);
  end;

  objectType:= rttiContext.getType(self.classType);
  if not assigned(objectType) then begin
    raise eObjectDestroyInterceptor.create(OBJECT_NOT_ASSIGNED);
  end;


  interceptionMethod:= objectType.getMethod(INTERCEPT_METHOD_NAME);

  if not assigned(interceptionMethod) then begin
    raise eObjectDestroyInterceptor.createFmt(DESTRUCTOR_METHOD_NOT_FOUND, [self.className]);
  end;

  try
    methodExecuter:= tInterceptionMethodBody(cClassKit.makeMethod(self, interceptionMethod.codeAddress));
    methodExecuter;
  finally
    //disconnect all object events
    disconnect(self);
    disconnectReceiver(self);
  end;

end;

class function cObjectDestroyInterceptor.isInterceptorConnected(aObject: tObject): boolean;
var
  vmtEntry: pPointer;
begin
  vmtEntry:= cClassKit.getVirtualMethodEntry(aObject, @cObjectDestroyInterceptor.interceptorDestructorStub);
  result:= assigned(vmtEntry);
end;

class procedure cObjectDestroyInterceptor.setObject(aObject: tObject);
begin
  connectInterceptor(aObject);
end;

{ cReceiverLookupItem }

constructor cReceiverLookupItem.create(aSender: tObject; aEvent: string; aReceiverMethod: tMethod);
begin
  inherited create;
  sender:= aSender;
  event:= aEvent;
  receiverMethod:= aReceiverMethod;
end;

{ cReceiverLookupItems }

constructor cReceiverLookupItems.create;
begin
  inherited create;
  fList:= cList.create;
end;

destructor cReceiverLookupItems.destroy;
begin
  if assigned(fList) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

procedure cReceiverLookupItems.add(aItem: cReceiverLookupItem);
begin
  fList.add(aItem);
end;

procedure cReceiverLookupItems.delete(aIndex: integer);
begin
  fList.freeInternalObject(aIndex);
  fList.delete(aIndex);
end;

function cReceiverLookupItems.getCount: integer;
begin
  result:= fList.count;
end;

function cReceiverLookupItems.getItemByIndex(aIndex: integer): cReceiverLookupItem;
begin
  result:= fList.items[aIndex];
end;

function cReceiverLookupItems.indexOf(aEvent: string; aReceiverMethod: tMethod): integer;
var
  i: integer;
  curItem: cReceiverLookupItem;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];

    if (aEvent = curItem.event) and (cClassKit.isMethodEquals(curItem.receiverMethod, aReceiverMethod)) then begin
      result:= i;
      exit;
    end;
  end;
end;

function cReceiverLookupItems.indexOf(aSender: tObject; aEvent: string; aReceiverMethod: tMethod): integer;
var
  i: integer;
  curItem: cReceiverLookupItem;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];

    if (aSender = curItem.sender) and (aEvent = curItem.event) and (cClassKit.isMethodEquals(curItem.receiverMethod, aReceiverMethod)) then begin
      result:= i;
      exit;
    end;
  end;
end;

function cReceiverLookupItems.indexOf(aReceiverMethod: tMethod): integer;
var
  i: integer;
  curItem: cReceiverLookupItem;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];

    if (cClassKit.isMethodEquals(curItem.receiverMethod, aReceiverMethod)) then begin
      result:= i;
      exit;
    end;
  end;
end;

procedure cReceiverLookupItems.remove(aSender: tObject; aEvent: string; aReceiverMethod: tMethod);
var
  foundIndex: integer;
begin
  foundIndex:= indexOf(aSender, aEvent, aReceiverMethod);
  if (foundIndex = -1) then exit;

  delete(foundIndex);
end;

procedure cReceiverLookupItems.remove(aReceiverMethod: tMethod);
var
  foundIndex: integer;
begin
  foundIndex:= indexOf(aReceiverMethod);

  while (foundIndex <> -1) do begin
    delete(foundIndex);

    foundIndex:= indexOf(aReceiverMethod);
  end;
end;

procedure cReceiverLookupItems.remove(aEvent: string; aReceiverMethod: tMethod);
var
  foundIndex: integer;
begin
  foundIndex:= indexOf(aEvent, aReceiverMethod);
  if (foundIndex = -1) then exit;

  delete(foundIndex);
end;

end.
