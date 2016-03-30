unit clsAbstractDataViewProxyMapperDelegate;

interface
uses
  classes,
  windows,


  uModels,
  clsVariantConversion,

  clsAbstractEditableViewProxy,


  clsAbstractTableModel,
  clsAbstractViewProxy,
  clsMulticastEvents;

type
  cAbstractDataViewProxyMapperDelegate = class
  public
    constructor create; virtual;
    destructor  destroy; override;
  public
    procedure   getEditorData(aView: cAbstractViewProxy; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; var aAssignedValue: variant); virtual; abstract;
    procedure   setEditorData(aView: cAbstractViewProxy; aModel: cAbstractTableModel; aModelCol, aModelRow: integer; const aAssignedValue: variant); virtual; abstract;
  end;

implementation

{ cAbstractDataViewProxyMapperDelegate }

constructor cAbstractDataViewProxyMapperDelegate.create;
begin
  inherited create;
end;

destructor cAbstractDataViewProxyMapperDelegate.destroy;
begin
  inherited;
end;

end.
