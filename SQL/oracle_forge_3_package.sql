create or replace package hr_pkg is

-- 사번을 받아 이름을 반환하는 함수
function fn_get_emp_name(
    pn_employee_id in number
)
return varchar2;

-- 사번을 받아 부서명을 반환하는 함수
function fn_get_dep_name (
    pn_employee_id in number
)
return varchar2;

-- 신규사원 입력
procedure new_emp_proc (
    ps_emp_name in varchar2
  , pd_hire_date in varchar2
);

procedure retire_emp_proc(pn_employee_id in number);

end hr_pkg;
/

create or replace package body hr_pkg is

    function fn_get_emp_name (
        pn_employee_id in number
    )
    return varchar2
    is
        vs_emp_name employees.emp_name%type;
    begin
        -- 사원명을 가져옴.
        select emp_name
          into vs_emp_name
          from employees
         where employee_id = pn_employee_id;
        
        -- 사원명 반환
        return nvl(vs_emp_name, '해당사원없음');
    end fn_get_emp_name;
    
    -- 신규 사원 입력 프로시저
    procedure new_emp_proc (
        ps_emp_name in varchar2
      , pd_hire_date in varchar2
    )
    IS
        vn_emp_id employees.employee_id%type;
        vd_hire_date date := to_date(pd_hire_date, 'YYYY-MM-DD');
    begin
        -- 신규사원의 사번 = 최대 사번 + 1
        select nvl(max(employee_id), 0) + 1
          into vn_emp_id
          from employees;
        
        insert into employees (employee_id, emp_name, hire_date, create_date, update_date)
            values (vn_emp_id, ps_emp_name, NVL(vd_hire_date, sysdate), sysdate, sysdate);
        
        commit;
    exception when others then
        dbms_output.put_line(sqlerrm);
        rollback;
    end new_emp_proc;
    
    -- 퇴사 사원 처리
    procedure retire_emp_proc (
        pn_employee_id in number
    )
    IS
        vn_cnt number := 0;
        e_no_data exception;
        
    begin
        -- 퇴사한 사원은 사원 테이블에서 삭제하지 않고 일단 퇴사일자(retire_date) 를 null 에서 현재일자로 갱신
        update employees
           set retire_date = sysdate
         where employee_id = pn_employee_id
           and retire_date is null;
        
        -- updated된 건수를 가져옴.
        vn_cnt := SQL%ROWCOUNT;
        
        -- 갱신된 건수가 없다면 사용자 예외처리
        if vn_cnt = 0 then
            raise e_no_data;
        end if;
        
        commit;
    exception
        when e_no_data then
            dbms_output.put_line (pn_employee_id || '에 해당되는 퇴사처리할 사원이 없습니다!');
            rollback;
        when others then
            dbms_output.put_line (sqlerrm);
            rollback;
    end retire_emp_proc;
    
    -- 사번을 받아 부서명을 반환하는 함수
    function fn_get_dep_name (
        pn_employee_id in number
    )
    return varchar2
    is
        vs_dep_name departments.department_name%type;
    begin
        -- 부서 테이블과 조인해 사번을 이용, 부서명까지 가져온다.
        select b.department_name
          into vs_dep_name
          from employees a, departments b
         where a.department_id = b.department_id
           and a.employee_id = pn_employee_id;
          
        -- 부서명 반환
        return vs_dep_name;
    end fn_get_dep_name;
        
end hr_pkg;
/

select hr_pkg.fn_get_emp_name(1000) from dual;

begin
    hr_pkg.new_emp_proc('탁창범', null);
end;
/

select * from employees where emp_name = '탁창범';

set serveroutput on;

begin
    hr_pkg.retire_emp_proc(10000);
end;
/

exec hr_pkg.retire_emp_proc(207);

-- package 의 body 를 구현하지 않고 호출 시 어떠한 문제가 있을까? 컴파일은 된다는 말인가.
create or replace procedure ch12_dep_proc (
    pn_employee_id in number
)
is
    vs_dep_name departments.department_name%type; -- 부서명 변수
begin
    -- 부서명 가져오기
    vs_dep_name := hr_pkg.fn_get_dep_name(pn_employee_id); -- 아직 body 구현 전. core 팀에서 만들면 다시 컴파일할 필요가 없으니, 이거 참 좋은 일이네.
    
    -- 부서명 출력
    dbms_output.put_line(nvl(vs_dep_name, '부서명 없음'));
end;
/

exec ch12_dep_proc(111);

begin
    ch12_dep_proc(111);
end;
/

----------------------------------------------------------------
-- 패키지 안의 변수는 한 세션에서 유지된다.
----------------------------------------------------------------

create or replace package ch12_var is

-- 상수 선언
c_test constant varchar2(10) := 'TEST';

-- 변수 선언
v_test varchar2(10);

-- 내부 변수 값을 가져오는 함수
function fn_get_value return varchar2;

-- 내부 변수 값을 변경하는 프로시저, 음. 실행전에 어떤 값을 맞춘다음에 실행시키겠다는 것인가. 함수안에서만 값을 바꿀 필요는 없다는 것이겠군.
procedure sp_set_value ( ps_value varchar2 );

end ch12_var;
/

begin
    dbms_output.put_line('상수 ch12_var.c_test = ' || ch12_var.c_test);
    dbms_output.put_line('변수 ch12_var.v_test = ' || ch12_var.v_test);
    -- 변수 값을 변경해보자.
    ch12_var.v_test := 'FIRST';
    dbms_output.put_line('변수 ch12_var.v_test = ' || ch12_var.v_test);
end;
/

-- 새 탭을 열어도 세션이 살아있네. 하지만 이것이 JDBC 에서의 관계를 정의할 수 있을까?

create or replace package body ch12_var is

-- 상수 선언
c_test_body constant varchar2(10) := 'CONSTNAT_BODY';

-- 변수선언
v_test_body varchar2(10);

function fn_get_value return varchar2
is
begin
    -- 변수 값을 반환
    return nvl(v_test_body, 'NULL!');
end fn_get_value;

procedure sp_set_value(ps_value varchar2)
is
begin
    v_test_body := ps_value;
end sp_set_value;

end ch12_var;
/

begin
    dbms_output.put_line('ch12_var.c_test_body = ' || ch12_var.c_test_body);
    dbms_output.put_line('ch12_var.v_test_body = ' || ch12_var.v_test_body);
end;
/

declare
    vs_value varchar2(10);
begin
    -- 값을 할당
    ch12_var.sp_set_value('EXTERNAL');
    
    -- 값 참조
    vs_value := ch12_var.fn_get_value();
    dbms_output.put_line('value: ' || vs_value);
end;
/


----------------------------------------------------------------
-- 패키지 선언부에서 커서 전체를 선언하는 형태
----------------------------------------------------------------
create or replace package ch12_cur_pkg is
    -- 커서 전체 선언
    cursor pc_empdep_cur (dep_id IN departments.department_id%type)
    is
        select a.employee_id, a.emp_name, b.department_name
          from employees a, departments b
         where a.department_id = b.department_id
           and a.department_id = dep_id;
           
    -- ROWTYPE 형 커서 헤더 선언
    cursor pc_depname_cur (dep_id in departments.department_id%type)
        return departments%rowtype; -- 이렇게 하면 * 를 return 해야 하겠군.
        
    -- 사용자 정의 레코드 타입 -> 기본적인 성질은 변수와 동일한다.
    type emp_dep_rt is record (
        emp_id employees.employee_id%type,
        emp_name employees.emp_name%type,
        job_title jobs.job_title%type
    );
    
    -- 사용자 정의 레코드를 반환하는 커서
    cursor pc_empdep2_cur ( p_job_id IN jobs.job_id%type )
        return emp_dep_rt;
             
end ch12_cur_pkg;
/

begin
    for rec in ch12_cur_pkg.pc_empdep_cur(30)
    loop
        dbms_output.put_line(rec.emp_name || ' - ' || rec.department_name);
    end loop;
end;
/

----------------------------------------------------------------
-- 패키지 커서. 쿼리를 제외한 커서 헤더 부분만 선언하는 형태
-- 커서가 반환, 패치하는 데이터를 가리키는 [return절] 을 명시해야 한다.
----------------------------------------------------------------

create or replace package body ch12_cur_pkg is
    -- rowtype형 커서 본문
    cursor pc_depname_cur ( dep_id in departments.department_id%type )
        return departments%rowtype
    is
        select *
          from departments
         where department_id = dep_id;
         
    -- 사용자 정의 레코드를 반환하는 커서
    cursor pc_empdep2_cur ( p_job_id in jobs.job_id%type )
        return emp_dep_rt
    is
        select a.employee_id, a.emp_name, b.job_title
          from employees a,
               jobs b
         where a.job_id = b.job_id
           and a.job_id = p_job_id;

end ch12_cur_pkg;
/

-- 커서에 대한 쿼리는 감춰져 있지만 사용법은 동일한다. cursor 는 ref 이니까.
begin
    for rec in ch12_cur_pkg.pc_depname_cur(30)
    loop
        dbms_output.put_line(rec.department_Id || ' - ' || rec.department_name);
    end loop;
end;
/

begin
    for rec in ch12_cur_pkg.pc_empdep2_cur('FI_ACCOUNT')
    loop
        dbms_output.put_line(rec.emp_id || ' - ' || rec.emp_name || ' - ' || rec.job_title);
    end loop;
end;
/

-- 지금까지 커서 사용 예제에서는 FOR문을 주로 사용했지만, LOOP 나 WHILE 문을 사용할 때는 "커서열기 -> 패치 -> 닫기" 과정을 직접 명시해 주어야 한다.

declare
    -- 커서 변수 선언
    dep_cur ch12_cur_pkg.pc_depname_cur%rowtype;
begin
    -- 커서 열기
    open ch12_cur_pkg.pc_depname_cur(30);
    
    loop
        fetch ch12_cur_pkg.pc_depname_cur INTO dep_cur;
        exit when ch12_cur_pkg.pc_depname_cur%notfound;
        dbms_output.put_line( dep_cur.department_id || ' - ' || dep_cur.department_name );
    end loop;
    
    -- 커서 닫기
    -- close ch12_cur_pkg.pc_depname_cur;
end;
/

----------------------------------------------------------------
-- 레코드와 컬렉션
----------------------------------------------------------------
create or replace package ch12_col_pkg is
    -- 중첩 테이블 선언
    type nt_dep_name is table of varchar2(30);
    
    -- 중첩 테이블 변수 선언 및 생성자로 초기화
    pv_nt_dep_name nt_dep_name := nt_dep_name();
    
    -- 선언한 중첩 테이블에 데이터 생성 프로시저
    procedure make_dep_proc ( p_par_id in number );
    
end ch12_col_pkg;
/

create or replace package body ch12_col_pkg is
    -- 선언한 중첩 테이블에 데이터 생성 프로시저
    procedure make_dep_proc ( p_par_id in number )
    is
    begin
        -- 부서 테이블의 parent_id 를 받아 부서명을 가져온다.
        for rec in ( select department_name
                       from departments
                      where parent_id = p_par_id )
        loop
            -- 중첩 테이블 변수 extend
            pv_nt_dep_name.extend();
            -- 중첩 테이블 변수에 데이터를 넣는다.
            pv_nt_dep_name(pv_nt_dep_name.count) := rec.department_name;
        end loop;
    end make_dep_proc;
end ch12_col_pkg;
/

begin
    -- 100번 부서에 속한 부서명을 ch12_col_pkg.pv_nt_dep_name 컬렉션 변수에 담기
    ch12_col_pkg.make_dep_proc(100);
    
    for i in 1..ch12_col_pkg.pv_nt_dep_name.count
    loop
        dbms_output.put_line(ch12_col_pkg.pv_nt_dep_name(i));
    end loop;
end;
/

begin
    -- 100번 부서에 속한 부서명을 ch12_col_pkg.pv_nt_dep_name 컬렉션 변수에 담기
--    ch12_col_pkg.make_dep_proc(100);

    -- 세션에서 계속 살아있는지. 그런데 머시 중한디?    
    for i in 1..ch12_col_pkg.pv_nt_dep_name.count
    loop
        dbms_output.put_line(ch12_col_pkg.pv_nt_dep_name(i));
    end loop;
end;
/

----------------------------------------------------------------
-- 유용한 시스템 패키지
----------------------------------------------------------------

select owner, object_name, object_type, status
  from all_objects
 where object_type = 'PACKAGE'
   and ( object_name like 'DBMS%' or object_name like 'UTL%')
 order by object_name;
 
select dbms_metadata.get_ddl('TABLE', 'EMPLOYEES', 'FORGE') from dual;

select dbms_metadata.get_ddl('TABLE', 'TB_COM_WICS', 'FORGE') from dual;

select dbms_metadata.get_ddl('PACKAGE', 'CH12_COL_PKG', 'FORGE') from dual;
 