# 월별 매출 상위 상품들의 주문 건수 및 고객 수
-- 매출 상위 10위 상품들
with monthly_rev_rnk as
(select substr(invoiceDate, 1, 7) as ym,
	stockCode,
	description,
    sum(quantity* unitPrice) as rev,
    row_number() over(partition by substr(invoiceDate, 1, 7)
					order by sum(quantity* unitPrice) desc) as rnk
from retail
group by 1, 2)

select stockCode,
	description,
    substr(invoiceDate, 1, 7) as ym,
    count(distinct invoiceNo) as order_cnt,
    count(distinct customerId) as cust_cnt
from retail
where stockCode in (select stockCode
					from monthly_rev_rnk
                    where rnk<= 10)
group by 1, 3
order by 4 desc, 5 desc;