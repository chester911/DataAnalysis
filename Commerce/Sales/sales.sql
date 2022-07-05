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

# 코호트분석 (월별)
-- 고객별 최초 구매일
with cohort_table as
(select a.cust_id,
	a.order_date,
    b.first_order,
    timestampdiff(month, b.first_order, a.order_date) as diff_month,
    substr(b.first_order, 1, 7) as 'group'
from
(select order_date,
	cust_id
from sale_log.sales
where status in ('complete', 'cod', 'paid')) as a
	left join (select cust_id,
					min(order_date) as first_order
				from sale_log.sales
				where status in ('complete', 'cod', 'paid')
                group by 1) as b
		on a.cust_id= b.cust_id)

select `group`,
	diff_month,
    count(distinct cust_id) as user_cnt
from cohort_table
group by 1, 2
order by 1;

# 월별 재구매율
-- 2020년 재구매율
with ret_20 as
(select substr(a.order_date, 1, 7) as ym,
	count(distinct a.cust_id) as pu_current,
    count(distinct b.cust_id) as pu_before,
    count(distinct b.cust_id)/ count(distinct a.cust_id)* 100 as retention_rate
from
(select order_date,
	cust_id
from sale_log.sales
where status in ('complete', 'cod', 'paid')
	and `year`= 2020) as a
	left join (select order_date,
					cust_id
				from sale_log.sales
                where status in ('complete', 'cod', 'paid')
					and `year`= 2020) as b
		on a.cust_id= b.cust_id
			and month(a.order_date)= month(b.order_date)+ 1
group by 1
order by 1),
-- 2021년 재구매율
ret_21 as
(select substr(a.order_date, 1, 7) as ym,
	count(distinct a.cust_id) as pu_current,
    count(distinct b.cust_id) as pu_before,
    count(distinct b.cust_id)/ count(distinct a.cust_id)* 100 as retention_rate
from
(select order_date,
	cust_id
from sale_log.sales
where status in ('complete', 'cod', 'paid')
	and `year`= 2021) as a
	left join (select order_date,
					cust_id
				from sale_log.sales
                where status in ('complete', 'cod', 'paid')
					and `year`= 2021) as b
		on a.cust_id= b.cust_id
			and month(a.order_date)= month(b.order_date)+ 1
group by 1
order by 1)

select * from ret_20
union
select * from ret_21;
-- 구매 고객에 비해 재구매율은 낮음

# 월별 취소 / 반품 주문 건수, 고객 비율
-- 전체 유저
with total_user as
(select substr(order_date, 1, 7) as  ym,
	count(distinct order_id) as order_cnt,
    count(distinct cust_id) as user_cnt
from sale_log.sales
where status in ('complete', 'canceled', 'refund', 'cod', 'paid', 'processing', 'holded')
group by 1
order by 1),

canceled_user as
(select substr(order_date, 1, 7) as ym,
	count(distinct order_id) as canceled_order,
    count(distinct cust_id) as canceled_cust
from sale_log.sales
where status in ('canceled', 'refund')
group by 1
order by 1)

select a.ym,
	b.canceled_order/ a.order_cnt* 100 as order_ratio,
    b.canceled_cust/ a.user_cnt* 100 as cust_ratio
from total_user as a
	left join canceled_user as b
		on a.ym= b.ym;
-- 취소, 반품 비율이 비정상적으로 높음

# 제품군별 취소, 반품 비율
-- 취소, 반품 주문 수
with canceled_order as
(select category,
	count(distinct order_id) as order_cnt,
    count(distinct cust_id) as user_cnt
from sale_log.sales
where status in ('canceled', 'refund')
group by 1),
-- 전체 주문 수
total_order as
(select category,
	count(distinct order_id) as order_cnt,
    count(distinct cust_id) as user_cnt
from sale_log.sales
where status in ('complete', 'canceled', 'refund', 'cod', 'paid', 'processing', 'holded')
group by 1)

select a.category,
	a.order_cnt as 'total_order',
    b.order_cnt as 'canceled_order',
    b.order_cnt/ a.order_cnt* 100 as 'canceled_ratio'
from total_order as a
	left join canceled_order as b
		on a.category= b.category
order by 4 desc;
-- Others 제품군의 취소 / 반품율이 약 90%로 상당히 높음
-- Others를 제외하면 Soghaat (베이커리) 제품군이 약 58%로 꽤 높음
-- Others 제품군의 제품?
select distinct sku
from sale_log.sales
where category= 'Others';

# 성별 별 최다 구매 제품군(월별 집계)
select ym,
	category,
    gender,
    pu
from
(select substr(order_date, 1, 7) as ym,
	category,
    gender,
    count(distinct cust_id) as pu,
    rank() over(partition by substr(order_date, 1, 7), gender order by count(distinct cust_id) desc) as rnk
from sale_log.sales
where status in ('complete', 'cod', 'paid')
group by 1, 2, 3
order by 1) as a
where rnk= 1;
-- 위에서 확인한 할인율과는 크게 상관있어보이지 않음

select *
from sale_log.sales
limit 100;