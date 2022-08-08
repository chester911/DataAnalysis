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

# 현상 1. 몇 번의 피크를 제외하고는 고객 수가 전반적으로 감소하는 추세임
# 가설 1.
-- 할인율 저하
-- 월별 평균 할인율
select substr(order_date, 1, 7) as ym,
	avg(discount_amount/ total* 100) as discount_ratio
from sale_log.sales
group by 1
order by 1;
-- 고객 수가 피크를 찍었던 2020-12월, 2021-4월, 6월의 할인율
-- 각각 11.4%, 7%, 10.8%
-- 시각화 결과 할인율과 고객 수가 크게 상관있어보이지 않음

# 가설 2.
-- 해당 월에 특정 제품이 프로모션을 했을 수도 있다.
-- 프로모션= 높은 할인율 로 설정
-- 전체 평균 할인율보다 높은 제품만 고려
with dc_ratio as
(select substr(order_date, 1, 7) as ym,
	category,
    avg(discount_amount/ total* 100) as discount_ratio
from sale_log.sales
group by 1, 2
order by 1, 3 desc),

user_ratio as
(select a.*,
	a.user_cnt/ b.user_cnt* 100 as user_ratio
from
(select substr(order_date, 1, 7) as ym,
	category,
    count(distinct cust_id) as user_cnt
from sale_log.sales
group by 1, 2
order by 1) as a
	left join
			(select substr(order_date, 1, 7) as ym,
				count(distinct cust_id) as user_cnt
			from sale_log.sales
            group by 1
            order by 1) as b
		on a.ym= b.ym)

select a.ym,
	sum(b.user_ratio) as 'user_ratio'
from dc_ratio as a
	left join user_ratio as b
		on a.ym= b.ym
			and a.category= b.category
where a.discount_ratio>= (select avg(discount_amount/ total* 100)
						from sale_log.sales)
group by 1
order by 1;
-- 확인 결과 2020년 12월, 2021년 6월에는 할인 품목을 구매한 고객의 비중이 압도적으로 높음
-- 제품의 월별 할인율을 지표로 삼기로 결정
select substr(order_date, 1, 7) as ym,
	category,
    avg(discount_amount/ total* 100) as dc_rate
from sale_log.sales
group by 1, 2
order by 1, 3 desc;

# 현상 2. 취소(canceled)된 주문이 압도적으로 많음
select *
from sale_log.sales
where status= 'canceled'
limit 100;