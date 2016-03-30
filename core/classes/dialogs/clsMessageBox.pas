unit clsMessageBox;

interface

uses
  windows,
  messages,
  sysUtils,
  variants,
  classes,
  graphics,
  controls,
  forms,
  dialogs,
  pngimage,
  extCtrls,
  stdCtrls,
  commCtrl,

  math,

  clsException,
  clsResources,

  clsComponentUtils,
  clsLists;


type
  eMessageBox = class(cException);

  tMessageBoxIcon = (mbtNoIcon, mbiInfo, mbiQuestion, mbiWarning, mbiCritical);

  tMessageBoxButtonAddPosition = (apLeft, apRight);

  tMessageBoxButtonType = (
    mbbNoButtons,
    mbbShowDetatils,
    mbbOk,
    mbbOpen,
    mbbSave,
    mbbCancel,
    mbbClose,
    mbbDiscard,
    mbbApply,
    mbbReset,
    mbbRestoreDefauls,
    mbbHelp,
    mbbSaveAll,
    mbbYes,
    mbbYesToAll,
    mbbNo,
    mbbNoToAll,
    mbbAbort,
    mbbRetry,
    mbbIgnore
  );

  tMessageBoxButtonTypes = set of tMessageBoxButtonType;

  tMessageBoxButtonClickEvent = procedure(aSender: tObject) of object;

  cMessageBoxButton = class
  private
    const

    PARENT_CLASS_IS_NOT_WINCONTROL = 'parent class: %s not inherited by tWinControl';
  private
    fButton         : tButton;

    fButtonType     : tMessageBoxButtonType;
    fParent         : tComponent;
    fDefault        : boolean;
    fAddPosition    : tMessageBoxButtonAddPosition;

    fRightMargin    : integer;
    fLeftMargin     : integer;
    fTopMargin      : integer;
    fBottomMargin   : integer;
    fAlign          : tAlign;
    fOnClick        : tMessageBoxButtonClickEvent;

    procedure   createButton;
    procedure   setupButton;

    procedure   setupButtonEvents;
    procedure   disconnectButtonEvents;

    procedure   applyDefaults;

  public
    function    getButton: tButton;
    function    getButtonType: tMessageBoxButtonType;
    function    getParent: tComponent;

    function    isDefault: boolean;

    procedure   setRightMargin(aMargin: integer);
    procedure   setLeftMargin(aMargin: integer);
    procedure   setTopMargin(aMargin: integer);
    procedure   setBottomMargin(aMargin: integer);

    procedure   setDefault(aValue: boolean);

    procedure   setAlign(aAlign: tAlign);

    function    getRightMargin: integer;
    function    getLeftMargin: integer;
    function    getTopMargin: integer;
    function    getBottomMargin: integer;

    function    getAlign: tAlign;

    constructor create(aParent: tComponent; aButtonType: tMessageBoxButtonType; aDefault: boolean; aAlign: tAlign; aAddPosition: tMessageBoxButtonAddPosition);
    destructor  destroy; override;

  published
  //SLOTS
    procedure   buttonClick(aSender: tObject);

  published
  //EVENTS

    property    onClick: tMessageBoxButtonClickEvent read fOnClick write fOnClick;
  end;

  cMessageBoxButtons = class
  private
    fList       : cList;
    fParent     : tComponent;

    function    getCount: integer;
    function    getItemByIndex(aIndex: integer): cMessageBoxButton;
    function    getItemByButtonType(aButtonType: tMessageBoxButtonType): cMessageBoxButton;

    procedure   add(aItem: cMessageBoxButton);

  public
    procedure   clear;

    procedure   delete(aItem: cMessageBoxButton);

    function    indexOfItem(aItem: cMessageBoxButton): integer;
    function    indexOfType(aType: tMessageBoxButtonType): integer;

    function    createButton(aMessageBoxButtonType: tMessageBoxButtonType; aDefaultButton: boolean; aAlign: tAlign; aAddPosition: tMessageBoxButtonAddPosition = apRight): cMessageBoxButton;


    constructor create(aParent: tComponent);
    destructor  destroy; override;

    property    items[aIndex: integer]: cMessageBoxButton read getItemByIndex; default;
    property    items[aButtonType: tMessageBoxButtonType]: cMessageBoxButton read getItemByButtonType; default;
    property    count: integer read getCount;
  end;


  tfrmMessageBox = class(tForm)
    pBody: TPanel;
    pButtons: TPanel;
    pIcon: TPanel;
    pMessage: TPanel;
    imgIcon: TImage;
    pMessageHeader: TPanel;
    pMessageBody: TPanel;
    lbMessageTitle: TLabel;
    pDetalization: TPanel;
    mDetalization: TMemo;
    mMessageBody: TMemo;
  private
    const
    ICON_TYPE_RESOURCES_NAME: array[low(tMessageBoxIcon)..high(tMessageBoxIcon)] of string = (
      '',
      repositoryResources.MSG_BOX_INFO_ICON_RESOURCE,
      repositoryResources.MSG_BOX_QUESTION_RESOURCE,
      repositoryResources.MSG_BOX_WARNING_RESOURCE,
      repositoryResources.MSG_BOX_CRITICAL_RESOURCE
    );
  private
    fDetalizationHeight  : integer;
    fBodyHeight          : integer;
    fBodyWidth           : integer;
    fDetalizationVisible : boolean;

    fButtons             : cMessageBoxButtons;
    fClickedButtonType   : tMessageBoxButtonType;

    procedure   destroyDetailsButton;
    procedure   createDetailsButton;
    procedure   createButtons(aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType);
    procedure   deleteButtons;

    procedure   disconnectButtonsEvents;

    procedure   setBodyHeight(aBodyHeight: integer);
    procedure   setBodyWidth(aBodyWidth: integer);

    procedure   updateMessageHeight;
    procedure   updateMessageWidth;
  public
    procedure   render(aCaption: string; aTitle: string; aMessage: string; aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType);

    function    getButtons: cMessageBoxButtons;

    function    getClickedButtonType: tMessageBoxButtonType;

    procedure   setCaption(aCaption: string);
    procedure   setTitle(aTitle: string);
    procedure   setIcon(aIcon: tMessageBoxIcon);
    procedure   setMessage(aMessage: string);


    procedure   setDetails(aDetalization: string);

    procedure   setDetalizationHeight(aHeight: integer);

    function    getBodyHeight: integer;
    function    getBodyWidth: integer;

    function    getDetalizationHeight: integer;

    function    getPanelButtonWidth: integer;

    function    getButtonsContainer: tPanel;

    function    isDetalizationVisible: boolean;

    procedure   setDetalizationVisible(aValue: boolean);

    constructor create(aOwner: tComponent); override;
    destructor  destroy; override;

    property    buttons: cMessageBoxButtons read getButtons;
  published
    //SLOTS

    procedure   buttonClick(aSender: tObject);
    procedure   detailsClick(aSender: tObject);
  end;

  cMessageBox = class
  private
    constructor       create;
    destructor        destroy; override;

    class function    showModal(aIcon: tMessageBoxIcon; aCaption: string; aTitle: string; aMessage: string; aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType): tMessageBoxButtonType;
  public

    class function    out(aMessage: variant; aArgs: array of const; aCaption: string = 'debug'; aTitle: string = ''; aDetails: string = ''; aButtons: tMessageBoxButtonTypes = [mbbOk]; aDefaultButton: tMessageBoxButtonType = mbbOk): tMessageBoxButtonType; overload;
    class function    out(aMessage: variant; aCaption: string = 'debug'; aTitle: string = ''; aDetails: string = ''; aButtons: tMessageBoxButtonTypes = [mbbOk]; aDefaultButton: tMessageBoxButtonType = mbbOk): tMessageBoxButtonType; overload;

    class function    information(aCaption: string; aTitle: string; aMessage: string; aDetails: string = ''; aButtons: tMessageBoxButtonTypes = [mbbOk]; aDefaultButton: tMessageBoxButtonType = mbbOk): tMessageBoxButtonType; overload;
    class function    question(aCaption: string; aTitle: string; aMessage: string; aDetails: string = ''; aButtons: tMessageBoxButtonTypes = [mbbYes, mbbNo]; aDefaultButton: tMessageBoxButtonType = mbbNo): tMessageBoxButtonType; overload;
    class function    warning(aCaption: string; aTitle: string; aMessage: string; aDetails: string = ''; aButtons: tMessageBoxButtonTypes = [mbbOk]; aDefaultButton: tMessageBoxButtonType = mbbOk): tMessageBoxButtonType; overload;
    class function    critical(aCaption: string; aTitle: string; aMessage: string; aDetails: string = ''; aButtons: tMessageBoxButtonTypes = [mbbOk]; aDefaultButton: tMessageBoxButtonType = mbbOk): tMessageBoxButtonType; overload;
  end;

type
  sMessageBoxButtonParams = record
    caption     : string;
    modalResult : tModalResult;
    isSplit     : boolean;
  end;

const

  MESSAGE_BOX_BUTTON_PARAMS: array[low(tMessageBoxButtonType)..high(tMessageBoxButtonType)] of sMessageBoxButtonParams = (
    (caption: ''                       ; modalResult: mrNone      ; isSplit: false),
    (caption: 'Детали...'              ; modalResult: mrNone      ; isSplit: true),
    (caption: 'Ок'                     ; modalResult: mrOk        ; isSplit: false),
    (caption: 'Открыть'                ; modalResult: mrOk        ; isSplit: false),
    (caption: 'Сохранить'              ; modalResult: mrOk        ; isSplit: false),
    (caption: 'Отменить'               ; modalResult: mrCancel    ; isSplit: false),
    (caption: 'Закрыть'                ; modalResult: mrClose     ; isSplit: false),
    (caption: 'Оставить без изменений' ; modalResult: mrCancel    ; isSplit: false),
    (caption: 'Применить'              ; modalResult: mrOk        ; isSplit: false),
    (caption: 'Сбросить'               ; modalResult: mrOk        ; isSplit: false),
    (caption: 'Восстановить значения'  ; modalResult: mrOk        ; isSplit: false),
    (caption: 'Помощь'                 ; modalResult: mrOk        ; isSplit: false),
    (caption: 'Сохранить все'          ; modalResult: mrYesToAll  ; isSplit: false),
    (caption: 'Да'                     ; modalResult: mrYes       ; isSplit: false),
    (caption: 'Да для всех'            ; modalResult: mrYesToAll  ; isSplit: false),
    (caption: 'Нет'                    ; modalResult: mrNo        ; isSplit: false),
    (caption: 'Нет для всех'           ; modalResult: mrNoToAll   ; isSplit: false),
    (caption: 'Прервать'               ; modalResult: mrAbort     ; isSplit: false),
    (caption: 'Повторить'              ; modalResult: mrRetry     ; isSplit: false),
    (caption: 'Пропустить'             ; modalResult: mrIgnore    ; isSplit: false)
  );

var
  frmMessageBox: TfrmMessageBox;
  i: integer;

implementation
uses
  clsMulticastEvents;

{$R resources\messageBoxIcons.res}

{$R *.dfm}


{ cMessageBoxButton }

procedure cMessageBoxButton.buttonClick(aSender: tObject);
begin
  if (assigned(fOnClick)) then begin
    fOnClick(self);
  end;
end;

constructor cMessageBoxButton.create(aParent: tComponent; aButtonType: tMessageBoxButtonType; aDefault: boolean; aAlign: tAlign; aAddPosition: tMessageBoxButtonAddPosition);
begin
  inherited create;
  fButton        := nil;

  fButtonType    := aButtonType;

  fParent        := aParent;
  fDefault       := aDefault;
  fAlign         := aAlign;

  fAddPosition   := aAddPosition;

  applyDefaults;

  createButton;
  setupButtonEvents;
  setupButton;
end;

procedure cMessageBoxButton.applyDefaults;
begin
  setRightMargin(0);
  setLeftMargin(0);
  setTopMargin(0);
  setBottomMargin(0);
end;

procedure cMessageBoxButton.createButton;
begin
  fButton:= tButton.create(fParent);

  if (not(fParent is tWinControl)) then begin
    raise eMessageBox.createFmt(PARENT_CLASS_IS_NOT_WINCONTROL, [fParent.className]);
  end;

  fButton.parent:= tWinControl(fParent);
end;

destructor cMessageBoxButton.destroy;
begin
  if assigned(fButton) then begin
    disconnectButtonEvents;

    freeAndNil(fButton);
  end;

  inherited;
end;

procedure cMessageBoxButton.disconnectButtonEvents;
begin
  disconnect(fButton, 'onClick');
end;

function cMessageBoxButton.getAlign: tAlign;
begin
  result:= fAlign;
end;

function cMessageBoxButton.getBottomMargin: integer;
begin
  result:= fBottomMargin;
end;

function cMessageBoxButton.getButton: tButton;
begin
  result:= fButton;
end;

function cMessageBoxButton.getButtonType: tMessageBoxButtonType;
begin
  result:= fButtonType;
end;

function cMessageBoxButton.getLeftMargin: integer;
begin
  result:= fLeftMargin;
end;

function cMessageBoxButton.getParent: tComponent;
begin
  result:=  fParent;
end;

function cMessageBoxButton.getRightMargin: integer;
begin
  result:= fRightMargin;
end;

function cMessageBoxButton.getTopMargin: integer;
begin
  result:= fTopMargin;
end;

function cMessageBoxButton.isDefault: boolean;
begin
  result:= fDefault;
end;

procedure cMessageBoxButton.setAlign(aAlign: tAlign);
begin
  fAlign:= aAlign;

  if (not (assigned(fButton))) then exit;
  fButton.align:= fAlign;
end;

procedure cMessageBoxButton.setBottomMargin(aMargin: integer);
begin
  fBottomMargin:= aMargin;

  if (not (assigned(fButton))) then exit;
  fButton.margins.bottom:= fBottomMargin;
end;

procedure cMessageBoxButton.setDefault(aValue: boolean);
begin
  fDefault:= aValue;

  if (not (assigned(fButton))) then exit;
  fButton.default:= fDefault;
end;

procedure cMessageBoxButton.setLeftMargin(aMargin: integer);
begin
  fLeftMargin:= aMargin;

  if (not (assigned(fButton))) then exit;
  fButton.margins.left:= fLeftMargin;
end;

procedure cMessageBoxButton.setRightMargin(aMargin: integer);
begin
  fRightMargin:= aMargin;

  if (not (assigned(fButton))) then exit;
  fButton.margins.right:= fRightMargin;
end;

procedure cMessageBoxButton.setTopMargin(aMargin: integer);
begin
  fTopMargin:= aMargin;

  if (not (assigned(fButton))) then exit;
  fButton.margins.top:= fTopMargin;
end;

procedure cMessageBoxButton.setupButton;
const
  TEXT_MARGIN = 10;
  BUTTON_HEIGHT = 25;

var
  splitBtnInfo: tButtonSplitinfo;
  splitWidth: integer;

  buttonWidth: integer;

  cnv: tCanvas;

  buttonParams: sMessageBoxButtonParams;
begin
  splitWidth:= 0;

  buttonParams:= MESSAGE_BOX_BUTTON_PARAMS[fButtonType];

  //need check is split supports
  buttonParams.isSplit:= ((buttonParams.isSplit) and (commCtrl.button_GetSplitInfo(fButton.handle, splitBtnInfo)));


  if (buttonParams.isSplit) then begin
    fButton.style:= bsSplitButton;
  end;

  cnv:= tCanvas.create;
  try
    cnv.handle:= getWindowDC(fButton.handle);

    cnv.font.assign(fButton.font);

    fButton.alignWithMargins  := true;
    fButton.margins.setBounds(getLeftMargin, getTopMargin, getRightMargin, getBottomMargin);

    fButton.modalResult       := buttonParams.modalResult;

    if (buttonParams.isSplit) then begin

      zeroMemory(@splitBtnInfo, sizeOf(splitBtnInfo));
      splitBtnInfo.mask:= BCSIF_SIZE;

      commCtrl.button_GetSplitInfo(fButton.handle, splitBtnInfo);

      splitWidth:= splitBtnInfo.size.cx;
    end;

    fButton.caption           := buttonParams.caption;
    buttonWidth:= cnv.textWidth(buttonParams.caption) + splitWidth + 2 * TEXT_MARGIN;
    setDefault(isDefault);

    fButton.width             := buttonWidth;
    fButton.height            := BUTTON_HEIGHT;

    case fAddPosition of
      apLeft  : fButton.left  := 0;
      apRight : fButton.left  := tWinControl(fParent).width;
    end;

    fButton.align             := getAlign;
  finally
    freeAndNil(cnv);
  end;

end;

procedure cMessageBoxButton.setupButtonEvents;
begin
  connect(fButton, 'onClick', self, 'buttonClick');
end;

{ cMessageBoxButtons }

procedure cMessageBoxButtons.add(aItem: cMessageBoxButton);
begin
  fList.add(aItem)
end;

procedure cMessageBoxButtons.clear;
begin
  fList.freeInternalObjects;
  fList.clear;
end;

constructor cMessageBoxButtons.create(aParent: tComponent);
begin
  inherited create;
  fList:=  cList.create;

  fParent:= aParent;
end;

function cMessageBoxButtons.createButton(aMessageBoxButtonType: tMessageBoxButtonType; aDefaultButton: boolean; aAlign: tAlign; aAddPosition: tMessageBoxButtonAddPosition): cMessageBoxButton;
var
  foundIndex: integer;
begin
  foundIndex:= indexOfType(aMessageBoxButtonType);

  if (foundIndex <> -1) then begin
    result:= items[foundIndex];
    exit;
  end;


  result:= cMessageBoxButton.create(
    fParent,
    aMessageBoxButtonType,
    aDefaultButton,
    aAlign,
    aAddPosition
  );
  add(result);
end;

procedure cMessageBoxButtons.delete(aItem: cMessageBoxButton);
var
  foundIndex: integer;
begin
  foundIndex:= indexOfItem(aItem);
  if (foundIndex = -1) then exit;

  freeAndNil(aItem);
  fList.delete(foundIndex);
end;

destructor cMessageBoxButtons.destroy;
begin
  if (assigned(fList)) then begin
    clear;
    freeAndNil(fList);
  end;

  inherited;
end;

function cMessageBoxButtons.getCount: integer;
begin
  result:= fList.count;
end;

function cMessageBoxButtons.getItemByButtonType(aButtonType: tMessageBoxButtonType): cMessageBoxButton;
var
  foundIndex: integer;
begin
  result:= nil;
  foundIndex:= indexOfType(aButtonType);

  if (foundIndex = -1) then exit;

  result:= items[foundIndex];
end;

function cMessageBoxButtons.getItemByIndex(aIndex: integer): cMessageBoxButton;
begin
  result:= fList.items[aIndex];
end;

function cMessageBoxButtons.indexOfItem(aItem: cMessageBoxButton): integer;
begin
  result:= fList.indexOf(aItem);
end;

function cMessageBoxButtons.indexOfType(aType: tMessageBoxButtonType): integer;
var
  i: integer;
  curBtn: cMessageBoxButton;
begin
  result:= -1;
  for i:=0 to count - 1 do begin
    curBtn:= items[i];

    if (curBtn.getButtonType = aType) then begin
      result:= i;
      exit;
    end;
  end;
end;

{ tfrmMessageBox }

constructor tfrmMessageBox.create(aOwner: tComponent);
begin
  inherited create(aOwner);

  fButtons:= cMessageBoxButtons.create(getButtonsContainer);

  borderStyle:= bsToolWindow;

  setIcon(mbiWarning);

  setDetalizationHeight(200);
  setBodyHeight(200);

  setDetalizationVisible(false);
end;

procedure tfrmMessageBox.createButtons(aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType);
var
  btnType: tMessageBoxButtonType;
  defBtn: cMessageBoxButton;

  newBtn: cMessageBoxButton;
begin
  for btnType in aButtons do begin
    newBtn:= buttons.createButton(btnType, false, alRight);
    newBtn.setLeftMargin(5);

    if (btnType = mbbShowDetatils) then continue;

    connect(newBtn, 'onClick', self, 'buttonClick');
  end;

  defBtn:= buttons.items[aDefaultButton];
  if (assigned(defBtn)) then begin
    defBtn.setDefault(true);
    activeControl:= defBtn.getButton;
  end;
end;

destructor tfrmMessageBox.destroy;
begin
  destroyDetailsButton;

  if (assigned(fButtons)) then begin
    deleteButtons;

    freeAndNil(fButtons);
  end;

  inherited;
end;

function tfrmMessageBox.getButtons: cMessageBoxButtons;
begin
  result:= fButtons;
end;

function tfrmMessageBox.getButtonsContainer: tPanel;
begin
  result:= pButtons;
end;

function tfrmMessageBox.getClickedButtonType: tMessageBoxButtonType;
begin
  result:= fClickedButtonType;
end;

function tfrmMessageBox.getDetalizationHeight: integer;
begin
  result:= fDetalizationHeight;
end;

function tfrmMessageBox.getPanelButtonWidth: integer;
var
  i: integer;
  curBtn: cMessageBoxButton;
  curBtnNativeButton: tButton;
begin
  result:= 0;

  for i:= 0 to fButtons.count - 1 do begin
    curBtn:= fButtons.items[i];

    curBtnNativeButton:= curBtn.getButton;

    result:= result +
      curBtnNativeButton.margins.left + curBtnNativeButton.margins.right +
      curBtnNativeButton.width +
      pButtons.padding.left + pButtons.padding.right;

  end;
end;

function tfrmMessageBox.getBodyHeight: integer;
begin
  result:= fBodyHeight;
end;

function tfrmMessageBox.getBodyWidth: integer;
begin
  result:= fBodyWidth;
end;

procedure tfrmMessageBox.render(aCaption, aTitle, aMessage, aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType);
begin
  deleteButtons;

  setCaption(aCaption);
  setTitle(aTitle);
  setMessage(aMessage);

  createButtons(aButtons, aDefaultButton);

  setDetails(aDetails);

  autoSize:= false;
  try
    updateMessageWidth;
    updateMessageHeight;

    clientWidth:= max(
      clientWidth,
      getPanelButtonWidth + padding.left + padding.right
    );

  finally
    autoSize:= true;
  end;
end;

procedure tfrmMessageBox.updateMessageWidth;
begin
  setBodyWidth(
    pIcon.width +
    pMessageBody.padding.left + pMessageBody.padding.right +
    cComponentUtils.getMemoTextWidth(mMessageBody)
  );
end;

procedure tfrmMessageBox.updateMessageHeight;
begin
  setBodyHeight(
    pMessageHeader.height +
    cComponentUtils.getMemoTextHeight(mMessageBody) +
    pMessageBody.padding.left + pMessageBody.padding.right
  );
end;

procedure tfrmMessageBox.deleteButtons;
begin
  disconnectButtonsEvents;
  fButtons.clear;
end;

procedure tfrmMessageBox.disconnectButtonsEvents;
var
  i: integer;
  curBtn: cMessageBoxButton;
begin
  for i:= 0 to buttons.count - 1 do begin
    curBtn:= buttons.items[i];

    if (curBtn.getButtonType = mbbShowDetatils) then continue;

    disconnect(curBtn, 'onClick');
  end;
end;

function tfrmMessageBox.isDetalizationVisible: boolean;
begin
  result:= fDetalizationVisible;
end;

procedure tfrmMessageBox.setBodyHeight(aBodyHeight: integer);
begin
  fBodyHeight:= aBodyHeight;

  pBody.height:= fBodyHeight;
end;

procedure tfrmMessageBox.setBodyWidth(aBodyWidth: integer);
begin
  fBodyWidth:= aBodyWidth;

  clientWidth:=
    aBodyWidth +
    padding.left + padding.right;
end;

procedure tfrmMessageBox.setCaption(aCaption: string);
begin
  caption:= aCaption;
end;

procedure tfrmMessageBox.setDetails(aDetalization: string);
var
  foundButtonIndex: integer;
  foundButton: cMessageBoxButton;
begin
  mDetalization.text:= aDetalization;

  if (mDetalization.text = '') then begin
    destroyDetailsButton;
  end else begin
    createDetailsButton;
  end;

end;

procedure tfrmMessageBox.createDetailsButton;
var
  foundButtonIndex: integer;
  newButton: cMessageBoxButton;
begin
  foundButtonIndex:= fButtons.indexOfType(mbbShowDetatils);
  if (foundButtonIndex = -1) then begin
    newButton:= fButtons.createButton(mbbShowDetatils, false, alLeft);
    connect(newButton, 'onClick', self, 'detailsClick');
  end;
end;

procedure tfrmMessageBox.destroyDetailsButton;
var
  foundButtonIndex: integer;
  foundButton: cMessageBoxButton;
begin
  foundButtonIndex:= fButtons.indexOfType(mbbShowDetatils);
  if (foundButtonIndex <> -1) then begin
    foundButton:= fButtons.items[foundButtonIndex];

    disconnect(foundButton, 'onClick');
  end;
end;

procedure tfrmMessageBox.setDetalizationHeight(aHeight: integer);
begin
  fDetalizationHeight:= aHeight;

  pDetalization.height:= aHeight;
end;

procedure tfrmMessageBox.setDetalizationVisible(aValue: boolean);
begin
  fDetalizationVisible:= aValue;

  pDetalization.visible:= fDetalizationVisible;
end;

procedure tfrmMessageBox.setIcon(aIcon: tMessageBoxIcon);
var
  res: tResourceStream;
  pngImage: tPngImage;
begin
  imgIcon.hide;
  if (aIcon = mbtNoIcon) then begin
    exit;
  end;


  res:= tResourceStream.create(hInstance, ICON_TYPE_RESOURCES_NAME[aIcon], repositoryResources.RESOURCES_SECTION);
  try
    pngImage:= tPngImage.create;
    try
      pngImage.loadFromStream(res);

      imgIcon.picture.assign(pngImage);

      imgIcon.show;

    finally
      freeAndNil(pngImage);
    end;

  finally
    freeAndNil(res);
  end;
end;

procedure tfrmMessageBox.setMessage(aMessage: string);
begin
  mMessageBody.text:= aMessage;
end;

procedure tfrmMessageBox.setTitle(aTitle: string);
begin
  lbMessageTitle.caption:= aTitle;
end;

//SLOTS
procedure tfrmMessageBox.detailsClick(aSender: tObject);
begin
  setDetalizationVisible(not isDetalizationVisible);
end;

procedure tfrmMessageBox.buttonClick(aSender: tObject);
begin
  fClickedButtonType:= (aSender as cMessageBoxButton).getButtonType;
end;

{cMessageBox}
class function cMessageBox.showModal(aIcon: tMessageBoxIcon; aCaption, aTitle, aMessage, aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType): tMessageBoxButtonType;
var
  messageBoxForm: tfrmMessageBox;
begin
  result:= mbbNoButtons;

  messageBoxForm:= tfrmMessageBox.create(nil);
  try
    messageBoxForm.setIcon(aIcon);
    messageBoxForm.render(aCaption, aTitle, aMessage, aDetails, aButtons, aDefaultButton);

    messageBoxForm.showModal;

    result:= messageBoxForm.getClickedButtonType;

  finally
    freeAndNil(messageBoxForm);
  end;
end;

class function cMessageBox.out(aMessage: variant; aArgs: array of const; aCaption: string; aTitle: string; aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType): tMessageBoxButtonType;
var
  strMessage: string;
begin
  strMessage:= varToStr(aMessage);
  if (length(aArgs) <> 0) then begin
    strMessage:= format(strMessage, aArgs);
  end;


  result:= showModal(mbiInfo, aCaption, aTitle, strMessage, aDetails, aButtons, aDefaultButton);
end;

class function cMessageBox.out(aMessage: variant; aCaption, aTitle, aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType): tMessageBoxButtonType;
begin
  result:= out(aMessage, [], aCaption, aTitle, aDetails, aButtons, aDefaultButton);
end;

class function cMessageBox.information(aCaption, aTitle, aMessage, aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType): tMessageBoxButtonType;
begin
  result:= showModal(mbiInfo, aCaption, aTitle, aMessage, aDetails, aButtons, aDefaultButton);
end;

class function cMessageBox.question(aCaption, aTitle, aMessage, aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType): tMessageBoxButtonType;
begin
  result:= showModal(mbiQuestion, aCaption, aTitle, aMessage, aDetails, aButtons, aDefaultButton);
end;

class function cMessageBox.warning(aCaption, aTitle, aMessage, aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType): tMessageBoxButtonType;
begin
  result:= showModal(mbiWarning, aCaption, aTitle, aMessage, aDetails, aButtons, aDefaultButton);
end;

class function cMessageBox.critical(aCaption, aTitle, aMessage, aDetails: string; aButtons: tMessageBoxButtonTypes; aDefaultButton: tMessageBoxButtonType): tMessageBoxButtonType;
begin
  result:= showModal(mbiCritical, aCaption, aTitle, aMessage, aDetails, aButtons, aDefaultButton);
end;

constructor cMessageBox.create;
begin
  inherited create;
end;

destructor cMessageBox.destroy;
begin
  inherited;
end;

end.
