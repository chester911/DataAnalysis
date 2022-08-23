# 월별 신규 고객의 수
-- 월별 신규 / 기존 고객의 수
-- 신규 / 기존 고객의 1인당 평균 매출
with usr_type as
(select a.*,
	case when substr(a.invoiceDate, 1, 7)= b.first_order then 'new_user'
		else 'old_user'
	end as user_type
from
	(select *
	from retail) as a
    left join
			(select customerId,
				substr(min(invoiceDate), 1, 7) as first_order
			from retail
            group by 1
            order by 2) as b
		on a.customerId= b.customerId)
        
select substr(invoiceDate, 1, 7) as ym,
	user_type,
    count(distinct customerId) as user_cnt,
    sum(quantity* unitPrice) as rev,
    sum(quantity* unitPrice)/ count(distinct customerId) as ARPPU
from usr_type
group by 1, 2;
-- 두 고객군의 매출은 모두 감소하는 추세임
-- 기존 고객의 수는 지속적으로 증가함
-- 신규 고객의 수는 감소하는 추세임

-- 1. ARPPU는 왜 감소했을까?
-- 2011년 3월, 4월을 기준으로 살펴보기로 함 (기존, 신규 고객 모두)

-- ARPPU 감소 = 1인당 평균 매출 감소 = 고객 수 감소와는 큰 관련 없음
-- 한명이 주문한 금액이 줄었다?
-- 최대 매출 품목의 주문이 감소한 것 아닐까?

-- 3월 매출 상위 10개 상품의 주문량 변화 (주문 건수)
with rev_rnk_mar as
(select stockCode,
    row_number() over(order by sum(quantity* unitPrice) desc) as rnk
from retail
where substr(invoiceDate, 1, 7)= '2011-03'
group by 1)

select a.stockCode,
	-- 4월 수치가 3월 수치의 몇 %인가?
    b.order_cnt/ a.order_cnt* 100 as order_diff_ratio,
    b.cust_cnt/ a.cust_cnt* 100 as cust_diff_ratio
from
	(select stockCode,
		count(distinct invoiceNo) as order_cnt,
		count(distinct customerId) as cust_cnt
	from retail
	where substr(invoiceDate, 1, 7)= '2011-03'
		and stockCode in (select stockCode
						from rev_rnk_mar
						where rnk<= 10)
	group by 1
	order by 2 desc, 3 desc) as a
    left join
			(select stockCode,
				count(distinct invoiceNo) as order_cnt,
                count(distinct customerId) as cust_cnt
            from retail
            where substr(invoiceDate, 1, 7)= '2011-04'
            group by 1) as b
		on a.stockCode= b.stockCode
order by 2 desc, 3 desc;
-- 주문 수는 1개 상품을 제외하고 모두 감소함
-- 고객 수 역시 3개 상품을 제외하고 모두 감소함 (증가 2, 유지 1)
-- 의심했던 사항과 맞아떨어지는 수치를 보여줌
-- 이 수치를 신규 / 기존 고객으로 나눠서 확인할 수 있을까?

-- 고객 유형별 (신규 / 기존), 상품별 매출액 순위
-- 3월 신규 / 기존 고객 분류
with user_type_mar as
(select distinct a.customerId,
	case when substr(a.invoiceDate, 1, 7)= b.first_order then 'new_user'
		else 'old_user'
	end as user_type
from retail as a
	left join
			(select customerId,
				substr(min(invoiceDate), 1, 7) as first_order
			from retail
            group by 1
            order by 2) as b
		on a.customerId= b.customerId
where substr(invoiceDate, 1, 7)= '2011-03'
order by 1),

-- 상품의 고객 유형별 매출 순위
# 이 지표를 통해 신규 고객들이 선호하는 제품들도 알 수 있을 듯 함
-- 고객 유형별 매출 상위 10위 제품들의 판매량 변화
rev_rnk_user_type as
(select a.stockCode,
	b.user_type,
    sum(a.quantity* a.unitPrice) as rev,
    row_number() over(partition by b.user_type
					order by sum(a.quantity* a.unitPrice) desc) as rnk
from retail as a
	left join user_type_mar as b
		on a.customerId= b.customerId
where substr(a.invoiceDate, 1, 7)= '2011-03'
group by 1, 2)
-- 알고 싶은 것 : 기존 고객들의 매출 상위 10위 제품들의 주문 건수, 고객수 변화
-- 4월달 상품별 주문 건수, 고객 수가 3월달의 몇 %인지?
select a.stockCode,
	b.order_cnt/ a.order_cnt* 100 as orders_diff_ratio,
    b.cust_cnt/ a.cust_cnt* 100 as custs_diff_ratio
from
	(select stockCode,
		count(distinct invoiceNo) as order_cnt,
		count(distinct customerId) as cust_cnt
	from retail
	where substr(invoiceDate, 1, 7)= '2011-03'
		and customerId in (select customerId
						from user_type_mar
						where user_type= 'old_user')
		and stockCode in (select stockCode
						from rev_rnk_user_type
						where user_type= 'old_user'
							and rnk<= 10)
	group by 1
	order by 3 desc, 2 desc) as a
    left join
			(select stockCode,
				count(distinct invoiceNo) as order_cnt,
				count(distinct customerId) as cust_cnt
			from retail
			where substr(invoiceDate, 1, 7)= '2011-04'
				and customerId in (select customerId
								from
									(select distinct a.customerId,
											case when substr(a.invoiceDate, 1, 7)= b.first_order then 'new_user'
												else 'old_user'
											end as user_type
									from retail as a
										left join
												(select customerId,
														substr(min(invoiceDate), 1, 7) as first_order
												from retail
												group by 1
												order by 2) as b
											on a.customerId= b.customerId
									where substr(a.invoiceDate, 1, 7)= '2011-04') as a
									where user_type= 'old_user')
			group by 1) as b
		on a.stockCode= b.stockCode
order by 2 desc, 3 desc;
-- 전체 고객을 대상으로 한 수치와 같은 결과를 보임
-- 월별 매출 상위 제품과 이 제품들의 월별 주문 건수와 고객수를 지표로 삼아도 좋을 것 같음