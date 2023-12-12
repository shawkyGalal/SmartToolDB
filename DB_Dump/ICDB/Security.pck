create or replace package Security is

  -- Author  : SFODA
  -- Created : 16/12/2013 17:04:17
  -- Purpose : Implements the Security Feature of the Smart Tool
  
    function is_User_Can_Update(m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 ; 
    function is_User_Can_Read  (m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 ; 
    function is_User_Can_execute(m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 ;
    function is_User_Can_Delete(m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 ; 
    function is_User_Can_Create(m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 ;

end Security;
/
create or replace package body Security is

  -- Very Important Rule : Roles with "Denay by default"  override roles with "Allow By Default"
 function is_User_Can_Update(m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 is
    v_result varchar2(1) := 'N';
    v_counter number ; 
  begin 
 
     -- Check if user has any role with "Allow by default" 
     select count(*) into v_counter 
     from icdb.sec_users_objects_updatabilty uou 
     where uou.user_name = m_user_Name
     and uou.Allow_update_by_Default = 'Y';

     if ( v_counter > 0  ) then  
        v_result :='Y' ; 
     end if  ; 

     -- check if the object is execluded  from the above role 
     select count(*) into v_counter 
     from icdb.sec_users_objects_updatabilty uou 
     where uou.user_name = m_user_Name
     and uou.Allow_update_by_Default = 'Y'
     and upper(uou.execption_object_type) = upper(m_object_type)
     and upper(uou.exception_object) = upper(m_object_unique_Id) ;

     if ( v_counter > 0  ) then  -- means that the object is execluded from the default allowance 
        v_result :='N' ; 
     end if  ; 

   --===============================================================================  
     -- check if User has any role with "Denay by Default"
 
     select count(*) into v_counter 
     from icdb.sec_users_objects_updatabilty uou 
     where uou.user_name = m_user_Name
     and uou.Allow_update_by_Default = 'N';

     if ( v_counter > 0 ) then 
          v_result :='N' ; 
     end if ; 

     -- check if the object is execluded  from the above role 
    select count(*) into v_counter 
    from icdb.sec_users_objects_updatabilty uou 
     where uou.user_name = m_user_Name
     and upper(uou.execption_object_type) = upper(m_object_type)
      and upper(uou.exception_object) =  upper(m_object_unique_Id) 
     and uou.Allow_update_by_Default = 'N';

     if ( v_counter > 0 ) then -- means that the object is execluded from the default denaial 
          v_result :='Y' ; 
     end if ; 
 
    return v_result;
  end;
--==============================================================================================
 function is_User_Can_Read(m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 is
    v_result varchar2(1) := 'N';
    v_counter number ; 
  begin 
 
     -- Check if user has any role with "Allow by default" 
     select count(*) into v_counter 
     from icdb.sec_users_objects_readabilty uo 
     where uo.user_name = m_user_Name
     and uo.Allow_Read_by_Default = 'Y';

     if ( v_counter > 0  ) then  
        v_result :='Y' ; 
     end if  ; 

     -- check if the object is execluded  from the above role 
     select count(*) into v_counter 
     from icdb.sec_users_objects_readabilty uo 
     where uo.user_name = m_user_Name
     and upper(uo.execption_object_type) = upper(m_object_type)
     and upper(uo.exception_object) = upper(m_object_unique_Id) 
     and uo.Allow_read_by_Default = 'Y';

     if ( v_counter > 0  ) then  -- means that the object is execluded from the default allowance 
        v_result :='N' ; 
     end if  ; 

   --===============================================================================  
     -- check if User has any role with "Denay by Default"
 
     select count(*) into v_counter 
     from icdb.sec_users_objects_readabilty uou 
     where uou.user_name = m_user_Name
     and uou.Allow_read_by_Default = 'N';

     if ( v_counter > 0 ) then 
          v_result :='N' ; 
     end if ; 

     -- check if the object is execluded  from the above role 
    select count(*) into v_counter 
    from icdb.sec_users_objects_readabilty uou 
     where uou.user_name = m_user_Name
     and upper(uou.execption_object_type) = upper(m_object_type)
      and upper(uou.exception_object) =  upper(m_object_unique_Id) 
     and uou.Allow_read_by_Default = 'N';

     if ( v_counter > 0 ) then -- means that the object is execluded from the default denaial 
          v_result :='Y' ; 
     end if ; 
 
    return v_result;
  end;

--==============================================================================================
 function is_User_Can_execute(m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 is
    v_result varchar2(1) := 'N';
    v_counter number ; 
  begin 
 
     -- Check if user has any role with "Allow by default" 
     select count(*) into v_counter 
     from icdb.sec_users_objects_executabilty uo 
     where uo.user_name = m_user_Name
     and uo.Allow_exec_by_Default = 'Y';

     if ( v_counter > 0  ) then  
        v_result :='Y' ; 
     end if  ; 

     -- check if the object is execluded  from the above role 
     select count(*) into v_counter 
     from icdb.sec_users_objects_executabilty uo 
     where uo.user_name = m_user_Name
     and upper(uo.execption_object_type) = upper(m_object_type)
     and upper(uo.exception_object) = upper(m_object_unique_Id) 
     and uo.Allow_exec_by_Default = 'Y';

     if ( v_counter > 0  ) then  -- means that the object is execluded from the default allowance 
        v_result :='N' ; 
     end if  ; 

   --===============================================================================  
     -- check if User has any role with "Denay by Default"
 
     select count(*) into v_counter 
     from icdb.sec_users_objects_executabilty uou 
     where uou.user_name = m_user_Name
     and uou.Allow_exec_by_Default = 'N';

     if ( v_counter > 0 ) then 
          v_result :='N' ; 
     end if ; 

     -- check if the object is execluded  from the above role 
    select count(*) into v_counter 
    from icdb.sec_users_objects_executabilty uou 
     where uou.user_name = m_user_Name
     and upper(uou.execption_object_type) = upper(m_object_type)
      and upper(uou.exception_object) =  upper(m_object_unique_Id) 
     and uou.Allow_exec_by_Default = 'N';

     if ( v_counter > 0 ) then -- means that the object is execluded from the default denaial 
          v_result :='Y' ; 
     end if ; 
 
    return v_result;
  end;
--========================================================================================

 function is_User_Can_Delete(m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 is
    v_result varchar2(1) := 'N';
    v_counter number ; 
  begin 
 
     -- Check if user has any role with "Allow by default" 
     select count(*) into v_counter 
     from icdb.sec_users_objects_deletabilty uo 
     where uo.user_name = m_user_Name
     and uo.Allow_delete_by_Default = 'Y';

     if ( v_counter > 0  ) then  
        v_result :='Y' ; 
     end if  ; 

     -- check if the object is execluded  from the above role 
     select count(*) into v_counter 
     from icdb.sec_users_objects_deletabilty uo 
     where uo.user_name = m_user_Name
     and upper(uo.execption_object_type) = upper(m_object_type)
     and upper(uo.exception_object) = upper(m_object_unique_Id) 
     and uo.Allow_delete_by_Default = 'Y';

     if ( v_counter > 0  ) then  -- means that the object is execluded from the default allowance 
        v_result :='N' ; 
     end if  ; 

   --===============================================================================  
     -- check if User has any role with "Denay by Default"
 
     select count(*) into v_counter 
     from icdb.sec_users_objects_deletabilty uou 
     where uou.user_name = m_user_Name
     and uou.Allow_delete_by_Default = 'N';

     if ( v_counter > 0 ) then 
          v_result :='N' ; 
     end if ; 

     -- check if the object is execluded  from the above role 
    select count(*) into v_counter 
    from icdb.sec_users_objects_deletabilty uou 
     where uou.user_name = m_user_Name
     and upper(uou.execption_object_type) = upper(m_object_type)
      and upper(uou.exception_object) =  upper(m_object_unique_Id) 
     and uou.Allow_delete_by_Default = 'N';

     if ( v_counter > 0 ) then -- means that the object is execluded from the default denaial 
          v_result :='Y' ; 
     end if ; 
 
    return v_result;
  end;
--============================================================
 function is_User_Can_Create(m_user_Name varchar2 , m_object_type varchar2 , m_object_unique_Id varchar2  ) return varchar2 is
    v_result varchar2(1) := 'N';
    v_counter number ; 
  begin 
 
     -- Check if user has any role with "Allow by default" 
     select count(*) into v_counter 
     from icdb.sec_users_objects_creatabilty uo 
     where uo.user_name = m_user_Name
     and uo.Allow_create_by_Default = 'Y';

     if ( v_counter > 0  ) then  
        v_result :='Y' ; 
     end if  ; 

     -- check if the object is execluded  from the above role 
     select count(*) into v_counter 
     from icdb.sec_users_objects_creatabilty uo 
     where uo.user_name = m_user_Name
     and upper(uo.execption_object_type) = upper(m_object_type)
     and upper(uo.exception_object) = upper(m_object_unique_Id) 
     and uo.Allow_create_by_Default = 'Y';

     if ( v_counter > 0  ) then  -- means that the object is execluded from the default allowance 
        v_result :='N' ; 
     end if  ; 

   --===============================================================================  
     -- check if User has any role with "Denay by Default"
 
     select count(*) into v_counter 
     from icdb.sec_users_objects_creatabilty uou 
     where uou.user_name = m_user_Name
     and uou.Allow_create_by_Default = 'N';

     if ( v_counter > 0 ) then 
          v_result :='N' ; 
     end if ; 

     -- check if the object is execluded  from the above role 
    select count(*) into v_counter 
    from icdb.sec_users_objects_creatabilty uou 
     where uou.user_name = m_user_Name
     and upper(uou.execption_object_type) = upper(m_object_type)
      and upper(uou.exception_object) =  upper(m_object_unique_Id) 
     and uou.Allow_create_by_Default = 'N';

     if ( v_counter > 0 ) then -- means that the object is execluded from the default denaial 
          v_result :='Y' ; 
     end if ; 
 
    return v_result;
  end;



end Security;
/
