CREATE OR REPLACE TRIGGER AI_contract
   After INSERT 
   ON Contract
   FOR EACH ROW
declare 
-- car_last_returnKM number ;
v_day_rate number ; 
v_km_per_day number ; 
v_over_km_rate number ; 
v_cust_categ carrent.cust_category%rowtype ; 
BEGIN


  if (:new.is_migrated = 'N') then 

    select c.dayrate into v_day_rate from carrent.car c where c.code = :new.car ;
    select c.kmperday into  v_km_per_day from carrent.car c where c.code = :new.car ; 
    select c.overkmrate into v_over_km_rate from carrent.car c where c.code = :new.car ;
    
    -- Apply Customer Ctegory/ Profile Values ------
    begin 
        select * into v_cust_categ from carrent.cust_category t 
                 where t.cat_id = ( select cu.cust_category 
                           from carrent.customer cu 
                           where cu.idno = :new.idno 
                           and cu.idtype = :new.idtype) ; 
        v_day_rate   := round( v_day_rate * ( 1 -  v_cust_categ.daily_rate_disc / 100) , 0 )  ; 
        v_km_per_day := round( v_km_per_day * ( 1 + v_cust_categ .km_increase_perc /100 ) , 0) ;  
     Exception when others then 
        null  ; 
     end ; 
   -- End of Apply Customer Ctegory/ Profile Values ------
    
    -- Create a Contract_care Record for the user selected car 
    insert into contract_car ( company_id , branch_id , serialno ,  car , dayrate , kmperday , overkmrate , hoursvalue  ,  fmkmreading , interval,  carincome) 
                                         values (  :new.company_id  
                                                  , :new.branch_id
                                                  , :new.serialno
                                                  , :new.car
                                                  , v_day_rate -- (select c.dayrate from carrent.car c where c.code = :new.car) 
                                                  , v_km_per_day -- (select c.kmperday from carrent.car c where c.code = :new.car)
                                                  , v_over_km_rate -- (select c.overkmrate from carrent.car c where c.code = :new.car)
                                                  ,(select c.hoursValue from carrent.car c where c.code = :new.car)
                                                  , carrent.contract_services.get_car_last_retrnkm (:new.car )
                                                  , :new.interval
                                                  -- , sysdate + :new.interval  
                                                  , (select c.dayrate from carrent.car c where c.code = :new.car)  * :new.interval
                                                ) ;
                                                
  end if; 

END;
/
