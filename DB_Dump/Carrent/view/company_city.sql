create or replace view company_city as
select "CODE","NAME","NAMEE","EDITDATE","COMPANY_ID"
    from carrent.city
   where company_id = security.get_User_Company
   order by name

