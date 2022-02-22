-- 1. ���̺� �����ϱ� ��Ű��&������
/*
CREATE TABLE ���θ������̺�� AS
SELECT * FROM ���������̺�� [WHERE ��]

> Ű�� ������� comment �� ����� ����.
*/
create table employees_1 as
select * from hr.employees
;

--select count(*) from employees_1 => 107

-- 2. ���̺� ������ �����ϱ�
/*
CREATE TABLE ���θ��鿡Ƽ��� AS
SELECT * FROM ���������̺�� WHERE 1=2 [where���� '��' �� �ƴ� ������ �־���]
*/
create table employees_2 as
select * from hr.employees where 1=2
;

-- 3. ���̺��� �̹� �����Ǿ� �ְ� �����͸� ���� (���̺� ������ ������ ��)
/*
INSERT INTO ���������̺�� SELECT * FROM ���̺�� [WHERE ��]
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
-- �̷��� �ϴ� value �� ũ�ٴ� ������ �߻�. sequence drop �� ���۾�.

-- 4. ���̺��� �̹� �����Ǿ� �ְ� �����͸� ���� (���̺� ������ �ٸ� ��)
/*
INSERT INTO ���������̺�� (NUM, TITLE, CONTENTS) SELECT NUM, TITLE, CONTENTS FROM ���̺��;
EX) INSERT INTO TB_BOARD_TEMP (NUM, TITLE, CONTENTS) SELECT NUM, TITLE, CONTENTS FROM TB_BOARD;
*/


-- 9. �������� ���̱׷��̼� �� ��, ������ �����ؼ� ������ �� ���� ������ ������ ����
--    ���߿��� ó������ �ʿ��� �����͸� �� �� �ְ���.
