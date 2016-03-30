unit clsCities;

interface
uses
  classes,
  clsPGSQLConnection,
  clsSQLTableModel;

type
  cCity = class(cSQLRowBase)
  private
    fTitle: string;
    fCountry_id: integer;
    fRegion_id: integer;
    fTest_date: tDateTime;
    fTest_curr: currency;
    fTest_bool: boolean;

  published

    property region_id: integer read fRegion_id write fRegion_id;
    property country_id: integer read fCountry_id write fCountry_id;
    property title: string read fTitle write fTitle;
    property test_date: tDateTime read fTest_date write fTest_date;
    property test_curr: currency read fTest_curr write fTest_curr;
    property test_bool: boolean read fTest_bool write fTest_bool;

  end;

  cCities = class(cSQLTableModel)
  public
    constructor create;override;
 end;

implementation

{ cCities }

constructor cCities.create;
begin
  inherited create;
  setRowClass(cCity);

  setSchema('public');
  setTableName('cities');
  setSelectCommand('select * from public.cities');

  addField('id'          , '���'          , true);
  addField('region_id'   , '��� �������'  , false);
  addField('country_id'  , '��� ������'   , false);
  addField('title'       , '���'          , false);
  addField('test_date'   , '����'         , true);
  addField('test_curr'   , '������'       , false);
  addField('test_bool'   , '����������'   , false);
end;

end.
