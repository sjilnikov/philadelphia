unit clsTablePagerWidget;

interface
uses
  classes,
  sysUtils,
  stdCtrls,
  controls,
  spin,
  extCtrls,

  math,

  clsException,
  clsStringUtils,
  clsMemory,
  clsResources,
  clsMulticastEvents,
  clsTablePagerModel;

type
  eTablePagerWidget = class(cException);

  tTablePagerWidget = class(tWinControl)
  private
    fSbFirst        : tImage;
    fSbPrev         : tImage;

    fECurPage       : tSpinEdit;

    fSbNext         : tImage;
    fSbLast         : tImage;

    fEItemsOnPage   : tSpinEdit;

    fLbHumanize     : tLabel;
    fPagerModel     : cTablePagerModel;

    procedure   loadIcons;

    procedure   setupView;
    procedure   setupEvents;
    procedure   disconnectEvents;

    procedure   setupPagerModelEvents;
    procedure   disconnectPagerModelEvents;

    procedure   setViewHumanizeText(aText: string);

    procedure   setViewCurPage(aValue: integer);
    function    getViewCurPage: integer;
    procedure   setViewCurPageMaxValue(aValue: integer);
    function    isCurPageViewEmpty: boolean;


    procedure   setViewItemsOnPage(aValue: integer);
    function    getViewItemsOnPage: integer;
    procedure   setViewItemsOnPageMaxValue(aValue: integer);
    function    isItemsOnPageViewEmpty: boolean;

    procedure   readModelData;
  public
    const

    CURRENT_VERSION                        = '1.0';
    INVALID_VERSION_FORMAT                 = 'invalid version, got: %s, expected: %s';
  public
    function    saveState: tBytesArray;
    function    restoreState(const aBytesArray: tBytesArray): boolean;

    procedure   setPagerModel(aPagerModel: cTablePagerModel);
    function    getPagerModel: cTablePagerModel;

    constructor create(aOnwer: tComponent); override;
    destructor  destroy; override;

    property    pagerModel: cTablePagerModel read getPagerModel;

  {$REGION 'parent properties'}
  published

    property    Align;
    property    BevelEdges;
    property    BevelInner;
    property    BevelKind;
    property    BevelOuter;
    property    BevelWidth;
    property    Color;
    property    DoubleBuffered;
    property    ParentBackground;
    property    ParentColor;
    property    ParentDoubleBuffered;
    property    Touch;

  {$ENDREGION}
  published
    //SLOTS
    procedure   pagerModelRendered(aTablePager: cTablePagerModel);

    procedure   firstClick(aSender: tObject);
    procedure   prevClick(aSender: tObject);
    procedure   nextClick(aSender: tObject);
    procedure   lastClick(aSender: tObject);

    procedure   curPageChange(aSender: tObject);
    procedure   itemsOnPageChange(aSender: tObject);
  end;

{$R resources\pager.res}

implementation

{ tTablePagerView }

constructor tTablePagerWidget.create(aOnwer: tComponent);
begin
  inherited create(aOnwer);
  fPagerModel:= nil;

  setupView;
  setupEvents;

  setViewHumanizeText('');
end;

destructor tTablePagerWidget.destroy;
begin
  disconnectEvents;
  disconnectPagerModelEvents;
  inherited;
end;

procedure tTablePagerWidget.setupView;
begin
  caption:= '';

  width:= 550;
  height:= 30;

  fSbFirst:= tImage.create(self);
  fSbFirst.parent:= self;
  fSbFirst.setBounds(6, 3, 20, 20);

  fSbPrev:= tImage.create(self);
  fSbPrev.parent:= self;
  fSbPrev.setBounds(42, 3, 20, 20);

  fECurPage:= tSpinEdit.create(self);
  fECurPage.parent:= self;
  fECurPage.setBounds(73, 3, 42, 22);
  fECurPage.minValue:= 1;

  fSbNext:= tImage.create(self);
  fSbNext.parent:= self;
  fSbNext.setBounds(126, 3, 20, 20);

  fSbLast:= tImage.create(self);
  fSbLast.parent:= self;
  fSbLast.setBounds(162, 3, 20, 20);

  fEItemsOnPage:= tSpinEdit.create(self);
  fEItemsOnPage.parent:= self;
  fEItemsOnPage.setBounds(198, 3, 57, 22);
  fEItemsOnPage.minValue:= 1;

  fLbHumanize:= tLabel.create(self);
  fLbHumanize.parent:= self;
  fLbHumanize.setBounds(261, 12, 100, 22);

  loadIcons;
end;

procedure tTablePagerWidget.setupEvents;
begin
  connect(fECurPage, 'onChange', self, 'curPageChange');
  connect(fEItemsOnPage, 'onChange', self, 'itemsOnPageChange');

  connect(fSbFirst, 'onClick', self, 'firstClick');
  connect(fSbPrev, 'onClick', self, 'prevClick');
  connect(fSbNext, 'onClick', self, 'nextClick');
  connect(fSbLast, 'onClick', self, 'lastClick');
end;

procedure tTablePagerWidget.disconnectEvents;
begin
  disconnect(fECurPage);
  disconnect(fEItemsOnPage);

  disconnect(fSbFirst);
  disconnect(fSbPrev);
  disconnect(fSbNext);
  disconnect(fSbLast);
end;

procedure tTablePagerWidget.setupPagerModelEvents;
begin
  if assigned(fPagerModel) then begin
    connect(fPagerModel, 'onModelRendered', self, 'pagerModelRendered');
  end;
end;

procedure tTablePagerWidget.disconnectPagerModelEvents;
begin
  if assigned(fPagerModel) then begin
    disconnect(fPagerModel);
  end;
end;

function tTablePagerWidget.getPagerModel: cTablePagerModel;
begin
  result:= fPagerModel;
end;

function tTablePagerWidget.getViewCurPage: integer;
var
  newValue: integer;
begin
  if fECurPage.text = '' then begin
    newValue:= cTablePagerModel.CUR_PAGE_MIN_VALUE;
  end else begin
    newValue:= fECurPage.value;
  end;

  result:= newValue;
end;

function tTablePagerWidget.getViewItemsOnPage: integer;
var
  newValue: integer;
begin
  if fEItemsOnPage.text = '' then begin
    newValue:= cTablePagerModel.DEFAULT_ITEMS_ON_PAGE;
  end else begin
    newValue:= fEItemsOnPage.value;
  end;

  result:= newValue;
end;

procedure tTablePagerWidget.loadIcons;
const
  I_FIRST = 0;
  I_PREV  = 1;
  I_NEXT  = 2;
  I_LAST  = 3;

  iconsNameArr: array[I_FIRST..I_LAST] of string = (
    repositoryResources.TABLE_PAGER_FIRST_RESOURCE,
    repositoryResources.TABLE_PAGER_PREV_RESOURCE,
    repositoryResources.TABLE_PAGER_NEXT_RESOURCE,
    repositoryResources.TABLE_PAGER_LAST_RESOURCE
  );
var
  resStream: tResourceStream;
  compArr: array[I_FIRST..I_LAST] of tImage;

  i: integer;
  curIconName: string;
begin
  compArr[I_FIRST]:= fSbFirst;
  compArr[I_PREV]:= fSbPrev;
  compArr[I_NEXT]:= fSbNext;
  compArr[I_LAST]:= fSbLast;


  for i:= low(iconsNameArr) to high(iconsNameArr) do begin
    curIconName:= iconsNameArr[i];

    resStream:= tResourceStream.create(hInstance, curIconName, repositoryResources.RESOURCES_SECTION);
    try
      compArr[i].picture.bitmap.loadFromStream(resStream);
    finally
      freeAndNil(resStream);
    end;

  end;

end;

procedure tTablePagerWidget.setViewCurPage(aValue: integer);
begin
  if not assigned(fPagerModel) then begin
    exit;
  end;

  fECurPage.value:= min(aValue, fPagerModel.pages);
end;

procedure tTablePagerWidget.setViewCurPageMaxValue(aValue: integer);
begin
  fECurPage.maxValue:= aValue;
end;

function tTablePagerWidget.isCurPageViewEmpty: boolean;
begin
  result:= fECurPage.text = '';
end;

procedure tTablePagerWidget.setViewHumanizeText(aText: string);
begin
  fLbHumanize.caption:= aText;
end;

procedure tTablePagerWidget.setViewItemsOnPage(aValue: integer);
begin
  if not assigned(fPagerModel) then begin
    exit;
  end;

  fEItemsOnPage.value:= min(aValue, cTablePagerModel.ITEMS_ON_PAGE_MAX_VALUE);
end;

procedure tTablePagerWidget.setViewItemsOnPageMaxValue(aValue: integer);
begin
  fEItemsOnPage.maxValue:= aValue;
end;

function tTablePagerWidget.isItemsOnPageViewEmpty: boolean;
begin
  result:= fEItemsOnPage.text = '';
end;

procedure tTablePagerWidget.readModelData;
begin
  if not assigned(fPagerModel) then begin
    exit;
  end;

  setViewCurPageMaxValue(fPagerModel.pages);
  setViewCurPage(fPagerModel.page);

  setViewItemsOnPageMaxValue(cTablePagerModel.ITEMS_ON_PAGE_MAX_VALUE);
  setViewItemsOnPage(fPagerModel.itemsOnPage);

  setViewHumanizeText(fPagerModel.getHumanizeText);
end;

function tTablePagerWidget.restoreState(const aBytesArray: tBytesArray): boolean;
var
  dataStream: cMemory;

  version: ansiString;
  curPage: integer;
  widgetVisible: boolean;
  itemsOnPage: integer;
begin
  result:= false;
  dataStream:= cMemory.create;
  try
    dataStream.fromBytes(aBytesArray);


    dataStream.readAnsiString(version);

    if (version = '') then begin
      exit;
    end;

    if (version <> CURRENT_VERSION) then begin
      raise eTablePagerWidget.createFmt(INVALID_VERSION_FORMAT, [version, CURRENT_VERSION]);
    end;

    dataStream.readInteger(curPage);
    dataStream.readInteger(itemsOnPage);
    dataStream.readBool(widgetVisible);


    fPagerModel.setPage(curPage);
    fPagerModel.setItemsOnPage(itemsOnPage);
    visible:= widgetVisible;

    result:= true;
  finally
    freeAndNil(dataStream);
  end;
end;

function tTablePagerWidget.saveState: tBytesArray;
var
  dataStream: cMemory;
begin
  if not assigned(fPagerModel) then exit;


  dataStream:= cMemory.create;
  try
    dataStream.clear;

    dataStream.writeAnsiString(CURRENT_VERSION);
    dataStream.writeInteger(fPagerModel.getPage);
    dataStream.writeInteger(fPagerModel.getItemsOnPage);
    dataStream.writeBool(visible);

    result:= dataStream.toBytes;
  finally
    freeAndNil(dataStream);
  end;
end;

procedure tTablePagerWidget.setPagerModel(aPagerModel: cTablePagerModel);
begin
  disconnectPagerModelEvents;

  fPagerModel:= aPagerModel;

  setupPagerModelEvents;


  readModelData;
end;


//SLOTS

procedure tTablePagerWidget.pagerModelRendered(aTablePager: cTablePagerModel);
begin
  readModelData;
end;

procedure tTablePagerWidget.firstClick(aSender: tObject);
begin
  if not assigned(fPagerModel) then begin
    exit;
  end;

  fPagerModel.firstPage;
end;

procedure tTablePagerWidget.prevClick(aSender: tObject);
begin
  if not assigned(fPagerModel) then begin
    exit;
  end;

  fPagerModel.prevPage;
end;

procedure tTablePagerWidget.nextClick(aSender: tObject);
begin
  if not assigned(fPagerModel) then begin
    exit;
  end;

  fPagerModel.nextPage;
end;

procedure tTablePagerWidget.lastClick(aSender: tObject);
begin
  if not assigned(fPagerModel) then begin
    exit;
  end;

  fPagerModel.lastPage;
end;

procedure tTablePagerWidget.curPageChange(aSender: tObject);
begin
  if not assigned(fPagerModel) then begin
    exit;
  end;

  if isCurPageViewEmpty then begin
    exit;
  end;


  fPagerModel.setPage(getViewCurPage);
end;

procedure tTablePagerWidget.itemsOnPageChange(aSender: tObject);
begin
  if not assigned(fPagerModel) then begin
    exit;
  end;

  if isItemsOnPageViewEmpty then begin
    exit;
  end;

  fPagerModel.setItemsOnPage(getViewItemsOnPage);
end;

end.

