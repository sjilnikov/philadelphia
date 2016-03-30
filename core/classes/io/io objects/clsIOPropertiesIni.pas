unit clsIOPropertiesIni;

interface
uses
  classes,
  iniFiles,
  sysUtils,
  variants,


  clsStringUtils,
  clsException,
  clsAbstractIOObject,
  clsClassKit,
  clsVariantConversion,
  clsAbstractConfig;

type
  eIOPropertiesIni = class(cException);
  //IO
  cIOPropertiesIni = class(cAbstractIOOProperties)
  private
    const
    INI_FILE_NOT_ASSIGNED     = 'ini file not assigned';
    DATATYPE_NOT_SUPPORTED    = 'datatype not supported';

  private
    fIniFile    : tIniFile;
    fFileName   : string;

    procedure   destroyIniFile;
    procedure   createIniFile;
    procedure   recreateIniFile;
  protected
    procedure   commit; override;
  public
    procedure   clear; override;

    procedure   saveToStream(aStream: tStream); override;
    procedure   loadFromStream(aStream: tStream); override;

    procedure   setFileName(aFileName: string);

    function    exists(aSection: string): boolean; override;

    procedure   iterateSections(aIteratorProc: tSectionsIteratorProc); override;

    function    read(aSection: string; aType: tDataType; aItemName: string; const aDefValue: variant): variant; override;
    procedure   write(aSection: string; aType: tDataType; aItemName: string; const aValue: variant); override;

    constructor create;
    destructor  destroy; override;

    property    fileName: string read fFileName;
  end;

implementation


{ cIOPropertiesIni }

procedure cIOPropertiesIni.clear;
var
  sectionForDelete: tStringList;
  i: integer;
begin
  sectionForDelete:= tStringList.create;
  try

    iterateSections(
      procedure(aSection: string; aIndex: integer)
      begin
        sectionForDelete.add(aSection);
      end
    );

    for i:= 0 to sectionForDelete.count - 1 do begin
      fIniFile.eraseSection(sectionForDelete[i]);
    end;

  finally
    freeAndNil(sectionForDelete);
  end;
end;

procedure cIOPropertiesIni.commit;
begin
  //do nothing
end;

constructor cIOPropertiesIni.create;
begin
  inherited create;

  fFileName:= '';
  fIniFile:= nil;
end;

procedure cIOPropertiesIni.createIniFile;
begin
  if assigned(fIniFile) then begin
    exit;
  end;

  forceDirectories(extractFilePath(fFileName));
  fIniFile:= tIniFile.create(fFileName);
end;

destructor cIOPropertiesIni.destroy;
begin
  destroyIniFile;
  inherited;
end;

procedure cIOPropertiesIni.destroyIniFile;
begin
  if assigned(fIniFile) then begin
    freeAndNil(fIniFile);
  end;
end;

function cIOPropertiesIni.exists(aSection: string): boolean;
begin
  result:= fIniFile.sectionExists(aSection);
end;

procedure cIOPropertiesIni.iterateSections(aIteratorProc: tSectionsIteratorProc);
var
  sectionsList: tStringList;
  i: integer;
begin
  inherited iterateSections(aIteratorProc);



  sectionsList:= tStringList.create;
  try
    fIniFile.readSections(sectionsList);

    for i:= 0 to sectionsList.count - 1 do begin
      aIteratorProc(sectionsList[i], i);
    end;
  finally
    freeAndNil(sectionsList);
  end;
end;

procedure cIOPropertiesIni.loadFromStream(aStream: tStream);
begin
  raise eIOPropertiesIni.create(METHOD_NOT_REALIZED);
end;

function cIOPropertiesIni.read(aSection: string; aType: tDataType; aItemName: string; const aDefValue: variant): variant;
begin
  result:= null;

  case aType of

    dtBoolean:
    begin
      result:= fIniFile.readBool(aSection, aItemName, aDefValue);
    end;

    dtInteger, dtInt64, dtWord, dtByte:
    begin
      result:= fIniFile.readInteger(aSection, aItemName, aDefValue);
    end;

    dtExtended, dtCurrency:
    begin
      result:= fIniFile.readFloat(aSection, aItemName, aDefValue);
    end;

    dtDateTime:
    begin
      result:= fIniFile.readDateTime(aSection, aItemName, aDefValue);
    end;

    dtString:
    begin
      result:= fIniFile.readString(aSection, aItemName, aDefValue);
    end;

    dtByteArray:
    begin
      result:= cStringUtils.stringToBytesArray(fIniFile.readString(aSection, aItemName, aDefValue));
    end;
  end;
end;

procedure cIOPropertiesIni.recreateIniFile;
begin
  destroyIniFile;
  createIniFile;
end;

procedure cIOPropertiesIni.saveToStream(aStream: tStream);
begin
  raise eIOPropertiesIni.create(METHOD_NOT_REALIZED);
end;

procedure cIOPropertiesIni.setFileName(aFileName: string);
begin
  fFileName:= aFileName;

  recreateIniFile;
end;

procedure cIOPropertiesIni.write(aSection: string; aType: tDataType; aItemName: string; const aValue: variant);
begin
  case aType of

    dtBoolean   : begin
      fIniFile.writeBool(aSection, aItemName, aValue);
    end;

    dtInteger,
    dtInt64     : begin
      fIniFile.writeInteger(aSection, aItemName, aValue);
    end;

    dtExtended,
    dtCurrency  : begin
      fIniFile.writeFloat(aSection, aItemName, aValue);
    end;

    dtDateTime  : begin
      fIniFile.writeDateTime(aSection, aItemName, aValue);
    end;

    dtString    : begin
      fIniFile.writeString(aSection, aItemName, aValue);
    end;

    dtByteArray    : begin
      fIniFile.writeString(aSection, aItemName, cStringUtils.bytesArrayToString(aValue));
    end;
  end;
end;

end.
