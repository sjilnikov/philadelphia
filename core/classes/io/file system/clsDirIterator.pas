unit clsDirIterator;

interface
uses
  classes,
  sysUtils,
  generics.collections,

  clsException,

  clsLists;
type

  eDirIterator = class(cException);

  tDirFilter = (dfReadOnly, dfHidden, dfSysFile, dfDirectory, dfArchive, dfSymLink, dfNormal, dfTemporary, dfAnyFile);
  tDirFilters = set of tDirFilter;
  //

  //todo: http://qt-project.org/doc/qt-4.8/qfileinfo.html#absoluteFilePath
  sFileInfo = record
    absoluteFilePath : string;
    isDir            : boolean;
  end;

  cDirIterator = class
  private
    const

    MOVE_NEXT_NOT_CALLED = 'cannot get current item, moveNext was not called';
  private
    fDirList     : tList<sFileInfo>;

    fItemIndex   : integer;
    fCurrentItem : sFileInfo;

    fDirectory   : string;
    fFilters     : tDirFilters;
    fMask        : string;

    function    filtersToAttributes(aFilters : tDirFilters): integer;

    procedure   findFiles(aStartDir: string; aFilters: tDirFilters; aFileMask: string);
    procedure   setCurrentItem(const aItem: sFileInfo);
  public
    class procedure getDirectoryFiles(aDirectory: string; aFilters: tDirFilters; aMask: string; aList: tStringList);

    function    getCurrent: sFileInfo; inline;
    function    moveNext: boolean;

    constructor create(aDirectory: string; aFilters: tDirFilters; aMask: string = '*.*');
    destructor  destroy; override;

    property    current: sFileInfo read getCurrent;
  end;



implementation

{ cDirIterator }

constructor cDirIterator.create(aDirectory: string; aFilters: tDirFilters; aMask: string);
begin
  inherited create;
  fDirectory:= aDirectory;
  fFilters:= aFilters;
  fMask:= aMask;
  fItemIndex:= -1;

  fDirList:= tList<sFileInfo>.create;
end;

destructor cDirIterator.destroy;
begin
  if assigned(fDirList) then begin
    freeAndNil(fDirList);
  end;

  inherited;
end;

function cDirIterator.filtersToAttributes(aFilters: tDirFilters): integer;
begin
  result:= 0;

  if dfReadOnly in aFilters then result:= result + faReadOnly;
  if dfHidden in aFilters then result:= result + faHidden;
  if dfSysFile in aFilters then result:= result + faSysFile;
  if dfDirectory in aFilters then result:= result + faDirectory;
  if dfArchive in aFilters then result:= result + faArchive;
  if dfSymLink in aFilters then result:= result + faSymLink;
  if dfNormal in aFilters then result:= result + faNormal;
  if dfTemporary in aFilters then result:= result + faTemporary;
  if dfAnyFile in aFilters then result:= result + faAnyFile;
end;

procedure cDirIterator.findFiles(aStartDir: string; aFilters: tDirFilters; aFileMask: string);
var
  sr: tSearchRec;
  dirList: tList<sFileInfo>;
  isFound: boolean;
  i: integer;

  curItem: sFileInfo;
begin
  aStartDir:= includeTrailingPathDelimiter(aStartDir);

  isFound:= findFirst(aStartDir + aFileMask, filtersToAttributes(aFilters), sr) = 0;
  try
    while isFound do begin

      curItem.absoluteFilePath:= aStartDir + sr.name;
      curItem.isDir:= (sr.attr and faDirectory) <> 0;

      fDirList.add(curItem);

      isFound:= findNext(sr) = 0;
    end;
  finally
    findClose(sr);
  end;

  // build a list of subdirectories
  dirList:= tList<sFileInfo>.create;
  try
    isFound:= findFirst(aStartDir + '*.*', faAnyFile, sr) = 0;
    try
      while isFound do begin
        if ((sr.attr and faDirectory) <> 0) and (sr.name[1] <> '.') then begin

          curItem.isDir:= true;
          curItem.absoluteFilePath:= aStartDir + sr.name;

          dirList.add(curItem);
        end;
        isFound:= findNext(sr) = 0;
      end;
    finally
      findClose(sr);
    end;

    // scan the list of subdirectories
    for i := 0 to dirList.count - 1 do begin
      findFiles(dirList[i].absoluteFilePath, aFilters, aFileMask);
    end;

  finally
    freeAndNil(dirList);
  end;
end;

function cDirIterator.getCurrent: sFileInfo;
begin
  if (fItemIndex = -1) then begin
    raise eDirIterator.create(MOVE_NEXT_NOT_CALLED);
  end;

  result:= fCurrentItem;
end;

class procedure cDirIterator.getDirectoryFiles(aDirectory: string; aFilters: tDirFilters; aMask: string; aList: tStringList);
var
  dirIterator: cDirIterator;

  curItem: sFileInfo;
begin
  if not assigned(aList) then exit;

  dirIterator:= cDirIterator.create(aDirectory, aFilters, aMask);
  try
    while dirIterator.moveNext do begin
      curItem:= dirIterator.getCurrent;

      aList.add(curItem.absoluteFilePath)
    end;

  finally
    freeAndNil(dirIterator);
  end;

end;

function cDirIterator.moveNext: boolean;
begin
  result:= false;

  if (fItemIndex = -1) then begin
    fDirList.clear;

    findFiles(fDirectory, fFilters, fMask);
  end;

  if (fDirList.count > 0) then begin
    if (fItemIndex = fDirList.count - 1) then exit;

    inc(fItemIndex);
    setCurrentItem(fDirList.items[fItemIndex]);
    result:= true;
  end;
end;

procedure cDirIterator.setCurrentItem(const aItem: sFileInfo);
begin
  fCurrentItem:= aItem;
end;

end.
