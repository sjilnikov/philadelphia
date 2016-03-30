unit clsCurrencyUtils;

interface

type

  cCurrencyUtils = class
  public
    class function getSumTotal(aSum: currency; aDiscount: currency): currency;
    class function getDiscount(aSum: currency; aSumTotal: currency): currency;
    class function getSum(aSumTotal: currency; aDiscount: currency): currency;
  end;

implementation

{ cCurrencyUtils }

class function cCurrencyUtils.getDiscount(aSum, aSumTotal: currency): currency;
begin
  result:= 100 - (100 * aSumTotal / aSum);
end;

class function cCurrencyUtils.getSum(aSumTotal, aDiscount: currency): currency;
begin
  result:= (aSumTotal * 100) / (100 - aDiscount);
end;

class function cCurrencyUtils.getSumTotal(aSum, aDiscount: currency): currency;
begin
  result:= (aSum * (100 - aDiscount)) / 100;
end;

end.
