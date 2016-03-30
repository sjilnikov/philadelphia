unit clsAggregateViewProxy;

interface
uses
  classes,
  windows,
  variants,
  graphics,
  controls,
  stdCtrls,
  sysUtils,

  KGrids,
  KGraphics,

  clsMulticastEvents,
  clsClassKit,
  clsAggregateModel,
  clsViewProxy,
  clsException;

type
  eAggregateViewProxyBase = class(cException);

  cAggregateViewHeaderCell = class(tKGridAttrTextCell)
  private

    function  alignmentToGridAlignment(aAlignment: tAlignment):tKHAlign; inline;
    function  verticalAlignmentToGridAlignment(aAlignment: tVerticalAlignment):tKVAlign;inline;

  public

    function  getBrush: tBrush;
    function  getfont: tFont;
    procedure setHorizontalAlignment(aAlignment: tAlignment);
    procedure setVerticalAlignment(aAlignment: tVerticalAlignment);
    procedure setHorizontalPadding(aPadding: integer);
    procedure setVerticalPadding(aPadding: integer);

    procedure setText(aText: string);
  end;

  cAggregateViewProxyBase = class(cViewProxyBase)
  private
    fModel      : cAggregateModelBase;
    fRendered   : boolean;

    procedure   setupViewEvents; override;
    procedure   disconnectViewEvents; override;

    procedure   setupModelEvents;
    procedure   disconnectModelEvents;

    function    getCastedView: tKGrid;

    procedure   prepareView;
    procedure   renderView;
    function    isRendered: boolean;
    procedure   setRendered(aValue: boolean);


    procedure   drawGridHeader(aSender: tObject; aCellPainter: tKGridCellPainter; aField: cAggregateField; aViewCol, aViewRow: integer; aRect: tRect; aStates: tKGridDrawState); inline;
    procedure   drawGridData(aSender: tObject; aCellPainter: tKGridCellPainter; aField: cAggregateField; aViewCol, aViewRow: integer; aRect: tRect; aStates: tKGridDrawState); inline;
  private
    const

    VIEW_NOT_ASSIGNED                      = 'view not assigned';
    VIEW_NOT_RENDERED                      = 'view not rendered use showAggregateView method!!!';
    MODEL_NOT_ASSIGNED                     = 'model not assigned';
  public
    procedure   clear;

    procedure   refreshView;

    procedure   setModel(aModel: cAggregateModelBase);
    function    getModel: cAggregateModelBase;

    procedure   setView(aView: tWinControl); override;

    procedure   showAggregateView;

    constructor create;
    destructor  destroy; override;
  public
    property    model: cAggregateModelBase read getModel write setModel;
  published
    //SLOTS
    procedure   modelAggregateValuesUpdated(aModel: cAggregateModelBase);
    procedure   viewDrawCell(aSender: tObject; aViewCol, aViewRow: integer; aRect: tRect; aState: tKGridDrawState);
  end;


implementation

{ cAggregateViewProxyBase }

procedure cAggregateViewProxyBase.clear;
begin
  if (not(assigned(view))) then exit;

  getCastedView.clearGrid;
  getCastedView.fixedCols := 0;
  getCastedView.colCount  := 1;

  getCastedView.fixedRows := 1;
  getCastedView.rowCount  := 2;

  getCastedView.defaultColWidth:= 64;
  getCastedView.defaultRowHeight:= 18;
end;

constructor cAggregateViewProxyBase.create;
begin
  inherited create;
end;

destructor cAggregateViewProxyBase.destroy;
begin
  disconnectModelEvents;
  inherited;
end;

procedure cAggregateViewProxyBase.setupModelEvents;
begin
  if (not(assigned(fModel))) then begin
    exit;
  end;

  connect(fModel, 'onAggregateValuesUpdated', self, 'modelAggregateValuesUpdated');
end;

procedure cAggregateViewProxyBase.setupViewEvents;
begin
  inherited setupViewEvents;

  if (not assigned(view)) then exit;

  connect(view, 'onDrawCell', self, 'viewDrawCell');
end;

procedure cAggregateViewProxyBase.disconnectModelEvents;
begin
  if (not(assigned(fModel))) then begin
    exit;
  end;

  disconnect(fModel, 'onAggregateValuesUpdated', self, 'modelAggregateValuesUpdated');
end;

procedure cAggregateViewProxyBase.disconnectViewEvents;
begin
  inherited disconnectViewEvents;

  if (not assigned(view)) then exit;

  disconnect(view, 'onDrawCell', self, 'viewDrawCell');
end;

procedure cAggregateViewProxyBase.drawGridData(aSender: tObject; aCellPainter: tKGridCellPainter; aField: cAggregateField; aViewCol, aViewRow: integer; aRect: tRect; aStates: tKGridDrawState);
begin

end;

procedure cAggregateViewProxyBase.drawGridHeader(aSender: tObject; aCellPainter: tKGridCellPainter; aField: cAggregateField; aViewCol, aViewRow: integer; aRect: tRect; aStates: tKGridDrawState);
var
  headerCell: tKGridCell;
begin

  with aCellPainter do begin

    headerCell:= getCastedView.cell[aViewCol, aViewRow];

    if (headerCell is cAggregateViewHeaderCell) then begin
      headerCell.applyDrawProperties;
    end;

    drawThemedHeaderCell;
  end;
end;

function cAggregateViewProxyBase.getCastedView: tKGrid;
begin
  result:= view as tKGrid;
end;

function cAggregateViewProxyBase.getModel: cAggregateModelBase;
begin
  result:= fModel;
end;

function cAggregateViewProxyBase.isRendered: boolean;
begin
  result:= fRendered;
end;

procedure cAggregateViewProxyBase.prepareView;
begin
  clear;

  getCastedView.cellClass := cAggregateViewHeaderCell;

  getCastedView.doubleBuffered:= true;
  getCastedView.options:= [
    goColMoving,
    goColSizing,
    goDoubleBufferedCells,
    goHeader,
    goHeaderAlignment,
    goHorzLine,
    goThemes,
    goThemedCells,
    goVertLine
  ];

  getCastedView.optionsEx:= [];

  getCastedView.popupMenu:= getPopupMenu;
end;

procedure cAggregateViewProxyBase.refreshView;
begin
  renderView;
end;

procedure cAggregateViewProxyBase.renderView;
begin
  clear;

  if (not(assigned(view))) then begin
    raise eAggregateViewProxyBase.create(VIEW_NOT_ASSIGNED);
  end;

  if (not(assigned(model))) then begin
    raise eAggregateViewProxyBase.create(MODEL_NOT_ASSIGNED);
  end;

  getCastedView.repaint;

  setRendered(true);
end;

procedure cAggregateViewProxyBase.setModel(aModel: cAggregateModelBase);
begin
  disconnectModelEvents;

  setRendered(false);

  fModel:= aModel;

  setupModelEvents;
end;

procedure cAggregateViewProxyBase.setRendered(aValue: boolean);
begin
  fRendered:= aValue;
end;

procedure cAggregateViewProxyBase.setView(aView: tWinControl);
begin
  setRendered(false);

  inherited setView(aView);

  if (assigned(aView)) and (not (aView is tKGrid)) then begin
    raise eClassError.createFmt(INVALID_CLASS_RECEIVED, [tKGrid.className, aView.className]);
  end;

  prepareView;
end;

procedure cAggregateViewProxyBase.showAggregateView;
begin
  if (not(assigned(view))) then begin
    raise eAggregateViewProxyBase.create(VIEW_NOT_ASSIGNED);
  end;

  if (not(assigned(fModel))) then begin
    raise eAggregateViewProxyBase.create(MODEL_NOT_ASSIGNED);
  end;

  renderView;
end;

//SLOTS
procedure cAggregateViewProxyBase.modelAggregateValuesUpdated(aModel: cAggregateModelBase);
begin
  if (not(assigned(view))) then begin
    raise eAggregateViewProxyBase.create(VIEW_NOT_ASSIGNED);
  end;

  if (not(assigned(view))) then begin
    raise eAggregateViewProxyBase.create(MODEL_NOT_ASSIGNED);
  end;

end;

procedure cAggregateViewProxyBase.viewDrawCell(aSender: tObject; aViewCol, aViewRow: integer; aRect: tRect; aState: tKGridDrawState);
begin
  if (not(isRendered)) then begin
    raise eAggregateViewProxyBase.create(VIEW_NOT_RENDERED);
  end;

  if (gdFixed in aState) then begin
    drawGridHeader(
      aSender,
      getCastedView.cellPainter,
      fModel.getAggregateField(aViewCol),
      aViewCol, aViewRow,
      aRect,
      aState
    );
  end else begin
    drawGridData(
      aSender,
      getCastedView.cellPainter,
      fModel.getAggregateField(aViewCol),
      aViewCol, aViewRow,
      aRect,
      aState
    );
  end;
end;


{ cAggregateViewHeaderCell }

function cAggregateViewHeaderCell.alignmentToGridAlignment(aAlignment: tAlignment): tKHAlign;
begin
  result:= halLeft;
  case aAlignment of
    taLeftJustify   : result:= halLeft;
    taRightJustify  : result:= halRight;
    taCenter        : result:= halCenter;
  end;
end;

function cAggregateViewHeaderCell.getBrush: tBrush;
begin
  result:= brush;
end;

function cAggregateViewHeaderCell.getfont: tFont;
begin
  result:= font;
end;

procedure cAggregateViewHeaderCell.setHorizontalAlignment(aAlignment: tAlignment);
begin
  hAlign:= alignmentToGridAlignment(aAlignment);
end;

procedure cAggregateViewHeaderCell.setHorizontalPadding(aPadding: integer);
begin
  hPadding:= aPadding;
end;

procedure cAggregateViewHeaderCell.setText(aText: string);
begin
  text:= aText;
end;

procedure cAggregateViewHeaderCell.setVerticalAlignment(aAlignment: tVerticalAlignment);
begin
  vAlign:= verticalAlignmentToGridAlignment(aAlignment);
end;

procedure cAggregateViewHeaderCell.setVerticalPadding(aPadding: integer);
begin
  vPadding:= aPadding;
end;

function cAggregateViewHeaderCell.verticalAlignmentToGridAlignment(aAlignment: tVerticalAlignment): tKVAlign;
begin
  result:= valTop;
  case aAlignment of
    taAlignTop       : result:= valTop;
    taAlignBottom    : result:= valBottom;
    taVerticalCenter : result:= valCenter;
  end;
end;

end.
