use onlineretail;

select *
from retail;

# Retention
select substr(a.invoicedate, 1, 7) as YM,
	count(distinct a.customerid) as pu_1,
    count(distinct b.customerid) as pu_2
from retail as a
	left join retail as b
		on a.customerid= b.customerid
			and date_format(a.invoicedate, '%Y%m')= date_format(b.invoicedate, '%Y%m')- 1
group by 1
order by 1;