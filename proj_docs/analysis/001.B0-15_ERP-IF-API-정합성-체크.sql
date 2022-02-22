-- #
-- # 1. ��� sql ������Ʈ ���� �۾��� �۾� ��� ����-QC-��� ����ȭ ��Ų��.
-- #

select --*
    object_name,
    object_type, -- ��ü �������� FUNCTION, INDEX, PACKAGE, PACKAGE BODY, PROCEDURE, TABLE, TABLE PARTITION, TYPE
    to_char(created, 'yyyymmdd hh24miss') as created,
    to_char(last_ddl_time, 'yyyymmdd hh24miss') as last_ddl_time,
    status
  from user_objects
 where 1=1
   and object_type <> 'INDEX PARTITION' -- 2804 BIN, SYS...
   and object_type <> 'INDEX'
   and object_type <> 'LOB' -- 28 SYS_LOB...
   and object_type <> 'LOB PARTITION'  -- 556 SYS_LOB00..
--   and object_type = 'LOB PARTITION'
   and object_type <> 'TABLE PARTITION' --1652 BIN$...
--   and object_type = 'TABLE PARTITION'
--   and object_name not like 'TB_%'
   
--   and object_type = 'FUNCTION' -- 21��.
--   and status = 'INVALID' -- 7��.

   and object_type = 'PROCEDURE' -- 133��.
   and object_name like 'ERP%'
--   and status = 'INVALID' -- 67��.

--   and object_type = 'PACKAGE BODY' -- 31��.
--   and status = 'INVALID' -- 12��.

--   and object_type = 'TABLE' -- 733��.
--   and object_name like 'TB_BAS_ITEM%'

 order by object_type, object_name;