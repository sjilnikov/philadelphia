unit clsIncSearchDecorator;

interface
uses
  windows,
  graphics,
  classes,
  sysUtils,

  uMetrics,

  clsStringUtils,
  clsMulticastEvents,
  clsAbstractViewProxy,
  clsTime,
  clsTimer;

type

  cIncSearchDecorator = class
  private
    fTimer               : cTimer;
    fViewProxy           : cAbstractViewProxy;
    fColor               : tColor;
    fFontColor           : tColor;
    fFrameColor          : tColor;
    fSearchTime          : cTime;
    fSearchTimerInterval : cardinal;
    fSearchDirection     : tViewSearchDirection;
    fActive              : boolean;

    fSearchText          : string;

    function    isActive: boolean;
    procedure   updateActive;

    procedure   setupEvents;
    procedure   disconnectEvents;

    procedure   setupViewProxyEvents;
    procedure   disconnectViewProxyEvents;

    function    locateViewProxy(aText: string; aSearchDirection: tViewSearchDirection; aSearchPosition: tViewSearchPosition): boolean;

    procedure   incSearch(aKey: char);
    procedure   drawIncSearch(aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment);
  public
    procedure   setSearchDirection(aDirection: tViewSearchDirection);
    function    getSearchDirection: tViewSearchDirection;

    procedure   setColor(aColor: tColor);
    procedure   setFrameColor(aColor: tColor);
    procedure   setFontColor(aColor: tColor);

    procedure   setSearchInterval(aValue: integer);
    function    getSearchInterval: integer;

    procedure   setViewProxy(aViewProxy: cAbstractViewProxy);
    function    getViewProxy: cAbstractViewProxy;

    constructor create;
    destructor  destroy; override;
  public
    const

    DEFAULT_SEARCH_TIMER_INTERVAL = 3 * SECOND;
  published
    //SLOTS
    procedure   searchTimerTick(aTimer: cTimer);
    procedure   viewProxyKeyPress(aSender: tObject; var aKey: char);
    procedure   viewProxyKeyDown(aSender: tObject; var aKey: word; aShift: tShiftState);
    procedure   viewProxySelectedItemPainted(aSender: cAbstractViewProxy; aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment);
  published

    property    viewProxy: cAbstractViewProxy read getViewProxy write setViewProxy;
  end;


implementation

{ cIncSearchDecorator }

constructor cIncSearchDecorator.create;
begin
  inherited create;

  fSearchTime:= cTime.create;

  fTimer:= cTimer.create(DEFAULT_SEARCH_TIMER_INTERVAL);
  fTimer.start;

  setSearchDirection(sdForward);
  setColor(clYellow);
  setFontColor(clBlack);
  setFrameColor(clSilver);

  setSearchInterval(DEFAULT_SEARCH_TIMER_INTERVAL);

  setupEvents;
  setupViewProxyEvents;
end;

destructor cIncSearchDecorator.destroy;
begin
  disconnectEvents;
  disconnectViewProxyEvents;


  if assigned(fSearchTime) then begin
    freeAndNil(fSearchTime);
  end;

  if assigned(fTimer) then begin
    freeAndNil(fTimer);
  end;

  inherited;
end;

procedure cIncSearchDecorator.disconnectEvents;
begin
  disconnect(fTimer);
end;

procedure cIncSearchDecorator.disconnectViewProxyEvents;
begin
  if not assigned(fViewProxy) then begin
    exit;
  end;

  disconnect(fViewProxy, 'onKeyPress', self, 'viewProxyKeyPress');
  disconnect(fViewProxy, 'onKeyDown', self, 'viewProxyKeyDown');
  disconnect(fViewProxy, 'onSelectedItemPainted', self, 'viewProxySelectedItemPainted');
end;

procedure cIncSearchDecorator.drawIncSearch(aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment);
var
  incSearchRect: tRect;

  roundRect: tRect;
  textWidth: integer;
  textHeight: integer;
begin
  if (fSearchText = '') then begin
    exit;
  end;

  incSearchRect:= aRect;
  inflateRect(incSearchRect, -2, -2);

  textWidth:= aCanvas.textWidth(fSearchText);
  textHeight:= aCanvas.textHeight(fSearchText);

  case aHAlign of
    taLeftJustify : incSearchRect.right:= incSearchRect.left + textWidth;
    taRightJustify: incSearchRect.left:= incSearchRect.right - textWidth;
    taCenter      :
    begin
      incSearchRect.left:= (aRect.right + aRect.left - textWidth) div 2;
      incSearchRect.right:= incSearchRect.left + textWidth;
    end;
  end;

  case aVAlign of
    taAlignTop      : incSearchRect.bottom:= incSearchRect.top + textHeight;
    taAlignBottom   : incSearchRect.top:= incSearchRect.bottom - textHeight;
    taVerticalCenter:
    begin
      incSearchRect.top:= (aRect.bottom + aRect.top - textHeight) div 2;
      incSearchRect.bottom:= incSearchRect.top + textHeight;
    end;
  end;

  roundRect:= incSearchRect;
  inflateRect(roundRect, 2, 1);

  aCanvas.pen.color:= fFrameColor;
  aCanvas.brush.color:= fColor;
  aCanvas.roundRect(roundRect, 5, 5);

  aCanvas.font.color:= fFontColor;
  aCanvas.textRect(incSearchRect, fSearchText);
end;

function cIncSearchDecorator.getSearchDirection: tViewSearchDirection;
begin
  result:= fSearchDirection;
end;

function cIncSearchDecorator.getSearchInterval: integer;
begin
  result:= fSearchTimerInterval;
end;

function cIncSearchDecorator.getViewProxy: cAbstractViewProxy;
begin
  result:= fViewProxy;
end;

procedure cIncSearchDecorator.incSearch(aKey: char);
const
  BACKSPACE_KEY_CODE = #8;
  RETURN_KEY_CODE = #13;
var
  returnPressed: boolean;
  backspacePressed: boolean;
  normalKeyPressed: boolean;
begin
  returnPressed:= false;
  backspacePressed:= false;
  normalKeyPressed:= false;
  fActive:= true;

  case aKey of
    BACKSPACE_KEY_CODE  : backspacePressed:= true;
    RETURN_KEY_CODE     : returnPressed:= true;
    else begin
      normalKeyPressed:= true;
    end;
  end;


  if backspacePressed then begin
    cStringUtils.deleteLastChar(fSearchText);
    updateActive;

    locateViewProxy(fSearchText, fSearchDirection, spFirst);

    exit;
  end;

  if returnPressed then begin
//    locateViewProxy(fSearchText, fSearchDirection, spNextFromCurrent);

    exit;
  end;

  if normalKeyPressed then begin
    fSearchText:= fSearchText + aKey;
    updateActive;

    if not (locateViewProxy(fSearchText, fSearchDirection, spFirst)) then begin
      cStringUtils.deleteLastChar(fSearchText);
    end;
  end;

end;

function cIncSearchDecorator.isActive: boolean;
begin
  result:= fActive;
end;

function cIncSearchDecorator.locateViewProxy(aText: string; aSearchDirection: tViewSearchDirection; aSearchPosition: tViewSearchPosition): boolean;
begin
  result:= false;
  if not assigned(fViewProxy) then begin
    exit;
  end;

  fSearchTime.start;

  result:= fViewProxy.locate(aText, aSearchDirection, aSearchPosition, stPartial);
  fViewProxy.invalidate;
end;

procedure cIncSearchDecorator.viewProxySelectedItemPainted(aSender: cAbstractViewProxy; aCanvas: tCanvas; aRect: tRect; aText: string; aHAlign: tAlignment; aVAlign: tVerticalAlignment);
begin
  drawIncSearch(aCanvas, aRect, aText, aHAlign, aVAlign);
end;

procedure cIncSearchDecorator.viewProxyKeyDown(aSender: tObject; var aKey: word; aShift: tShiftState);
begin
  if (isActive) and (aKey = VK_SPACE) then begin
    aKey:= 0;
  end;


  if (aKey = VK_F3) or ((aKey = VK_F3) and (ssCtrl in aShift)) then begin
    locateViewProxy(fSearchText, fSearchDirection, spNextFromCurrent);
  end;
end;

procedure cIncSearchDecorator.viewProxyKeyPress(aSender: tObject; var aKey: char);
begin
  if not isActive then begin
    if (aKey = ' ') then exit;
  end;


  incSearch(aKey);
end;

procedure cIncSearchDecorator.searchTimerTick(aTimer: cTimer);
var
  oldSearchText: string;
begin
  if (fSearchTime.elapsed > fSearchTimerInterval) then begin
    oldSearchText:= fSearchText;

    fSearchText:= '';
    updateActive;

    if (assigned(fViewProxy)) and (oldSearchText <> '') then begin
      fViewProxy.invalidate;
    end;

  end;
end;

procedure cIncSearchDecorator.setColor(aColor: tColor);
begin
  fColor:= aColor;
end;

procedure cIncSearchDecorator.setFontColor(aColor: tColor);
begin
  fFontColor:= aColor;
end;

procedure cIncSearchDecorator.setFrameColor(aColor: tColor);
begin
  fFrameColor:= aColor;
end;

procedure cIncSearchDecorator.setSearchDirection(aDirection: tViewSearchDirection);
begin
  fSearchDirection:= aDirection;
end;

procedure cIncSearchDecorator.setSearchInterval(aValue: integer);
begin
  fSearchTimerInterval:= aValue;

  fTimer.setInterval(aValue);
end;

procedure cIncSearchDecorator.setupEvents;
begin
  connect(fTimer, 'onTick', self, 'searchTimerTick');
end;

procedure cIncSearchDecorator.setupViewProxyEvents;
begin
  if not assigned(fViewProxy) then begin
    exit;
  end;

  connect(fViewProxy, 'onKeyPress', self, 'viewProxyKeyPress');
  connect(fViewProxy, 'onKeyDown', self, 'viewProxyKeyDown');
  connect(fViewProxy, 'onSelectedItemPainted', self, 'viewProxySelectedItemPainted');
end;

procedure cIncSearchDecorator.setViewProxy(aViewProxy: cAbstractViewProxy);
begin
  disconnectViewProxyEvents;

  fViewProxy:= aViewProxy;

  setupViewProxyEvents;
end;

procedure cIncSearchDecorator.updateActive;
begin
  fActive:= fSearchText <> '';
end;

end.
