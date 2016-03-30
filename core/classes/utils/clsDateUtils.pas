{
Description:
related to datetime, used by many units to visually display formatted time eg: 00:00:00
}

//checked
unit clsDateUtils;

interface

uses
 sysUtils,
 windows;


type
  cDateUtils = class
  public
  const
    MIN_UNIX_TIME : tDateTime = (25569.125);
  public
  end;

implementation




end.
