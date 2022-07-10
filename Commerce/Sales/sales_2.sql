##### 취소, 반품 주문 지표 #####
# 월별 취소 및 반품 주문 추이
-- 전체 주문
with total_order as
(select substr(order_date, 1, 7) as ym,
	region,
    state,
    category,
    gender,
    count(distinct order_id) as order_cnt
from sale_log.sales
where status in ('complete', 'canceled', 'refund', 'cod', 'paid')
group by 1, 2, 3, 4, 5
order by 1),
-- 취소 주문
canceled_order as
(select substr(order_date, 1, 7) as ym,
	region,
    state,
    category,
    gender,
    count(distinct order_id) as order_cnt
from sale_log.sales
where status in ('canceled', 'refund')
group by 1, 2, 3, 4, 5
order by 1)

select a.ym,
	a.region,
    a.state,
    a.category,
    a.gender,
    a.order_cnt as 'total_order',
    coalesce(b.order_cnt, 0) as 'canceled_order',
    coalesce(b.order_cnt/ a.order_cnt* 100, 0) as canceled_ratio
from total_order as a
	left join canceled_order as b
		on a.ym= b.ym
			and a.region= b.region
            and a.state= b.state
            and a.category= b.category
            and a.gender= b.gender;

# 상품별 취소 및 반품 주문 건수
select substr(order_date, 1, 7) as ym,
	region,
    state,
    gender,
    category,
    count(distinct order_id) as order_cnt
from sale_log.sales
where status in ('canceled', 'refund')
group by 1, 2, 3, 4, 5
order by 1;

# 연령대별 주문 취소, 반품 건 수
-- 단위 : 10세
select substr(order_date, 1, 7) as ym,
	region,
    state,
    category,
    gender,
    case when age between 10 and 19 then '10s'
		when age between 20 and 29 then '20s'
        when age between 30 and 39 then '30s'
        when age between 40 and 49 then '40s'
        when age between 50 and 59 then '50s'
        when age between 60 and 69 then '60s'
		else '70+'
	end as age_bin,
    coalesce(count(distinct order_id), 0) as order_cnt
from sale_log.sales
where status in ('conceled', 'refund')
group by 1, 2, 3, 4, 5, 6
order by 1;

