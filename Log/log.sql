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
	count(distinct b.user_id) as purchase_cnt,
    count(distinct b.user_id)/ count(distinct a.user_id) as conversion
from view_usr as a
	left join purchase_usr as b
		on a.user_id= b.user_id
group by 1
order by 1;

# 월별 재구매율
select substr(a.event_time, 1, 7) as YM,
	count(distinct a.user_id) as pu_1,
	count(distinct b.user_id) as pu_2,
    count(distinct b.user_id)/ count(distinct a.user_id) as retention_rate
from
(select event_time,
	user_id
from event.log
where event_type= 'purchase') as a
	left join (select event_time,
					user_id
				from event.log
                where event_type= 'purchase') as b
					on a.user_id= b.user_id
						and month(a.event_time)= month(b.event_time)- 1
group by 1
order by 1;
-- 전자제품의 특성상 1개월 이내의 재구매가 적음
-- 2020년 9월에는 재구매율이 비교적 높았음

# 월별 이탈율
-- 구매 기준
-- 마지막 구매일 이후 1개월동안 조회하지 않으면 이탈로 간주
with bounce as
(select *,
	case when diff_month>= 1 then 'bounce'
		else 'non_bounce'
	end as 'bounce_type'
from
(select user_id,
	latest_order,
    '2020-12-15' as baseline,
    timestampdiff(month, latest_order, '2020-12-15') as diff_month
from
(select user_id,
	max(event_time) as latest_order
from event.log
where event_type= 'purchase'
group by 1) as a) as b)

select substr(latest_order, 1, 7) as YM,
	count(distinct user_id) as user_cnt,
	count(case when bounce_type= 'bounce' then bounce_type else null end) as 'bounce_cnt',
    count(case when bounce_type= 'non_bounce' then bounce_type else null end) as 'non_bounce_cnt'
from bounce
group by 1
order by 1;
-- 전자제품의 특성상 1개월 후 이탈이 많을 것으로 판단
-- 2020년 11월에는 이탈이 비교적 적음
-- 이때 판매된 상품들?

# 2020년 11월에 재구매된 상품들
with product_ret as
(select substr(a.event_time, 1, 7) as YM,
	a.product_id as 'product',
    count(a.user_id) as pu1,
    count(b.user_id) as pu2
from
(select event_time,
	product_id,
    user_id
from event.log
where event_type= 'purchase') as a
	left join (select event_time,
					product_id,
                    user_id
				from event.log
                where event_type= 'purchase') as b
		on a.user_id= b.user_id
			and month(a.event_time)= month(b.event_time)- 1
group by 1, 2),

nov_ret as
(select ym,
	product,
    pu1,
    pu2
from product_ret
where ym= '2020-11'
	and pu2!= 0)
-- 이 상품들의 판매량, 매출
select product_id as 'product',
	category_code as 'category',
	count(user_id) as order_cnt,
    sum(price) as rev
from event.log
where event_type= 'purchase'
	and product_id in (select product from nov_ret)
group by 1;

# 브랜드별 재구매율 (월별)
-- 월별 브랜드별 재구매율 테이블 생성
with brand_ret as
(select substr(a.event_time, 1, 7) as YM,
	a.brand,
    count(a.user_id) as pu1,
    count(b.user_id) as pu2,
    count(b.user_id)/ count(a.user_id) as ret,
    rank() over(partition by substr(a.event_time, 1, 7) order by count(b.user_id)/ count(a.user_id) desc) as rnk
from
(select event_time,
	brand,
    user_id
from event.log
where event_type= 'purchase') as a
	left join (select event_time,
					brand,
                    user_id
				from event.log
                where event_type= 'purchase') as b
		on a.user_id= b.user_id
			and month(a.event_time)= month(b.event_time)- 1
group by 1, 2)
-- 월별 재구매율 1위 브랜드
select YM,
	brand,
    ret
from brand_ret
where rnk= 1
	and ym!= '2020-12';

# 브랜드별 재구매율 (전체기간)
select a.brand,
	count(b.user_id)/ count(a.user_id) as ret
from
(select event_time,
	brand,
    user_id
from event.log
where event_type= 'purchase') as a
	left join (select event_time,
					brand,
                    user_id
				from event.log
                where event_type= 'purchase') as b
		on a.user_id= b.user_id
			and month(a.event_time)= month(b.event_time)- 1
group by 1
order by 2 desc;

# 건당 주문 금액 (월별)
-- 하나의 세션을 한 건의 주문으로 간주
select substr(event_time, 1, 7) as YM,
	count(distinct user_session) as order_cnt,
    sum(price) as rev,
    sum(price)/ count(distinct user_session) as atv
from event.log
where event_type= 'purchase'
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