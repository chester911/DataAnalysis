# 대시보드로 시각화 이후
# 체포 건수가 일정 기간을 간격으로 급격히 증감하는 패턴을 반복하는 것을 확인함

select *
from arrest.arrest
limit 100;

-- 전일 대비 체포 건수가 100건 이상 증가한 일자의 데이터 추출
create temporary table rising_date
with daily_cnt as
(select *,
	lag(arrest_cnt, 1) over(order by arrest_date) as prev_cnt
from
(select arrest_date,
	count(distinct arrest_key) as arrest_cnt
from arrest.arrest
group by 1
order by 1) as a )

select *
from arrest.arrest
where arrest_date in
(select arrest_date
from daily_cnt
where arrest_cnt- prev_cnt>= 100)
order by arrest_date;

-- 우선 범죄 분류부터 파악
-- 중범죄인지 경범죄인지
select law_cat_cd,
	count(distinct arrest_key) as arrest_cnt
from rising_date
group by 1
order by 2 desc;
-- 경범죄가 가장 많고 그 다음이 중범죄임
-- 단순 위반 범죄는 적음

-- 범죄 세부 분류별 체포 건수
select law_cat_cd,
	ofns_desc as 'description',
    count(distinct arrest_key) as arrest_cnt
from rising_date
group by 1, 2
order by 3 desc;
-- 경, 중범죄 모두 폭행이 가장 많이 발생함
-- 그 다음으로는 절도와 각종 형법상 체포가 가장 많았음

-- 데이터를 다시 보니 약 1주일 간격으로 범죄가 급증함
-- 해당 기간 매 주 범죄를 제일 많이 저지를 지역
select `week`,
	region,
    arrest_cnt
from
(select yearweek(arrest_date) as 'week',
	arrest_boro as 'region',
    count(distinct arrest_key) as arrest_cnt,
    rank() over(partition by yearweek(arrest_date) order by count(distinct arrest_key) desc) as rnk
from rising_date
group by 1, 2
order by 1) as a
where rnk= 1;
-- K (브루클린)에서 이러한 현상이 가장 많이 발생함

select ofns_desc as 'description',
	count(distinct arrest_key) as arrest_cnt
from rising_date
where arrest_boro= 'K'
group by 1
order by 2 desc;