create or replace package hr_pkg is

-- ����� �޾� �̸��� ��ȯ�ϴ� �Լ�
function fn_get_emp_name(
    pn_employee_id in number
)
return varchar2;

-- ����� �޾� �μ����� ��ȯ�ϴ� �Լ�
function fn_get_dep_name (
    pn_employee_id in number
)
return varchar2;

-- �űԻ�� �Է�
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
        -- ������� ������.
        select emp_name
          into vs_emp_name
          from employees
         where employee_id = pn_employee_id;
        
        -- ����� ��ȯ
        return nvl(vs_emp_name, '�ش�������');
    end fn_get_emp_name;
    
    -- �ű� ��� �Է� ���ν���
    procedure new_emp_proc (
        ps_emp_name in varchar2
      , pd_hire_date in varchar2
    )
    IS
        vn_emp_id employees.employee_id%type;
        vd_hire_date date := to_date(pd_hire_date, 'YYYY-MM-DD');
    begin
        -- �űԻ���� ��� = �ִ� ��� + 1
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
    
    -- ��� ��� ó��
    procedure retire_emp_proc (
        pn_employee_id in number
    )
    IS
        vn_cnt number := 0;
        e_no_data exception;
        
    begin
        -- ����� ����� ��� ���̺��� �������� �ʰ� �ϴ� �������(retire_date) �� null ���� �������ڷ� ����
        update employees
           set retire_date = sysdate
         where employee_id = pn_employee_id
           and retire_date is null;
        
        -- updated�� �Ǽ��� ������.
        vn_cnt := SQL%ROWCOUNT;
        
        -- ���ŵ� �Ǽ��� ���ٸ� ����� ����ó��
        if vn_cnt = 0 then
            raise e_no_data;
        end if;
        
        commit;
    exception
        when e_no_data then
            dbms_output.put_line (pn_employee_id || '�� �ش�Ǵ� ���ó���� ����� �����ϴ�!');
            rollback;
        when others then
            dbms_output.put_line (sqlerrm);
            rollback;
    end retire_emp_proc;
    
    -- ����� �޾� �μ����� ��ȯ�ϴ� �Լ�
    function fn_get_dep_name (
        pn_employee_id in number
    )
    return varchar2
    is
        vs_dep_name departments.department_name%type;
    begin
        -- �μ� ���̺�� ������ ����� �̿�, �μ������ �����´�.
        select b.department_name
          into vs_dep_name
          from employees a, departments b
         where a.department_id = b.department_id
           and a.employee_id = pn_employee_id;
          
        -- �μ��� ��ȯ
        return vs_dep_name;
    end fn_get_dep_name;
        
end hr_pkg;
/

select hr_pkg.fn_get_emp_name(1000) from dual;

begin
    hr_pkg.new_emp_proc('Źâ��', null);
end;
/

select * from employees where emp_name = 'Źâ��';

set serveroutput on;

begin
    hr_pkg.retire_emp_proc(10000);
end;
/

exec hr_pkg.retire_emp_proc(207);

-- package �� body �� �������� �ʰ� ȣ�� �� ��� ������ ������? �������� �ȴٴ� ���ΰ�.
create or replace procedure ch12_dep_proc (
    pn_employee_id in number
)
is
    vs_dep_name departments.department_name%type; -- �μ��� ����
begin
    -- �μ��� ��������
    vs_dep_name := hr_pkg.fn_get_dep_name(pn_employee_id); -- ���� body ���� ��. core ������ ����� �ٽ� �������� �ʿ䰡 ������, �̰� �� ���� ���̳�.
    
    -- �μ��� ���
    dbms_output.put_line(nvl(vs_dep_name, '�μ��� ����'));
end;
/

exec ch12_dep_proc(111);

begin
    ch12_dep_proc(111);
end;
/

----------------------------------------------------------------
-- ��Ű�� ���� ������ �� ���ǿ��� �����ȴ�.
----------------------------------------------------------------

create or replace package ch12_var is

-- ��� ����
c_test constant varchar2(10) := 'TEST';

-- ���� ����
v_test varchar2(10);

-- ���� ���� ���� �������� �Լ�
function fn_get_value return varchar2;

-- ���� ���� ���� �����ϴ� ���ν���, ��. �������� � ���� ��������� �����Ű�ڴٴ� ���ΰ�. �Լ��ȿ����� ���� �ٲ� �ʿ�� ���ٴ� ���̰ڱ�.
procedure sp_set_value ( ps_value varchar2 );

end ch12_var;
/

begin
    dbms_output.put_line('��� ch12_var.c_test = ' || ch12_var.c_test);
    dbms_output.put_line('���� ch12_var.v_test = ' || ch12_var.v_test);
    -- ���� ���� �����غ���.
    ch12_var.v_test := 'FIRST';
    dbms_output.put_line('���� ch12_var.v_test = ' || ch12_var.v_test);
end;
/

-- �� ���� ��� ������ ����ֳ�. ������ �̰��� JDBC ������ ���踦 ������ �� ������?

create or replace package body ch12_var is

-- ��� ����
c_test_body constant varchar2(10) := 'CONSTNAT_BODY';

-- ��������
v_test_body varchar2(10);

function fn_get_value return varchar2
is
begin
    -- ���� ���� ��ȯ
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
    -- ���� �Ҵ�
    ch12_var.sp_set_value('EXTERNAL');
    
    -- �� ����
    vs_value := ch12_var.fn_get_value();
    dbms_output.put_line('value: ' || vs_value);
end;
/


----------------------------------------------------------------
-- ��Ű�� ����ο��� Ŀ�� ��ü�� �����ϴ� ����
----------------------------------------------------------------
create or replace package ch12_cur_pkg is
    -- Ŀ�� ��ü ����
    cursor pc_empdep_cur (dep_id IN departments.department_id%type)
    is
        select a.employee_id, a.emp_name, b.department_name
          from employees a, departments b
         where a.department_id = b.department_id
           and a.department_id = dep_id;
           
    -- ROWTYPE �� Ŀ�� ��� ����
    cursor pc_depname_cur (dep_id in departments.department_id%type)
        return departments%rowtype; -- �̷��� �ϸ� * �� return �ؾ� �ϰڱ�.
        
    -- ����� ���� ���ڵ� Ÿ�� -> �⺻���� ������ ������ �����Ѵ�.
    type emp_dep_rt is record (
        emp_id employees.employee_id%type,
        emp_name employees.emp_name%type,
        job_title jobs.job_title%type
    );
    
    -- ����� ���� ���ڵ带 ��ȯ�ϴ� Ŀ��
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
-- ��Ű�� Ŀ��. ������ ������ Ŀ�� ��� �κи� �����ϴ� ����
-- Ŀ���� ��ȯ, ��ġ�ϴ� �����͸� ����Ű�� [return��] �� ����ؾ� �Ѵ�.
----------------------------------------------------------------

create or replace package body ch12_cur_pkg is
    -- rowtype�� Ŀ�� ����
    cursor pc_depname_cur ( dep_id in departments.department_id%type )
        return departments%rowtype
    is
        select *
          from departments
         where department_id = dep_id;
         
    -- ����� ���� ���ڵ带 ��ȯ�ϴ� Ŀ��
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

-- Ŀ���� ���� ������ ������ ������ ������ �����Ѵ�. cursor �� ref �̴ϱ�.
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

-- ���ݱ��� Ŀ�� ��� ���������� FOR���� �ַ� ���������, LOOP �� WHILE ���� ����� ���� "Ŀ������ -> ��ġ -> �ݱ�" ������ ���� ����� �־�� �Ѵ�.

declare
    -- Ŀ�� ���� ����
    dep_cur ch12_cur_pkg.pc_depname_cur%rowtype;
begin
    -- Ŀ�� ����
    open ch12_cur_pkg.pc_depname_cur(30);
    
    loop
        fetch ch12_cur_pkg.pc_depname_cur INTO dep_cur;
        exit when ch12_cur_pkg.pc_depname_cur%notfound;
        dbms_output.put_line( dep_cur.department_id || ' - ' || dep_cur.department_name );
    end loop;
    
    -- Ŀ�� �ݱ�
    -- close ch12_cur_pkg.pc_depname_cur;
end;
/

----------------------------------------------------------------
-- ���ڵ�� �÷���
----------------------------------------------------------------
create or replace package ch12_col_pkg is
    -- ��ø ���̺� ����
    type nt_dep_name is table of varchar2(30);
    
    -- ��ø ���̺� ���� ���� �� �����ڷ� �ʱ�ȭ
    pv_nt_dep_name nt_dep_name := nt_dep_name();
    
    -- ������ ��ø ���̺� ������ ���� ���ν���
    procedure make_dep_proc ( p_par_id in number );
    
end ch12_col_pkg;
/

create or replace package body ch12_col_pkg is
    -- ������ ��ø ���̺� ������ ���� ���ν���
    procedure make_dep_proc ( p_par_id in number )
    is
    begin
        -- �μ� ���̺��� parent_id �� �޾� �μ����� �����´�.
        for rec in ( select department_name
                       from departments
                      where parent_id = p_par_id )
        loop
            -- ��ø ���̺� ���� extend
            pv_nt_dep_name.extend();
            -- ��ø ���̺� ������ �����͸� �ִ´�.
            pv_nt_dep_name(pv_nt_dep_name.count) := rec.department_name;
        end loop;
    end make_dep_proc;
end ch12_col_pkg;
/

begin
    -- 100�� �μ��� ���� �μ����� ch12_col_pkg.pv_nt_dep_name �÷��� ������ ���
    ch12_col_pkg.make_dep_proc(100);
    
    for i in 1..ch12_col_pkg.pv_nt_dep_name.count
    loop
        dbms_output.put_line(ch12_col_pkg.pv_nt_dep_name(i));
    end loop;
end;
/

begin
    -- 100�� �μ��� ���� �μ����� ch12_col_pkg.pv_nt_dep_name �÷��� ������ ���
--    ch12_col_pkg.make_dep_proc(100);

    -- ���ǿ��� ��� ����ִ���. �׷��� �ӽ� ���ѵ�?    
    for i in 1..ch12_col_pkg.pv_nt_dep_name.count
    loop
        dbms_output.put_line(ch12_col_pkg.pv_nt_dep_name(i));
    end loop;
end;
/

----------------------------------------------------------------
-- ������ �ý��� ��Ű��
----------------------------------------------------------------

select owner, object_name, object_type, status
  from all_objects
 where object_type = 'PACKAGE'
   and ( object_name like 'DBMS%' or object_name like 'UTL%')
 order by object_name;
 
select dbms_metadata.get_ddl('TABLE', 'EMPLOYEES', 'FORGE') from dual;

select dbms_metadata.get_ddl('TABLE', 'TB_COM_WICS', 'FORGE') from dual;

select dbms_metadata.get_ddl('PACKAGE', 'CH12_COL_PKG', 'FORGE') from dual;
 