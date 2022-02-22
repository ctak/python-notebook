select * from dba_jobs;

select * from all_jobs;

select * from user_jobs;

-- �����Ͱ� �� ���� �ֳ�.
select seq, to_char(insert_date, 'yyyy-mm-dd hh24:mi:ss') from ch15_job_test;

create table ch15_job_test (
    seq number,
    insert_date date);
    
create or replace procedure ch15_job_test_proc
is
    vn_next_seq number;
    
begin
    -- ���� ������ �����´�.
    select nvl(max(seq), 0) + 1
      into vn_next_seq
      from ch15_job_test;
      
    -- ch15_job_test ���̺� insert
    insert into ch15_job_test values (vn_next_seq, sysdate);
    
    commit;
exception when others then
    rollback;
    dbms_output.put_line(sqlerrm);
end;
/

DBMS_JOB.SUBMIT (
    job         OUT binary_integer, -- �� ��ȣ. ��� ������ �ڵ����� ��ȣ�� �Ű�����.
    what        in varchar2, -- ����� ���α׷�, ���ڿ� ���·� sql�̳� pl/sql �� �´�. (��: ������ ������� ch15_job_test_proc�� ���� ���ν���)
    next_date   in date default sysdate, -- ���� ����� ���� ��¥ (�ð�), ����Ʈ ���� sysdate
    interval    in varchar2 default 'NULL', -- ���� ���� �ֱ��, ���ڿ� ������ ��
    no_parse    in boolean default false, -- false �� �����ϸ�, no_parse �� �ƴϴ� parse ��. false�� �����ϸ� ����Ŭ�� �ش� ��� ������ ���ν����� �Ľ��ϰ�, true �� �����ϸ� ���� �� ó�� ������� ���� �Ľ��Ѵ�.
    instance    in binary_integer default any_instance,
    force       in boolean default false
);

-- 1�п� 1ȸ: SYSDATE + 1/60/24
-- 30�ʿ� 1ȸ: SYSDATE + 30/60/60/24
-- 10�ʿ� 1ȸ: SYSDATE + 10/60/60/24

-- ���� �Ͽ��� ���� 3�ø��� ����: NEXT_DAY( TRUNC(SYSDATE), '�Ͽ���' ) + 15/24
-- ���� ������ ���� 11�ø��� ����: NEXT_DAY( TRUNC(SYSDATE), '������' ) + 23/24
-- �ſ� ������ �� ���� 6�� 30�п� ����: LAST_DAY( TRUNC(SYSDATE) + 18/24 + 30/60/24 )

select to_char( trunc(sysdate), 'yyyymmdd hh24miss') from dual;

declare
    v_job_no number;
begin
    -- ���� �ð� ���� 1�п� 1���� ch15_job_test_proc ���ν����� �����ϴ� �� ���
    dbms_job.submit ( 
        job => v_job_no,
        what => 'ch15_job_test_proc();', -- note1: semicolon �� �ֳ�.
        next_date => SYSDATE,
        interval => 'SYSDATE + 1/60/24'
    );
    
    COMMIT; -- note2 COMMIT �� �־�� �ϳ�.
    
    -- note3. ����������, ����� �� ��ȣ�� �ý��ۿ��� �ڵ� �������ֹǷ� submit ���ν����� ȣ���� ����
    -- �� ��ȣ�� ���� ������ ������ �� �ֵ��� �͸� ��� ���·� �����ؾ� �Ѵ�.
    
    -- �ý��ۿ��� �ڵ� ������ �� ��ȣ ���
    dbms_output.put_line('v_job_no : ' || v_job_no);
end;
/

select job, last_date, last_sec, next_date, next_sec, broken, interval, failures, what
from user_jobs;

DBMS_JOB.BROKEN (
    job         IN binary_integer, -- �� ��ȣ
    broken      IN BOOLEAN, -- ���� ������ ���� true, �ٽ� ������ ���� false
    next_date   IN date default sysdate -- ���� �����ǰų� ������ ��¥(�ð�), ���������ϸ� ����Ʈ ���� sysdate
);

begin
    -- �� ����
    dbms_job.broken( 1, true );
    commit; -- �̰͵� commit �� �ؾ� �ϴ� ��.
end;
/

begin
    -- �� �����
    dbms_job.broken(1, false);
    commit;
end;
/

DBMS_JOB.CHANGE (
    job         IN binary_integer, -- �� ��ȣ.
    what        in varchar2, -- ����� ���α׷�, ���ڿ� ���·� sql�̳� pl/sql �� �´�. (��: ������ ������� ch15_job_test_proc�� ���� ���ν���)
    next_date   in date default sysdate, -- ���� ����� ���� ��¥ (�ð�), ����Ʈ ���� sysdate
    interval    in varchar2 default 'NULL', -- ���� ���� �ֱ��, ���ڿ� ������ ��
    instance    in binary_integer default any_instance,
    force       in boolean default false
);
truncate table ch15_job_test;
begin
    -- �� ����
    dbms_job.change(
        job => 1,
        what => 'ch15_job_test_proc;',
        next_date => sysdate,
        interval=> 'sysdate + 3/60/24');
    commit;
end;
/

-- ���� ����: �ֱ⿡ ������� ������ ������ ���� �ִ�.
dbms_job.run (
    job         IN binary_integer,
    force       IN boolean default false -- �̰� ���� ����, ���� �������� ������ �� �ִ� �̰���.
);

begin
    -- �� ���� ����
    dbms_job.run(1);
    commit;
end;
/
    
-- ���� ����
dbms_job.remove (
    job IN binary_integer );
    
begin
    dbms_job.remove(1);
    commit;
end;
/

----------------------------------------------------------------
-- DBMS_SCHEDULRE.
-- ���α׷� ��ü ����
----------------------------------------------------------------

DBMS_SCHEDULER.CREATE_PROGRAM (
    program_name IN varchar2, -- ���α׷� ��ü�� ���� �̸�. ���ϴ� ��Ī�� �Է�. (��. ���α׷��� �̸��� �Է��� �� �ְ� �Ͽ���.)
    program_type IN varchar2, -- 'PLSQL_BLOCK | PROCEDURE | EXECUTABLE'
    program_action IN varchar2, -- ���� ����� �͸� ���, ���ν�����, �ܺ� �������α׷�. (�̰�  DBMS_JOB. �� ����. string �̶�� ��.)
    number_of_arguments IN PLS_INTEGER default 0, -- �ӵ��� ���� ������ pls_integer, binary_integer, number. [number] �� ���� ���� �ٺ�����.
    enabled IN boolean default false, -- ������ ���α׷� ��ü�� Ȱ��ȭ ����
    comments IN varchar2 default null -- ���α׷� ��ü�� ���� �ּ�.
);

begin
dbms_scheduler.create_program (
    program_name => 'my_program1',
    program_type => 'STORED_PROCEDURE',
    program_action => 'ch15_job_test_proc',
    comments => 'ù��° ���α׷�'
);

-- NO COMMIT!!! 
end;
/

select program_name, program_type, program_action, number_of_arguments, enabled, comments
  from user_scheduler_programs;
  
----------------------------------------------------------------
-- DBMS_SCHEDULRE.
-- ������ ��ü ����
--
-- ������ ��ü���� �߿��� �׸��� [����] �� [�󸶳� ����] �̴�.
----------------------------------------------------------------
dbms_scheduler.create_schedule (
    schedule_name IN varchar2, -- ������ ��ü�� ���� �̸�
    start_date IN TIMESTAMP WITH TIMEZONE default null, -- ������ �������ڿ� �ð�
    repeat_interval IN varchar2, -- ������ ���� �ֱ�. �� �� ������ �ֱ� ������ ����
    end_date IN TIMESTAMP WITH TIMEZONE defualt null, -- ������ �������ڿ� �ð�
    comments IN varchar2
);

FREQ:           ���� �ֱ�. ���� ���� [ YEARLY, MONTHLY, WEEKLY, DAILY, HOURLY, MINUTELY, SECONDLY ]
INTERVAL:       ���� Ƚ��. ����Ʈ ���� 1. �ִ� ���� ���� 99. (�� ���̳� ������ �� �ִٴ� ���ΰ�?)
BYMONTH:        �� ���� ���� �� �ش� ���� ���
                ��) 3���� ���� -> BYMONTH=3 Ȥ�� BYMONTH=MAR
BYWEEKNO:       �� ���� ���� �� ������ȣ�� ���
BYYEARDAY:      �� ���� ���� �� �������� ����(1~365)�� ���.
BYDATE:         ���� ����Ʈ�� YYYYMMDD(YYYY�� ���� ����) �������� ���
                ��) 1�� 20�� ���� -> BYDATE = 0120
                    1�� 10��, 2�� 10��, 4�� 15�� ���� -> BYDATE=0110,0210,0415
BYMONTHDAY:     �� ����, �� ���� ����(1~31)�� ���
                ������ �Է��ϸ� �� ���� ���� ���ڸ� �ǹ�
BYDAY:          �� ����. �����Ͽ��� �Ͽ��ϱ��� �� ���� ���� ���
                ��) �� ��° ������ -> BYDAY = 2WED
BYHOUR:         �ð� ���� ����. 0~23 �ð��� ���
BYMINUTE:       �� ���� ����. 0~59���� ���
BYSECOND:       �� ���� ����. 0~59�� ���
BYSETPOS:       �ٸ� ���� ��ġ�� ����ϴ� ���� ������ ���� ��
                (-1)�̸� ����Ʈ�� �� ��, (-2)�� �� ������ �� ��°, 1�̸� �� ���ʿ��� ù ��°�� �ǹ�
                FREQ ���� MONTHLY, YEARLY �� ���� ��� ����
                ��) �ٹ����� ������~�ݿ��� �̶�� �� �� �ſ� ������ �ٹ��Ͽ� ����ǵ��� �Ѵٸ�,
                    FREQ=MONTHLY; BYDAY=MON,TUE,WED,THU,FRI; BYSETPOS=-1
INCLUDE:        CREATE_SCHEDULE ���ν����� ������ �ٸ� �������� ������ �� ���
EXCLUDE:        CREATE_SCHEDULE ���ν����� ������ �ٸ� �������� ������ �� ���.

* ������ ���� ->             FREQ=DAILY; BYDAY=MON; (�Ϻ� �ֱ�, �����Ͽ� ����) Ȥ��
                            FREQ=WEEKLY; BYDAY=MON; (�ֺ� �ֱ�, �����Ͽ� ����) Ȥ��
                            FREQ=YEARLY; BYDAY=MON; (������ �ֱ�, �����Ͽ� ����)
* �������� ������ ���� ->    FREQ=WEEKLY; INTERVAL=2; BYDAY=MON;
* �ſ� �������� ���� ->     FREQ=MONTHLY; BYMONTHDAY=-1;
* �ų� 5�� 10�� ���� ->       FREQ=YEARLY; BYMONTH=MAY; BYMONTHDAY=10; Ȥ��
                            FREQ=YEARLY; BYDATE=0510;
* �ſ� 25�� ���� ->          FREQ=MONTHLY; BYMONTHDAY=25;
* �ſ� �� ��° ������ ���� ->         FREQ=MONTHLY; BYDAY=2WED;
* ���� ���� 6��, ���� 6�ÿ� ���� ->    FREQ=DAILY; BYHOUR=06,18;
* 1�ð����� ���� ->           FREQ=HOURLY; INTERVAL=1;
                            ( �� ��� ���� �ð� �������� 1�ð����� 1���� ����� )
* �� �ð� 10�п� �� ���� ���� ->      FREQ=HOURLY; INTERVAL=1; BYMINUTE=10;
* 1�и��� ���� ->            FREQ=MINUTELY; INTERVAL=1;

begin
    dbms_scheduler.create_schedule (
        schedule_name => 'my_schedule1',
        start_date => null,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=1', -- 1�п� 1��
        end_date => null,
        comments => '1�и��� ����'
    );
end;
/

select schedule_name, schedule_type, start_date, repeat_interval, end_date, comments
  from user_scheduler_schedules; -- schedule_type �� [CALENDAR] �ε�, �̰��� [PL/SQL ǥ����] �� �ƴ� [�޷� ǥ����] �� ����ؼ� �̴�.

----------------------------------------------------------------
-- DBMS_SCHEDULRER.CREATE_JOB (
-- �� ��ü ����
--
----------------------------------------------------------------

-- ���� 1 - �� ��ü �ܵ����� ����ϴ� ���
DBMS_SCHEDULER.CREATE_JOB (
    job_name            IN varchar2, -- ���� �̸�
    job_type            IN varchar2, -- CREATE_PROGRAM �� program_type �Ű������� ����
    job_action          IN varchar2, -- CREATE_PROGRAM �� program_action �Ű������� ����
    number_of_arguments IN pls_integer default 0, -- CREATE_PROGRAM �� number_of_arguments �Ű������� ����
    start_date          IN timestamp with time zone default null, -- CREATE_SCHEDULE �� start_date �Ű������� ����
    repeat_interval     IN varchar2 default null, -- CREATE_SCHEDULE �� repeat_interval �Ű������� ����
    end_date            IN timestamp with time zone default null,
    job_class           IN varchar2 default 'DEFAULT_JOB_CLASS', -- �� Ŭ����
    enabled             IN boolean default false, -- Ȱ��ȭ ����, ����Ʈ ���� false
    auto_drop           IN boolean default true, -- true �̸� ���� �� �ڵ� drop
    comments            IN varchar2 default null,
);

-- ���� 1�� �� ��ü �ܵ����� ����ϹǷ� ���α׷� ��ü�� ������ ��ü�� �����ϸ鼭 �ʿ��� ������ �Ű������� �� ���޹޾ƾ� �Ѵ�.

-- ���� 2 - ���α׷�, ������ ��ü�� ��� ����ϴ� ���
DBMS_SCHEDULER.CREATE_JOB (
    job_name        IN varchar2,
    program_name    IN varchar2, -- ���α׷� ��ü��
    schedule_name   IN varchar2, -- ������ ��ü��
    job_class           IN varchar2 default 'DEFAULT_JOB_CLASS',
    enabled             IN boolean default false,
    auto_drop           IN boolean default true,
    comments            IN varchar2 default null,
    job_style       IN varchar2 default 'REQULAR', -- ���α׷� ��ü�� ����� ���� ���('REGULAR' -> �Ϲ����� ���, 'LIGHTWEIGHT' -> ����ð��� ª�� ��� ����� ����� ���)
);

-- ���� 3 - ���α׷� ��ü�� ����ϴ� ���
DBMS_SCHEDULER.CREATE_JOB (
    job_name        IN varchar2,
    program_name    IN varchar2, -- ���α׷� ��ü��
    start_date          IN timestamp with time zone default null, -- CREATE_SCHEDULE �� start_date �Ű������� ����
    repeat_interval     IN varchar2 default null, -- CREATE_SCHEDULE �� repeat_interval �Ű������� ����
    end_date            IN timestamp with time zone default null,
    job_class           IN varchar2 default 'DEFAULT_JOB_CLASS',
    enabled             IN boolean default false,
    auto_drop           IN boolean default true,
    comments            IN varchar2 default null,
    job_style       IN varchar2 default 'REQULAR', -- ���α׷� ��ü�� ����� ���� ���('REGULAR' -> �Ϲ����� ���, 'LIGHTWEIGHT' -> ����ð��� ª�� ��� ����� ����� ���)
);

-- ���� 4 - ������ ��ü�� ����ϴ� ���
DBMS_SCHEDULER.CREATE_JOB (
    job_name        IN varchar2,
    schedule_name   IN varchar2, -- ������ ��ü��
    job_type            IN varchar2, -- CREATE_PROGRAM �� program_type �Ű������� ����
    job_action          IN varchar2, -- CREATE_PROGRAM �� program_action �Ű������� ����
    number_of_arguments IN pls_integer default 0, -- CREATE_PROGRAM �� number_of_arguments �Ű������� ����
    job_class           IN varchar2 default 'DEFAULT_JOB_CLASS',
    enabled             IN boolean default false,
    auto_drop           IN boolean default true,
    comments            IN varchar2 default null,
    job_style       IN varchar2 default 'REQULAR', -- ���α׷� ��ü�� ����� ���� ���('REGULAR' -> �Ϲ����� ���, 'LIGHTWEIGHT' -> ����ð��� ª�� ��� ����� ����� ���)
);

----------------------------------------------------------------
-- ��ü Ȱ��ȭ�� ��Ȱ��ȭ
--
----------------------------------------------------------------
DBMS_SCHEDULER.ENABLE (
    name                IN varchar2,
    commit_semantics    IN varchar2 DEFAULT 'STOP_ON_FIRST_ERROR');
    
DBMS_SCHEDULER.DISABLE (
    name                IN varchar2,
    force               IN boolean default false,
    commit_semantics    IN varchar2 default 'STOP_ON_FIRST_ERROR');
    
----------------------------------------------------------------
-- ��ü �Ӽ� ����
--
----------------------------------------------------------------
DBMS_SCHEDULER.SET_ATTRIBUTE (
    name        IN varchar2, -- �Ӽ����� �ٲ� ��ü��
    attribute   IN varchar2, -- �Ӽ����� �ٲ� ��ü�� �Ӽ��� ex) start_date, repeat_interval, job_action, number_of_arguments, ...
    value       IN {BOOLEAN|DATE|TIMESTAMP|TIMESTAMP WITH TIME ZONE|TIMESTAMP WITH LOCAL TIME ZONE|INTERVAL DAY TO SECOND}
);
DBMS_SCHEDULER.SET_ATTRIBUTE (
    name        IN varchar2,
    attribute   IN varchar2,
    value       IN varchar2,
    value2      IN varchar2 default null -- ��κ��� �Ӽ��� ���� 1������, ���� 2���� �Ӽ��� ������ �̷� �� ���
);
-- �Ӽ� ���� NULL �� �����ؾ� �Ѵٸ�, set_attribute_null ���ν����� ����Ѵ�.
DBMS_SCHEDULER.SET_ATTRIBUTE_NULL (
    name        IN varchar2,
    attribute   IN varchar2
);

----------------------------------------------------------------
-- ��ü ����
--
----------------------------------------------------------------
DBMS_SCHEDULER.DROP_PROGRAM (
    program_name        IN varchar2, -- ������ ���α׷� ��ü��.
    force               IN boolean default false -- FALSE -> �����ϴ� JOB �� ������ ���� �߻�, TRUE -> �����ϴ� JOB �� ��Ȱ��ȭ ��.
);

DBMS_SCHEDULER.DROP_SCHEDULE (
    schedule_name       IN varchar2, -- ������ ������ ��ü��
    force               IN boolean default false -- FALSE -> �����ϴ� JOB �� ������ ���� �߻�, TRUE -> �����ϴ� JOB �� ��Ȱ��ȭ ��.
);

DBMS_SCHEDULER.DROP_JOB (
    job_name            IN varchar2,
    force               IN boolean default false, -- TRUE �� �����ϸ� ���� ����ǰ� �ִ� ���� �ߴܽ�Ų ���� ���� ����
    defer               IN boolean default false, -- TRUE �� �����ϸ� ����ǰ� �ִ� ���� �Ϸ�� ������ ���� ����
    commit_semantics    IN varchar2 default 'STOP_ON_FIRST_ERROR'
);

----------------------------------------------------------------
-- �� ��ü���� �̿��� �����ٸ�
begin
    dbms_scheduler.create_job (
        job_name            => 'my_job1',
        job_type            => 'STORED_PROCEDURE',
        job_action          => 'ch15_job_test_proc',
        repeat_interval     => 'FREQ=MINUTELY; INTERVAL=1', -- 1�п� 1��
        comments            => '����1 �ⰴü'
    );
end;
/

----------------------------------------------------------------
-- JOBS ��ȸ
----------------------------------------------------------------
-- JOBS ��ȸ
select job_name, program_name, job_style, job_type, job_action, schedule_name, schedule_type, repeat_interval, 
    enabled, auto_drop, state, comments
  from user_scheduler_jobs;
  
-- JOB �� ���� ���ϰ� �ִ���
select log_id, log_date, job_name, operation, status
  from user_scheduler_job_log
-- where job_name = 'MY_JOB1'
;

-- �� �� ���� �α�
select log_date, job_name, status, error#, req_start_date, actual_start_date,
    run_duration
  from user_scheduler_job_run_details
 order by 1 desc
;
  
truncate table ch15_job_test;

select seq, to_char(insert_date, 'yyyymmdd hh24miss') as insert_date from ch15_job_test;

begin
--    dbms_scheduler.enable('my_job1');
    dbms_scheduler.disable('my_job1');
end;
/

----------------------------------------------------------------
-- ������ ������� ���α׷��� ������ 

begin
    dbms_scheduler.create_job(
        job_name => 'my_job2',
        program_name => 'MY_PROGRAM1',
        schedule_name => 'MY_SCHEDULE1',
        comments => '����2 �ⰴü' 
    );
end;
/

begin
    dbms_scheduler.enable('MY_PROGRAM1');
end;
/

begin
    dbms_scheduler.enable('my_job2');
end;
/

----------------------------------------------------------------
-- CHAIN
--
----------------------------------------------------------------

-- 1. ch15_changed_object ���̺�

create table ch15_changed_object (
    object_name varchar2(128), -- ��ü��
    object_type varchar2(50), -- ��ü ����
    created date, -- ��ü ��������
    last_ddl_time date, -- ��ü ��������
    status varchar2(7), -- ��ü ����
    creation_date date -- ��������
);

-- 2. ch15_check_objects_prc ���ν���: ������ �� ������ ��ü������ �ִ��� �ľ��ϴ� ���ν���

create or replace procedure ch15_check_objects_prc
is
    vn_cnt number := 0;
begin
    -- ������ �� ����� ��ü �� ch15_changed_object �� ���� ��ü�� ã�´�.
    -- �ֳ��ϸ� ���� ���ν��� ���� �� ����� ��ü�� ������ �̹� ch15_changed_object �� �ԷµƱ� �����̴�.
    -- �����ϰ� ����� object �� ã�µ�, �ѹ��� ��ϵǸ� �ȴٴ� ���̱�. �ֳ��ϸ� �׽�Ʈ �̴ϱ�.
    select count(*)
      into vn_cnt
      from user_objects a
     where last_ddl_time between sysdate - 7 and sysdate
       and not exists (
            select 1
              from ch15_changed_object b
             where a.object_name = b.object_name )
    ;
    
    -- ����� ��ü�� ������ RAISE_APPLICATION_ERROR �� �߻����� �����ڵ带 �ѱ��
    -- �����ڵ带 �ѱ�� ������ �꿡�� ó���ϱ� �����̴�.
    if vn_cnt = 0 then
        RAISE_APPLICATION_ERROR(-20001, '����� ��ü ����');
    end if;
end;
/

-- 3. ch15_make_objects_prc ���ν���: ����� ��ü ������ ch15_changed_object ���̺� �����ϴ� ���ν���

create or replace procedure ch15_make_objects_prc
is
begin
    insert into ch15_changed_object (
        object_name,
        object_type,
        created,
        last_ddl_time,
        status,
        creation_date
    )
    select
        object_name,
        object_type,
        created,
        last_ddl_time,
        status,
        sysdate
      from user_objects a
     where last_ddl_time between sysdate - 7 and sysdate
       and not exists (
        select 1
          from ch15_changed_object b
         where a.object_name = b.object_name );
         
    commit;
exception when others then
    dbms_output.put_line(sqlerrm);
    raise_application_error(-20002, SQLERRM);
    rollback;
end;
/

-- 4. �� �� ���� ���ν����� ���� ���α׷� ��ü 2��
begin
    -- ch15_check_objects_prc �� ���� ���α׷� ��ü ����
    dbms_scheduler.create_program (
        program_name => 'MY_CHAIN_PROG1',
        program_type => 'STORED_PROCEDURE',
        program_action => 'ch15_check_objects_prc',
        comments => 'ù��° ü�� ���α׷�'
    );
    
    -- ch1_make_objects_proc �� ���� ���α׷� ��ü ����
    dbms_scheduler.create_program (
        program_name => 'MY_CHAIN_PROG2',
        program_type => 'STORED_PROCEDURE',
        program_action => 'ch15_make_objects_prc',
        comments => '�ι�° ü�� ���α׷�'
    );
    
    -- ���α׷� ��ü Ȱ��ȭ
    dbms_scheduler.enable ('MY_CHAIN_PROG1');
    dbms_scheduler.enable ('MY_CHAIN_PROG2');
end;
/

-- �����غ�� ��� ������.
-- 5. ü�� 1��

begin
    dbms_scheduler.create_chain (
        chain_name => 'MY_CHAIN1',
        rule_set_name => null,
        evaluation_interval => null,
        comments => 'ù ��° ü��'
    );
end;
/

-- 6. ���� 2��

begin
    -- step 1
    dbms_scheduler.define_chain_step (
        chain_name => 'MY_CHAIN1',
        step_name => 'STEP1',
        program_name => 'MY_CHAIN_PROG1' -- ������ ���α׷��� ����Ǿ� �ִ�.
    );
    
    -- step 2
    dbms_scheduler.define_chain_step (
        chain_name => 'MY_CHAIN1',
        step_name => 'STEP2',
        program_name => 'MY_CHAIN_PROG2' -- ó�� ��Ÿ�� �ļ� �ٽ� �������.
    );
end;
/

-- ������ �߸� �������.
-- https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12457

-- �ᱹ�� oracle ���� https://docs.oracle.com/database/121/ARPLS/d_sched.htm#ARPLS72340
begin

  -- �̰� ����. parameter �� �� �´´ٰ� �ϴµ� �� �𸣰���.
  /*
    dbms_scheduler.alter_chain (
        chain_name => 'MY_CHAIN1',
        step_name => 'STEP2',
        attribute => 'program_name',
        value => 'MY_CHAIN_PROG2'
    );
*/
    
--    dbms_scheduler.drop_chain_step ( chain_name => 'MY_CHAIN1', step_name => 'STEP2' );
--    dbms_scheduler.drop_chain_step ( chain_name => 'MY_CHAIN1', step_name => 'STEP1' );
    
--    SYS.dbms_scheduler.drop_chain_rule ( chain_name => 'MY_CHAIN1', rule_name => 'MY_RULE1' );
--    SYS.dbms_scheduler.drop_chain_rule ( chain_name => 'MY_CHAIN1', rule_name => 'MY_RULE2' );
--    SYS.dbms_scheduler.drop_chain_rule ( chain_name => 'MY_CHAIN1', rule_name => 'MY_RULE3' );
--    SYS.dbms_scheduler.drop_chain_rule ( chain_name => 'MY_CHAIN1', rule_name => 'MY_RULE4' );

--    SYS.dbms_scheduler.drop_chain ( chain_name => 'MY_CHAIN1', force => true );

    SYS.dbms_scheduler.drop_job (job_name => 'MY_CHAIN_JOBS');
end;
/

begin
    -- step 2
    dbms_scheduler.define_chain_step (
        chain_name => 'MY_CHAIN1',
        step_name => 'STEP2',
        program_name => 'MY_CHAIN_PROG2' -- ó�� ��Ÿ�� �ļ� �ٽ� �������.
    );
end;
/


-- 7. �� 4��
begin
    -- ���� STEP1�� ���۽�Ű�� ��
    dbms_scheduler.define_chain_rule (
        chain_name => 'MY_CHAIN1',
        condition => 'TRUE',
        action => 'START STEP1',
        rule_name => 'MY_RULE1',
        comments => 'START ��'
    );
end;
/

begin
    -- �� ��° ��, �����ϰ� ����� ��ü�� ���ٸ� ����� ������.
    -- �̴� STEP1 �� ������ �� ����� ���� �ڵ带 �޾��� �� �����ϵ��� ó���Ѵ�.
    dbms_scheduler.define_chain_rule (
        chain_name => 'MY_CHAIN1',
        condition => 'STEP1 ERROR_CODE = 20001',
        action => 'END',
        rule_name => 'MY_RULE2',
        comments => '��2'
    );
end;
/

begin
    -- STEP1 ���� STEP2 �� ���� ��
    dbms_scheduler.define_chain_rule (
        chain_name => 'MY_CHAIN1',
        condition => 'STEP1 SUCCEEDED', -- DSL ����. [SUCCEEDED'
        action => 'START STEP2',
        rule_name => 'MY_RULE3',
        comments => '��3'
    );
    
    -- STEP2 �� ��ġ�� �����ϴ� ��
    dbms_scheduler.define_chain_rule (
        chain_name => 'MY_CHAIN1',
        condition => 'STEP2 SUCCEEDED',
        action => 'END',
        rule_name => 'MY_RULE4',
        comments => '��4'
    );
end;
/

-- 8. �� ��ü 1��

begin
    dbms_scheduler.create_job (
        job_name => 'MY_CHAIN_JOBS',
        job_type => 'CHAIN', -- ü���� �����ϴ� ��!
        job_action => 'MY_CHAIN1', -- ü���� �����ϴ� ��!
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=1',
        comments => 'ü���� �����ϴ� ��'
    );
end;
/

-- ü��, ����, ���� �� ������� �ִ���.
select *
  from user_scheduler_chains;

select chain_name, step_name, program_name, step_type, skip, pause
  from user_scheduler_chain_steps;
  
select *
  from user_scheduler_chain_rules;
  
-- ü�ΰ� ���� Ȱ��ȭ

-- �ϴ� �߸��� ���� �����ϰ�, 
begin
    dbms_scheduler.disable( name => 'MY_CHAIN_JOBS', force => true);
    dbms_scheduler.disable('MY_CHAIN1');
end;
/

begin
    -- ü�� Ȱ��ȭ
    dbms_scheduler.enable('MY_CHAIN1');
    
    -- �� Ȱ��ȭ
    dbms_scheduler.enable('MY_CHAIN_JOBS');
    
end;
/

select log_date, job_subname, operation, status, additional_info
  from user_scheduler_job_log
 where job_name = 'MY_CHAIN_JOBS'
 order by 1;

select log_date, job_subname, status, actual_start_date, run_duration,
    additional_info
  from user_scheduler_job_run_details
 where job_name = 'MY_CHAIN_JOBS';
