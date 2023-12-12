create or replace package Contract_Services is
       procedure  close_contract(m_company_id number ,  m_branch_id number , m_year number , m_serialNo number   ); 
       procedure  register_Customer_debit (m_company_id number , m_branch_id number , m_year number , m_serialNo number   ) ;
       procedure  register_Car_return (m_company_id number , m_branch_id number ,  m_serialNo number , m_returmKM number , return_date date   ) ;
       procedure recalculate_Contract_Fees (  contractCarRowId varchar2 ); 
       function get_car_last_retrnkm(m_car varchar2 )  return number; 
       function get_total_payments ( m_company_id number,  m_branch_id number, m_year number , m_serialNo number ) return number ; 
       function get_total_act_payments ( m_company_id number,  m_branch_id number, m_year number , m_serialNo number ) return number ;
       procedure  reOpen_contract(m_company_id number ,  m_branch_id number , m_year number , m_serialNo number   ) ; 
       procedure  collect_contract_debit(m_company_id  number ,  m_branch_id number , m_serialno number , m_amount number ) ;  
       procedure settle_contract(m_company_id  number ,  m_branch_id number , m_year number , m_serialno number ) ; 
       procedure test ; 
end;
/
create or replace package body Contract_Services is

---------------------------------------------------------------------
  procedure  close_contract(m_company_id number ,  m_branch_id number , m_year number , m_serialNo number   ) is
  total_payaments number ;
  contract_value number ;
  begin
    total_payaments := Contract_Services.get_total_payments ( m_company_id ,  m_branch_id , m_year  , m_serialNo  ) ; 
  
    select c.carincome into contract_value from carrent.contract_car c 
    where c.company_id = m_company_id
    and c.branch_id = m_branch_id
    and c.year = m_year
    and c.serialno = m_serialNo ; 
    
    if ( contract_value  > total_payaments ) then
       Raise_application_error(-20000, 'ﬁÌ„… «·„ Õ’· '||to_char(total_payaments)||' «ﬁ· „‰ ﬁÌ„… «·⁄ﬁœ '||to_char(contract_value)||' . »—Ã«¡  Õ’Ì· «·›—ﬁ '||to_char(contract_value  - total_payaments ) ||' „‰ «·⁄„Ì·  «Ê  ”ÃÌ· «·›«—ﬁ ﬂ„œÌÊ‰Ì… ⁄·Ï «·⁄„Ì·');
   
    end if ;
     
    if (contract_value  < total_payaments ) then 
     Raise_application_error(-20000, '»—Ã«¡ —œ „»·€ ' || to_char ( total_payaments - contract_value )  ||' «·Ï «·⁄„Ì·  ' );
    
    else
        update carrent.contract c 
          set c.status = 1  , c.closedate = sysdate
        where c.company_id = m_company_id
        and c.branch_id = m_branch_id
        and c.year = m_year
        and c.serialno = m_serialNo ; 

    end if ;
  
  end;
----------------------------
procedure  reOpen_contract(m_company_id number ,  m_branch_id number , m_year number , m_serialNo number   ) is

  begin

        update carrent.contract c 
          set c.status = 0  , c.closedate = null
        where c.company_id = m_company_id
        and c.branch_id = m_branch_id
        and c.year = m_year
        and c.serialno = m_serialNo ; 
  
  end;
  
  
-------------------------------------------------------------------------------------------------
  function get_total_act_payments ( m_company_id number,  m_branch_id number, m_year number , m_serialNo number ) return number is 
  v_result  number  := 0 ;
  
  begin

    select nvl(  sum (p.amount *  p.drcr ) , 0)  into v_result from carrent.payment p 
    where p.company_id = m_company_id
    and p.branch_id = m_branch_id
    and p.year = m_year
    and p.serialno = m_serialNo
    and p.drcr in ( 1, -1 ) ;
  
    return v_result ;
  end ;


  -------------------------------------------------------------------
  function get_total_payments ( m_company_id number,  m_branch_id number, m_year number , m_serialNo number ) return number is 
  v_result  number  := 0 ;
  
  begin

    select nvl(  sum (p.amount * decode ( p.drcr , 0 , 1 ,p.drcr ) ) , 0)  into v_result from carrent.payment p 
    where p.company_id = m_company_id
    and p.branch_id = m_branch_id
    and p.year = m_year
    and p.serialno = m_serialNo
    and p.drcr in ( 1, -1 , 0 ) ;
  
    return v_result ;
  end ;
  ---------------------------------------------------------------------
  procedure  register_Customer_debit (m_company_id number ,  m_branch_id number , m_year number , m_serialNo number   ) is

  total_payaments number ;
  contract_value number ;
  begin

    delete from carrent.payment p 
    where p.company_id = m_company_id 
      and p.branch_id = m_branch_id
      and p.serialno = m_serialNo
      and p.year = m_year 
      and p.drcr = 0;
  
    total_payaments := Contract_Services.get_total_act_payments ( m_company_id ,  m_branch_id , m_year  , m_serialNo  ) ; 
  
    select c.carincome into contract_value from carrent.contract_car c 
    where c.company_id = m_company_id
    and c.branch_id = m_branch_id
    and c.year = m_year
    and c.serialno = m_serialNo ; 

    if ( contract_value > total_payaments ) then 
      insert into carrent.payment ( company_id ,  branch_id , year , serialno ,date_ , amount , drcr ) 
      values (m_company_id ,  m_branch_id , m_year  , m_serialNo  , sysdate , contract_value - total_payaments , 0 ) ; 
      
      
      ----------Mark Customer as Susbected -----
      update carrent.customer cu set cu.suspected = 'Y' 
         where cu.idno = ( Select idno from carrent.contract c 
                            where c.company_id = m_company_id 
                            and c.branch_id = m_branch_id
                            and c.serialno = m_serialNo
                            and c.year = m_year) ; 
    end if; 
  end;
  ----------------------------------------------------------------------------------------------------------------
  function get_car_last_retrnkm(m_car varchar2 )  return number is 
  v_result number := 0 ;
  begin
  
    select max(cc.returnkmreading) into v_result 
     from carrent.contract_car cc 
     where cc.car = m_car ;
    return v_result;
  
  end ;
 
 
---------------------------------
  procedure recalculate_Contract_Fees (  contractCarRowId varchar2 ) is
    contract_car_rec carrent.contract_car%rowtype ;
  begin
         Select * into contract_car_rec from carrent.contract_car cc where cc.rowid = contractCarRowId ;
         register_Car_return ( contract_car_rec.company_id , contract_car_rec.branch_id , contract_car_rec.serialNo , contract_car_rec.returnkmreading , contract_car_rec.returndate ) ; 
  end ; 
------------------------------------------------------------------
  
  procedure  register_Car_return (m_company_id number , m_branch_id number ,  m_serialNo number , m_returmKM number , return_date date   ) is

  contract_car_rec carrent.contract_car%rowtype ;
  noOfDays number ; 
  extraHours number := 0 ;
  extraHoursValue number :=0 ; 
  extraKm number :=0 ;
  extraKmValue number :=0 ; 
  total_act_payment number ; 
  
  
  begin

       Select * into contract_car_rec from carrent.contract_car cc
       where cc.branch_id = m_branch_id 
       and cc.company_id = m_company_id 
       and cc.year = to_char(cc.fmdate , 'YYYY')
       and cc.serialno = m_serialNo ;
  
       noOfDays :=  trunc(return_date, 'dd')  - trunc( contract_car_rec.fmdate , 'dd') ;
       
       if ( extraHours  <  0 ) then 
               extraHours :=  0;
       end if;
       --- Extra Hours calc --
       extraHours :=  ( return_date - contract_car_rec.fmdate - noOfDays  ) * 24 ;
       
       if ( extraHours > 0 ) then 
       extraHoursValue := round(( extraHours  * contract_car_rec.hoursvalue) , 2) ; 
       end if; 
       
       if ( extraHoursValue  >  contract_car_rec.dayrate ) then 
               extraHoursValue := contract_car_rec.dayrate ;
       end if; 
       
       -- Extra KM calculation        
       extraKm := ( nvl( m_returmKM , contract_car_rec.fmkmreading )  - contract_car_rec.fmkmreading ) -  noOfDays * contract_car_rec.kmperday ;
       if ( extraKm < 0 ) then 
            extraKm := 0 ; 
       end if ;
       extraKmValue   :=  round(extraKm * contract_car_rec.overkmrate/100 , 2) ; 
       
       update carrent.contract_car cc
       set cc.returndate = return_date
          , cc.interval = noOfDays 
          , cc.returnkmreading = m_returmKM
          , cc.contract_days_value = noOfDays * cc.dayrate 
          , cc.contract_extrahours_value = extraHoursValue  -- round(extraHours * cc.hoursvalue  , 2)
          , cc.contract_extrakm_value = extraKmValue
          , cc.carincome = noOfDays * cc.dayrate   -- ﬁÌ„… «·«Ì«„ 
                         + extraHoursValue -- ﬁÌ„… «·”«⁄«  «·«÷«›Ì…
                         + extraKmValue   --  ﬁÌ„… «·ﬂ„ «·“«∆œ
                         + nvl( cc.damgevalue , 0)  -- ﬁÌ„… «· ·›Ì« 
                         + nvl( cc.penality , 0) 
                         - nvl( cc.discount , 0 )  -- ﬁÌ„… «·Œ’„
       where cc.branch_id = m_branch_id 
       and cc.company_id = m_company_id 
       and cc.serialno = m_serialNo ;

       --- Update Contract debit value (if Exist)

      Select *  into contract_car_rec from carrent.contract_car cc
       where cc.branch_id = m_branch_id 
       and cc.company_id = m_company_id 
       and cc.year = to_char(cc.fmdate , 'YYYY')
       and cc.serialno = m_serialNo ;

       total_act_payment := carrent.contract_services.get_total_act_payments (m_company_id  ,  m_branch_id  ,  contract_car_rec.year , m_serialNo )  ;

       update carrent.payment p
       set p.amount = contract_car_rec.carincome - total_act_payment
       where p.branch_id = m_branch_id 
       and p.company_id = m_company_id 
       and p.serialno = m_serialNo 
       and p.drcr = 0 ;


 end;
---------------------------------------------------------------
 procedure collect_contract_debit(m_company_id  number ,  m_branch_id number , m_serialno number , m_amount number ) is 
  begin 
   insert into carrent.payment ( company_id , branch_id , serialno , amount , drcr , date_  , notes)
   values ( m_company_id , m_branch_id , m_serialno  , m_amount ,  1 , sysdate , ' Õ’Ì· „œÌÊ‰Ì… „‰ «·⁄„Ì·' ) ;
   
   update carrent.payment p 
    set p.amount =  p.amount - m_amount
    where p.drcr = 0 
    and p.branch_id = m_branch_id
    and p.serialno = m_serialno
    and p.company_id = m_company_id ; 
  end ;       

--------------------Automatically Collects the required amount for a contract ---------------
procedure settle_contract(m_company_id  number ,  m_branch_id number , m_year number , m_serialno number ) is 
 total_act_payments number ; 
 v_car_income number ; 
 v_payment_req number ; 
 v_drcr number ;
begin
 total_act_payments :=  carrent.contract_services.get_total_act_payments (m_company_id  , m_branch_id  , m_year , m_serialno ) ;

 select cc.carincome  into v_car_income 
 from carrent.contract_car cc 
 where cc.branch_id = m_branch_id
 and cc.company_id = m_company_id
 and cc.year = m_year
 and cc.serialno = m_serialno ;
 
 if (v_car_income > total_act_payments ) then 
   v_payment_req :=  v_car_income - total_act_payments ; 
   v_drcr := 1; 
   else 
   v_payment_req :=   total_act_payments - v_car_income ; 
   v_drcr := -1; 
 end if ;
 
  insert into carrent.payment (branch_id , year , serialno, company_id , amount , drcr , notes)
  values (m_branch_id , m_year , m_serialno , m_company_id , v_payment_req , v_drcr , ' ’›Ì… «·⁄ﬁœ  ·ﬁ«∆Ì«') ;
 
end ;

------------------------
procedure test is 
begin
 insert into carrent.payment (branch_id , year , company_id , serialno , drcr , amount) 
 values (1,2005 , 1 , 123 , 0 , 0 ) ;
end;

end Contract_Services;
/
