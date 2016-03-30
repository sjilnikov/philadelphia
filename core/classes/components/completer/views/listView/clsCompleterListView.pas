unit clsCompleterListView;

interface
uses
  windows,
  sysUtils,

  clsPopupListView,
  clsAbstractCompleterView,

  clsMulticastEvents;

type
  cCompleterListView = class(cAbstractCompleterView)
  private
    fListView   : cPopupListView;

    procedure   setupEvents;
    procedure   disconnectEvents;


  public
    function    isVisible: boolean; override;
    function    getItemIndexAtPos(aPoint: tPoint): integer; override;

    procedure   beginUpdate; override;
    procedure   endUpdate; override;

    procedure   setFocus; override;

    procedure   clear; override;

    procedure   setSelectedIndex(aIndex: integer); override;
    function    getSelectedIndex: integer; override;

    procedure   setMinWidth(aValue: integer); override;
    procedure   setWidth(aValue: integer); override;

    procedure   popup(aX, aY: integer); overload; override;
    procedure   popup(aPoint: tPoint); overload; override;

    procedure   hide; override;

    function    getCount: integer; override;
    function    getItemData(aIndex: integer): tObject; override;
    function    getItemText(aIndex: integer): string; override;

    procedure   addItem(aText: string; aObject: tObject = nil); override;

    constructor create;
    destructor  destroy; override;
  published
    procedure   viewItemSelected(aSender: cPopupListView; aIndex: integer);
  end;

implementation


{ cCompleterListView }

procedure cCompleterListView.beginUpdate;
begin
  inherited;
  fListView.beginUpdate;
end;

procedure cCompleterListView.endUpdate;
begin
  fListView.endUpdate;
  inherited;
end;

procedure cCompleterListView.clear;
begin
  fListView.clear;
end;

constructor cCompleterListView.create;
begin
  inherited create;
  fListView:= cPopupListView.create;

  setupEvents;
end;

destructor cCompleterListView.destroy;
begin
  disconnectEvents;

  if assigned(fListView) then begin
    freeAndNil(fListView);
  end;

  inherited;
end;

procedure cCompleterListView.setFocus;
begin
  fListView.setFocus;
end;

procedure cCompleterListView.setMinWidth(aValue: integer);
begin
  inherited setMinWidth(aValue);

  fListView.setMinWidth(aValue);
end;

procedure cCompleterListView.setSelectedIndex(aIndex: integer);
begin
  fListView.setSelectedIndex(aIndex);
end;

procedure cCompleterListView.setupEvents;
begin
  connect(fListView, 'onItemSelected', self, 'viewItemSelected');
end;

procedure cCompleterListView.disconnectEvents;
begin
  disconnect(fListView, 'onItemSelected', self, 'viewItemSelected');
end;

procedure cCompleterListView.setWidth(aValue: integer);
begin
  inherited setWidth(aValue);

  fListView.setWidth(aValue);
end;

procedure cCompleterListView.addItem(aText: string; aObject: tObject);
begin
  fListView.addItem(aText, aObject);
end;

function cCompleterListView.getCount: integer;
begin
  result:= fListView.getCount;
end;

function cCompleterListView.getItemData(aIndex: integer): tObject;
begin
  result:= fListView.getItemData(aIndex);
end;

function cCompleterListView.getItemIndexAtPos(aPoint: tPoint): integer;
begin
  result:= fListView.getItemIndexAtPos(aPoint);
end;

function cCompleterListView.getItemText(aIndex: integer): string;
begin
  result:= fListView.getItemText(aIndex);
end;

function cCompleterListView.getSelectedIndex: integer;
begin
  result:= fListView.getSelectedIndex;
end;

procedure cCompleterListView.hide;
begin
  fListView.hide;
end;

function cCompleterListView.isVisible: boolean;
begin
  result:= fListView.isVisible;
end;

procedure cCompleterListView.popup(aX, aY: integer);
begin
  fListView.popup(aX, aY);
end;

procedure cCompleterListView.popup(aPoint: tPoint);
begin
  fListView.popup(aPoint);
end;

//SLOTS
procedure cCompleterListView.viewItemSelected(aSender: cPopupListView; aIndex: integer);
begin
  selectItem(aIndex);
end;

end.
