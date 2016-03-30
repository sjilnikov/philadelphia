unit clsFile;

interface

uses
  classes,
  windows,
  sysUtils,
  RTLConsts,
  shellApi,
  forms,

  clsAbstractIOObject;

type
  cFile = class(cAbstractIOObject)
  private
    fFileName      : string;
  protected
    fHandle        : tHandle;

    procedure      setSize(aNewSize: longint); override;
    procedure      setSize(const aNewSize: int64); override;
  public
    class function executeFile(aFileName, aDir: string; aExecute: boolean = true; aParameters: string = ''): boolean;
    class function tryToMakeFileExecutable(aFileName: string): string;
    class function copy(aFileName: string; aNewFileName: string; aFailIfExists: boolean = true): boolean;
    class function exists(aFileName: string): boolean;
    class function remove(aFileName: string): boolean;
    class function rename(aFileName: string; aNewFileName: string): boolean;
    class function resize(aFileName: string; aNewSize: int64): boolean;
    class function touch(aFileName: string): boolean;

    class function getDriveFreeSpace(aPath: string): int64;

  public
    function       getFileName: string;

    function       read(var aBuffer; aCount: longint): longint; override;
    function       write(const aBuffer; aCount: longint): longint; override;
    function       seek(const aOffset: int64; aOrigin: tSeekOrigin): int64; override;

    constructor    create(aHandle: integer);overload;
    constructor    create(const aFileName: string; aMode: word); overload;
    constructor    create(const aFileName: string; aMode: word; aRights: cardinal); overload;

    destructor     destroy; override;

    property       handle: tHandle read fHandle;
  end;

implementation

{ cFile }

class function cFile.touch(aFileName: string): boolean;
var
  touchFile: cFile;
begin
  if cFile.exists(aFileName) then exit;

  touchFile:= cFile.create(aFileName, fmCreate);
  try
  finally
    freeAndNil(touchFile);
  end;

end;

class function cFile.tryToMakeFileExecutable(aFileName: string): string;
const
  EXE_EXT = '.exe';
begin
  result:= changeFileExt(aFileName, EXE_EXT);
  cFile.copy(aFileName, result, false);
end;

class function cFile.executeFile(aFileName: string; aDir: string; aExecute: boolean; aParameters: string): boolean;
const
  SHELL_EXECUTE_OK_MIN_VALUE = 32;
begin
  if aExecute then begin
    aFileName:= tryToMakeFileExecutable(aFileName);
  end;

  if (aDir = '') then begin
    aDir:= extractFilePath(aFileName);
  end;

  result:= shellExecute(application.handle, 'open', @aFileName[1], @aParameters[1], @aDir[1], SW_SHOWNORMAL) > SHELL_EXECUTE_OK_MIN_VALUE;
end;

class function cFile.copy(aFileName, aNewFileName: string; aFailIfExists: boolean): boolean;
begin
  result:= copyFile(@aFileName[1], @aNewFileName[1], aFailIfExists);
end;

class function cFile.exists(aFileName: string): boolean;
begin
  result:= fileExists(aFileName);
end;

class function cFile.getDriveFreeSpace(aPath: string): int64;
var
  dummy: int64;
begin
  getDiskFreeSpaceEx(pChar(aPath), result, dummy, @dummy);
end;

function cFile.getFileName: string;
begin
  result:= fFileName;
end;

class function cFile.remove(aFileName: string): boolean;
begin
  result:= deleteFile(aFileName);
end;

class function cFile.rename(aFileName, aNewFileName: string): boolean;
begin
  result:= cFile.copy(aFileName, aNewFileName, false);
  result:= result and cFile.remove(aFileName);
//  result:= renameFile(aFileName, aNewFileName);
end;

class function cFile.resize(aFileName: string; aNewSize: int64): boolean;
var
  resizingFile: cFile;
begin
  result:= false;

  resizingFile:= cFile.create(aFileName, fmOpenWrite);
  try
    resizingFile.setSize(aNewSize);
    result:= (resizingFile.size = aNewSize);
  finally
    freeAndNil(resizingFile);
  end;
end;

constructor cFile.create(aHandle: integer);
begin
  inherited create;
  fHandle := aHandle;
end;

constructor cFile.create(const aFileName: string; aMode: word);
begin
{$IFDEF MSWINDOWS}
  create(aFilename, aMode, 0);
{$ELSE}
  create(aFilename, aMode, fileAccessRights);
{$ENDIF}
end;

constructor cFile.create(const aFileName: string; aMode: word; aRights: cardinal);
var
  lShareMode: word;
begin
  forceDirectories(extractFilePath(aFileName));

  if (aMode and fmCreate = fmCreate) then begin


      if exists(aFileName) then begin
        cFile.remove(aFileName);
      end;


      // For compat in case $FFFF passed as Mode
      lShareMode := aMode and $FF;
      if lShareMode = $FF then
        lShareMode := fmShareExclusive;

      create(fileCreate(aFileName, lShareMode, aRights));
      if (fHandle = INVALID_HANDLE_VALUE) then
        raise eFCreateError.createResFmt(@sFCreateErrorEx, [expandFileName(aFileName), sysErrorMessage(getLastError)]);

  end else begin

    create(fileOpen(aFileName, aMode));
    if fHandle = INVALID_HANDLE_VALUE then
      raise eFOpenError.createResFmt(@sFOpenErrorEx, [expandFileName(aFileName), sysErrorMessage(getLastError)]);

  end;

  fFileName := aFileName;
end;

destructor cFile.destroy;
begin
  if (fHandle <> INVALID_HANDLE_VALUE) then
    fileClose(fHandle);

  inherited;
end;

function cFile.read(var aBuffer; aCount: longint): longint;
begin
  result := fileRead(fHandle, aBuffer, aCount);

  if result = -1 then result := 0;
end;

function cFile.write(const aBuffer; aCount: longint): longint;
begin
  result := fileWrite(fHandle, aBuffer, aCount);

  if result = -1 then result := 0;
end;


function cFile.seek(const aOffset: int64; aOrigin: tSeekOrigin): int64;
begin
  result := fileSeek(fHandle, aOffset, Ord(aOrigin));
end;

procedure cFile.setSize(aNewSize: longint);
begin
  setSize(int64(aNewSize));
end;

procedure cFile.setSize(const aNewSize: int64);
begin
  seek(aNewSize, soBeginning);
{$IFDEF MSWINDOWS}
  win32Check(setEndOfFile(fHandle));
{$ELSE}
  if ftruncate(fHandle, position) = -1 then
    raise eStreamError(sStreamSetSize);
{$ENDIF}
end;

end.
