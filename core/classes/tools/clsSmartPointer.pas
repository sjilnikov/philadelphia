unit clsSmartPointer;

interface

uses
  sysUtils,
  generics.defaults;

type
  cSmartPointer<T: class, constructor> = record
  strict private
    fValue            : T;
    fFreeTheValue     : iInterface;
    function getValue : T;
  private
    type
      cFreeTheValue = class (tInterfacedObject)
      private
        fObjectToFree: tObject;
      public
        constructor create(aObjectToFree: tObject);
        destructor  destroy; override;
      end;
  public
    constructor create(aValue: T); overload;
    procedure   create; overload;

    property    value: T read getValue;
  public
    class operator implicit(aValue: T): cSmartPointer<T>;
    class operator implicit(aSmartPointer: cSmartPointer <T>): T;
  end;

implementation

{ cSmartPointer<T> }

constructor cSmartPointer<T>.create(aValue: T);
begin
  fValue := aValue;
  fFreeTheValue := cFreeTheValue.create(fValue);
end;

procedure cSmartPointer<T>.create;
begin
  create(T.create);
end;

function cSmartPointer<T>.getValue: T;
begin
  if not assigned(fFreeTheValue) then begin
    create;
  end;

  result:= fValue;
end;

class operator cSmartPointer<T>.implicit(aSmartPointer: cSmartPointer<T>): T;
begin
  result:= aSmartPointer.value;
end;

class operator cSmartPointer<T>.implicit(aValue: T): cSmartPointer<T>;
begin
  result:= cSmartPointer<T>.create(aValue);
end;

{ cSmartPointer<T>.cFreeTheValue }

constructor cSmartPointer<T>.cFreeTheValue.create(aObjectToFree: tObject);
begin
  fObjectToFree:= aObjectToFree;
end;

destructor cSmartPointer<T>.cFreeTheValue.destroy;
begin
  freeAndNil(fObjectToFree);
  inherited;
end;


end.
