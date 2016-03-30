unit clsTableViewProxy;

interface
uses
  clipBrd,
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
  generics.collections,

  KControls,
  KGrids,
  KGraphics,

  clsException,
  clsClassKit,
  clsDynamicalObject,

  uModels,
  uMetrics,

  clsTimer,

  clsMemory,
  clsIntegerList,
  clsAbstractIOObject,
  clsAbstractViewProxy,
  clsAbstractEditableViewProxy,
  clsEditViewProxy,
  clsMemoViewProxy,
  clsEditButtonViewProxy,
  clsDateTimePickerViewProxy,
  clsComboBoxViewProxy,
  clsCheckBoxViewProxy,

  clsExtendedValidator,

  clsVariantConversion,
  clsDBTypeConversion,
  clsStringUtils,
  clsLists,
  clsAbstractTableModel;


type
  eTableViewProxy = class(cException);

  cTableViewProxy = class;

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

    function  alignmentToGridAlignment(aAlignment: tAlignment): tKHAlign; inline;
    function  verticalAlignmentToGridAlignment(aAlignment: tVerticalAlignment): tKVAlign;inline;

  public

    function  getBrush: tBrush;
    function  getfont: tFont;
    procedure setHorizontalAlignment(aAlignment: tAlignment);
    procedure setVerticalAlignment(aAlignment: tVerticalAlignment);
    procedure setHorizontalPadding(aPadding: integer);
    procedure setVerticalPadding(aPadding: integer);

    procedure setText(const aText: string);
  end;

  cColumnMapItem = class
  private
    fSurrogateIndex  : integer;
  public
    function    getSurrogateIndex: integer;

    procedure   setSurrogateIndex(aSurrogateIndex: integer);

    constructor create(aModelIndex: integer);
  end;


  cColumnMap = class;

  tColumnMapColumnMovedEvent = procedure(aColumnMap: cColumnMap; aFromCol: integer; aToCol: integer) of object;

  cColumnMap = class
  private
    fList          : cList;
    fOnColumnMoved : tColumnMapColumnMovedEvent;

    function    getCount: integer;
  public
    function    indexOfSurrogateIndex(aSurrogateIndex: integer): integer;

    function    getItemByIndex(aIndex: integer): cColumnMapItem;
    function    getItemBySurrogateIndex(aSurrogateIndex: integer): cColumnMapItem;

    procedure   clear;
    procedure   add(aItem: cColumnMapItem);
    procedure   moveTo(aFromIndex, aToIndex: integer);

    constructor create;
    destructor  destroy; override;

    property    count: integer read getCount;
    property    items[aIndex: integer]: cColumnMapItem read getItemByIndex;
  published
    //EVENTS
    property    onColumnMoved: tColumnMapColumnMovedEvent read fOnColumnMoved write fOnColumnMoved;
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
    fGrid       : cTableViewProxy;
    fList       : cList;
    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cGridHeader;
    procedure   add(aItem: cGridHeader);
  public
    procedure   clear;

    function    createHeader(aHeaderType: tHeaderType; aStartIndex: integer; aEndIndex: integer; aName: string): cGridHeader;

    function    getGrid: cTableViewProxy;

    constructor create(aGrid: cTableViewProxy);
    destructor  destroy; override;

    property    grid: cTableViewProxy read getGrid;
    property    count: integer read getCount;
    property    items[aIndex: integer]: cGridHeader read getItemByIndex;
  end;






  tHeadersRenderingEvent = procedure(aView: cTableViewProxy; aHeaders: cGridHeaders) of object;

  tModelHeaderRenderingEvent = procedure(aView: cTableViewProxy; aHeaders: cGridHeaders; aModelFields: cTableFields; aStartIndex: integer; aEndIndex: integer; aStartOffset: integer) of object;

  tModelRowRenderingEvent = procedure(aView: cTableViewProxy; aCellPainter: tKGridCellPainter; aModelRow: cAbstractTableRow; aRowStates: tKGridDrawState) of object;


  tTableViewProxyScrollDataEvent = procedure (aView: cTableViewProxy; aViewLeftCol: integer; aViewTopRow: integer; aViewRightCol: integer; aViewBottomRow: integer; aModel: cAbstractTableModel; aModelLeftCol: integer; aModelTopRow: integer; aModelRightCol: integer; aModelBottomRow: integer) of object;

  tTableViewProxyCanCreateEditorEvent = function (aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aDefaultCanCreateEditor: boolean): boolean of object;
  tTableViewProxyCreateEditorEvent = function (aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aType: tDataType): cAbstractEditableViewProxy of object;
  tTableViewProxyDestroyEditorEvent = procedure(aView:cTableViewProxy; aEditor: cAbstractEditableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aType: tDataType) of object;


  tTableViewProxyGetEditorDataEvent = procedure (aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aAssignedValue: variant) of object;
  tTableViewProxySetEditorDataEvent = procedure (aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aAssignedValue: variant) of object;

  tTableViewProxyUpdateEditorGeometryEvent = procedure (aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aRect: tRect) of object;

  tTableViewProxyCellCanEditEvent = procedure (aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aCanEdit: boolean) of object;

  tTableViewProxyCellClickEvent = procedure (aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aCanSortCol: boolean) of object;
  tTableViewProxyCellDblClickEvent = procedure (aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aCanEditCell: boolean) of object;
  tTableViewProxyCellSelectingEvent = procedure(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aCanSelect: boolean) of object;
  tTableViewProxyCellSelectedEvent = procedure(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer) of object;

  tTableViewProxyRenderingTextEvent = procedure(aView: cTableViewProxy; aRenderingModelRow: cAbstractTableRow; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aText: string) of object;

  tTableViewProxyCellHintEvent = procedure(aSender: tObject; aCol, aRow: integer; aShow: boolean) of object;

  tTableViewProxyState = (psBatchRowReloading, psDblClicked);

  tTableViewProxyStates = set of tTableViewProxyState;

  tTableViewProxyLocateCompareProc = function (aModelRow: integer; aText: string): boolean of object;

  tTableViewProxySelectedIteratorProc = reference to procedure (aViewRow: integer);
  tTableViewProxyCheckedIteratorProc = reference to procedure (aViewRow: integer);

  tTableViewProxyRenderedEvent = reference to procedure (aView: cTableViewProxy);

  tTableViewProxyModelAssignedEvent = procedure (aView: cTableViewProxy) of object;

  {$REGION 'forward declaration cAbstractTableViewProxyDelegate'}
  cAbstractTableViewProxyDelegatePrivate = type cAnyObject;
  {$ENDREGION}

  {$REGION 'forward declaration cTableViewProxyDataReplacerPrivate'}
  cTableViewProxyDataReplacerPrivate = type cAnyObject;
  {$ENDREGION}

  sTableViewProxyCell = record
    col: integer;
    row: integer;
  end;

  cTableViewProxy = class(cAbstractViewProxy)
  private
    const

    DEFAULT_COL_WIDTH = 100;

    FIELD_SORT_DIRECTION_MAP: array[low(tTableFieldSortDirection)..high(tTableFieldSortDirection)] of tKGridDrawState = (
      [], //dummy
      [gdRowsSortedUp],
      [gdRowsSortedDown]
    );

    STATE_STRING_MAP: array[low(tTableViewProxyState)..high(tTableViewProxyState)] of string = (
      'psBatchRowReloading', 'psDblClicked'
    );
  private
    fModel                    : cAbstractTableModel;
    fHeaders                  : cGridHeaders;

    fModelColumnMap           : cColumnMap;
    fViewColumnMap            : cColumnMap; //for delegates and

    fDelegates                : tDictionary<sTableViewProxyCell, cAbstractTableViewProxyDelegatePrivate>;
    fDataReplacers            : tDictionary<sTableViewProxyCell, cTableViewProxyDataReplacerPrivate>;

    fViewModelColStartOffset  : integer;
    fViewModelRowStartOffset  : integer;

    fEditorViewProxy          : cAbstractEditableViewProxy;

    fInitialEditorData        : variant;
    fDrawingModelRow          : cAbstractTableRow;
    fDrawingRow               : integer;
    fRendered                 : boolean;
    fSortable                 : boolean;
    fColSizing                : boolean;

    fEditable                 : boolean;

    fClickTimer               : cTimer;

    fPrevCellClicked          : tKGridCell;
    fPrevRowSelected          : integer;
    fColumnMapMoving          : boolean;

    fPrevDelegate             : cAbstractTableViewProxyDelegatePrivate;
    fPrevDelegateCol          : integer;
    fPrevDelegateRow          : integer;

    fPrevDataReplacer         : cTableViewProxyDataReplacerPrivate;
    fPrevDataReplacerCol      : integer;
    fPrevDataReplacerRow      : integer;

    fOnRendered               : tTableViewProxyRenderedEvent;
    fOnModelAssigned          : tTableViewProxyModelAssignedEvent;

    fOnHeadersRendering       : tHeadersRenderingEvent;
    fOnModelHeaderRendering   : tModelHeaderRenderingEvent;
    fOnModelRowRendering      : tModelRowRenderingEvent;
    fOnModelRowRenderingText  : tTableViewProxyRenderingTextEvent;
    fOnCreateEditor           : tTableViewProxyCreateEditorEvent;
    fOnDestroyEditor          : tTableViewProxyDestroyEditorEvent;
    fStates                   : tTableViewProxyStates;
    fOnGetEditorData          : tTableViewProxyGetEditorDataEvent;
    fOnSetEditorData          : tTableViewProxySetEditorDataEvent;
    fOnCellClick              : tTableViewProxyCellClickEvent;
    fOnCellDblClick           : tTableViewProxyCellDblClickEvent;
    fOnCellSelecting          : tTableViewProxyCellSelectingEvent;
    fOnCellSelected           : tTableViewProxyCellSelectedEvent;
    fOnCellHintEvent          : tTableViewProxyCellHintEvent;
    fOnCanCreateEditor        : tTableViewProxyCanCreateEditorEvent;
    fOnCellCanEdit            : tTableViewProxyCellCanEditEvent;
    fOnUpdateEditorGeometry   : tTableViewProxyUpdateEditorGeometryEvent;
    fOnScrollData             : tTableViewProxyScrollDataEvent;

    function    canEditModelCol(aCol: integer): boolean;
    procedure   clearSorting;

    procedure   beginColumnMapMoving;
    procedure   endColumnMapMoving;

    function    getCastedView: tKGrid;

    procedure   renderView(aOnlyData: boolean = false);
    function    isRendered: boolean;
    procedure   setRendered(aValue: boolean);

    procedure   setupColumnMapEvents;
    procedure   disconnectColumnMapEvents;

    procedure   setupModelEvents;
    procedure   disconnectModelEvents;

    procedure   setupViewEvents; override;
    procedure   disconnectViewEvents; override;

    procedure   createHeaderForModel;

    function    getHeaders: cGridHeaders;

    procedure   setViewModelOffsets;

    procedure   updateColumnsMapping;

    procedure   prepareView;

    function    getMaxRowFromHeaders: integer;
    function    getMaxColFromHeaders: integer;


    procedure   drawGridHeader(aSender: tObject; aCellPainter: tKGridCellPainter; aViewCol, aViewRow: integer; aRect: tRect; aStates: tKGridDrawState); inline;
    procedure   drawGridData(aSender: tObject; aCellPainter: tKGridCellPainter; const aFieldValue: variant; aViewCol, aViewRow: integer; aModelCol, aModelRow: integer; aRect: tRect; aStates: tKGridDrawState); inline;


    procedure   setViewFixedColCount(aCount: integer);
    function    getViewFixedColCount: integer;

    procedure   setViewFixedRowCount(aCount: integer);
    function    getViewFixedRowCount: integer;

    function    getViewCell(aViewCol, aViewRow: integer): tKGridCell;
    procedure   setViewCell(aViewCol, aViewRow: integer; aCell: tKGridCell);

    function    createViewHeaderCell: cGridHeaderCell;

    function    getViewColCount: integer;
    procedure   setViewColCount(aCount: integer);

    function    getViewRowCount: integer;
    procedure   setViewRowCount(aCount: integer);

    procedure   setViewCellSpan(aViewCol, aViewRow: integer; aColSpan, aRowSpan: integer);

    procedure   increaseViewCellsIfNeeded(aColCount: integer; aRowCount: integer);


    function    viewAppendRow: integer;
    procedure   viewDeleteRow;

    //syncronized with db
    function    modelAppendRow(aId: int64 = NEW_KEY_ID): integer;
    function    modelAppendRowToCache: integer;

    procedure   modelDeleteRow(aModelRow: integer);
    procedure   modelDeleteRowFromCache(aModelRow: integer);
    procedure   modelSetRowData(aModelCol, aModelRow: integer; aValue: variant);
    function    modelGetRowData(aModelCol, aModelRow: integer): variant;

    function    getViewIndexOfModelField(aName: string): integer;

    procedure   selectFirstRow;

    function    getDelegateForCell(aCol: integer; aRow: integer): cAbstractTableViewProxyDelegatePrivate;
    function    getDataReplacerForCell(aCol: integer; aRow: integer): cTableViewProxyDataReplacerPrivate;

    function    createEditor(aType: tDataType): cAbstractEditableViewProxy;
    procedure   destroyEditor(aEditor: cAbstractEditableViewProxy; aType: tDataType);

    procedure   removeDelegates;
    procedure   removeDataReplacers;

    function    initialViewColToViewCol(aInitialViewCol: integer): integer;
    function    viewColToInitialViewCol(aViewCol: integer): integer;
    function    getViewColumnMap: cColumnMap;
  public
    function    saveState: tBytesArray;
    function    restoreState(const aBytesArray: tBytesArray): boolean;

    procedure   setDefaultColsWidth;

    procedure   setColDelegate(aCol: integer; aDelegate: cAbstractTableViewProxyDelegatePrivate);
    procedure   setRowDelegate(aRow: integer; aDelegate: cAbstractTableViewProxyDelegatePrivate);
    procedure   setCellDelegate(aCol: integer; aRow: integer; aDelegate: cAbstractTableViewProxyDelegatePrivate);
    procedure   setDelegate(aDelegate: cAbstractTableViewProxyDelegatePrivate);

    procedure   setColDataReplacer(aCol: integer; aDataReplacer: cTableViewProxyDataReplacerPrivate);
    procedure   setRowDataReplacer(aRow: integer; aDataReplacer: cTableViewProxyDataReplacerPrivate);
    procedure   setCellDataReplacer(aCol: integer; aRow: integer; aDataReplacer: cTableViewProxyDataReplacerPrivate);


    procedure   sort(aViewCol: integer; aSortDirection: tTableFieldSortDirection);
    procedure   moveCol(aColFrom: integer; aColTo: integer);

    procedure   setColVisible(aCol: integer; aValue: boolean);
    function    isColVisible(aCol: integer): boolean;

    procedure   setRowVisible(aRow: integer; aValue: boolean);
    function    isRowVisible(aRow: integer): boolean;

    procedure   setHeadersVisible(aValue: boolean);

    procedure   setColSizing(aValue: boolean);

    procedure   setRowHeight(aRow: integer; aHeight: integer);
    function    getRowHeight(aRow: integer) : integer;

    procedure   setColWidth(aCol: integer; aWidth: integer);
    function    getColWidth(aCol: integer): integer;

    procedure   setHint(aHint: string); override;

    procedure   setFocusedRangeBgColor(aColor: tColor);override;
    procedure   setFocusedRangeTextColor(aColor: tColor); override;

    procedure   setFocusedBgColor(aColor: tColor); override;
    procedure   setFocusedTextColor(aColor: tColor); override;

    procedure   setSelectedBgColor(aColor: tColor); override;
    procedure   setSelectedTextColor(aColor: tColor); override;

    procedure   setSelectedRangeBgColor(aColor: tColor); override;
    procedure   setSelectedRangeTextColor(aColor: tColor); override;

    procedure   setCanTakeFocus(aValue: boolean); override;

    procedure   viewToggleCheck(aCol: integer; aRow: integer);

    function    getViewRowAt(aPoint: tPoint): integer;
    function    getViewColAt(aPoint: tPoint): integer;

    procedure   iterateSelectedRows(aSelectedIteratorProc: tTableViewProxySelectedIteratorProc);
    procedure   iterateCheckedRows(aCheckedIteratorProc: tTableViewProxyCheckedIteratorProc);

    function    locate(aText: string; aSearchDirection: tViewSearchDirection; aSearchPosition: tViewSearchPosition; aSearchType: tViewSearchType = stPartial): boolean; override;

    procedure   refreshView;

    function    getModelColumnMap: cColumnMap;

    function    viewColToModelCol(aViewCol: integer): integer; inline;

    function    viewRowToModelRow(aViewRow: integer): integer; inline;
    function    modelRowToViewRow(aModelRow: integer): integer; inline;

    function    modelColToViewCol(aModelCol: integer): integer;

    procedure   beginBatchRowReload;
    procedure   endBatchRowReload;

    function    getStates: tTableViewProxyStates;

    function    defaultCreateEditor(aType: tDataType): cAbstractEditableViewProxy;
    procedure   defaultDestroyEditor(aEditor: cAbstractEditableViewProxy; aType: tDataType);

    procedure   clear;
    function    isEmpty: boolean; override;
    function    getCheckedCount: integer; override;
    procedure   setViewRowChecked(aViewRow: integer; aChecked: boolean);
    function    getFirstVisibleCol: integer;

    procedure   selectionToCheck(aValue: boolean); override;

    procedure   selectViewCol(aViewCol: integer);
    procedure   selectViewRow(aViewRow: integer);

    function    getViewCol: integer;
    function    getViewRow: integer;

    procedure   edit(aViewCol, aViewRow: integer);
    procedure   disableEditing;
    procedure   enableEditing;
    procedure   cancelEditing;
    procedure   startEditing;


    procedure   setModel(aModel: cAbstractTableModel);
    procedure   setView(aView: tWinControl); override;

    procedure   setEditable(aValue: boolean);
    function    isEditable: boolean;

    procedure   setSortable(aValue: boolean);
    function    isSortable: boolean;


    procedure   render;

    function    getModel: cAbstractTableModel;

    constructor create;
    destructor  destroy;override;

    property    headers: cGridHeaders read getHeaders;
    property    model: cAbstractTableModel read getModel write setModel;
    property    modelColumnMap: cColumnMap read getModelColumnMap;
    property    viewColumnMap: cColumnMap read getViewColumnMap;
  public
    const
    CURRENT_VERSION                        = '1.0';

    INVALID_VERSION_FORMAT                 = 'invalid version, got: %s, expected: %s';

    MODEL_HEADER_NAME                      = 'modelHeader';

    VIEW_NOT_ASSIGNED                      = 'view not assigned';
    VIEW_NOT_RENDERED                      = 'view not rendered use render method!!!';

    MODEL_NOT_ASSIGNED                     = 'model not assigned';

    EDITOR_FOR_TYPE_NOT_SUPPORTED          = 'editor for type not supported';
    GET_EDITOR_DATA_FOR_TYPE_NOT_SUPPORTED = 'get editor data for type not supported';
    SET_EDITOR_DATA_FOR_TYPE_NOT_SUPPORTED = 'set editor data for type not supported';
    CANNOT_CHANGE_STATE                    = 'cannot change current state to: %s';
    CANNOT_SET_EDITABLE_VIEW_NOT_ASSIGNED  = 'cannot set editable, view not assigned';
  published
    //virtuals
    procedure   keyDown(aSender: tObject; var aKey: word; aShift: tShiftState); override;

    //SLOTS
    procedure   clickTimerTick(aSender: cTimer);

    procedure   columnMapColumnMoved(aColumnMap: cColumnMap; aFromIndex, aToIndex: integer);

    procedure   modelRowReloaded(aModel: cAbstractTableModel; aModelRow: integer);
    procedure   modelRowAppended(aModel: cAbstractTableModel; aModelRow: integer);
    procedure   modelRowDeleting(aModel: cAbstractTableModel; aModelRow: integer);
    procedure   modelDataChanged(aModel: cAbstractTableModel; aType: tAbstractTableModelDataChangedType);
    procedure   modelDataFetched(aModel: cAbstractTableModel);

    procedure   modelBeginRowsAppending(aModel: cAbstractTableModel);
    procedure   modelEndRowsAppending(aModel: cAbstractTableModel);

    procedure   modelBeginRowsDeleting(aModel: cAbstractTableModel);
    procedure   modelEndRowsDeleting(aModel: cAbstractTableModel);

    procedure   modelBeginRowsReloading(aModel: cAbstractTableModel);
    procedure   modelEndRowsReloading(aModel: cAbstractTableModel);

    procedure   viewLooseFocus(aSender: tObject);
    procedure   viewColumnMoved(aSender: tObject; aFromIndex, aToIndex: integer);
    procedure   viewDrawCell(aSender: tObject; aViewCol, aViewRow: integer; aRect: tRect; aState: tKGridDrawState);

    procedure   viewEditorCreate(aSender: tObject; aViewCol, aViewRow: integer; var aEditor: tWinControl);
    procedure   viewEditorDestroy(aSender: tObject; var aEditor: tWinControl; aViewCol,aViewRow: integer);

    procedure   editorDataToView(aSender: tObject; aEditor: tWinControl; aViewCol, aViewRow: integer; var assignText: boolean);
    procedure   viewDataToEditor(aSender: tObject; aEditor: tWinControl; aViewCol, aViewRow: integer; var assignText: boolean);


    procedure   viewCellClick(aSender: tObject; aViewCol, aViewRow: integer);
    procedure   viewCellDblClick(aSender: tObject; aViewCol, aViewRow: integer);

    procedure   viewCellSelecting(aSender: tObject; aViewCol, aViewRow: integer; var aCanSelect: boolean);
    procedure   viewCellSelected(aSender: tObject; aViewCol, aViewRow: integer);
    procedure   viewCellHint(aSender: tObject; aCol, aRow: integer; aShow: boolean);

    procedure   viewResizeEditor(aSender: tObject; aEditor: tWinControl; aCol, aRow: integer; var aRect: tRect);
    procedure   viewTopLeftChanged(aSender: tObject);
  published
    //EVENTS
    property    onModelAssigned: tTableViewProxyModelAssignedEvent read fOnModelAssigned write fOnModelAssigned;

    property    onRendered: tTableViewProxyRenderedEvent read fOnRendered write fOnRendered;

    property    onCellClick: tTableViewProxyCellClickEvent read fOnCellClick write fOnCellClick;
    property    onCellDblClick: tTableViewProxyCellDblClickEvent read fOnCellDblClick write fOnCellDblClick;
    property    onCellSelecting: tTableViewProxyCellSelectingEvent read fOnCellSelecting write fOnCellSelecting;
    property    onCellSelected: tTableViewProxyCellSelectedEvent read fOnCellSelected write fOnCellSelected;

    property    onScrollData: tTableViewProxyScrollDataEvent read fOnScrollData write fOnScrollData;

    property    onHeadersRendering: tHeadersRenderingEvent read fOnHeadersRendering write fOnHeadersRendering;

    property    onModelHeaderRendering: tModelHeaderRenderingEvent read fOnModelHeaderRendering write fOnModelHeaderRendering;
    property    onModelRowRendering: tModelRowRenderingEvent read fOnModelRowRendering write fOnModelRowRendering;
    property    onModelRowRenderingText: tTableViewProxyRenderingTextEvent read fOnModelRowRenderingText write fOnModelRowRenderingText;

    property    onGetEditorData: tTableViewProxyGetEditorDataEvent read fOnGetEditorData write fOnGetEditorData;
    property    onSetEditorData: tTableViewProxySetEditorDataEvent read fOnSetEditorData write fOnSetEditorData;

    property    onUpdateEditorGeometry: tTableViewProxyUpdateEditorGeometryEvent read fOnUpdateEditorGeometry write fOnUpdateEditorGeometry;

    property    onCellHint: tTableViewProxyCellHintEvent read fOnCellHintEvent write fOnCellHintEvent;
    property    onCanCreateEditor: tTableViewProxyCanCreateEditorEvent read fOnCanCreateEditor write fOnCanCreateEditor;
    property    onCellCanEdit: tTableViewProxyCellCanEditEvent read fOnCellCanEdit write fOnCellCanEdit;

    property    onCreateEditor: tTableViewProxyCreateEditorEvent read fOnCreateEditor write fOnCreateEditor;
    property    onDestroyEditor: tTableViewProxyDestroyEditorEvent read fOnDestroyEditor write fOnDestroyEditor;
  end;

implementation
uses
  clsAbstractTableViewProxyDelegate,
  clsTableViewProxyDataReplacer,
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

procedure cGridHeaders.clear;
begin
  fList.freeInternalObjects;
  fList.clear;
end;

constructor cGridHeaders.create(aGrid: cTableViewProxy);
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
    clear;
    freeAndNil(fList);
  end;

  inherited;
end;

function cGridHeaders.getCount: integer;
begin
  result:= fList.count;
end;

function cGridHeaders.getGrid: cTableViewProxy;
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

procedure cGridHeaderCell.setText(const aText: string);
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

function cColumnMap.getItemBySurrogateIndex(aSurrogateIndex: integer): cColumnMapItem;
var
  foundIndex: integer;
begin
  result:= nil;
  foundIndex:= indexOfSurrogateIndex(aSurrogateIndex);

  if foundIndex = -1 then begin
    exit;
  end;

  result:= items[foundIndex];
end;

function cColumnMap.indexOfSurrogateIndex(aSurrogateIndex: integer): integer;
var
  i: integer;
  curItem: cColumnMapItem;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];

    if (curItem.getSurrogateIndex = aSurrogateIndex) then begin
      result:= i;
      exit;
    end;

  end;
end;

procedure cColumnMap.moveTo(aFromIndex, aToIndex: integer);
begin
  fList.move(aFromIndex, aToIndex);

  if assigned(fOnColumnMoved) then begin
    fOnColumnMoved(self, aFromIndex, aToIndex);
  end;
end;

{ cColumnMapItem }

constructor cColumnMapItem.create(aModelIndex: integer);
begin
  inherited create;
  fSurrogateIndex:= aModelIndex;
end;

function cColumnMapItem.getSurrogateIndex: integer;
begin
  result:= fSurrogateIndex;
end;

procedure cColumnMapItem.setSurrogateIndex(aSurrogateIndex: integer);
begin
  fSurrogateIndex:= aSurrogateIndex;
end;

{ cTableViewProxy }

procedure cTableViewProxy.prepareView;
begin
  clear;

  getCastedView.cellClass := cGridCell;

  getCastedView.doubleBuffered:= true;
  getCastedView.options:= getCastedView.options + [goColMoving] + [goColSizing] + [goRowSelect];

  getCastedView.optionsEx:= getCastedView.optionsEx + [gxEnterWraps] + [gxTabWraps];

  setSelectedBgColor(getSelectedBgColor);
  setSelectedTextColor(getSelectedTextColor);

  setFocusedBgColor(getFocusedBgColor);
  setFocusedTextColor(getFocusedTextColor);

  setSelectedRangeBgColor(getSelectedRangeBgColor);
  setSelectedRangeTextColor(getSelectedRangeTextColor);

  setFocusedRangeBgColor(getFocusedRangeBgColor);
  setFocusedRangeTextColor(getFocusedRangeTextColor);

  getCastedView.popupMenu:= getPopupMenu;

  setEditable(fEditable);

  setSortable(fSortable);

  setColSizing(fColSizing);
end;

procedure cTableViewProxy.viewToggleCheck(aCol, aRow: integer);
var
  fieldValue: variant;
  modelCol, modelRow: integer;
begin
  modelCol:= viewColToModelCol(aCol);
  modelRow:= viewRowToModelRow(aRow);

  if (modelCol < 0) or (modelRow < 0) then begin
    exit;
  end;

  if (not isEditable) and (modelCol <> fModel.getFields.getSelectorFieldIndex) then begin
    exit;
  end;



  fieldValue:= fModel.getFieldData(modelCol, modelRow);


  if (fModel.getFieldType(modelCol) = dtBoolean) then begin
    modelSetRowData(modelCol, modelRow, not cVariantConversion.varToBool(fieldValue));
  end;

  refreshView;
end;

function cTableViewProxy.viewRowToModelRow(aViewRow: integer): integer;
begin
  result:= aViewRow - getCastedView.fixedRows;
end;

procedure cTableViewProxy.viewCellSelected(aSender: tObject; aViewCol, aViewRow: integer);
begin
  if assigned(fOnCellSelected) and (aViewRow <> fPrevRowSelected) then begin
    fOnCellSelected(self, aViewCol, aViewRow, fModel, viewColToModelCol(aViewCol), viewRowToModelRow(aViewRow));
  end;

  if assigned(fOnScrollData) then begin
    fOnScrollData(
      self,
      getCastedView.visibleGridRect.col1,
      getCastedView.visibleGridRect.row1,
      getCastedView.visibleGridRect.col2,
      aViewRow,

      fModel,
      viewColToModelCol(getCastedView.visibleGridRect.col1),
      viewRowToModelRow(getCastedView.visibleGridRect.row1),
      viewColToModelCol(getCastedView.visibleGridRect.col2),
      viewRowToModelRow(aViewRow)
    );
  end;

  fPrevRowSelected:= aViewRow;
end;

procedure cTableViewProxy.viewCellSelecting(aSender: tObject; aViewCol, aViewRow: integer; var aCanSelect: boolean);
begin
  if (assigned(fOnCellSelecting))  then begin
    fOnCellSelecting(self, aViewCol, aViewRow, fModel, viewColToModelCol(aViewCol), viewRowToModelRow(aViewRow), aCanSelect);
  end;
end;

procedure cTableViewProxy.viewCellHint(aSender: tObject; aCol, aRow: integer; aShow: boolean);
begin
  if assigned(fOnCellHintEvent) then begin
    fOnCellHintEvent(self, aCol, aRow, aShow);
  end;
end;

procedure cTableViewProxy.viewResizeEditor(aSender: tObject; aEditor: tWinControl; aCol, aRow: integer; var aRect: tRect);
var
  modelCol, modelRow: integer;

  surrogateViewCol: integer;
  delegate: cAbstractTableViewProxyDelegate;
begin
  if (not isEditable) then begin
    exit;
  end;

  modelCol:= viewColToModelCol(aCol);
  modelRow:= viewRowToModelRow(aRow);

  if (not(assigned(fEditorViewProxy))) then begin
    exit;
  end;

  surrogateViewCol:= fViewColumnMap.getItemByIndex(aCol).getSurrogateIndex;
  delegate:= getDelegateForCell(surrogateViewCol, aRow);

  if assigned(delegate) then begin
    delegate.updateEditorGeometry(self, aCol, aRow, fModel, modelCol, modelRow, fEditorViewProxy, aRect);
  end else begin
    if (assigned(fOnUpdateEditorGeometry)) then begin
      fOnUpdateEditorGeometry(self, aCol, aRow, fModel, modelCol, modelRow, fEditorViewProxy, aRect);
    end;
  end;
end;

procedure cTableViewProxy.viewTopLeftChanged(aSender: tObject);
begin
  if not (assigned(fView) and assigned(fModel)) then exit;

  if not isRendered then exit;


  if assigned(fOnScrollData) then begin
    fOnScrollData(
      self,
      getCastedView.visibleGridRect.col1,
      getCastedView.visibleGridRect.row1,
      getCastedView.visibleGridRect.col2,
      getCastedView.visibleGridRect.row2,

      fModel,
      viewColToModelCol(getCastedView.visibleGridRect.col1),
      viewRowToModelRow(getCastedView.visibleGridRect.row1),
      viewColToModelCol(getCastedView.visibleGridRect.col2),
      viewRowToModelRow(getCastedView.visibleGridRect.row2)
    );
  end;
end;

function cTableViewProxy.modelAppendRow(aId: int64): integer;
begin
  result:= fModel.appendRow(aId);
end;

function cTableViewProxy.modelAppendRowToCache: integer;
begin
  result:= fModel.appendRowToCache;
end;

procedure cTableViewProxy.modelBeginRowsAppending(aModel: cAbstractTableModel);
begin
  getCastedView.lockUpdate;
end;

procedure cTableViewProxy.modelBeginRowsDeleting(aModel: cAbstractTableModel);
begin
  getCastedView.lockUpdate;
end;

procedure cTableViewProxy.modelBeginRowsReloading(aModel: cAbstractTableModel);
begin
  getCastedView.lockUpdate;
end;

function cTableViewProxy.modelColToViewCol(aModelCol: integer): integer;
var
  i: integer;
  columnMapItem: cColumnMapItem;
begin
  result:= 0;
  for i:= 0 to fModelColumnMap.count - 1 do begin
    columnMapItem:= fModelColumnMap.items[i];
    if (columnMapItem.getSurrogateIndex = aModelCol) then begin
      result:= i;
    end;
  end;
end;

function cTableViewProxy.initialViewColToViewCol(aInitialViewCol: integer): integer;
begin
  result:= fViewColumnMap.items[aInitialViewCol].getSurrogateIndex;
end;

function cTableViewProxy.viewColToInitialViewCol(aViewCol: integer): integer;
var
  i: integer;
  columnMapItem: cColumnMapItem;
begin
  result:= 0;
  for i:= 0 to fViewColumnMap.count - 1 do begin
    columnMapItem:= fViewColumnMap.items[i];
    if (columnMapItem.getSurrogateIndex = aViewCol) then begin
      result:= i;
    end;
  end;
end;

procedure cTableViewProxy.modelDataChanged(aModel: cAbstractTableModel; aType: tAbstractTableModelDataChangedType);
begin
  if (not(assigned(view))) then exit;

  refreshView;
end;

procedure cTableViewProxy.modelDataFetched(aModel: cAbstractTableModel);
begin
  renderView(true);
end;

procedure cTableViewProxy.modelDeleteRow(aModelRow: integer);
begin
  fModel.deleteRow(aModelRow);
end;

procedure cTableViewProxy.modelDeleteRowFromCache(aModelRow: integer);
begin
  fModel.deleteRowFromCache(aModelRow);
end;

procedure cTableViewProxy.modelEndRowsAppending(aModel: cAbstractTableModel);
begin
  getCastedView.unlockUpdate;
end;

procedure cTableViewProxy.modelEndRowsDeleting(aModel: cAbstractTableModel);
begin
  getCastedView.unlockUpdate;
end;

procedure cTableViewProxy.modelEndRowsReloading(aModel: cAbstractTableModel);
begin
  getCastedView.unlockUpdate;
end;

function cTableViewProxy.modelGetRowData(aModelCol, aModelRow: integer): variant;
begin
  result:= fModel.getFieldData(aModelCol, aModelRow);
end;

procedure cTableViewProxy.modelRowAppended(aModel: cAbstractTableModel; aModelRow: integer);
begin
  if (not(assigned(view))) then exit;

  if (aModel.getRowCount <> 1) then begin //in view by default more than 0 rows
    viewAppendRow;
  end;
end;

procedure cTableViewProxy.modelRowDeleting(aModel: cAbstractTableModel; aModelRow: integer);
begin
  if (not(assigned(view))) then exit;

  viewDeleteRow;
end;

procedure cTableViewProxy.modelRowReloaded(aModel: cAbstractTableModel; aModelRow: integer);
begin
  if (not(assigned(view))) then exit;

  refreshView;
end;

function cTableViewProxy.modelRowToViewRow(aModelRow: integer): integer;
begin
  result:= aModelRow + getCastedView.fixedRows;
end;

procedure cTableViewProxy.modelSetRowData(aModelCol, aModelRow: integer; aValue: variant);
begin
  fModel.setFieldData(aModelCol, aModelRow, aValue);
end;

procedure cTableViewProxy.moveCol(aColFrom, aColTo: integer);
begin
  if not assigned(fView) then begin
    exit;
  end;

  getCastedView.moveCol(aColFrom, aColTo);
end;

procedure cTableViewProxy.viewCellClick(aSender: tObject; aViewCol, aViewRow: integer);
const
  FIELD_INVERT_SORT_DIRECTION: array[low(tTableFieldSortDirection)..high(tTableFieldSortDirection)] of tTableFieldSortDirection =
    (
      sdAsc, sdDesc, sdNone
    );
var
  curCell: tKGridCell;

  tableField: cTableField;

  modelCol, modelRow: integer;
  canSortCol: boolean;

  cellCanEdit: boolean;
begin
  fClickTimer.singleShot(4 * SECOND, self, 'clickTimerTick');

  curCell:= getCastedView.cell[aViewCol, aViewRow];

  modelCol:= viewColToModelCol(aViewCol);
  modelRow:= viewRowToModelRow(aViewRow);

  cellCanEdit:= canEditModelCol(modelCol);

  if assigned(fOnCellCanEdit) then begin
    fOnCellCanEdit(self, aViewCol, aViewRow, fModel, modelCol, modelRow, cellCanEdit);
  end;

  if (cellCanEdit) and ((modelRow >=0) and (modelCol >= 0) and (fPrevCellClicked = curCell)) then begin
    startEditing;
  end;

  fPrevCellClicked:= curCell;

  if (cellCanEdit) then begin
    viewToggleCheck(aViewCol, aViewRow);
  end;

  canSortCol:= true;
  if assigned(fOnCellClick) then begin
    fOnCellClick(self, aViewCol, aViewRow, fModel, modelCol, modelRow, canSortCol);
  end;

  canSortCol:= canSortCol and isSortable;

  if (not assigned(fEditorViewProxy)) and (canSortCol) and (curCell is cGridHeaderCell) then begin
    tableField:= fModel.getFields.items[modelCol];
    sort(aViewCol, FIELD_INVERT_SORT_DIRECTION[tableField.sortDirection]);
  end;

end;

procedure cTableViewProxy.sort(aViewCol: integer; aSortDirection: tTableFieldSortDirection);
var
  tableField: cTableField;
begin
  tableField:= fModel.getFields.items[viewColToModelCol(aViewCol)];
  tableField.sortDirection:= aSortDirection;

  refreshView;
end;

procedure cTableViewProxy.viewCellDblClick(aSender: tObject; aViewCol, aViewRow: integer);
var
  modelCol, modelRow: integer;
  canEditRow: boolean;
begin
  fPrevCellClicked:= nil;

  modelCol:= viewColToModelCol(aViewCol);
  modelRow:= viewRowToModelRow(aViewRow);

  canEditRow:= true;
  if assigned(fOnCellDblClick) then begin
    fOnCellDblClick(self, aViewCol, aViewRow, fModel, modelCol, modelRow, canEditRow);

    if not canEditRow then begin
      cancelEditing;
    end;
  end;
end;

procedure cTableViewProxy.beginBatchRowReload;
begin
  if (fStates <> []) then begin
    raise eTableViewProxy.createFmt(CANNOT_CHANGE_STATE, [STATE_STRING_MAP[psBatchRowReloading]]);
  end;

  fStates:= fStates + [psBatchRowReloading];
end;

procedure cTableViewProxy.enableEditing;
begin
end;

procedure cTableViewProxy.endBatchRowReload;
begin
  fStates:= fStates - [psBatchRowReloading];
  refreshView;
end;

procedure cTableViewProxy.endColumnMapMoving;
begin
  fColumnMapMoving:= false;
end;

function cTableViewProxy.getCheckedCount: integer;
var
  count: integer;
begin
  result:= 0;
  count:= 0;

  if (not(assigned(view))) then exit;

  iterateCheckedRows(
    procedure(aViewRow: integer)
    begin
      inc(count);
    end
  );

  result:= count;
end;

function cTableViewProxy.getModelColumnMap: cColumnMap;
begin
  result:= fModelColumnMap;
end;

function cTableViewProxy.getViewColumnMap: cColumnMap;
begin
  result:= fViewColumnMap;
end;

function cTableViewProxy.getColWidth(aCol: integer): integer;
begin
  result:= 0;
  if (not(assigned(view))) then begin
    exit;
  end;

  result:= getCastedView.colWidths[aCol];
end;

function cTableViewProxy.getStates: tTableViewProxyStates;
begin
  result:= fStates;
end;

procedure cTableViewProxy.beginColumnMapMoving;
begin
  fColumnMapMoving:= true;
end;

procedure cTableViewProxy.cancelEditing;
begin
  getCastedView.editorMode:= false;
end;

function cTableViewProxy.canEditModelCol(aCol: integer): boolean;
begin
  result:= isEditable and getModel.colCanEdit(aCol);
end;

procedure cTableViewProxy.clear;
begin
  if (not(assigned(view))) then exit;

  getCastedView.clearGrid;
  getCastedView.fixedCols := 0;
//  getCastedView.colCount  := 1;

  getCastedView.fixedRows := 0;
  getCastedView.rowCount  := 1;
  getCastedView.defaultColWidth:= 64;
end;

procedure cTableViewProxy.clearSorting;
begin
  if (not assigned(fModel)) then begin
    exit;
  end;

  if (not assigned(fView)) then begin
    exit;
  end;

  fModel.getFields.clearSort;

  refreshView;
end;

procedure cTableViewProxy.clickTimerTick(aSender: cTimer);
begin
  fPrevCellClicked:= nil;
end;

procedure cTableViewProxy.columnMapColumnMoved(aColumnMap: cColumnMap; aFromIndex, aToIndex: integer);
begin
  if (fColumnMapMoving) then begin
    exit;
  end;

  beginColumnMapMoving;
  try
    moveCol(aFromIndex, aToIndex);
  finally
    endColumnMapMoving;
  end;
end;

procedure cTableViewProxy.viewLooseFocus(aSender: tObject);
begin
  fPrevCellClicked:= nil;
end;

constructor cTableViewProxy.create;
begin
  inherited create;

  fColumnMapMoving := false;

  fEditable        := true;

  fStates          := [];

  fModelColumnMap  := cColumnMap.create;
  fViewColumnMap   := cColumnMap.create;
  fHeaders         := cGridHeaders.create(self);

  fViewModelColStartOffset:= -1;
  fViewModelRowStartOffset:= -1;

  fPrevDelegateCol   := -1;
  fPrevDelegateRow   := -1;
  fPrevDelegate      := nil;

  fPrevDataReplacerCol   := -1;
  fPrevDataReplacerRow   := -1;
  fPrevDataReplacer      := nil;

  fDrawingModelRow   := nil;
  fEditorViewProxy   := nil;

  fPrevCellClicked   := nil;
  fPrevRowSelected   := -1;

  fDelegates := tDictionary<sTableViewProxyCell, cAbstractTableViewProxyDelegatePrivate>.create;
  fDataReplacers := tDictionary<sTableViewProxyCell, cTableViewProxyDataReplacerPrivate>.create;

  fClickTimer:= cTimer.create;

  setSortable(false);
  setEditable(true);

  setColSizing(true);

  setSelectedBgColor(clBtnFace);
  setSelectedTextColor(clBlack);
  setFocusedBgColor(clHighlight);
  setFocusedTextColor(clWhite);

  setSelectedRangeBgColor(clBtnFace);
  setSelectedRangeTextColor(clBlack);
  setFocusedRangeBgColor(clBtnFace);
  setFocusedRangeTextColor(clBlack);

  setSelectedFramePenWidth(1);
  setSelectedFramePenColor(clBlack);
  setSelectedFramePenStyle(psClear);

  setCanDrawFrameSelected(true);

  setCanTakeFocus(true);

  setupColumnMapEvents;
end;

function cTableViewProxy.isEmpty: boolean;
begin
  result:= false;

  if not assigned(fModel) then begin
    exit;
  end;

  result:= fModel.getRowCount = 0;
end;

function cTableViewProxy.createEditor(aType: tDataType): cAbstractEditableViewProxy;
var
  surrogateViewCol: integer;
  delegate: cAbstractTableViewProxyDelegate;
begin
  result:= nil;

  surrogateViewCol:= fViewColumnMap.getItemByIndex(getViewCol).getSurrogateIndex;
  delegate:= getDelegateForCell(surrogateViewCol, getViewRow);

  if assigned(delegate) then begin
    result:= delegate.createEditor(self, getViewCol, getViewRow, fModel, viewColToModelCol(getViewCol), viewRowToModelRow(getViewRow), aType);
    exit;
  end else begin
    if (assigned(fOnCreateEditor)) then begin
      result:= fOnCreateEditor(self, getViewCol, getViewRow, fModel, viewColToModelCol(getViewCol), viewRowToModelRow(getViewRow), aType);
      exit;
    end;
  end;

  result:= defaultCreateEditor(aType);
end;

function cTableViewProxy.defaultCreateEditor(aType: tDataType): cAbstractEditableViewProxy;
var
  relation: cRelation;

  comboBoxProxy: cComboBoxViewProxy;
begin
  result:= nil;

  relation:= fModel.getRelation(viewColToModelCol(getViewCol));

  if assigned(relation) then begin

    comboBoxProxy:= cComboBoxViewProxy.create;

    comboBoxProxy.setView(tComboBox.createParented(getView.handle));
    comboBoxProxy.setModel(relation.getTableModel);
    comboBoxProxy.setDisplayModelCol(relation.getDisplayValueFieldIndex);
    comboBoxProxy.setEditable(false);

    result:= comboBoxProxy;
  end else begin


    case aType of

      dtNotSupported: begin
        raise eTableViewProxy.create(EDITOR_FOR_TYPE_NOT_SUPPORTED);
      end;

      dtBoolean  : begin
        result:= cCheckBoxViewProxy.create;

        result.setView(tCheckBox.create(nil));
      end;

      dtInteger, dtInt64, dtExtended, dtCurrency  : begin
        result:= cEditButtonViewProxy.create;

        result.setView(tButtonedEdit.create(nil));
        result.setValidator(cExtendedValidator.create);
      end;

      dtDateTime : begin
        result:= cDateTimePickerViewProxy.create;

        result.setView(tDateTimePicker.create(nil));
      end;

      dtString   : begin
        result:= cEditButtonViewProxy.create;

        result.setView(tButtonedEdit.create(nil));
      end;
    end;

  end;
end;


procedure cTableViewProxy.createHeaderForModel;
var
  modelHeader: cGridHeader;
  headerRow: integer;
  i: integer;
  modelFields: cTableFields;
begin
  fHeaders.clear;

  modelFields:= fModel.getFields;
  headerRow:= getMaxRowFromHeaders + 1;

  if (assigned(fOnModelHeaderRendering)) then begin
    fOnModelHeaderRendering(self, fHeaders, modelFields, headerRow, headerRow, fViewModelColStartOffset);
  end else begin
    modelHeader:= fHeaders.createHeader(htHorizontal, headerRow, headerRow, MODEL_HEADER_NAME);
    for i:= 0 to modelFields.count - 1 do begin
      modelHeader.data(i + fViewModelColStartOffset, 0).setText(modelFields.items[i].title);
    end;

  end;

end;

procedure cTableViewProxy.setViewCellSpan(aViewCol, aViewRow, aColSpan, aRowSpan: integer);
begin
  getCastedView.cellSpan[aViewCol, aViewRow]:= makeCellSpan(aColSpan, aRowSpan);
end;

function cTableViewProxy.createViewHeaderCell: cGridHeaderCell;
begin
  result:= cGridHeaderCell.create(getCastedView);
end;

procedure cTableViewProxy.removeDelegates;
var
  curDelegate: cAbstractTableViewProxyDelegate;
  curPair: tPair<sTableViewProxyCell, cAbstractTableViewProxyDelegatePrivate>;
begin
  if assigned(fDelegates) then begin
    for curPair in fDelegates do begin
      curDelegate:= curPair.value;
      freeAndNil(curDelegate);
    end;

    freeAndNil(fDelegates);
  end;
end;

procedure cTableViewProxy.removeDataReplacers;
var
  curDataReplacer: cTableViewProxyDataReplacer;
  curPair: tPair<sTableViewProxyCell, cTableViewProxyDataReplacerPrivate>;
begin
  if assigned(fDataReplacers) then begin
    for curPair in fDataReplacers do begin
      curDataReplacer:= curPair.value;
      freeAndNil(curDataReplacer);
    end;

    freeAndNil(fDataReplacers);
  end;
end;

destructor cTableViewProxy.destroy;
begin
  //remove any pending events
  clear;

  disconnectColumnMapEvents;

  disconnectModelEvents;

  removeDelegates;

  removeDataReplacers;

  if assigned(fClickTimer) then begin
    freeAndNil(fClickTimer);
  end;

  if assigned(fHeaders) then begin
    freeAndNil(fHeaders);
  end;

  if assigned(fModelColumnMap) then begin
    freeAndNil(fModelColumnMap);
  end;

  if assigned(fViewColumnMap) then begin
    freeAndNil(fViewColumnMap);
  end;

  inherited;
end;

procedure cTableViewProxy.destroyEditor(aEditor: cAbstractEditableViewProxy; aType: tDataType);
var
  surrogateViewCol: integer;
  delegate: cAbstractTableViewProxyDelegate;
begin
  surrogateViewCol:= fViewColumnMap.getItemByIndex(getViewCol).getSurrogateIndex;
  delegate:= getDelegateForCell(surrogateViewCol, getViewRow);

  if assigned(delegate) then begin
    delegate.destroyEditor(self, aEditor, getViewCol, getViewRow, fModel, viewColToModelCol(getViewCol), viewRowToModelRow(getViewRow), aType);
    exit;
  end else begin
    if (assigned(fOnDestroyEditor)) then begin
      fOnDestroyEditor(self, aEditor, getViewCol, getViewRow, fModel, viewColToModelCol(getViewCol), viewRowToModelRow(getViewRow), aType);
      exit;
    end;
  end;

  defaultDestroyEditor(aEditor, aType);
end;

procedure cTableViewProxy.defaultDestroyEditor(aEditor: cAbstractEditableViewProxy; aType: tDataType);
var
  editorView: tWinControl;
begin
  if (aType = dtNotSupported) then begin
    raise eTableViewProxy.create(EDITOR_FOR_TYPE_NOT_SUPPORTED);
  end;

  if (not(assigned(fEditorViewProxy))) then begin
    exit;
  end;

//  fEditableViewProxy.setView(nil);

  editorView:= fEditorViewProxy.getView;
  if assigned(editorView) then begin
    //freeAndNil(editorView); autofree in KGrid
  end;

  freeAndNil(fEditorViewProxy);
end;

procedure cTableViewProxy.setupColumnMapEvents;
begin
  connect(fModelColumnMap, 'onColumnMoved', self, 'columnMapColumnMoved');
end;

procedure cTableViewProxy.setDefaultColsWidth;
var
  i: integer;
begin
  for i:= 0 to getViewColCount - 1 do begin
    setColWidth(i, DEFAULT_COL_WIDTH);
  end;
end;

procedure cTableViewProxy.setDelegate(aDelegate: cAbstractTableViewProxyDelegatePrivate);
begin
  setCellDelegate(-1, -1, aDelegate);
end;

procedure cTableViewProxy.setupModelEvents;
begin
  if (not assigned(model)) then exit;

  connect(fModel, 'onDataFetched', self, 'modelDataFetched');

  connect(fModel, 'onRowReloaded', self, 'modelRowReloaded');
  connect(fModel, 'onRowAppended', self, 'modelRowAppended');
  connect(fModel, 'onRowDeleting', self, 'modelRowDeleting');
  connect(fModel, 'onDataChanged', self, 'modelDataChanged');

  connect(fModel, 'onBeginRowsAppending', self, 'modelBeginRowsAppending');
  connect(fModel, 'onEndRowsAppending', self, 'modelEndRowsAppending');

  connect(fModel, 'onBeginRowsDeleting', self, 'modelBeginRowsDeleting');
  connect(fModel, 'onEndRowsDeleting', self, 'modelEndRowsDeleting');

  connect(fModel, 'onBeginRowsReloading', self, 'modelBeginRowsReloading');
  connect(fModel, 'onEndRowsReloading', self, 'modelEndRowsReloading');
end;

procedure cTableViewProxy.setupViewEvents;
begin
  inherited setupViewEvents;

  if (not assigned(view)) then exit;

  connect(view, 'onDrawCell', self, 'viewDrawCell');
  connect(view, 'onMouseClickCell', self, 'viewCellClick');
  connect(view, 'onMouseDblClickCell', self, 'viewCellDblClick');
  connect(view, 'onColumnMoved', self, 'viewColumnMoved');

  connect(view, 'onSelectCell', self, 'viewCellSelecting');
  connect(view, 'onSelectedCell', self, 'viewCellSelected');

  connect(view, 'onEditorCreate', self, 'viewEditorCreate');
  connect(view, 'onEditorDestroy', self, 'viewEditorDestroy');
  connect(view, 'onEditorDataFromGrid', self, 'viewDataToEditor');
  connect(view, 'onEditorDataToGrid', self, 'editorDataToView');
  connect(view, 'onEditorResize', self, 'viewResizeEditor');

  connect(view, 'onMouseCellHint', self, 'viewCellHint');
  connect(view, 'onExit', self, 'viewLooseFocus');
  connect(view, 'onTopLeftChanged', self, 'viewTopLeftChanged');
end;

procedure cTableViewProxy.disableEditing;
begin
  getCastedView.options:= getCastedView.options - [goEditing];
end;

procedure cTableViewProxy.disconnectColumnMapEvents;
begin
  disconnect(fModelColumnMap, 'onColumnMoved', self, 'columnMapColumnMoved');
end;

procedure cTableViewProxy.disconnectModelEvents;
begin
  if (not assigned(model)) then exit;

  disconnect(fModel, 'onDataFetched', self, 'modelDataFetched');
  disconnect(fModel, 'onRowReloaded', self, 'modelRowReloaded');
  disconnect(fModel, 'onRowAppended', self, 'modelRowAppended');
  disconnect(fModel, 'onRowDeleting', self, 'modelRowDeleting');
  disconnect(fModel, 'onDataChanged', self, 'modelDataChanged');

  disconnect(fModel, 'onBeginRowsAppending', self, 'modelBeginRowsAppending');
  disconnect(fModel, 'onEndRowsAppending', self, 'modelEndRowsAppending');

  disconnect(fModel, 'onBeginRowsDeleting', self, 'modelBeginRowsDeleting');
  disconnect(fModel, 'onEndRowsDeleting', self, 'modelEndRowsDeleting');

  disconnect(fModel, 'onBeginRowsReloading', self, 'modelBeginRowsReloading');
  disconnect(fModel, 'onEndRowsReloading', self, 'modelEndRowsReloading');
end;

procedure cTableViewProxy.disconnectViewEvents;
begin
  inherited disconnectViewEvents;

  if (not assigned(view)) then exit;

  disconnect(view, 'onDrawCell', self, 'viewDrawCell');
  disconnect(view, 'onMouseClickCell', self, 'viewCellClick');
  disconnect(view, 'onMouseDblClickCell', self, 'viewCellDblClick');
  disconnect(view, 'onColumnMoved', self, 'viewColumnMoved');

  disconnect(view, 'onSelectCell', self, 'viewCellSelecting');
  disconnect(view, 'onSelectedCell', self, 'viewCellSelected');

  disconnect(view, 'onEditorCreate', self, 'viewEditorCreate');
  disconnect(view, 'onEditorDestroy', self, 'viewEditorDestroy');
  disconnect(view, 'onEditorDataFromGrid', self, 'viewDataToEditor');
  disconnect(view, 'onEditorDataToGrid', self, 'editorDataToView');
  disconnect(view, 'onEditorResize', self, 'viewResizeEditor');

  disconnect(view, 'onMouseCellHint', self, 'viewCellHint');
  disconnect(view, 'onExit', self, 'viewLooseFocus');
  disconnect(view, 'onTopLeftChanged', self, 'viewTopLeftChanged');
end;

procedure cTableViewProxy.refreshView;
begin
  if (not(assigned(view))) then exit;

  if (fStates <> []) then exit;

  view.invalidate;
end;

procedure cTableViewProxy.renderView(aOnlyData: boolean);
var
  storedRowIndex: integer;
  storedColIndex: integer;
begin
  if (not(assigned(view))) then exit;

  storedRowIndex:= getViewRow;
  storedColIndex:= getViewCol;

  if (not aOnlyData) then begin
    clear;

    //setup other header must be defined here
    if assigned(fOnHeadersRendering) then begin
      fOnHeadersRendering(self, fHeaders);
    end;
    //

    setViewColCount(getMaxColFromHeaders + 1 + fModel.getFields.count);
    setViewModelOffsets;

    createHeaderForModel;
    updateColumnsMapping;
  end;

  if (fModel.getRowCount = 0) then begin
    setViewRowCount(getMaxRowFromHeaders + 1 + 1);
  end else begin
    setViewRowCount(getMaxRowFromHeaders + 1 + fModel.getRowCount);
  end;

  fDrawingModelRow:= nil;

  selectFirstRow;

  setRendered(true);

  refreshView;

  selectViewRow(min(storedRowIndex, getViewRowCount - 1));
  selectViewCol(min(storedColIndex, getViewColCount - 1));
end;

function cTableViewProxy.restoreState(const aBytesArray: tBytesArray): boolean;
var
  i: integer;
  curModelColumnMapItem: cColumnMapItem;
  curField: cTableField;
  curFieldSortDirection: tTableFieldSortDirection;


  surrogateModelIndex: integer;

  colWidth: integer;

  viewColCount: integer;
  modelFieldsCount: integer;
  modelColumnMapCount: integer;

  modelColumnMapModelIndex: integer;

  integerList: cIntegerList;

  dataStream: cMemory;

  version: ansiString;
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
      raise eTableViewProxy.createFmt(INVALID_VERSION_FORMAT, [version, CURRENT_VERSION]);
    end;


    integerList:= cIntegerList.create;
    try

      dataStream.readInteger(modelColumnMapCount);
      for i:= 0 to modelColumnMapCount - 1 do begin
        curModelColumnMapItem:= fModelColumnMap.items[i];

        dataStream.readInteger(surrogateModelIndex);

        integerList.add(surrogateModelIndex);
      end;

      for i := 0 to modelColumnMapCount - 1 do begin
        modelColumnMapModelIndex:= integerList.items[i];
        moveCol(fModelColumnMap.indexOfSurrogateIndex(modelColumnMapModelIndex), integerList.indexOf(modelColumnMapModelIndex));
      end;


    finally
      freeAndNil(integerList);
    end;


    dataStream.readInteger(viewColCount);
    for i:= 0 to viewColCount - 1 do begin
      dataStream.readInteger(colWidth);

      setColWidth(i, colWidth);
    end;

    dataStream.readInteger(modelFieldsCount);
    if (not isSortable) then begin
      clearSorting;
    end else begin
      for i:= 0 to modelFieldsCount - 1 do begin
        curField:= model.getFields.items[i];

        dataStream.read(curFieldSortDirection, sizeOf(curFieldSortDirection));
        curField.sortDirection:= curFieldSortDirection;
      end;
    end;

    refreshView;

    result:= true;
  finally
    freeAndNil(dataStream);
  end;
end;

procedure cTableViewProxy.viewDrawCell(aSender: tObject; aViewCol, aViewRow: integer; aRect: tRect; aState: tKGridDrawState);
var
  modelCol: integer;
  modelRow: integer;
begin
  if (not(isRendered)) then begin
    raise eTableViewProxy.create(VIEW_NOT_RENDERED);
  end;

  if (gdFixed in aState) then begin
    drawGridHeader(
      aSender,
      getCastedView.cellPainter,
      aViewCol, aViewRow,
      aRect,
      aState
    );
  end else begin
    modelCol:= viewColToModelCol(aViewCol);
    modelRow:= viewRowToModelRow(aViewRow);

    drawGridData(
      aSender,
      getCastedView.cellPainter,
      fModel.getFieldData(modelCol, modelRow),
      aViewCol, aViewRow,
      modelCol, modelRow,
      aRect,
      aState
    );
  end;
end;

procedure cTableViewProxy.viewDataToEditor(aSender: tObject; aEditor: tWinControl; aViewCol, aViewRow: integer; var assignText: boolean);
var
  modelCol, modelRow: integer;

  editorData: variant;

  relation: cRelation;

  surrogateViewCol: integer;
  delegate: cAbstractTableViewProxyDelegate;
  dataReplacer: cTableViewProxyDataReplacer;
begin
  fInitialEditorData:= null;
  assignText:= false;

  modelCol:= viewColToModelCol(aViewCol);
  modelRow:= viewRowToModelRow(aViewRow);

  fInitialEditorData:= fModel.getFieldData(modelCol, modelRow);
  editorData:= fInitialEditorData;

  if (fModel.getFieldType(modelCol) = dtNotSupported) then begin
    raise eTableViewProxy.create(SET_EDITOR_DATA_FOR_TYPE_NOT_SUPPORTED);
  end;

  if (not(assigned(fEditorViewProxy))) then begin
    exit;
  end;

  surrogateViewCol:= fViewColumnMap.getItemByIndex(aViewCol).getSurrogateIndex;

  dataReplacer:= getDataReplacerForCell(surrogateViewCol, aViewRow);
  if assigned(dataReplacer) then begin
    dataReplacer.setEditorData(self, aViewCol, aViewRow, fModel, modelCol, modelRow, fEditorViewProxy, editorData);
  end;

  delegate:= getDelegateForCell(surrogateViewCol, aViewRow);

  //value [in, out]
  if assigned(delegate) then begin
    delegate.setEditorData(self, aViewCol, aViewRow, fModel, modelCol, modelRow, fEditorViewProxy, editorData);
  end else begin
    if assigned(fOnSetEditorData) then begin
      fOnSetEditorData(self, aViewCol, aViewRow, fModel, modelCol, modelRow, fEditorViewProxy, editorData);
    end;
  end;

  relation:= fModel.getRelation(modelCol);
  if assigned(relation) then begin
    fEditorViewProxy.setValue(editorData);
  end else begin
    fEditorViewProxy.setValue(editorData);
  end;
end;

procedure cTableViewProxy.viewDeleteRow;
var
  curRow: integer;
begin
  curRow:= getViewRowCount - 1;

  if (curRow > 1) then begin
    getCastedView.deleteRow(curRow);
  end;
end;

procedure cTableViewProxy.edit(aViewCol, aViewRow: integer);
begin
  if (not(assigned(view))) then exit;

  selectViewCol(aViewCol);
  selectViewRow(aViewRow);
  fModel.reload(viewRowToModelRow(aViewRow));

  startEditing;
end;

procedure cTableViewProxy.viewEditorCreate(aSender: tObject; aViewCol, aViewRow: integer; var aEditor: tWinControl);
var
  modelCol, modelRow: integer;
  canCreateEditor: boolean;

  surrogateViewCol: integer;
  delegate: cAbstractTableViewProxyDelegate;
begin
  aEditor:= nil;

  modelCol:= viewColToModelCol(aViewCol);
  modelRow:= viewRowToModelRow(aViewRow);

  if (not canEditModelCol(modelCol)) then begin
    exit;
  end;

  canCreateEditor:= not ((fModel.getFields.items[modelCol].readOnly) or (fModel.getFields.items[modelCol].isSelector));

  surrogateViewCol:= fViewColumnMap.getItemByIndex(aViewCol).getSurrogateIndex;
  delegate:= getDelegateForCell(surrogateViewCol, aViewRow);

  if assigned(delegate) then begin
    canCreateEditor:= delegate.canCreateEditor(self, aViewCol, aViewRow, fModel, modelCol, modelRow, canCreateEditor);
  end else begin
    if (assigned(fOnCanCreateEditor)) then begin
      canCreateEditor:= fOnCanCreateEditor(self, aViewCol, aViewRow, fModel, modelCol, modelRow, canCreateEditor);
    end;
  end;



  if (not canCreateEditor) then exit;

  fEditorViewProxy:= createEditor(fModel.getFieldType(modelCol));
  if (not(assigned(fEditorViewProxy))) then begin
    exit;
  end;

  aEditor:= fEditorViewProxy.getView;
end;

procedure cTableViewProxy.editorDataToView(aSender: tObject; aEditor: tWinControl; aViewCol, aViewRow: integer; var assignText: boolean);
var
  value: variant;

  modelCol, modelRow: integer;

  relation: cRelation;

  newStringValue: string;

  surrogateViewCol: integer;

  delegate: cAbstractTableViewProxyDelegate;
  dataReplacer: cTableViewProxyDataReplacer;
begin
  modelCol:= viewColToModelCol(aViewCol);
  modelRow:= viewRowToModelRow(aViewRow);


  if (fModel.getFieldType(modelCol) = dtNotSupported) then begin
    raise eTableViewProxy.create(SET_EDITOR_DATA_FOR_TYPE_NOT_SUPPORTED);
  end;

  if (not(assigned(fEditorViewProxy))) then begin
    exit;
  end;


  relation:= fModel.getRelation(modelCol);
  if assigned(relation) then begin
    value:= cComboBoxViewProxy(fEditorViewProxy).getSelectedModelKey;

    newStringValue:= varToStr(fEditorViewProxy.getValue);
  end else begin
    value:= fEditorViewProxy.getValue;

    newStringValue:= varToStr(value);
  end;

  surrogateViewCol:= fViewColumnMap.getItemByIndex(aViewCol).getSurrogateIndex;

  dataReplacer:= getDataReplacerForCell(surrogateViewCol, aViewRow);
  if assigned(dataReplacer) then begin
    dataReplacer.getEditorData(self, aViewCol, aViewRow, fModel, modelCol, modelRow, fEditorViewProxy, value);
  end;


  delegate:= getDelegateForCell(surrogateViewCol, aViewRow);

  //value [in, out]
  if assigned(delegate) then begin
    delegate.getEditorData(self, aViewCol, aViewRow, fModel, modelCol, modelRow, fEditorViewProxy, value);
  end else begin
    if assigned(fOnGetEditorData) then begin
      fOnGetEditorData(self, aViewCol, aViewRow, fModel, modelCol, modelRow, fEditorViewProxy, value);
    end;
  end;



  if (newStringValue = varToStr(fInitialEditorData)) then exit;

  modelSetRowData(modelCol, modelRow, value);

  refreshView;
end;

procedure cTableViewProxy.viewEditorDestroy(aSender: tObject; var aEditor: tWinControl; aViewCol, aViewRow: integer);
begin
  destroyEditor(fEditorViewProxy, fModel.getFieldType(viewColToModelCol(aViewCol)));
end;

function cTableViewProxy.getDelegateForCell(aCol: integer; aRow: integer): cAbstractTableViewProxyDelegatePrivate;
var
  cell: sTableViewProxyCell;
begin
  if (aCol = fPrevDelegateCol) and (aRow = fPrevDelegateRow) then begin
    result:= fPrevDelegate;
    exit;
  end;

  result:= nil;

  //for cell
  cell.col:= aCol;
  cell.row:= aRow;
  if (fDelegates.containsKey(cell)) then begin
    result:= fDelegates.items[cell];
    exit;
  end;

  //for row
  cell.col:= -1;
  cell.row:= aRow;
  if (fDelegates.containsKey(cell)) then begin
    result:= fDelegates.items[cell];
    exit;
  end;

  //for col
  cell.col:= aCol;
  cell.row:= -1;
  if (fDelegates.containsKey(cell)) then begin
    result:= fDelegates.items[cell];
    exit;
  end;

  //for whole view
  cell.col:= -1;
  cell.row:= -1;
  if (fDelegates.containsKey(cell)) then begin
    result:= fDelegates.items[cell];
    exit;
  end;
end;

function cTableViewProxy.getDataReplacerForCell(aCol: integer; aRow: integer): cTableViewProxyDataReplacerPrivate;
var
  cell: sTableViewProxyCell;
begin
  if (aCol = fPrevDataReplacerCol) and (aRow = fPrevDataReplacerRow) then begin
    result:= fPrevDataReplacer;
    exit;
  end;

  result:= nil;
  //for cell
  cell.col:= aCol;
  cell.row:= aRow;
  if (fDataReplacers.containsKey(cell)) then begin
    result:= fDataReplacers.items[cell];
    exit;
  end;

  //for row
  cell.col:= -1;
  cell.row:= aRow;
  if (fDataReplacers.containsKey(cell)) then begin
    result:= fDataReplacers.items[cell];
  end;

  //for col
  cell.col:= aCol;
  cell.row:= -1;
  if (fDataReplacers.containsKey(cell)) then begin
    result:= fDataReplacers.items[cell];
  end;
end;

function cTableViewProxy.getFirstVisibleCol: integer;
var
  i: integer;
  startCol: integer;
begin
  startCol:= getCastedView.visibleGridRect.col1;

  result:= -1;
  for i:= startCol to getViewColCount - 1 do begin
    if isColVisible(i) then begin
      result:= i;
      exit;
    end;
  end;

end;

procedure cTableViewProxy.drawGridData(aSender: tObject; aCellPainter: tKGridCellPainter; const aFieldValue: variant; aViewCol, aViewRow: integer; aModelCol, aModelRow: integer; aRect: tRect; aStates: tKGridDrawState);
var
  drawingRowChanged: boolean;
  firstColDrawing: boolean;

  hAlignment: tAlignment;
  vAlignment: tVerticalAlignment;

  selectedCellDrawing: boolean;

  fieldType: tDataType;


  surrogateViewCol: integer;
  delegate: cAbstractTableViewProxyDelegate;
  dataReplacer: cTableViewProxyDataReplacer;

  isEmpty: boolean;
begin
  isEmpty:= (fModel.getRowCount = 0);

  selectedCellDrawing:= (aViewRow = getViewRow) and (aViewCol = getViewCol);


  firstColDrawing:= (aViewCol = getFirstVisibleCol);
  drawingRowChanged:= (fDrawingRow <> aViewRow);

  fDrawingRow:= aViewRow;

  with aCellPainter do begin

    text:= varToStr(aFieldValue);

    fieldType:= cVariantConversion.varTypeToDataType(aFieldValue);
    case fieldType of

      dtInteger, dtInt64, dtExtended, dtCurrency: begin
        hAlign:= halRight;
      end;

      dtBoolean: begin
        checkBox:= true;
        checkBoxChecked:= aFieldValue;

        text:= '';
      end;
    end;


    case hAlign of
      halLeft   : hAlignment:= taLeftJustify;
      halCenter : hAlignment:= taCenter;
      halRight  : hAlignment:= taRightJustify;
    end;

    case vAlign of
      valTop    : vAlignment:= taAlignTop;
      valCenter : vAlignment:= taVerticalCenter;
      valBottom : vAlignment:= taAlignBottom;
    end;

    if ((firstColDrawing) or (drawingRowChanged)) then begin

      if (assigned(fOnModelRowRendering) or assigned(fOnModelRowRenderingText)) then begin
        fDrawingModelRow:= fModel.getIteratorRow(aModelRow);
      end;

    end;

    surrogateViewCol:= fViewColumnMap.getItemByIndex(aViewCol).getSurrogateIndex;

    delegate:= getDelegateForCell(surrogateViewCol, aViewRow);
    dataReplacer:= getDataReplacerForCell(surrogateViewCol, aViewRow);


    if (assigned(fDrawingModelRow)) then begin

      if assigned(dataReplacer) then begin
        dataReplacer.rowRenderingText(self, fDrawingModelRow, aViewCol, aViewRow, fModel, aModelCol, aModelRow, text);
      end;

      if assigned(delegate) then begin
        delegate.rowRenderingText(self, fDrawingModelRow, aViewCol, aViewRow, fModel, aModelCol, aModelRow, text);
      end else begin
        if assigned(fOnModelRowRenderingText) then begin
          fOnModelRowRenderingText(self, fDrawingModelRow, aViewCol, aViewRow, fModel, aModelCol, aModelRow, text);
        end;
      end;
    end;


    if selectedCellDrawing then begin
      selectedItemPainting(self, getCastedView.cellPainter.canvas, aRect, text, hAlignment, vAlignment);
    end;

    if (assigned(fDrawingModelRow)) then begin
      if assigned(delegate) then begin
        delegate.rowRendering(self, aCellPainter, fDrawingModelRow, aStates);
      end else begin
        if assigned(fOnModelRowRendering) then begin
          fOnModelRowRendering(self, aCellPainter, fDrawingModelRow, aStates);
        end;
      end;
    end;

    defaultDraw;

    if selectedCellDrawing then begin
      selectedItemPainted(self, getCastedView.cellPainter.canvas, aRect, text, hAlignment, vAlignment);
    end;

  end;
end;

procedure cTableViewProxy.drawGridHeader(aSender: tObject; aCellPainter: tKGridCellPainter; aViewCol, aViewRow: integer; aRect: tRect; aStates: tKGridDrawState);
var
  headerCell: tKGridCell;
  tableField: cTableField;
begin

  with aCellPainter do begin

    headerCell:= getCastedView.cell[aViewCol, aViewRow];

    if (headerCell is cGridHeaderCell) then begin
      tableField:= fModel.getFields.items[viewColToModelCol(aViewCol)];

      if (tableField.containsStates([fsSortable])) then
        state:= state + FIELD_SORT_DIRECTION_MAP[tableField.sortDirection];


      headerCell.applyDrawProperties;

    end;

    drawThemedHeaderCell;
  end;
end;

function cTableViewProxy.getViewFixedColCount: integer;
begin
  result:= getCastedView.fixedCols;
end;

function cTableViewProxy.getViewFixedRowCount: integer;
begin
  result:= getCastedView.fixedRows;
end;

function cTableViewProxy.getCastedView: tKGrid;
begin
  result:= getView as tKGrid;
end;

function cTableViewProxy.getHeaders: cGridHeaders;
begin
  result:= fHeaders;
end;

function cTableViewProxy.getMaxColFromHeaders: integer;
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

function cTableViewProxy.getMaxRowFromHeaders: integer;
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

function cTableViewProxy.getModel: cAbstractTableModel;
begin
  result:= fModel;
end;

function cTableViewProxy.getRowHeight(aRow: integer): integer;
begin
  result:= 0;
  if (not(assigned(view))) then begin
    exit;
  end;

  result:= getCastedView.rowHeights[aRow];
end;

function cTableViewProxy.getViewRowAt(aPoint: tPoint): integer;
var
  col: integer;
begin
  result:= -1;
  if (not(assigned(view))) then exit;

  getCastedView.mouseToCell(aPoint.X, aPoint.Y, col, result);
end;

function cTableViewProxy.getViewCell(aViewCol, aViewRow: integer): tKGridCell;
begin
  result:= getCastedView.cell[aViewCol, aViewRow];
end;

function cTableViewProxy.getViewCol: integer;
begin
  result:= -1;
  if (not(assigned(view))) then exit;

  result:= getCastedView.col;
end;

function cTableViewProxy.getViewColAt(aPoint: tPoint): integer;
var
  row: integer;
begin
  result:= -1;
  if (not(assigned(view))) then exit;

  getCastedView.mouseToCell(aPoint.X, aPoint.Y, result, row);
end;

function cTableViewProxy.getViewColCount: integer;
begin
  result:= getCastedView.colCount;
end;

function cTableViewProxy.getViewRow: integer;
begin
  result:= -1;
  if (not(assigned(view))) then exit;

  result:= getCastedView.row;
end;

function cTableViewProxy.getViewRowCount: integer;
begin
  result:= getCastedView.rowCount;
end;

procedure cTableViewProxy.setColVisible(aCol: integer; aValue: boolean);
begin
  if (not(assigned(view))) then exit;

  if (aValue) then begin
    setColWidth(aCol, 100);
  end else begin
    setColWidth(aCol, 0);
  end;
end;

function cTableViewProxy.isColVisible(aCol: integer): boolean;
begin
  result:= getColWidth(aCol) <> 0;
end;

procedure cTableViewProxy.setRowVisible(aRow: integer; aValue: boolean);
begin
  if (not(assigned(view))) then exit;

  if (aValue) then begin
    setRowHeight(aRow, getCastedView.defaultRowHeight);
  end else begin
    setRowHeight(aRow, 0);
  end;
end;

function cTableViewProxy.isRowVisible(aRow: integer): boolean;
begin
  result:= getRowHeight(aRow) <> 0;
end;

procedure cTableViewProxy.increaseViewCellsIfNeeded(aColCount, aRowCount: integer);
begin
  if (aColCount > getViewColCount) then begin
    setViewColCount(aColCount);
  end;

  if (aRowCount > getViewRowCount) then begin
    setViewRowCount(aRowCount);
  end;
end;

function cTableViewProxy.isEditable: boolean;
begin
  result:= fEditable and not ((assigned(fModel)) and (fModel.getRowCount = 0));
end;

function cTableViewProxy.isRendered: boolean;
begin
  result:= fRendered;
end;

function cTableViewProxy.isSortable: boolean;
begin
  result:= fSortable;
end;

procedure cTableViewProxy.iterateCheckedRows(aCheckedIteratorProc: tTableViewProxyCheckedIteratorProc);
var
  i: integer;

  selectorColIndex: integer;
  selected: boolean;
begin
  if (not(assigned(fModel))) then exit;
  if (not(assigned(view))) then exit;

  if (not assigned(aCheckedIteratorProc)) then begin
    exit;
  end;

  selectorColIndex:= fModel.getFields.getSelectorFieldIndex;
  if (selectorColIndex = -1) then exit;


  for i:= 0 to fModel.getRowCount - 1 do begin
    selected:= fModel.getFieldData(selectorColIndex, i);
    if selected then begin
      aCheckedIteratorProc(modelRowToViewRow(i));
    end;
  end;
end;

procedure cTableViewProxy.iterateSelectedRows(aSelectedIteratorProc: tTableViewProxySelectedIteratorProc);
var
  i: integer;
begin
  if (not assigned(aSelectedIteratorProc)) then begin
    exit;
  end;

  if (getCastedView.selectionCount <> 1) then begin
    exit;
  end;


  getCastedView.selectionNormalize;

  for i:= getCastedView.selection.row1 to getCastedView.selection.row2 do begin
    aSelectedIteratorProc(i);
  end;

end;

procedure cTableViewProxy.keyDown(aSender: tObject; var aKey: word; aShift: tShiftState);
const
  SMALL_C_KEY_CODE  = 67;
  CAPS_C_KEY_CODE   = 99;
begin
  if (aShift = [ssCtrl]) and (aKey in [SMALL_C_KEY_CODE, CAPS_C_KEY_CODE]) then begin
    clipboard.asText:= varToStr(getModel.getFieldData(
      viewColToModelCol(getViewCol),
      viewRowToModelRow(getViewRow)
    ));
  end;


  if (aKey <> VK_SPACE) then begin
    inherited keyDown(aSender, aKey, aShift);

    exit;
  end;

  inherited keyDown(aSender, aKey, aShift);

  viewCellClick(getCastedView, getViewCol, getViewRow);
end;

function cTableViewProxy.locate(aText: string; aSearchDirection: tViewSearchDirection; aSearchPosition: tViewSearchPosition; aSearchType: tViewSearchType): boolean;
const
  viewSearchPositionToModelSearchPosition: array[tViewSearchPosition] of tModelSearchPosition = (
    tModelSearchPosition.spFirst,
    tModelSearchPosition.spCurrent,
    tModelSearchPosition.spNextFromCurrent,
    tModelSearchPosition.spPrevFromCurrent,
    tModelSearchPosition.spLast
  );
  viewSearchDirectionToModelSearchDirection: array[tViewSearchDirection] of tModelSearchDirection = (
    tModelSearchDirection.sdForward,
    tModelSearchDirection.sdBackward
  );
var
  findedRowIndex: integer;
begin
  result:= false;

  findedRowIndex:= -1;
  case aSearchType of
    stEntire: begin
      findedRowIndex:= fModel.locate(
        fModel.locateByValueEqualProc,
        aText,
        viewColToModelCol(getViewCol),
        viewRowToModelRow(getViewRow),
        viewSearchDirectionToModelSearchDirection[aSearchDirection],
        viewSearchPositionToModelSearchPosition[aSearchPosition]
      );
    end;

    stPartial: begin
      findedRowIndex:= fModel.locate(
        fModel.locateByValuePartProc,
        aText,
        viewColToModelCol(getViewCol),
        viewRowToModelRow(getViewRow),
        viewSearchDirectionToModelSearchDirection[aSearchDirection],
        viewSearchPositionToModelSearchPosition[aSearchPosition]
      );
    end;
  end;

  result:= (findedRowIndex <> -1);

  if (result) then begin
    selectViewRow(modelRowToViewRow(findedRowIndex));
  end;


end;

function cTableViewProxy.getViewIndexOfModelField(aName: string): integer;
var
  modelFields: cTableFields;
  modelIndex: integer;
begin
  result:= -1;

  if (not(assigned(fModel))) then exit;
  if (not(assigned(view))) then exit;

  modelFields:= fModel.getFields;
  modelIndex:= modelFields.indexOfName(aName);

  if (modelIndex = -1) then begin
    cLog.getInstance.write(self, 'getViewIndexOfModelField: modelIndex not found', ltWarning);
    exit;
  end;

  result:= modelColToViewCol(modelIndex);
end;

procedure cTableViewProxy.updateColumnsMapping;
var
  i: integer;
begin
  fModelColumnMap.clear;
  fViewColumnMap.clear;

  for i:= 0 to getViewColCount - 1 do begin
    fModelColumnMap.add(cColumnMapItem.create(i - fViewModelColStartOffset));
  end;

  for i:= 0 to getViewColCount - 1 do begin
    fViewColumnMap.add(cColumnMapItem.create(i));
  end;
end;

function cTableViewProxy.viewAppendRow: integer;
begin
  getCastedView.insertRow(getViewRowCount - 1);
  result:= getViewRowCount - 1;
end;

function cTableViewProxy.viewColToModelCol(aViewCol: integer): integer;
begin
  result:= fModelColumnMap.items[aViewCol].getSurrogateIndex;
end;

procedure cTableViewProxy.viewColumnMoved(aSender: tObject; aFromIndex, aToIndex: integer);
begin
  if (fColumnMapMoving) then begin
    exit;
  end;

  beginColumnMapMoving;
  try
    fModelColumnMap.moveTo(aFromIndex, aToIndex);
    fViewColumnMap.moveTo(aFromIndex, aToIndex);
  finally
    endColumnMapMoving;
  end;
end;

procedure cTableViewProxy.setViewFixedColCount(aCount: integer);
begin
  getCastedView.fixedCols:= aCount;
end;

procedure cTableViewProxy.setViewFixedRowCount(aCount: integer);
begin
  getCastedView.fixedRows:= aCount;
end;

function cTableViewProxy.saveState: tBytesArray;
var
  i: integer;
  curModelColumnMapItem: cColumnMapItem;
  curField: cTableField;
  viewColCount: integer;
  modelFieldsCount: integer;
  modelColumnMapCount: integer;

  surrogateModelIndex: integer;

  colWidth: integer;

  dataStream: cMemory;
begin
  if not assigned(fModel) then exit;


  dataStream:= cMemory.create;
  try
    dataStream.clear;

    dataStream.writeAnsiString(CURRENT_VERSION);

    modelColumnMapCount:= fModelColumnMap.count;

    dataStream.writeInteger(modelColumnMapCount);

    for i:= 0 to modelColumnMapCount - 1 do begin
      curModelColumnMapItem:= fModelColumnMap.items[i];

      surrogateModelIndex:= curModelColumnMapItem.getSurrogateIndex;

      dataStream.writeInteger(surrogateModelIndex);
    end;


    viewColCount:= getViewColCount;

    dataStream.writeInteger(viewColCount);
    for i:= 0 to viewColCount - 1 do begin
      colWidth:= getColWidth(i);

      dataStream.writeInteger(colWidth);
    end;

    modelFieldsCount:= model.getFields.count;

    dataStream.writeInteger(modelFieldsCount);
    for i:= 0 to modelFieldsCount - 1 do begin
      curField:= model.getFields.items[i];

      dataStream.write(curField.sortDirection, sizeOf(curField.sortDirection));
    end;

    result:= dataStream.toBytes;
  finally
    freeAndNil(dataStream);
  end;
end;

procedure cTableViewProxy.selectFirstRow;
var
  canSelectStub: boolean;
  viewRow, viewCol: integer;
begin
  canSelectStub:= true;

  viewRow:= modelRowToViewRow(0);
  viewCol:= modelColToViewCol(0);

  selectViewRow(viewRow);
  selectViewCol(viewCol);

  viewCellSelecting(getCastedView, viewCol, viewRow, canSelectStub);
end;

procedure cTableViewProxy.selectionToCheck(aValue: boolean);
begin
  iterateSelectedRows(
    procedure(aViewRow: integer)
    var
      modelRow: integer;
    begin
      modelRow:= viewRowToModelRow(aViewRow);

      fModel.setRowSelected(modelRow, aValue);
    end
  );
end;

procedure cTableViewProxy.selectViewCol(aViewCol: integer);
begin
  if (not(assigned(view))) then exit;

  getCastedView.col:= aViewCol;
end;

procedure cTableViewProxy.selectViewRow(aViewRow: integer);

  function getFirstVisibleSelectedCol: integer;
  var
    i: integer;

    candidate: integer;
    candidateFound: boolean;
  begin
    result:= 0;
    candidateFound:= false;
    for i:= 0 to getViewColCount - 1 do begin
      if (not candidateFound) and ((i > getCastedView.fixedCols) and (getColWidth(i) <> 0)) then begin
        candidate:= i;
        candidateFound:= true;
      end;

      if (getColWidth(i) <> 0) and (getViewCol = i) then begin
        result:= i;
        exit;
      end;

    end;

    if (candidateFound) then begin
      result:= candidate;
    end;

  end;
begin
  if (not(assigned(view))) then exit;

  getCastedView.focusCell(getFirstVisibleSelectedCol, aViewRow);
end;

procedure cTableViewProxy.setCanTakeFocus(aValue: boolean);
begin
  inherited setCanTakeFocus(aValue);

  if (not assigned(fView)) then begin
    exit;
  end;

  if (canTakeFocus) then begin
    getCastedView.enabled:= true;
    getCastedView.disabledDrawStyle:= ddBright;
  end else begin
    getCastedView.enabled:= false;
    getCastedView.disabledDrawStyle:= ddNormal;
  end;
end;

procedure cTableViewProxy.setCellDelegate(aCol, aRow: integer; aDelegate: cAbstractTableViewProxyDelegatePrivate);
var
  cell: sTableViewProxyCell;
begin
  cell.col:= aCol;
  cell.row:= aRow;

  fDelegates.add(cell, aDelegate);
end;

procedure cTableViewProxy.setColDelegate(aCol: integer; aDelegate: cAbstractTableViewProxyDelegatePrivate);
begin
  setCellDelegate(aCol, -1, aDelegate);
end;

procedure cTableViewProxy.setRowDelegate(aRow: integer; aDelegate: cAbstractTableViewProxyDelegatePrivate);
begin
  setCellDelegate(-1, aRow, aDelegate);
end;

procedure cTableViewProxy.setCellDataReplacer(aCol, aRow: integer; aDataReplacer: cTableViewProxyDataReplacerPrivate);
var
  cell: sTableViewProxyCell;
begin
  cell.col:= aCol;
  cell.row:= aRow;

  fDataReplacers.add(cell, aDataReplacer);
end;

procedure cTableViewProxy.setColDataReplacer(aCol: integer; aDataReplacer: cTableViewProxyDataReplacerPrivate);
begin
  setCellDataReplacer(aCol, -1, aDataReplacer);
end;

procedure cTableViewProxy.setRowDataReplacer(aRow: integer; aDataReplacer: cTableViewProxyDataReplacerPrivate);
begin
  setCellDataReplacer(-1, aRow, aDataReplacer);
end;

procedure cTableViewProxy.setColSizing(aValue: boolean);
begin
  fColSizing:= aValue;

  if (not(assigned(view))) then begin
    exit;
  end;

  if aValue then begin
    getCastedView.options:= getCastedView.options + [goColSizing];
  end else begin
    getCastedView.options:= getCastedView.options - [goColSizing];
  end;
end;

procedure cTableViewProxy.setColWidth(aCol: integer; aWidth: integer);
begin
  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.colWidths[aCol]:= aWidth;
end;

procedure cTableViewProxy.setEditable(aValue: boolean);
begin
  fEditable:= aValue;

  if (not assigned(fView)) then begin
    exit;
    //raise eTableViewProxy.create(CANNOT_SET_EDITABLE_VIEW_NOT_ASSIGNED);
  end;

  if fEditable then begin
    getCastedView.options:= getCastedView.options + [goEditing];
  end else begin
    getCastedView.options:= getCastedView.options - [goEditing];
  end;
end;

procedure cTableViewProxy.setFocusedBgColor(aColor: tColor);
begin
  inherited setFocusedBgColor(aColor);

  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.colors.focusedCellBkGnd:= aColor;
end;

procedure cTableViewProxy.setFocusedTextColor(aColor: tColor);
begin
  inherited setFocusedTextColor(aColor);

  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.colors.focusedCellText:= aColor;
end;

procedure cTableViewProxy.setHeadersVisible(aValue: boolean);
var
  i: integer;
begin
  for i:= 0 to getMaxRowFromHeaders do begin
    setRowVisible(i, aValue);
  end;
end;

procedure cTableViewProxy.setHint(aHint: string);
begin
  inherited setHint(aHint);
  getCastedView.hint:= aHint;
end;

procedure cTableViewProxy.setFocusedRangeBgColor(aColor: tColor);
begin
  inherited setFocusedRangeBgColor(aColor);

  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.colors.focusedRangeBkGnd:= aColor;
end;

procedure cTableViewProxy.setFocusedRangeTextColor(aColor: tColor);
begin
  inherited setFocusedRangeTextColor(aColor);

  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.colors.focusedRangeText:= aColor;
end;

procedure cTableViewProxy.setModel(aModel: cAbstractTableModel);
begin
  disconnectModelEvents;

  setRendered(false);

  fModel:= aModel;

  if assigned(fOnModelAssigned) then begin
    fOnModelAssigned(self);
  end;

  setupModelEvents;
end;

procedure cTableViewProxy.setRendered(aValue: boolean);
begin
  fRendered:= aValue;

  if (fRendered) then begin
    if assigned(fOnRendered) then begin
      fOnRendered(self);
    end;
  end;

end;

procedure cTableViewProxy.setRowHeight(aRow: integer; aHeight: integer);
begin
  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.rowHeights[aRow]:= aHeight;
end;

procedure cTableViewProxy.setSelectedBgColor(aColor: tColor);
begin
  inherited setSelectedBgColor(aColor);

  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.colors.selectedCellBkGnd:= aColor;
end;

procedure cTableViewProxy.setSelectedTextColor(aColor: tColor);
begin
  inherited setSelectedTextColor(aColor);

  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.colors.selectedCellText:= aColor;
end;

procedure cTableViewProxy.setSortable(aValue: boolean);
begin
  fSortable:= aValue;

  if (not fSortable) then begin
    clearSorting;
  end;
end;

procedure cTableViewProxy.setSelectedRangeBgColor(aColor: tColor);
begin
  inherited setSelectedRangeBgColor(aColor);

  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.colors.selectedRangeBkGnd:= aColor;
end;

procedure cTableViewProxy.setSelectedRangeTextColor(aColor: tColor);
begin
  inherited setSelectedRangeTextColor(aColor);

  if (not(assigned(view))) then begin
    exit;
  end;

  getCastedView.colors.selectedRangeText:= aColor;
end;

procedure cTableViewProxy.setView(aView: tWinControl);
begin
  setRendered(false);

  inherited setView(aView);

  if (assigned(aView)) and (not (aView is tKGrid)) then begin
    raise eClassError.createFmt(INVALID_CLASS_RECEIVED, [tKGrid.className, aView.className]);
  end;


  prepareView;
end;

procedure cTableViewProxy.setViewCell(aViewCol, aViewRow: integer; aCell: tKGridCell);
begin
  getCastedView.cell[aViewCol, aViewRow]:= aCell;
end;

procedure cTableViewProxy.setViewColCount(aCount: integer);
begin
  getCastedView.colCount:= aCount;
end;

procedure cTableViewProxy.setViewModelOffsets;
begin
  fViewModelColStartOffset:= getViewFixedColCount;
  fViewModelRowStartOffset:= getViewFixedRowCount;
end;

procedure cTableViewProxy.setViewRowChecked(aViewRow: integer; aChecked: boolean);
begin
  if (not(assigned(view))) then begin
    raise eTableViewProxy.create(VIEW_NOT_ASSIGNED);
  end;

  if (not(assigned(fModel))) then begin
    raise eTableViewProxy.create(MODEL_NOT_ASSIGNED);
  end;

  fModel.setRowSelected(viewRowToModelRow(aViewRow), aChecked);
  refreshView;
end;

procedure cTableViewProxy.setViewRowCount(aCount: integer);
begin
  getCastedView.rowCount:= aCount;
end;

procedure cTableViewProxy.render;
begin
  if (not(assigned(view))) then begin
    raise eTableViewProxy.create(VIEW_NOT_ASSIGNED);
  end;

  if (not(assigned(fModel))) then begin
    raise eTableViewProxy.create(MODEL_NOT_ASSIGNED);
  end;

  renderView;
end;

procedure cTableViewProxy.startEditing;
begin
  getCastedView.editorMode:= true;
end;

end.

