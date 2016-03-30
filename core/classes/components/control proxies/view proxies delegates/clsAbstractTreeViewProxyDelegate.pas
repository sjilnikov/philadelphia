unit clsAbstractTreeViewProxyDelegate;

interface
uses
  classes,
  windows,
  kGrids,
  virtualTrees,

  uModels,
  clsVariantConversion,

  clsAbstractEditableViewProxy,


  clsAbstractTreeModel,
  clsTreeViewProxy,
  clsMulticastEvents;

type
  cAbstractTreeViewProxyDelegate = class
  public
    constructor create; virtual;
    destructor  destroy; override;
  public
    procedure renderingNode(aSender: cTreeViewProxy; aModelItem: cTreeModelItem; aCellPainter: cTreeCellPainter; aNodeStates: tVirtualNodeStates); virtual;
    procedure renderingNodeText(aSender: cTreeViewProxy; aModelItem: cTreeModelItem; var aText: string); virtual;
    procedure renderedNode(aSender: cTreeViewProxy; aModelItem: cTreeModelItem; aCellPainter: cTreeCellPainter; aNodeStates: tVirtualNodeStates); virtual;


    function  canCreateEditor(aView: cTreeViewProxy; aItem: cTreeModelItem; aDefaultCanCreateEditor: boolean): boolean; virtual;

    function  createEditor(aView: cTreeViewProxy; aItem: cTreeModelItem): cAbstractEditableViewProxy; virtual; abstract;
    procedure destroyEditor(aView: cTreeViewProxy; aEditor: cAbstractEditableViewProxy; aItem: cTreeModelItem); virtual; abstract;

    procedure getEditorData(aView: cTreeViewProxy; fModel: cAbstractTreeModel; aEditor: cAbstractEditableViewProxy; aItem: cTreeModelItem; var aAssignedTitle: string); virtual; abstract;
    procedure setEditorData(aView: cTreeViewProxy; fModel: cAbstractTreeModel; aEditor: cAbstractEditableViewProxy; aItem: cTreeModelItem; var aAssignedTile: string); virtual; abstract;

    procedure updateEditorGeometry(aView: cTreeViewProxy; fModel: cAbstractTreeModel; aEditor: cAbstractEditableViewProxy; aItem: cTreeModelItem; var aRect: tRect); virtual;
  end;

implementation

{ cAbstractTreeViewProxyDelegate }

function cAbstractTreeViewProxyDelegate.canCreateEditor(aView: cTreeViewProxy; aItem: cTreeModelItem; aDefaultCanCreateEditor: boolean): boolean;
begin
  result:= true;
end;

constructor cAbstractTreeViewProxyDelegate.create;
begin
  inherited create;
end;

destructor cAbstractTreeViewProxyDelegate.destroy;
begin
  inherited;
end;

procedure cAbstractTreeViewProxyDelegate.renderedNode(aSender: cTreeViewProxy; aModelItem: cTreeModelItem; aCellPainter: cTreeCellPainter; aNodeStates: tVirtualNodeStates);
begin

end;

procedure cAbstractTreeViewProxyDelegate.renderingNode(aSender: cTreeViewProxy; aModelItem: cTreeModelItem; aCellPainter: cTreeCellPainter; aNodeStates: tVirtualNodeStates);
begin

end;

procedure cAbstractTreeViewProxyDelegate.renderingNodeText(aSender: cTreeViewProxy; aModelItem: cTreeModelItem; var aText: string);
begin

end;

procedure cAbstractTreeViewProxyDelegate.updateEditorGeometry(aView: cTreeViewProxy; fModel: cAbstractTreeModel; aEditor: cAbstractEditableViewProxy; aItem: cTreeModelItem; var aRect: tRect);
begin

end;

end.

