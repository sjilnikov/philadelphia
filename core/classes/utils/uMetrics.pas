unit uMetrics;

interface
uses
  windows,
  sysUtils,
  classes,
  clsLists;

const
  UNIXSTARTDATE : tDateTime = 25569.0;
  TENTHOFSEC     = 100;
  SECOND         = 1000;
  MINUTE         = 60000;
  HOUR           = 3600000;
  DAY            = 86400000;
  SECONDSPERDAY  = 86400;

  BITS_IN_BYTE    = 8;
  GIGABYTE        = 1073741824;
  MEGABYTE        = 1048576;
  KBYTE           = 1024;

  STR_KB          = '��';
  STR_MB          = '��';
  STR_GB          = '��';
  STR_BYTES       = '����';
  STR_KB_SEC      = STR_KB + '/���';


implementation


end.

