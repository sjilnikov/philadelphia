unit clsMailSender;

interface
uses
  classes,
  sysUtils,
  generics.collections,
  smtpSend,
  mimemess,
  mimePart;


type
  cAttachment = class
  private
    fFileName: string;
  public
    function    getFileName: string;
    constructor create(aFileName: string);
  end;

  tMailSenderMailType = (mtPlainText, mtHtml);

  cMailSender = class
  private
    fHost           : string;
    fLogin          : string;
    fPassword       : string;
    fFrom           : string;

    fAttachmentList : tObjectList<cAttachment>;
  public
    procedure   setHost(aHost: string);
    procedure   setLogin(aLogin: string);
    procedure   setPassword(aPassword: string);

    procedure   setFrom(aFrom: string);

    function    send(aTo: string; aSubject: string; aBody: string; aMailType: tMailSenderMailType = mtHtml): boolean;

    procedure   addAttachment(aFileName: string);
    procedure   clearAttachment;

    constructor create(aHost: string; aLogin: string; aPassword: string);
    destructor  destroy; override;
  end;


implementation

{ cAttachment }

constructor cAttachment.create(aFileName: string);
begin
  inherited create;
  fFileName:= aFileName;
end;

function cAttachment.getFileName: string;
begin
  result:= fFileName;
end;

{ cMailSender }

constructor cMailSender.create(aHost, aLogin, aPassword: string);
begin
  inherited create;
  setHost(aHost);
  setLogin(aLogin);
  setPassword(aPassword);

  fAttachmentList:= tObjectList<cAttachment>.create;
end;

destructor cMailSender.destroy;
begin
  if assigned(fAttachmentList) then begin
    freeAndNil(fAttachmentList);
  end;

  inherited;
end;

procedure cMailSender.addAttachment(aFileName: string);
begin
  fAttachmentList.add(cAttachment.create(aFileName));
end;

procedure cMailSender.clearAttachment;
begin
  fAttachmentList.clear;
end;

function cMailSender.send(aTo, aSubject, aBody: string; aMailType: tMailSenderMailType): boolean;
var
  mimeMessage : tMimeMess;
  tmpStringList : tStringList;
  tmpMimePart : tMimePart;

  curAttachmentItem: cAttachment;
begin
  result:= false;
  mimeMessage := tMimeMess.create;
  try
  tmpStringList := tStringList.create;
  try
    mimeMessage.header.subject:= aSubject;
    mimeMessage.header.from:= fFrom;
    mimeMessage.header.toList.add(aTo);

    tmpMimePart := mimeMessage.addPartMultipart('alternate', nil);

    tmpStringList.text:= aBody;
    if aMailType = mtPlainText then begin
      mimeMessage.addPartText(tmpStringList, tmpMimePart);
    end else begin
      mimeMessage.addPartHTML(tmpStringList, tmpMimePart);
    end;

    for curAttachmentItem in fAttachmentList do begin
      mimeMessage.addPartBinaryFromFile(curAttachmentItem.getFileName, tmpMimePart);
    end;

    mimeMessage.encodeMessage;
    result:= smtpsend.sendToRaw(fFrom, aTo, fHost, mimeMessage.lines, fLogin, fPassword);

  finally
    freeAndNil(mimeMessage);
  end;
  finally
    freeAndNil(tmpStringList);
  end;
end;

procedure cMailSender.setFrom(aFrom: string);
begin
  fFrom:= aFrom;
end;

procedure cMailSender.setHost(aHost: string);
begin
  fHost:= aHost;
end;

procedure cMailSender.setLogin(aLogin: string);
begin
  fLogin:= aLogin;
end;

procedure cMailSender.setPassword(aPassword: string);
begin
  fPassword:= aPassword;
end;

end.
