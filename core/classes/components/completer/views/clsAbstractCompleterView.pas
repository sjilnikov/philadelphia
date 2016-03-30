unit clsAbstractCompleterView;

interface
uses
  windows,
  math;

type
  cAbstractCompleterView = class;

  tAbstractCompleterViewItemSelectedEvent = procedure(aSender: cAbstractCompleterView; aIndex: integer) of object;

  cAbstractCompleterView = class
  private
    fWidth          : integer;
    fMinWidth       : integer;
    fUpdating       : boolean;
    fOnItemSelected : tAbstractCompleterViewItemSelectedEvent;
  protected

    function    isUpdating: boolean;

    procedure   selectItem(aIndex: integer);
  public
    function    isVisible: boolean; virtual; abstract;

    procedure   selectNextItem(aDelta: integer);

    function    getItemIndexAtPos(aPoint: tPoint): integer; virtual; abstract;

    procedure   beginUpdate; virtual;
    procedure   endUpdate; virtual;

    procedure   setFocus; virtual; abstract;

    procedure   clear; virtual; abstract;

    procedure   setSelectedIndex(aIndex: integer); virtual; abstract;
    function    getSelectedIndex: integer; virtual; abstract;


    procedure   setWidth(aValue: integer); virtual;
    function    getWidth: integer;

    procedure   setMinWidth(aValue: integer); virtual;
    function    getMinWidth: integer;

    procedure   popup(aX, aY: integer); overload; virtual; abstract;
    procedure   popup(aPoint: tPoint); overload; virtual; abstract;

    procedure   hide; virtual; abstract;

    function    getCount: integer; virtual; abstract;
    function    getItemData(aIndex: integer): tObject; virtual; abstract;
    function    getItemText(aIndex: integer): string; virtual; abstract;

    procedure   addItem(aText: string; aObject: tObject = nil); virtual; abstract;

    property    itemData[aIndex: integer]: tObject read getItemData;
    property    itemText[aIndex: integer]: string read getItemText;

    property    count: integer read getCount;
  published
    //EVENTS
    property    onItemSelected: tAbstractCompleterViewItemSelectedEvent read fOnItemSelected write fOnItemSelected;
  end;

  ccCompleterViewItem = class
  private
    fKey : int64;
  public

    constructor create(aKey: int64);

    property    key: int64 read fKey;
  end;


implementation

{ cAbstractCompleterView }

procedure cAbstractCompleterView.beginUpdate;
begin
  fUpdating:= true;
end;

procedure cAbstractCompleterView.selectItem(aIndex: integer);
begin
  if assigned(fOnItemSelected) then begin
    fOnItemSelected(self, aIndex);
  end;
end;

procedure cAbstractCompleterView.endUpdate;
begin
  fUpdating:= false;
end;

function cAbstractCompleterView.getMinWidth: integer;
begin
  result:= fMinWidth;
end;

function cAbstractCompleterView.getWidth: integer;
begin
  result:= fWidth;
end;

procedure cAbstractCompleterView.selectNextItem(aDelta: integer);
var
  newIndex: integer;
begin
  newIndex:= getSelectedIndex;

  newIndex:= newIndex + aDelta;

  newIndex:= min(getCount - 1, newIndex);
  newIndex:= max(0, newIndex);

  setSelectedIndex(newIndex);
end;

function cAbstractCompleterView.isUpdating: boolean;
begin
  result:= fUpdating;
end;

procedure cAbstractCompleterView.setMinWidth(aValue: integer);
begin
  fMinWidth:= aValue;
end;

procedure cAbstractCompleterView.setWidth(aValue: integer);
begin
  fWidth:= aValue;
end;

{ ccCompleterViewItem }

constructor ccCompleterViewItem.create(aKey: int64);
begin
  inherited create;
  fKey:= aKey;
end;

end.
