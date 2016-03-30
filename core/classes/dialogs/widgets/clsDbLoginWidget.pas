unit clsDbLoginWidget;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ExtCtrls,
  StdCtrls,

  clsStringUtils,
  clsMessageBox,
  clsMulticastEvents,
  clsAbstractSQLConnection;

type
  {$REGION 'UI'}
  TfrmDbLogin = class(TForm)
    pClient: TPanel;
    pBottom: TPanel;
    gPanel: TGridPanel;
    pButtons: TPanel;
    sbLogin: TButton;
    sbCancel: TButton;
    eLogin: TEdit;
    ePassword: TEdit;
    lbLogin: TLabel;
    lbPassword: TLabel;
    lbAttempts: TLabel;
  private

    const

    CAPTION_FORMAT                 = 'Доступ к базе: [%s]';

    LOGIN_LABEL_CAPTION            = 'Логин';
    PASSWORD_LABEL_CAPTION         = 'Пароль';

    LOGIN_BUTTON_CAPTION           = 'войти';
    CANCEL_BUTTON_CAPTION          = 'отмена';

    ATTEMPTS_LABEL_CAPTION_FORMAT  = 'У вас осталось %s';
  private
    fDbName      : string;
    fAttemps     : integer;

    procedure    initialize;

    procedure    updateCaption;

    procedure    setCaption(aCaption: string);

    procedure    createParams(var aParams: tCreateParams); override;
  public
    constructor  create(aOwner: tComponent); override;

    procedure    setAttempts(aValue: integer);
    function     getAttemps: integer;

    procedure    setDbName(aName: string);
    function     getDbName: string;

    procedure    setLogin(aLogin: string);
    procedure    setPassword(aPassword: string);

    function     getLogin: string;
    function     getPassword: string;
  end;
  {$ENDREGION}

  cDbLoginWidget = class;

  tDbLoginWidgetSaveStateEvent = procedure(aSender: cDbLoginWidget; aUi: tFrmDbLogin) of object;
  tDbLoginWidgetRestoreStateEvent = procedure(aSender: cDbLoginWidget; aUi: tFrmDbLogin) of object;

  cDbLoginWidget = class
  private
    const

    ATTEMPTS_COUNT                = 3;
    IDENTIFICATION_FAILED_MESSAGE = 'Идентификационные данные указаны неверно';

  private
    fUi             :  TfrmDbLogin;

    fConnection     : cAbstractSQLConnection;

    fOnSaveState    : tDbLoginWidgetSaveStateEvent;
    fOnRestoreState : tDbLoginWidgetRestoreStateEvent;

    procedure    createUI;
    procedure    removeUI;

    procedure    setupUiEvents;
    procedure    disconnectUiEvents;

    procedure    setConnection(aConnection: cAbstractSQLConnection);

    function     showModal: tModalResult;

    constructor  create;
    destructor   destroy; override;

    property     ui: tFrmDbLogin read fUi write fUi;
  public
    class procedure login(aConnection: cAbstractSQLConnection);
  published
    {$REGION 'SLOTS'}
    procedure    sbLoginClick(aSender: tObject);
    procedure    sbCancelClick(aSender: tObject);
    {$ENDREGION}
  published
    {$REGION 'EVENTS'}
    property     onSaveState: tDbLoginWidgetSaveStateEvent read fOnSaveState write fOnSaveState;
    property     onRestoreState: tDbLoginWidgetRestoreStateEvent read fOnRestoreState write fOnRestoreState;
    {$ENDREGION}
  end;

implementation

{$R *.dfm}

{ TfrmLoginWidget }

constructor TfrmDbLogin.create(aOwner: tComponent);
begin
  inherited create(aOwner);

  initialize;
end;

procedure TfrmDbLogin.createParams(var aParams: tCreateParams);
begin
  inherited createParams(aParams);
  with aParams do begin
    exStyle:= exStyle or WS_EX_TOPMOST;
    wndParent:= getDesktopwindow;
  end;
end;

function TfrmDbLogin.getAttemps: integer;
begin
  result:= fAttemps;
end;

function TfrmDbLogin.getDbName: string;
begin
  result:= fDbName;
end;

function TfrmDbLogin.getLogin: string;
begin
  result:= eLogin.text;
end;

function TfrmDbLogin.getPassword: string;
begin
  result:= ePassword.text;
end;

procedure TfrmDbLogin.initialize;
begin
  lbLogin.caption:= LOGIN_LABEL_CAPTION;
  lbPassword.caption:= PASSWORD_LABEL_CAPTION;

  sbLogin.caption:= LOGIN_BUTTON_CAPTION;
  sbCancel.caption:= CANCEL_BUTTON_CAPTION;

  setDbName('');
  setAttempts(0);
end;

procedure TfrmDbLogin.setAttempts(aValue: integer);
begin
  fAttemps:= aValue;

  lbAttempts.caption:= format(ATTEMPTS_LABEL_CAPTION_FORMAT, [cStringUtils.getConcatDeclination(aValue, ['попытка', 'попытки', 'попыток'])]);
end;

procedure TfrmDbLogin.setCaption(aCaption: string);
begin
  caption:= aCaption;
end;

procedure TfrmDbLogin.setDbName(aName: string);
begin
  fDbName:= aName;

  updateCaption;
end;

procedure TfrmDbLogin.setLogin(aLogin: string);
begin
  eLogin.text:= aLogin;
end;

procedure TfrmDbLogin.setPassword(aPassword: string);
begin
  ePassword.text:= aPassword;
end;

procedure TfrmDbLogin.updateCaption;
begin
  setCaption(format(CAPTION_FORMAT, [getDbName]));
end;

{ cDbLoginWidget }

constructor cDbLoginWidget.create;
begin
  inherited create;

  createUI;
  setupUiEvents;
end;

destructor cDbLoginWidget.destroy;
begin
  disconnectUiEvents;
  removeUI;


  inherited;
end;

procedure cDbLoginWidget.createUI;
begin
  fUi:= tFrmDbLogin.create(nil);

  if assigned(fOnRestoreState) then begin
    fOnRestoreState(self, ui);
  end;
end;

procedure cDbLoginWidget.removeUI;
begin
  if assigned(fOnSaveState) then begin
    fOnSaveState(self, ui);
  end;

  if assigned(fUi) then begin
    freeAndNil(fUi);
  end;
end;

procedure cDbLoginWidget.setupUiEvents;
begin
  connect(ui.sbLogin, 'onClick', self, 'sbLoginClick');
  connect(ui.sbCancel, 'onClick', self, 'sbCancelClick');
end;

function cDbLoginWidget.showModal: tModalResult;
begin
  result:= fUi.showModal;
end;

procedure cDbLoginWidget.disconnectUiEvents;
begin
  disconnect(ui.sbLogin);
  disconnect(ui.sbCancel);
end;

class procedure cDbLoginWidget.login(aConnection: cAbstractSQLConnection);
var
  instance: cDbLoginWidget;
begin
  instance:= cDbLoginWidget.create;
  try
    instance.setConnection(aConnection);
    instance.showModal;
  finally
    freeAndNil(instance);
  end;
end;

procedure cDbLoginWidget.setConnection(aConnection: cAbstractSQLConnection);
begin
  fConnection:= aConnection;

  fUi.setAttempts(ATTEMPTS_COUNT);
  fUi.setDbName(aConnection.connectionInfo.database);
end;

{$REGION 'SLOTS'}
procedure cDbLoginWidget.sbLoginClick(aSender: tObject);
var
  attempts: integer;
begin
  fConnection.setUserName(ui.getLogin);
  fConnection.setPassword(ui.getPassword);

  if (fConnection.open) then begin
    ui.modalResult:= mrOk;
    exit;
  end else begin
    cMessageBox.critical(
      'Ошибка подключение к базе',
      format('Возникла ошибка при попытке подключения к базе: [%s]', [fConnection.connectionInfo.database]),
      'Невозможно идентифицировать пользователя или возникла внутренняя ошибка',

      fConnection.getLastError
    );

    attempts:= ui.getAttemps - 1;

    if (attempts = 0) then begin
      cMessageBox.critical(
        'Ошибка подключение к базе',
        'Исчерпано количество попыток',
        'Не удалось подключиться к базе, так как исчерпано количество попыток'
      );

      ui.modalResult:= mrCancel;
      exit;
    end;

    ui.setAttempts(attempts);
  end;
end;

procedure cDbLoginWidget.sbCancelClick(aSender: tObject);
begin
  application.terminate;
end;
{$ENDREGION}

end.
