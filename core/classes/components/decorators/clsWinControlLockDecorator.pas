unit clsWinControlLockDecorator;

interface
uses
  forms,
  graphics,
  controls,
  classes,
  messages,
  windows,
  sysUtils,
  math,
  imgList,
  generics.collections,


  clsResources,
  clsApplication,
  clsMulticastEvents;

type
  cWinControlLockDecorator = class
  private
    const

    IMAGE_LIST_ICON_WIDTH = 16;
    IMAGE_LIST_ICON_HEIGHT = 16;

    LOCK_ICON_INDEX = 0;
  private
    class var
    fOldWndProcMap  : tDictionary<hWnd,pointer>;
    fControl        : TWinControl;
    fImageList      : tImageList;
    fFrameColor     : tColor;
    fLinesColor     : tColor;

    class procedure   loadIcons;
    class function    wndProc(aHandle: hWnd; aMsg, aWParam, aLParam: longInt): longInt; stdcall; static;


    class constructor create;
    class destructor  destroy;

    class procedure   unlockControl(aHwnd: hWnd); overload;
  public
    procedure   setControl(aControl: tWinControl);
    procedure   setLinesColor(aColor: tColor);
    procedure   setFrameColor(aColor: tColor);

    procedure   lockControl;
    procedure   unlockControl; overload;

    constructor create;
    destructor  destroy; override;
  end;

implementation

{$R resources\winControlLockDecorator.res}

{ cWinControlLockDecorator }

class constructor cWinControlLockDecorator.create;
begin
  fLinesColor:= clSilver;
  fFrameColor:= clGray;

  fOldWndProcMap:= tDictionary<hWnd,pointer>.create;
  fImageList:= tImageList.create(nil);

  fImagelist.colorDepth:= cd32Bit;
  fImagelist.imageType:= itImage;
  fImagelist.drawingStyle:= dsTransparent;

  fImageList.width:= cWinControlLockDecorator.IMAGE_LIST_ICON_WIDTH;
  fImageList.height:= cWinControlLockDecorator.IMAGE_LIST_ICON_HEIGHT;

  loadIcons;
end;

constructor cWinControlLockDecorator.create;
begin
  inherited create;
end;

destructor cWinControlLockDecorator.destroy;
var
  curPair: tPair<hWnd,pointer>;
begin
  if assigned(fOldWndProcMap) then begin
    for curPair in fOldWndProcMap do begin
      setWindowLong(curPair.key, GWL_WNDPROC, integer(curPair.value));
    end;
  end;

  inherited;
end;

class procedure cWinControlLockDecorator.loadIcons;
var
  res: tResourceStream;
  icon: tIcon;
begin
  res:= tResourceStream.create(hInstance, repositoryResources.WINCONTROL_LOCK_DECORATOR_LOCK_RESOURCE, repositoryResources.RESOURCES_SECTION);
  try
    icon:= tIcon.create;
    try
      icon.loadFromStream(res);

      fImageList.addIcon(icon);
    finally
      freeAndNil(icon);
    end;
  finally
    freeAndNil(res);
  end;
end;

procedure cWinControlLockDecorator.lockControl;
begin
  if fOldWndProcMap.containsKey(fControl.handle) then exit;

  fOldWndProcMap.add(fControl.handle, pointer(setWindowLong(fControl.handle, GWL_WNDPROC, integer(@cWinControlLockDecorator.wndProc))));

  setWindowLong(fControl.handle, GWL_STYLE, getWindowLong(fControl.handle, GWL_STYLE) and not WS_BORDER and not WS_SIZEBOX and not WS_DLGFRAME );
  setWindowPos(fControl.handle, HWND_NOTOPMOST, fControl.left, fControl.top, fControl.width, fControl.height, SWP_SHOWWINDOW);

  fControl.invalidate;
end;

class destructor cWinControlLockDecorator.destroy;
begin
  if assigned(fOldWndProcMap) then begin
    freeAndNil(fOldWndProcMap);
  end;

  if assigned(fImageList) then begin
    freeAndNil(fImageList);
  end;
end;

procedure cWinControlLockDecorator.setControl(aControl: tWinControl);
begin
  fControl:= aControl;
end;

procedure cWinControlLockDecorator.setFrameColor(aColor: tColor);
begin
  fFrameColor:= aColor;
end;

procedure cWinControlLockDecorator.setLinesColor(aColor: tColor);
begin
  fLinesColor:= aColor;
end;

class procedure cWinControlLockDecorator.unlockControl(aHwnd: hWnd);
begin
  if fOldWndProcMap.containsKey(aHwnd) then begin
    setWindowLong(aHwnd, GWL_WNDPROC, integer(fOldWndProcMap.items[aHwnd]));

    fOldWndProcMap.remove(aHwnd);
  end;
end;

procedure cWinControlLockDecorator.unlockControl;
begin
  unlockControl(fControl.handle);
end;

class function cWinControlLockDecorator.wndProc(aHandle: hWnd; aMsg, aWParam, aLParam: longInt): longInt;
  procedure paintRect(aWndHandle: HWND);
  var
    cnvs: tCanvas;
    wndRect: tRect;
    dc: HDC;
    paintStruct: tPaintStruct;
  begin
    getWindowRect(aWndHandle, wndRect);

    offsetRect(wndRect, -wndRect.left, -wndRect.top);

    dc:= beginPaint(aWndHandle, paintStruct);
    try
      dc:= getWindowDC(aWndHandle);

      cnvs:= tCanvas.create;
      try
        cnvs.handle:= dc;

        cnvs.pen.style:= psSolid;
        cnvs.pen.color:= fFrameColor;

        cnvs.brush.color:= clWindow;
        cnvs.rectangle(wndRect);

        cnvs.brush.color:= fLinesColor;

        cnvs.brush.style:= bsFDiagonal;

        cnvs.rectangle(wndRect);

        fImageList.draw(cnvs, (wndRect.right - fImageList.width) div 2 , (wndRect.bottom - fImageList.height) div 2, cWinControlLockDecorator.LOCK_ICON_INDEX);

      finally
        freeAndNil(cnvs);
      end;
    finally
      endPaint(aWndHandle, paintStruct);
    end;
  end;
begin
  case aMsg of
    WM_PAINT: begin
      paintRect(aHandle);
    end;

    WM_DESTROY, WM_NCDESTROY: begin
      if fOldWndProcMap.containsKey(aHandle) then begin
        callWindowProc(fOldWndProcMap.items[aHandle], aHandle, aMsg, aWParam, aLParam);

        unlockControl(aHandle);
      end;
    end;

  end;
end;

end.
