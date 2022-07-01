##### Overview Dashboard #####
# 월별 사용자 수, 매출
with monthly_view as
(select substr(event_time, 1, 7) as YM,
	count(distinct user_id) as view_cnt
from event.log
where event_type= 'view'
group by 1
order by 1),

monthly_cart as
(select substr(event_time, 1, 7) as YM,
	count(distinct user_id) as cart_cnt
from event.log
where event_type= 'cart'
group by 1
order by 1),

monthly_purchase as
(select substr(event_time, 1, 7) as YM,
	count(distinct user_id) as purchase_cnt,
    sum(price) as rev
from event.log
where event_type= 'purchase'
group by 1
order by 1),

monthly_total as
(select substr(event_time, 1, 7) as YM,
	count(distinct user_id) as MAU
from event.log
group by 1)

select a.ym,
	d.mau,
	a.view_cnt,
    b.cart_cnt,
    c.purchase_cnt,
    c.rev,
    rev/ d.mau as arpu,
    rev/ c.purchase_cnt as arppu
from monthly_view as a
	left join monthly_cart as b
		on a.ym= b.ym
	left join monthly_purchase as c
		on a.ym= c.ym
	left join monthly_total as d
		on a.ym= d.ym;

# 상품별 판매 수량, 매출
select substr(event_time, 1, 7) as YM,
	brand,
	product_id as 'product',
	category_code as 'category',
    count(distinct user_id) as pu,
    sum(price) as rev
from event.log
where event_type= 'purchase'
group by 1, 2, 3, 4
order by 1;

##### Specific Table #####
# event type별 유저 수
-- view user
with view_user as
(select substr(event_time, 1, 7) as ym,
	user_id
from event.log
where event_type= 'view'),
-- cart user
cart_user as
(select substr(event_time, 1, 7) as ym,
	user_id
from event.log
where event_type= 'cart'),
-- purchase user
purchase_user as
(select substr(event_time, 1, 7) as ym,
	user_id
from event.log
where event_type= 'purchase')

-- 월별 전환율
select a.ym,
	count(distinct a.user_id) as view_user,
    count(distinct b.user_id) as cart_user,
    count(distinct c.user_id) as purchase_user,
    count(distinct b.user_id)/ count(distinct a.user_id) as view_to_cart_ratio,
    count(distinct c.user_id)/ count(distinct b.user_id) as cart_to_purchase_ratio
from view_user as a
	left join cart_user as b
		on a.user_id= b.user_id
	left join purchase_user as c
		on a.user_id= c.user_id
			and b.user_id= c.user_id
group by 1
order by 1;
-- 상품 조회 후 장바구니에 추가하는 유저의 비율이 10% 이하로 상당히 낮음
-- 장바구니에 상품을 추가한 후 구매한 유저는 매 월 50% 이상임
-- 일단 장바구니에 상품을 추가하면 절반 이상의 유저는 그 상품을 구매함
-- 상품 조회 -> 장바구니 추가 -> 구매의 과정을 거친 고객들이 구매한 상품은?
with views as
(select substr(event_time, 1, 7) as YM,
	user_id
from event.log
where event_type= 'view'),

carts as
(select substr(event_time, 1, 7) as YM,
	user_id
from event.log
where event_type= 'cart'),

purchases as
(select substr(event_time, 1, 7) as YM,
	user_id,
	product_id as product,
    category_code as category,
    brand,
    price
from event.log
where event_type= 'purchase')

select a.ym,
	c.product,
    c.category,
    count(distinct c.user_id) as pu,
    sum(c.price) as rev
from views as a
	left join carts as b
		on a.user_id= b.user_id
	left join purchases as c
		on b.user_id= c.user_id
			and a.user_id= c.user_id
group by 1, 2, 3;

# 월별 재구매율
-- 1개월 전에 구매한 사람이 해당 월에도 구매한 비율
select substr(a.date, 1, 7) as YM,
	count(distinct b.user_id) as pu_before,
    count(distinct a.user_id) as pu_current,
	count(distinct b.user_id)/ count(distinct a.user_id)* 100 as retention
from
(select date(event_time) as 'date',
	user_id
from event.log
where event_type= 'purchase') as a
	left join (select date(event_time) as 'date',
					user_id
				from event.log
				where event_type= 'purchase') as b
		on a.user_id= b.user_id
			and month(a.date)= month(b.date)+ 1
where substr(a.date, 1, 7)!= '2020-09'
group by 1
order by 1;
-- 전자제품의 특성상 1개월 이내의 재구매율이 상당히 낮음
-- 그럼 재구매된 상품들은?

# 제품군별 재구매율
with ret_category as
(select substr(a.date, 1, 7) as YM,
    a.category_code as category,
    count(distinct b.user_id)/ count(distinct a.user_id)* 100 as retention
from
(select date(event_time) as 'date',
	user_id,
    category_code
from event.log
where event_type= 'purchase') as a
	left join (select date(event_time) as 'date',
					user_id,
                    category_code
				from event.log
                where event_type= 'purchase') as b
		on a.user_id= b.user_id
			and month(a.date)= month(b.date)+ 1
group by 1, 2
order by 1)

select ym,
	category,
    retention
from ret_category
where ym!= '2020-09'
	and retention!= 0;