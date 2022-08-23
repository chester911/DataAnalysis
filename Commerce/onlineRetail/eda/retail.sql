use onlineretail;

select *
from retail
limit 100;

##### EDA #####
select count(*)
from retail;

select count(distinct stockcode)
from retail;

select min(invoicedate), max(invoicedate)
from retail;

-- Monthly Users
select substr(invoicedate, 1, 7) as ym,
	count(distinct customerId) as cust_cnt,
    count(distinct invoiceNo) as order_cnt
from retail
group by 1
order by 1;