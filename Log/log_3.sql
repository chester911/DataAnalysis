select *
from sale_log.sales
limit 100;

select status,
	count(distinct cust_id) as 'user'
from sale_log.sales
group by 1
order by 2 desc;

# 월간 고객 추이
select substr(order_date, 1, 7) as ym,
	status,
    count(distinct cust_id) as user_cnt
from sale_log.sales
group by 1, 2
order by 1, 3 desc;