set serveroutput on;

-- ���α׷��� ������ ��.
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

-- ���α׷��� ���� ��.
declare
    vn_log_id number := 1;
begin
    dbms_output.put_line('log_id: ' || vn_log_id);
    no_pkg_mig.prg_end (
        vn_log_id, 
        'log desc: ���� �� ������.' );
end;
/

-- ���α׷��� ������ �� ��.
declare
    vn_log_id number := 3;
begin
    dbms_output.put_line('log_id: ' || vn_log_id);
    no_pkg_mig.prg_error (
        vn_log_id, 
        'log desc: ���� ���̾� �̰�!!!' );
end;
/

-- ���̺� copy �׽�Ʈ�� ����.

create table bk_asm_source_20210415_v2 as select * from bk_asm_source_20210415 where 1=2;
truncate table bk_asm_source_20210415_v2;
select count(1) from bk_asm_source_20210415_v2;
drop table bk_asm_source_20210415_v2 cascade constraints;

select count(1) from legerp_tb_cics; -- 1500�� ��.
create table legerp_tb_cics_v2 as select * from legerp_tb_cics where 1=2; -- 1500�� ��. 3�� 10��.

set serveroutput on;

begin
    no_pkg_mig.copy_table (
        'legerp_tb_cics',
        'legerp_tb_cics_v2' );
end;
/

----------------------------------------------------------------

select count(1) from legerp_tb_cics; -- 1500�� ��.
create table legerp_tb_cics_v3 as select * from legerp_tb_cics where 1=2; -- 1500�� ��. 67��.

set serveroutput on;

-- /*+ APPEND */ �� �� ��.,
begin
    no_pkg_mig.copy_table_2 (
        'legerp_tb_cics',
        'legerp_tb_cics_v3' );
end;
/

select count(1) from legerp_tb_cics@DBL_SALES; -- 1500����. 4�� 18��. ������ �ʾ�.
-- @DBL_SALES ���� MEMS ����.
-- /*+ APPEND */ �� �� ��.,
begin
    no_pkg_mig.copy_table_2 (
        'legerp_tb_cics@DBL_SALES',
        'legerp_tb_cics' );
end;
/


----------------------------------------------------------------

select count(1) from legerp_tb_cics; -- 1500�� ��.
create table legerp_tb_cics_v4 as select * from legerp_tb_cics where 1=2; -- 1500�� ��. APPEND hint( 4core => 74��. 8core => 81��. 2core => 46��. 60��. )
create table legerp_tb_cics_v5 as select * from legerp_tb_cics where 1=2;
create table legerp_tb_cics_v6 as select * from legerp_tb_cics where 1=2; -- APPEND ���� 2core => 66.6��. 4core => 40��. 49.4��. 8core => 87��.
select count(1) from legerp_tb_cics_v6;
truncate table legerp_tb_cics_v6;

-- PARALLEL DML
begin
    no_pkg_mig.copy_table_3 (
        'legerp_tb_cics',
        'legerp_tb_cics_v6' );
end;
/

-- ���� MEM ���� ������ ����.
-- ����� ���ݿ��� ������ ���� PARALELL �� ����, LOCAL ���� ������ ���� PARALLEL �� ����.
select count(1) from legerp_tb_cics@DBL_SALES;
create table legerp_tb_cics_v2 as select * from legerp_tb_cics@DBL_SALES where 1=2;
create table legerp_tb_cics_v3 as select * from legerp_tb_cics@DBL_SALES where 1=2;
-- @DBL_SALES ���� MEMS ����.
-- /*+ APPEND */ �� �� ��.,
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
