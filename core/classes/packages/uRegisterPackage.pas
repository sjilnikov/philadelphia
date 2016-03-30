unit uRegisterPackage;

interface
uses
  controls,
  classes,

  clsRangeSlider,
  clsSQLFilterDesignerWidget,
  clsTablePagerWidget;

procedure register;

implementation

procedure register;
begin
  registerComponents('Data Controls', [tTablePagerWidget]);
  registerComponents('Data Controls', [tSQLFilterDesignerWidget]);
  registerComponents('Additional', [tRangeSlider]);
end;

end.
