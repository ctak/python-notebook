create table emp_bulk (
    bulk_id         number          not null,
    employee_id     number(6)       not null,
    emp_name        varchar2(80)    not null,
    email           varchar2(50),
    phone_number    varchar2(30),
    hire_date       date            not null,
    salary          number(8,2),
    manager_id      number(6),
    commission_pct  number(2,2),
    retire_date     date,
    department_id   number(6),
    job_id          varchar2(10),
    dep_name        varchar2(100),
    job_title       varchar2(80)
);

begin
    for i in 1..10000
    loop
        insert into emp_bulk
            ( bulk_id,
              employee_id, emp_name, email,
              phone_number, hire_date, salary, manager_id,
              commission_pct, retire_date, department_id, job_id )
        select i,
            employee_id, emp_name, email,
            phone_number, hire_date, salary, manager_id,
            commission_pct, retire_date, department_id, job_id
        from
            employees;
    end loop;
    
    commit;
end;
/

select count(*) from emp_bulk; -- 1,080,000

set serveroutput on;

declare
    -- Ŀ�� ����
    cursor c1 is
    select employee_id from emp_bulk;
    
    vn_cnt number := 0;
    vn_emp_id number;
    vd_sysdate date;
    vn_total_time number := 0;
begin
    -- ���� �� vd_sysdate �� ����ð� ����
    vd_sysdate := sysdate;
    
    open c1;
    
    loop
        fetch c1 into vn_emp_id;
        exit when c1%NOTFOUND OR c1%NOTFOUND IS NULL;
        
        -- ���� Ƚ��
        vn_cnt := vn_cnt + 1;
    end loop;
    
    close c1;
    
    -- �� �ҿ�ð� ���(�ʷ� ����ϱ� ���� 60 * 60 * 24�� ����)
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    -- ���� Ƚ�� ���
    dbms_output.put_line('��ü�Ǽ�: ' || vn_cnt);
    -- �� �ҿ�ð� ���
    dbms_output.put_line('�ҿ�ð�: ' || vn_total_time);
end;
/

-- �ᱹ�� ���̺� ���� ������ ����϶�� ���ΰ�.

declare
    -- Ŀ�� ����
    cursor c1 is
    select employee_id from emp_bulk;
    
    -- �÷���Ÿ�� ����
    TYPE bkEmpTP is table of emp_bulk.employee_id%type;
    -- bkEmpTP ���� ����
    vnt_bkEmpTP bkEmpTP;
    
    vd_sysdate date;
    vn_total_time number := 0;
begin
    -- ���� �� vd_sysdate �� ����ð� ����
    vd_sysdate := sysdate;
    
    open c1;
    
    -- ������ ������ �ʴ´�.
    fetch c1 bulk collect into vnt_bkEmpTP;
    
    close c1;
    
    -- �� �ҿ�ð� ���(�ʷ� ����ϱ� ���� 60 * 60 * 24�� ����)
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    -- �÷��� ������ vnt_bkEmpTP ��� ���� ���
    dbms_output.put_line('��ü�Ǽ�: ' || vnt_bkEmpTP.COUNT);
    -- �� �ҿ�ð� ���
    dbms_output.put_line('�ҿ�ð�: ' || vn_total_time);
end;
/

select min(bulk_id), max(bulk_id), count(*)
  from emp_bulk;
  
create index ix_emp_bulk_01 on emp_bulk (bulk_id);

-- ��� ������ �־�� ����Ŭ ��Ƽ�������� SQL���� �� �� ȿ�������� ������ �� �ֱ� �����̴�.
execute dbms_stats.gather_table_stats('FORGE', 'emp_bulk');

-- ���� �Ϲ����� Ŀ���� for ���� Ȱ���� �����͸� ������ ����.

declare
    -- Ŀ�� ����
    cursor c1 is
    select distinct bulk_id
        from emp_bulk;
        
    -- �÷��� Ÿ�� ����
    type BulkIDTP is table of emp_bulk.bulk_id%type;
    
    -- BulkdIDTP�� ���� ����
    vnt_BulkID BulkIDTP;
    
    vd_sysdate date;
    vn_total_time number := 0;
begin
    -- ���� �� vd_sysdate�� ����ð� ����
    vd_sysdate := sysdate;
    
    open c1;
    
    -- bulk collect ���� ����� vnt_BulkID ������ ������ ���
    -- �հ� ������Ʈ�� ��뷮 ���̺� ġ�� ���ؼ��� ���� ����� ���� ���� �ʿ䰡 �ְڱ�.
    fetch c1 bulk collect into vnt_BulkID;
    
    -- ������ ���� update
    for i in 1..vnt_BulkID.count
    loop
        update emp_bulk
           set retire_date = hire_date
         where bulk_id = vnt_BulkID(i); -- 1 ���� idx
    end loop;
    
    commit;
    
    close c1;
    
    -- �� �ҿ� �ð� ��� (�ʷ� ����ϱ� ���� 60 * 60 * 24 �� ����)
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    -- �÷��� ������ vnt_BulkID ��� ���� ���
    dbms_output.put_line('��ü�Ǽ�: ' || vnt_BulkID.count);
    -- �� �ҿ�ð� ���
    dbms_output.put_line('FOR LOOP �ҿ� �ð�: ' || vn_total_time);
end;
/

declare
    -- Ŀ�� ����
    cursor c1 is
    select distinct bulk_id
        from emp_bulk;
        
    -- �÷��� Ÿ�� ����
    type BulkIDTP is table of emp_bulk.bulk_id%type;
    
    -- BulkdIDTP�� ���� ����
    vnt_BulkID BulkIDTP;
    
    vd_sysdate date;
    vn_total_time number := 0;
begin
    -- ���� �� vd_sysdate�� ����ð� ����
    vd_sysdate := sysdate;
    
    open c1;
    
    -- bulk collect ���� ����� vnt_BulkID ������ ������ ���
    -- �հ� ������Ʈ�� ��뷮 ���̺� ġ�� ���ؼ��� ���� ����� ���� ���� �ʿ䰡 �ְڱ�.
    fetch c1 bulk collect into vnt_BulkID;
    
    -- ������ ������ �ʰ� update
    forall i in 1..vnt_BulkID.count
        update emp_bulk
           set retire_date = hire_date
         where bulk_id = vnt_BulkID(i);
    
    commit;
    
    close c1;
    
    -- �� �ҿ� �ð� ��� (�ʷ� ����ϱ� ���� 60 * 60 * 24 �� ����)
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    -- �÷��� ������ vnt_BulkID ��� ���� ���
    dbms_output.put_line('��ü�Ǽ�: ' || vnt_BulkID.count);
    -- �� �ҿ�ð� ���
    dbms_output.put_line('FORALL �ҿ� �ð�: ' || vn_total_time);
end;
/

----------------------------------------------------------------
-- �Լ� ���� ���
----------------------------------------------------------------

create or replace function fn_get_depname_normal( pv_dept_id varchar2 )
    return varchar2
is
    vs_dep_name departments.department_name%type;
begin

    select department_name
      into vs_dep_name
      from departments
     where department_id = pv_dept_id;
     
    return vs_dep_name;
    
exception when others then
    return '';
end;
/

declare
    vn_cnt number := 0;
    vd_sysdate date;
    vn_total_time number := 0;
begin

    vd_sysdate := sysdate;
    
    -- dep_name Į���� �μ����� ������ ����
    update emp_bulk
       set dep_name = fn_get_depname_normal( department_id )
     where bulk_id between 1 and 1000;
     
    vn_cnt := SQL%ROWCOUNT;
    
    commit;
    
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    dbms_output.put_line('update �Ǽ� : ' || vn_cnt);
    dbms_output.put_line('�ҿ� �ð� : ' || vn_total_time);
    
end;
/

select department_id, dep_name, count(*)
  from emp_bulk
 where bulk_id between 1 and 1000
 group by department_id, dep_name
 order by department_id, dep_name;
 
-- RESULT_CHACHE �Լ� ���
create or replace function fn_get_depname_rsltcache( pv_dept_id varchar2 )
    return varchar2
    RESULT_CACHE
    RELIES_ON ( DEPARTMENTS ) -- (���� ���̺�1, ...)
IS
    vs_dep_name departments.department_name%type;
begin

    select department_name
      into vs_dep_name
      from departments
     where department_id = pv_dept_id;
     
    return vs_dep_name;
    
exception when others then
    return '';
    
end;
/

declare
    vn_cnt number := 0;
    vd_sysdate date;
    vn_total_time number := 0;
begin

    vd_sysdate := sysdate;
    
    -- dep_name Į���� �μ����� ������ ����
    update emp_bulk
       set dep_name = fn_get_depname_rsltcache( department_id )
     where bulk_id between 1 and 1000;
     
    vn_cnt := SQL%ROWCOUNT;
    
    commit;
    
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    dbms_output.put_line('update �Ǽ� : ' || vn_cnt);
    dbms_output.put_line('�ҿ� �ð� : ' || vn_total_time);
    
end;
/

select * from v$result_cache_statistics;

show parameter result_cache_max_size;

show parameter result_csche_mode;

----------------------------------------------------------------
-- �ٽ�����
----------------------------------------------------------------

-- 1. Ŀ���� ������ ����ؼ� ó���� �� BULK COLLECT ���� ����ϸ� ������ ũ�� ���ȴ�.
-- 2. Ŀ���� ������ ����� ���� ������ DML���� ������ �� FORALL ���� ����ϸ� ������ ��������. (������)
-- 3. �뷮�� �����͸� ��ȸ�� �� �Լ��� ����ϸ� ������ �ɰ��ϰ� ���ϵȴ�.
-- 4. ����Ŭ 11g���ʹ� �Լ��� ������ �� result cache ������� ���� ��� ȿ���� �� �� �ִ�.
-- 5. result cache�� ����� ĳ�ÿ� ������ ���ٰ� �ٽ� ������ �Ű������� ���޵� �� �Լ� ������ ó������ �ʰ� ĳ�ÿ� ����� ��� ���� �����ϴ� ���� ���Ѵ�.
-- 6. result cache ����� ����������, �뷮�� �����͸� ��ȸ�� ���� �Լ� ��� ������ �������.
-- 7. ���� ó���� �ϸ� ������ �ش�ȭ�� �� ������ ���� ó������ ���� ������ ���� DML �� �ִ�.
-- 8. ���� ������ ALTER SESSION ��ɾ �����ϴ� ����� PARALLEL ��Ʈ�� ����ϴ� ����� �ִ�.
-- 9. ���� DML�� ALTER SESSION ��ɾ�� ó���� �� ������ ������ ���� ������ �Բ� ���ȴ�.
-- 10. ���� ó���� �ʿ��� ���� ����ϴ� ���� ������ �����ϸ� ������ �������ϸ� �ʷ��Ѵ�.

-- # AutoCommit �� [OFF] ���� �ϰ�, sql ���� [commit;] �� �ٿ��� �Ѵ�.
-- * https://www.phpschool.com/gnuboard4/bbs/board.php?bo_table=qna_db&wr_id=211629&page=181
-- * http://1004lucifer.blogspot.com/2016/07/sql-developer-sql.html
-- * �ϳ��� dml�� �ȿ��� �����ڰ� ������ ���� �󸶳� �ǹ̰� ������?

-- # INSERT �� index �� ����.
-- * �ϴ��� index ���� �־��.
-- * http://www.gurubee.net/lecture/2285

