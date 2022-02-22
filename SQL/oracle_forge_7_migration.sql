set serveroutput on;

-- 프로그램을 시작할 때.
declare
    vn_log_id number;
begin
    vn_log_id := no_prg_log_seq.NEXTVAL;
    dbms_output.put_line('log_id: ' || vn_log_id);
    no_pkg_mig.prg_start (
        vn_log_id, 
        '2nd. hello world!', 
        'params -> null' );
end;
/

-- 프로그램을 끝낼 때.
declare
    vn_log_id number := 1;
begin
    dbms_output.put_line('log_id: ' || vn_log_id);
    no_pkg_mig.prg_end (
        vn_log_id, 
        'log desc: 아주 잘 끝났네.' );
end;
/

-- 프로그램이 에러가 날 때.
declare
    vn_log_id number := 3;
begin
    dbms_output.put_line('log_id: ' || vn_log_id);
    no_pkg_mig.prg_error (
        vn_log_id, 
        'log desc: 무슨 일이야 이거!!!' );
end;
/

-- 테이블 copy 테스트를 위해.

create table bk_asm_source_20210415_v2 as select * from bk_asm_source_20210415 where 1=2;
truncate table bk_asm_source_20210415_v2;
select count(1) from bk_asm_source_20210415_v2;
drop table bk_asm_source_20210415_v2 cascade constraints;

select count(1) from legerp_tb_cics; -- 1500만 건.
create table legerp_tb_cics_v2 as select * from legerp_tb_cics where 1=2; -- 1500만 건. 3분 10초.

set serveroutput on;

begin
    no_pkg_mig.copy_table (
        'legerp_tb_cics',
        'legerp_tb_cics_v2' );
end;
/

----------------------------------------------------------------

select count(1) from legerp_tb_cics; -- 1500만 건.
create table legerp_tb_cics_v3 as select * from legerp_tb_cics where 1=2; -- 1500만 건. 67초.

set serveroutput on;

-- /*+ APPEND */ 로 할 시.,
begin
    no_pkg_mig.copy_table_2 (
        'legerp_tb_cics',
        'legerp_tb_cics_v3' );
end;
/

select count(1) from legerp_tb_cics@DBL_SALES; -- 1500만건. 4분 18초. 나쁘지 않아.
-- @DBL_SALES 에서 MEMS 으로.
-- /*+ APPEND */ 로 할 시.,
begin
    no_pkg_mig.copy_table_2 (
        'legerp_tb_cics@DBL_SALES',
        'legerp_tb_cics' );
end;
/


----------------------------------------------------------------

select count(1) from legerp_tb_cics; -- 1500만 건.
create table legerp_tb_cics_v4 as select * from legerp_tb_cics where 1=2; -- 1500만 건. APPEND hint( 4core => 74초. 8core => 81초. 2core => 46초. 60초. )
create table legerp_tb_cics_v5 as select * from legerp_tb_cics where 1=2;
create table legerp_tb_cics_v6 as select * from legerp_tb_cics where 1=2; -- APPEND 빼고 2core => 66.6초. 4core => 40초. 49.4초. 8core => 87초.
select count(1) from legerp_tb_cics_v6;
truncate table legerp_tb_cics_v6;

-- PARALLEL DML
begin
    no_pkg_mig.copy_table_3 (
        'legerp_tb_cics',
        'legerp_tb_cics_v6' );
end;
/

-- 이제 MEM 에서 실행해 보자.
-- 결론은 원격에서 가져올 때는 PARALELL 을 끄고, LOCAL 에서 실행할 때는 PARALLEL 을 켜자.
select count(1) from legerp_tb_cics@DBL_SALES;
create table legerp_tb_cics_v2 as select * from legerp_tb_cics@DBL_SALES where 1=2;
create table legerp_tb_cics_v3 as select * from legerp_tb_cics@DBL_SALES where 1=2;
-- @DBL_SALES 에서 MEMS 으로.
-- /*+ APPEND */ 로 할 시.,
begin
    no_pkg_mig.copy_table_2 (
        'legerp_tb_cics@DBL_SALES',
        'legerp_tb_cics_v3' );
end;
/


----------------------------------------------------------------

-- CTAS

select * from bk_program_log order by 1 desc;
-- ORA-01031: insufficient privileges

set serveroutput on;

begin
    no_pkg_mig.ctas_table (
        'employees', -- from
        'employees_4' ); -- to
end;
/

select count(1) from employees; -- 108
select count(1) from employees_4;
