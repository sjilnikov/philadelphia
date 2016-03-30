unit clsComboBoxViewProxy;

interface
uses
  messages,
  variants,
  graphics,
  classes,
  controls,
  stdCtrls,
  sysUtils,
  math,
  db,

  uModels,

  clsComponentUtils,
  clsAbstractTableModel,
  clsClassKit,
  clsAbstractEditableViewProxy;

type

  cComboBoxViewProxy = class(cAbstractEditableViewProxy)
  private
    fModel            : cAbstractTableModel;
    fDropDownAutoSize : boolean;
    fDisplayModelCol  : integer;
    fRendered         : boolean;

    function    getCastedView: tComboBox;

    function    getViewValue: variant; override;
    procedure   setViewValue(aValue: variant); override;

    procedure   setupViewEvents; override;
    procedure   disconnectViewEvents; override;

    function    getCount: integer;
    function    getItemData(aIndex: integer): tObject;
    function    getItemText(aIndex: integer): string;

    procedure   setItemText(aItemIndex: integer; const aValue: string);
    procedure   setItemData(aItemIndex: integer; aObject: tObject);

    procedure   tryToLoadModelData;

    procedure   setupModelEvents;
    procedure   disconnectModelEvents;

    const

    INVALID_INDEX = 'list index: %d out of bounds';
  public
    function    getModel: cAbstractTableModel;

    function    getSelectedModelKey: int64;

    procedure   setEditable(aValue: boolean);
    function    isEditable: boolean;

    procedure   setDropDownAutoSize(aValue: boolean);

    procedure   setItemIndex(aIndex: integer);
    function    getItemIndex: integer;

    procedure   addItem(aText: string; aData: tObject=nil);
    procedure   deleteItem(aIndex: integer);

    procedure   setDisplayModelCol(aCol: integer);
    function    getDisplayModelCol: integer;

    procedure   setView(aView: tWinControl); override;
    procedure   setModel(aModel: cAbstractTableModel);

    function    getFont: tFont;

    procedure   clear;

    function    getSelectedItemData: tObject;


    constructor create;
    destructor  destroy; override;

    property    itemData[aIndex: integer]: tObject read getItemData;
    property    itemText[aIndex: integer]: string read getItemText;

    property    count: integer read getCount;

  published
    property    model: cAbstractTableModel read getModel;

    //SLOTS
    procedure   dropDown(aSender: tObject);

    procedure   modelDataFetched(aModel: cAbstractTableModel; const aCommand: string; const aCondition: string; aLimit: integer; aOffset: integer);
    procedure   modelRowReloaded(aModel: cAbstractTableModel; aRow: integer);
    procedure   modelRowDeleting(aModel: cAbstractTableModel; aRow: integer);
    procedure   modelRowAppended(aModel: cAbstractTableModel; aRow: integer);
  end;

implementation
uses
  clsMulticastEvents;

{ cComboBoxViewProxy }

function cComboBoxViewProxy.getCastedView: tComboBox;
begin
  result:= fView as tComboBox;
end;

function cComboBoxViewProxy.getCount: integer;
begin
  result:= 0;

  if not assigned(fView) then exit;

  result:= getCastedView.items.count;
end;

function cComboBoxViewProxy.getDisplayModelCol: integer;
begin
  result:= fDisplayModelCol;
end;

procedure cComboBoxViewProxy.addItem(aText: string; aData: tObject);
begin
  if (not assigned(fView)) then exit;

  getCastedView.addItem(aText, aData);
end;

procedure cComboBoxViewProxy.clear;
var
  i: integer;
  itemData: tObject;
begin
  for i:= 0 to count - 1 do begin

    itemData:= getItemData(i);

    if assigned(itemData) then begin
      freeAndNil(itemData);
    end;

  end;

  getCastedView.clear;
end;

constructor cComboBoxViewProxy.create;
begin
  inherited create;
  fDisplayModelCol:= -1;
end;

procedure cComboBoxViewProxy.deleteItem(aIndex: integer);
begin
  if (not assigned(fView)) then exit;

  getCastedView.items.delete(aIndex);
end;

destructor cComboBoxViewProxy.destroy;
begin
  disconnectModelEvents;

  clear;
  inherited;
end;

procedure cComboBoxViewProxy.disconnectModelEvents;
begin
  if not assigned(fModel) then exit;

  disconnect(fModel, 'onDataFetched', self, 'modelDataFetched');
  disconnect(fModel, 'onRowReloaded', self, 'modelRowReloaded');
  disconnect(fModel, 'onRowAppended', self, 'modelRowAppended');
  disconnect(fModel, 'onRowDeleting', self, 'modelRowDeleting');
end;

procedure cComboBoxViewProxy.disconnectViewEvents;
begin
  inherited disconnectViewEvents;

  if (not(assigned(fView))) then exit;

  disconnect(fView, 'onDropDown', self, 'dropDown');
  disconnect(fView, 'onClick'   , self, 'changed');
end;

function cComboBoxViewProxy.getFont: tFont;
begin
  result:= nil;
  if (not assigned(fView)) then exit;

  result:= getCastedView.font;
end;

function cComboBoxViewProxy.getItemData(aIndex: integer): tObject;
begin
  result:= nil;

  if not assigned(fView) then exit;

  result:= getCastedView.items.objects[aIndex];
end;

function cComboBoxViewProxy.getItemIndex: integer;
begin
  result:= -1;
  if (not assigned(fView)) then exit;

  result:= getCastedView.itemIndex;
end;

function cComboBoxViewProxy.getItemText(aIndex: integer): string;
begin
  result:= '';

  if not assigned(fView) then exit;

  result:= getCastedView.items[aIndex];
end;

function cComboBoxViewProxy.getModel: cAbstractTableModel;
begin
  result:= fModel;
end;

function cComboBoxViewProxy.getSelectedModelKey: int64;
var
  fieldData: variant;
begin
  fieldData:= getModel.getFieldData(getModel.getFields.getKeyFieldIndex, getItemIndex);
  if (fieldData = NULL) then begin
    result:= NOT_VALID_KEY_ID;
  end else begin
    result:= fieldData;
  end;
end;

function cComboBoxViewProxy.getSelectedItemData: tObject;
var
  selIndex: integer;
begin
  result:= nil;
  selIndex:= getItemIndex;
  if (selIndex = -1) then exit;

  result:= itemData[selIndex];
end;

function cComboBoxViewProxy.getViewValue: variant;
begin
  result:= getCastedView.text;
end;

function cComboBoxViewProxy.isEditable: boolean;
begin
  result:= false;

  if not assigned(fView) then exit;

  result:= getCastedView.style <> csDropDownList;
end;

procedure cComboBoxViewProxy.tryToLoadModelData;
var
  i: integer;
begin
  if (fRendered) then exit;

  if (not assigned(fView)) then exit;
  if (not assigned(fModel)) then exit;

  if not ((fDisplayModelCol >= 0) and (fDisplayModelCol < fModel.getFields.count)) then exit;

  clear;

  for i:= 0 to fModel.getRowCount - 1 do begin
    addItem(varToStr(fModel.getFieldData(fDisplayModelCol, i)));
  end;

  fRendered:= true;

  setItemIndex(-1);
end;

procedure cComboBoxViewProxy.setDisplayModelCol(aCol: integer);
begin
  fDisplayModelCol:= aCol;

  tryToLoadModelData;
end;

procedure cComboBoxViewProxy.setDropDownAutoSize(aValue: boolean);
begin
  fDropDownAutoSize:= aValue;
end;

procedure cComboBoxViewProxy.setEditable(aValue: boolean);
begin
  if not assigned(fView) then exit;

  if (aValue) then begin
    getCastedView.style:= csDropDown;
  end else begin
    getCastedView.style:= csDropDownList;
  end;
end;

procedure cComboBoxViewProxy.setModel(aModel: cAbstractTableModel);
begin
  disconnectModelEvents;

  fModel:= aModel;

  setupModelEvents;

  tryToLoadModelData;
end;

procedure cComboBoxViewProxy.setupModelEvents;
begin
  if not assigned(fModel) then exit;

  connect(fModel, 'onDataFetched', self, 'modelDataFetched');
  connect(fModel, 'onRowReloaded', self, 'modelRowReloaded');
  connect(fModel, 'onRowAppended', self, 'modelRowAppended');
  connect(fModel, 'onRowDeleting', self, 'modelRowDeleting');
end;

procedure cComboBoxViewProxy.setupViewEvents;
begin
  inherited setupViewEvents;

  connect(fView, 'onDropDown', self, 'dropDown');
  connect(fView, 'onClick', self, 'changed');
end;

procedure cComboBoxViewProxy.setView(aView: tWinControl);
begin
  inherited setView(aView);

  if (assigned(aView)) and (not (aView is tComboBox)) then begin
    raise eClassError.createFmt(INVALID_CLASS_RECEIVED, [tComboBox.className, aView.className]);
  end;

  clear;

  tryToLoadModelData;

  setItemIndex(-1);
end;

procedure cComboBoxViewProxy.setItemData(aItemIndex: integer; aObject: tObject);
begin
  if (not assigned(fView)) then exit;

  getCastedView.items.objects[aItemIndex]:= aObject;
end;

procedure cComboBoxViewProxy.setItemIndex(aIndex: integer);
begin
  if (not assigned(fView)) then exit;

  if (aIndex >= -1) and (aIndex < count) then begin
    getCastedView.itemIndex:= aIndex;
  end else begin
    raise eListError.createFmt(INVALID_INDEX, [aIndex]);
  end;
end;

procedure cComboBoxViewProxy.setItemText(aItemIndex: integer; const aValue: string);
begin
  if (not assigned(fView)) then exit;

  getCastedView.items.strings[aItemIndex]:= aValue;
end;

procedure cComboBoxViewProxy.setViewValue(aValue: variant);
begin
  if (aValue = NULL) then begin
    aValue:= '';
  end;

  setItemIndex(getCastedView.items.indexOf(aValue));
end;


//SLOTS
procedure cComboBoxViewProxy.dropDown(aSender: tObject);
const
  DROP_DOWN_BORDER_SIZE = 16;
var
  dropDownWidth: integer;

  comboBox: tComboBox;
begin
  if (not fDropDownAutoSize) then exit;


  comboBox:= getCastedView;


  dropDownWidth:= max(comboBox.width, cComponentUtils.getWidthForStrings(comboBox.canvas, comboBox.items));
  comboBox.perform(CB_SETDROPPEDWIDTH, 2 * DROP_DOWN_BORDER_SIZE + dropDownWidth , 0);
end;

procedure cComboBoxViewProxy.modelDataFetched(aModel: cAbstractTableModel; const aCommand, aCondition: string; aLimit, aOffset: integer);
begin
  fRendered:= false;

  tryToLoadModelData;
end;

procedure cComboBoxViewProxy.modelRowAppended(aModel: cAbstractTableModel; aRow: integer);
begin
  addItem(varToStr(fModel.getFieldData(fDisplayModelCol, aRow)));
end;

procedure cComboBoxViewProxy.modelRowDeleting(aModel: cAbstractTableModel; aRow: integer);
begin
  deleteItem(aRow);
end;

procedure cComboBoxViewProxy.modelRowReloaded(aModel: cAbstractTableModel; aRow: integer);
begin
  setItemText(aRow, varToStr(fModel.getFieldData(fDisplayModelCol, aRow)));
end;

end.
