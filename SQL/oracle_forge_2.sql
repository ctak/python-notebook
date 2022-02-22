-- 1. 테이블 복사하기 스키아&데이터
/*
CREATE TABLE 새로만들테이블명 AS
SELECT * FROM 복사할테이블명 [WHERE 절]

> 키가 사라지고 comment 가 사라져 있음.
*/
create table employees_1 as
select * from hr.employees
;

--select count(*) from employees_1 => 107

-- 2. 테이블 구조만 복사하기
/*
CREATE TABLE 새로만들에티블명 AS
SELECT * FROM 복사할테이블명 WHERE 1=2 [where절에 '참' 이 아닌 조건을 넣어줌]
*/
create table employees_2 as
select * from hr.employees where 1=2
;

-- 3. 테이블은 이미 생성되어 있고 데이터만 복사 (테이블 구조가 동일할 때)
/*
INSERT INTO 복사할테이블명 SELECT * FROM 테이블명 [WHERE 절]
ex) insert into tb_board_temp select * from tb_board;
*/
create table employees_3 as
select * from hr.employees where 1=2;

CREATE SEQUENCE SEQ_EMPLOYEES_01
INCREMENT BY 1
START WITH 100001
;

DROP SEQUENCE SEQ_EMPLOYEES_01;

insert into employees_3 
select seq_employees_01.nextval as employee_id,
first_name,
last_name,
email,
phone_number,
hire_date,
job_id,
salary,
commission_pct,
manager_id,
department_id
from hr.employees
;
-- 이렇게 하니 value 가 크다는 에러가 발생. sequence drop 후 재작업.

-- 4. 테이블은 이미 생성되어 있고 데이터만 복사 (테이블 구조가 다를 때)
/*
INSERT INTO 복사할테이블명 (NUM, TITLE, CONTENTS) SELECT NUM, TITLE, CONTENTS FROM 테이블명;
EX) INSERT INTO TB_BOARD_TEMP (NUM, TITLE, CONTENTS) SELECT NUM, TITLE, CONTENTS FROM TB_BOARD;
*/


-- 9. 영수증을 마이그레이션 할 때, 역으로 생각해서 영수증 을 찍을 때부터 생각한 다음
--    나중에는 처음부터 필요한 데이터를 알 수 있겠지.
