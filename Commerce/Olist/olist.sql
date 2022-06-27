# 월별 주문 상태별 주문량, 주문자 수, 매출
select substr(a.order_purchase_timestamp, 1, 7) as YM,
	b.customer_city as 'city',
    b.customer_state as 'state',
    a.order_status as 'order_status',
    count(a.order_id) as order_cnt,
    count(distinct a.customer_id) as customer_cnt,
    coalesce(sum(c.price), 0) as rev
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
	left join olist.order_items as c
		on a.order_id= c.order_id
group by 1, 2, 3, 4
order by 1;