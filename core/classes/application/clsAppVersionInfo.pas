unit clsAppVersionInfo;

interface
uses
  forms,
  clsFileVersionInfo;

type
  sAppVersionInfo = record
    major   : string;
    minor   : string;
    release : string;

    version : string;

    module  : string;
  end;

  cAppVersionInfo = class
  private
    class var fMajor: ansiString;
    class var fMinor: ansiString;
    class var fRelease: ansiString;
    class var fAppInfoStruct: sAppVersionInfo;

    class procedure initialize;

    class function getAppVersionInfo (aFullVersion: ansiString; aIndex: integer): ansiString;

    const
      iVpMajor    = 0;
      iVpMinor    = 1;
      iVpRelease  = 2;
  public
    class property major: ansiString read fMajor;
    class property minor: ansiString read fMinor;
    class property release: ansiString read fRelease;

    class property appInfoStruct: sAppVersionInfo read fAppInfoStruct;
  end;

implementation

{ cAppVersionInfo }

class function cAppVersionInfo.getAppVersionInfo(aFullVersion: ansiString; aIndex: integer): ansiString;
var
  tmpVal: ansiString;
  verLength: integer;
  i: integer;
  curChar: ansiString;

  curDelimIndex: integer;
begin
  result:= '0';

  tmpVal:= '';

  curDelimIndex:= 0;

  verLength:= length(aFullVersion);

  for i := 1 to verLength do begin
    curChar:= aFullVersion[i];
    if curChar <> '.' then begin
      tmpVal:= tmpVal + curChar;
    end;

    if (curChar = '.') or (i = verLength) then begin
      if curDelimIndex = aIndex then begin
        result:= tmpVal;
        exit;
      end;

      inc(curDelimIndex);

      tmpVal:= '';
    end;

  end;
end;

class procedure cAppVersionInfo.initialize;
var
  exeName: string;
  moduleInfo: cFileVersionInfo;
begin
  exeName:= application.exeName;
  moduleInfo:= cFileVersionInfo.create(exeName);
  try
    fMajor:= getAppVersionInfo(moduleInfo.fileVersion, iVpMajor);
    fMinor:= getAppVersionInfo(moduleInfo.fileVersion, iVpMinor);
    fRelease:= getAppVersionInfo(moduleInfo.fileVersion, iVpRelease);

    fAppInfoStruct.major:= fMajor;
    fAppInfoStruct.minor:= fMinor;
    fAppInfoStruct.release:= fRelease;
    fAppInfoStruct.module:= exeName;

    fAppInfoStruct.version:= fMajor+'.'+fMinor+'.'+fRelease;
  finally
    moduleInfo.free;
  end;
end;

initialization
  cAppVersionInfo.initialize;
end.
