select * from dba_jobs;

select * from all_jobs;

select * from user_jobs;

-- 데이터가 잘 들어가고 있나.
select seq, to_char(insert_date, 'yyyy-mm-dd hh24:mi:ss') from ch15_job_test;

create table ch15_job_test (
    seq number,
    insert_date date);
    
create or replace procedure ch15_job_test_proc
is
    vn_next_seq number;
    
begin
    -- 다음 순번을 가져온다.
    select nvl(max(seq), 0) + 1
      into vn_next_seq
      from ch15_job_test;
      
    -- ch15_job_test 테이블에 insert
    insert into ch15_job_test values (vn_next_seq, sysdate);
    
    commit;
exception when others then
    rollback;
    dbms_output.put_line(sqlerrm);
end;
/

DBMS_JOB.SUBMIT (
    job         OUT binary_integer, -- 잡 번호. 출력 변수로 자동으로 번호가 매겨진다.
    what        in varchar2, -- 실행될 프로그램, 문자열 형태로 sql이나 pl/sql 이 온다. (예: 위에서 만들었던 ch15_job_test_proc와 같은 프로시저)
    next_date   in date default sysdate, -- 잡이 실행될 다음 날짜 (시간), 디폴트 잡은 sysdate
    interval    in varchar2 default 'NULL', -- 잡의 실행 주기로, 문자열 형태의 값
    no_parse    in boolean default false, -- false 로 설정하면, no_parse 가 아니니 parse 임. false로 설정하면 오라클은 해당 잡과 연관된 프로시저를 파싱하고, true 로 설정하면 잡이 맨 처음 실행됐을 때만 파싱한다.
    instance    in binary_integer default any_instance,
    force       in boolean default false
);

-- 1분에 1회: SYSDATE + 1/60/24
-- 30초에 1회: SYSDATE + 30/60/60/24
-- 10초에 1회: SYSDATE + 10/60/60/24

-- 매주 일요일 오후 3시마다 수행: NEXT_DAY( TRUNC(SYSDATE), '일요일' ) + 15/24
-- 매주 수요일 오후 11시마다 수행: NEXT_DAY( TRUNC(SYSDATE), '수요일' ) + 23/24
-- 매월 마지막 날 오후 6시 30분에 수행: LAST_DAY( TRUNC(SYSDATE) + 18/24 + 30/60/24 )

select to_char( trunc(sysdate), 'yyyymmdd hh24miss') from dual;

declare
    v_job_no number;
begin
    -- 현재 시간 기준 1분에 1번씩 ch15_job_test_proc 프로시저를 실행하는 잡 등록
    dbms_job.submit ( 
        job => v_job_no,
        what => 'ch15_job_test_proc();', -- note1: semicolon 이 있네.
        next_date => SYSDATE,
        interval => 'SYSDATE + 1/60/24'
    );
    
    COMMIT; -- note2 COMMIT 이 있어야 하네.
    
    -- note3. 마지막으로, 등록할 잡 번호는 시스템에서 자동 생성해주므로 submit 프로시저를 호출할 때는
    -- 잡 번호를 받을 변수를 지정할 수 있도록 익명 블록 형태로 실행해야 한다.
    
    -- 시스템에서 자동 생성된 잡 번호 출력
    dbms_output.put_line('v_job_no : ' || v_job_no);
end;
/

select job, last_date, last_sec, next_date, next_sec, broken, interval, failures, what
from user_jobs;

DBMS_JOB.BROKEN (
    job         IN binary_integer, -- 잡 번호
    broken      IN BOOLEAN, -- 잡을 중지할 때는 true, 다시 실행할 때는 false
    next_date   IN date default sysdate -- 잡이 중지되거나 재실행될 날짜(시간), 생략가능하며 디폴트 값은 sysdate
);

begin
    -- 잡 중지
    dbms_job.broken( 1, true );
    commit; -- 이것도 commit 을 해야 하는 군.
end;
/

begin
    -- 잡 재실행
    dbms_job.broken(1, false);
    commit;
end;
/

DBMS_JOB.CHANGE (
    job         IN binary_integer, -- 잡 번호.
    what        in varchar2, -- 실행될 프로그램, 문자열 형태로 sql이나 pl/sql 이 온다. (예: 위에서 만들었던 ch15_job_test_proc와 같은 프로시저)
    next_date   in date default sysdate, -- 잡이 실행될 다음 날짜 (시간), 디폴트 잡은 sysdate
    interval    in varchar2 default 'NULL', -- 잡의 실행 주기로, 문자열 형태의 값
    instance    in binary_integer default any_instance,
    force       in boolean default false
);
truncate table ch15_job_test;
begin
    -- 잡 편집
    dbms_job.change(
        job => 1,
        what => 'ch15_job_test_proc;',
        next_date => sysdate,
        interval=> 'sysdate + 3/60/24');
    commit;
end;
/

-- 잡의 실행: 주기에 상관없이 강제로 실행할 수도 있다.
dbms_job.run (
    job         IN binary_integer,
    force       IN boolean default false -- 이건 생략 가능, 뭐가 문제여도 실행할 수 있다 이겠지.
);

begin
    -- 잡 강제 실행
    dbms_job.run(1);
    commit;
end;
/
    
-- 잡의 삭제
dbms_job.remove (
    job IN binary_integer );
    
begin
    dbms_job.remove(1);
    commit;
end;
/

----------------------------------------------------------------
-- DBMS_SCHEDULRE.
-- 프로그램 객체 생성
----------------------------------------------------------------

DBMS_SCHEDULER.CREATE_PROGRAM (
    program_name IN varchar2, -- 프로그램 객체의 고유 이름. 원하는 명칭을 입력. (음. 프로그램도 이름을 입력할 수 있게 하였군.)
    program_type IN varchar2, -- 'PLSQL_BLOCK | PROCEDURE | EXECUTABLE'
    program_action IN varchar2, -- 실제 수행될 익명 블록, 프로시저명, 외부 실행프로그램. (이건  DBMS_JOB. 과 같네. string 이라는 것.)
    number_of_arguments IN PLS_INTEGER default 0, -- 속도가 빠른 순으로 pls_integer, binary_integer, number. [number] 를 쓰는 것은 바보같다.
    enabled IN boolean default false, -- 생성할 프로그램 객체의 활성화 여부
    comments IN varchar2 default null -- 프로그램 객체에 대한 주석.
);

begin
dbms_scheduler.create_program (
    program_name => 'my_program1',
    program_type => 'STORED_PROCEDURE',
    program_action => 'ch15_job_test_proc',
    comments => '첫번째 프로그램'
);

-- NO COMMIT!!! 
end;
/

select program_name, program_type, program_action, number_of_arguments, enabled, comments
  from user_scheduler_programs;
  
----------------------------------------------------------------
-- DBMS_SCHEDULRE.
-- 스케줄 객체 생성
--
-- 스케줄 객체에서 중요한 항목은 [언제] 와 [얼마나 자주] 이다.
----------------------------------------------------------------
dbms_scheduler.create_schedule (
    schedule_name IN varchar2, -- 스케줄 객체의 고유 이름
    start_date IN TIMESTAMP WITH TIMEZONE default null, -- 스케줄 시작일자와 시간
    repeat_interval IN varchar2, -- 스케줄 수행 주기. 좀 더 정교한 주기 설정이 가능
    end_date IN TIMESTAMP WITH TIMEZONE defualt null, -- 스케줄 종료일자와 시간
    comments IN varchar2
);

FREQ:           수행 주기. 설정 값은 [ YEARLY, MONTHLY, WEEKLY, DAILY, HOURLY, MINUTELY, SECONDLY ]
INTERVAL:       수행 횟수. 디폰트 값은 1. 최대 설정 값은 99. (몇 번이나 수행할 수 있다는 것인가?)
BYMONTH:        월 단위 수행 시 해당 월을 명시
                예) 3월에 수행 -> BYMONTH=3 혹은 BYMONTH=MAR
BYWEEKNO:       주 단위 수행 시 주차번호를 명시
BYYEARDAY:      일 단위 수행 시 연도기준 일자(1~365)를 명시.
BYDATE:         일자 리스트를 YYYYMMDD(YYYY는 생략 가능) 형식으로 명시
                예) 1월 20일 수행 -> BYDATE = 0120
                    1월 10일, 2월 10일, 4월 15일 수행 -> BYDATE=0110,0210,0415
BYMONTHDAY:     일 단위, 월 기준 일자(1~31)를 명시
                음수를 입력하면 월 기준 이전 일자를 의미
BYDAY:          일 단위. 월요일에서 일요일까지 한 주의 일을 명시
                예) 두 번째 수요일 -> BYDAY = 2WED
BYHOUR:         시간 단위 수행. 0~23 시간을 명시
BYMINUTE:       분 단위 수행. 0~59분을 명시
BYSECOND:       초 단위 수행. 0~59초 명시
BYSETPOS:       다른 값의 위치를 명시하는 보조 수단의 설정 값
                (-1)이면 리스트의 맨 끝, (-2)면 맨 끝에서 두 번째, 1이면 맨 앞쪽에서 첫 번째를 의미
                FREQ 값이 MONTHLY, YEARLY 일 때만 사용 가능
                예) 근무일이 월요일~금요일 이라고 할 때 매월 마지막 근무일에 수행되도록 한다면,
                    FREQ=MONTHLY; BYDAY=MON,TUE,WED,THU,FRI; BYSETPOS=-1
INCLUDE:        CREATE_SCHEDULE 프로시저로 생성한 다른 스케줄을 포함할 때 사용
EXCLUDE:        CREATE_SCHEDULE 프로시저로 생성한 다른 스케줄을 배제할 때 사용.

* 월요일 수행 ->             FREQ=DAILY; BYDAY=MON; (일별 주기, 월요일에 수행) 혹은
                            FREQ=WEEKLY; BYDAY=MON; (주별 주기, 월요일에 수행) 혹은
                            FREQ=YEARLY; BYDAY=MON; (연도별 주기, 월요일에 수행)
* 격주차로 월요일 수행 ->    FREQ=WEEKLY; INTERVAL=2; BYDAY=MON;
* 매월 마지막날 수행 ->     FREQ=MONTHLY; BYMONTHDAY=-1;
* 매년 5월 10일 수행 ->       FREQ=YEARLY; BYMONTH=MAY; BYMONTHDAY=10; 혹은
                            FREQ=YEARLY; BYDATE=0510;
* 매월 25일 수행 ->          FREQ=MONTHLY; BYMONTHDAY=25;
* 매월 두 번째 수요일 수행 ->         FREQ=MONTHLY; BYDAY=2WED;
* 매일 오전 6시, 오후 6시에 수행 ->    FREQ=DAILY; BYHOUR=06,18;
* 1시간마다 수행 ->           FREQ=HOURLY; INTERVAL=1;
                            ( 이 경우 시작 시간 기준으로 1시간마다 1번씩 수행됨 )
* 매 시간 10분에 한 번씩 수행 ->      FREQ=HOURLY; INTERVAL=1; BYMINUTE=10;
* 1분마다 수행 ->            FREQ=MINUTELY; INTERVAL=1;

begin
    dbms_scheduler.create_schedule (
        schedule_name => 'my_schedule1',
        start_date => null,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=1', -- 1분에 1번
        end_date => null,
        comments => '1분마다 수행'
    );
end;
/

select schedule_name, schedule_type, start_date, repeat_interval, end_date, comments
  from user_scheduler_schedules; -- schedule_type 이 [CALENDAR] 인데, 이것은 [PL/SQL 표현식] 이 아닌 [달력 표현식] 을 사용해서 이다.

----------------------------------------------------------------
-- DBMS_SCHEDULRER.CREATE_JOB (
-- 잡 객체 생성
--
----------------------------------------------------------------

-- 버전 1 - 잡 객체 단독으로 사용하는 경우
DBMS_SCHEDULER.CREATE_JOB (
    job_name            IN varchar2, -- 고유 이름
    job_type            IN varchar2, -- CREATE_PROGRAM 의 program_type 매개변수와 동일
    job_action          IN varchar2, -- CREATE_PROGRAM 의 program_action 매개변수와 동일
    number_of_arguments IN pls_integer default 0, -- CREATE_PROGRAM 의 number_of_arguments 매개변수와 동일
    start_date          IN timestamp with time zone default null, -- CREATE_SCHEDULE 의 start_date 매개변수와 동일
    repeat_interval     IN varchar2 default null, -- CREATE_SCHEDULE 의 repeat_interval 매개변수와 동일
    end_date            IN timestamp with time zone default null,
    job_class           IN varchar2 default 'DEFAULT_JOB_CLASS', -- 잡 클래스
    enabled             IN boolean default false, -- 활성화 여부, 디폴트 값은 false
    auto_drop           IN boolean default true, -- true 이면 수행 후 자동 drop
    comments            IN varchar2 default null,
);

-- 버전 1은 잡 객체 단독으로 사용하므로 프로그램 객체와 스케줄 객체를 생성하면서 필요한 정보를 매개변수로 다 전달받아야 한다.

-- 버전 2 - 프로그램, 스케줄 객체를 모두 사용하는 경우
DBMS_SCHEDULER.CREATE_JOB (
    job_name        IN varchar2,
    program_name    IN varchar2, -- 프로그램 객체명
    schedule_name   IN varchar2, -- 스케줄 객체명
    job_class           IN varchar2 default 'DEFAULT_JOB_CLASS',
    enabled             IN boolean default false,
    auto_drop           IN boolean default true,
    comments            IN varchar2 default null,
    job_style       IN varchar2 default 'REQULAR', -- 프로그램 객체를 사용할 때만 명시('REGULAR' -> 일반적인 경우, 'LIGHTWEIGHT' -> 수행시간이 짧은 대신 빈번히 수행될 경우)
);

-- 버전 3 - 프로그램 객체만 사용하는 경우
DBMS_SCHEDULER.CREATE_JOB (
    job_name        IN varchar2,
    program_name    IN varchar2, -- 프로그램 객체명
    start_date          IN timestamp with time zone default null, -- CREATE_SCHEDULE 의 start_date 매개변수와 동일
    repeat_interval     IN varchar2 default null, -- CREATE_SCHEDULE 의 repeat_interval 매개변수와 동일
    end_date            IN timestamp with time zone default null,
    job_class           IN varchar2 default 'DEFAULT_JOB_CLASS',
    enabled             IN boolean default false,
    auto_drop           IN boolean default true,
    comments            IN varchar2 default null,
    job_style       IN varchar2 default 'REQULAR', -- 프로그램 객체를 사용할 때만 명시('REGULAR' -> 일반적인 경우, 'LIGHTWEIGHT' -> 수행시간이 짧은 대신 빈번히 수행될 경우)
);

-- 버전 4 - 스케줄 객체만 사용하는 경우
DBMS_SCHEDULER.CREATE_JOB (
    job_name        IN varchar2,
    schedule_name   IN varchar2, -- 스케줄 객체명
    job_type            IN varchar2, -- CREATE_PROGRAM 의 program_type 매개변수와 동일
    job_action          IN varchar2, -- CREATE_PROGRAM 의 program_action 매개변수와 동일
    number_of_arguments IN pls_integer default 0, -- CREATE_PROGRAM 의 number_of_arguments 매개변수와 동일
    job_class           IN varchar2 default 'DEFAULT_JOB_CLASS',
    enabled             IN boolean default false,
    auto_drop           IN boolean default true,
    comments            IN varchar2 default null,
    job_style       IN varchar2 default 'REQULAR', -- 프로그램 객체를 사용할 때만 명시('REGULAR' -> 일반적인 경우, 'LIGHTWEIGHT' -> 수행시간이 짧은 대신 빈번히 수행될 경우)
);

----------------------------------------------------------------
-- 객체 활성화와 비활성화
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
-- 객체 속성 변경
--
----------------------------------------------------------------
DBMS_SCHEDULER.SET_ATTRIBUTE (
    name        IN varchar2, -- 속성값을 바꿀 객체명
    attribute   IN varchar2, -- 속성값을 바꿀 객체의 속성명 ex) start_date, repeat_interval, job_action, number_of_arguments, ...
    value       IN {BOOLEAN|DATE|TIMESTAMP|TIMESTAMP WITH TIME ZONE|TIMESTAMP WITH LOCAL TIME ZONE|INTERVAL DAY TO SECOND}
);
DBMS_SCHEDULER.SET_ATTRIBUTE (
    name        IN varchar2,
    attribute   IN varchar2,
    value       IN varchar2,
    value2      IN varchar2 default null -- 대부분의 속성은 값이 1개지만, 값이 2개인 속성도 있으면 이럴 때 사용
);
-- 속성 값을 NULL 로 설정해야 한다면, set_attribute_null 프로시저를 사용한다.
DBMS_SCHEDULER.SET_ATTRIBUTE_NULL (
    name        IN varchar2,
    attribute   IN varchar2
);

----------------------------------------------------------------
-- 객체 삭제
--
----------------------------------------------------------------
DBMS_SCHEDULER.DROP_PROGRAM (
    program_name        IN varchar2, -- 삭제할 프로그램 객체명.
    force               IN boolean default false -- FALSE -> 참조하는 JOB 이 있으면 오류 발생, TRUE -> 참조하는 JOB 이 비활성화 됨.
);

DBMS_SCHEDULER.DROP_SCHEDULE (
    schedule_name       IN varchar2, -- 삭제할 스케줄 객체명
    force               IN boolean default false -- FALSE -> 참조하는 JOB 이 있으면 오류 발생, TRUE -> 참조하는 JOB 이 비활성화 됨.
);

DBMS_SCHEDULER.DROP_JOB (
    job_name            IN varchar2,
    force               IN boolean default false, -- TRUE 로 설정하면 먼저 실행되고 있는 잡을 중단시킨 다음 잡을 삭제
    defer               IN boolean default false, -- TRUE 로 설정하면 수행되고 있는 잡이 완료된 다음에 잡을 삭제
    commit_semantics    IN varchar2 default 'STOP_ON_FIRST_ERROR'
);

----------------------------------------------------------------
-- 잡 객체만을 이용한 스케줄링
begin
    dbms_scheduler.create_job (
        job_name            => 'my_job1',
        job_type            => 'STORED_PROCEDURE',
        job_action          => 'ch15_job_test_proc',
        repeat_interval     => 'FREQ=MINUTELY; INTERVAL=1', -- 1분에 1번
        comments            => '버전1 잡객체'
    );
end;
/

----------------------------------------------------------------
-- JOBS 조회
----------------------------------------------------------------
-- JOBS 조회
select job_name, program_name, job_style, job_type, job_action, schedule_name, schedule_type, repeat_interval, 
    enabled, auto_drop, state, comments
  from user_scheduler_jobs;
  
-- JOB 이 일을 잘하고 있는지
select log_id, log_date, job_name, operation, status
  from user_scheduler_job_log
-- where job_name = 'MY_JOB1'
;

-- 좀 더 상세한 로그
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
-- 기존에 만들었던 프로그램과 스케줄 

begin
    dbms_scheduler.create_job(
        job_name => 'my_job2',
        program_name => 'MY_PROGRAM1',
        schedule_name => 'MY_SCHEDULE1',
        comments => '버전2 잡객체' 
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

-- 1. ch15_changed_object 테이블

create table ch15_changed_object (
    object_name varchar2(128), -- 객체명
    object_type varchar2(50), -- 객체 유형
    created date, -- 객체 생성일자
    last_ddl_time date, -- 객체 변경일자
    status varchar2(7), -- 객체 상태
    creation_date date -- 생성일자
);

-- 2. ch15_check_objects_prc 프로시저: 일주일 간 수정된 객체정보가 있는지 파악하는 프로시저

create or replace procedure ch15_check_objects_prc
is
    vn_cnt number := 0;
begin
    -- 일주일 간 변경된 객체 중 ch15_changed_object 에 없는 객체만 찾는다.
    -- 왜냐하면 이전 프로시저 수행 시 변경된 객체가 있으면 이미 ch15_changed_object 에 입력됐기 때문이다.
    -- 일주일간 변경된 object 를 찾는데, 한번만 기록되면 된다는 말이군. 왜냐하면 테스트 이니까.
    select count(*)
      into vn_cnt
      from user_objects a
     where last_ddl_time between sysdate - 7 and sysdate
       and not exists (
            select 1
              from ch15_changed_object b
             where a.object_name = b.object_name )
    ;
    
    -- 변경된 객체가 없으면 RAISE_APPLICATION_ERROR 를 발생시켜 에러코드를 넘긴다
    -- 에러코드를 넘기는 이유는 룰에서 처리하기 위함이다.
    if vn_cnt = 0 then
        RAISE_APPLICATION_ERROR(-20001, '변경된 객체 없음');
    end if;
end;
/

-- 3. ch15_make_objects_prc 프로시저: 변경된 객체 정보를 ch15_changed_object 테이블에 저장하는 프로시저

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

-- 4. 위 두 개의 프로시저에 대한 프로그램 객체 2개
begin
    -- ch15_check_objects_prc 에 대한 프로그램 객체 생성
    dbms_scheduler.create_program (
        program_name => 'MY_CHAIN_PROG1',
        program_type => 'STORED_PROCEDURE',
        program_action => 'ch15_check_objects_prc',
        comments => '첫번째 체인 프로그램'
    );
    
    -- ch1_make_objects_proc 에 대한 프로그램 객체 생성
    dbms_scheduler.create_program (
        program_name => 'MY_CHAIN_PROG2',
        program_type => 'STORED_PROCEDURE',
        program_action => 'ch15_make_objects_prc',
        comments => '두번째 체인 프로그램'
    );
    
    -- 프로그램 객체 활성화
    dbms_scheduler.enable ('MY_CHAIN_PROG1');
    dbms_scheduler.enable ('MY_CHAIN_PROG2');
end;
/

-- 사전준비는 모두 끝났다.
-- 5. 체인 1개

begin
    dbms_scheduler.create_chain (
        chain_name => 'MY_CHAIN1',
        rule_set_name => null,
        evaluation_interval => null,
        comments => '첫 번째 체인'
    );
end;
/

-- 6. 스텝 2개

begin
    -- step 1
    dbms_scheduler.define_chain_step (
        chain_name => 'MY_CHAIN1',
        step_name => 'STEP1',
        program_name => 'MY_CHAIN_PROG1' -- 스텝은 프로그램과 연결되어 있다.
    );
    
    -- step 2
    dbms_scheduler.define_chain_step (
        chain_name => 'MY_CHAIN1',
        step_name => 'STEP2',
        program_name => 'MY_CHAIN_PROG2' -- 처음 오타를 쳐서 다시 만들었음.
    );
end;
/

-- 스텝을 잘못 만들었음.
-- https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12457

-- 결국은 oracle 참조 https://docs.oracle.com/database/121/ARPLS/d_sched.htm#ARPLS72340
begin

  -- 이건 실패. parameter 가 안 맞는다고 하는데 잘 모르겠음.
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
        program_name => 'MY_CHAIN_PROG2' -- 처음 오타를 쳐서 다시 만들었음.
    );
end;
/


-- 7. 룰 4개
begin
    -- 최초 STEP1을 시작시키는 룰
    dbms_scheduler.define_chain_rule (
        chain_name => 'MY_CHAIN1',
        condition => 'TRUE',
        action => 'START STEP1',
        rule_name => 'MY_RULE1',
        comments => 'START 룰'
    );
end;
/

begin
    -- 두 번째 룰, 일주일간 변경된 객체가 없다면 종료로 빠진다.
    -- 이는 STEP1 을 실행행 그 결과로 오류 코드를 받았을 때 종료하도록 처리한다.
    dbms_scheduler.define_chain_rule (
        chain_name => 'MY_CHAIN1',
        condition => 'STEP1 ERROR_CODE = 20001',
        action => 'END',
        rule_name => 'MY_RULE2',
        comments => '룰2'
    );
end;
/

begin
    -- STEP1 에서 STEP2 로 가는 룰
    dbms_scheduler.define_chain_rule (
        chain_name => 'MY_CHAIN1',
        condition => 'STEP1 SUCCEEDED', -- DSL 같군. [SUCCEEDED'
        action => 'START STEP2',
        rule_name => 'MY_RULE3',
        comments => '룰3'
    );
    
    -- STEP2 를 마치고 종료하는 룰
    dbms_scheduler.define_chain_rule (
        chain_name => 'MY_CHAIN1',
        condition => 'STEP2 SUCCEEDED',
        action => 'END',
        rule_name => 'MY_RULE4',
        comments => '룰4'
    );
end;
/

-- 8. 잡 객체 1개

begin
    dbms_scheduler.create_job (
        job_name => 'MY_CHAIN_JOBS',
        job_type => 'CHAIN', -- 체인을 실행하는 잡!
        job_action => 'MY_CHAIN1', -- 체인을 실행하는 잡!
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=1',
        comments => '체인을 실행하는 잡'
    );
end;
/

-- 체인, 스텝, 룰이 잘 만들어져 있는지.
select *
  from user_scheduler_chains;

select chain_name, step_name, program_name, step_type, skip, pause
  from user_scheduler_chain_steps;
  
select *
  from user_scheduler_chain_rules;
  
-- 체인과 잡을 활성화

-- 일단 잘못된 잡을 정지하고, 
begin
    dbms_scheduler.disable( name => 'MY_CHAIN_JOBS', force => true);
    dbms_scheduler.disable('MY_CHAIN1');
end;
/

begin
    -- 체인 활성화
    dbms_scheduler.enable('MY_CHAIN1');
    
    -- 잡 활성화
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
