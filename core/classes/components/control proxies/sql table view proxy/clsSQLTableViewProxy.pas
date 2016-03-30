unit clsSQLTableViewProxy;

interface
uses
  variants,
  stdCtrls,
  extCtrls,
  comCtrls,
  classes,
  controls,
  graphics,
  windows,
  sysUtils,
  db,
  math,

  KControls,
  KGrids,
  KGraphics,


  clsClassKit,

  clsEditButtonViewProxy,

  clsExtendedValidator,

  clsVariantConversion,
  clsDBTypeConversion,
  clsStringUtils,
  clsLists,
  clsTableModel,
  clsSQLTableModel;


type
  eSQLTableViewProxy = class(exception);

  cSQLTableViewProxy = class;
  cGridHeaders = class;

  cGridSpan = class
  private
    fCol     : integer;
    fRow     : integer;
    fColSpan : integer;
    fRowSpan : integer;
  public
    function getCol: integer;
    function getRow: integer;
    function getColSpan: integer;
    function getRowSpan: integer;

    constructor create(aCol: integer; aRow: integer; aColSpan: integer; aRowSpan: integer);
  end;

  cGridSpans = class
  private
    fList       : cList;
    function    getCount: integer;
    function    indexOfItem(aItem: cGridSpan): integer;
  public
    procedure   add(aItem: cGridSpan);
    procedure   delete(aItem: cGridSpan);

    constructor create;
    destructor  destroy;override;
    property    count: integer read getCount;

  end;

  tHeaderType = (htHorizontal, htVertical);

  cGridCell = class(tKGridCell)
  end;

  cGridHeaderCell = class(tKGridAttrTextCell)
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

  cColumnMapItem = class
  private
    fViewIndex   : integer;
    fModelIndex  : integer;
  public
    function    getViewIndex: integer;
    function    getModelIndex: integer;

    constructor create(aViewIndex: integer; aModelIndex: integer);
  end;

  cColumnMap = class
  private
    fList       : cList;
    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cColumnMapItem;
  public
    procedure   clear;
    procedure   add(aItem: cColumnMapItem);
    procedure   moveTo(aFromIndex, aToIndex: integer);

    constructor create;
    destructor  destroy; override;

    property    count: integer read getCount;
    property    items[aIndex: integer]: cColumnMapItem read getItemByIndex;
  end;

  cGridHeader = class
  private
    fOwner      : cGridHeaders;

    fSpans      : cGridSpans;
    fName       : string;
    fStartIndex : integer;
    fEndIndex   : integer;
    fHeaderType : tHeaderType;

    fOffsetCol  : integer;
    fOffsetRow  : integer;

    procedure   updateView;

    function    relRowToGridRow(aRow: integer): integer;
    function    relColToGridCol(aCol: integer): integer;

    procedure   setOffsetCol(aIndex: integer);
    procedure   setOffsetRow(aIndex: integer);
    function    getSpans: cGridSpans;
    procedure   applySpan(aSpan: cGridSpan);
  public
    procedure   addSpan(aSpan: cGridSpan);

    function    data(aRelCol, aRelRow: integer): cGridHeaderCell;

    function    getName: string;
    function    getStartIndex: integer;
    function    getEndIndex: integer;

    function    getType: tHeaderType;
    procedure   setType(aType: tHeaderType);


    function    getOffsetCol: integer;
    function    getOffsetRow: integer;

    constructor create(aOwner: cGridHeaders; aHeaderType: tHeaderType; aStartIndex: integer; aEndIndex: integer; aName: string);
    destructor  destroy; override;

  end;

  cGridHeaders = class
  private
    fGrid       : cSQLTableViewProxy;
    fList       : cList;
    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cGridHeader;
    procedure   add(aItem: cGridHeader);
  public
    function    createHeader(aHeaderType: tHeaderType; aStartIndex: integer; aEndIndex: integer; aName: string): cGridHeader;

    function    getGrid: cSQLTableViewProxy;

    constructor create(aGrid: cSQLTableViewProxy);
    destructor  destroy; override;

    property    grid: cSQLTableViewProxy read getGrid;
    property    count: integer read getCount;
    property    items[aIndex: integer]: cGridHeader read getItemByIndex;
  end;






  tHeadersRenderingEvent = procedure(aSender: cSQLTableViewProxy; aHeaders: cGridHeaders) of object;

  tModelHeaderRenderingEvent = procedure(aSender: cSQLTableViewProxy; aHeaders: cGridHeaders; aModelFields: cTableFields; aStartIndex: integer; aEndIndex: integer; aStartOffset: integer) of object;

  tModelRowRenderingEvent = procedure(aSender: tObject; aCellPainter: tKGridCellPainter; aRow: cSQLRowBase) of object;




  tCreateEditorEvent = function (aType: tDataType): tWinControl of object;
  tDestroyEditorEvent = procedure(aEditor: tWinControl; aType: tDataType) of object;

  tGetEditorDataEvent = function(aEditor: tWinControl; aType: tDataType): variant of object;
  tSetEditorDataEvent = procedure(aEditor: tWinControl; aType: tDataType; aValue: variant) of object;

  tSQLTableViewProxyState = (psBatchRowReloading);

  tSQLTableViewProxyStates = set of tSQLTableViewProxyState;

  cSQLTableViewProxy = class
  private
    const

    SQLFieldSortDirectionMap: array[low(tTableFieldSortDirection)..high(tTableFieldSortDirection)] of tKGridDrawState = (
      [], //dummy
      [gdRowsSortedUp],
      [gdRowsSortedDown]
    );

    stateStringMap: array[low(tSQLTableViewProxyState)..high(tSQLTableViewProxyState)] of string = (
      'psBatchRowReloading'
    );
  private
    fModel                    : cSQLTableModel;
    fView                     : tKGrid;
    fHeaders                  : cGridHeaders;
    fColumnMap                : cColumnMap;
    fViewModelColStartOffset  : integer;
    fViewModelRowStartOffset  : integer;
    fNumericEditorViewProxy   : cEditButtonViewProxy;
    fInitialEditorData        : variant;
    fDrawingModelRow          : cSQLRowBase;
    fDrawingRow               : integer;
    fRendered                 : boolean;

    fOnHeadersRendering       : tHeadersRenderingEvent;
    fOnModelHeaderRendering   : tModelHeaderRenderingEvent;
    fOnModelRowRendering      : tModelRowRenderingEvent;
    fOnCreateEditor           : tCreateEditorEvent;
    fOnDestroyEditor          : tDestroyEditorEvent;
    fOnGetEditorData          : tGetEditorDataEvent;
    fOnSetEditorData          : tSetEditorDataEvent;
    fStates                   : tSQLTableViewProxyStates;

    procedure   renderView;
    function    isRendered: boolean;
    procedure   setRendered(aValue: boolean);

    procedure   setupViewEvents;
    procedure   disconnectViewEvents;

    procedure   createHeaderForModel;

    function    getHeaders: cGridHeaders;

    procedure   setViewModelOffsets;

    procedure   updaColumnsMapping;

    procedure   prepareView;

    function    getMaxRowFromHeaders: integer;
    function    getMaxColFromHeaders: integer;


    procedure   drawGridHeader(aSender: tObject; aCellPainter: tKGridCellPainter; aCol, aRow: integer; aRect: tRect; aStates: tKGridDrawState); inline;
    procedure   drawGridData(aSender: tObject; aCellPainter: tKGridCellPainter; aField: tField; aCol, aRow: integer; aRect: tRect; aStates: tKGridDrawState); inline;


    procedure   setViewFixedColCount(aCount: integer);
    function    getViewFixedColCount: integer;

    procedure   setViewFixedRowCount(aCount: integer);
    function    getViewFixedRowCount: integer;

    function    getViewCell(aCol, aRow: integer): tKGridCell;
    procedure   setViewCell(aCol, aRow: integer; aCell: tKGridCell);

    function    createViewHeaderCell: cGridHeaderCell;

    function    getViewColCount: integer;
    procedure   setViewColCount(aCount: integer);

    function    getViewRowCount: integer;
    procedure   setViewRowCount(aCount: integer);

    procedure   setViewCellSpan(aCol, aRow: integer; aColSpan, aRowSpan: integer);

    procedure   increaseViewCellsIfNeeded(aColCount: integer; aRowCount: integer);

    function    viewColToModelCol(aCol: integer): integer; inline;
    function    viewRowToModelRow(aRow: integer): integer; inline;
    function    modelRowToViewRow(aRow: integer): integer; inline;
    function    modelColToViewCol(aCol: integer): integer;




    function    viewAppendRow: integer;
    procedure   viewDeleteRow;

    //syncronized with db
    function    modelAppendRow: integer;
    procedure   modelDeleteRow(aRow: integer);
    procedure   modelSetRowData(aCol, aRow: integer; aValue: variant);
    function    modelGetRowData(aCol, aRow: integer): variant;



    function    createEditor(aType: tDataType): tWinControl;
    procedure   destroyEditor(aEditor: tWinControl; aType: tDataType);

    function    getEditorData(aEditor: tWinControl; aType: tDataType): variant;
    procedure   setEditorData(aEditor: tWinControl; aType: tDataType; aValue: variant);

    procedure   refreshView;
  public

    procedure   beginBatchRowReload;
    procedure   endBatchRowReload;


    function    getStates: tSQLTableViewProxyStates;

    function    defaultCreateEditor(aType: tDataType): tWinControl;
    procedure   defaultDestroyEditor(aEditor: tWinControl; aType: tDataType);

    function    defaultGetEditorData(aEditor: tWinControl; aType: tDataType): variant;
    procedure   defaultSetEditorData(aEditor: tWinControl; aType: tDataType; aValue: variant);



    procedure   clear;

    function    reloadRow(aRow: integer): boolean;
    function    reloadCurrentRow: boolean;
    function    getViewIndexOfModelField(aName: string): integer;

    procedure   selectCol(aCol: integer);
    procedure   selectRow(aRow: integer);

    function    getViewCol: integer;
    function    getViewRow: integer;

    procedure   edit(aCol, aRow: integer);

    function    appendRow: integer;
    procedure   deleteRow(aViewRow: integer);

    procedure   setModel(aModel: cSQLTableModel);
    procedure   setView(aView: tKGrid);
    procedure   showGrid;



    constructor create;
    destructor  destroy;override;

    property    headers: cGridHeaders read getHeaders;
  public
    const

    modelHeaderName                  = 'modelHeader';

    viewNotAssigned                  = 'view not assigned';
    viewNotRendered                  = 'view not rendered use showGrid method!!!';

    modelNotAssigned                 = 'model not assigned';

    editorForTypeNotSupported        = 'editor for type not supported';
    getEditorDataForTypeNotSupported = 'get editor data for type not supported';
    setEditorDataForTypeNotSupported = 'set editor data for type not supported';
    cannotChangeState                = 'cannot change current state to: %s';
  published
    //SLOTS
    procedure   viewColumnMoved(aSender: tObject; aFromIndex, aToIndex: integer);
    procedure   viewDrawCell(aSender: tObject; aCol, aRow: integer; aRect: tRect; aState: tKGridDrawState);

    procedure   viewEditorCreate(aSender: tObject; aCol, aRow: integer; var aEditor: tWinControl);
    procedure   viewEditorDestroy(aSender: tObject; var aEditor: tWinControl; aCol,aRow: integer);

    procedure   editorDataToView(aSender: tObject; aEditor: tWinControl; aCol, aRow: integer; var assignText: boolean);
    procedure   viewDataToEditor(aSender: tObject; aEditor: tWinControl; aCol, aRow: integer; var assignText: boolean);


    procedure   viewCellClick(aSender: tObject; aCol, aRow: integer);


  published
    //EVENTS
    property    onHeadersRendering: tHeadersRenderingEvent read fOnHeadersRendering write fOnHeadersRendering;

    property    onModelHeaderRendering: tModelHeaderRenderingEvent read fOnModelHeaderRendering write fOnModelHeaderRendering;
    property    onModelRowRendering: tModelRowRenderingEvent read fOnModelRowRendering write fOnModelRowRendering;

    property    onCreateEditor: tCreateEditorEvent read fOnCreateEditor write fOnCreateEditor;
    property    onDestroyEditor: tDestroyEditorEvent read fOnDestroyEditor write fOnDestroyEditor;
    property    onGetEditorData: tGetEditorDataEvent read fOnGetEditorData write fOnGetEditorData;
    property    onSetEditorData: tSetEditorDataEvent read fOnSetEditorData write fOnSetEditorData;
  end;

implementation
uses
  clsMulticastEvents,
  clsLog;


{ cGridHeader }

procedure cGridHeader.addSpan(aSpan: cGridSpan);
begin
  fSpans.add(aSpan);

  if (not(assigned(fOwner))) then begin
    cLog.getInstance.write(self, 'addSpan: owner not assigned', ltError);
    exit;
  end;

  applySpan(aSpan);
end;

procedure cGridHeader.applySpan(aSpan: cGridSpan);
begin
  fOwner.grid.increaseViewCellsIfNeeded(
    relColToGridCol(aSpan.getCol + aSpan.getColSpan),
    relRowToGridRow(aSpan.getRow + aSpan.getRowSpan)
  );

  fOwner.grid.setViewCellSpan(
    relColToGridCol(aSpan.getCol) , relRowToGridRow(aSpan.getRow),
    aSpan.getColSpan              , aSpan.getRowSpan
  );
end;

constructor cGridHeader.create(aOwner: cGridHeaders; aHeaderType: tHeaderType; aStartIndex: integer; aEndIndex: integer; aName: string);
begin
  inherited create;
  fOwner:= aOwner;

  fHeaderType:= aHeaderType;
  fStartIndex:= aStartIndex;
  fEndIndex:= aEndIndex;
  fName:= aName;

  fSpans:= cGridSpans.create;

  setType(aHeaderType);

  updateView;
end;

{ cGridHeaders }

procedure cGridHeaders.add(aItem: cGridHeader);
begin
  fList.add(aItem);
end;

constructor cGridHeaders.create(aGrid: cSQLTableViewProxy);
begin
  inherited create;
  fGrid:= aGrid;

  fList:= cList.create;
end;

function cGridHeaders.createHeader(aHeaderType: tHeaderType; aStartIndex, aEndIndex: integer; aName: string): cGridHeader;
begin
  result:= cGridHeader.create(self, aHeaderType, aStartIndex, aEndIndex, aName);
  add(result);
end;

destructor cGridHeaders.destroy;
begin
  if assigned(fList) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

function cGridHeaders.getCount: integer;
begin
  result:= fList.count;
end;

function cGridHeaders.getGrid: cSQLTableViewProxy;
begin
  result:= fGrid;
end;

function cGridHeaders.getItemByIndex(aIndex: integer): cGridHeader;
begin
  result:= fList[aIndex];
end;

function cGridHeader.data(aRelCol, aRelRow: integer): cGridHeaderCell;
var
  gridCell: tKGridCell;
  gridCol, gridRow: integer;
begin
  result:= nil;
  if (not(assigned(fOwner))) then begin
    cLog.getInstance.write(self, 'data: owner not assigned', ltError);
    exit;
  end;

  gridCol:= relColToGridCol(aRelCol);
  gridRow:= relRowToGridRow(aRelRow);

  fOwner.grid.increaseViewCellsIfNeeded(gridCol + 1, gridRow + 1);

  gridCell:= fOwner.grid.getViewCell(gridCol, gridRow);
  if (gridCell is cGridHeaderCell) then
    result:= cGridHeaderCell(gridCell)
  else begin
    result:= fOwner.grid.createViewHeaderCell;
    fOwner.grid.setViewCell(gridCol, gridRow, result);
  end;
end;

destructor cGridHeader.destroy;
begin
  if assigned(fSpans) then begin
    freeAndNil(fSpans);
  end;

  inherited;
end;

function cGridHeader.getEndIndex: integer;
begin
  result:= fEndIndex;
end;

function cGridHeader.getName: string;
begin
  result:= fName;
end;

function cGridHeader.getOffsetCol: integer;
begin
  result:= fOffsetCol;
end;

function cGridHeader.getOffsetRow: integer;
begin
  result:= fOffsetRow;
end;

function cGridHeader.getSpans: cGridSpans;
begin
  result:= fSpans;
end;

function cGridHeader.getStartIndex: integer;
begin
  result:= fStartIndex;
end;

function cGridHeader.getType: tHeaderType;
begin
  result:= fHeaderType;
end;

function cGridHeader.relColToGridCol(aCol: integer): integer;
begin
  result:= aCol + fOffsetCol;
end;

function cGridHeader.relRowToGridRow(aRow: integer): integer;
begin
  result:= aRow + fOffsetRow;
end;

procedure cGridHeader.setOffsetCol(aIndex: integer);
begin
  fOffsetCol:= aIndex;
end;

procedure cGridHeader.setOffsetRow(aIndex: integer);
begin
  fOffsetRow:= aIndex;
end;

procedure cGridHeader.setType(aType: tHeaderType);
begin
  fHeaderType:= aType;
  case fHeaderType of
    htHorizontal : begin
      setOffsetCol(0);
      setOffsetRow(fStartIndex);
    end;
    htVertical   : begin
      setOffsetCol(fStartIndex);
      setOffsetRow(0);
    end;
  end;
end;

procedure cGridHeader.updateView;
begin
  if (not(assigned(fOwner))) then begin
    cLog.getInstance.write(self, 'updateView: owner not assigned', ltError);
    exit;
  end;

  case fHeaderType of
    htVertical   : fOwner.grid.setViewFixedColCount(max(fOwner.grid.getViewFixedColCount, fEndIndex + 1));
    htHorizontal : fOwner.grid.setViewFixedRowCount(max(fOwner.grid.getViewFixedRowCount, fEndIndex + 1));
  end;
end;

{ cGridSpans }

procedure cGridSpans.add(aItem: cGridSpan);
begin
  fList.add(aItem);
end;

constructor cGridSpans.create;
begin
  inherited create;
  fList:= cList.create;
end;


procedure cGridSpans.delete(aItem: cGridSpan);
var
  foundIndex: integer;
begin
  foundIndex:= indexOfItem(aItem);
  if (foundIndex = -1) then exit;

  freeAndNil(aItem);
  fList.delete(foundIndex);
end;

destructor cGridSpans.destroy;
begin
  if assigned(fList) then begin
    fList.freeInternalObjects;
    freeAndNil(fList);
  end;

  inherited;
end;

function cGridSpans.getCount: integer;
begin
  result:= fList.count;
end;

function cGridSpans.indexOfItem(aItem: cGridSpan): integer;
begin
  result:= fList.indexOf(aItem);
end;

{ cGridSpan }

constructor cGridSpan.create(aCol, aRow, aColSpan, aRowSpan: integer);
begin
  inherited create;
  fCol:= aCol;
  fRow:= aRow;
  fColSpan:= aColSpan;
  fRowSpan:= aRowSpan;
end;

function cGridSpan.getCol: integer;
begin
  result:= fCol;
end;

function cGridSpan.getColSpan: integer;
begin
  result:= fColSpan;
end;

function cGridSpan.getRow: integer;
begin
  result:= fRow;
end;

function cGridSpan.getRowSpan: integer;
begin
  result:= fRowSpan;
end;

{ cGridHeaderCell }

function cGridHeaderCell.alignmentToGridAlignment(aAlignment: tAlignment): tKHAlign;
begin
  result:= halLeft;
  case aAlignment of
    taLeftJustify   : result:= halLeft;
    taRightJustify  : result:= halRight;
    taCenter        : result:= halCenter;
  end;
end;

function cGridHeaderCell.getBrush: tBrush;
begin
  result:= brush;
end;

function cGridHeaderCell.getfont: tFont;
begin
  result:= font;
end;

procedure cGridHeaderCell.setHorizontalAlignment(aAlignment: tAlignment);
begin
  hAlign:= alignmentToGridAlignment(aAlignment);
end;

procedure cGridHeaderCell.setHorizontalPadding(aPadding: integer);
begin
  hPadding:= aPadding;
end;

procedure cGridHeaderCell.setText(aText: string);
begin
  text:= aText;
end;

procedure cGridHeaderCell.setVerticalAlignment(aAlignment: tVerticalAlignment);
begin
  vAlign:= verticalAlignmentToGridAlignment(aAlignment);
end;

procedure cGridHeaderCell.setVerticalPadding(aPadding: integer);
begin
  vPadding:= aPadding;
end;

function cGridHeaderCell.verticalAlignmentToGridAlignment(aAlignment: tVerticalAlignment): tKVAlign;
begin
  result:= valTop;
  case aAlignment of
    taAlignTop       : result:= valTop;
    taAlignBottom    : result:= valBottom;
    taVerticalCenter : result:= valCenter;
  end;
end;

{ cColumnMap }

procedure cColumnMap.add(aItem: cColumnMapItem);
begin
  fList.add(aItem)
end;

procedure cColumnMap.clear;
begin
  fList.freeInternalObjects;
  fList.clear;
end;

constructor cColumnMap.create;
begin
  inherited create;
  fList:= cList.create;
end;

destructor cColumnMap.destroy;
begin
  if (assigned(fList)) then begin
    clear;
    freeAndNil(fList);
  end;

  inherited;
end;

function cColumnMap.getCount: integer;
begin
  result:= fList.count;
end;

function cColumnMap.getItemByIndex(aIndex: integer): cColumnMapItem;
begin
  result:= fList[aIndex];
end;

procedure cColumnMap.moveTo(aFromIndex, aToIndex: integer);
begin
  fList.move(aFromIndex, aToIndex);
end;

{ cColumnMapItem }

constructor cColumnMapItem.create(aViewIndex: integer; aModelIndex: integer);
begin
  inherited create;
  fViewIndex:= aViewIndex;
  fModelIndex:= aModelIndex;
end;

function cColumnMapItem.getModelIndex: integer;
begin
  result:= fModelIndex;
end;

function cColumnMapItem.getViewIndex: integer;
begin
  result:= fViewIndex;
end;


{ cSQLTableViewProxy }

procedure cSQLTableViewProxy.prepareView;
begin
  clear;

  fView.cellClass := cGridCell;

  fView.doubleBuffered:= true;
  fView.options:= [
    goColMoving,
    goColSizing,
    goDoubleBufferedCells,
    goDrawFocusSelected,
    goEditing,
    goHeader,
    goHeaderAlignment,
    goHorzLine,
    goMouseCanHideCells,
    goMouseOverCells,
    goRangeSelect,
    goRowSelect,
    goThemes,
    goThemedCells,
    goVertLine
  ];

  fView.optionsEx:= [
    gxEnterWraps,
    gxTabWraps
  ];
end;

function cSQLTableViewProxy.viewRowToModelRow(aRow: integer): integer;
begin
  result:= aRow - fView.fixedRows;
end;

function cSQLTableViewProxy.modelAppendRow: integer;
begin
  result:= fModel.appendRow;
end;

function cSQLTableViewProxy.modelColToViewCol(aCol: integer): integer;
var
  i: integer;
  columnMapItem: cColumnMapItem;
begin
  for i:= 0 to fColumnMap.count - 1 do begin
    columnMapItem:= fColumnMap.items[i];
    if (columnMapItem.getModelIndex = aCol) then begin
      result:= i;
    end;
  end;
end;

procedure cSQLTableViewProxy.modelDeleteRow(aRow: integer);
begin
  fModel.deleteRow(aRow);
end;

function cSQLTableViewProxy.modelGetRowData(aCol, aRow: integer): variant;
begin
  result:= fModel.getField(aCol, aRow).asVariant;
end;

function cSQLTableViewProxy.modelRowToViewRow(aRow: integer): integer;
begin
  result:= aRow + fView.fixedRows;
end;

procedure cSQLTableViewProxy.modelSetRowData(aCol, aRow: integer; aValue: variant);
begin
  fModel.setFieldData(aCol, aRow, aValue);
end;

function cSQLTableViewProxy.appendRow: integer;
begin
  result:= -1;

  if (not(assigned(fModel))) then exit;
  if (not(assigned(fView))) then exit;

  try
    modelAppendRow;
    result:= viewAppendRow;

    refreshView;
  except
    on e: exception do begin
      cLog.getInstance.write(self, 'appendRow: append failed, message: %s', [e.message], ltError);
    end;
  end;
end;

procedure cSQLTableViewProxy.viewCellClick(aSender: tObject; aCol, aRow: integer);
const
  SQLFieldInvertSortDirection: array[low(tTableFieldSortDirection)..high(tTableFieldSortDirection)] of tTableFieldSortDirection =
    (
      sdAsc, sdDesc, sdNone
    );
var
  headerCell: tKGridCell;

  SQLTableField: cTableField;
begin

  headerCell:= fView.cell[aCol, aRow];

  if (headerCell is cGridHeaderCell) then begin
    SQLTableField:= fModel.getFields.items[viewColToModelCol(aCol)];

    SQLTableField.sortDirection:= SQLFieldInvertSortDirection[SQLTableField.sortDirection];

    refreshView;

  end;

end;

procedure cSQLTableViewProxy.beginBatchRowReload;
begin
  if (fStates <> []) then begin
    raise eSQLTableViewProxy.createFmt(cannotChangeState, [stateStringMap[psBatchRowReloading]]);
  end;

  fStates:= fStates + [psBatchRowReloading];
end;

procedure cSQLTableViewProxy.endBatchRowReload;
begin
  fStates:= fStates - [psBatchRowReloading];
  refreshView;
end;

procedure cSQLTableViewProxy.clear;
begin
  if (not(assigned(fView))) then exit;

  fView.clearGrid;
  fView.fixedCols := 0;
  fView.colCount  := 1;

  fView.fixedRows := 0;
  fView.rowCount  := 1;
  fView.defaultColWidth:= 64;
  fView.defaultRowHeight:= 18;
end;

constructor cSQLTableViewProxy.create;
begin
  inherited create;

  fStates     := [];

  fNumericEditorViewProxy := cEditButtonViewProxy.create;

  fColumnMap  := cColumnMap.create;
  fHeaders    := cGridHeaders.create(self);

  fViewModelColStartOffset:= -1;
  fViewModelRowStartOffset:= -1;

  fDrawingModelRow := nil;
end;

function cSQLTableViewProxy.createEditor(aType: tDataType): tWinControl;
begin
  result:= nil;
  //handle by user
  if (assigned(fOnCreateEditor)) then begin
    result:= fOnCreateEditor(aType);
    exit;
  end;
  //

  result:= defaultCreateEditor(aType);
end;

function cSQLTableViewProxy.defaultCreateEditor(aType: tDataType): tWinControl;
begin
  result:= nil;
  case aType of

    dtNotSupported: begin
      raise eSQLTableViewProxy.create(editorForTypeNotSupported);
    end;

    dtBoolean  : begin
      result:= tCheckBox.create(nil);
    end;

    dtInteger, dtInt64, dtExtended, dtCurrency  : begin
      result:= tButtonedEdit.create(nil);

      fNumericEditorViewProxy.setView(tButtonedEdit(result));
      fNumericEditorViewProxy.setValidator(cExtendedValidator.create);
    end;

    dtDateTime : begin
      result:= tDateTimePicker.create(nil);
    end;

    dtString   : begin
      result:= tButtonedEdit.create(nil);
    end;
  end;
end;


procedure cSQLTableViewProxy.createHeaderForModel;
var
  modelHeader: cGridHeader;
  headerRow: integer;
  i: integer;
  modelFields: cTableFields;
begin
  modelFields:= fModel.getFields;
  headerRow:= getMaxRowFromHeaders + 1;

  if (assigned(fOnModelHeaderRendering)) then begin
    fOnModelHeaderRendering(self, fHeaders, modelFields, headerRow, headerRow, fViewModelColStartOffset);
  end else begin

    modelHeader:= fHeaders.createHeader(htHorizontal, headerRow, headerRow, modelHeaderName);
    for i:= 0 to modelFields.count - 1 do begin
      modelHeader.data(i + fViewModelColStartOffset, 0).setText(modelFields.items[i].title);
    end;

  end;

end;

procedure cSQLTableViewProxy.setViewCellSpan(aCol, aRow, aColSpan, aRowSpan: integer);
begin
  fView.cellSpan[aCol, aRow]:= makeCellSpan(aColSpan, aRowSpan);
end;

function cSQLTableViewProxy.createViewHeaderCell: cGridHeaderCell;
begin
  result:= cGridHeaderCell.create(fView);
end;

procedure cSQLTableViewProxy.deleteRow(aViewRow: integer);
begin
  if (not(assigned(fModel))) then exit;
  if (not(assigned(fView))) then exit;

  try
    modelDeleteRow(viewRowToModelRow(aViewRow));
    viewDeleteRow;
  except
    on e: exception do begin
      cLog.getInstance.write(self, 'deleteRow: append failed, message: %s', [e.message], ltError);
    end;
  end;
end;

destructor cSQLTableViewProxy.destroy;
begin
  disconnectViewEvents;
  clear;

  if assigned(fNumericEditorViewProxy) then begin
    freeAndNil(fNumericEditorViewProxy);
  end;

  if assigned(fHeaders) then begin
    freeAndNil(fHeaders);
  end;

  if assigned(fColumnMap) then begin
    freeAndNil(fColumnMap);
  end;

  inherited;
end;

procedure cSQLTableViewProxy.destroyEditor(aEditor: tWinControl; aType: tDataType);
begin
  //handle by user
  if (assigned(fOnDestroyEditor)) then begin
    fOnDestroyEditor(aEditor, aType);
    exit;
  end;
  //
  defaultDestroyEditor(aEditor, aType);
end;

procedure cSQLTableViewProxy.defaultDestroyEditor(aEditor: tWinControl; aType: tDataType);
begin
  case aType of

    dtNotSupported: begin
      raise eSQLTableViewProxy.create(editorForTypeNotSupported);
    end;

    dtBoolean  : begin
    end;

    dtInteger, dtInt64, dtExtended, dtCurrency  : begin
      fNumericEditorViewProxy.setView(nil);
    end;

    dtDateTime : begin
    end;

    dtString   : begin
    end;
  end;
end;

procedure cSQLTableViewProxy.setupViewEvents;
begin
  if (not assigned(fView)) then exit;

  connect(fView, 'onDrawCell', self, 'viewDrawCell');
  connect(fView, 'onMouseClickCell', self, 'viewCellClick');
  connect(fView, 'onColumnMoved', self, 'viewColumnMoved');

  connect(fView, 'onEditorCreate', self, 'viewEditorCreate');
  connect(fView, 'onEditorDestroy', self, 'viewEditorDestroy');
  connect(fView, 'onEditorDataFromGrid', self, 'viewDataToEditor');
  connect(fView, 'onEditorDataToGrid', self, 'editorDataToView');
end;

procedure cSQLTableViewProxy.disconnectViewEvents;
begin
  if (not assigned(fView)) then exit;

  disconnect(fView, 'onDrawCell', self, 'viewDrawCell');
  disconnect(fView, 'onMouseClickCell', self, 'viewCellClick');
  disconnect(fView, 'onColumnMoved', self, 'viewColumnMoved');

  disconnect(fView, 'onEditorCreate', self, 'viewEditorCreate');
  disconnect(fView, 'onEditorDestroy', self, 'viewEditorDestroy');
  disconnect(fView, 'onEditorDataFromGrid', self, 'viewDataToEditor');
  disconnect(fView, 'onEditorDataToGrid', self, 'editorDataToView');
end;

procedure cSQLTableViewProxy.refreshView;
begin
  if (not(assigned(fView))) then exit;

  if (fStates <> []) then exit;

  fView.invalidate;
end;

function cSQLTableViewProxy.reloadCurrentRow: boolean;
begin
  result:= reloadRow(getViewCol);
end;

function cSQLTableViewProxy.reloadRow(aRow: integer): boolean;
begin
  if (not(assigned(fModel))) then exit;
  if (not(assigned(fView))) then exit;

  fModel.reload(viewRowToModelRow(aRow));
  refreshView;
end;

procedure cSQLTableViewProxy.renderView;
begin
  if (not(assigned(fView))) then exit;


  //setup other header must be defined here
  if assigned(fOnHeadersRendering) then begin
    fOnHeadersRendering(self, fHeaders);
  end;
  //

  setViewColCount(getMaxColFromHeaders + 1 + fModel.getFields.count);
  setViewModelOffsets;

  createHeaderForModel;
  updaColumnsMapping;

  setViewRowCount(getMaxRowFromHeaders + 1 + fModel.getRecordCount);

  setRendered(true);
end;

procedure cSQLTableViewProxy.viewDrawCell(aSender: tObject; aCol, aRow: integer; aRect: tRect; aState: tKGridDrawState);
begin
  if (not(isRendered)) then begin
    raise eSQLTableViewProxy.create(viewNotRendered);
  end;

  if (gdFixed in aState) then begin
    drawGridHeader(
      aSender,
      fView.cellPainter,
      aCol, aRow,
      aRect,
      aState
    );
  end else begin
    drawGridData(
      aSender,
      fView.cellPainter,
      fModel.getField(viewColToModelCol(aCol), viewRowToModelRow(aRow)),
      aCol,
      aRow,
      aRect,
      aState
    );
  end;
end;

procedure cSQLTableViewProxy.viewDataToEditor(aSender: tObject; aEditor: tWinControl; aCol, aRow: integer; var assignText: boolean);
var
  field: tField;
begin
  fInitialEditorData:= null;
  assignText:= false;

  field:= fModel.getField(viewColToModelCol(aCol), viewRowToModelRow(aRow));
  if (not (assigned(field))) then exit;

  fInitialEditorData:= field.asVariant;
  setEditorData(aEditor, cDBTypeConversion.fieldTypeToDataType(field.dataType), fInitialEditorData);
end;

procedure cSQLTableViewProxy.viewDeleteRow;
begin
  fView.deleteRow(fView.rowCount - 1);
end;

procedure cSQLTableViewProxy.edit(aCol, aRow: integer);
begin
  if (not(assigned(fView))) then exit;

  selectCol(aCol);
  selectRow(aRow);
  fView.editorMode:= true;
end;

procedure cSQLTableViewProxy.viewEditorCreate(aSender: tObject; aCol, aRow: integer; var aEditor: tWinControl);
var
  field: tField;
  modelCol, modelRow: integer;
begin
  aEditor:= nil;

  modelCol:= viewColToModelCol(aCol);
  modelRow:= viewRowToModelRow(aRow);

  if (fModel.getFields.items[modelCol].readOnly) then exit;

  field:= fModel.getField(modelCol, modelRow);
  if (not (assigned(field))) then exit;

  aEditor:= createEditor(cDBTypeConversion.fieldTypeToDataType(field.dataType));
end;

procedure cSQLTableViewProxy.editorDataToView(aSender: tObject; aEditor: tWinControl; aCol, aRow: integer; var assignText: boolean);
var
  field: tField;
  value: variant;

  row: cSQLRowBase;

  modelCol, modelRow: integer;
begin
  modelCol:= viewColToModelCol(aCol);
  modelRow:= viewRowToModelRow(aRow);

  field:= fModel.getField(modelCol, modelRow);
  if (not (assigned(field))) then exit;

  value:= getEditorData(aEditor, cDBTypeConversion.fieldTypeToDataType(field.dataType));

  if (varToStr(value) = varToStr(fInitialEditorData)) then exit;

  modelSetRowData(modelCol,modelRow, value);
end;

procedure cSQLTableViewProxy.viewEditorDestroy(aSender: tObject; var aEditor: tWinControl; aCol, aRow: integer);
var
  field: tField;
begin
  field:= fModel.getField(viewColToModelCol(aCol), viewRowToModelRow(aRow));
  if (not (assigned(field))) then exit;

  destroyEditor(aEditor, cDBTypeConversion.fieldTypeToDataType(field.dataType));
end;

procedure cSQLTableViewProxy.drawGridData(aSender: tObject; aCellPainter: tKGridCellPainter; aField: tField; aCol, aRow: integer; aRect: tRect; aStates: tKGridDrawState);
var
  drawingRowChanged: boolean;
  firstColDrawing: boolean;
begin
  firstColDrawing:= (aCol = fViewModelColStartOffset);
  drawingRowChanged:= (fDrawingRow <> aRow);
  fDrawingRow:= aRow;

  with aCellPainter do begin

    text:= aField.asString;

    case cDBTypeConversion.fieldTypeToDataType(aField.dataType) of

      dtInteger, dtInt64, dtExtended, dtCurrency: begin
        hAlign:= halRight;
      end;

      dtBoolean: begin
        checkBox:= true;
        checkBoxChecked:= aField.asBoolean;

        text:= '';
      end;
    end;


    if (((firstColDrawing) or (drawingRowChanged)) and (assigned(fOnModelRowRendering))) then begin
      fDrawingModelRow:= fModel.getIteratorRow;
    end;

    if (assigned(fDrawingModelRow) and assigned(fOnModelRowRendering)) then begin
      fOnModelRowRendering(self, aCellPainter, fDrawingModelRow);
    end;



    defaultDraw;
  end;

end;

procedure cSQLTableViewProxy.drawGridHeader(aSender: tObject; aCellPainter: tKGridCellPainter; aCol, aRow: integer; aRect: tRect; aStates: tKGridDrawState);
var
  headerCell: tKGridCell;
  SQLTableField: cTableField;
begin

  with aCellPainter do begin

    headerCell:= fView.cell[aCol, aRow];

    if (headerCell is cGridHeaderCell) then begin
      SQLTableField:= fModel.getFields.items[viewColToModelCol(aCol)];

      if (SQLTableField.containsStates([fsSortable])) then
        state:= state + SQLFieldSortDirectionMap[SQLTableField.sortDirection];


      headerCell.applyDrawProperties;

    end;

    drawThemedHeaderCell;
  end;
end;

function cSQLTableViewProxy.getViewFixedColCount: integer;
begin
  result:= fView.fixedCols;
end;

function cSQLTableViewProxy.getViewFixedRowCount: integer;
begin
  result:= fView.fixedRows;
end;

function cSQLTableViewProxy.getEditorData(aEditor: tWinControl; aType: tDataType): variant;
begin
  result:= null;
  //handle by user
  if (assigned(fOnGetEditorData)) then begin
    result:= fOnGetEditorData(aEditor, aType);

    exit;
  end;
  //
  result:= defaultGetEditorData(aEditor, aType);
end;

function cSQLTableViewProxy.defaultGetEditorData(aEditor: tWinControl; aType: tDataType): variant;
begin
  result:= null;
  case aType of

    dtNotSupported: begin
      raise eSQLTableViewProxy.create(getEditorDataForTypeNotSupported);
    end;

    dtBoolean  : begin
      result:= tCheckBox(aEditor).checked;
    end;

    dtInteger, dtInt64, dtExtended, dtCurrency: begin
      result:= fNumericEditorViewProxy.getValue;
    end;

    dtDateTime : begin
      result:= tDateTimePicker(aEditor).dateTime;
    end;

    dtString   : begin
      result:= tButtonedEdit(aEditor).text;
    end;
  end;
end;

function cSQLTableViewProxy.getHeaders: cGridHeaders;
begin
  result:= fHeaders;
end;

function cSQLTableViewProxy.getMaxColFromHeaders: integer;
var
  i: integer;
  curHeader: cGridHeader;
begin
  result:= -1;
  for i:= 0 to fHeaders.count - 1 do begin
    curHeader:= fHeaders.items[i];

    if (curHeader.getType = htHorizontal) then continue;

    result:= max(result, curHeader.getEndIndex);
  end;
end;

function cSQLTableViewProxy.getMaxRowFromHeaders: integer;
var
  i: integer;
  curHeader: cGridHeader;
begin
  result:= -1;
  for i:= 0 to fHeaders.count - 1 do begin
    curHeader:= fHeaders.items[i];

    if (curHeader.getType = htVertical) then continue;

    result:= max(result, curHeader.getEndIndex);
  end;
end;

function cSQLTableViewProxy.getStates: tSQLTableViewProxyStates;
begin
  result:= fStates;
end;

function cSQLTableViewProxy.getViewCell(aCol, aRow: integer): tKGridCell;
begin
  result:= fView.cell[aCol, aRow];
end;

function cSQLTableViewProxy.getViewCol: integer;
begin
  result:= -1;
  if (not(assigned(fView))) then exit;

  result:= fView.col;
end;

function cSQLTableViewProxy.getViewColCount: integer;
begin
  result:= fView.colCount;
end;

function cSQLTableViewProxy.getViewRow: integer;
begin
  result:= -1;
  if (not(assigned(fView))) then exit;

  result:= fView.row;
end;

function cSQLTableViewProxy.getViewRowCount: integer;
begin
  result:= fView.rowCount;
end;

procedure cSQLTableViewProxy.increaseViewCellsIfNeeded(aColCount, aRowCount: integer);
begin
  if (aColCount > getViewColCount) then begin
    setViewColCount(aColCount);
  end;

  if (aRowCount > getViewRowCount) then begin
    setViewRowCount(aRowCount);
  end;
end;

function cSQLTableViewProxy.isRendered: boolean;
begin
  result:= fRendered;
end;

function cSQLTableViewProxy.getViewIndexOfModelField(aName: string): integer;
var
  modelFields: cTableFields;
  modelIndex: integer;
begin
  result:= -1;

  if (not(assigned(fModel))) then exit;
  if (not(assigned(fView))) then exit;

  modelFields:= fModel.getFields;
  modelIndex:= modelFields.indexOfName(aName);

  if (modelIndex = -1) then begin
    cLog.getInstance.write(self, 'getViewIndexOfModelField: modelIndex not found', ltWarning);
    exit;
  end;

  result:= modelColToViewCol(modelIndex);
end;

procedure cSQLTableViewProxy.updaColumnsMapping;
var
  i: integer;
begin
  fColumnMap.clear;

  for i:=  0 to fView.colCount - 1 do begin
    fColumnMap.add(cColumnMapItem.create(i, i - fViewModelColStartOffset));
  end;
end;

function cSQLTableViewProxy.viewAppendRow: integer;
begin
  fView.insertRow(fView.rowCount - 1);
  result:= fView.rowCount - 1;
end;

function cSQLTableViewProxy.viewColToModelCol(aCol: integer): integer;
begin
  result:= fColumnMap.items[aCol].getModelIndex;
end;

procedure cSQLTableViewProxy.viewColumnMoved(aSender: tObject; aFromIndex, aToIndex: integer);
begin
  fColumnMap.moveTo(aFromIndex, aToIndex);
end;

procedure cSQLTableViewProxy.setViewFixedColCount(aCount: integer);
begin
  fView.fixedCols:= aCount;
end;

procedure cSQLTableViewProxy.setViewFixedRowCount(aCount: integer);
begin
  fView.fixedRows:= aCount;
end;

procedure cSQLTableViewProxy.selectCol(aCol: integer);
begin
  if (not(assigned(fView))) then exit;

  fView.col:= aCol;
end;

procedure cSQLTableViewProxy.selectRow(aRow: integer);
begin
  if (not(assigned(fView))) then exit;

  fView.row:= aRow;
end;

procedure cSQLTableViewProxy.setEditorData(aEditor: tWinControl; aType: tDataType; aValue: variant);
begin
  //handle by user
  if (assigned(fOnSetEditorData)) then begin
    fOnSetEditorData(aEditor, aType, aValue);

    exit;
  end;
  //
  defaultSetEditorData(aEditor, aType, aValue);
end;

procedure cSQLTableViewProxy.defaultSetEditorData(aEditor: tWinControl; aType: tDataType; aValue: variant);
begin
  case aType of
    dtNotSupported: begin
      raise eSQLTableViewProxy.create(setEditorDataForTypeNotSupported);
    end;

    dtBoolean  : begin
      tCheckBox(aEditor).checked:= aValue;
    end;

    dtInteger, dtInt64, dtExtended, dtCurrency: begin
      fNumericEditorViewProxy.setValue(aValue);
    end;

    dtString: begin
      tButtonedEdit(aEditor).text:= aValue;
    end;

    dtDateTime : begin
      tDateTimePicker(aEditor).dateTime:= aValue;
    end;

  end;
end;


procedure cSQLTableViewProxy.setModel(aModel: cSQLTableModel);
begin
  setRendered(false);

  fModel:= aModel;
end;

procedure cSQLTableViewProxy.setRendered(aValue: boolean);
begin
  fRendered:= aValue;
end;

procedure cSQLTableViewProxy.setView(aView: tKGrid);
begin
  setRendered(false);

  disconnectViewEvents;

  fview:= aView;

  if (not(assigned(fView))) then exit;

  prepareView;

  setupViewEvents;
end;

procedure cSQLTableViewProxy.setViewCell(aCol, aRow: integer; aCell: tKGridCell);
begin
  fView.cell[aCol, aRow]:= aCell;
end;

procedure cSQLTableViewProxy.setViewColCount(aCount: integer);
begin
  fView.colCount:= aCount;
end;

procedure cSQLTableViewProxy.setViewModelOffsets;
begin
  fViewModelColStartOffset:= getViewFixedColCount;
  fViewModelRowStartOffset:= getViewFixedRowCount;
end;

procedure cSQLTableViewProxy.setViewRowCount(aCount: integer);
begin
  fView.rowCount:= aCount;
end;

procedure cSQLTableViewProxy.showGrid;
begin
  if (not(assigned(fView))) then begin
    raise eSQLTableViewProxy.create(viewNotAssigned);
  end;

  if (not(assigned(fModel))) then begin
    raise eSQLTableViewProxy.create(modelNotAssigned);
  end;

  renderView;
end;

end.
