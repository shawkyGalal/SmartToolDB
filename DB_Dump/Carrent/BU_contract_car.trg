CREATE OR REPLACE TRIGGER BU_contract_car
   BEFORE Update
   ON Contract_Car
   FOR EACH ROW
declare 

v_counter number :=0 ;
BEGIN


-- return km should be more than fmkm 
  if ( :new.returnkmreading  < :new.fmkmreading) then 
       raise_application_error( -20000 , 'ÚÏÇÏ ÇáÚæÏÉ áÇÈÏ Çä íßæä ÇßÈÑ ãä ÚÏÇÏ ÇáÎÑæÌ') ;
  end if ; 


  if (:old.status = '1' and :new.status = '0' and user <> 'CARRENT') then 
       raise_application_error( -20000 , 'ÛíÑ ãÕÑÍ áß ÈÅÚÇÏÉ İÊÍ åĞÇ ÇáÚŞÏ') ;
  end if ; 
  
  if ( :old.status = '1' and :new.status = '1') then
     raise_application_error( -20000 , 'ÇáİÑÚ/ ÑŞã ÇáÚŞÏ = ' || :old.branch_id || '/'|| :old.serialno || ' áÚİæÇ åĞÇ ÇáÚŞÏ ãÛáŞ ..áÇ íãßä ÇáÊÚÏíá İíå ŞÈá ÅÚÇÏÉ İÊÍÉ') ;
  end if ; 

  --- åá íæÌÏ ãÏíæäíÉ 
      select count(*) into v_counter from carrent.payment p 
      where p.company_id =:new.company_id
      and p.branch_id = :new.branch_id 
      and p.serialno = :new.serialno 
      and p.drcr  =0 ; 
      
      if (v_counter > 0  
         and (   :new.dayrate <> :old.dayrate 
              or :new.kmperday <> :old.kmperday 
              or :new.fmdate <> :old.fmdate
              or :new.returndate <> :old.returndate 
              or :new.fmkmreading <> :old.fmkmreading
              or :new.returnKmreading <> :old.returnKmreading
              or :new.discount   <> :old.discount
              or :new.damgevalue <> :old.damgevalue 
              or :new.overkmrate <> :old.overkmrate
              or :new.hoursvalue  <> :old.hoursvalue       
              ) 
          ) then
           raise_application_error( -20000 , 'Êã ÊÓÌíá ãÏíæäíÉ ÈåĞÇ ÇáÚŞÏ.. áÇ íãßä ÇáÊÚÏíá ŞÈá ÇáÛÇÁ ÇáãÏíæäíÉ') ;
      end if; 

  -- İì ÍÇáÉ   ÊÛíÑ ÇáÓíÇÑÉ ---
  if ( :new.car <> :old.car) then 

     if (:old.RETURNKMREADING > 0 ) then 
      raise_application_error( -20000 , 'áÇ íãßä ÊÛíÑ ÇáÓíÇÑÉ ÈÚÏ ÊÓÌíá ÇáÚæÏÉ') ;
     end if; 

     select count(*) into v_counter from carrent.cars_available_for_rent t where  t.car_code = :new.car ;
     if ( v_counter = 0 ) then 
      raise_application_error( -20000 , 'ÚİæÇåĞå ÇáÓíÇÑÉ ÛíÑ ãÊÇÍÉ ÍÇáíÇ ááÊÃÌíÑ') ;
      end if; 
  end if ; 

--- İì ÍÇáÉ ÊÛíÑ ŞíãÉ ÇáÎÕã 
  if ( :new.discount <> :old.discount) then 
     if ( :new.discount > (5 * :new.carincome /100 ) )  then 
           raise_application_error( -20000 , 'ÇáÍÏ ÇáÇŞÕì ááÎÕã 5% ãä ÅÌãÇáì ŞíãÉ ÇáÚŞÏ ') ;
     end if ; 

  end if ; 
  
  -- in case of changing car return date 
  if ( :new.RETURNDATE <> :old.RETURNDATE and :new.RETURNDATE < sysdate )  then 
    raise_application_error( -20000 , 'áÇ íãßä ÊÓÌíá ÚæÏÉ ÇáÓíÇÑÉ ÈÊÇÑíÎ ÓÇÈŞ ') ;
  end if ; 
  if (:new.RETURNDATE < :new.FMDATE ) then 
    raise_application_error( -20000 , 'ÊÇÑíÎ ÇáÚæÏÉ áÇ ÈÏ Çä íßæä ÈÚÏ ÊÇÑíÎ ÇáÎÑæÌ ') ;
  end if; 
  

END;
/
