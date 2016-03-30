unit uSQLDrivers;

interface

const
  MSSQL_DRIVER_NOT_SUPPORTED = 'MSSQL driver not supported';
  MYSQL_DRIVER_NOT_SUPPORTED = 'MYSQL driver not supported';
  PGSQL_DRIVER_NOT_SUPPORTED = 'PGSQL driver not supported';
  SQLITE_DRIVER_NOT_SUPPORTED = 'SQLite driver not supported';
  MEMORY_DRIVER_NOT_SUPPORTED = 'Memory driver not supported';

type
  tSQLDriver = (drvMSSQL, drvMYSQL, drvPGSQL, drvSQLite, drvMemory);

implementation

end.
