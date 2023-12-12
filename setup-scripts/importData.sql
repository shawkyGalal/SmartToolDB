ACCEPT dbName CHAR PROMPT 'Enter dbName';
ACCEPT contScriptPath CHAR PROMPT 'Enter contScriptPath';
ACCEPT dbPassword CHAR PROMPT 'Enter Password';

ALTER SESSION SET CONTAINER = &dbName;
imp log=&contScriptPath/plsimp.log file=&contScriptPath/DB_Dump/PNU_Dump/SmartTool20170610.dmp userid="sys/&dbPassword as sysdba" buffer=30720 commit=yes full=yes grants=yes ignore=yes indexes=yes rows=yes show=no constraints=yes