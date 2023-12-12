CREATE OR REPLACE TRIGGER bi_city
   BEFORE INSERT 
   ON City
   FOR EACH ROW
declare v_user_company_id number ; 
BEGIN

v_user_company_id :=  carrent.security.get_User_Company();
 
if :new.company_id is null then 
  :new.company_id :=  v_user_company_id ;
end if; 


if :new.code is null then 
  select nvl ( max(c.code), 0 ) + 1 into :new.code
  from carrent.city c 
  where c.company_id = v_user_company_id ; 
end if; 
END;
/
