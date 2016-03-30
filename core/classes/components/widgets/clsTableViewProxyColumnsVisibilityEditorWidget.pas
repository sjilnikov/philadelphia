unit clsTableViewProxyColumnsVisibilityEditorWidget;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  KControls,
  KGrids,
  ExtCtrls,
  Buttons,
  ComCtrls,

  uModels,

  clsIncSearchDecorator,

  clsAbstractEditableViewProxy,
  clsFormDecorator,
  clsStringUtils,
  clsException,
  clsCompleter,
  clsApplicationConfig,
  clsMessageBox,
  clsMemory,
  clsEditViewProxy,
  clsAbstractViewProxy,
  clsAbstractTableModel,
  clsFrmSQLFilterEditor,
  clsAbstractSQLConnection,
  clsTableViewProxy,
  clsMemoryTableModel,
  clsMulticastEvents,
  clsSQLTableModel,
  clsClassKit,
  clsDBTypeConversion,
  clsVariantConversion;

type
  {$REGION 'UI'}
  tfrmTableViewProxyColumnsVisibility = class(TForm)
    gFields: TKGrid;
  private
    fFieldsViewProxy  : cTableViewProxy;

    procedure   createProxies;
    procedure   setupProxies;
    procedure   removeProxies;
  public
    constructor create(aOwner: tComponent); virtual;
    destructor  destroy; override;

    property    fieldsViewProxy: cTableViewProxy read fFieldsViewProxy;
  end;
  {$ENDREGION}


  eTableViewProxyColumnsVisibility = class(cException);

  cTableViewProxyColumnsVisibilityWidget = class
  private
    {$REGION 'CONST'}

    const

    ID_FIELD_NAME                   = 'id';
    COLUMN_TITLE_FIELD_NAME         = 'columnTitle';
    COLUMN_NAME_FIELD_NAME          = 'columnName';
    COLUMN_WIDTH_FIELD_NAME         = 'columnWidth';
    COLUMN_VISIBILITY_FIELD_NAME    = 'visibility';

    SELECTOR_TITLE                  = 'Селектор';

    CAPTION_FORMAT                  = 'Колонки - [%s]';
    VIEW_PROXY_NOT_ASSIGNED         = 'view proxy not assigned';
    VIEW_PROXY_MODEL_NOT_ASSIGNED   = 'view proxy model not assigned';

    CONFIG_SECTION_NAME             = 'tableColumnsVisibility';

    CONFIG_FORM_STATE_NAME          = 'formState';
    CONFIG_FIELDS_VIEW_STATE_NAME   = 'fieldsViewState';
    {$ENDREGION}
  private
    fUi                            : tFrmTableViewProxyColumnsVisibility;
    fViewProxy                     : cTableViewProxy;
    fFieldsModel                   : cMemoryTableModel;

    fFormDecorator                 : cFormDecorator;
    fFieldsIncSearchDecorator      : cIncSearchDecorator;

    procedure   updateCaption;

    procedure   checkViewProxyAssigned;

    procedure   createUi;
    procedure   removeUi;

    procedure   setupUi;

    function    addRowToFieldsModel: integer;
    procedure   setupFieldsViewProxy;
    procedure   setupFieldsModel;

    procedure   createDecorators;
    procedure   removeDecorators;
    procedure   setupDecorators;

    procedure   createFieldsModel;
    procedure   removeFieldsModel;

    procedure   setupUiEvents;
    procedure   disconnectUiEvents;

    procedure   setupFieldsModelEvents;
    procedure   disconnectFieldsModelEvents;

    procedure   initialize;

    procedure   saveState;
    procedure   restoreState;

    function    getConfigSectionName: string;
    procedure   updateFieldsModel(aRow: integer; aColumnName: string; aColumnTitle: string; aVisibility: boolean; aWidth: integer);

    procedure   loadColumns;
  public
    function    showModal: tModalResult;

    procedure   setViewProxy(aViewProxy: cTableViewProxy);
    function    getViewProxy: cTableViewProxy;

    constructor create;
    destructor  destroy; override;

    property    ui: tFrmTableViewProxyColumnsVisibility read fUi;
    property    viewProxy: cTableViewProxy read getViewProxy write setViewProxy;
  published
    {$REGION 'SLOTS'}
    procedure   fieldsModelDataChanged(aModel: cAbstractTableModel; aType: tAbstractTableModelDataChangedType);

    function    fieldsCreateTableEditor(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aType: tDataType): cAbstractEditableViewProxy;
    {$ENDREGION}
  end;

implementation

{$R *.dfm}

{$REGION 'UI'}

{ tFrmTableColumnsVisibility }

constructor tfrmTableViewProxyColumnsVisibility.create(aOwner: tComponent);
begin
  inherited create(aOwner);

  createProxies;
  setupProxies;
end;

destructor tfrmTableViewProxyColumnsVisibility.destroy;
begin
  removeProxies;

  inherited;
end;

procedure tfrmTableViewProxyColumnsVisibility.createProxies;
begin
  fFieldsViewProxy:= cTableViewProxy.create;
end;

procedure tfrmTableViewProxyColumnsVisibility.removeProxies;
begin
  if assigned(fFieldsViewProxy) then begin
    freeAndNil(fFieldsViewProxy);
  end;
end;

procedure tfrmTableViewProxyColumnsVisibility.setupProxies;
begin
  fFieldsViewProxy.setFocusedTextColor(clWhite);

  fFieldsViewProxy.setView(gFields);
end;
{$ENDREGION}

{ cFrmTableColumnsVisibilityWidget }

constructor cTableViewProxyColumnsVisibilityWidget.create;
begin
  inherited create;

  createUi;
  setupUiEvents;

  setupUi;

  createFieldsModel;
  setupFieldsModel;
  setupFieldsViewProxy;

  createDecorators;
  setupDecorators;

  initialize;
end;

destructor cTableViewProxyColumnsVisibilityWidget.destroy;
begin
  try
    saveState;
  finally
    removeDecorators;
    disconnectUiEvents;

    removeUi;

    disconnectFieldsModelEvents;
    removeFieldsModel;

    inherited;
  end;
end;

procedure cTableViewProxyColumnsVisibilityWidget.createUi;
begin
  fUi:= tFrmTableViewProxyColumnsVisibility.create(nil);
end;

procedure cTableViewProxyColumnsVisibilityWidget.removeUi;
begin
  if assigned(fUi) then begin
    freeAndNil(fUi);
  end;
end;

procedure cTableViewProxyColumnsVisibilityWidget.createDecorators;
begin
  fFieldsIncSearchDecorator:= cIncSearchDecorator.create;

  fFormDecorator:= cFormDecorator.create;
end;

procedure cTableViewProxyColumnsVisibilityWidget.createFieldsModel;
begin
  fFieldsModel:= cMemoryTableModel.create;
end;

procedure cTableViewProxyColumnsVisibilityWidget.removeDecorators;
begin
  if assigned(fFormDecorator) then begin
    freeAndNil(fFormDecorator);
  end;

  if assigned(fFieldsIncSearchDecorator) then begin
    freeAndNil(fFieldsIncSearchDecorator);
  end;
end;

procedure cTableViewProxyColumnsVisibilityWidget.removeFieldsModel;
begin
  freeAndNil(fFieldsModel);
end;

function cTableViewProxyColumnsVisibilityWidget.addRowToFieldsModel: integer;
begin
  result:= fFieldsModel.appendRow;
end;

function cTableViewProxyColumnsVisibilityWidget.getConfigSectionName: string;
begin
  checkViewProxyAssigned;

  result:= format('%s.%s', [CONFIG_SECTION_NAME, getViewProxy.model.className]);
end;

procedure cTableViewProxyColumnsVisibilityWidget.checkViewProxyAssigned;
begin
  if not assigned(fViewProxy) then begin
    raise eTableViewProxyColumnsVisibility.create(VIEW_PROXY_NOT_ASSIGNED);
  end;

  if not assigned(fViewProxy.model) then begin
    raise eTableViewProxyColumnsVisibility.create(VIEW_PROXY_MODEL_NOT_ASSIGNED);
  end;
end;

function cTableViewProxyColumnsVisibilityWidget.getViewProxy: cTableViewProxy;
begin
  result:= fViewProxy;
end;

procedure cTableViewProxyColumnsVisibilityWidget.initialize;
begin
end;

procedure cTableViewProxyColumnsVisibilityWidget.loadColumns;
var
  i: integer;
  viewCol: integer;

  modelFields: cTableFields;
  curField: cTableField;

  fieldTitle: string;
begin
  if (not assigned(fViewProxy)) then begin
    exit;
  end;

  if (not assigned(fViewProxy.model)) then begin
    exit;
  end;

  modelFields:= fViewProxy.model.getFields;

  for i := 0 to modelFields.count - 1 do begin
    curField:= modelFields.items[i];

    fieldTitle:= curField.title;
    if (curField.isSelector) then begin
      fieldTitle:= SELECTOR_TITLE;
    end;

    viewCol:= fViewProxy.modelColToViewCol(i);

    updateFieldsModel(addRowToFieldsModel, curField.name, fieldTitle, fViewProxy.isColVisible(viewCol), fViewProxy.getColWidth(viewCol));
  end;
  setupFieldsModelEvents;
  restoreState;
end;

procedure cTableViewProxyColumnsVisibilityWidget.setupDecorators;
begin
  with fFieldsIncSearchDecorator do begin
    setSearchDirection(sdForward);
    setViewProxy(ui.fieldsViewProxy);
  end;

  with fFormDecorator do begin
    setForm(ui);
    setCloseQuestionInfo('Закрытие формы', 'Форма закрывается', 'подтвердите операцию');
  end;
end;

procedure cTableViewProxyColumnsVisibilityWidget.setupFieldsModel;
begin
  with fFieldsModel do begin
    addField(ID_FIELD_NAME, 'Код', dtInt64, 0, true, false);
    addField(COLUMN_NAME_FIELD_NAME, 'Название колонки', dtString, 40, false, false);
    addField(COLUMN_TITLE_FIELD_NAME, 'Колонка', dtString, 40, false, false);
    addField(COLUMN_VISIBILITY_FIELD_NAME, 'Видимость', dtBoolean, 0, false, false);
    addField(COLUMN_WIDTH_FIELD_NAME, 'Ширина', dtInteger, 0, false, false);

    setKeyField('id');

    fetch('1=1', NO_CONSIDER_LIMIT, NO_CONSIDER_OFFSET);
  end;
end;

procedure cTableViewProxyColumnsVisibilityWidget.setupFieldsViewProxy;
begin
  with ui.fieldsViewProxy, fFieldsModel.getFields do begin

    setModel(fFieldsModel);

    setColSizing(true);
    setSortable(true);
    setEditable(true);

    setSelectedFramePenStyle(psClear);

    render;

    setColWidth(modelColToViewCol(indexOfName(COLUMN_TITLE_FIELD_NAME)), 150);
    setColWidth(modelColToViewCol(indexOfName(COLUMN_VISIBILITY_FIELD_NAME)), 50);

    setColVisible(modelColToViewCol(indexOfName(ID_FIELD_NAME)), false);
    setColVisible(modelColToViewCol(indexOfName(COLUMN_NAME_FIELD_NAME)), false);
    setColVisible(modelColToViewCol(indexOfName(COLUMN_WIDTH_FIELD_NAME)), false);

    selectViewCol(modelColToViewCol(indexOfName(COLUMN_TITLE_FIELD_NAME)));
  end;
end;

{$REGION 'SETUP MODEL EVENTS'}
procedure cTableViewProxyColumnsVisibilityWidget.setupFieldsModelEvents;
begin
  connect(fFieldsModel, 'onDataChanged', self, 'fieldsModelDataChanged');
end;

procedure cTableViewProxyColumnsVisibilityWidget.disconnectFieldsModelEvents;
begin
  disconnect(fFieldsModel, 'onDataChanged', self, 'fieldsModelDataChanged');
end;

{$ENDREGION}

{$REGION 'SETUP UI EVENTS'}
procedure cTableViewProxyColumnsVisibilityWidget.setupUi;
begin
//  fUi.fieldsViewProxy.setEditable(false);
end;

procedure cTableViewProxyColumnsVisibilityWidget.setupUiEvents;
begin
  connect(ui.fieldsViewProxy, 'onCreateEditor', self, 'fieldsCreateTableEditor');
end;

procedure cTableViewProxyColumnsVisibilityWidget.setViewProxy(aViewProxy: cTableViewProxy);
begin
  fViewProxy:= aViewProxy;

  checkViewProxyAssigned;

  updateCaption;

  loadColumns;
end;

procedure cTableViewProxyColumnsVisibilityWidget.disconnectUiEvents;
begin
  disconnect(ui.fieldsViewProxy);
end;

{$ENDREGION}

function cTableViewProxyColumnsVisibilityWidget.showModal: tModalResult;
begin
  checkViewProxyAssigned;

  result:= ui.showModal;
end;

procedure cTableViewProxyColumnsVisibilityWidget.updateCaption;
var
  newCaption: string;
  displayName: string;
begin
  displayName:= '';
  if assigned(fViewProxy) then begin
    displayName:= fViewProxy.getModel.className;
  end;

  newCaption:= format(CAPTION_FORMAT, [displayName]);

  fUi.caption:= newCaption;
end;

procedure cTableViewProxyColumnsVisibilityWidget.updateFieldsModel(aRow: integer; aColumnName: string; aColumnTitle: string; aVisibility: boolean; aWidth: integer);
begin
  with fFieldsModel do begin
    setFieldData(COLUMN_NAME_FIELD_NAME, aRow, aColumnName);
    setFieldData(COLUMN_TITLE_FIELD_NAME, aRow, aColumnTitle);
    setFieldData(COLUMN_VISIBILITY_FIELD_NAME, aRow, aVisibility);
    setFieldData(COLUMN_WIDTH_FIELD_NAME, aRow, aWidth);
  end;
end;

{$REGION 'SAVE/RESTORE OPTIONS'}

procedure cTableViewProxyColumnsVisibilityWidget.saveState;
begin
  if (not assigned(fViewProxy)) then begin
    exit;
  end;

  try
    with cApplicationConfig.getInstance do begin
      writeSection(getConfigSectionName, dtByteArray, CONFIG_FORM_STATE_NAME, fFormDecorator.saveState);
      writeSection(getConfigSectionName, dtByteArray, CONFIG_FIELDS_VIEW_STATE_NAME, ui.fieldsViewProxy.saveState);
    end;
  except
    on e: exception do begin
      cMessageBox.critical('Ошибка сохранения', 'Внимание!', 'Возникла ошибка при попытке сохранить текущее состояние.', e.message);
    end;
  end;
end;

procedure cTableViewProxyColumnsVisibilityWidget.restoreState;
begin
  if (not assigned(fViewProxy)) then begin
    exit;
  end;

  try
    with cApplicationConfig.getInstance do begin
      fFormDecorator.restoreState(readSection(getConfigSectionName, dtByteArray, CONFIG_FORM_STATE_NAME, ''));
      ui.fieldsViewProxy.restoreState(readSection(getConfigSectionName, dtByteArray, CONFIG_FIELDS_VIEW_STATE_NAME, ''));
    end;
  except
    on e: exception do begin
      cMessageBox.critical('Ошибка восстановления', 'Внимание!', 'Возникла ошибка при попытке восстановить предыдущее состояние.', e.message);
    end;
  end;
end;


{$ENDREGION}

{$REGION 'SLOTS'}
function cTableViewProxyColumnsVisibilityWidget.fieldsCreateTableEditor(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aType: tDataType): cAbstractEditableViewProxy;
begin
  result:= nil;
end;

procedure cTableViewProxyColumnsVisibilityWidget.fieldsModelDataChanged(aModel: cAbstractTableModel; aType: tAbstractTableModelDataChangedType);
const
  DEFAULT_COLUMN_WIDTH = 100;
var
  columnName: string;
  columnIndex: integer;
  columnVisible: boolean;
  columnWidth: integer;

  selectedModelRow: integer;

  newWidth: integer;
begin
  selectedModelRow:= ui.fieldsViewProxy.viewRowToModelRow(ui.fieldsViewProxy.getViewRow);

  columnName:= fFieldsModel.getFieldData(COLUMN_NAME_FIELD_NAME, selectedModelRow);
  columnIndex:= fViewProxy.modelColToViewCol(fViewProxy.model.getFields.indexOfName(columnName));
  columnVisible:= fFieldsModel.getFieldData(COLUMN_VISIBILITY_FIELD_NAME, selectedModelRow);
  columnWidth:= fFieldsModel.getFieldData(COLUMN_WIDTH_FIELD_NAME, selectedModelRow);

  if (fViewProxy.isColVisible(columnIndex) <> columnVisible) then begin

    if (columnVisible) then begin


      if (columnWidth = 0) then begin
        newWidth:= DEFAULT_COLUMN_WIDTH;
      end else begin
        newWidth:= columnWidth;
      end;

      fViewProxy.setColWidth(columnIndex, newWidth);

    end else begin
      fViewProxy.setColVisible(columnIndex, false);
    end;

  end;
end;

{$ENDREGION}

end.
