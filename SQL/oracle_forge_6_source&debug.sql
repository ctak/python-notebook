select table_name, tablespace_name, status, num_rows, -- num_rows, blocks, last_analyzed 는 통계정보가 만들어진 다음에 값이 만들어짐.
    blocks, -- 테이블에서 사용된 블록 수 (블록은 오라클에서 데이터의 최소 저장단위임)
    last_analyzed
  from user_tables
 order by table_name;

select table_name, column_name, data_type, data_length, data_precision, data_scale,
    nullable, column_id, data_default
  from user_tab_cols;
  
select owner, constraint_name,
    constraint_type, -- [C]: NOT NULL 혹은 CHECK, [P]: Primary key, [U]: Unique, [R]: Foreign key
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
    object_type, -- 객체 유형으로 FUNCTION, INDEX, PACKAGE, PACKAGE BODY, PROCEDURE, TABLE, TABLE PARTITION, TYPE
    created,
    last_ddl_time,
    status
  from user_objects
 order by object_type, object_name;
 
-- user_procedures -> 프로시저와 함수에 대한 정보를 가진 뷰.
select object_name, -- 패키지에 속해 있다면 패키지명. 독립적으로 존재한다면 함수 및 프로시저명
    procedure_name, -- 패키지에 속해 있으면 함수나 프로시저명. 독립적으로 존재하는 함수나 프로시저이면 NULL
    object_type, -- FUNCTION, PROCEDURE, PACKAGE
    pipelined, -- 파이프라인 함수이면 YES, 그 외는 NO
    overload -- 오버로드된 경우에는 1부터 순번이 부여되고 그 외는 NULL
  from user_procedures
 order by object_name;
 
 -- user_arguments -> 함수나 프로시저의 매개변수 정보를 가지고 있다.
 select object_name,
    package_name,
    argument_name,
    sequence,
    data_type,
    default_value, -- 매개변수의 디폴트 값. 없으면 null. 디폴트 값을 어떻게 설정하지?
    in_out -- IN, OUT, IN/OUT
   from user_arguments;
   
-- user_dependencies -> 객체간 서로 참조하는 정보를 가진 뷰다.
-- 예를 들면 [CUSTOMERS] 테이블을 참조하는 객체는.
select name, -- 참조하는 객체명
    type, -- 참조하는 객체 타입
    referenced_owner, -- 참조되는 객체의 소유자
    referenced_name, -- 참조되는 객체명
    referenced_type -- 참조되는 객체 타입
  from user_dependencies
 where referenced_name = 'CUSTOMERS'
;

-- 프로시저, 함수, 패키지 등의 모든 프로그램의 소스 정보
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
        vd_sysdate date; -- 현재일자
        vn_total_time number := 0; -- 소요시간 계산용 변수
        vn_total_time_2 number := 0; -- 1/100 초
    begin
    
        dbms_output.put_line('---------------------------<변수값 출력>--------------------------');
        dbms_output.put_line('ps_month: ' || ps_month); -- 200112
        dbms_output.put_line('ps_amt: ' || ps_amt); -- 10000
        dbms_output.put_line('pn_rate: ' || pn_rate); -- 1
        dbms_output.put_line('----------------------------------------------------------------');
        
        -- delete 전 vd_sysdate에 현재시간 설정
        vd_sysdate := sysdate;
        
        vn_total_time2 := dbms_utility.get_time;
        
        -- 1. p_month 에 해당하는 월의 ch17_sales_detail 데이터 삭제. 실행할 때마다 값을 새롭게 하기 위해서이군.
        delete ch17_sales_detail
         where sales_month = ps_month;
         
        dbms_output.put_line('DELTE 건수: ' || SQL%ROWCOUNT); -- 22698
        vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
        dbms_output.put_line('소요시간: ' || vn_total_time);
        vn_total_time := (dbms_utility.get_time - vn_total_time_2) / 100;
        dbms_output.put_line('소요시간: ' || vn_total_time2);
        
        -- 2. p_month 에 해당하는 월의 ch17_sales_detail 데이터 생성
        
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
            
        dbms_ouptut.put_line('INSERT 건수: ' || sql%rowcount);
        vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
        dbms_output.put_line('소요시간: ' || vn_total_time);
        -- 3. 판매금액(sales_amt) 이 pn_amt 보다 큰 건은 pn_rate 비율만큼 할인
        update ch17_sales_detail
           set sales_amt = sales_amt - ( sales_amt * pn_rate * 0.01 )
         where sales_month = ps_month
           and sales_amt > pn_amt;
           
        dbms_ouptut.put_line('UPDATE 건수: ' || sql%rowcount); -- 0
           
        commit;
        
        dbms_output.put_line('여기서의 값은???? : ' || sql%rowcount); -- 0 COMMIT 의 값은 0이네.
            
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
 
-- 일부러 [or] 조건을 사용한다.
select *
  from user_source
 where text like '%EMPLOYEES%'
    or text like '%employees%'
 order by name, type, line;
 
-- 매일 백업하는 문장.

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

