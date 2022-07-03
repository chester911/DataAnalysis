# 월별 고객수, 주문 수, 매출
select substr(order_date, 1, 7) as ym,
	status,
    count(distinct cust_id) as user_cnt,
    count(distinct order_id) as order_cnt,
    sum(total) as rev
from sale_log.sales
group by 1, 2
order by 1;

# 상품별 구매자 수, 주문 건수, 주문 수량, 매출 (월별로 집계)
-- status == 'complete', 'cod', 'paid'
select substr(order_date, 1, 7) as ym,
	category,
	item_id,
    count(distinct cust_id) as pu,
    count(distinct order_id) as order_cnt,
    sum(qty_ordered) as quantity,
    sum(total) as rev
from sale_log.sales
where status in ('complete', 'cod', 'paid')
group by 1, 2, 3
order by 1;

# 제품군별 할인율 (월별)
-- 제품군별 월별 할인율
with monthly_discount as
(select substr(order_date, 1, 7) as ym,
	category,
    avg(discount_percent) as 'discount_percent',
    rank() over(partition by substr(order_date, 1, 7) order by avg(discount_percent) desc) as rnk
from sale_log.sales
group by 1, 2
order by 1)
-- 월별 최고 할인 제품군
select ym,
	category,
    discount_percent
from monthly_discount
where rnk= 1;
-- 할인 품목들과 주문량이 관련이 있을지 의문이 듦

# 제품의 월별 할인 여부 별 주문 건수 (구매 기준)
-- 제품군별 월별 할인 여부
select substr(order_date, 1, 7) as ym,
	category,
    case when discount_percent> 0 then 'sale'
		else 'non_sale'
	end as sale_type,
    order_id
from sale_log.sales
where status in ('complete', 'cod', 'paid')
order by 1;

# 지역별 구매자 수, 주문 건수, 매출 (월별로 집계)
select substr(order_date, 1, 7) as ym,
	region,
    state,
    count(distinct cust_id) as pu,
    count(distinct order_id) as order_cnt,
    sum(total) as rev
from sale_log.sales
where status in ('complete', 'cod', 'paid')
group by 1, 2, 3
order by 1;
-- 구매자 수 보다 주문 건수가 많은 월이 있음
-- 한 고객이 여러번 주문했음을 의미

# 1개월 이내에 여러번 주문한 고객
-- 월별 고객당 주문 건수
with order_user as
(select substr(order_date, 1, 7) as ym,
	`user name` as 'user',
    count(distinct order_id) as order_cnt
from sale_log.sales
where status in ('complete', 'cod', 'paid')
group by 1, 2
order by 1)
-- 한달에 2회 이상 구매한 고객이 구매한 제품군
select category,
	count(distinct cust_id) as pu,
    count(distinct order_id) as order_cnt,
    sum(total) as rev
from sale_log.sales
where status in ('complete', 'cod', 'paid')
	and `user name` in (select distinct user
						from order_user
                        where order_cnt>= 2)
group by 1;

select *
from sale_log.sales
limit 10;