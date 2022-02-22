-- system/oracle

alter user FORGE quota 128M on users;
GRANT UNLIMITED TABLESPACE TO FORGE;

grant create session to FORGE;

-- 테이블 스페이스 확인
select tablespace_name, file_name, bytes from dba_data_files;

-- 사용자 확인/ Default Tablespace
select username, default_tablespace from dba_users;

select table_name, tablespace_name, owner from dba_tables where owner = 'HR';

select distinct owner from dba_tables;

select * from hr.employees;

-- HR 유저의 passwd 를 1111 로 설정.
alter user hr identified by 1111;

-- 이후 접속하려니 [the account is locked] 가 걸려서...
select * from dba_users;
alter user hr account unlock; -- 이 명령으로 풀음.

GRANT CONNECT, DBA, RESOURCE TO hr;

----------------------------------------------------------------
-- 시간대 맞추기
----------------------------------------------------------------

select sysdate, systimestamp from dual;

select dbtimezone, sessiontimezone from dual;
-- -> +00:00, Asia/Seoul

alter database set time_zone = '+09:00';

-- 결국 [우분투 리눅스 타임존 설정] 하고,
  -- https://www.lesstif.com/lpt/ubuntu-linux-timezone-setting-61899162.html
  
-- 디비 시간대를 맞추어서
  -- https://forgiveall.tistory.com/590

-- 해결함.

----------------------------------------------------------------
-- ora_user 의 sales 칼럼을 가져오기 위하여.
-- 결국은 sales 자체가 없었음. xe 버전은 HR 만 설치되서인 것 같음.
----------------------------------------------------------------

-- 테이블 스페이스 생성

CREATE TABLESPACE myts DATAFILE 
 '/home/oracle/myts.dbf' SIZE 100M AUTOEXTEND ON NEXT 5M;
 
 
-- 사용자 생성
CREATE USER ora_user IDENTIFIED BY hong 
DEFAULT TABLESPACE MYTS
TEMPORARY TABLESPACE TEMP;

-- DBA 롤 부여
GRANT DBA TO ora_user;

----------------------------------------------------------------

select distinct owner from all_tables;

----------------------------------------------------------------
-- Insufficient Privileges Create table CTAS

grant create any table to anonymous; -- 이게 되나? 안됨!
grant resource to forge; -- 결국 모두 실패.
GRANT CONNECT, DBA, RESOURCE TO forge; -- 결국 모두 실패

grant create table to forge; -- 이게 성공함.

----------------------------------------------------------------
