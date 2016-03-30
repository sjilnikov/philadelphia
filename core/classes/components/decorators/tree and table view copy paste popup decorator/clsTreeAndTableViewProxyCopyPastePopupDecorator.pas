unit clsTreeAndTableViewProxyCopyPastePopupDecorator;

interface
uses
  classes,
  menus,
  windows,
  sysUtils,
  virtualTrees,



  clsWaitingForm,
  clsException,
  clsAbstractViewProxy,

  clsAbstractTableModel,
  clsAbstractTreeModel,

  clsTableViewProxy,
  clsTreeViewProxy,

  clsObjectSerializer,
  clsIOPropertiesXML,
  clsLists,
  clsAbstractPopupDecorator,
  clsMulticastEvents,
  clsMessageBox;

type
  eTreeAndTableViewProxyCopyPastePopupDecorator = class(cException);

  sCopyCheckedItemsInfo = record
    popupItemName: string;
    popupItemCaptionFormat: string;

    operationCaption: string;
    operationMessage: string;

    imageIndex: integer;
  end;

  sCutCheckedItemsInfo = record
    popupItemName: string;
    popupItemCaptionFormat: string;

    operationCaption: string;
    operationMessage: string;

    imageIndex: integer;
  end;

  sPasteCheckedItemsInfo = record
    popupItemName: string;
    popupItemCaptionFormat: string;

    operationCaption: string;
    operationMessage: string;

    imageIndex: integer;

    questionTitle: string;
    questionCaption: string;
    questionMessageFormat: string;
  end;


  sDeleteCheckedItemsInfo = record
    popupItemName: string;
    popupItemCaptionFormat: string;

    imageIndex: integer;

    operationCaption: string;
    operationMessage: string;

    questionTitle: string;
    questionCaption: string;
    questionMessageFormat: string;
  end;

  sClearItemsInfo = record
    popupItemName: string;
    popupItemCaptionFormat: string;

    imageIndex: integer;
  end;

  tLastPopupAction = (paCopy, paCut);

  cPasteMapItem = class
  private
    fFromValue : int64;
    fToValue   : int64;
  public
    function    getFromValue: int64;
    function    getToValue: int64;

    constructor create(aFromValue: int64; aToValue: int64);
    destructor  destroy; override;

    property    fromValue: int64 read getFromValue;
    property    toValue: int64 read getToValue;
  end;

  cPasteMapList = class
  private
    fList       :  cList;

    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cPasteMapItem;
  public
    procedure   clear;
    procedure   add(aItem: cPasteMapItem);

    function    indexOfFromValue(aFromValue: int64): integer;

    constructor create;
    destructor  destroy; override;

    property    items[aIndex: integer]: cPasteMapItem read getItemByIndex;
    property    count: integer read getCount;
  end;

  tTreeAndTableViewProxyCopyPastePopupCommand = (pcCopy, pcCut, pcPaste, pcDelete);

  cTreeAndTableViewProxyCopyPastePopupDecoratorPasteToViewProc = reference to procedure(aViewProxy: cAbstractViewProxy; aPasteRow: cAbstractTableRow);

  cTreeAndTableViewProxyCopyPastePopupDecorator = class(cAbstractPopupDecorator)
  private
    fCopyCheckedItemsInfo  : sCopyCheckedItemsInfo;
    fCutCheckedItemsInfo   : sCutCheckedItemsInfo;
    fPasteCheckedItemsInfo : sPasteCheckedItemsInfo;
    fClearItemsInfo        : sClearItemsInfo;
    fDeleteCheckedItemsInfo: sDeleteCheckedItemsInfo;

    fLastPopupAction       : tLastPopupAction;

    fSerializer            : cObjectSerializer;
    fPasteMapList          : cPasteMapList;

    fPasteToViewProc       : cTreeAndTableViewProxyCopyPastePopupDecoratorPasteToViewProc;

    procedure   initialize;

    procedure   addPopupItems; override;

    procedure   setupEvents; override;
    procedure   disconnectEvents; override;

    procedure   setupViewProxyEvents; override;
    procedure   disconnectViewProxyEvents; override;


    procedure   copyViewCheckedItems(aNeedCut: boolean); overload;
  public
    const
    ONLY_TREE_VIEW_OR_TABLE_VIEW_SUPPURTS_FORMAT = 'only tree view or table view supports, got: %s';

    DEFAULT_METADATA_NODE_NAME   = 'metadata';

    DEFAULT_COPY_ITEMS_NAME = 'copyitems';
    DEFAULT_CUT_ITEMS_NAME = 'cutItems';
    DEFAULT_PASTE_ITEMS_NAME = 'pasteItems';
    DEFAULT_DELETE_ITEMS_NAME = 'deleteItems';

    DEFAULT_CLEAR_ITEMS_NAME = 'clearItems';

    DEFAULT_COPY_ITEMS_FORMAT = 'copy items (count: %d)';
    DEFAULT_CUT_ITEMS_FORMAT = 'cut items (count: %d)';
    DEFAULT_PASTE_ITEMS_FORMAT = 'paste items (count: %d)';
    DEFAULT_CLEAR_ITEMS_FORMAT = 'clear buffer (count: %d)';
    DEFAULT_DELETE_ITEMS_FORMAT = 'delete items (count: %d)';

    DEFAULT_COPY_OPERATION_CAPTION = 'Please wait';
    DEFAULT_COPY_OPERATION_MESSAGE = 'copying...';

    DEFAULT_CUT_OPERATION_CAPTION = 'Please wait';
    DEFAULT_CUT_OPERATION_MESSAGE = 'cutting...';

    DEFAULT_PASTE_OPERATION_CAPTION = 'Please wait';
    DEFAULT_PASTE_OPERATION_MESSAGE = 'inserting...';

    DEFAULT_DELETE_OPERATION_CAPTION = 'Please wait';
    DEFAULT_DELETE_OPERATION_MESSAGE = 'deleting...';

    DEFAULT_POPUP_PASTE_ITEMS_CAPTION = 'paste items';

    DEFAULT_PASTE_ITEMS_QUESTION_CAPTION = 'paste items';
    DEFAULT_PASTE_ITEMS_QUESTION_TITLE = 'paste items';
    DEFAULT_PASTE_ITEMS_QUESTION_MESSAGE_FORMAT = 'paste stored items (count: %d)?';


    DEFAULT_DELETE_ITEMS_QUESTION_CAPTION = 'delete items';
    DEFAULT_DELETE_ITEMS_QUESTION_TITLE = 'delete items';
    DEFAULT_DELETE_ITEMS_QUESTION_MESSAGE_FORMAT = 'delete selected (count: %d)?';

    DEFAULT_DELETE_ITEMS_NOTHING_TO_DELETE_CAPTION = 'nothing to delete!';
  public
    procedure   setPasteToViewProc(aPasteToViewProc: cTreeAndTableViewProxyCopyPastePopupDecoratorPasteToViewProc);
    procedure   doCommand(aCommand: tTreeAndTableViewProxyCopyPastePopupCommand);

    procedure   pasteToTableView(aTableViewProxy: cTableViewProxy; aSrcRow: cAbstractTableRow; aDestRow: integer);
    procedure   pasteToTreeView(aTreeViewProxy: cTreeViewProxy; aSrcRow: cAbstractTableRow; aDestNode: pVirtualNode);

    procedure   setViewProxy(aViewProxy: cAbstractViewProxy); override;

    procedure   copyViewCheckedItems; overload;
    procedure   cutViewCheckedItems;
    procedure   pasteViewCheckedItems;
    procedure   deleteViewCheckedItems;
    procedure   clearSerializer;

    procedure   setCopyCheckedItemsInfo(aInfo: sCopyCheckedItemsInfo);
    function    getCopyCheckedItemsInfo: sCopyCheckedItemsInfo;

    procedure   setCutCheckedItemsInfo(aInfo: sCutCheckedItemsInfo);
    function    getCutCheckedItemsInfo: sCutCheckedItemsInfo;

    procedure   setPasteCheckedItemsInfo(aInfo: sPasteCheckedItemsInfo);
    function    getPasteCheckedItemsInfo: sPasteCheckedItemsInfo;

    procedure   setDeleteCheckedItemsInfo(aInfo: sDeleteCheckedItemsInfo);
    function    getDeleteCheckedItemsInfo: sDeleteCheckedItemsInfo;

    procedure   setClearItemsInfo(aInfo: sClearItemsInfo);
    function    getClearItemsInfo: sClearItemsInfo;

    constructor create;
    destructor  destroy; override;

  published
    //SLOTS
    procedure   popupItemClicked(aSender: tObject); override;
    procedure   popupInvoked(aSender: tObject); override;
  end;


implementation

{ cTreeAndTableViewProxyCopyPastePopupDecorator }

constructor cTreeAndTableViewProxyCopyPastePopupDecorator.create;
begin
  inherited create;

  initialize;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.deleteViewCheckedItems;
var
  treeViewProxy: cTreeViewProxy;
  tableViewProxy: cTableViewProxy;
begin
  cWaitingForm.show(fDeleteCheckedItemsInfo.operationCaption, fDeleteCheckedItemsInfo.operationMessage);
  try

    if (viewProxy is cTableViewProxy) then begin
      tableViewProxy:= viewProxy as cTableViewProxy;
      tableViewProxy.model.deleteSelectedRows;
    end;

    if (viewProxy is cTreeViewProxy) then begin
      treeViewProxy:= viewProxy as cTreeViewProxy;
      treeViewProxy.model.deleteSelectedItems;
    end;

    viewProxy.invalidate;
  finally
    cWaitingForm.hide;
  end;
end;

destructor cTreeAndTableViewProxyCopyPastePopupDecorator.destroy;
begin
  if assigned(fSerializer) then begin
    freeAndNil(fSerializer);
  end;

  if assigned(fPasteMapList) then begin
    freeAndNil(fPasteMapList);
  end;


  inherited;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.addPopupItems;
begin
  createMenuItem(getCopyCheckedItemsInfo.popupItemName, format(getCopyCheckedItemsInfo.popupItemCaptionFormat, [0]), getCopyCheckedItemsInfo.imageIndex);
  createMenuItem(getCutCheckedItemsInfo.popupItemName, format(getCutCheckedItemsInfo.popupItemCaptionFormat, [0]), getCutCheckedItemsInfo.imageIndex);
  createMenuItem(getPasteCheckedItemsInfo.popupItemName, format(getPasteCheckedItemsInfo.popupItemCaptionFormat, [0]), getPasteCheckedItemsInfo.imageIndex);
  createMenuItem(getDeleteCheckedItemsInfo.popupItemName, format(getDeleteCheckedItemsInfo.popupItemCaptionFormat, [0]), getDeleteCheckedItemsInfo.imageIndex);

  createMenuItem(getClearItemsInfo.popupItemName, format(getClearItemsInfo.popupItemCaptionFormat, [0]), getClearItemsInfo.imageIndex);
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.disconnectEvents;
begin

end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.disconnectViewProxyEvents;
begin

end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.doCommand(aCommand: tTreeAndTableViewProxyCopyPastePopupCommand);
begin
  case aCommand of
    pcCopy   : copyViewCheckedItems;
    pcCut    : cutViewCheckedItems;
    pcPaste  : pasteViewCheckedItems;
    pcDelete : deleteViewCheckedItems;
  end;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.setupEvents;
begin

end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.setupViewProxyEvents;
begin

end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.setViewProxy(aViewProxy: cAbstractViewProxy);
begin
  if not ((aViewProxy is cTreeViewProxy) or (aViewProxy is cTableViewProxy)) then begin
    raise eTreeAndTableViewProxyCopyPastePopupDecorator.createFmt(ONLY_TREE_VIEW_OR_TABLE_VIEW_SUPPURTS_FORMAT, [aViewProxy.className]);
  end;

  inherited setViewProxy(aViewProxy);
end;

function cTreeAndTableViewProxyCopyPastePopupDecorator.getClearItemsInfo: sClearItemsInfo;
begin
  result:= fClearItemsInfo;
end;

function cTreeAndTableViewProxyCopyPastePopupDecorator.getCopyCheckedItemsInfo: sCopyCheckedItemsInfo;
begin
  result:= fCopyCheckedItemsInfo;
end;

function cTreeAndTableViewProxyCopyPastePopupDecorator.getCutCheckedItemsInfo: sCutCheckedItemsInfo;
begin
  result:= fCutCheckedItemsInfo;
end;

function cTreeAndTableViewProxyCopyPastePopupDecorator.getDeleteCheckedItemsInfo: sDeleteCheckedItemsInfo;
begin
  result:= fDeleteCheckedItemsInfo;
end;

function cTreeAndTableViewProxyCopyPastePopupDecorator.getPasteCheckedItemsInfo: sPasteCheckedItemsInfo;
begin
  result:= fPasteCheckedItemsInfo;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.initialize;
var
  copyInfo: sCopyCheckedItemsInfo;
  cutInfo: sCutCheckedItemsInfo;
  pasteInfo: sPasteCheckedItemsInfo;
  deleteInfo: sDeleteCheckedItemsInfo;
  clearInfo: sClearItemsInfo;

  IOPropertiesXML: cIOPropertiesXML;
begin
  copyInfo.popupItemName:= DEFAULT_COPY_ITEMS_NAME;
  copyInfo.popupItemCaptionFormat:= DEFAULT_COPY_ITEMS_FORMAT;
  copyInfo.operationCaption:= DEFAULT_COPY_OPERATION_CAPTION;
  copyInfo.operationMessage:= DEFAULT_COPY_OPERATION_MESSAGE;
  setCopyCheckedItemsInfo(copyInfo);

  cutInfo.popupItemName:= DEFAULT_CUT_ITEMS_NAME;
  cutInfo.popupItemCaptionFormat:= DEFAULT_CUT_ITEMS_FORMAT;
  cutInfo.operationCaption:= DEFAULT_CUT_OPERATION_CAPTION;
  cutInfo.operationMessage:= DEFAULT_CUT_OPERATION_MESSAGE;
  setCutCheckedItemsInfo(cutInfo);

  pasteInfo.popupItemName:= DEFAULT_PASTE_ITEMS_NAME;
  pasteInfo.popupItemCaptionFormat:= DEFAULT_PASTE_ITEMS_FORMAT;
  pasteInfo.questionTitle:= DEFAULT_PASTE_ITEMS_QUESTION_TITLE;
  pasteInfo.questionCaption:= DEFAULT_PASTE_ITEMS_QUESTION_CAPTION;
  pasteInfo.questionMessageFormat:= DEFAULT_PASTE_ITEMS_QUESTION_MESSAGE_FORMAT;
  pasteInfo.operationCaption:= DEFAULT_PASTE_OPERATION_CAPTION;
  pasteInfo.operationMessage:= DEFAULT_PASTE_OPERATION_MESSAGE;
  setPasteCheckedItemsInfo(pasteInfo);

  deleteInfo.popupItemName:= DEFAULT_DELETE_ITEMS_NAME;
  deleteInfo.popupItemCaptionFormat:= DEFAULT_DELETE_ITEMS_FORMAT;
  deleteInfo.questionTitle:= DEFAULT_DELETE_ITEMS_QUESTION_TITLE;
  deleteInfo.questionCaption:= DEFAULT_DELETE_ITEMS_QUESTION_CAPTION;
  deleteInfo.questionMessageFormat:= DEFAULT_DELETE_ITEMS_QUESTION_MESSAGE_FORMAT;
  deleteInfo.operationCaption:= DEFAULT_DELETE_OPERATION_CAPTION;
  deleteInfo.operationMessage:= DEFAULT_DELETE_OPERATION_MESSAGE;
  setDeleteCheckedItemsInfo(deleteInfo);

  clearInfo.popupItemName:= DEFAULT_CLEAR_ITEMS_NAME;
  clearInfo.popupItemCaptionFormat:= DEFAULT_CLEAR_ITEMS_FORMAT;
  setClearItemsInfo(clearInfo);


  IOPropertiesXML:= cIOPropertiesXML.create;
  IOPropertiesXML.setUseInMemory(true);
  IOPropertiesXML.setRootNodeName(DEFAULT_METADATA_NODE_NAME);

  fSerializer:= cObjectSerializer.create;

  fSerializer.setSerializerIO(IOPropertiesXML);

  fPasteMapList:= cPasteMapList.create;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.setClearItemsInfo(aInfo: sClearItemsInfo);
begin
  fClearItemsInfo:= aInfo;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.setCopyCheckedItemsInfo(aInfo: sCopyCheckedItemsInfo);
begin
  fCopyCheckedItemsInfo:= aInfo;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.setCutCheckedItemsInfo(aInfo: sCutCheckedItemsInfo);
begin
  fCutCheckedItemsInfo:= aInfo;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.setDeleteCheckedItemsInfo(aInfo: sDeleteCheckedItemsInfo);
begin
  fDeleteCheckedItemsInfo:= aInfo;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.setPasteCheckedItemsInfo(aInfo: sPasteCheckedItemsInfo);
begin
  fPasteCheckedItemsInfo:= aInfo;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.setPasteToViewProc(aPasteToViewProc: cTreeAndTableViewProxyCopyPastePopupDecoratorPasteToViewProc);
begin
  fPasteToViewProc:= aPasteToViewProc;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.clearSerializer;
begin
  fSerializer.clear;
  viewProxy.invalidate;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.copyViewCheckedItems;
begin
  copyViewCheckedItems(false);
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.copyViewCheckedItems(aNeedCut: boolean);
var
  activeRecord: cAbstractTableRow;

  treeViewProxy: cTreeViewProxy;
  tableViewProxy: cTableViewProxy;

  opCaption: string;
  opMessage: string;
begin
  opCaption:= fCopyCheckedItemsInfo.operationCaption;
  opMessage:= fCopyCheckedItemsInfo.operationMessage;
  if (aNeedCut) then begin
    opCaption:= fCutCheckedItemsInfo.operationCaption;
    opMessage:= fCutCheckedItemsInfo.operationMessage;
  end;


  cWaitingForm.show(opCaption, opMessage);
  try

    clearSerializer;

    fLastPopupAction:= paCopy;

    if (viewProxy is cTableViewProxy) then begin
      tableViewProxy:= viewProxy as cTableViewProxy;

      with tableViewProxy, tableViewProxy.getModel do begin

        iterateCheckedRows(

          procedure(aViewRow: integer)
          begin

            activeRecord:= createActiveRecord;
            try
              activeRecord.fetch(getRowKey(viewRowToModelRow(aViewRow)));
              fSerializer.serialize(activeRecord);
            finally
              freeAndNil(activeRecord);
            end;

            if not aNeedCut then begin
              tableViewProxy.setViewRowChecked(aViewRow, false);
            end;
          end
        );

        if aNeedCut then begin
          fLastPopupAction:= paCut;
          deleteSelectedRows;
        end;

      end;

      viewProxy.invalidate;
      exit;
    end;

    if (viewProxy is cTreeViewProxy) then begin
      treeViewProxy:= viewProxy as cTreeViewProxy;

      with treeViewProxy, treeViewProxy.getModel.getTableModel do begin

        iterateCheckedRows(

          procedure(aViewNode: pVirtualNode; aModelItem: cTreeModelItem)
          begin

            activeRecord:= createActiveRecord;
            try
              activeRecord.fetch(aModelItem.id);
              fSerializer.serialize(activeRecord);
            finally
              freeAndNil(activeRecord);
            end;

            if not aNeedCut then begin
              aModelItem.selected:= false;
            end;
          end,
          false
        );

        if aNeedCut then begin
          fLastPopupAction:= paCut;
          model.deleteSelectedItems;
        end;
      end;

      viewProxy.invalidate;
      exit;
    end;
  finally
    cWaitingForm.hide;
  end;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.cutViewCheckedItems;
begin
  copyViewCheckedItems(true);
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.pasteToTableView(aTableViewProxy: cTableViewProxy; aSrcRow: cAbstractTableRow; aDestRow: integer);
var
  appendedRowModelIndex: integer;
  tableModel: cAbstractTableModel;
  newId: int64;
begin
  case fLastPopupAction of
    paCopy : appendedRowModelIndex:= aTableViewProxy.model.appendRow;
    paCut  : appendedRowModelIndex:= aTableViewProxy.model.appendRow(aSrcRow.id);
  end;

  tableModel:= aTableViewProxy.getModel;
  newId:= tableModel.getRowKey(appendedRowModelIndex);



  aSrcRow.id:= newId;

  if assigned(fPasteToViewProc) then begin
    fPasteToViewProc(aTableViewProxy, aSrcRow);
  end;


  aSrcRow.update;

  aTableViewProxy.model.reload(appendedRowModelIndex);
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.pasteToTreeView(aTreeViewProxy: cTreeViewProxy; aSrcRow: cAbstractTableRow; aDestNode: pVirtualNode);
var
  tableModel: cAbstractTableModel;
  foundMapIndex: integer;
  nodeExistsInMap: boolean;
  destParentId: int64;
  destItem: cTreeModelItem;

  newId: int64;

  newRow: cAbstractTableRow;
  newItem: cTreeModelItem;
begin
  newItem:= nil;

  tableModel:= aTreeViewProxy.getModel.getTableModel;

  destItem:= aTreeViewProxy.getModelItemByViewNode(aDestNode);

  foundMapIndex:= fPasteMapList.indexOfFromValue(aSrcRow.getPropertyData(cAbstractTreeModel.DEFAULT_PARENT_ID_FIELD_NAME).value);
  nodeExistsInMap:= (foundMapIndex <> -1);
  if (nodeExistsInMap) then begin
    destParentId:= fPasteMapList.items[foundMapIndex].getToValue;

    case fLastPopupAction of
      paCopy : newId:= tableModel.getRowKey(tableModel.appendRow);
      paCut  : newId:= tableModel.getRowKey(tableModel.appendRow(aSrcRow.id));
    end;

  end else begin
    destParentId:= aTreeViewProxy.getModelItemByViewNode(aDestNode).id;

    case fLastPopupAction of
      paCopy : newItem:= aTreeViewProxy.model.append(destItem, aSrcRow.getPropertyData(cAbstractTreeModel.DEFAULT_TITLE_FIELD_NAME).value);
      paCut  : newItem:= aTreeViewProxy.model.append(destItem, aSrcRow.id, aSrcRow.getPropertyData(cAbstractTreeModel.DEFAULT_TITLE_FIELD_NAME).value);
    end;

    newId:= newItem.id;
  end;

  fPasteMapList.add(cPasteMapItem.create(aSrcRow.id, newId));

  aSrcRow.id:= newId;

  aSrcRow.setPropertyData(cAbstractTreeModel.DEFAULT_PARENT_ID_FIELD_NAME, destParentId);

  if assigned(fPasteToViewProc) then begin
    fPasteToViewProc(aTreeViewProxy, aSrcRow);
  end;

  aSrcRow.update;

  if assigned(newItem) then begin
    aTreeViewProxy.model.reload(newItem);
  end;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.pasteViewCheckedItems;
var
  popupClientPoint: tPoint;

  destNode: pVirtualNode;
  destRow: integer;

  activeRecord: cAbstractTableRow;

  treeViewProxy: cTreeViewProxy;
  tableViewProxy: cTableViewProxy;

  tableModel: cAbstractTableModel;
begin
  cWaitingForm.show(fPasteCheckedItemsInfo.operationCaption, fPasteCheckedItemsInfo.operationMessage);
  try

    fPasteMapList.clear;

    tableModel:= nil;
    tableViewProxy:= nil;
    treeViewProxy:= nil;
    destNode:= nil;

    popupClientPoint:= viewProxy.view.screenToClient(getPopupPoint);

    if (viewProxy is cTableViewProxy) then begin
      tableViewProxy:= viewProxy as cTableViewProxy;
      tableModel:= tableViewProxy.getModel;

      destRow:= tableViewProxy.getViewRowAt(popupClientPoint);
    end;

    if (viewProxy is cTreeViewProxy) then begin
      treeViewProxy:= viewProxy as cTreeViewProxy;
      tableModel:= treeViewProxy.getModel.getTableModel;

      destNode:= treeViewProxy.getViewNodeAt(popupClientPoint);
    end;

    if not assigned(tableModel) then begin
      exit;
    end;

    fSerializer.iterateObjects(
      procedure(aSection: string; aIndex: integer)
      begin
        activeRecord:= tableModel.createActiveRecord;
        try
          fSerializer.deserializeByObjectId(activeRecord, aSection);

          case fLastPopupAction of
            paCopy, paCut:
            begin

              if assigned(tableViewProxy) then begin
                pasteToTableView(tableViewProxy, activeRecord, destRow);
              end;

              if assigned(treeViewProxy) then begin
                pasteToTreeView(treeViewProxy, activeRecord, destNode);
              end;

            end;
          end;

        finally
          freeAndNil(activeRecord);
        end;
      end
    );

    if (fLastPopupAction = paCut) then begin
      clearSerializer;
    end;

    if (viewProxy is cTableViewProxy) then begin
      tableViewProxy.selectViewRow(tableViewProxy.modelRowToViewRow(tableModel.getRowCount - 1));
    end;

    viewProxy.invalidate;
  finally
    cWaitingForm.hide;
  end;
end;

//SLOTS
procedure cTreeAndTableViewProxyCopyPastePopupDecorator.popupItemClicked(aSender: tObject);
var
  popupItem: tMenuItem;
begin
  popupItem:= aSender as tMenuItem;
  if not assigned(popupItem) then begin
    exit;
  end;

  if (popupItem.name = getCopyCheckedItemsInfo.popupItemName) then begin
    copyViewCheckedItems;

    exit;
  end;

  if (popupItem.name = getCutCheckedItemsInfo.popupItemName) then begin
    cutViewCheckedItems;

    exit;
  end;

  if (popupItem.name = getPasteCheckedItemsInfo.popupItemName) then begin

    if (cMessageBox.question
         (
           fPasteCheckedItemsInfo.questionCaption, fPasteCheckedItemsInfo.questionTitle,
           format(fPasteCheckedItemsInfo.questionMessageFormat, [fSerializer.propertiesSectionCount])
         ) = mbbYes
       ) then
    begin
      pasteViewCheckedItems;
    end;

    exit;
  end;

  if (popupItem.name = getDeleteCheckedItemsInfo.popupItemName) then begin
    if (cMessageBox.question
         (
           fDeleteCheckedItemsInfo.questionCaption, fDeleteCheckedItemsInfo.questionTitle,
           format(fDeleteCheckedItemsInfo.questionMessageFormat, [viewProxy.getCheckedCount])
         ) = mbbYes
       ) then
    begin
      deleteViewCheckedItems;
    end;

    exit;
  end;

  if (popupItem.name = getClearItemsInfo.popupItemName) then begin
    clearSerializer;

    exit;
  end;
end;

procedure cTreeAndTableViewProxyCopyPastePopupDecorator.popupInvoked(aSender: tObject);
var
  curItem: tMenuItem;
  i: integer;

  viewCheckedCount: integer;
  propertiesSectionCount: integer;
begin
  viewCheckedCount:= viewProxy.getCheckedCount;
  propertiesSectionCount:= fSerializer.propertiesSectionCount;

  for i:= 0 to menuItemsCount - 1 do begin
    curItem:= getMenuItem(i);

    if (curItem.name = getCopyCheckedItemsInfo.popupItemName) then begin
      curItem.enabled:= (not viewProxy.isEmpty) and (viewCheckedCount > 0);
      curItem.caption:= format(getCopyCheckedItemsInfo.popupItemCaptionFormat, [viewCheckedCount]);

      continue;
    end;

    if (curItem.name = getCutCheckedItemsInfo.popupItemName) then begin
      curItem.enabled:= (not viewProxy.isEmpty) and (viewCheckedCount > 0);
      curItem.caption:= format(getCutCheckedItemsInfo.popupItemCaptionFormat, [viewCheckedCount]);

      continue;
    end;

    if (curItem.name = getPasteCheckedItemsInfo.popupItemName) then begin
      curItem.enabled:= (propertiesSectionCount > 0);
      curItem.caption:= format(getPasteCheckedItemsInfo.popupItemCaptionFormat, [propertiesSectionCount]);

      continue;
    end;

    if (curItem.name = getClearItemsInfo.popupItemName) then begin
      curItem.enabled:= (propertiesSectionCount > 0);
      curItem.caption:= format(getClearItemsInfo.popupItemCaptionFormat, [propertiesSectionCount]);

      continue;
    end;

    if (curItem.name = getDeleteCheckedItemsInfo.popupItemName) then begin
      curItem.enabled:= (not viewProxy.isEmpty) and (viewCheckedCount > 0);
      curItem.caption:= format(getDeleteCheckedItemsInfo.popupItemCaptionFormat, [viewCheckedCount]);

      continue;
    end;

    if (curItem.name = getClearItemsInfo.popupItemName) then begin
      curItem.enabled:= (propertiesSectionCount > 0);
      curItem.caption:= format(getClearItemsInfo.popupItemCaptionFormat, [propertiesSectionCount]);

      continue;
    end;
  end;
end;


{ cPasteIdSubstitutionItem }

constructor cPasteMapItem.create(aFromValue, aToValue: int64);
begin
  inherited create;

  fFromValue:= aFromValue;
  fToValue:= aToValue;
end;

destructor cPasteMapItem.destroy;
begin
  inherited;
end;

function cPasteMapItem.getFromValue: int64;
begin
  result:= fFromValue;
end;

function cPasteMapItem.getToValue: int64;
begin
  result:= fToValue;
end;

{ cPasteIdSubstitutionList }

procedure cPasteMapList.add(aItem: cPasteMapItem);
begin
  fList.add(aItem);
end;

procedure cPasteMapList.clear;
begin
  fList.freeInternalObjects;
  fList.clear;
end;

constructor cPasteMapList.create;
begin
  inherited create;
  fList:= cList.create;
end;

destructor cPasteMapList.destroy;
begin
  if assigned(fList) then begin
    clear;
    freeAndNil(fList);
  end;

  inherited;
end;

function cPasteMapList.getCount: integer;
begin
  result:= fList.count;
end;

function cPasteMapList.getItemByIndex(aIndex: integer): cPasteMapItem;
begin
  result:= fList.items[aIndex];
end;

function cPasteMapList.indexOfFromValue(aFromValue: int64): integer;
var
  curItem: cPasteMapItem;
  i: integer;
begin
  result:= -1;
  for i:= 0 to count - 1 do begin
    curItem:= items[i];
    if (curItem.fFromValue = aFromValue) then begin
      result:= i;
      exit;
    end;
  end;
end;

end.
