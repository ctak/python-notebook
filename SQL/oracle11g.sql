-- system/oracle

alter user FORGE quota 128M on users;
GRANT UNLIMITED TABLESPACE TO FORGE;

grant create session to FORGE;

-- ���̺� �����̽� Ȯ��
select tablespace_name, file_name, bytes from dba_data_files;

-- ����� Ȯ��/ Default Tablespace
select username, default_tablespace from dba_users;

select table_name, tablespace_name, owner from dba_tables where owner = 'HR';

select distinct owner from dba_tables;

select * from hr.employees;

-- HR ������ passwd �� 1111 �� ����.
alter user hr identified by 1111;

-- ���� �����Ϸ��� [the account is locked] �� �ɷ���...
select * from dba_users;
alter user hr account unlock; -- �� ������� Ǯ��.

GRANT CONNECT, DBA, RESOURCE TO hr;

----------------------------------------------------------------
-- �ð��� ���߱�
----------------------------------------------------------------

select sysdate, systimestamp from dual;

select dbtimezone, sessiontimezone from dual;
-- -> +00:00, Asia/Seoul

alter database set time_zone = '+09:00';

-- �ᱹ [����� ������ Ÿ���� ����] �ϰ�,
  -- https://www.lesstif.com/lpt/ubuntu-linux-timezone-setting-61899162.html
  
-- ��� �ð��븦 ���߾
  -- https://forgiveall.tistory.com/590

-- �ذ���.

----------------------------------------------------------------
-- ora_user �� sales Į���� �������� ���Ͽ�.
-- �ᱹ�� sales ��ü�� ������. xe ������ HR �� ��ġ�Ǽ��� �� ����.
----------------------------------------------------------------

-- ���̺� �����̽� ����

CREATE TABLESPACE myts DATAFILE 
 '/home/oracle/myts.dbf' SIZE 100M AUTOEXTEND ON NEXT 5M;
 
 
-- ����� ����
CREATE USER ora_user IDENTIFIED BY hong 
DEFAULT TABLESPACE MYTS
TEMPORARY TABLESPACE TEMP;

-- DBA �� �ο�
GRANT DBA TO ora_user;

----------------------------------------------------------------

select distinct owner from all_tables;

----------------------------------------------------------------
-- Insufficient Privileges Create table CTAS

grant create any table to anonymous; -- �̰� �ǳ�? �ȵ�!
grant resource to forge; -- �ᱹ ��� ����.
GRANT CONNECT, DBA, RESOURCE TO forge; -- �ᱹ ��� ����

grant create table to forge; -- �̰� ������.

----------------------------------------------------------------
