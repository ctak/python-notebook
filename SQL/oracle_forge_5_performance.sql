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
    -- 커서 선언
    cursor c1 is
    select employee_id from emp_bulk;
    
    vn_cnt number := 0;
    vn_emp_id number;
    vd_sysdate date;
    vn_total_time number := 0;
begin
    -- 시작 전 vd_sysdate 에 현재시간 설정
    vd_sysdate := sysdate;
    
    open c1;
    
    loop
        fetch c1 into vn_emp_id;
        exit when c1%NOTFOUND OR c1%NOTFOUND IS NULL;
        
        -- 루프 횟수
        vn_cnt := vn_cnt + 1;
    end loop;
    
    close c1;
    
    -- 총 소요시간 계산(초로 계산하기 위해 60 * 60 * 24을 곱함)
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    -- 루프 횟수 출력
    dbms_output.put_line('전체건수: ' || vn_cnt);
    -- 총 소요시간 출력
    dbms_output.put_line('소요시간: ' || vn_total_time);
end;
/

-- 결국은 테이블에 넣은 다음에 계산하라는 말인가.

declare
    -- 커서 선언
    cursor c1 is
    select employee_id from emp_bulk;
    
    -- 컬렉션타입 선언
    TYPE bkEmpTP is table of emp_bulk.employee_id%type;
    -- bkEmpTP 변수 선언
    vnt_bkEmpTP bkEmpTP;
    
    vd_sysdate date;
    vn_total_time number := 0;
begin
    -- 시작 전 vd_sysdate 에 현재시간 설정
    vd_sysdate := sysdate;
    
    open c1;
    
    -- 루프를 돌리지 않는다.
    fetch c1 bulk collect into vnt_bkEmpTP;
    
    close c1;
    
    -- 총 소요시간 계산(초로 계산하기 위해 60 * 60 * 24을 곱함)
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    -- 컬렉션 변수인 vnt_bkEmpTP 요소 개수 출력
    dbms_output.put_line('전체건수: ' || vnt_bkEmpTP.COUNT);
    -- 총 소요시간 출력
    dbms_output.put_line('소요시간: ' || vn_total_time);
end;
/

select min(bulk_id), max(bulk_id), count(*)
  from emp_bulk;
  
create index ix_emp_bulk_01 on emp_bulk (bulk_id);

-- 통계 정보가 있어야 오라클 옵티마이저가 SQL문을 좀 더 효율적으로 실행할 수 있기 때문이다.
execute dbms_stats.gather_table_stats('FORGE', 'emp_bulk');

-- 먼저 일반적인 커서와 for 문을 활용해 데이터를 갱신해 보자.

declare
    -- 커서 선언
    cursor c1 is
    select distinct bulk_id
        from emp_bulk;
        
    -- 컬렉션 타입 선언
    type BulkIDTP is table of emp_bulk.bulk_id%type;
    
    -- BulkdIDTP형 변수 선언
    vnt_BulkID BulkIDTP;
    
    vd_sysdate date;
    vn_total_time number := 0;
begin
    -- 시작 전 vd_sysdate에 현재시간 설정
    vd_sysdate := sysdate;
    
    open c1;
    
    -- bulk collect 절을 사용해 vnt_BulkID 변수에 데이터 담기
    -- 먼가 업데이트를 대용량 테이블에 치기 위해서는 먼저 대상대는 값을 뽑을 필요가 있겠군.
    fetch c1 bulk collect into vnt_BulkID;
    
    -- 루프를 돌며 update
    for i in 1..vnt_BulkID.count
    loop
        update emp_bulk
           set retire_date = hire_date
         where bulk_id = vnt_BulkID(i); -- 1 부터 idx
    end loop;
    
    commit;
    
    close c1;
    
    -- 총 소요 시간 계산 (초로 계산하기 위해 60 * 60 * 24 을 곱함)
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    -- 컬렉션 변수인 vnt_BulkID 요소 개수 출력
    dbms_output.put_line('전체건수: ' || vnt_BulkID.count);
    -- 총 소요시간 출력
    dbms_output.put_line('FOR LOOP 소요 시간: ' || vn_total_time);
end;
/

declare
    -- 커서 선언
    cursor c1 is
    select distinct bulk_id
        from emp_bulk;
        
    -- 컬렉션 타입 선언
    type BulkIDTP is table of emp_bulk.bulk_id%type;
    
    -- BulkdIDTP형 변수 선언
    vnt_BulkID BulkIDTP;
    
    vd_sysdate date;
    vn_total_time number := 0;
begin
    -- 시작 전 vd_sysdate에 현재시간 설정
    vd_sysdate := sysdate;
    
    open c1;
    
    -- bulk collect 절을 사용해 vnt_BulkID 변수에 데이터 담기
    -- 먼가 업데이트를 대용량 테이블에 치기 위해서는 먼저 대상대는 값을 뽑을 필요가 있겠군.
    fetch c1 bulk collect into vnt_BulkID;
    
    -- 루프를 돌리지 않고 update
    forall i in 1..vnt_BulkID.count
        update emp_bulk
           set retire_date = hire_date
         where bulk_id = vnt_BulkID(i);
    
    commit;
    
    close c1;
    
    -- 총 소요 시간 계산 (초로 계산하기 위해 60 * 60 * 24 을 곱함)
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    -- 컬렉션 변수인 vnt_BulkID 요소 개수 출력
    dbms_output.put_line('전체건수: ' || vnt_BulkID.count);
    -- 총 소요시간 출력
    dbms_output.put_line('FORALL 소요 시간: ' || vn_total_time);
end;
/

----------------------------------------------------------------
-- 함수 성능 향상
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
    
    -- dep_name 칼럼에 부서명을 가져와 갱신
    update emp_bulk
       set dep_name = fn_get_depname_normal( department_id )
     where bulk_id between 1 and 1000;
     
    vn_cnt := SQL%ROWCOUNT;
    
    commit;
    
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    dbms_output.put_line('update 건수 : ' || vn_cnt);
    dbms_output.put_line('소요 시간 : ' || vn_total_time);
    
end;
/

select department_id, dep_name, count(*)
  from emp_bulk
 where bulk_id between 1 and 1000
 group by department_id, dep_name
 order by department_id, dep_name;
 
-- RESULT_CHACHE 함수 사용
create or replace function fn_get_depname_rsltcache( pv_dept_id varchar2 )
    return varchar2
    RESULT_CACHE
    RELIES_ON ( DEPARTMENTS ) -- (참조 테이블1, ...)
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
    
    -- dep_name 칼럼에 부서명을 가져와 갱신
    update emp_bulk
       set dep_name = fn_get_depname_rsltcache( department_id )
     where bulk_id between 1 and 1000;
     
    vn_cnt := SQL%ROWCOUNT;
    
    commit;
    
    vn_total_time := (sysdate - vd_sysdate) * 60 * 60 * 24;
    
    dbms_output.put_line('update 건수 : ' || vn_cnt);
    dbms_output.put_line('소요 시간 : ' || vn_total_time);
    
end;
/

select * from v$result_cache_statistics;

show parameter result_cache_max_size;

show parameter result_csche_mode;

----------------------------------------------------------------
-- 핵심정리
----------------------------------------------------------------

-- 1. 커서와 루프를 사용해서 처리할 때 BULK COLLECT 절을 사용하면 성능이 크게 향상된다.
-- 2. 커서와 루프를 사용해 루프 내에서 DML문을 실행할 때 FORALL 문을 사용하면 성능이 좋아진다. (반정도)
-- 3. 대량의 데이터를 조회할 때 함수를 사용하면 성능이 심각하게 저하된다.
-- 4. 오라클 11g부터는 함수를 정의할 때 result cache 기능으로 성능 향상 효과를 볼 수 있다.
-- 5. result cache란 결과를 캐시에 저장해 놨다가 다시 동일한 매개변수가 전달될 때 함수 본문을 처리하지 않고 캐시에 저장된 결과 값을 재사용하는 것을 말한다.
-- 6. result cache 기능이 지원되지만, 대량의 데이터를 조회할 때는 함수 대신 조인을 사용하자.
-- 7. 병렬 처리를 하면 성능을 극대화할 수 있으며 병렬 처리에는 병렬 쿼리와 병령 DML 이 있다.
-- 8. 병렬 쿼리는 ALTER SESSION 명령어를 실행하는 방법과 PARALLEL 힌트를 사용하는 방법이 있다.
-- 9. 병렬 DML은 ALTER SESSION 명령어로 처리할 수 있으며 보통은 병렬 쿼리와 함께 사용된다.
-- 10. 병렬 처리는 필요할 때만 사용하는 것이 좋으며 남용하면 오히려 성능저하를 초래한다.

-- # AutoCommit 은 [OFF] 여야 하고, sql 끝에 [commit;] 을 붙여야 한다.
-- * https://www.phpschool.com/gnuboard4/bbs/board.php?bo_table=qna_db&wr_id=211629&page=181
-- * http://1004lucifer.blogspot.com/2016/07/sql-developer-sql.html
-- * 하나의 dml문 안에서 개발자가 나누는 것이 얼마나 의미가 있을까?

-- # INSERT 시 index 의 유무.
-- * 일단은 index 없이 넣어보자.
-- * http://www.gurubee.net/lecture/2285

