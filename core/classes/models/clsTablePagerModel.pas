unit clsTablePagerModel;

interface
uses
  sysUtils,
  classes,
  math,

  clsMulticastEvents,
  clsException,
  clsAbstractTableModel;

type
  eTablePagerModel = class(cException);

  cTablePagerModel = class;

  tTablePagerModelRenderedEvent = procedure(aModel: cTablePagerModel) of object;

  cTablePagerModel = class
  private
    fTableModel         : cAbstractTableModel;

    fHumanizeTextFormat : string;

    fPage               : integer;
    fRowCount           : integer;
    fPages              : integer;
    fLimit              : integer;
    fOffset             : integer;
    fItemsOnPage        : integer;
    fFetching           : boolean;
    fHumanizeText       : string;

    fOnModelRendered    : tTablePagerModelRenderedEvent;

    procedure   modelRendered;

    procedure   updateModelRowCount;

    procedure   beginFetch;
    procedure   endFetch;

    procedure   setupTableModelEvents;
    procedure   disconnectTableModelEvents;

    procedure   updateValues;
    procedure   readModelData;
    procedure   renderModel;
  public
    const

    ITEMS_ON_PAGE_MAX_VALUE = 999999;

    DEFAULT_HUMANIZE_TEXT_FORMAT = '%d page of %d (total: %d)';
    DEFAULT_ITEMS_ON_PAGE = 50;
    CANNOT_RENDER_MODEL_MODEL_NOT_ASSIGNED = 'cannot render model, model not assigned';

    ITEMS_ON_PAGE_MIN_VALUE = 1;
    CUR_PAGE_MIN_VALUE = 1;
  public
    procedure   setPage(aValue: integer);
    function    getPage: integer;

    procedure   setItemsOnPage(aValue: integer);
    function    getItemsOnPage: integer;

    procedure   setHumanizeTextFormat(aValue: string);
    function    getHumanizeTextFormat: string;
    function    getHumanizeText: string;

    procedure   setModel(aModel: cAbstractTableModel);

    procedure   nextPage;
    procedure   prevPage;

    procedure   firstPage;
    procedure   lastPage;

    constructor create;
    destructor  destroy; override;

    property    limit: integer read fLimit;
    property    offset: integer read fOffset;
    property    itemsOnPage: integer read getItemsOnPage write setItemsOnPage;
    property    page: integer read getPage write setPage;
    property    rowCount: integer read fRowCount;
    property    pages: integer read fPages;
    property    humanizeTextFormat: string read getHumanizeTextFormat write setHumanizeTextFormat;
    property    humanizeText: string read getHumanizeText;
  published
    //EVENTS
    property    onModelRendered: tTablePagerModelRenderedEvent read fOnModelRendered write fOnModelRendered;
  published
    //SLOTS
    procedure   tableModelFetching(aModel: cAbstractTableModel; aCondition: string; var aLimit: integer; var aOffset: integer);
    procedure   tableModelConditionSetted(aModel: cAbstractTableModel; aCondition: string);
    procedure   tableModelRowCountChanged(aModel: cAbstractTableModel);
  end;


implementation

{ cTablePagerModel }

constructor cTablePagerModel.create;
begin
  inherited create;

  fFetching:= false;

  setHumanizeTextFormat(DEFAULT_HUMANIZE_TEXT_FORMAT);

  fTableModel:= nil;

  fPage:= 1;
  fPages:= 1;
  fItemsOnPage:= DEFAULT_ITEMS_ON_PAGE;
  fLimit:= fItemsOnPage;
  fOffset:= 0;
end;

destructor cTablePagerModel.destroy;
begin
  disconnectTableModelEvents;
  inherited;
end;

procedure cTablePagerModel.setupTableModelEvents;
begin
  if not assigned(fTableModel) then begin
    exit;
  end;

  connect(fTableModel, 'onDataFetching', self, 'tableModelFetching');
  connect(fTableModel, 'onConditionSetted', self, 'tableModelConditionSetted');

  connect(fTableModel, 'onRowCountChanged', self, 'tableModelRowCountChanged');
end;

procedure cTablePagerModel.disconnectTableModelEvents;
begin
  if not assigned(fTableModel) then begin
    exit;
  end;

  disconnect(fTableModel, 'onDataFetching', self, 'tableModelFetching');
  disconnect(fTableModel, 'onConditionSetted', self, 'tableModelConditionSetted');
  disconnect(fTableModel, 'onRowCountChanged', self, 'tableModelRowCountChanged');
end;

procedure cTablePagerModel.beginFetch;
begin
  fFetching:= true;
end;

procedure cTablePagerModel.endFetch;
begin
  fFetching:= false;
end;

function cTablePagerModel.getHumanizeText: string;
begin
  result:= fHumanizeText;
end;

function cTablePagerModel.getHumanizeTextFormat: string;
begin
  result:= fHumanizeTextFormat;
end;

function cTablePagerModel.getItemsOnPage: integer;
begin
  result:= fItemsOnPage;
end;

function cTablePagerModel.getPage: integer;
begin
  result:= fPage;
end;

procedure cTablePagerModel.lastPage;
begin
  setPage(fPages);
end;

procedure cTablePagerModel.modelRendered;
begin
  if assigned(fOnModelRendered) then begin
    fOnModelRendered(self);
  end;
end;

procedure cTablePagerModel.nextPage;
begin
  if (fPage <> fPages) then begin
    setPage(fPage + 1);
  end;
end;

procedure cTablePagerModel.firstPage;
begin
  setPage(1);
end;

procedure cTablePagerModel.prevPage;
begin
  if (fPage <> 1) then begin
    setPage(fPage - 1);
  end;
end;

procedure cTablePagerModel.readModelData;
begin
  if not assigned(fTableModel) then begin
    exit;
  end;

  fRowCount:= fTableModel.getFullRowCountWithoutLimits;
  fPage:= 1;
end;

procedure cTablePagerModel.renderModel;
begin
  if (not assigned(fTableModel)) then begin
    exit;
  end;

  if (fItemsOnPage = 0) then begin
    exit;
  end;


  beginFetch;
  try
    fTableModel.reload;
  finally
    endFetch;
  end;

  modelRendered;
end;

procedure cTablePagerModel.setHumanizeTextFormat(aValue: string);
begin
  fHumanizeTextFormat:= aValue;
end;

procedure cTablePagerModel.setItemsOnPage(aValue: integer);
begin
  fItemsOnPage := aValue;

  renderModel;

end;

procedure cTablePagerModel.setModel(aModel: cAbstractTableModel);
begin
  disconnectTableModelEvents;

  fTableModel:= aModel;

  setupTableModelEvents;
end;

procedure cTablePagerModel.setPage(aValue: integer);
begin
  if (aValue = fPage) and ((aValue >= 1) and (aValue <= fPages)) then begin
    exit;
  end;

  fPage := aValue;
  if (aValue >= pages) then begin
    fPage:= pages;
  end;

  if (aValue <= 1) then begin
    fPage:= 1;
  end;

  renderModel;

end;

procedure cTablePagerModel.updateModelRowCount;
begin
  fRowCount:= fTableModel.getFullRowCountWithoutLimits;
end;

procedure cTablePagerModel.updateValues;
begin
  fPages:= max(1, ceil(fRowCount / fItemsOnPage));
  fLimit:= fItemsOnPage;
  fOffset:= (fPage - 1) * fItemsOnPage;

  if (fHumanizeTextFormat <> '') then begin
    fHumanizeText:= format(fHumanizeTextFormat, [fPage, fPages, fRowCount]);
  end;
end;

{$REGION 'SLOTS'}
procedure cTablePagerModel.tableModelFetching(aModel: cAbstractTableModel; aCondition: string; var aLimit: integer; var aOffset: integer);
begin
  updateValues;

  aLimit:= fLimit;
  aOffset:= fOffset;
end;

procedure cTablePagerModel.tableModelRowCountChanged(aModel: cAbstractTableModel);
begin
  updateModelRowCount;
  updateValues;

  modelRendered;
end;

procedure cTablePagerModel.tableModelConditionSetted(aModel: cAbstractTableModel; aCondition: string);
begin
  readModelData;
  renderModel;
end;
{$ENDREGION}

end.
