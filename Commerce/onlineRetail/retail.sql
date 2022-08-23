use onlineretail;

# 월간 매출 추세
select substr(invoiceDate, 1, 7) as ym,
	sum(quantity* unitPrice) as rev
from retail
group by 1
order by 1;
-- 전체적으로는 감소함
-- 조금 더 자세히 확인

# 월간 고객 수, ARPPU 변동
select substr(invoiceDate, 1, 7) as ym,
	count(distinct customerId) as cust_cnt,
    sum(quantity* unitPrice)/ count(distinct customerId) as ARPPU
from retail
group by 1
order by 1;
-- 고객 수는 증감을 반복하지만 전체적으로는 증가하는 추세
-- 반면 ARPPU는 전체적으로 감소함
-- 2011년 1월 고객 수는 감소했지만 ARPPU는 증가함
-- 이 때의 전체 매출을 감소했지만 평균 결제 금액은 증가함
-- 왜?
-- 2010년 12월, 2011년 1월 내역만 살펴보기로 함

# 고객 수가 왜 감소했을까?
-- 신규 고객과 기존 고객을 나눠서 파악해보기로 함
-- 신규 고객= 첫 주문이 2011년 1월인 고객
select count(distinct a.customerId) as cust_total,
	count(distinct case when substr(b.first_order, 1, 7)= '2010-12' then b.customerId else null end) as cust_old,
    count(distinct case when substr(b.first_order, 1, 7)= '2011-01' then b.customerId else null end) as cust_new
from (select *
	from retail
	where substr(invoiceDate, 1, 7)= '2011-01') as a
	left join
		(select customerId,
			min(invoiceDate) as first_order
		from retail
		group by 1
		order by 2) as b
		on a.customerId= b.customerId;
-- 2011년 1월 신규 고객은 약 56.2%, 재주문 고객은 약 43.8%임
-- 기존 고객의 이탈이 고객 수 감소의 원인으로 보임

# 그럼 ARPPU는 왜 증가한걸까?
-- 기존 고객의 재구매는 비교적 적음
-- 가설 1. 그럼 주문 건당 금액이 증가한 것 아닐까?
select *
from
(select sum(quantity* unitPrice)/ count(distinct invoiceNo) as ATV_DEC
from retail
where substr(invoiceDate, 1, 7)= '2010-12') as a,
(select sum(quantity* unitPrice)/ count(distinct invoiceNo) as ATV_JAN
from retail
where substr(invoiceDate, 1, 7)= '2011-01') as b;
-- 건당 주문 금액은 증가함

-- 가설 2. 고객 1인당 평균 주문 횟수가 증가하지 않았을까?
select *
from
(select count(distinct invoiceNo)/ count(distinct customerId) as order_per_cust_DEC
from retail
where substr(invoiceDate, 1, 7)= '2010-12') as a,
(select count(distinct invoiceNo)/ count(distinct customerId) as order_per_cust_JAN
from retail
where substr(invoiceDate, 1, 7)= '2011-01') as b;
-- 고객당 평균 주문 횟수는 오히려 감소함

-- 2011년 1월, 2월도 유사한 현상을 보임
-- 이 두 기간의 내역만 분리해 확인
select *
from
(select sum(quantity* unitPrice)/ count(distinct invoiceNo) as ATV_DEC
from retail
where substr(invoiceDate, 1, 7)= '2011-01') as a,
(select sum(quantity* unitPrice)/ count(distinct invoiceNo) as ATV_JAN
from retail
where substr(invoiceDate, 1, 7)= '2011-02') as b;
-- 건당 주문 금액은 감소함
select *
from
(select count(distinct invoiceNo)/ count(distinct customerId) as order_per_cust_DEC
from retail
where substr(invoiceDate, 1, 7)= '2011-01') as a,
(select count(distinct invoiceNo)/ count(distinct customerId) as order_per_cust_JAN
from retail
where substr(invoiceDate, 1, 7)= '2011-02') as b;
-- 고객 1인당 평균 주문 횟수 역시 감소함

-- 2010년 12월 ~ 2011년 1월 건당 주문 금액은 증가했지만 1인당 평균 주문 횟수는 감소함
-- 반면 2011년 1월 ~ 2월에는 건당 주문 금액과 1인당 평균 주문 횟수 모두 감소함

# 결론
-- ATV와 1인당 평균 주문 횟수가 고객 수 감소와 ARPPU 증가의 원인으로 보이지는 않음
-- 하지만 현황을 파악하기에는 좋은 지표로 파악됨

# 2011년 2월~3월, 4월~5월에는 고객 수와 ARPPU가 모두 증가함
-- 2월 ~ 3월에는 1인당 주문 건수가 증가하고 건당 주문 금액이 감소함
-- 4월 ~ 5월에는 주문 건수는 감소하고 건당 주문 금액은 증가함
-- 2월~3월 ARPPU는 왜 증가했을까?
-- 이 때 주문된 상품이 원인 아닐까?

-- 2월에 주문된 상품들의 3월달 고객당 평균 주문 수
with order_increase_ratio as
(select a.stockCode,
	a.avg_order as avg_order_FEB,
    b.avg_order as avg_order_MAR,
    b.avg_order/ a.avg_order* 100 as INCREASE_RATE
from
	(select stockCode,
		count(distinct invoiceNo)/ count(distinct customerId) as avg_order
	from retail
	where substr(invoiceDate, 1, 7)= '2011-02'
	group by 1
	order by 2 desc) as a
	left join
			(select stockCode,
				count(distinct invoiceNo)/ count(distinct customerId) as avg_order
            from retail
            where substr(invoiceDate, 1, 7)= '2011-03'
            group by 1
            order by 2 desc) as b
		on a.stockCode= b.stockCode
order by 4 desc)

select count(distinct case when increase_rate> 100 then stockCode else null end) as order_increased,
	count(distinct case when increase_rate= 100 then stockCode else null end) as order_maintained,
	count(distinct case when increase_rate< 100 then stockCode else null end) as order_not_increased
from order_increase_ratio;
-- 1인당 주문 건수가 증가한 상품이 많음
-- 2월~3월 고객당 주문 건수 증가의 원인으로 상품별 고객 1인당 평균 주문 건수를 채택

-- 그럼 건당 상품별 건당 주문 금액은?
with atv_increase_rate as
(select a.stockCode,
	coalesce(b.atv/ a.atv* 100, 0) as increase_rate
from
	(select stockCode,
		sum(quantity* unitPrice)/ count(distinct invoiceNo) as atv
	from retail
	where substr(invoiceDate, 1, 7)= '2011-02'
	group by 1
	order by 2 desc) as a
    left join
			(select stockCode,
				sum(quantity* unitPrice)/ count(distinct invoiceNo) as atv
			from retail
            where substr(invoiceDate, 1, 7)= '2011-03'
            group by 1
            order by 2 desc) as b
		on a.stockCode= b.stockCode
order by 2 desc)

select count(distinct case when increase_rate> 100 then stockCode else null end) as atv_increased,
	count(distinct case when increase_rate= 100 then stockCode else null end) as atv_maintain,
	count(distinct case when increase_rate< 100 then stockCode else null end) as atv_decreased
from atv_increase_rate;
-- ATV는 반대로 감소한 상품이 많음
-- 상품당 ATV 역시 2~3월 ATV의 감소 원인으로 채택