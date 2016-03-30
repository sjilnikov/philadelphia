unit clsAbstractTableViewProxyDelegate;

interface
uses
  classes,
  windows,
  kGrids,


  uModels,
  clsVariantConversion,

  clsAbstractEditableViewProxy,


  clsAbstractTableModel,
  clsTableViewProxy,
  clsMulticastEvents;

type
  cAbstractTableViewProxyDelegate = class
  public
    constructor create; virtual;
    destructor  destroy; override;
  public
    procedure   rowRendering(aView: cTableViewProxy; aCellPainter: tKGridCellPainter; aModelRow: cAbstractTableRow; aRowStates: tKGridDrawState); virtual;
    procedure   rowRenderingText(aView: cTableViewProxy; aRenderingModelRow: cAbstractTableRow; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aText: string); virtual;

    function    canCreateEditor(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aDefaultCanCreateEditor: boolean): boolean; virtual;

    function    createEditor(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aType: tDataType): cAbstractEditableViewProxy; virtual; abstract;
    procedure   destroyEditor(aView:cTableViewProxy; aEditor: cAbstractEditableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aType: tDataType); virtual; abstract;


    procedure   getEditorData(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aAssignedValue: variant); virtual; abstract;
    procedure   setEditorData(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aAssignedValue: variant); virtual; abstract;

    procedure   updateEditorGeometry(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aRect: tRect); virtual;
  end;

implementation

{ cAbstractTableViewProxyDelegate }

function cAbstractTableViewProxyDelegate.canCreateEditor(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aDefaultCanCreateEditor: boolean): boolean;
begin
  result:= true;
end;

constructor cAbstractTableViewProxyDelegate.create;
begin
  inherited create;
end;

destructor cAbstractTableViewProxyDelegate.destroy;
begin
  inherited;
end;

procedure cAbstractTableViewProxyDelegate.rowRendering(aView: cTableViewProxy; aCellPainter: tKGridCellPainter; aModelRow: cAbstractTableRow; aRowStates: tKGridDrawState);
begin

end;

procedure cAbstractTableViewProxyDelegate.rowRenderingText(aView: cTableViewProxy; aRenderingModelRow: cAbstractTableRow; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aText: string);
begin

end;

procedure cAbstractTableViewProxyDelegate.updateEditorGeometry(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aRect: tRect);
begin

end;

end.
