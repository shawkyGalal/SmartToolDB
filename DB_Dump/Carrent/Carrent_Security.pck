create or replace package carrent.Security is
       procedure test ;
       function is_user_can_add_debit return varchar ;
       procedure create_Carrent_user (  user_name varchar2 ) ;
       procedure Drop_Carrent_user (  user_name varchar2 ) ;
       procedure create_user_By_Rowid (  m_rowId varchar2 ) ;
       function get_User_Branch return number ;
       function get_User_Company return number ;
end;
/
create or replace package body carrent.Security is

---------------------------------------------------------------------

procedure test is
begin
 insert into carrent.payment (branch_id ,  company_id , serialno , drcr , amount)
 values (1, 1 , 123 , 0 , 0 ) ;
end;
-------------
function is_user_can_add_debit return varchar is
v_can_add_debit varchar(1) ;
begin
  select nvl(u.can_add_debit, 'N')  into v_can_add_debit from carrent.users u where upper(u.user_name) = user ;
  return v_can_add_debit ;
end ;

------------

procedure drop_carrent_user (  user_name varchar2 ) is
sql_stmt varchar2(1000)  ;
BEGIN

     sql_stmt :=  ' drop user '||user_name || ' cascade ' ;

    begin

          execute immediate  sql_stmt ;

      exception
        when others then
        null ;
      end;

end ;

procedure create_user_By_Rowid (  m_rowId varchar2 ) is
v_user_name varchar2 (50) ;

begin
 select user_name into v_user_name from carrent.users u where u.rowid = m_rowId ;
 create_Carrent_user (v_user_name) ;

end ;
--------
procedure create_Carrent_user (  user_name varchar2 ) is
 sql_stmt varchar2(1000)  ;
 begin

   drop_carrent_user ( user_name) ;

           sql_stmt :=  ' Create user '||user_name
                        ||'  identified by 123 '
                        ||'  default tablespace CARRENT_DATA '
                        ||'  temporary tablespace CARRENT_TMP ' ;


          execute immediate sql_stmt ;

           sql_stmt :=  ' Grant carrent_user_role to '||user_name   ;

          execute immediate sql_stmt ;


end ;

 function get_User_Branch return number is
   v_result number ;
   begin
       select branch_id  into v_result from carrent.users u where upper (u.user_name) = user  ;
       return v_result ;
   end ;
  function get_User_Company return number  is
   v_result number ;
   begin
       select company_id  into v_result from carrent.users u where upper (u.user_name) = user  ;
       return v_result ;
   end ;


end Security;
/
