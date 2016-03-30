unit clsPipes;
//FIFO
interface

uses
  Windows, SysUtils, Classes, Messages {, ObjInst};

resourcestring

  // Exception resource strings
  resPipeActive = 'Cannot change property while server is active!';
  resPipeConnected = 'Cannot change property when client is connected!';
  resBadPipeName = 'Invalid pipe name specified!';

const

  // Maximum and minimum constants
  MAX_THREADS = 101; // 1 Listener and 100 Workers
  MIN_BUFFER = 4096;
  MAX_BUFFER = MaxWord;

const

  // Pipe window messages
  WM_PIPEERROR_L = WM_USER + 100;
  WM_PIPEERROR_W = Succ(WM_PIPEERROR_L);
  WM_PIPECONNECT = Succ(WM_PIPEERROR_W);
  WM_PIPEDISCONNECT = Succ(WM_PIPECONNECT);
  WM_PIPESEND = Succ(WM_PIPEDISCONNECT);
  WM_PIPEMESSAGE = Succ(WM_PIPESEND);

type
  // Define the pipe data type
  HPIPE = THandle;

  // Pipe exceptions
  EPipeException = class(Exception);

  // Forward declarations
  TPipeServer = class;
  TPipeClient = class;

  // Pipe write data structure
  PPipeWrite = ^TPipeWrite;
  TPipeWrite = packed record
    Buffer: PChar;
    Count: Integer;
  end;

  // Writer queue node structure
  PWriteNode = ^TWriteNode;
  TWriteNode = packed record
    PipeWrite: PPipeWrite;
    NextNode: PWriteNode;
  end;

  // Writer queue class
  TWriteQueue = class(TObject)
  private
    // Private declarations
    FCount: Integer;
    FDataEv: THandle;
    FHead: PWriteNode;
    FTail: PWriteNode;
  protected
    // Protected declarations
    procedure Clear;
    function NewNode(PipeWrite: PPipeWrite): PWriteNode;
  public
    // Public declarations
    constructor Create;
    destructor Destroy; override;
    procedure Enqueue(PipeWrite: PPipeWrite);
    function Dequeue: PPipeWrite;
    property DataEvent: THandle read FDataEv;
    property Count: Integer read FCount;
  end;

  // Base class pipe thread that exposes SafeSynchronize method
  TPipeThread = class(TThread)
  private
    // Private declarations
  protected
    // Protected declarations
    procedure SafeSynchronize(Method: TThreadMethod);
  public
    // Public declarations
  end;

  // Pipe Listen thread class
  TPipeListenThread = class(TPipeThread)
  private
    // Private declarations
    FNotify: HWND;
    FErrorCode: Integer;
    FPipe: HPIPE;
    FPipeName: string;
    FConnected: Boolean;
    FEvents: array[0..1] of THandle;
    FOlapConnect: TOverlapped;
    FPipeServer: TPipeServer;
    FSA: TSecurityAttributes;
  protected
    // Protected declarations
    function CreateServerPipe: Boolean;
    procedure DoWorker;
    procedure Execute; override;
  public
    // Public declarations
    constructor Create(PipeServer: TPipeServer; KillEvent: THandle);
    destructor Destroy; override;
  end;

  // Pipe Server worker thread class
  TPipeServerThread = class(TPipeThread)
  private
    // Private declarations
    FNotify: HWND;
    FPipe: HPIPE;
    FErrorCode: Integer;
    FPipeServer: TPipeServer;
    FWrite: DWORD;
    FPipeWrite: PPipeWrite;
    FRcvRead: DWORD;
    FPendingRead: Boolean;
    FPendingWrite: Boolean;
    FRcvStream: TMemoryStream;
    FRcvBuffer: PChar;
    FRcvSize: DWORD;
    FEvents: array[0..3] of THandle;
    FOlapRead: TOverlapped;
    FOlapWrite: TOverlapped;
  protected
    // Protected declarations
    function QueuedRead: Boolean;
    function CompleteRead: Boolean;
    function QueuedWrite: Boolean;
    function CompleteWrite: Boolean;
    procedure DoMessage;
    procedure DoDequeue;
    procedure Execute; override;
  public
    // Public declarations
    constructor Create(PipeServer: TPipeServer; Pipe: HPIPE; KillEvent,
      DataEvent: THandle);
    destructor Destroy; override;
    property Pipe: HPIPE read FPipe;
  end;

  // Pipe info record stored by the TPipeServer component for each working thread
  PPipeInfo = ^TPipeInfo;
  TPipeInfo = packed record
    Pipe: HPIPE;
    WriteQueue: TWriteQueue;
  end;

  // Pipe context for error messages
  TPipeContext = (pcListener, pcWorker);

  // Pipe Events
  TOnPipeConnect = procedure(Sender: TObject; Pipe: HPIPE) of object;
  TOnPipeDisconnect = procedure(Sender: TObject; Pipe: HPIPE) of object;
  TOnPipeMessage = procedure(Sender: TObject; Pipe: HPIPE; Stream: TStream) of
    object;
  TOnPipeSent = procedure(Sender: TObject; Pipe: HPIPE; Size: DWORD) of object;
  TOnPipeError = procedure(Sender: TObject; Pipe: HPIPE; PipeContext:
    TPipeContext; ErrorCode: Integer) of object;

  // Pipe Server component
  TPipeServer = class(TComponent)
  private
    // Private declarations
    FHwnd: HWND;
    FPipeName: string;
    FActive: Boolean;
    FInShutDown: Boolean;
    FKillEv: THandle;
    FClients: TList;
    FListener: TPipeListenThread;
    FThreadCount: Integer;
    FSA: TSecurityAttributes;
    FOPS: TOnPipeSent;
    FOPC: TOnPipeConnect;
    FOPD: TOnPipeDisconnect;
    FOPM: TOnPipeMessage;
    FOPE: TOnPipeError;
    procedure DoStartup;
    procedure DoShutdown;
  protected
    // Protected declarations
    function Dequeue(Pipe: HPIPE): PPipeWrite;
    function GetClient(Index: Integer): HPIPE;
    function GetActiveClients: Integer;
    procedure WndMethod(var Message: TMessage);
    procedure RemoveClient(Pipe: HPIPE);
    procedure SetActive(Value: Boolean);
    procedure SetPipeName(Value: string);
    procedure AddWorkerThread(Pipe: HPIPE);
    procedure RemoveWorkerThread(Sender: TObject);
    procedure RemoveListenerThread(Sender: TObject);
  public
    // Public declarations
    constructor Create; overload;
    constructor Create(AOwner: TComponent); overload; override;
    destructor Destroy; override;
    function Write(Pipe: HPIPE; var Buffer; Count: Integer): Boolean;

    procedure start;
    procedure stop;

    property WindowHandle: HWND read FHwnd;
    property ActiveClients: Integer read GetActiveClients;
    property Clients[Index: Integer]: HPIPE read GetClient;
  published
    // Published declarations
    property Active: Boolean read FActive write SetActive;
    property OnPipeSent: TOnPipeSent read FOPS write FOPS;
    property OnPipeConnect: TOnPipeConnect read FOPC write FOPC;
    property OnPipeDisconnect: TOnPipeDisconnect read FOPD write FOPD;
    property OnPipeMessage: TOnPipeMessage read FOPM write FOPM;
    property OnPipeError: TOnPipeError read FOPE write FOPE;
    property PipeName: string read FPipeName write SetPipeName;
  end;

  // Pipe Client worker thread class
  TPipeClientThread = class(TPipeThread)
  private
    // Private declarations
    FNotify: HWND;
    FPipe: HPIPE;
    FErrorCode: Integer;
    FPipeClient: TPipeClient;
    FWrite: DWORD;
    FPipeWrite: PPipeWrite;
    FRcvRead: DWORD;
    FPendingRead: Boolean;
    FPendingWrite: Boolean;
    FRcvStream: TMemoryStream;
    FRcvBuffer: PChar;
    FRcvSize: DWORD;
    FEvents: array[0..3] of THandle;
    FOlapRead: TOverlapped;
    FOlapWrite: TOverlapped;
  protected
    // Protected declarations
    function QueuedRead: Boolean;
    function CompleteRead: Boolean;
    function QueuedWrite: Boolean;
    function CompleteWrite: Boolean;
    procedure DoMessage;
    procedure DoDequeue;
    procedure Execute; override;
  public
    // Public declarations
    constructor Create(PipeClient: TPipeClient; Pipe: HPIPE; KillEvent,
      DataEvent: THandle);
    destructor Destroy; override;
  end;

  // Pipe Client component
  TPipeClient = class(TComponent)
  private
    // Private declarations
    FHwnd: HWND;
    FPipe: HPIPE;
    FPipeName: string;
    FServerName: string;
    FConnected: Boolean;
    FWriteQueue: TWriteQueue;
    FWorker: TPipeClientThread;
    FKillEv: THandle;
    FSA: TSecurityAttributes;
    FOPE: TOnPipeError;
    FOPD: TOnPipeDisconnect;
    FOPM: TOnPipeMessage;
    FOPS: TOnPipeSent;
  protected
    // Protected declarations
    procedure SetPipeName(Value: string);
    procedure SetServerName(Value: string);
    function Dequeue: PPipeWrite;
    procedure RemoveWorkerThread(Sender: TObject);
    procedure WndMethod(var Message: TMessage);
  public
    // Public declarations
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Connect: Boolean;
    procedure Disconnect;
    function Write(var Buffer; Count: Integer): Boolean;
    property Connected: Boolean read FConnected;
    property WindowHandle: HWND read FHwnd;
  published
    // Published declarations
    property PipeName: string read FPipeName write SetPipeName;
    property ServerName: string read FServerName write SetServerName;
    property OnPipeDisconnect: TOnPipeDisconnect read FOPD write FOPD;
    property OnPipeMessage: TOnPipeMessage read FOPM write FOPM;
    property OnPipeSent: TOnPipeSent read FOPS write FOPS;
    property OnPipeError: TOnPipeError read FOPE write FOPE;
  end;

  // Pipe write helper functions
function AllocPipeWrite(const Buffer; Count: Integer): PPipeWrite;
procedure DisposePipeWrite(PipeWrite: PPipeWrite);
procedure CheckPipeName(Value: string);

// Security helper functions
procedure InitializeSecurity(var SA: TSecurityAttributes);
procedure FinalizeSecurity(var SA: TSecurityAttributes);

// Component register procedure

implementation

////////////////////////////////////////////////////////////////////////////////
//
//   TPipeClient
//
////////////////////////////////////////////////////////////////////////////////

constructor TPipeClient.Create(AOwner: TComponent);
begin

  // Perform inherited
  inherited Create(AOwner);

  // Set properties
  InitializeSecurity(FSA);
  FKillEv := CreateEvent(@FSA, True, False, nil);
  FPipe := INVALID_HANDLE_VALUE;
  FConnected := False;
  FWriteQueue := TWriteQueue.Create;
  FWorker := nil;
  FPipeName := 'PipeServer';
  FServerName := '';
  FHwnd := AllocateHWnd(WndMethod);

end;

destructor TPipeClient.Destroy;
begin

  // Disconnect if connected
  Disconnect;

  // Free resources
  FinalizeSecurity(FSA);
  CloseHandle(FKillEv);
  FWriteQueue.Free;
  DeAllocateHWnd(FHwnd);

  // Perform inherited
  inherited Destroy;

end;

function TPipeClient.Connect: Boolean;
var
  szname: string;
  lpname: array[0..1023] of Char;
  resolved: Boolean;
  dwmode: DWORD;
  dwSize: DWORD;
begin

  // Optimistic result
  result := True;

  // Exit if already connected
  if FConnected then
    exit;

  // Set server name resolution
  resolved := False;

  // Check name against local computer name first
  dwSize := SizeOf(lpname);
  if GetComputerName(lpname, dwSize) then
  begin
    // Compare names
    if (CompareText(lpname, FServerName) = 0) then
    begin
      // Server name represents local computer, switch to the
      // preferred use of "." for the name
      szname := '.';
      resolved := True;
    end;
  end;

  // Resolve the server name
  if not (resolved) then
  begin
    // Blank name also indicates local computer
    if (FServerName = '') then
      szname := '.'
    else
      szname := FServerName;
  end;

  // Build the full pipe name
  StrCopy(lpname, PChar(Format('\\%s\pipe\%s', [szname, FPipeName])));

  // Attempt to wait for the pipe first
  if WaitNamedPipe(@lpname, NMPWAIT_USE_DEFAULT_WAIT) then
  begin
    // Attempt to create client side handle
    FPipe := CreateFile(@lpname, GENERIC_READ or GENERIC_WRITE, 0, @FSA,
      OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_OVERLAPPED, 0);
    // Success if we have a valid handle
    result := (FPipe <> INVALID_HANDLE_VALUE);
    // Need to set message mode
    if result then
    begin
      dwmode := PIPE_READMODE_MESSAGE or PIPE_WAIT;
      SetNamedPipeHandleState(FPipe, dwmode, nil, nil);
      // Create thread to handle the pipe IO
      FWorker := TPipeClientThread.Create(Self, FPipe, FKillEv,
        FWriteQueue.DataEvent);
      FWorker.OnTerminate := RemoveWorkerThread;
    end;
  end
  else
    // Failure
    result := False;

  // Set connected flag
  FConnected := result;

end;

procedure TPipeClient.Disconnect;
begin

  // Exit if not connected
  if not (FConnected) then
    exit;

  // Signal the kill event
  SetEvent(FKillEv);

  // Terminate and wait for the worker thread to finish
  if Assigned(FWorker) then
  begin
    FWorker.Terminate;
    //FWorker.WaitFor; removed
  end;

  // Set new state
  FConnected := False;

end;

function TPipeClient.Write(var Buffer; Count: Integer): Boolean;
begin

  // Set default result (depends on connected state)
  result := FConnected;

  // Exit if not connected
  if not (result) then
    exit;

  // Enqueue the data
  FWriteQueue.Enqueue(AllocPipeWrite(Buffer, Count));

end;

procedure TPipeClient.SetPipeName(Value: string);
begin

  // Raise error if pipe is connected
  if FConnected then
    raise EPipeException.CreateRes(@resPipeConnected);

  // Check the pipe name
  CheckPipeName(Value);

  // Set the pipe name
  FPipeName := Value;

end;

procedure TPipeClient.SetServerName(Value: string);
begin

  // Raise error if pipe is connected
  if FConnected then
    raise EPipeException.CreateRes(@resPipeConnected);

  // Set the server name
  FServerName := Value;

end;

function TPipeClient.Dequeue: PPipeWrite;
begin

  // Dequeue the record and break
  result := FWriteQueue.Dequeue;

end;

procedure TPipeClient.RemoveWorkerThread(Sender: TObject);
begin

  // Notify of disconnect
  if not (csDestroying in ComponentState) and Assigned(FOPD) then
    FOPD(Self, FPipe);

  // Set thread variable to nil
  FWorker := nil;
  FPipe := INVALID_HANDLE_VALUE;

  // Set state to disconneted
  FConnected := False;

end;

procedure TPipeClient.WndMethod(var Message: TMessage);
var
  MemStream: TMemoryStream;
  lpmsg: PChar;
  dwmem: Integer;
begin

  // Handle the pipe messages
  case Message.Msg of
    WM_PIPEERROR_W:
      if Assigned(FOPE) then
        FOPE(Self, Message.wParam, pcWorker, Message.lParam);
    WM_PIPEDISCONNECT:
      if Assigned(FOPD) then
        FOPD(Self, Message.wParam);
    WM_PIPESEND:
      if Assigned(FOPS) then
        FOPS(Self, Message.wParam, Message.lParam);
    WM_PIPEMESSAGE:
      begin
        dwmem := GlobalSize(Message.lParam);
        if (dwmem > 0) then
        begin
          MemStream := TMemoryStream.Create;
          lpmsg := GlobalLock(Message.lParam);
          try
            // Copy the actual stream contents over
            MemStream.Write(lpmsg^, dwmem);
            MemStream.Position := 0;
            // Call the OnMessage event if assigned
            if Assigned(FOPM) then
              FOPM(Self, Message.wParam, MemStream);
          finally
            MemStream.Free;
            GlobalUnLock(Message.lParam);
          end;
        end;
        GlobalFree(Message.lParam);
      end;
  else
    // Call default window procedure
    DefWindowProc(FHwnd, Message.Msg, Message.wParam, Message.lParam);
  end;

end;

////////////////////////////////////////////////////////////////////////////////
//
//   TPipeClientThread
//
////////////////////////////////////////////////////////////////////////////////

constructor TPipeClientThread.Create(PipeClient: TPipeClient; Pipe: HPIPE;
  KillEvent, DataEvent: THandle);
begin

  // Set starting parameters
  FreeOnTerminate := True;
  FPipe := Pipe;
  FPipeClient := PipeClient;
  FNotify := PipeClient.WindowHandle;
  FErrorCode := ERROR_SUCCESS;
  FPendingRead := False;
  FPendingWrite := False;
  FPipeWrite := nil;
  FRcvSize := MIN_BUFFER;
  FRcvBuffer := AllocMem(FRcvSize);
  FRcvStream := TMemoryStream.Create;
  FOlapRead.Offset := 0;
  FOlapRead.OffsetHigh := 0;
  FOlapRead.hEvent := CreateEvent(nil, True, False, nil);
  FOlapWrite.hEvent := CreateEvent(nil, True, False, nil);
  ResetEvent(KillEvent);
  FEvents[0] := KillEvent;
  FEvents[1] := FOlapRead.hEvent;
  FEvents[2] := FOlapWrite.hEvent;
  FEvents[3] := DataEvent;

  // Perform inherited
  inherited Create(False);

end;

destructor TPipeClientThread.Destroy;
begin

  // Free the write buffer we may be holding on to
  if FPendingWrite and Assigned(FPipeWrite) then
    DisposePipeWrite(FPipeWrite);

  // Free the receiver stream and buffer memory
  FreeMem(FRcvBuffer);
  FRcvStream.Free;

  // Perform inherited
  inherited Destroy;

end;

function TPipeClientThread.QueuedRead: Boolean;
var
  bRead: Boolean;
begin

  // Set default result
  result := True;

  // If we already have a pending read then nothing to do
  if not (FPendingRead) then
  begin
    // Set defaults for reading
    FRcvStream.Clear;
    FRcvSize := MIN_BUFFER;
    ReAllocMem(FRcvBuffer, FRcvSize);
    // Keep reading all available data until we get a pending read or a failure
    while result and not (FPendingRead) do
    begin
      // Perform a read
      bRead := ReadFile(FPipe, FRcvBuffer^, FRcvSize, FRcvRead, @FOlapRead);
      // Get the last error code
      FErrorCode := GetLastError;
      // Check the read result
      if bRead then
      begin
        // We read a full message
        FRcvStream.Write(FRcvBuffer^, FRcvRead);
        // Call the OnData
        DoMessage;
      end
      else
      begin
        // Handle cases where message is larger than read buffer used
        if (FErrorCode = ERROR_MORE_DATA) then
        begin
          // Write the current data
          FRcvStream.Write(FRcvBuffer^, FRcvSize);
          // Determine how much we need to expand the buffer to
          if PeekNamedPipe(FPipe, nil, 0, nil, nil, @FRcvSize) then
            ReallocMem(FRcvBuffer, FRcvSize)
          else
          begin
            // Failure
            FErrorCode := GetLastError;
            result := False;
          end;
        end
          // Pending read
        else
          if (FErrorCode = ERROR_IO_PENDING) then
            // Set pending flag
            FPendingRead := True
          else
            // Failure
            result := False;
      end;
    end;
  end;

end;

function TPipeClientThread.CompleteRead: Boolean;
begin

  // Reset the read event and pending flag
  ResetEvent(FOlapRead.hEvent);

  // Check the overlapped results
  result := GetOverlappedResult(FPipe, FOlapRead, FRcvRead, True);

  // Handle failure
  if not (result) then
  begin
    // Get the last error code
    FErrorCode := GetLastError;
    // Check for more data
    if (FErrorCode = ERROR_MORE_DATA) then
    begin
      // Write the current data
      FRcvStream.Write(FRcvBuffer^, FRcvSize);
      // Determine how much we need to expand the buffer to
      result := PeekNamedPipe(FPipe, nil, 0, nil, nil, @FRcvSize);
      if result then
      begin
        // Realloc mem to read in rest of message
        ReallocMem(FRcvBuffer, FRcvSize);
        // Read from the file again
        result := ReadFile(FPipe, FRcvBuffer^, FRcvSize, FRcvRead, @FOlapRead);
        // Handle error
        if not (result) then
        begin
          // Set error code
          FErrorCode := GetLastError;
          // Check for pending again, which means our state hasn't changed
          if (FErrorCode = ERROR_IO_PENDING) then
          begin
            // Bail out and wait for this operation to complete
            result := True;
            exit;
          end;
        end;
      end
      else
        // Set error code
        FErrorCode := GetLastError;
    end;
  end;

  // Handle success
  if result then
  begin
    // We read a full message
    FRcvStream.Write(FRcvBuffer^, FRcvRead);
    // Call the OnData
    DoMessage;
    // Reset the pending read
    FPendingRead := False;
  end;

end;

function TPipeClientThread.QueuedWrite: Boolean;
var
  bWrite: Boolean;
begin

  // Set default result
  result := True;

  // If we already have a pending write then nothing to do
  if not (FPendingWrite) then
  begin
    // Check state of data event
    if (WaitForSingleObject(FEvents[3], 0) = WAIT_OBJECT_0) then
    begin
      // Pull the data from the queue
      SafeSynchronize(DoDequeue);
      // Is the record assigned?
      if Assigned(FPipeWrite) then
      begin
        // Write the data to the client
        bWrite := WriteFile(FPipe, FPipeWrite^.Buffer^, FPipeWrite^.Count,
          FWrite, @FOlapWrite);
        // Get the last error code
        FErrorCode := GetLastError;
        // Check the write operation
        if bWrite then
        begin
          // Call the OnData in the main thread
          PostMessage(FNotify, WM_PIPESEND, FPipe, FWrite);
          // Free the pipe write data
          DisposePipeWrite(FPipeWrite);
          FPipeWrite := nil;
          // Reset the write event
          ResetEvent(FOlapWrite.hEvent);
        end
        else
        begin
          // Only acceptable error is pending
          if (FErrorCode = ERROR_IO_PENDING) then
            // Set pending flag
            FPendingWrite := True
          else
            // Failure
            result := False;
        end;
      end;
    end;
  end;

end;

function TPipeClientThread.CompleteWrite: Boolean;
begin

  // Reset the write event and pending flag
  ResetEvent(FOlapWrite.hEvent);

  // Check the overlapped results
  result := GetOverlappedResult(FPipe, FOlapWrite, FWrite, True);

  // Handle failure
  if not (result) then
    // Get the last error code
    FErrorCode := GetLastError
  else
    // We sent a full message so call the OnSent in the main thread
    PostMessage(FNotify, WM_PIPESEND, FPipe, FWrite);

  // We are done either way. Make sure to free the queued pipe data
  // and to reset the pending flag
  if Assigned(FPipeWrite) then
  begin
    DisposePipeWrite(FPipeWrite);
    FPipeWrite := nil;
  end;
  FPendingWrite := False;

end;

procedure TPipeClientThread.DoDequeue;
begin

  // Get the next queued data event
  FPipeWrite := FPipeClient.Dequeue;

end;

procedure TPipeClientThread.DoMessage;
var
  lpmem: DWORD;
  lpmsg: PChar;
begin

  // Convert the memory to global memory and send to pipe server
  lpmem := GlobalAlloc(GHND, FRcvStream.Size);
  lpmsg := GlobalLock(lpmem);

  // Copy from the pipe
  FRcvStream.Position := 0;
  FRcvStream.Read(lpmsg^, FRcvStream.Size);

  // Unlock the memory
  GlobalUnlock(lpmem);

  // Send to the pipe server to manage
  PostMessage(FNotify, WM_PIPEMESSAGE, FPipe, lpmem);

  // Clear the read stream
  FRcvStream.Clear;

end;

procedure TPipeClientThread.Execute;
var
  dwEvents: Integer;
  bOK: Boolean;
begin

  // Loop while not terminated
  while not (Terminated) do
  begin
    // Make sure we always have an outstanding read and write queued up
    bOK := (QueuedRead and QueuedWrite);
    if bOK then
    begin
      // If we are in a pending write then we need will not wait for the
      // DataEvent, because we are already waiting for a write to finish
      dwEvents := 4;
      if FPendingWrite then
        Dec(dwEvents);
      // Handle the event that was signalled (or failure)
      case WaitForMultipleObjects(dwEvents, @FEvents, False, INFINITE) of
        // Killed by pipe server
        WAIT_OBJECT_0: Terminate;
        // Read completed
        WAIT_OBJECT_0 + 1: bOK := CompleteRead;
        // Write completed
        WAIT_OBJECT_0 + 2: bOK := CompleteWrite;
        // Data waiting to be sent
        WAIT_OBJECT_0 + 3: ; // Data available to write
      else
        // General failure
        FErrorCode := GetLastError;
        bOK := False;
      end;
    end;
    // Check status
    if not (bOK) then
    begin
      // Call OnError in the main thread if this is not a disconnect. Disconnects
      // have their own event, and are not to be considered an error
      if (FErrorCode <> ERROR_PIPE_NOT_CONNECTED) then
        PostMessage(FNotify, WM_PIPEERROR_W, FPipe, FErrorCode);
      // Terminate
      Terminate;
    end;
  end;

  // Make sure the handle is still valid
  if (FErrorCode <> ERROR_INVALID_HANDLE) then
  begin
    DisconnectNamedPipe(FPipe);
    CloseHandle(FPipe);
  end;

  // Close all open handles that we own
  CloseHandle(FOlapRead.hEvent);
  CloseHandle(FOlapWrite.hEvent);

end;

////////////////////////////////////////////////////////////////////////////////
//
//   TServerPipe
//
////////////////////////////////////////////////////////////////////////////////

constructor TPipeServer.Create(AOwner: TComponent);
begin

  // Perform inherited
  inherited Create(AOwner);

  // Initialize the security attributes
  InitializeSecurity(FSA);

  // Set staring defaults
  FPipeName := 'PipeServer';
  FActive := False;
  FInShutDown := False;
  FKillEv := CreateEvent(@FSA, True, False, nil);
  FClients := TList.Create;
  FListener := nil;
  FThreadCount := 0;
  FHwnd := AllocateHWnd(WndMethod);

end;

destructor TPipeServer.Destroy;
begin

  // Perform the shutdown if active
  if FActive then
    DoShutdown;

  // Release all objects, events, and handles
  CloseHandle(FKillEv);
  FClients.Free;
  FinalizeSecurity(FSA);

  // Close the window
  DeAllocateHWnd(FHwnd);

  // Perform inherited
  inherited Destroy;

end;

procedure TPipeServer.WndMethod(var Message: TMessage);
var
  MemStream: TMemoryStream;
  lpmsg: PChar;
  dwmem: Integer;
begin
  // Handle the pipe messages
  case Message.Msg of
    WM_PIPEERROR_L:
      if not (FInShutdown) and Assigned(FOPE) then
        FOPE(Self, Message.wParam, pcListener, Message.lParam);
    WM_PIPEERROR_W:
      if not (FInShutdown) and Assigned(FOPE) then
        FOPE(Self, Message.wParam, pcWorker, Message.lParam);
    WM_PIPECONNECT:
      if Assigned(FOPC) then
        FOPC(Self, Message.wParam);
    WM_PIPEDISCONNECT:
      if Assigned(FOPD) then
        FOPD(Self, Message.wParam);
    WM_PIPESEND:
      if Assigned(FOPS) then
        FOPS(Self, Message.wParam, Message.lParam);
    WM_PIPEMESSAGE:
      begin
        dwmem := GlobalSize(Message.lParam);
        if (dwmem > 0) then
        begin
          MemStream := TMemoryStream.Create;
          lpmsg := GlobalLock(Message.lParam);
          try
            // Copy the actual stream contents over
            MemStream.Write(lpmsg^, dwmem);
            MemStream.Position := 0;
            // Call the OnMessage event if assigned
            if Assigned(FOPM) then
              FOPM(Self, Message.wParam, MemStream);
          finally
            MemStream.Free;
            GlobalUnLock(Message.lParam);
          end;
        end;
        GlobalFree(Message.lParam);
      end;
  else
    // Call default window procedure
    DefWindowProc(FHwnd, Message.Msg, Message.wParam, Message.lParam);
  end;

end;

function TPipeServer.GetClient(Index: Integer): HPIPE;
begin

  // Return the requested pipe
  result := PPipeInfo(FClients[Index])^.Pipe;

end;

function TPipeServer.GetActiveClients: Integer;
begin

  // Return the number of active clients
  result := FClients.Count;

end;

function TPipeServer.Write(Pipe: HPIPE; var Buffer; Count: Integer): Boolean;
var
  index: Integer;
  ppiClient: PPipeInfo;
begin

  // Set default result
  result := False;

  // Locate the pipe info record for the given pipe first
  ppiClient := nil;
  for index := FClients.Count - 1 downto 0 do
  begin
    // Get the pipe record and compare handles
    ppiClient := FClients[index];
    if (ppiClient^.Pipe = Pipe) then
      break;
    ppiClient := nil;
  end;

  // If client record is nil then raise exception
  if (ppiClient = nil) or (Count > MAX_BUFFER) then
    exit;

  // Queue the data
  ppiClient.WriteQueue.Enqueue(AllocPipeWrite(Buffer, Count));
  result := True;

end;

constructor TPipeServer.Create;
begin
  Create(nil);
end;

function TPipeServer.Dequeue(Pipe: HPIPE): PPipeWrite;
var
  index: Integer;
  ppiClient: PPipeInfo;
begin

  // Locate the pipe info record for the given pipe and dequeue the next
  // available record
  result := nil;
  for index := FClients.Count - 1 downto 0 do
  begin
    // Get the pipe record and compare handles
    ppiClient := FClients[index];
    if (ppiClient^.Pipe = Pipe) then
    begin
      // Found the desired pipe record, dequeue the record and break
      result := ppiClient.WriteQueue.Dequeue;
      break;
    end;
  end;

end;

procedure TPipeServer.RemoveClient(Pipe: HPIPE);
var
  index: Integer;
  ppiClient: PPipeInfo;
begin

  // Locate the pipe info record for the give pipe and remove it
  for index := FClients.Count - 1 downto 0 do
  begin
    // Get the pipe record and compare handles
    ppiClient := FClients[index];
    if (ppiClient^.Pipe = Pipe) then
    begin
      // Found the desired pipe record, free it
      FClients.Delete(index);
      ppiClient.WriteQueue.Free;
      FreeMem(ppiClient);
      // Call the OnDisconnect if assigned and not in a shutdown
      if not (FInShutdown) and Assigned(FOPD) then
        PostMessage(FHwnd, WM_PIPEDISCONNECT, Pipe, 0);
      // Break the loop
      break;
    end;
  end;

end;

procedure TPipeServer.SetActive(Value: Boolean);
begin

  // Check against current state
  if (FActive <> Value) then
  begin
    // Shutdown if active
    if FActive then
      DoShutdown;
    // Startup if not active
    if Value then
      DoStartup
  end;

end;

procedure TPipeServer.SetPipeName(Value: string);
begin

  // Cannot change pipe name if pipe server is active
  if FActive then
    raise EPipeException.CreateRes(@resPipeActive);

  // Check the pipe name
  CheckPipeName(Value);

  // Set the new pipe name
  FPipeName := Value;

end;

procedure TPipeServer.AddWorkerThread(Pipe: HPIPE);
var
  ppInfo: PPipeInfo;
  pstWorker: TPipeServerThread;
begin

  // If there are more than 100 worker threads then we need to
  // suspend the listener thread until our count decreases
  if (FThreadCount > MAX_THREADS) and Assigned(FListener) then
    FListener.Suspend;

  // Create a new pipe info structure to manage the pipe
  ppInfo := AllocMem(SizeOf(TPipeInfo));
  ppInfo^.Pipe := Pipe;
  ppInfo^.WriteQueue := TWriteQueue.Create;

  // Add the structure to the list of pipes
  FClients.Add(ppInfo);

  // Resource protection
  pstWorker := nil;
  try
    // Create the server worker thread
    Inc(FThreadCount);
    pstWorker := TPipeServerThread.Create(Self, Pipe, FKillEv,
      ppInfo^.WriteQueue.DataEvent);
    pstWorker.OnTerminate := RemoveWorkerThread;
  except
    // Exception during thread create, remove the client record
    RemoveClient(Pipe);
    // Disconnect and close the pipe handle
    DisconnectNamedPipe(Pipe);
    CloseHandle(Pipe);
    FreeAndNil(pstWorker);
    // Decrement the thread count
    Dec(FThreadCount);
  end;

end;

procedure TPipeServer.RemoveWorkerThread(Sender: TObject);
begin

  // Remove the pipe info record associated with this thread
  RemoveClient(TPipeServerThread(Sender).Pipe);

  // Decrement the thread count
  Dec(FThreadCount);

  // If there are less than 100 worker threads then we need to
  // resume the listener thread
  if (FThreadCount < MAX_THREADS) and Assigned(FListener) then
    FListener.Resume;

end;

procedure TPipeServer.start;
begin
  Active:= true;
end;

procedure TPipeServer.stop;
begin
  Active:= false;
end;

procedure TPipeServer.RemoveListenerThread(Sender: TObject);
begin

  // Decrement the thread count
  Dec(FThreadCount);

  // If we not in a shutdown, and we were the only thread, then
  // change the active state
  if (not (FInShutDown) and (FThreadCount = 0)) then
    FActive := False;

end;

procedure TPipeServer.DoStartup;
begin

  // If we are active then exit
  if FActive then
    exit;

  // Make sure the kill event is in a non-signaled state
  ResetEvent(FKillEv);

  // Resource protection
  try
    // Create the listener thread
    Inc(FThreadCount);
    FListener := TPipeListenThread.Create(Self, FKillEv);
    FListener.OnTerminate := RemoveListenerThread;
  except
    // Exception during thread create. Decrement the thread count and
    // re-raise the exception
    FreeAndNil(FListener);
    Dec(FThreadCount);
    raise;
  end;

  // Set active state
  FActive := True;

end;

procedure TPipeServer.DoShutdown;
var
  msg: TMsg;
  failsafe: DWORD;
begin

  // If we are not active then exit
  if not (FActive) then
    exit;

  // Resource protection
  try
    // Set shutdown flag
    FInShutDown := True;
    // Signal the kill event
    SetEvent(FKillEv);
    // Wait until all threads have completed (or we hit failsafe)
    failsafe := GetTickCount;
    while (FThreadCount > 0) do
    begin
      // Process messages (which is how the threads synchronize with our thread)
      if PeekMessage(msg, 0, 0, 0, PM_REMOVE) then
      begin
        TranslateMessage(msg);
        DispatchMessage(msg);
      end;
      if (GetTickCount > failsafe + 10000) then
        break;
    end;
  finally
    // Set active state to false
    FInShutDown := False;
    FActive := False;
  end;

end;

////////////////////////////////////////////////////////////////////////////////
//
//   TPipeServerThread
//
////////////////////////////////////////////////////////////////////////////////

constructor TPipeServerThread.Create(PipeServer: TPipeServer; Pipe: HPIPE;
  KillEvent, DataEvent: THandle);
begin

  // Set starting parameters
  FreeOnTerminate := True;
  FPipe := Pipe;
  FPipeServer := PipeServer;
  FNotify := PipeServer.WindowHandle;
  FErrorCode := ERROR_SUCCESS;
  FPendingRead := False;
  FPendingWrite := False;
  FPipeWrite := nil;
  FRcvSize := MIN_BUFFER;
  FRcvBuffer := AllocMem(FRcvSize);
  FRcvStream := TMemoryStream.Create;
  FOlapRead.Offset := 0;
  FOlapRead.OffsetHigh := 0;
  FOlapRead.hEvent := CreateEvent(nil, True, False, nil);
  FOlapWrite.hEvent := CreateEvent(nil, True, False, nil);
  FEvents[0] := KillEvent;
  FEvents[1] := FOlapRead.hEvent;
  FEvents[2] := FOlapWrite.hEvent;
  FEvents[3] := DataEvent;

  // Perform inherited
  inherited Create(False);

end;

destructor TPipeServerThread.Destroy;
begin

  // Free the write buffer we may be holding on to
  if FPendingWrite and Assigned(FPipeWrite) then
    DisposePipeWrite(FPipeWrite);

  // Free the receiver stream and buffer memory
  FreeMem(FRcvBuffer);
  FRcvStream.Free;

  // Perform inherited
  inherited Destroy;

end;

function TPipeServerThread.QueuedRead: Boolean;
var
  bRead: Boolean;
begin

  // Set default result
  result := True;

  // If we already have a pending read then nothing to do
  if not (FPendingRead) then
  begin
    // Set defaults for reading
    FRcvStream.Clear;
    FRcvSize := MIN_BUFFER;
    ReAllocMem(FRcvBuffer, FRcvSize);
    // Keep reading all available data until we get a pending read or a failure
    while result and not (FPendingRead) do
    begin
      // Perform a read
      bRead := ReadFile(FPipe, FRcvBuffer^, FRcvSize, FRcvRead, @FOlapRead);
      // Get the last error code
      FErrorCode := GetLastError;
      // Check the read result
      if bRead then
      begin
        // We read a full message
        FRcvStream.Write(FRcvBuffer^, FRcvRead);
        // Call the OnData
        DoMessage;
      end
      else
      begin
        // Handle cases where message is larger than read buffer used
        if (FErrorCode = ERROR_MORE_DATA) then
        begin
          // Write the current data
          FRcvStream.Write(FRcvBuffer^, FRcvSize);
          // Determine how much we need to expand the buffer to
          if PeekNamedPipe(FPipe, nil, 0, nil, nil, @FRcvSize) then
            ReallocMem(FRcvBuffer, FRcvSize)
          else
          begin
            // Failure
            FErrorCode := GetLastError;
            result := False;
          end;
        end
          // Pending read
        else
          if (FErrorCode = ERROR_IO_PENDING) then
            // Set pending flag
            FPendingRead := True
          else
            // Failure
            result := False;
      end;
    end;
  end;

end;

function TPipeServerThread.CompleteRead: Boolean;
begin

  // Reset the read event and pending flag
  ResetEvent(FOlapRead.hEvent);

  // Check the overlapped results
  result := GetOverlappedResult(FPipe, FOlapRead, FRcvRead, True);

  // Handle failure
  if not (result) then
  begin
    // Get the last error code
    FErrorCode := GetLastError;
    // Check for more data
    if (FErrorCode = ERROR_MORE_DATA) then
    begin
      // Write the current data
      FRcvStream.Write(FRcvBuffer^, FRcvSize);
      // Determine how much we need to expand the buffer to
      result := PeekNamedPipe(FPipe, nil, 0, nil, nil, @FRcvSize);
      if result then
      begin
        // Realloc mem to read in rest of message
        ReallocMem(FRcvBuffer, FRcvSize);
        // Read from the file again
        result := ReadFile(FPipe, FRcvBuffer^, FRcvSize, FRcvRead, @FOlapRead);
        // Handle error
        if not (result) then
        begin
          // Set error code
          FErrorCode := GetLastError;
          // Check for pending again, which means our state hasn't changed
          if (FErrorCode = ERROR_IO_PENDING) then
          begin
            // Bail out and wait for this operation to complete
            result := True;
            exit;
          end;
        end;
      end
      else
        // Set error code
        FErrorCode := GetLastError;
    end;
  end;

  // Handle success
  if result then
  begin
    // We read a full message
    FRcvStream.Write(FRcvBuffer^, FRcvRead);
    // Call the OnData
    DoMessage;
    // Reset the pending read
    FPendingRead := False;
  end;

end;

function TPipeServerThread.QueuedWrite: Boolean;
var
  bWrite: Boolean;
begin

  // Set default result
  result := True;

  // If we already have a pending write then nothing to do
  if not (FPendingWrite) then
  begin
    // Check state of data event
    if (WaitForSingleObject(FEvents[3], 0) = WAIT_OBJECT_0) then
    begin
      // Pull the data from the queue
      SafeSynchronize(DoDequeue);
      // Is the record assigned?
      if Assigned(FPipeWrite) then
      begin
        // Write the data to the client
        bWrite := WriteFile(FPipe, FPipeWrite^.Buffer^, FPipeWrite^.Count,
          FWrite, @FOlapWrite);
        // Get the last error code
        FErrorCode := GetLastError;
        // Check the write operation
        if bWrite then
        begin
          // Call the OnData in the main thread
          PostMessage(FNotify, WM_PIPESEND, FPipe, FWrite);
          // Free the pipe write data
          DisposePipeWrite(FPipeWrite);
          FPipeWrite := nil;
          // Reset the write event
          ResetEvent(FOlapWrite.hEvent);
        end
        else
        begin
          // Only acceptable error is pending
          if (FErrorCode = ERROR_IO_PENDING) then
            // Set pending flag
            FPendingWrite := True
          else
            // Failure
            result := False;
        end;
      end;
    end;
  end;

end;

function TPipeServerThread.CompleteWrite: Boolean;
begin

  // Reset the write event and pending flag
  ResetEvent(FOlapWrite.hEvent);

  // Check the overlapped results
  result := GetOverlappedResult(FPipe, FOlapWrite, FWrite, True);

  // Handle failure
  if not (result) then
    // Get the last error code
    FErrorCode := GetLastError
  else
    // We sent a full message so call the OnSent in the main thread
    PostMessage(FNotify, WM_PIPESEND, FPipe, FWrite);

  // We are done either way. Make sure to free the queued pipe data
  // and to reset the pending flag
  if Assigned(FPipeWrite) then
  begin
    DisposePipeWrite(FPipeWrite);
    FPipeWrite := nil;
  end;
  FPendingWrite := False;

end;

procedure TPipeServerThread.DoDequeue;
begin

  // Get the next queued data event
  FPipeWrite := FPipeServer.Dequeue(FPipe);

end;

procedure TPipeServerThread.DoMessage;
var
  lpmem: DWORD;
  lpmsg: PChar;
begin

  // Convert the memory to global memory and send to pipe server
  lpmem := GlobalAlloc(GHND, FRcvStream.Size);
  lpmsg := GlobalLock(lpmem);

  // Copy from the pipe
  FRcvStream.Position := 0;
  FRcvStream.Read(lpmsg^, FRcvStream.Size);

  // Unlock the memory
  GlobalUnlock(lpmem);

  // Send to the pipe server to manage
  PostMessage(FNotify, WM_PIPEMESSAGE, FPipe, lpmem);

  // Clear the read stream
  FRcvStream.Clear;

end;

procedure TPipeServerThread.Execute;
var
  dwEvents: Integer;
  bOK: Boolean;
begin

  // Notify the pipe server of the connect
  PostMessage(FNotify, WM_PIPECONNECT, FPipe, 0);

  // Loop while not terminated
  while not (Terminated) do
  begin
    // Make sure we always have an outstanding read and write queued up
    bOK := (QueuedRead and QueuedWrite);
    if bOK then
    begin
      // If we are in a pending write then we need will not wait for the
      // DataEvent, because we are already waiting for a write to finish
      dwEvents := 4;
      if FPendingWrite then
        Dec(dwEvents);
      // Handle the event that was signalled (or failure)
      case WaitForMultipleObjects(dwEvents, @FEvents, False, INFINITE) of
        // Killed by pipe server
        WAIT_OBJECT_0: Terminate;
        // Read completed
        WAIT_OBJECT_0 + 1: bOK := CompleteRead;
        // Write completed
        WAIT_OBJECT_0 + 2: bOK := CompleteWrite;
        // Data waiting to be sent
        WAIT_OBJECT_0 + 3: ; // Data available to write
      else
        // General failure
        FErrorCode := GetLastError;
        bOK := False;
      end;
    end;
    // Check status
    if not (bOK) then
    begin
      // Call OnError in the main thread if this is not a disconnect. Disconnects
      // have their own event, and are not to be considered an error
      if (FErrorCode <> ERROR_BROKEN_PIPE) then
        PostMessage(FNotify, WM_PIPEERROR_W, FPipe, FErrorCode);
      // Terminate
      Terminate;
    end;
  end;

  // Disconnect and close the pipe handle at this point. This will kill the
  // overlapped events that may be attempting to access our memory blocks
  // NOTE *** Ensure that the handle is STILL valid, otherwise the ntkernel
  // will raise an exception
  if (FErrorCode <> ERROR_INVALID_HANDLE) then
  begin
    DisconnectNamedPipe(FPipe);
    CloseHandle(FPipe);
  end;

  // Close all open handles that we own
  CloseHandle(FOlapRead.hEvent);
  CloseHandle(FOlapWrite.hEvent);

end;

////////////////////////////////////////////////////////////////////////////////
//
//   TPipeListenThread
//
////////////////////////////////////////////////////////////////////////////////

constructor TPipeListenThread.Create(PipeServer: TPipeServer; KillEvent:
  THandle);
begin

  // Set starting parameters
  FreeOnTerminate := True;
  FPipeName := PipeServer.PipeName;
  FPipeServer := PipeServer;
  FNotify := PipeServer.WindowHandle;
  FEvents[0] := KillEvent;
  InitializeSecurity(FSA);
  FPipe := INVALID_HANDLE_VALUE;
  FConnected := False;
  FOlapConnect.Offset := 0;
  FOlapConnect.OffsetHigh := 0;
  FEvents[1] := CreateEvent(@FSA, True, False, nil);
  ;
  FOlapConnect.hEvent := FEvents[1];

  // Perform inherited
  inherited Create(False);

end;

destructor TPipeListenThread.Destroy;
begin

  // Close the connect event handle
  CloseHandle(FOlapConnect.hEvent);

  // Disconnect and free the handle
  if (FPipe <> INVALID_HANDLE_VALUE) then
  begin
    if FConnected then
      DisconnectNamedPipe(FPipe);
    CloseHandle(FPipe);
  end;

  // Release memory for security structure
  FinalizeSecurity(FSA);

  // Perform inherited
  inherited Destroy;

end;

function TPipeListenThread.CreateServerPipe: Boolean;
const
  OpenMode = PIPE_ACCESS_DUPLEX or FILE_FLAG_OVERLAPPED;
  PipeMode = PIPE_TYPE_MESSAGE or PIPE_READMODE_MESSAGE or PIPE_WAIT;
  Instances = PIPE_UNLIMITED_INSTANCES;
begin

  // Create the outbound pipe first
  FPipe := CreateNamedPipe(PChar('\\.\pipe\' + FPipeName), OpenMode, PipeMode,
    Instances, 0, 0, 1000, @FSA);

  // Set result value based on valid handle
  if (FPipe = INVALID_HANDLE_VALUE) then
    FErrorCode := GetLastError
  else
    FErrorCode := ERROR_SUCCESS;

  // Success if handle is valid
  result := (FPipe <> INVALID_HANDLE_VALUE);

end;

procedure TPipeListenThread.DoWorker;
begin

  // Call the pipe server on the main thread to add a new worker thread
  FPipeServer.AddWorkerThread(FPipe);

end;

procedure TPipeListenThread.Execute;
begin

  // Thread body
  while not (Terminated) do
  begin
    // Set default state
    FConnected := False;
    // Attempt to create first pipe server instance
    if CreateServerPipe then
    begin
      // Connect the named pipe
      FConnected := ConnectNamedPipe(FPipe, @FOlapConnect);
      // Handle failure
      if not (FConnected) then
      begin
        // Check the last error code
        FErrorCode := GetLastError;
        // Is pipe connected?
        if (FErrorCode = ERROR_PIPE_CONNECTED) then
          FConnected := True
            // IO pending?
        else
          if (FErrorCode = ERROR_IO_PENDING) then
          begin
            // Wait for a connect or kill signal
            case WaitForMultipleObjects(2, @FEvents, False, INFINITE) of
              WAIT_FAILED: FErrorCode := GetLastError;
              WAIT_OBJECT_0: Terminate;
              WAIT_OBJECT_0 + 1: FConnected := True;
            end;
          end;
      end;
    end;
    // If we are not connected at this point then we had a failure
    if not (FConnected) then
    begin
      // Client may have connected / disconnected simultaneously, in which
      // case it is not an error. Otherwise, post the error message to the
      // pipe server
      if (FErrorCode <> ERROR_NO_DATA) then
        PostMessage(FNotify, WM_PIPEERROR_L, FPipe, FErrorCode);
      // Close the handle
      CloseHandle(FPipe);
      FPipe := INVALID_HANDLE_VALUE;
    end
    else
      // Notify server of connect
      SafeSynchronize(DoWorker);
  end;

end;

////////////////////////////////////////////////////////////////////////////////
//
//   TPipeThread
//
////////////////////////////////////////////////////////////////////////////////

procedure TPipeThread.SafeSynchronize(Method: TThreadMethod);
begin

  // Exception trap
  try
    // Call
    Synchronize(Method);
  except
    // Trap and eat the exception, just call terminate on the thread
    Terminate;
  end;

end;

////////////////////////////////////////////////////////////////////////////////
//
//   TWriteQueue
//
////////////////////////////////////////////////////////////////////////////////

constructor TWriteQueue.Create;
begin

  // Perform inherited
  inherited Create;

  // Starting values
  FCount := 0;
  FHead := nil;
  FTail := nil;
  FDataEv := CreateEvent(nil, True, False, nil);

end;

destructor TWriteQueue.Destroy;
begin

  // Clear
  Clear;

  // Close the data event handle
  CloseHandle(FDataEv);

  // Perform inherited
  inherited Destroy;

end;

procedure TWriteQueue.Clear;
var
  node: PWriteNode;
begin

  // Reset the writer event
  ResetEvent(FDataEv);

  // Free all the items in the stack
  while Assigned(FHead) do
  begin
    // Get the head node and push forward
    node := FHead;
    FHead := FHead^.NextNode;
    // Free the pipe write data
    DisposePipeWrite(node^.PipeWrite);
    // Free the queued node
    FreeMem(node);
  end;

  // Set the tail to nil
  FTail := nil;

  // Reset the count
  FCount := 0;

end;

function TWriteQueue.NewNode(PipeWrite: PPipeWrite): PWriteNode;
begin

  // Allocate memory for new node
  result := AllocMem(SizeOf(TWriteNode));

  // Set the structure fields
  result^.PipeWrite := PipeWrite;
  result^.NextNode := nil;

  // Increment the count
  Inc(FCount);

end;

procedure TWriteQueue.Enqueue(PipeWrite: PPipeWrite);
var
  node: PWriteNode;
begin

  // Create a new node
  node := NewNode(PipeWrite);

  // Make this the last item in the queue
  if (FTail = nil) then
    FHead := node
  else
    FTail^.NextNode := node;

  // Update the new tail
  FTail := node;

  // Set the write event to signalled
  SetEvent(FDataEv);

end;

function TWriteQueue.Dequeue: PPipeWrite;
var
  node: PWriteNode;
begin

  // Remove the first item from the queue
  if not (Assigned(FHead)) then
    result := nil
  else
  begin
    // Set the return data
    result := FHead^.PipeWrite;
    // Move to next node, update head (possibly tail), then free node
    node := FHead;
    if (FHead = FTail) then
      FTail := nil;
    FHead := FHead^.NextNode;
    // Free the memory for the node
    FreeMem(node);
    Dec(FCount);
  end;

  // Reset the write event if no more data records to write
  if (FCount = 0) then
    ResetEvent(FDataEv);

end;

////////////////////////////////////////////////////////////////////////////////
//
//   Utility functions
//
////////////////////////////////////////////////////////////////////////////////

function AllocPipeWrite(const Buffer; Count: Integer): PPipeWrite;
begin

  // Allocate memory for the result
  result := AllocMem(SizeOf(TPipeWrite));

  // Set the count of the buffer
  result^.Count := Count;

  // Allocate enough memory to store the data buffer, then copy the data over
  result^.Buffer := AllocMem(Count);
  System.Move(Buffer, result^.Buffer^, Count);

end;

procedure DisposePipeWrite(PipeWrite: PPipeWrite);
begin

  // Dispose of the memory being used by the pipe write structure
  if Assigned(PipeWrite^.Buffer) then
    FreeMem(PipeWrite^.Buffer);

  // Free the memory record
  FreeMem(PipeWrite);

end;

procedure CheckPipeName(Value: string);
begin

  // Validate the pipe name
  if (Pos('\', Value) > 0) or
    (Length(Value) > 63) or
    (Length(Value) = 0) then
  begin
    raise EPipeException.CreateRes(@resBadPipeName);
  end;

end;

procedure InitializeSecurity(var SA: TSecurityAttributes);
var
  sd: PSecurityDescriptor;
begin

  // Allocate memory for the security descriptor
  sd := AllocMem(SECURITY_DESCRIPTOR_MIN_LENGTH);

  // Initialise the new security descriptor
  InitializeSecurityDescriptor(sd, SECURITY_DESCRIPTOR_REVISION);

  // Add a NULL descriptor ACL to the security descriptor
  SetSecurityDescriptorDacl(sd, True, nil, False);

  // Set up the security attributes structure
  with SA do
  begin
    nLength := SizeOf(TSecurityAttributes);
    lpSecurityDescriptor := sd;
    bInheritHandle := True;
  end;

end;

procedure FinalizeSecurity(var SA: TSecurityAttributes);
begin

  // Release memory that was assigned to security descriptor
  if Assigned(SA.lpSecurityDescriptor) then
  begin
    FreeMem(SA.lpSecurityDescriptor);
    SA.lpSecurityDescriptor := nil;
  end;

end;

end.

