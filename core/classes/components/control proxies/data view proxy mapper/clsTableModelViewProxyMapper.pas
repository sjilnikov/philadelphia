unit clsTableModelViewProxyMapper;

interface
uses
  sysUtils,
  generics.collections,

  clsException,

  clsClasskit,
  clsMulticastEvents,
  clsAbstractDataViewProxyMapperDelegate,
  clsAbstractTableModel,
  clsAbstractEditableViewProxy;


type
  tSubmitPolicy = (spAutoSubmit, spManualSubmit);

  cTableModelViewProxyMapper = class;

  sMappingInfo = record
    modelColIndex : integer;
    propertyName  : string;

    class function create(aModelIndex: integer; aPropertyName: string): sMappingInfo; static;
  end;

  eTableModelViewProxyMapper = class(cException);

  cTableModelViewProxyMapper = class
  private
    const

    MODEL_NOT_ASSIGNED               = 'model not assigned';
    MODEL_COLUMN_INDEX_OUT_OF_BOUNDS = 'model index out of bounds';
  private
    fMapping            : tDictionary<cAbstractEditableViewProxy,sMappingInfo>;
    fCurrentRowIndex    : integer;
    fModel              : cAbstractTableModel;
    fSubmitPolicy       : tSubmitPolicy;
    fDelegate           : cAbstractDataViewProxyMapperDelegate;

    procedure   setupViewProxyEvents(aViewProxy: cAbstractEditableViewProxy);
    procedure   disconnectViewProxyEvents(aViewProxy: cAbstractEditableViewProxy);

    procedure   readModelDataToProxies;
    procedure   checkModelAssigned;

    procedure  	submit(aViewProxy: cAbstractEditableViewProxy); overload;
  public
    procedure	  addMapping (aViewProxy: cAbstractEditableViewProxy; aModelRowIndex: integer; aPropertyName: string); overload;
    procedure	  addMapping (aViewProxy: cAbstractEditableViewProxy; aModelFieldName: string; aPropertyName: string); overload;
    procedure	  clearMapping;

    function    getCurrentRowIndex: integer;
    procedure 	setCurrentRowIndex(aModelRowIndex: integer);

    procedure 	setModel(aModel: cAbstractTableModel);
    function  	getModel: cAbstractTableModel;

    procedure 	removeMapping (aViewProxy: cAbstractEditableViewProxy);

    procedure   setDelegate(aDelegate: cAbstractDataViewProxyMapperDelegate);
    function    getDelegate: cAbstractDataViewProxyMapperDelegate;

    procedure  	setSubmitPolicy(aSubmitPolicy: tSubmitPolicy);
    function  	getSubmitPolicy: tSubmitPolicy;

    procedure  	submit; overload;

    Procedure 	toFirst;
    procedure 	toLast;
    procedure   toNext;
    procedure 	toPrevious;

    constructor create;
    destructor  destroy; override;
  published
    {$REGION 'SLOTS'}
    procedure   viewProxyLoseFocus(aSender: cAbstractEditableViewProxy);
    procedure   viewProxyKeyPress(aSender: cAbstractEditableViewProxy; var aKey: char);
    {$ENDREGION}
  end;


implementation

{ cAbstractTableModelViewProxyMapper }

constructor cTableModelViewProxyMapper.create;
begin
  inherited create;
  fMapping:= tDictionary<cAbstractEditableViewProxy,sMappingInfo>.create;

  setSubmitPolicy(spAutoSubmit);
end;

destructor cTableModelViewProxyMapper.destroy;
begin
  clearMapping;

  if assigned(fMapping) then begin
    freeAndNil(fMapping);
  end;

  inherited;
end;

procedure cTableModelViewProxyMapper.addMapping(aViewProxy: cAbstractEditableViewProxy; aModelRowIndex: integer; aPropertyName: string);
begin
  checkModelAssigned;

  if not (aModelRowIndex >= 0) and (aModelRowIndex < fModel.getFields.count) then begin
    raise eTableModelViewProxyMapper.create(MODEL_COLUMN_INDEX_OUT_OF_BOUNDS);
  end;

  fMapping.addOrSetValue(aViewProxy, sMappingInfo.create(aModelRowIndex, aPropertyName));

  disconnectViewProxyEvents(aViewProxy);
  setupViewProxyEvents(aViewProxy);

  if assigned(aViewProxy) then begin
    cClassKit.setObjectProperty(aViewProxy, aPropertyName, '');
  end;
end;

procedure cTableModelViewProxyMapper.addMapping(aViewProxy: cAbstractEditableViewProxy; aModelFieldName, aPropertyName: string);
begin
  addMapping(aViewProxy, fModel.getFields.indexOfName(aModelFieldName), aPropertyName);
end;

procedure cTableModelViewProxyMapper.checkModelAssigned;
begin
  if not assigned(fModel) then begin
    raise eTableModelViewProxyMapper.create(MODEL_NOT_ASSIGNED);
  end;
end;

procedure cTableModelViewProxyMapper.clearMapping;
var
  curMapping: tPair<cAbstractEditableViewProxy,sMappingInfo>;
  curViewProxy: cAbstractEditableViewProxy;
begin
  for curMapping in fMapping do begin
    curViewProxy:= curMapping.key;
    disconnectViewProxyEvents(curViewProxy);
  end;

  fMapping.clear;
  fCurrentRowIndex:= -1;
end;

function cTableModelViewProxyMapper.getCurrentRowIndex: integer;
begin
  result:= fCurrentRowIndex;
end;

function cTableModelViewProxyMapper.getDelegate: cAbstractDataViewProxyMapperDelegate;
begin
  result:= fDelegate;
end;

function cTableModelViewProxyMapper.getModel: cAbstractTableModel;
begin
  result:= fModel;
end;

function cTableModelViewProxyMapper.getSubmitPolicy: tSubmitPolicy;
begin
  result:= fSubmitPolicy;
end;

procedure cTableModelViewProxyMapper.readModelDataToProxies;
var
  curMapping: tPair<cAbstractEditableViewProxy,sMappingInfo>;
  curViewProxy: cAbstractEditableViewProxy;
begin
  checkModelAssigned;

  for curMapping in fMapping do begin
    curViewProxy:= curMapping.key;

    if assigned(fDelegate) then begin
      fDelegate.setEditorData(
        curViewProxy,
        fModel,
        curMapping.value.modelColIndex,
        fCurrentRowIndex,
        fModel.getFieldData(curMapping.value.modelColIndex, fCurrentRowIndex)
      );
    end else begin
      cClassKit.setObjectProperty(
        curViewProxy,
        curMapping.value.propertyName,
        fModel.getFieldData(curMapping.value.modelColIndex, fCurrentRowIndex)
      );
    end;

  end;
end;

procedure cTableModelViewProxyMapper.removeMapping(aViewProxy: cAbstractEditableViewProxy);
begin
  fMapping.remove(aViewProxy);
end;

procedure cTableModelViewProxyMapper.setCurrentRowIndex(aModelRowIndex: integer);
begin
  fCurrentRowIndex:= aModelRowIndex;

  readModelDataToProxies;
end;

procedure cTableModelViewProxyMapper.setDelegate(aDelegate: cAbstractDataViewProxyMapperDelegate);
begin
  fDelegate:= aDelegate;
end;

procedure cTableModelViewProxyMapper.setModel(aModel: cAbstractTableModel);
begin
  fModel:= aModel;
  clearMapping;
end;

procedure cTableModelViewProxyMapper.setSubmitPolicy(aSubmitPolicy: tSubmitPolicy);
begin
  fSubmitPolicy:= aSubmitPolicy;
end;

procedure cTableModelViewProxyMapper.setupViewProxyEvents(aViewProxy: cAbstractEditableViewProxy);
begin
  if not assigned(aViewProxy) then exit;

  connect(aViewProxy, 'onLoseFocus', self, 'viewProxyLoseFocus');
  connect(aViewProxy, 'onKeyPress', self, 'viewProxyKeyPress');
end;

procedure cTableModelViewProxyMapper.submit(aViewProxy: cAbstractEditableViewProxy);
var
  mappingInfo: sMappingInfo;
  settingValue: variant;
begin
  checkModelAssigned;

  mappingInfo:= fMapping.items[aViewProxy];

  settingValue:= aViewProxy.getValue;

  if assigned(fDelegate) then begin
    fDelegate.getEditorData(aViewProxy, fModel, mappingInfo.modelColIndex, getCurrentRowIndex, settingValue);
  end else begin
    fModel.setFieldData(mappingInfo.modelColIndex, getCurrentRowIndex, settingValue);
  end;
end;

procedure cTableModelViewProxyMapper.disconnectViewProxyEvents(aViewProxy: cAbstractEditableViewProxy);
begin
  if not assigned(aViewProxy) then exit;

  disconnect(aViewProxy, 'onLoseFocus', self, 'viewProxyLoseFocus');
  disconnect(aViewProxy, 'onKeyPress', self, 'viewProxyKeyPress');
end;

procedure cTableModelViewProxyMapper.submit;
var
  curMapping: tPair<cAbstractEditableViewProxy,sMappingInfo>;
  curViewProxy: cAbstractEditableViewProxy;
begin
  for curMapping in fMapping do begin
    curViewProxy:= curMapping.key;

    submit(curViewProxy);
  end;
end;

procedure cTableModelViewProxyMapper.toFirst;
begin
  fCurrentRowIndex:= -1;
  if (fCurrentRowIndex + 1) < fModel.getRowCount  then begin
    inc(fCurrentRowIndex);

    readModelDataToProxies;
  end;
end;

procedure cTableModelViewProxyMapper.toLast;
begin
  fCurrentRowIndex:= fModel.getRowCount;
  if (fCurrentRowIndex - 1) < fModel.getRowCount  then begin
    dec(fCurrentRowIndex);

    readModelDataToProxies;
  end;
end;

procedure cTableModelViewProxyMapper.toNext;
begin
  if (fCurrentRowIndex + 1) < fModel.getRowCount  then begin
    inc(fCurrentRowIndex);

    readModelDataToProxies;
  end;
end;

procedure cTableModelViewProxyMapper.toPrevious;
begin
  if ((fCurrentRowIndex - 1) < fModel.getRowCount) and (fCurrentRowIndex - 1 >= 0) then begin
    dec(fCurrentRowIndex);

    readModelDataToProxies;
  end;
end;

{$REGION 'SLOTS'}
procedure cTableModelViewProxyMapper.viewProxyLoseFocus(aSender: cAbstractEditableViewProxy);
begin
  case fSubmitPolicy of
    spAutoSubmit:
    begin
      submit(aSender);
    end;

    spManualSubmit:
    begin
      //do nothing
    end;
  end;
end;

procedure cTableModelViewProxyMapper.viewProxyKeyPress(aSender: cAbstractEditableViewProxy; var aKey: char);
begin
  if aKey = #13 then begin
    viewProxyLoseFocus(aSender);
  end;
end;
{$ENDREGION}

{ sMappingInfo }

class function sMappingInfo.create(aModelIndex: integer; aPropertyName: string): sMappingInfo;
begin
  result.modelColIndex:= aModelIndex;
  result.propertyName:= aPropertyName;
end;


end.
