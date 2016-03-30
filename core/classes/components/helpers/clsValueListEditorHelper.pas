unit clsValueListEditorHelper;

interface
uses
  classes,
  sysUtils,
  valEdit,

  clsStringUtils,
  clsMemory,
  clsVariantConversion;

type
  cValueListEditorHelper = class helper for tValueListEditor
  public
    function  saveState: tBytesArray;
    procedure restoreState(const aBytesArray: tBytesArray);
  end;


implementation

{ cValueListEditorHelper }

procedure cValueListEditorHelper.restoreState(const aBytesArray: tBytesArray);
var
  dataStream: cMemory;
  readedData: string;
begin
  dataStream:= cMemory.create;
  try
    dataStream.fromBytes(aBytesArray);

    dataStream.readUnicodeString(readedData);

    strings.text:= readedData;
  finally
    freeAndNil(dataStream);
  end;
end;

function cValueListEditorHelper.saveState: tBytesArray;
var
  dataStream: cMemory;
begin
  dataStream:= cMemory.create;
  try
    dataStream.clear;

    dataStream.writeUnicodeString(strings.text);

    result:= dataStream.toBytes;
  finally
    freeAndNil(dataStream);
  end;
end;

end.
