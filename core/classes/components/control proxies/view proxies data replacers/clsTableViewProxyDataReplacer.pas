unit clsTableViewProxyDataReplacer;

interface
uses
  classes,
  windows,
  variants,
  kGrids,


  uModels,
  clsVariantConversion,

  clsAbstractEditableViewProxy,


  clsAbstractTableModel,
  clsTableViewProxy,
  clsMulticastEvents;

type
  cTableViewProxyDataReplacer = class
  private
    fSetEditorData: variant;
    fSetEditorReplaceData: variant;
    fGetEditorData: variant;
    fGetEditorReplaceData: variant;
  public
    constructor create(aSetEditorData: variant; aSetEditorReplaceData: variant; aGetEditorData: variant; aGetEditorReplaceData: variant);
    destructor  destroy; override;
  public
    procedure   rowRenderingText(aView: cTableViewProxy; aRenderingModelRow: cAbstractTableRow; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aText: string);
    procedure   getEditorData(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aAssignedValue: variant);
    procedure   setEditorData(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aAssignedValue: variant);
  end;

implementation

{ cAbstractTableViewProxyDataReplacer }

constructor cTableViewProxyDataReplacer.create(aSetEditorData: variant; aSetEditorReplaceData: variant; aGetEditorData: variant; aGetEditorReplaceData: variant);
begin
  inherited create;
  fSetEditorData:= aSetEditorData;
  fSetEditorReplaceData:= aSetEditorReplaceData;

  fGetEditorData:= aGetEditorData;
  fGetEditorReplaceData:= aGetEditorReplaceData;
end;

destructor cTableViewProxyDataReplacer.destroy;
begin
  inherited;
end;

procedure cTableViewProxyDataReplacer.getEditorData(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aAssignedValue: variant);
begin
  if (aAssignedValue = fGetEditorData) then begin
    aAssignedValue:= fGetEditorReplaceData;
  end;
end;

procedure cTableViewProxyDataReplacer.rowRenderingText(aView: cTableViewProxy; aRenderingModelRow: cAbstractTableRow; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aText: string);
begin
  if (aText = varToStr(fSetEditorData)) then begin
    aText:= varToStr(fSetEditorReplaceData);
  end;
end;

procedure cTableViewProxyDataReplacer.setEditorData(aView: cTableViewProxy; aViewCol, aViewRow: integer; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; aEditor: cAbstractEditableViewProxy; var aAssignedValue: variant);
begin
  if (aAssignedValue = fSetEditorData) then begin
    aAssignedValue:= fSetEditorReplaceData;
  end;
end;

end.
