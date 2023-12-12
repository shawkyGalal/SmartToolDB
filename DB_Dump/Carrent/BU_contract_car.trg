CREATE OR REPLACE TRIGGER BU_contract_car
   BEFORE Update
   ON Contract_Car
   FOR EACH ROW
declare 

v_counter number :=0 ;
BEGIN


-- return km should be more than fmkm 
  if ( :new.returnkmreading  < :new.fmkmreading) then 
       raise_application_error( -20000 , '���� ������ ���� �� ���� ���� �� ���� ������') ;
  end if ; 


  if (:old.status = '1' and :new.status = '0' and user <> 'CARRENT') then 
       raise_application_error( -20000 , '��� ���� �� ������ ��� ��� �����') ;
  end if ; 
  
  if ( :old.status = '1' and :new.status = '1') then
     raise_application_error( -20000 , '�����/ ��� ����� = ' || :old.branch_id || '/'|| :old.serialno || ' ����� ��� ����� ���� ..�� ���� ������� ��� ��� ����� ����') ;
  end if ; 

  --- �� ���� ������� 
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
           raise_application_error( -20000 , '�� ����� ������� ���� �����.. �� ���� ������� ��� ����� ���������') ;
      end if; 

  -- �� ����   ���� ������� ---
  if ( :new.car <> :old.car) then 

     if (:old.RETURNKMREADING > 0 ) then 
      raise_application_error( -20000 , '�� ���� ���� ������� ��� ����� ������') ;
     end if; 

     select count(*) into v_counter from carrent.cars_available_for_rent t where  t.car_code = :new.car ;
     if ( v_counter = 0 ) then 
      raise_application_error( -20000 , '������� ������� ��� ����� ����� �������') ;
      end if; 
  end if ; 

--- �� ���� ���� ���� ����� 
  if ( :new.discount <> :old.discount) then 
     if ( :new.discount > (5 * :new.carincome /100 ) )  then 
           raise_application_error( -20000 , '���� ������ ����� 5% �� ������ ���� ����� ') ;
     end if ; 

  end if ; 
  
  -- in case of changing car return date 
  if ( :new.RETURNDATE <> :old.RETURNDATE and :new.RETURNDATE < sysdate )  then 
    raise_application_error( -20000 , '�� ���� ����� ���� ������� ������ ���� ') ;
  end if ; 
  if (:new.RETURNDATE < :new.FMDATE ) then 
    raise_application_error( -20000 , '����� ������ �� �� �� ���� ��� ����� ������ ') ;
  end if; 
  

END;
/
