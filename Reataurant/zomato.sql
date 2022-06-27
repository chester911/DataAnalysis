use restaurant;
# 데이터 살펴보기
select *
from zomato;

-- 평점 종류
select `rating color`, count(`rating color`) as cnt,
	`rating text`, count(`rating text`) as text_cnt
from zomato
group by 1, 3;

# 지역별 평점
-- 평균 평점
select city,
	avg(longitude) as 'long',
    avg(latitude) as 'lat',
	avg(`aggregate rating`) as 'rating'
from zomato
group by 1
order by 4 desc;
-- 지역별 평점 종류
select city,
	avg(longitude) as 'long',
    avg(latitude) as 'lat',
	`rating text`,
	count(`restaurant name`) as cnt
from zomato
group by 1, 4
order by 1;

# 매장별 가격대 (2인기준)
-- 통화 통일 (달러)
select distinct currency
from zomato;

select `restaurant name` as 'restaurant',
	cuisines,
	city,
	longitude, latitude,
    case when currency like 'Botswana%' then `average cost for two`* 0.082
		when currency like 'Brazilian%' then `average cost for two`* 0.19
        when currency like 'Emirati%' then `average cost for two`* 0.27
        when currency like 'Indian%' then `average cost for two`* 0.013
        when currency like 'Indonesian%' then `average cost for two`* 0.000068
        when currency like 'NewZealand%' then `average cost for two`* 0.63
        when currency like 'Pounds%' then `average cost for two`* 1.23
        when currency like 'Qatari%' then `average cost for two`* 0.27
        when currency like 'Rand%' then `average cost for two`* 0.063
        when currency like 'Sri%' then `average cost for two`* 0.0028
        when currency like 'Turkish%' then `average cost for two`* 0.062
        else `average cost for two`
        end as 'price',
        `aggregate rating`
from zomato;

select *
from zomato;