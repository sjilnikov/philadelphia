unit clsFileVersionInfo;

//**! ------------------------------------------------------------------
//**! This unit is a part of GSPackage project (Gregory Sitnin's Delphi 
//**! Components Package).
//**! ------------------------------------------------------------------
//**! You may use or redistribute this unit for your purposes while
//**! unit's code and this copyright notice is unchanged and exists.
//**! ------------------------------------------------------------------
//**! (c) Gregory Sitnin, 2001-2002. All rights reserved.
//**! ------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes;

type
  cFileVersionInfo = class
  private
    FFilename: TFilename;
    FVersionInfoSize: cardinal;
    FFileVersion: string;
    FFileDescription: string;
    FInternalName: string;
    FOriginalFilename: string;
    FCompanyName: string;
    FProductVersion: string;
    FProductName: string;
    FLegalCopyright: string;
    FLanguageInfo: string;
    FComments: string;
    procedure SetFilename(const Value: TFilename);
    { Private declarations }
  protected
    { Protected declarations }
    property VersionInfoSize: cardinal read FVersionInfoSize;
    procedure LoadFromFile;
    procedure ClearAll;
  public
    constructor create(aFileName: string);

    function getBuildOnly: string;
    property filename: TFilename read FFilename write SetFilename;
    property languageInfo: string read FLanguageInfo;
    property companyName: string read FCompanyName;
    property fileDescription: string read FFileDescription;
    property fileVersion: string read FFileVersion;
    property internalName: string read FInternalName;
    property legalCopyright: string read FLegalCopyright;
    property originalFilename: string read FOriginalFilename;
    property productName: string read FProductName;
    property productVersion: string read FProductVersion;
    property comments: string read FComments;
  end;

implementation

{ cFileVersionInfo }

procedure cFileVersionInfo.ClearAll;
begin
  FVersionInfoSize:= 0;
  FCompanyName := '';
  FFileDescription := '';
  FFileVersion := '';
  FInternalName := '';
  FLegalCopyright := '';
  FOriginalFilename := '';
  FProductName := '';
  FProductVersion := '';
  FComments := '';
end;

constructor cFileVersionInfo.create(aFileName: string);
begin
  SetFilename(aFileName);
end;

function cFileVersionInfo.GetBuildOnly: string;
var p: integer;
    s: string;
begin
  s := FileVersion;
  p := LastDelimiter('.',s);
  Result := copy(s,p+1,length(s)-p);
end;

procedure cFileVersionInfo.LoadFromFile;
var VISize:   cardinal;
    VIBuff:   pointer;
    trans:    pointer;
    buffsize: cardinal;
    temp: integer;
    str: pchar;
    LangCharSet: string;

  function GetStringValue(const From: string): string;
  begin
    VerQueryValue(VIBuff, pchar('\StringFileInfo\'+LanguageInfo+'\'+From), pointer(str), buffsize);
    if buffsize > 0 then Result := str else Result := 'n/a';
  end;

begin
  ClearAll;
  VIBuff := nil;
  if not fileexists(Filename) then raise EFilerError.Create('File not found: '+Filename);
  VISize := GetFileVersionInfoSize(pchar(Filename),buffsize);
  FVersionInfoSize := VISize;
  if VISize < 1 then raise EReadError.Create('Invalid version info record in file '+Filename);
  VIBuff := AllocMem(VISize);
  GetFileVersionInfo(pchar(Filename),cardinal(0),VISize,VIBuff);

  VerQueryValue(VIBuff,'\VarFileInfo\Translation',Trans,buffsize);
  if Assigned(trans) then
  begin
    temp:=0;
    move(Trans^, temp, sizeOf(word));
    LangCharSet:= IntToHex(temp, 4);
    move(pByte(Trans)[2], temp, sizeOf(word));
    FLanguageInfo := LangCharSet+IntToHex(temp, 4);
  end else raise EReadError.Create('Invalid language info in file '+Filename);

  FCompanyName := GetStringValue('CompanyName');
  FFileDescription := GetStringValue('FileDescription');
  FFileVersion := GetStringValue('FileVersion');
  FInternalName := GetStringValue('InternalName');
  FLegalCopyright := GetStringValue('LegalCopyright');
  FOriginalFilename := GetStringValue('OriginalFilename');
  FProductName := GetStringValue('ProductName');
  FProductVersion := GetStringValue('ProductVersion');
  FComments := GetStringValue('Comments');

  FreeMem(VIBuff,VISize);
end;

procedure cFileVersionInfo.SetFilename(const Value: TFilename);
begin
  FFilename := Value;
  LoadFromFile;
end;

end.

