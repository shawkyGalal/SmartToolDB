-- Set server output on to enable DBMS_OUTPUT
SET SERVEROUTPUT ON
-- Set up error handling to continue on error
WHENEVER SQLERROR CONTINUE

Declare 
v_dbName VARCHAR2(30);
v_userName VARCHAR2(30);
v_data_tableSpace_name VARCHAR2(30);
v_temp_tableSpace_name VARCHAR2(30);
v_commnd VARCHAR2(1000); 

Begin 
v_dbName := UPPER('&1');
v_userName := UPPER('&2');
v_data_tableSpace_name := v_userName || '_DATA' ; 
v_temp_tableSpace_name := v_userName || '_TEMP' ;

EXECUTE IMMEDIATE ' ALTER SESSION SET CONTAINER = ' ||  v_dbName ;
begin 
  EXECUTE IMMEDIATE ' DROP TABLESPACE ' || v_data_tableSpace_name || ' INCLUDING CONTENTS AND DATAFILES' ;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM); 
END;
-- v_commnd := 'CREATE TABLESPACE ' || v_data_tableSpace_name || ' DATAFILE /opt/oracle/oradata/FREE/SVDB/' || v_data_tableSpace_name ||'.dbf SIZE 512M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED LOGGING ONLINE PERMANENT EXTENT MANAGEMENT LOCAL AUTOALLOCATE BLOCKSIZE 8K SEGMENT SPACE MANAGEMENT AUTO FLASHBACK ON' ;  
v_commnd := 'CREATE TABLESPACE ' || v_data_tableSpace_name || 
              ' DATAFILE ''/opt/oracle/oradata/FREE/'||v_dbName||'/' || v_data_tableSpace_name || '.dbf'' ' ||
              ' SIZE 512M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED ' ||
              ' LOGGING ONLINE PERMANENT EXTENT MANAGEMENT LOCAL AUTOALLOCATE ' ||
              ' BLOCKSIZE 8K SEGMENT SPACE MANAGEMENT AUTO FLASHBACK ON';
-- DBMS_OUTPUT.PUT_LINE ('Command To be execued Immediatly  ' || v_commnd ) ;
EXECUTE IMMEDIATE  v_commnd ; 

begin
  EXECUTE IMMEDIATE ' DROP TABLESPACE ' || v_temp_tableSpace_name || ' INCLUDING CONTENTS AND DATAFILES ' ;
 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM); 
END;

v_commnd :=  ' CREATE TEMPORARY TABLESPACE '||v_temp_tableSpace_name||
                ' TEMPFILE ''/opt/oracle/oradata/FREE/'||v_dbName||'/' || v_temp_tableSpace_name || '.dbf'' ' || 
                ' SIZE 128M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED TABLESPACE GROUP '''' EXTENT MANAGEMENT LOCAL UNIFORM SIZE 1M ' ;
EXECUTE IMMEDIATE v_commnd ; 


begin
  EXECUTE IMMEDIATE ' DROP USER '|| v_userName ||' CASCADE ' ;
 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM); 
END;

EXECUTE IMMEDIATE ' CREATE USER '||v_userName ||'  IDENTIFIED BY 123  DEFAULT TABLESPACE '||v_data_tableSpace_name || '  TEMPORARY TABLESPACE '||v_temp_tableSpace_name||'  PROFILE DEFAULT  ACCOUNT UNLOCK ' ;
  -- 3 Roles  
EXECUTE IMMEDIATE ' GRANT CONNECT TO '||v_userName||' WITH ADMIN OPTION ' ;
EXECUTE IMMEDIATE '  GRANT RESOURCE TO '||v_userName||' WITH ADMIN OPTION ' ;
EXECUTE IMMEDIATE '  GRANT DBA TO '||v_userName||' WITH ADMIN OPTION ' ;
EXECUTE IMMEDIATE '  ALTER USER '||v_userName||' DEFAULT ROLE ALL ' ;
  -- 2 System Privileges  
EXECUTE IMMEDIATE '  GRANT ALTER TABLESPACE TO '||v_userName||' WITH ADMIN OPTION' ;
EXECUTE IMMEDIATE '  GRANT UNLIMITED TABLESPACE TO '||v_userName||' WITH ADMIN OPTION ' ;
end; 
/
