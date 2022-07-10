##### 태블로 시각화와 병행하면서 진행 #####
select *
from sale_log.sales
limit 100;

# WAU, 주간 주문량
select yearweek(order_date) as 'week',
	count(distinct order_id) as order_cnt,
    count(distinct cust_id) as cust_cnt
from sale_log.sales
group by 1
order by 1;
-- 2020년 51주차에 사용자, 주문량 급격하게 증가
-- 2021년 17주차에도 급격히 증가 후 18주차에 감소함
-- 이때의 데이터만 추출

# 사용자, 주문량이 급격히 증가한 기간 추출
-- 이 기간에 어떤 이벤트가 발생했는지?
select yearweek(order_date) as 'week',
	status,
    count(distinct cust_id) as cust_cnt,
    count(distinct order_id) as order_cnt
from
(select *
from sale_log.sales
where yearweek(order_date) in ('202051', '202117')) as a
group by 1, 2
order by 1;
-- 두 기간 모두 완료, 취소, 환불 완료 주문이 많음
-- 이 세가지 이벤트가 일어난 주문 확인

# 특정 기간, 특정 이벤트
-- 이 기간동안의 매출
select order_date,
	sum(rev) as daily_rev
from
(select order_date,
	status,
    case when status in ('canceled', 'order_refunded') then total* -1
		else total
	end as rev
from sale_log.sales
where yearweek(order_date) in ('202051', '202117')
	and status in ('complete', 'canceled', 'order_refunded')) as a
group by 1
order by 1;
-- 2021년 17주차에는 적자만 발생함
-- 당시 취소된 주문이 완료된 주문보다 압도적으로 많은 것이 원인이라고 판단
-- 우선 취소된 주문부터 확인

# 2021년 17주차에 취소된 주문 확인
-- 취소된 상품들의 평균 할인율
select category,
	count(distinct cust_id) as cust_cnt,
    count(distinct order_id) as order_cnt,
    avg(discount_percent) as avg_discount
from sale_log.sales
where yearweek(order_date)= '202117'
	and status= 'canceled'
group by 1;
-- 시각화 결과, 할인율이 낮을 수록 취소를 많이 한 것을 확인함
-- 그럼 당시에 주문 취소를 가장 많이 한 고객은?

select full_name,
	cust_id,
    count(distinct order_id) as order_cnt
from sale_log.sales
where yearweek(order_date)= '202117'
	and status= 'canceled'
group by 1
order by 3 desc;
-- 무려 44번이나 취소한 사용자가 있음
-- 이 사람이 취소한 상품은?

select category,
	count(distinct order_id) as order_cnt
from sale_log.sales
where yearweek(order_date)= '202117'
	and status= 'canceled'
    and cust_id= '39707'
group by 1
order by 2 desc;
-- 휴대전화와 태블릿만 환불한 것을 확인함
-- 이 고객의 소비 추세를 확인하고 싶어짐

create temporary table beebe
select *
from sale_log.sales
where cust_id= '39707';

select min(order_date), max(order_date)
from beebe;
-- 최초주문일 : 2020-10-12 // 최근주문일 : 2021-09-29

-- 주차별 주문량
select yearweek(order_date),
	count(distinct order_id) as order_cnt
from beebe
group by 1
order by 1;
-- 주문이 있던 주에는 최소 2번 이상의 주문을 진행함
-- 주문 유형 별 횟수는?
select status,
	count(distinct order_id)
from beebe
group by 1
order by 2 desc;
-- 대부분이 주문 취소임
-- 어떤 상품을 구매했을까?
select category,
	status,
	count(distinct order_id) as order_cnt
from beebe
group by 1, 2;
-- 휴대폰, 태블릿만 주문함
-- 그 중 대부분은 취소 주문임

# Mobile & Tablets 상품 집중 분석
create temporary table mobile
select *
from sale_log.sales
where category= 'Mobiles & Tablets';

select status,
	count(distinct order_id) as order_cnt
from mobile
group by 1
order by 2 desc;