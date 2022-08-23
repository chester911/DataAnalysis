# 월별 재구매율
-- 신규, 기존 주문 고객을 분류해보니 기존 고객들에 대한 세분화가 필요해 보임
-- 단순 분류가 아닌 월별 재구매율을 구해야 할 필요를 느낌
-- 2010년 12월~2011년 1월 데이터는 나중에 따로 병함
-- 우선은 2011년 데이터만 추출

# 2011년 월별 재구매율
-- 2010년 12월 ~ 2011년 1월 데이터
with order_dates_2010 as
(select customerId,
	order_date
from
	(select distinct invoiceNo,
		customerId,
		substr(invoiceDate, 1, 10) as order_date
	from retail
	where substr(invoiceDate, 1, 7) in ('2010-12', '2011-01')) as a),
-- 2011년 데이터
order_dates_2011 as
(select customerId,
	order_date
from
	(select distinct invoiceNo,
		customerId,
		substr(invoiceDate, 1, 10) as order_date
	from retail
	where year(invoiceDate)= 2011) as a)
-- 월별 재구매율 계산
-- 2011년 12월 제외
select ym, ret_rate
from
(select substr(a.order_date, 1, 7) as ym,
	count(distinct a.customerId) as cust_current,
    count(distinct b.customerId) as cust_prev,
    -- 해당 월 고객 중 저번 달에 주문한 고객의 비율
    count(distinct b.customerId)/ count(distinct a.customerId)* 100 as ret_rate
from order_dates_2010 as a
	left join order_dates_2010 as b
		on a.customerId= b.customerId
			and year(a.order_date)= year(b.order_date)+ 1
group by 1) as a
where ym!= '2010-12'
-- 병함
union
-- 2011년 1월 제외
select ym, ret_rate
from
(select substr(a.order_date, 1, 7) as ym,
	count(distinct a.customerId) as cust_current,
	count(distinct b.customerId) as cust_prev,
	-- 해당 월 고객 중 저번 월에 주문을 한 고객의 비율
	count(distinct b.customerId)/ count(distinct a.customerId)* 100 as ret_rate
from order_dates_2011 as a
	left join order_dates_2011 as b
		on a.customerId= b.customerId
			and month(a.order_date)= month(b.order_date)+ 1
group by 1
order by 1) as a
where ym!= '2011-01';