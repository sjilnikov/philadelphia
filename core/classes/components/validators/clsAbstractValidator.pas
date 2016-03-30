unit clsAbstractValidator;

interface

type

  tValidState = (vsInvalid, vsIntermediate, vsAcceptable);

  cAbstractValidator = class
  public
    function   validateSingleValue(aWholeData: variant; aNewValue: variant): tValidState; virtual; abstract;
    function   validate(var aValue: variant; var aPos: integer): tValidState; virtual; abstract;
    function   fixup(aValue: variant): variant; virtual; abstract;
  end;

implementation

end.
