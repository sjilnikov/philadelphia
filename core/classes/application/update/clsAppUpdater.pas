unit clsAppUpdater;

interface
uses
  windows,
  classes,
  sysUtils,
  httpSend,
  forms,
  asyncCalls,
  activeX,
  MSXML,

  clsLog,
  clsMessageBox,
  clsApplication,
  clsDebug,
  clsFile,
  clsAppVersionInfo,
  uMetrics,
  clsSingleton;

type

  tAppUpdaterState = (asIdle, asAwaitingAnswer);

  cAppUpdater = class(tThread)
  private
    fLastTick            : cardinal;

    fAppInfo             : sAppVersionInfo;
    fXMLDoc              : iXMLDomDocument;

    fNewVersion          : string;

    fCheckInterval       : cardinal;
    fUpdateFilePath      : string;
    fEnabled             : boolean;
    fState               : tAppUpdaterState;

    procedure   execute; override;

    procedure   checkForUpdate;
    procedure   tryToUpdateApplication(aUpdateFile: string);
    function    runUpdateProcess(aModuleName: string): boolean;

    procedure   initialize;
    procedure   uninitialize;


    function    loadXML(aTarget: string): boolean;
    //

    destructor  destroy; override;
  private
    const
      updateFileName            = 'update.dat';

      appNodeName               = 'application';
      appVersiontAttributeName  = 'version';

      updateNodeName            = 'update';
      updateURLAttributeName    = 'path';

      appNodePath               = '//' + appNodeName;
      updateNodePath            = appNodePath + '/' +updateNodeName;

  public
    procedure       setCheckInterval(aInterval: integer);
    procedure       setUpdateFilePath(aUpdateFilePath: string);

    procedure       setEnabled(aValue: boolean);

    class function  getInstance: cAppUpdater;

    constructor     create;
  end;


implementation

{ cAppUpdater }

function cAppUpdater.loadXML(aTarget: string): boolean;
begin
  result:= false;
  try
    result:= fXMLDoc.load(aTarget);
  except
    on e: exception do begin
      cLog.getInstance.write(self, 'loadXML: error while parsing target: %s, message: %s', [aTarget, e.message], ltDebug);
    end;
  end;
end;

procedure cAppUpdater.checkForUpdate;

  function needUpdate(var aNewVersion: string; var aUpdateTargetPath: string): boolean;
  var
    appNode: iXMLDOMNode;

    versionAttribNode: iXMLDomNode;

    updateNode: iXMLDomNode;
    updateURLAttribNode: iXMLDomNode;
  begin
    result:= false;
    aUpdateTargetPath:= '';
    aNewVersion:= '';


    cLog.getInstance.write(self, 'checkForUpdate::needUpdate:: try read update file: %s', [fUpdateFilePath], ltDebug);
    if loadXML(fUpdateFilePath) then begin
      appNode:= fXMLDoc.selectSingleNode(appNodePath);
      if assigned(appNode) then begin
        versionAttribNode:= appNode.attributes.getNamedItem(appVersiontAttributeName);
        if assigned(versionAttribNode) then begin
          aNewVersion:= versionAttribNode.nodeValue;
          result:= aNewVersion <> fAppInfo.version;

          if result then begin

            updateNode:= fXMLDoc.selectSingleNode(updateNodePath);
            if assigned(updateNode) then begin
              updateURLAttribNode:= updateNode.attributes.getNamedItem(updateURLAttributeName);
              if assigned(updateURLAttribNode) then aUpdateTargetPath:= updateURLAttribNode.nodeValue;

            end;

          end;
        end;
      end;
    end;
  end;
var
  updateFilePath: string;
begin
  if (fState = asAwaitingAnswer) then exit;

  //all params is out
  cLog.getInstance.write(self, 'checkForUpdate:: try to update from: %s, currentVersion: %s', [fUpdateFilePath, fAppInfo.version], ltDebug);
  if needUpdate(fNewVersion, updateFilePath) then begin //get update url if update needed
    if (updateFilePath <> '') then begin
      tryToUpdateApplication(updateFilePath);
    end;
  end;
end;

constructor cAppUpdater.create;
begin
  inherited create(false);

  fState:= asIdle;
  setEnabled(false);
end;

destructor cAppUpdater.destroy;
begin
  inherited;
end;

procedure cAppUpdater.execute;
var
  tick: cardinal;
begin
  initialize;
  while (not terminated) do begin
    try

      if (fEnabled) then begin

        tick:= gettickcount;

        if (tick - fLastTick > fCheckInterval) then begin
          //
          checkForUpdate;
          //
          fLastTick:= tick;
        end;

      end;


      //relinquish CPU
      sleep(1000);
    except
      on e: exception do begin
        cLog.getInstance.write(self, 'execute:: error, message: %s', [e.message], ltDebug);
        sleep(1000);
      end;
    end;
  end;

  try
    uninitialize;
    cLog.getInstance.write(self, 'execute:: execution complete, exiting', ltDebug);
  except
    on e: exception do begin
      cLog.getInstance.write(self, 'execute: error, message: %s', [e.message], ltDebug);
    end;
  end;
end;

class function cAppUpdater.getInstance: cAppUpdater;
begin
  result:= cSingleton.getInstance<cAppUpdater>;
end;

procedure cAppUpdater.initialize;
begin
  fLastTick:= 0;

  coInitialize(nil);
  fXMLDoc:= coDOMDocument.create; //not constructor, just class function
  fXMLDoc.async:= false;

  fAppInfo:= cAppVersionInfo.appInfoStruct;
end;

function cAppUpdater.runUpdateProcess(aModuleName: string): boolean;
begin
  result:= false;
  try
    result:= cFile.executeFile(aModuleName, cApplication.getStartPath, true, format('%u "%s"', [hinstance, cApplication.getStartFile]));
  except
    on e: exception do begin
      cLog.getInstance.write(self, 'runUpdateProcess::runUpdateProcess: error, message: %s', [e.message], ltDebug);
    end;
  end;
end;

procedure cAppUpdater.setCheckInterval(aInterval: integer);
begin
  fCheckInterval:= aInterval;
end;

procedure cAppUpdater.setEnabled(aValue: boolean);
begin
  fEnabled:= aValue;
end;

procedure cAppUpdater.setUpdateFilePath(aUpdateFilePath: string);
begin
  fUpdateFilePath:= aUpdateFilePath;
end;

procedure cAppUpdater.tryToUpdateApplication(aUpdateFile: string);
begin
  cLog.getInstance.write(self, 'tryToUpdateApplication:: file name: %s', [aUpdateFile], ltDebug);

  try
  fState:= asAwaitingAnswer;

  if application.terminated then exit;

  enterMainThread;
  try

    if (cMessageBox.question(
      'Внимание',
      'Внимание',
      format(
        'Появилась новая версия приложения: %s, хотите обновить сейчас?', [fNewVersion]
      )
    ) = mbbYes)
    then begin
      if runUpdateProcess(aUpdateFile) then begin
        cLog.getInstance.write(self, 'checkForUpdate:: updating application from version: %s to %s', [fAppInfo.version, fNewVersion], ltDebug);
        application.terminate;
      end;
    end;

  finally
    leaveMainThread;
  end;
  finally
    fState:= asIdle;
  end;
end;

procedure cAppUpdater.uninitialize;
begin
  coUninitialize;
  fXMLDoc:= nil;
end;

end.
