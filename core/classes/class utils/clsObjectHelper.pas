unit clsObjectHelper;

interface
uses
  clsApplication;

type
  cObjectHelper = class helper for tObject
  public
    procedure deleteLater;
  end;


implementation

{ cObjectHelper }

procedure cObjectHelper.deleteLater;
begin
  cApplication.getInstance.deleteLater(self);
end;

end.
