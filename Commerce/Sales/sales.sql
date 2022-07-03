select *
from sale_log.sales
limit 100;

# 지역별 구매자 수 및 매출액
-- complete, cod, paid만 집계
select substr(order_date, 1, 7) as ym,
	state,
    count(distinct cust_id) as user_cnt,
    count(distinct order_id) as order_cnt,
    sum(total) as rev
from sale_log.sales
where status in ('complete', 'cod', 'paid')
group by 1, 2
order by 1;
-- 월별 매출 1위 지역?
with monthly_rev as
(select substr(order_date, 1, 7) as ym,
	state,
    sum(total) as rev,
    rank() over(partition by substr(order_date, 1, 7) order by sum(total) desc) as rnk
from sale_log.sales
where status in ('complete', 'cod', 'paid')
group by 1, 2
order by 1)

select ym,
	state,
    rev
from monthly_rev
where rnk= 1;

# 상품별 구매자 수 및 매출액
select substr(order_date, 1, 7) as ym,
	category,
    count(distinct cust_id) as user_cnt,
	count(distinct order_id) as order_cnt,
    sum(total) as rev
from sale_log.sales
where status in ('complete', 'cod', 'paid')
group by 1, 2
order by 1;
-- 월별 1위 주문량 상품
with monthly_qty as
(select substr(order_date, 1, 7) as ym,
	category,
    sum(qty_ordered) as quantity,
    row_number() over(partition by substr(order_date, 1, 7) order by sum(qty_ordered) desc) as rnk
from sale_log.sales
where status in ('complete', 'cod', 'paid')
group by 1, 2
order by 1),

monthly_top as
(select ym,
	category,
    quantity
from monthly_qty
where rnk= 1)
-- 이 상품들을 구매한 지역은?
select category,
	state,
    sum(qty_ordered) as quantity
from sale_log.sales
where status in ('complete', 'cod', 'paid')
	and category in (select category from monthly_top)
group by 1, 2;

### 취소, 반품 주문 분석
# 지역별 취소 주문 비율
-- 지역별 취소 주문
with monthly_cancel as
(select substr(order_date, 1, 7) as ym,
	region,
    state,
    count(distinct order_id) as cancel_cnt
from sale_log.sales
where status in ('order_refunded', 'canceled', 'refund')
group by 1, 2, 3
order by 1),
-- 지역별 전체 주문
monthly_cnt as
(select substr(order_date, 1, 7) as ym,
	region,
	state,
    count(distinct order_id) as order_cnt
from sale_log.sales
where status!= 'payment_review'
group by 1, 2, 3 
order by 1)

select a.*,
	coalesce(b.cancel_cnt, 0) as cancel_cnt,
    coalesce(b.cancel_cnt/ a.order_cnt* 100, 0) as ratio
from monthly_cnt as a
	left join monthly_cancel as b
		on a.ym= b.ym
			and a.region= b.region
            and a.state= b.state;