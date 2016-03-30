unit clsCompleter;

interface

uses
  classes,
  windows,
  sysUtils,
  variants,
  math,

  clsMemoryTableModel,
  clsDynamicalObject,
  clsAbstractCompleterView,
  clsAbstractTableModel,
  clsMulticastEvents;



type

  {$REGION 'forward declaration of cEditableViewProxy'}
  cEditableViewProxyPrivate = type cAnyObject;
  {$ENDREGION}

  cCompleter = class;

  tCompleterItemSelectedEvent = procedure(aCompleter: cCompleter; aIndex: integer; aData: variant) of object;

  tCompleterFilterProc = reference to function(aFilterText: string; aItemText: string): boolean;

  cCompleter = class
  private
    fModel            : cAbstractTableModel;
    fView             : cAbstractCompleterView;
    fDisplayModelCol  : integer;
    fWidth            : integer;
    fMinWidth         : integer;
    fAccepted         : boolean;
    fAutoComplete     : boolean;
    fViewProxy        : cEditableViewProxyPrivate;
    fFilterText       : string;

    fFilterProc       : tCompleterFilterProc;

    fOnItemSelected   : tCompleterItemSelectedEvent;


    procedure   loadModelData;

    procedure   setupViewEvents;
    procedure   disconnectViewEvents;

    procedure   setupViewProxyEvents;
    procedure   disconnectViewProxyEvents;

    procedure   removeView;
    procedure   removeModel;

    procedure   setView(aView: cAbstractCompleterView);

    procedure   setFilter(aText: string);

    function    defaultFilterProc(aFilterText: string; aItemText: string): boolean;
  public
    procedure   setFilterProc(aFilterProc: tCompleterFilterProc);

    procedure   setAutoComplete(aValue: boolean);
    function    isAutoComplete: boolean;

    procedure   acceptItem(aIndex: integer);
    procedure   acceptCurrentItem;

    function    isAccepted: boolean;
    function    isVisible: boolean;

    procedure   refresh;

    procedure   setFocus;

    function    getItemIndexAtPos(aPoint: tPoint): integer;

    procedure   setSelectedIndex(aIndex: integer);
    function    getSelectedIndex: integer;
    procedure   selectNextItem(aDelta: integer);

    procedure   popup(aX, aY: integer); overload;
    procedure   popup(aPoint: tPoint); overload;

    procedure   hide;
    procedure   clear;

    procedure   setDisplayModelCol(aCol: integer);
    function    getDisplayModelCol: integer;

    procedure   setMinWidth(aValue: integer);
    function    getMinWidth: integer;

    procedure   setWidth(aValue: integer);
    function    getWidth: integer;

    procedure   setViewProxy(aViewProxy: cEditableViewProxyPrivate);

    procedure   setModel(aModel: cAbstractTableModel);
    function    getModel: cAbstractTableModel;

    constructor create;
    destructor  destroy; override;
  published
    //EVENTS
    property    onItemSelected: tCompleterItemSelectedEvent read fOnItemSelected write fOnItemSelected;
  published
    //SLOTS
    procedure   viewItemSelected(aSender: cAbstractCompleterView; aIndex: integer);
    procedure   viewProxyChanged(aSender: tObject);
  end;


implementation
uses
  clsAbstractEditableViewProxy,
  clsCompleterListView;

{ cCompleter }

procedure cCompleter.acceptCurrentItem;
begin
  acceptItem(getSelectedIndex);
end;

procedure cCompleter.acceptItem(aIndex: integer);
begin
  fAccepted:= true;
  try
    hide;

    if assigned(fOnItemSelected) then begin
      fOnItemSelected(self, aIndex, fModel.getFieldData(getDisplayModelCol, aIndex));
    end;

  finally
    fAccepted:= false;
    clear;
  end;
end;

procedure cCompleter.clear;
begin
  if (not assigned(fView)) then exit;

  fView.clear;
end;

constructor cCompleter.create;
begin
  inherited create;

  fModel:= nil;
  fFilterText:= '';

  setAutoComplete(false);
  setFilterProc(defaultFilterProc);
  setView(cCompleterListView.create);
end;

function cCompleter.defaultFilterProc(aFilterText, aItemText: string): boolean;
begin
  result:= copy(aItemText, 1, length(aFilterText)) = aFilterText;
end;

destructor cCompleter.destroy;
begin
  disconnectViewProxyEvents;

  disconnectViewEvents;

  removeView;

  inherited;
end;

procedure cCompleter.setupViewEvents;
begin
  if not assigned(fView) then begin
    exit;
  end;

  connect(fView, 'onItemSelected', self, 'viewItemSelected');
end;

procedure cCompleter.setupViewProxyEvents;
begin
  if not assigned(fViewProxy) then begin
    exit;
  end;

  connect(fViewProxy, 'onChanged', self, 'viewProxyChanged');
end;

procedure cCompleter.disconnectViewEvents;
begin
  if not assigned(fView) then begin
    exit;
  end;

  disconnect(fView, 'onItemSelected', self, 'viewItemSelected');
end;

procedure cCompleter.disconnectViewProxyEvents;
begin
  if not assigned(fViewProxy) then begin
    exit;
  end;

  disconnect(fViewProxy, 'onChanged', self, 'viewProxyChanged');
end;

procedure cCompleter.setFilter(aText: string);
begin
  fFilterText:= aText;
end;

procedure cCompleter.setFilterProc(aFilterProc: tCompleterFilterProc);
begin
  fFilterProc:= aFilterProc;
end;

function cCompleter.isAutoComplete: boolean;
begin
  result:= fAutoComplete;
end;

function cCompleter.getDisplayModelCol: integer;
begin
  result:= fDisplayModelCol;
end;

function cCompleter.getItemIndexAtPos(aPoint: tPoint): integer;
begin
  result:= -1;

  if (not assigned(fView)) then exit;

  result:= fView.getItemIndexAtPos(aPoint);
end;

function cCompleter.getMinWidth: integer;
begin
  result:= fMinWidth;
end;

function cCompleter.getModel: cAbstractTableModel;
begin
  result:= fModel;
end;

function cCompleter.getSelectedIndex: integer;
begin
  result:= -1;
  if (not assigned(fView)) then exit;
  result:= fView.getSelectedIndex;
end;

function cCompleter.getWidth: integer;
begin
  result:= fWidth;
end;

procedure cCompleter.hide;
begin
  if (not assigned(fView)) then exit;
  fView.hide;
end;

function cCompleter.isAccepted: boolean;
begin
  result:= fAccepted;
end;

function cCompleter.isVisible: boolean;
begin
  result:= false;
  if (not assigned(fView)) then exit;

  result:= fView.isVisible;
end;

procedure cCompleter.loadModelData;
var
  i: integer;
  displayText: string;
begin

  if (not assigned(fView)) then exit;
  if (not assigned(fModel)) then exit;

  if not ((fDisplayModelCol >= 0) and (fDisplayModelCol < fModel.getFields.count)) then exit;

  clear;

  fView.beginUpdate;
  try

    for i:= 0 to fModel.getRowCount - 1 do begin
      displayText:= varToStr(fModel.getFieldData(fDisplayModelCol, i));

      if (not(isAutoComplete) or (isAutoComplete and (fFilterProc(fFilterText, displayText)))) then begin
        fView.addItem(displayText, ccCompleterViewItem.create(fModel.getRowKey(i)));
      end;
    end;

  finally
    fView.endUpdate;
  end;

  setSelectedIndex(0);
end;

procedure cCompleter.popup(aX, aY: integer);
begin
  if not assigned(fView) then begin
    exit;
  end;

  fView.popup(aX, aY);
end;

procedure cCompleter.popup(aPoint: tPoint);
begin
  if not assigned(fView) then begin
    exit;
  end;

  refresh;

  if (fView.count <> 0) then begin
    fView.popup(aPoint);
  end else begin
    if isVisible then begin
      hide;
    end;

  end;

end;

procedure cCompleter.refresh;
begin
  loadModelData;
end;

procedure cCompleter.removeModel;
begin
  if not assigned(fModel) then begin
    exit;
  end;

  freeAndNil(fModel);
end;

procedure cCompleter.removeView;
begin
  if not assigned(fView) then begin
    exit;
  end;

  freeAndNil(fView);
end;

procedure cCompleter.selectNextItem(aDelta: integer);
begin
  if not assigned(fView) then begin
    exit;
  end;

  fView.selectNextItem(aDelta);
end;

procedure cCompleter.setAutoComplete(aValue: boolean);
begin
  fAutoComplete:= aValue;
end;

procedure cCompleter.setDisplayModelCol(aCol: integer);
begin
  fDisplayModelCol:= aCol;
end;

procedure cCompleter.setFocus;
begin
  fView.setFocus;
end;

procedure cCompleter.setMinWidth(aValue: integer);
begin
  fMinWidth:= aValue;

  fView.setMinWidth(aValue);
end;

procedure cCompleter.setModel(aModel: cAbstractTableModel);
begin
  removeModel;

  fModel:= aModel;
end;

procedure cCompleter.setSelectedIndex(aIndex: integer);
begin
  if (not assigned(fView)) then exit;
  fView.setSelectedIndex(aIndex);
end;

procedure cCompleter.setView(aView: cAbstractCompleterView);
begin
  disconnectViewEvents;

  removeView;

  fView:= aView;

  setupViewEvents;
end;

procedure cCompleter.setViewProxy(aViewProxy: cEditableViewProxyPrivate);
begin
  disconnectViewProxyEvents;

  fViewProxy:= aViewProxy;

  if (isAutoComplete) then begin
    setupViewProxyEvents;
  end;
end;

procedure cCompleter.setWidth(aValue: integer);
begin
  fWidth:= aValue;
  if not assigned(fView) then begin
    exit;
  end;

  fView.setWidth(aValue);
end;

//SLOTS
procedure cCompleter.viewItemSelected(aSender: cAbstractCompleterView; aIndex: integer);
begin
  acceptItem(aIndex);
end;

procedure cCompleter.viewProxyChanged(aSender: tObject);
begin
  if not assigned(fView) then begin
    exit;
  end;

  setFilter(varToStr(cAbstractEditableViewProxy(fViewProxy).getValue));
end;

end.
