# 재구매율을 확인함
-- 전반적으로 감소하는 추세임
-- 감소 중, 2011년 3월 ~ 4월에는 재구매율이 증가함
-- 왜 증가했을까?

-- 

-- 4월에 재구매 한 고객들 추출
with orders_mar_apr as
(select customerId,
	order_date
from
	(select distinct invoiceNo,
		customerId,
		substr(invoiceDate, 1, 10) as order_date
	from retail
	where substr(invoiceDate, 1, 7) in ('2011-03', '2011-04')) as a)
-- 3월 고객 중 4월에도 주문한 고객들이 4월에 주문한 상품들
select *
from retail
where substr(invoiceDate, 1, 7)= '2011-04'
	and customerId in (select distinct b.customerId
					from orders_mar_apr as a
						left join orders_mar_apr as b
							on a.customerId= b.customerId
								and month(a.order_date)= month(b.order_date)- 1
					where b.customerId is not null);