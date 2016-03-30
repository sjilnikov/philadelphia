unit clsFormDecorator;

interface
uses
  windows,
  sysUtils,
  classes,
  forms,

  clsException,
  clsStringUtils,
  clsMemory,
  clsMessageBox,
  clsMulticastEvents;
  
type
  tCloseQuestionInfo = record
    title   : string;
    caption : string;
    text    : string;
  end;

  eFormDecorator = class(cException);
  
  cFormDecorator = class
  private
    fForm               : tForm;
    fCloseQuestionInfo  : tCloseQuestionInfo;
    fUseCloseQuestion   : boolean;
  
    procedure   setupFormEvents;
    procedure   disconnectFormEvents;
  public
    const


    CURRENT_VERSION                        = '1.0';
    INVALID_VERSION_FORMAT                 = 'invalid version, got: %s, expected: %s';

    DEFAULT_CONFIRM_CLOSE_CAPTION = 'Close confirmation';
    DEFAULT_CONFIRM_CLOSE_TITLE   = 'Form is closing';
    DEFAULT_CONFIRM_CLOSE_TEXT    = 'Do you really  want to close form?';
  public
    procedure   setCloseQuestionInfo(aCaption: string; aTitle: string; aText: string);
    function    getCloseQuestionInfo: tCloseQuestionInfo;
    
    procedure   setUseCloseQuestion(aValue: boolean);
    function    useCloseQuestion: boolean;

    procedure   setForm(aForm: tForm);

    function    saveState: tBytesArray;
    function    restoreState(const aBytesArray: tBytesArray): boolean;

    constructor create;
    destructor  destroy; override;
  published
    //SLOTS
    procedure   formKeyDown(aSender: tObject; var aKey: word; aShift: tShiftState);
  end;
  

implementation

constructor cFormDecorator.create;
begin
  inherited create;
  
  fForm:= nil;
  fUseCloseQuestion:= true;

  setCloseQuestionInfo(DEFAULT_CONFIRM_CLOSE_CAPTION, DEFAULT_CONFIRM_CLOSE_TITLE, DEFAULT_CONFIRM_CLOSE_TEXT);
end;

destructor cFormDecorator.destroy;
begin
  disconnectFormEvents;

  inherited;
end;

procedure cFormDecorator.setupFormEvents;
begin
  if not assigned(fForm) then begin
    exit;
  end;

  connect(fForm, 'onKeyDown', self, 'formKeyDown');
end;

procedure cFormDecorator.disconnectFormEvents;
begin
  if not assigned(fForm) then begin
    exit;
  end;

  disconnect(fForm, 'onKeyDown', self, 'formKeyDown');
end;

procedure cFormDecorator.setUseCloseQuestion(aValue: boolean);
begin
  fUseCloseQuestion:= aValue;
end;

procedure cFormDecorator.setCloseQuestionInfo(aCaption: string; aTitle: string; aText: string);
begin
  fCloseQuestionInfo.caption:= aCaption;
  fCloseQuestionInfo.title:= aTitle;
  fCloseQuestionInfo.text:= aText;
end;

procedure cFormDecorator.setForm(aForm: tForm);
begin
  disconnectFormEvents;

  fForm:= aForm;

  if assigned(fForm) then begin
    fForm.keyPreview:= true;
  end;

  setupFormEvents;
end;

function cFormDecorator.useCloseQuestion: boolean;
begin
  result:= fUseCloseQuestion;
end;

function cFormDecorator.getCloseQuestionInfo: tCloseQuestionInfo;
begin
  result:= fCloseQuestionInfo;
end;


function cFormDecorator.restoreState(const aBytesArray: tBytesArray): boolean;
var
  dataStream: cMemory;

  version: ansiString;

  formLeft: integer;
  formTop: integer;

  formWidth: integer;
  formHeight: integer;

  formWindowsState: tWindowState;

begin
  result:= false;
  dataStream:= cMemory.create;
  try
    dataStream.fromBytes(aBytesArray);


    dataStream.readAnsiString(version);

    if (version = '') then begin
      exit;
    end;

    if (version <> CURRENT_VERSION) then begin
      raise eFormDecorator.createFmt(INVALID_VERSION_FORMAT, [version, CURRENT_VERSION]);
    end;

    dataStream.readInteger(formLeft);
    dataStream.readInteger(formTop);
    dataStream.readInteger(formWidth);
    dataStream.readInteger(formHeight);

    dataStream.readEnum(formWindowsState);

    fForm.left:= formLeft;
    fForm.top:= formTop;
    fForm.width:= formWidth;
    fForm.height:= formHeight;

    fForm.windowState:= formWindowsState;

    result:= true;
  finally
    freeAndNil(dataStream);
  end;
end;

function cFormDecorator.saveState: tBytesArray;
var
  dataStream: cMemory;
begin
  dataStream:= cMemory.create;
  try
    dataStream.clear;

    dataStream.writeAnsiString(CURRENT_VERSION);
    dataStream.writeInteger(fForm.left);
    dataStream.writeInteger(fForm.top);
    dataStream.writeInteger(fForm.width);
    dataStream.writeInteger(fForm.height);

    dataStream.writeEnum(fForm.windowState);

    result:= dataStream.toBytes;
  finally
    freeAndNil(dataStream);
  end;
end;

//SLOTS
procedure cFormDecorator.formKeyDown(aSender: tObject; var aKey: word; aShift: tShiftState);
begin
  if (aKey = VK_ESCAPE) then begin
    if (useCloseQuestion) then begin
      if ((cMessageBox.question(fCloseQuestionInfo.caption, fCloseQuestionInfo.title, fCloseQuestionInfo.text)) = mbbYes) then begin
        fForm.close;
      end;
    end;
  end;
end;

end.
