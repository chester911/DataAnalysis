# 월별 주문 상태별 주문량, 주문자 수, 매출
select substr(a.order_purchase_timestamp, 1, 7) as YM,
	b.customer_city as 'city',
    b.customer_state as 'state',
    a.order_status as 'order_status',
    count(a.order_id) as order_cnt,
    count(distinct a.customer_id) as customer_cnt,
    coalesce(sum(c.price), 0) as rev
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
	left join olist.order_items as c
		on a.order_id= c.order_id
group by 1, 2, 3, 4
order by 1;

# 지역별 매출
-- 위도, 경도 포함
-- unavailable, canceled 주문 제외
with monthly as
(select substr(a.order_purchase_timestamp, 1, 7) as YM,
	c.customer_state as 'state',
	sum(b.price) as rev
from olist.orders as a
	left join olist.order_items as b
		on a.order_id= b.order_id
	left join olist.customers as c
		on a.customer_id= c.customer_id
where a.order_status not in ('unavailable', 'canceled')
group by 1, 2
order by 1),

maps as
(select geolocation_state as 'state',
	geolocation_city as 'city',
	avg(geolocation_lat) as 'lat',
    avg(geolocation_lng) as 'long'
from olist.geolocation
group by 1)

select a.*, b.city, b.lat, b.long
from monthly as a
	left join maps as b
		on a.state= b.state;

# 지역별 최다 판매 물품 (주문 수, 매출)
select substr(a.order_purchase_timestamp, 1, 7) as YM,
	c.customer_state as 'state',
    d.product_category_name as 'product',
    count(distinct a.customer_id) as pu_cnt,
    sum(b.price) as rev
from olist.orders as a
	left join olist.order_items as b
		on a.order_id= b.order_id
	left join olist.customers as c
		on a.customer_id= c.customer_id
	left join olist.products as d
		on b.product_id= d.product_id
where a.order_status not in ('unavailable', 'canceled')
group by 1, 2, 3
order by 1;

# 월별 판매자 순위
select substr(a.order_purchase_timestamp, 1, 7) as YM,
	b.customer_state as 'state',
    b.customer_city as 'city',
    count(distinct c.seller_id) as seller_id
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
	left join olist.order_items as c
		on a.order_id= c.order_id
where a.order_status not in ('unavailable', 'canceled')
group by 1, 2, 3
order by 1;

# 판매자별 물품 판매량, 매출
select substr(a.order_purchase_timestamp, 1, 7) as YM,
	coalesce(b.seller_id, 'unknown') as 'seller',
    coalesce(c.product_category_name, '') as 'product',
    count(distinct a.order_id) as order_cnt,
    coalesce(sum(b.price), 0) as rev
from olist.orders as a
	left join olist.order_items as b
		on a.order_id= b.order_id
	left join olist.products as c
		on b.product_id= c.product_id
where a.order_status not in ('unavailable', 'canceled')
group by 1, 2, 3
order by 1;