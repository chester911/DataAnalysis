use onlineretail;

# 코호트 단위 결정 -> 첫 구매 일자 계산 -> 코호트 인덱스 계산(첫 구매 일자와 원본에서의 구매 날짜의 차이)
# 				-> 코호트 그룹 계산(첫 구매 날짜를 그룹지어줌) -> 코호트 그룹별, 코호트 인덱스별 유저 수 집계

# 코호트 단위 구하기 --> 월별

# 코호트 인덱스 구하기
-- 1. 고객별 첫 구매 일자
select customerid,
	date(min(invoicedate)) as first_order
from retail
group by 1;

-- 2. 첫 구매 일자와 원본 데이터 합치기
with first_order as
(select customerid,
	date(min(invoicedate)) as first_order
from retail
group  by 1)
-- 첫 구매 날짜와 주문 날짜의 차이 계산
select a.*,
	b.first_order,
    abs(timestampdiff(month, a.invoicedate, b.first_order)) as cohort_index
from retail as a
	left join first_order as b
		on a.customerid= b.customerid;

# 코호트 그룹 만들기
-- 1.같은 달에 첫 구매한 고객끼리 묶어주기
with first_order as
(select customerid,
	date(min(invoicedate)) as first_order
from retail
group by 1)

select a.*,
	b.first_order,
    abs(timestampdiff(month, a.invoicedate, b.first_order)) as cohort_index,
    date_format(b.first_order, '%Y%m') as cohort_group
from retail as a
	left join first_order as b
		on a.customerid= b.customerid;

-- 2. 코호트 그룹별, 인덱스별 해당 고객수 확인
with first_order as
(select customerid,
	date(min(invoicedate)) as first_order
from retail
group by 1)

select f.cohort_group,
	f.cohort_index,
    count(distinct customerid) as customer_cnt
from
(select a.*,
	b.first_order,
    abs(timestampdiff(month, a.invoicedate, b.first_order)) as cohort_index,
    date_format(b.first_order, '%Y%m') as cohort_group
from retail as a
	left join first_order as b
		on a.customerid= b.customerid) as f
group by 1, 2;