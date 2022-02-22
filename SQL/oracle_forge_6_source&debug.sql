select table_name, tablespace_name, status, num_rows, -- num_rows, blocks, last_analyzed �� ��������� ������� ������ ���� �������.
    blocks, -- ���̺��� ���� ��� �� (����� ����Ŭ���� �������� �ּ� ���������)
    last_analyzed
  from user_tables
 order by table_name;

select table_name, column_name, data_type, data_length, data_precision, data_scale,
    nullable, column_id, data_default
  from user_tab_cols;
  
select owner, constraint_name,
    constraint_type, -- [C]: NOT NULL Ȥ�� CHECK, [P]: Primary key, [U]: Unique, [R]: Foreign key
    table_name,
    status
  from user_constraints;
  
select index_name,
    index_type, -- NORMAL, BITMAP, FUNCTION-BASED NORMAL, FUNCTION-BASED-BITMAP, DOMAIN
    table_name,
    uniqueness,
    num_rows,
    last_analyzed
  from user_indexes;
  
-- "COMMENT ON TABLE IS ~"
select table_name,
    table_type,
    comments
  from user_tab_comments;
  
-- "COMMENT ON COLUMN IS ~"
select *
  from user_col_comments;


select --*
    object_name,
    object_type, -- ��ü �������� FUNCTION, INDEX, PACKAGE, PACKAGE BODY, PROCEDURE, TABLE, TABLE PARTITION, TYPE
    created,
    last_ddl_time,
    status
  from user_objects
 order by object_type, object_name;
 
-- user_procedures -> ���ν����� �Լ��� ���� ������ ���� ��.
select object_name, -- ��Ű���� ���� �ִٸ� ��Ű����. ���������� �����Ѵٸ� �Լ� �� ���ν�����
    procedure_name, -- ��Ű���� ���� ������ �Լ��� ���ν�����. ���������� �����ϴ� �Լ��� ���ν����̸� NULL
    object_type, -- FUNCTION, PROCEDURE, PACKAGE
    pipelined, -- ���������� �Լ��̸� YES, �� �ܴ� NO
    overload -- �����ε�� ��쿡�� 1���� ������ �ο��ǰ� �� �ܴ� NULL
  from user_procedures
 order by object_name;
 
 -- user_arguments -> �Լ��� ���ν����� �Ű����� ������ ������ �ִ�.
 select object_name,
    package_name,
    argument_name,
    sequence,
    data_type,
    default_value, -- �Ű������� ����Ʈ ��. ������ null. ����Ʈ ���� ��� ��������?
    in_out -- IN, OUT, IN/OUT
   from user_arguments;
   
-- user_dependencies -> ��ü�� ���� �����ϴ� ������ ���� ���.
-- ���� ��� [CUSTOMERS] ���̺��� �����ϴ� ��ü��.
select name, -- �����ϴ� ��ü��
    type, -- �����ϴ� ��ü Ÿ��
    referenced_owner, -- �����Ǵ� ��ü�� ������
    referenced_name, -- �����Ǵ� ��ü��
    referenced_type -- �����Ǵ� ��ü Ÿ��
  from user_dependencies
 where referenced_name = 'CUSTOMERS'
;

-- ���ν���, �Լ�, ��Ű�� ���� ��� ���α׷��� �ҽ� ����
select
    name,
    type, -- PROCEDURE, FUNCTION, PACKAGE, PACKAGE BODY, TYPE
    line,
    text
  from user_source;
  
create or replace package ch17_src_test_pkg is
    ps_name varchar2(30) := 'CH17_SRC_TEST_PKG';
    
    procedure sales_detail_prc (
        ps_month IN varchar2,
        pn_amt IN number,
        pn_rate IN number
    );
    
end ch17_src_test_pkg;
/

create or replace package body ch17_src_test_pkg is
    ps_temp varchar2(30) := 'TEST';
    
    procedure sales_detail_prc (
        ps_month IN varchar2,
        pn_amt IN number,
        pn_rate IN number
    )
    IS
        vd_sysdate date; -- ��������
        vn_total_time number := 0; -- �ҿ�ð� ���� ����
        vn_total_time_2 number := 0; -- 1/100 ��
    begin
    
        dbms_output.put_line('---------------------------<������ ���>--------------------------');
        dbms_output.put_line('ps_month: ' || ps_month); -- 200112
        dbms_output.put_line('ps_amt: ' || ps_amt); -- 10000
        dbms_output.put_line('pn_rate: ' || pn_rate); -- 1
        dbms_output.put_line('----------------------------------------------------------------');
        
        -- delete �� vd_sysdate�� ����ð� ����
        vd_sysdate := sysdate;
        
        vn_total_time2 := dbms_utility.get_time;
        
        -- 1. p_month �� �ش��ϴ� ���� ch17_sales_detail ������ ����. ������ ������ ���� ���Ӱ� �ϱ� ���ؼ��̱�.
        delete ch17_sales_detail
         where sales_month = ps_month;
         
        dbms_output.put_line('DELTE �Ǽ�: ' || SQL%ROWCOUNT); -- 22698
        vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
        dbms_output.put_line('�ҿ�ð�: ' || vn_total_time);
        vn_total_time := (dbms_utility.get_time - vn_total_time_2) / 100;
        dbms_output.put_line('�ҿ�ð�: ' || vn_total_time2);
        
        -- 2. p_month �� �ش��ϴ� ���� ch17_sales_detail ������ ����
        
        vd_sysdate := sysdate;
        
        insert into ch17_sales_detail
        select b.prod_name,
            b.channel_desc,
            c.cust_name,
            e.emp_name,
            a.sales_date,
            a.sales_month,
            sum(a.quantity_sold),
            sum(a.amount_sold)
          from sales a,
            products b,
            customers c,
            channels d,
            employees e
         where a.prod_id = b.prod_id
           and a.cust_id = c.cust_id
           and a.channel_id = d.channel_id
           and a.employee_id = e.employee_id
           and a.sales_month = ps_month
         group by b.prod_name,
            d.channel_desc,
            c.cust_name,
            e.emp_name,
            a.sales_date,
            a.seles_month;
            
        dbms_ouptut.put_line('INSERT �Ǽ�: ' || sql%rowcount);
        vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
        dbms_output.put_line('�ҿ�ð�: ' || vn_total_time);
        -- 3. �Ǹűݾ�(sales_amt) �� pn_amt ���� ū ���� pn_rate ������ŭ ����
        update ch17_sales_detail
           set sales_amt = sales_amt - ( sales_amt * pn_rate * 0.01 )
         where sales_month = ps_month
           and sales_amt > pn_amt;
           
        dbms_ouptut.put_line('UPDATE �Ǽ�: ' || sql%rowcount); -- 0
           
        commit;
        
        dbms_output.put_line('���⼭�� ����???? : ' || sql%rowcount); -- 0 COMMIT �� ���� 0�̳�.
            
    exception when others then
        dbms_output.put_line(sqlerrm);
        rollback;
        
    end sales_detail_prc;
        
end ch17_src_test_pkg;
/

select *
  from user_source
 where name = 'CH17_SRC_TEST_PKG'
 order by type, line;
 
-- �Ϻη� [or] ������ ����Ѵ�.
select *
  from user_source
 where text like '%EMPLOYEES%'
    or text like '%employees%'
 order by name, type, line;
 
-- ���� ����ϴ� ����.

create table bk_source_20210411 as
select *
  from user_source
 order by name, type, line;
 
----------------------------------------------------------------
-- DEBUGGING
----------------------------------------------------------------

-- first create table and index

create table ch17_sales_detail (
    channel_name varchar2(50),
    prod_name varchar2(300),
    cust_name varchar2(100),
    emp_name varchar2(100),
    sales_date date,
    sales_month varchar2(6),
    sales_qty number default 0,
    sales_amt number default 0
);

create index ix_ch17_sales_detail_01 on ch17_sales_detail (sales_month);

