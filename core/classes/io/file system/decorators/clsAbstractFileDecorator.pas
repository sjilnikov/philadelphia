unit clsAbstractFileDecorator;

interface
uses
  classes,
  sysUtils,

  clsFile;

type
  cAbstractFileDecorator = class
  private
    fFile       : cFile;
  public
    procedure   setFile(aFile: cFile);
    function    getFile: cFile;

    constructor create;
    destructor  destroy; override;
  end;

implementation

{ cAbstractFileDecorator }

constructor cAbstractFileDecorator.create;
begin
  inherited create;

end;

destructor cAbstractFileDecorator.destroy;
begin

  inherited;
end;

function cAbstractFileDecorator.getFile: cFile;
begin
  result:= fFile;
end;

procedure cAbstractFileDecorator.setFile(aFile: cFile);
begin
  fFile:= aFile;
end;

end.
