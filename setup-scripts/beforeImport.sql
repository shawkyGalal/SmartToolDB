-- This Script Should Be called before importing the db dump file and after creading icdb user 
GRANT SELECT ON sys.user$ TO ICDB;
Grant Execute on  sys.DBMS_CRYPTO TO ICDB ; 