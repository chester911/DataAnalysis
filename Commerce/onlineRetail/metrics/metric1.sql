# ARPPU, ATV, 고객당 평균 주문 횟수
select substr(invoiceDate, 1, 7) as ym,
	sum(quantity* unitPrice)/ count(distinct customerId) as ARPPU,
    sum(quantity* unitPrice)/ count(distinct invoiceNo) as ATV,
    count(distinct invoiceNo)/ count(distinct customerId) as AVG_ORDER_CNT
from retail
group by 1
order by 1;