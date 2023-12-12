create or replace package data_migration is
procedure clean_Company_data( m_company_id number ) ; 

procedure migrate_carold_data(m_company_id number ) ;
procedure migrate_lookups (m_company_id number ) ; 
procedure migrate_cars( m_company_id number ) ; 
procedure migrate_customers( m_company_id number ) ; 
procedure migrate_all_contracts( m_company_id number ) ;
procedure migrate_contract( m_company_id number , m_branch_id number , m_serial number ) ; 
procedure clean_Company_contracts( m_company_id number ) ; 
procedure reload_Company_contracts(m_company_id number  ) ; 
function get_Gdate_from_HDate( m_hdate date) return date; 

end;
/
create or replace package body data_migration is

-- Converts date stored in Hijri to Grog
function get_Gdate_from_HDate( m_hdate date) return date is 
v_result date ;
begin
 select x.me_dt into v_result 
  from carold.cardhe02 x 
  where x.heg_dt =  to_char ( m_hdate , 'yyyy') || to_char ( m_hdate , 'mm') ||  to_char ( m_hdate , 'dd') ;
return v_result ;
end ;
-------This procedure will upload old system data in Carold Schema to our new system Carrent and assign it to company  -------------------
procedure migrate_carold_data(m_company_id number ) is 

begin
if (m_company_id = 1 ) then 
   raise_application_error (-20000 , 'Company No 1 is assined for testing you can not upload data to it' )   ;
end if ; 
 
 Savepoint start_migrate ;

begin
  -- 0 Clean Company Data 
    carrent.data_migration.clean_Company_data( m_company_id ) ; 
  -- 1 Migrate Lookups -----
   carrent.data_migration.migrate_lookups( m_company_id) ; 
  
  -- 2- Migrate Cars----
  
    carrent.data_migration.migrate_cars (m_company_id ) ; 
  
  ---4 - Migrate customer informations
   carrent.data_migration. migrate_customers ( m_company_id ) ; 
  ---5 - Migrate contract & payment information
  
  carrent.data_migration.migrate_all_contracts( m_company_id ) ;
  
exception
  when others then
    rollback to start_migrate ; 
    raise ; 
end;

end ; 
--===========================================================
procedure migrate_all_contracts( m_company_id number ) is 

begin
 
 for old_cont in ( select cont.cont_br , cont.cont_no 
                       from carold.CARDCN03 cont 
                       where cont.cont_no <> 0 
                       and (cont.cont_br , cont.cont_no  ) in ( select car.cont_br , car.cont_no from carold.cardcn02 car where trim(car.plate_no) in ( select trim(ca.plate_no) from carold.cardca01 ca ))  -- should have a valid car info 
                       and (cont.cont_br , cont.cont_no  ) in ( select car.cont_br , car.cont_no from carold.cardcn01 car )  -- should have customer info
                  ) 
 loop
 
      migrate_contract(m_company_id  , old_cont.cont_br , old_cont.cont_no ) ; 
  
 end loop ; 
 
end ; 

--===========================================================
procedure migrate_contract( m_company_id number , m_branch_id number , m_serial number ) is 

cont_info carold.CARDCN03%rowtype ; 
cont_car_info carold.CARDCN02%rowtype ; 
cont_cus_info carold.cardcn01%rowtype ;
v_fmdate date ; 
v_returndate date ;
v_drcr number ; 
v_contrat_Car_rowid rowid ; 

begin 

  -- Reading Cont info --------
  select * into cont_info from carold.cardcn03 c 
  where c.cont_br = m_branch_id
  and c.cont_no = m_serial
  and c.cont_no <> 0  ;  -- 0 is assigned to car movments ; 

  -- Reading Car info --------
  select * into cont_car_info from carold.cardcn02 c 
  where c.cont_br = m_branch_id
  and c.cont_no = m_serial
  and c.cont_no <> 0   -- 0 is assigned to car movments 
  and c.plate_no is not null 
  and trim(c.plate_no) in ( select trim(ca.plate_no) from carold.cardca01 ca ) ; 
  
  -- Reading Cust info --------
  select * into cont_cus_info from carold.cardcn01 cu 
  where cu.cont_br = m_branch_id
  and cu.cont_no = m_serial
  and rownum = 1; 

   
  insert into carrent.contract 
        (company_id  , branch_id  , serialno , idtype              , idno                      , idsource             , car                         , interval            , is_migrated ) 
  values(m_company_id, m_branch_id, m_serial , cont_cus_info.doc_ty, trim(cont_cus_info.doc_no), cont_cus_info.doc_plc, trim(cont_car_info.plate_no), cont_info.cont_nday , 'Y') ;
  
  v_fmdate := misc.to_datetime( cont_car_info.rent_dt , cont_car_info.rent_tim , cont_car_info.rent_tis )  ; 
  v_returndate := misc.to_datetime( cont_car_info.rent_dte , cont_car_info.rent_time , cont_car_info.rent_tise )  ; 
  
  if (v_returndate < v_fmdate ) then 
       v_returndate := null ; 
                    -- consider the contract as closed 
  end if ;  
 

  insert into carrent.contract_car 
         ( company_id  , branch_id  , serialno , car                          , fmdate  , dayrate              , kmperday             , overkmrate                 , fmkmreading          , returndate  , hoursvalue            , returnkmreading       , discount          , is_migrated ) 
  values ( m_company_id, m_branch_id, m_serial , trim(cont_car_info.plate_no) , v_fmdate, cont_car_info.day_val, cont_car_info.allw_km, cont_car_info.km_add * 100 , cont_car_info.rent_km, v_returndate, cont_car_info.hour_add, cont_car_info.rent_kme, cont_info.cont_dis , 'Y' ) ;


  ---Reading payment inf0 
  for old_pay in ( Select * from carold.CardRC01 p
                          where rc_br = m_branch_id
                          and rc_cont = m_serial
                         ) 
  loop 
  
       v_drcr := 1; 
       if ( old_pay.rc_typ in ( 3, 4 ) 
            or ( old_pay.rc_typ = 2 and old_pay.rc_typ1 = 3 )  ) then  
          v_drcr := -1 ; 
        end if; 
       insert into carrent.payment 
              (company_id    , branch_id   , serialno ,  date_        , amount         ,  drcr , notes         , pay_by         ,  is_migrated )
       values ( m_company_id , m_branch_id , m_serial ,  old_pay.rc_dt, old_pay.rc_amt , v_drcr, old_pay.rc_nt , old_pay.rc_ptyp ,  'Y' )  ;
  end loop ; 

--=======

  select rowid into v_contrat_Car_rowid from carrent.contract_car cc where cc.company_id = m_company_id and cc.branch_id = m_branch_id and cc.serialno = m_serial ;
  carrent.contract_services.recalculate_Contract_Fees( v_contrat_Car_rowid) ;      


  -- In case the car is returned  
  --ÅÚÊÈÇÑ ÇáÚÞÏ ãÛáÞ æ  ÊÓÌíá ÝÑÞ ÇáÚÞÏ ÅÐÇ æÌÏ ßãÏíæäíÉ 
  if ( v_returndate is not null and v_returndate > v_fmdate ) then 
      carrent.CONTRACT_SERVICES.REGISTER_CUSTOMER_DEBIT (m_company_id  ,  m_branch_id  ,  m_serial , v_returndate  , 'Y') ; 

      update carrent.contract_car cc 
      set cc.status = 1
      where cc.company_id = m_company_id
      and cc.branch_id = m_branch_id 
      and cc.serialno = m_serial ; 

  end if ; 
 


end ; 
--===========================================================
procedure clean_Company_contracts( m_company_id number ) is 
begin 
 -- Delete Contracts information ----------
 delete from payment p where p.company_id =  m_company_id and p.is_migrated = 'Y';
 delete from contract c where c.company_id = m_company_id and c.is_migrated = 'Y';
 delete from contract_car c where c.company_id = m_company_id and c.is_migrated = 'Y';


end ; 
--===========================================================
procedure clean_Company_data( m_company_id number ) is 

begin 

 clean_Company_contracts(m_company_id); 
 ------Delete cars information -----------
 delete from carrent.car_km_move ckm where ckm.car_code in ( select c.code from carrent.car c where c.company =  m_company_id ) ; 
 delete from carrent.car c where c.company = m_company_id ; 
 
 
 ---- Daelete Customers Info -------
 delete from carrent.customer cu where cu.company_id = m_company_id ; 
 

 --- Delete other Lookups ----------
 delete from carrent.nationality na where na.company_id = m_company_id ; 
 delete carrent.SYS_CODES sc where sc.company_id = m_company_id ;  
 delete from carrent.cartype ct where ct.company_id = m_company_id ; 
 delete from carrent.color ct where ct.company_id = m_company_id ; 
 delete from carrent.city c where c.company_id = m_company_id ; 
 delete from carrent.id_types t where t.company_id = m_company_id ; 
 delete from carrent.branch b where b.company_id =  m_company_id ; 
 
end ; 

--===========================================================
procedure migrate_customers( m_company_id number ) is 
begin

------ Getting Last Customer Contract Info---------
for customer_uk_record in (select distinct max(c2.upd_dt) upd_dt , c2.doc_no , c2.doc_ty , c2.doc_plc  from carold.cardcn01 c2 
                           group by  c2.doc_no  , c2.doc_ty , c2.doc_plc)
loop
   
   begin 
   
     insert into carrent.customer 
                  (company_id, branch_id, cust_no        , name            ,  nationality, idno          , idtype  , idsource , id_date                        , id_date_expire                 , licno   , licsource, lic_date                      , lic_date_expire                , address                     , tel2      , sponsoraddress             , sponsortel , sponsor   ) 
         select  m_company_id, c.cont_br, trim(c.cont_id), trim(c.cont_nam), c.cont_nat  , trim(c.doc_no), c.doc_ty, c.doc_plc, get_Gdate_from_HDate(c.doc_dt), get_Gdate_from_HDate(c.doc_edt), c.lic_no, c.lic_plc , get_Gdate_from_HDate(c.lic_dt), get_Gdate_from_HDate(c.lic_edt), c.cont_adr ||'-'|| c.hom_adr, c.cont_tel, c.cont_wor || c.kaf_adr    , c.hom_tel  , c.kaf_nam  from carold.cardcn01 c 
          where c.upd_dt =  customer_uk_record.upd_dt 
          and c.doc_no  =  customer_uk_record.doc_no 
          and c.doc_ty =  customer_uk_record.doc_ty
          and c.doc_plc = customer_uk_record.doc_plc 
          and rownum = 1           ; 
   Exception 
        when DUP_VAL_ON_INDEX then  begin null; end ;
        when others then begin    raise;  end ; 
   end ; 

end loop;

end ;
--===========================================================
procedure migrate_cars( m_company_id number ) is 

begin 
  insert into carrent.car 
                (code       , color        ,  cartype    , istemarafmdate , istemaratodate , chasihno    , notes                         , dayrate    , kmperday    , overkmrate , branch_id  , company      ,status , buyvalue , hoursvalue , year , MONTH_RATE  ) 
   select trim(ca.plate_no) , ca.color_car , ca.make_car , ca.lic_dat     , ca.lic_edat    , ca.chass_no ,  ca.note_car1 || ca.note_car2 , ca.day_val , ca.km_daily , ca.km_add * 100 , ca.lic_plc , m_company_id , 0     , ca.sol_amt , ca.hour_add , ca.model_year , ca.mon_val
    from carold.cardca01 ca ; 
    
   ------------Migrate Car Movments -------
    insert into carrent.car_km_move 
         (car_code , from_km , to_km    , tran_date                    , created_by , move_from , move_to )
       select  trim(plate_no) , rent_km , rent_kme , nvl(del_date , cont_date ) TRN_DATE, user_ , plac_bgn ,  plac_end 
          from ( 
           Select  cont.plate_no
             , rent_km 
             , rent_kme 
             , carrent.misc.to_datetime(
                 (Select del.del_date from carold.CARDDEL1  del where del.D_CONT_NO = cont.trn_num and trim(del.DEL_CAR)  = trim(cont.plate_no) ) 
                ,(Select del.del_tim from carold.CARDDEL1  del where del.D_CONT_NO = cont.trn_num and trim(del.DEL_CAR)  = trim(cont.plate_no) ) 
                ) del_date   
              , carrent.misc.to_datetime (  cont.rent_dt, cont.rent_tim , cont.rent_tis ) cont_date
             , (Select del.del_user from carold.CARDDEL1  del where del.D_CONT_NO = cont.trn_num and trim(del.DEL_CAR)  = trim(cont.plate_no) ) user_
             , cont.PLAC_BGN  
             , cont.PLAC_END 
           from carold.cardcn02 cont 
           where cont.cont_no = 0 
           ) 
    ; 
   -----------End of Migrate Car Movments -------
end ;

--===========================================================
procedure migrate_lookups (m_company_id number ) is 

begin 
-- 0-1 - Nationality 
insert into carrent.nationality (code ,  name  ,  namee ,  company_id ) 
  select t.minor_cod , t.ara_titel , t.des_titel , m_company_id 
  from carold.cardcod1 t   
   where t.major_cod = 1 ; 

-- 0-2 - Jobs 
insert into carrent.SYS_CODES (major_code , minor_code , a_desc , e_desc ,   company_id ) 
  select 2, t.minor_cod , t.ara_titel , t.des_titel , m_company_id 
  from carold.cardcod1 t   
   where t.major_cod = 2 ; 
   
 --0-3 Car Make

 insert into carrent.cartype (code , name , namee , company_id ) 
  select t.minor_cod , t.ara_titel , t.des_titel , m_company_id  from carold.cardcod1 t 
  where t.major_cod = 3 ; 

 --0-4 Colors

 insert into carrent.color (code , name , namee , company_id ) 
  select t.minor_cod , t.ara_titel , t.des_titel , m_company_id  from carold.cardcod1 t 
  where t.major_cod = 4 ; 

 --0-5 City 
 insert into carrent.city (code , name , namee , company_id ) 
  select t.minor_cod , t.ara_titel , t.des_titel , m_company_id  from carold.cardcod1 t 
  where t.major_cod = 5 ; 

 --0-6 IDTypes
 insert into carrent.id_types (code , name , namee,  company_id ) 
  select t.minor_cod , t.ara_titel , t.des_titel , m_company_id  from carold.cardcod1 t 
  where t.major_cod = 6 ; 

--- Car Status 
insert into carrent.SYS_CODES (major_code , minor_code , a_desc , e_desc ,   company_id ) 
  select 13, t.minor_cod , t.ara_titel , t.des_titel , m_company_id 
  from carold.cardcod1 t   
   where t.major_cod = 13 ; 

--- Payment Methods
insert into carrent.SYS_CODES (major_code , minor_code , a_desc , e_desc ,   company_id ) 
  select 14, t.minor_cod , t.ara_titel , t.des_titel , m_company_id 
  from carold.cardcod1 t   
   where t.major_cod = 14 ; 

-- Recipet Types
insert into carrent.SYS_CODES (major_code , minor_code , a_desc , e_desc ,   company_id ) 
  select 15, t.minor_cod , t.ara_titel , t.des_titel , m_company_id 
  from carold.cardcod1 t   
   where t.major_cod = 15 ; 

-- 12 Branches ------
insert into carrent.branch (code , name , namee ,  company_id )
select t.minor_cod , t.ara_titel , t.des_titel , m_company_id from carold.cardcod1 t 
 where t.major_cod = 12 ; 
 
 
end ; 

--===========================================================

procedure reload_Company_contracts(m_company_id number  ) is 
begin
 clean_Company_contracts (m_company_id) ; 
 migrate_all_contracts (m_company_id) ; 
end;


end data_migration;
/
