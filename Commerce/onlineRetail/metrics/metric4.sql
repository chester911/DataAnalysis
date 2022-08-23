# 신규 유저들이 구매한 상품들
-- 신규 고객들이 주문한 상품들의 월별 주문 건수, 주문 고객 수, 매출
with order_types as
(select a.*,
	b.first_order,
    case when substr(a.invoiceDate, 1, 7)= b.first_order then 'new_order'
		else 'not_new_order'
	end as order_type
from retail as a
	left join (select customerId,
					substr(min(invoiceDate), 1, 7) as first_order
				from retail
                group by 1) as b
		on a.customerId= b.customerId)

select stockCode,
	description,
    substr(invoiceDate, 1, 7) as ym,
    count(distinct invoiceNo) as order_cnt,
    count(distinct customerId) as cust_cnt,
    sum(quantity* unitPrice) as rev
from order_types
where order_type= 'new_order'
group by 1, 3
order by 1, 3;