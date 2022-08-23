# 상품별 고객당 평균 주문 횟수, ATV
select stockCode,
	substr(invoiceDate, 1, 7) as ym,
    count(distinct invoiceNo)/ count(distinct customerId) as avg_order_cnt,
    sum(quantity* unitPrice)/ count(distinct invoiceNo) as ATV
from retail
group by 1, 2
order by 1, 2;