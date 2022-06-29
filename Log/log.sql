# DAU, 일간 arpu
with daily_rev as
(select substr(event_time, 1, 10) as 'date',
	sum(price) as rev
from event.log
where event_type= 'purchase'
group by 1
order by 1),

dau as
(select substr(event_time, 1, 10) as 'date',
	count(distinct user_id) as DAU
from event.log
group by 1
order by 1)

select a.date,
	a.dau,
    b.rev,
    b.rev/ a.dau as arpu
from dau as a
	left join daily_rev as b
		on a.date= b.date;

# WAU, 주간 apru
with wau as
(select yearweek(event_time) as 'week',
	count(distinct user_id) as WAU
from event.log
group by 1
order by 1),

weekly_rev as
(select yearweek(event_time) as 'week',
	sum(price) as rev
from event.log
where event_type= 'purchase'
group by 1
order by 1)

select a.week,
	a.wau,
    b.rev,
	b.rev/ a.wau as arpu
from wau as a
	left join weekly_rev as b
		on a.week= b.week;

# MAU, 월간 arpu
with mau as
(select substr(event_time, 1, 7) as YM,
	count(distinct user_id) as MAU
from event.log
group by 1
order by 1),

monthly_rev as
(select substr(event_time, 1, 7) as YM,
	sum(price) as rev
from event.log
where event_type= 'purchase'
group by 1
order by 1)

select a.ym,
	a.mau,
    b.rev,
    b.rev/ a.mau as arpu
from mau as a
	left join monthly_rev as b
		on a.ym= b.ym;
        
# 월별 구매전환율
-- view한 유저가 purchase를 한 경우
-- view user table
with view_usr as
(select substr(event_time, 1, 7) as ym,
	user_id
from event.log
where event_type= 'view'),
-- purchase user table
purchase_usr as
(select substr(event_time, 1, 7) as ym,
	user_id
from event.log
where event_type= 'purchase')

select a.ym,
	count(distinct a.user_id) as view_cnt,
	count(distinct b.user_id) as purchase_cnt
from view_usr as a
	left join purchase_usr as b
		on a.user_id= b.user_id
group by 1
order by 1;

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

# event type별 세션 수
select substr(event_time, 1, 7) as YM,
	event_type,
	count(distinct user_session) as sessions
from event.log
group by 1, 2
order by 1;

# 제품별 구매자 수, 매출 (월별)
-- category_code가 비어있는 데이터는 제외
-- 월별 최다 구매자 상품
with pu_monthly as
(select substr(event_time, 1, 7) as YM,
	category_code,
    count(distinct user_id) as pu,
    dense_rank() over(partition by substr(event_time, 1, 7) order by count(distinct user_id) desc) as rnk
from event.log
where event_type= 'purchase'
group by 1, 2)

select ym,
	category_code as category,
    pu
from pu_monthly
where rnk= 2;
-- 월별 최고 매출 상품
with rev_monthly as
(select substr(event_time, 1, 7) as YM,
	category_code,
    sum(price) as rev,
    dense_rank() over(partition by substr(event_time, 1, 7) order by sum(price) desc) as rnk
from event.log
where event_type= 'purchase'
group by 1, 2)

select ym,
	category_code as 'category',
    rev
from rev_monthly
where rnk= 1;

-- # 코호트분석 (단위 : 월)
-- -- purchase 완료한 유저만 집계
-- with first_order as
-- (select user_id,
-- 	min(event_time) as first_order
-- from event.log
-- where event_type= 'purchase'
-- group by 1)

-- select ym,
-- 	month_diff,
--     count(distinct user_id) as user_cnt
-- from
-- (select a.*,
-- 	b.first_order,
--     timestampdiff(month, b.first_order, a.event_time) as month_diff,
--     substr(b.first_order, 1, 7) as YM
-- from event.log as a
-- 	left join first_order as b
-- 		on a.user_id= b.user_id
-- where a.event_type= 'purchase') as f
-- group by 1, 2
-- order by 1;