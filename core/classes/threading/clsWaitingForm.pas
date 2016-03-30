unit clsWaitingForm;

interface

uses
  windows,
  sysUtils,
  classes,
  graphics,
  controls,
  messages,
  syncObjs,
  commCtrl,
  types,

  GIFImg,

  uMetrics,

  clsException,
  clsTimer;

type
  tImageLayout = (ilImageTop, ilImageLeft, ilImageBottom, ilImageRight);

  eThreadedWaitingForm = class(exception);

  cThreadedWaitingForm = class(tThread)
  private
    const

    THREAD_WAIT_TIMEOUT_MESSAGE = 'thread wait timeout';

    THREAD_WAIT_TIMEOUT = 5 * SECOND;
  private
    fCS             : tCriticalSection;

    fHWnd           : HWND;

    //window proc stub for the splash screen
    fWNDProcStub    : pointer;
    fWndClass       : ATOM;

    fCanvas         : tCanvas;
    fImage          : tGIFImage;

    // upper left position of splash window
    fOrigin         : tPoint;

    fCentered       : boolean;
    fTopmost        : boolean;
    fImageLayout    : tImageLayout;
    fInternalGap    : integer;
    fBorderMargin   : integer;
    fColor          : tColor;
    fImageStream    : tMemoryStream;
    fMessage        : string;
    fWidth          : integer;
    fHeight         : integer;
    fCaption        : string;
    fVisible        : boolean;

    fCurrentFrame   : integer;
  private
    //messages
    procedure   WMPaint(var aMessage: tWMPaint); message WM_PAINT;
    procedure   WMCreate(var aMessage: tWMCreate); message WM_CREATE;

    procedure   wndProc(var aMessage: tMessage);

  private

    procedure   createWindowClass;
    procedure   destroyWindowClass;

    procedure   createWindow;
    procedure   centerWindow;

    procedure   applyDefaults;

    procedure   paintImage(aCanvas: tCanvas);
    procedure   paintMessage(aCanvas: tCanvas);

    procedure   defaultHandler(var aMessage); override;

    function    getClientRect: tRect;
    function    getOriginalClientRect: tRect;
    function    getImageRect: tRect;
    function    getMessageRect: tRect;

    procedure   execute; override;

    //
    procedure   invalidateImage(aTimer: cTimer);
    procedure   nextFrame;

    function    getWindowClassName: string;

    constructor create;
    destructor  destroy; override;
  public
    function    isCentered: boolean;
    function    isVisible: boolean;
    function    isTopMost: boolean;
    function    getImageLayout: tImageLayout;
    function    getInternalGap: integer;
    function    getBorderMargin: integer;
    function    getColor: tColor;
    function    getImageStream: tStream;
    function    getMessage: string;
    function    getWidth: integer;
    function    getHeight: integer;
    function    getCaption: string;


    procedure   setCentered(aValue: boolean);
    procedure   setTopmost(aValue: boolean);
    procedure   setImageLayout(aLayout: tImageLayout);
    procedure   setVisible(aValue: boolean);

    procedure   setInternalGap(aGap: integer);
    procedure   setBorderMargin(aMargin: integer);

    procedure   setColor(aColor: tColor);


    procedure   setImageStream(aStream: tStream);
    procedure   setMessage(aMessage: string);
    procedure   setWidth(aWidth: integer);
    procedure   setHeight(aHeight: integer);

    procedure   setCaption(aCaption: string);

  end;

  cWaitingForm = class
  strict private
    class var
      fThreadedForm : cThreadedWaitingForm;
      fCS           : tCriticalSection;
  public
    class constructor create;
    class destructor  destroy;
  published
    class procedure   show(aCaption: string; aMessage: string; aImageLayout: tImageLayout = ilImageTop; aColor: tColor = clBtnFace);
    class procedure   hide;
    class function    isShowing: boolean;
    class procedure   break;
    class procedure   continue;
  end;

implementation
uses
  clsLog,
  clsResources;

{$R resources\loading.res}

function createWndProc( wnd: HWND; msg: cardinal; wparam: WPARAM; lparam: LPARAM ): LRESULT; stdcall;
var
  thread: cThreadedWaitingForm;
begin
  if msg = WM_NCCREATE then begin
    thread := cThreadedWaitingForm( pCreateStruct( lParam )^.lpCreateParams );
    thread.fHWnd := wnd;
    setWindowLong( wnd, GWL_WNDPROC, integer( thread.fWNDProcStub ));
    result := 1;
  end else // will actually never get here, but better safe than sorry
    result := defWindowProc( wnd, msg, wParam, lParam );
end;

procedure cThreadedWaitingForm.centerWindow;
var
  r, workArea: tRect;
  x, y: integer;
begin
  win32Check( getWindowRect( fHWnd, r ));
  systemParametersInfo( SPI_GETWORKAREA, sizeof( workArea ), @workArea, 0 );
  x:= ((workArea.right - workArea.left) - (r.right - r.left )) div 2;
  y:= ((workArea.bottom - workArea.top) - (r.bottom - r.top )) div 2;

  setWindowPos( fHWnd, 0, x, y, 0, 0, SWP_NOSIZE or SWP_NOZORDER );
end;

constructor cThreadedWaitingForm.create;
begin
  fCS:= tCriticalSection.create;

  fVisible:= true;
  fCurrentFrame:= -1;
  fCanvas:= nil;
  fImage:= nil;
  fWNDProcStub:= makeObjectInstance( wndProc );

  fImageStream:= tMemoryStream.create;

  applyDefaults;

  inherited create(false);
end;

procedure cThreadedWaitingForm.createWindow;
const
  TOPMOST_STYLE: array [boolean] of dWORD = (0, WS_EX_TOPMOST );
  NO_ACTIVATE_STYLE : array [boolean] of dWORD = (0, WS_EX_NOACTIVATE );
var
  wSize: tSize;
begin
  wSize.cx := getWidth + getSystemMetrics( SM_CXEDGE ) * 2;
  wSize.cy := getHeight + getSystemMetrics( SM_CYEDGE ) * 2;


  fHWnd := createWindowEx(
            TOPMOST_STYLE[fTopmost] or WS_EX_TOOLWINDOW or NO_ACTIVATE_STYLE[win32MajorVersion >= 5],
            pChar(getWindowClassName),
            nil,
            WS_CAPTION,
            fOrigin.x, fOrigin.y,
            wSize.cx, wSize.cy,
            0, 0, hInstance, self
          );

  if (fHWnd = 0) then begin
    raise eThreadedWaitingForm.create('createWindow: createWindowEx failed');
  end;

  setCaption(getCaption);
end;

function cThreadedWaitingForm.getWindowClassName: string;
begin
  result:= format('%s_wnd_%x', [className, getCurrentThreadId])
end;

procedure cThreadedWaitingForm.createWindowClass;
var
  wnd—lass: tWndClassEx;
begin
  fillChar(wnd—lass, sizeOf(wnd—lass), 0);

  wnd—lass.cbSize         := sizeOf(wnd—lass);
  wnd—lass.style          := CS_VREDRAW or CS_HREDRAW;
  wnd—lass.lpfnWndProc    := @createWndProc;
  wnd—lass.cbClsExtra     := 0;
  wnd—lass.cbWndExtra     := 0;
  wnd—lass.hInstance      := hInstance;
  wnd—lass.hIcon          := 0;
  wnd—lass.hCursor        := loadCursor(0, IDC_WAIT);
  wnd—lass.hbrBackground  := HBRUSH(GetStockObject(WHITE_BRUSH));
  wnd—lass.lpszMenuName   := nil;
  wnd—lass.lpszClassName  := pChar(getWindowClassName);

  fWndClass               := windows.registerClassEx(wnd—lass);

  if (fWndClass = 0) then begin
    raiseLastOSError;
  end;
end;

procedure cThreadedWaitingForm.defaultHandler(var aMessage);
begin
  with tMessage(aMessage) do begin
    result := defWindowProc( fHWnd, msg, wParam, lParam );
  end;
end;

destructor cThreadedWaitingForm.destroy;
begin
  terminate;

  if (fHWnd <> 0) then begin
    postMessage(fHWnd, WM_CLOSE, 0, 0 );
  end;

  if (waitForSingleObject(handle, INFINITE) = WAIT_TIMEOUT) then begin
    cLog.getInstance.write(self, THREAD_WAIT_TIMEOUT_MESSAGE, ltError);
  end;

  freeObjectInstance(fWNDProcStub);

  destroyWindowClass;

  if (assigned(fImageStream)) then begin
    freeAndNil(fImageStream);
  end;

  if (assigned(fCS)) then begin
    freeAndNil(fCS);
  end;

  inherited;
end;

procedure cThreadedWaitingForm.destroyWindowClass;
begin
  if (fWndClass <> 0) then begin
    windows.unregisterClass(makeIntResource(fWndClass), hInstance);
  end;
end;

procedure cThreadedWaitingForm.execute;
var
  msg: tMsg;

  timer: cTimer;
begin

  peekMessage(msg, 0, 0, 0, PM_NOREMOVE );
  try

    fCanvas:= tCanvas.create;
    try

      createWindowClass;
      createWindow;

      setVisible(isVisible);


      fImage:= tGIFImage.create;
      try

        fImage.loadFromStream(fImageStream);

        timer:= cTimer.create(fImage.animationSpeed);
        try
          timer.onTick:= invalidateImage;
          timer.start;

          //message loop
          while (windows.getMessage(msg, 0, 0, 0 )) do begin
            if (terminated) then break;

            windows.translateMessage(msg);
            windows.dispatchMessage(msg);
          end;
          //

          timer.stop;
        finally
          freeAndNil(timer);
        end;

      finally
        freeAndNil(fImage);
      end;

    finally
      freeAndNil(fCanvas);
    end;

  except
    on e: exception do begin
      raise;
    end;
  end;
end;

function cThreadedWaitingForm.getBorderMargin: integer;
begin
  fCS.enter;
  try
    result:= fBorderMargin;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.getCaption: string;
begin
  fCS.enter;
  try
    result:= fCaption;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.getClientRect: tRect;
var
  borderMargin: integer;
begin
  result:= getOriginalClientRect;
  borderMargin:= getBorderMargin;
  inflateRect(result, -borderMargin, -borderMargin);
end;

function cThreadedWaitingForm.getColor: tColor;
begin
  fCS.enter;
  try
    result:= fColor;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.getHeight: integer;
begin
  fCS.enter;
  try
    result:= fHeight;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.getImageLayout: tImageLayout;
begin
  fCS.enter;
  try
    result:= fImageLayout;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.getImageRect: tRect;
var
  adjustRect: tRect;
begin
  result:= getClientRect;
  adjustRect:= rect(0, 0, fImage.width, fImage.height);

  case fImageLayout of
    ilImageTop    : begin
      result.bottom:= result.top + fImage.height;
    end;

    ilImageLeft   : begin
      result.right:= result.left + fImage.width;
    end;

    ilImageBottom : begin
      result.top:= result.bottom - fImage.height;
    end;

    ilImageRight  : begin
      result.left:= result.right - fImage.width;
    end;
  end;


  result:= centeredRect(result, adjustRect);
end;

function cThreadedWaitingForm.getImageStream: tStream;
begin
  fCS.enter;
  try
    result:= fImageStream;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.getInternalGap: integer;
begin
  fCS.enter;
  try
    result:= fInternalGap;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.getMessage: string;
begin
  fCS.enter;
  try
    result:= fMessage;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.getMessageRect: tRect;
var
  internalGap: integer;
begin
  internalGap:= getInternalGap;

  result:= getClientRect;

  case fImageLayout of
    ilImageTop    : begin
      result.top:= result.top + fImage.height + internalGap;
    end;

    ilImageLeft   : begin
      result.left:= result.left + fImage.width + internalGap;
    end;

    ilImageBottom : begin
      result.bottom:= result.bottom - fImage.height - internalGap;
    end;

    ilImageRight  : begin
      result.right:= result.right - fImage.width - internalGap;
    end;
  end;
end;

function cThreadedWaitingForm.getOriginalClientRect: tRect;
begin
  windows.getClientRect(fHWnd, result);
end;

function cThreadedWaitingForm.getWidth: integer;
begin
  fCS.enter;
  try
    result:= fWidth;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.applyDefaults;
begin
  setImageLayout(ilImageTop);
  setWidth(200);
  setHeight(100);

  setInternalGap(5);
  setBorderMargin(5);

  setCaption('');
  setMessage('');

  setCentered(true);
  setTopmost(true);

  setColor(clBtnFace);
end;

procedure cThreadedWaitingForm.invalidateImage(aTimer: cTimer);
var
  invRect: tRect;
begin
  if terminated then exit;

  invRect:= getImageRect;
  invalidateRect(fHWnd, @invRect, false);
end;

function cThreadedWaitingForm.isCentered: boolean;
begin
  fCS.enter;
  try
    result:= fCentered;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.isTopMost: boolean;
begin
  fCS.enter;
  try
    result:= fTopmost;
  finally
    fCS.leave;
  end;
end;

function cThreadedWaitingForm.isVisible: boolean;
begin
  fCS.enter;
  try
    result:= fVisible;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.paintMessage(aCanvas: tCanvas);
var
  messageRect: tRect;
begin
  messageRect:= getMessageRect;
  windows.drawText(
    aCanvas.handle,
    getMessage,
    -1,
    messageRect,
    DT_SINGLELINE or DT_WORD_ELLIPSIS or DT_CENTER or DT_VCENTER
  );
end;

procedure cThreadedWaitingForm.nextFrame;
begin
  if (fCurrentFrame = fImage.images.count - 1) then begin
    fCurrentFrame:= -1;
  end;

  inc(fCurrentFrame);
end;

procedure cThreadedWaitingForm.paintImage(aCanvas: tCanvas);
var
  drawingBitmap: tBitmap;

begin
  nextFrame;

  drawingBitmap:= fImage.images[fCurrentFrame].bitmap;
  drawingBitmap.transparent:= true;

  drawingBitmap.canvas.lock;
  try
    aCanvas.draw(getImageRect.left, getImageRect.top, drawingBitmap);
  finally
    drawingBitmap.canvas.unlock;
  end;
end;

procedure cThreadedWaitingForm.setBorderMargin(aMargin: integer);
begin
  fCS.enter;
  try
    fBorderMargin:= aMargin;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setCaption(aCaption: string);
begin
  fCS.enter;
  try
    fCaption:= aCaption;

    if (fHWnd <> 0) then begin
      windows.setWindowText(fHWnd, fCaption);
    end;

  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setCentered(aValue: boolean);
begin
  fCS.enter;
  try
    fCentered:= aValue;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setColor(aColor: tColor);
begin
  fCS.enter;
  try
    fColor:= aColor;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setHeight(aHeight: integer);
begin
  fCS.enter;
  try
    fHeight:= aHeight;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setImageLayout(aLayout: tImageLayout);
begin
  fCS.enter;
  try
    fImageLayout:= aLayout;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setImageStream(aStream: tStream);
begin
  fCS.enter;
  try
    fImageStream.loadFromStream(aStream);
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setInternalGap(aGap: integer);
begin
  fCS.enter;
  try
    fInternalGap:= aGap;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setMessage(aMessage: string);
begin
  fCS.enter;
  try
    fMessage:= aMessage;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setTopmost(aValue: boolean);
begin
  fCS.enter;
  try
    fTopmost:= aValue;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.setVisible(aValue: boolean);
begin
  fVisible:= aValue;



  if (fVisible) then begin
   showWindow(fHWnd, SW_SHOWNA);
  end else begin
    showWindow(fHWnd, SW_HIDE);
  end;
end;

procedure cThreadedWaitingForm.setWidth(aWidth: integer);
begin
  fCS.enter;
  try
    fWidth:= aWidth;
  finally
    fCS.leave;
  end;
end;

procedure cThreadedWaitingForm.wndProc(var aMessage: tMessage);
begin
  try
    aMessage.result := 0;

    case aMessage.msg Of
      WM_ERASEBKGND   : begin
      end;

      WM_SYSCOMMAND   : begin
      end;

      WM_CLOSE        : begin
        destroyWindow(fHWnd);
      end;

      WM_DESTROY      : begin
        postQuitMessage(0);
      end;

      WM_NCDESTROY    : begin
        fHWnd := 0;
      end

    else
      dispatch(aMessage);
    end;

  except
    on e: exception do begin
      raise;
    end;
  end;
end;

procedure cThreadedWaitingForm.WMCreate(var aMessage: tWMCreate);
begin
  aMessage.result := 1;
  if (isCentered) then begin
    centerWindow;
  end;
end;

procedure cThreadedWaitingForm.WMPaint(var aMessage: tWMPaint);
var
  paintStruct: tPaintStruct;
begin

  fCanvas.handle:= beginPaint(fHWnd, paintStruct);
  try
    with fCanvas do begin
      brush.color:= clWhite;
      pen.color:= clWhite;

      rectangle(getOriginalClientRect);

      paintImage(fCanvas);
      paintMessage(fCanvas);
    end;

  finally
    endPaint(fHWnd, paintStruct);
  end;
end;

{ cWaitingForm }

class procedure cWaitingForm.break;
begin
  if not isShowing then exit;

  //it just message, so do it without blocking
  fThreadedForm.setVisible(false);
end;

class procedure cWaitingForm.continue;
begin
  if not isShowing then exit;

  //it just message, so do it without blocking
  fThreadedForm.setVisible(true);
end;

class constructor cWaitingForm.create;
begin
  fThreadedForm:= nil;
  fCS:= tCriticalSection.create;
end;

class destructor cWaitingForm.destroy;
begin
  if (assigned(fCS)) then begin
    freeAndNil(fCS);
  end;
end;

class procedure cWaitingForm.hide;
begin
  fCS.enter;
  try
    if assigned(fThreadedForm) then begin
      freeAndNil(fThreadedForm);
    end;
  finally
    fCS.leave;
  end;
end;

class function cWaitingForm.isShowing: boolean;
begin
  result:= assigned(fThreadedForm);
end;

class procedure cWaitingForm.show(aCaption, aMessage: string; aImageLayout: tImageLayout; aColor: tColor);
var
  res: tResourceStream;
begin
  fCS.enter;
  try
    if (isShowing) then exit;

    res:= tResourceStream.create(hInstance, repositoryResources.LOADING_RESOURCE, repositoryResources.RESOURCES_SECTION);
    try
      fThreadedForm:= cThreadedWaitingForm.create;

      fThreadedForm.setColor(aColor);
      fThreadedForm.setImageLayout(aImageLayout);
      fThreadedForm.setCaption(aCaption);
      fThreadedForm.setMessage(aMessage);

      fThreadedForm.setImageStream(res);
    finally
      freeAndNil(res);
    end;


  finally
    fCS.leave;
  end;
end;

end.
