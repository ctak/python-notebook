/*

- B0-6. ����� TO-BE ��Ű��.
  * A. ���̺��� AS-IS.��� �ִµ� TO-BE.���߿� ���ٸ� => ���̺��� �����ϰ� ������ ���̱׷��̼��� Ȯ���ؾ� �Ѵ�.
      -> 2�� ���̺� �����Ͽ���, 2�� ���̺��� ����ȭ ����.
  * B. ���̺��� TO-BE.���߿� �ִµ� AS-IS.��� ���ٸ� => ���̺��� �����Ѵ�.
      -> @TODO ����� �±�, �Ҹ��� ���� 8�� ���̺� �����ϰ� ������ �־�� ��. by ���ֿ�
  * C. Į���� AS-IS.��� �ִµ� TO-BE.���߿� ���ٸ� => ���ߵ��߿� ����� ������� ���̰� Į���� �����Ѵ�.
      -> ���߿� 2�� ���̺��� ����� ����. ���̱׷��̼ǰ� ��� ���� ���̺���.
  * D. Į���� TO-BE.���߿� �ִµ� AS-IS.��� ���ٸ� => ���ߵ��߿� ���߿��� ������� ���̰� TOBE� �� Į���� �����ؾ� �ϰ�, AS-IS.� ���̱׷��̼� �� insert table (COLUMNS) �� �ʿ��ϴ�.
      -> ��� 2�� ���̺� 3�� Į�� �߰���. ���̱׷��̼ǰ� ��� ���� ���̺���.
  * E. C�� ����� TOBE���߿� �ϴ� Į�� ��Ű���� �߰��� ���� ����ؼ� ���̱׷��̼� �۾��� �ϸ� �ȴ�.
      -> ���̱׷��̼� �۾� �ʿ����.
  * F. D�� ����̰� ������Ʈ�� �ʿ����� �ʴٸ� �̸� Į���� �����ص� �ȴ�.
      -> ���̱׷��̼� �۾� �ʿ����.
  * G. SEQUENCE ��Ű�� Ȯ��.
  
- �� �۾� �ó�����.
  1. TO-BE.����.MEMSNX ���� ASIS� VIEW �� �����Ͽ� ����� ���Ѵ�.

*/

----------------------------------------------------------------
-- 1. TO-BE.����.MEMSNX ���� ASIS� VIEW �� �����Ͽ� ����� ���Ѵ�.
--    �� ��, TO-BE.�.MEMSNX �� 4/8 ���ڷ� ����ȭ �Ǿ� ������ �����ؾ� �Ѵ�.
--    �׸��� tablespace ���� �ٸ��ٴ� ���� �����. ����: MEMS_DAT, QC: MEMS_DAT, �: TBS_MEMS
--
----------------------------------------------------------------

select * from no_vw_mems_tables@dbl_sales;
select * from no_vw_mems_columns@dbl_sales;
select * from no_vw_mems_indexes@dbl_sales;

-- A ã��
select distinct table_name from no_vw_mems_tables@dbl_sales
MINUS
select distinct table_name from user_tables
;
/*
TB_MEM_ACTION_LOG -> TOBE.� �� �־ DDL �� ����� ����, QC �� ������. @okay
TB_MEM_SEARCH_LOG -> TOBE.� �� �־ DDL �� ����� ����, QC �� ������. @okay
TB_ONLINE_ORDER_20210401 -> ����. @okay
TB_ONLINE_ORDER_20210405 -> ����. @okay
*/

-- Bã��.

select distinct table_name from user_tables 
 where table_name not like 'BK_%'
MINUS
select distinct table_name from no_vw_mems_tables@dbl_sales
;

/*

-- �� ���̺��� ���� ����� �±ް� �Ҹ��� ���� �ʿ��� ���̺�� ����� ��������� ������ �־����� ��. by ���ֿ�k.

LEGERP_TB_CICS
ONEBN_MBR_INFO
ONEBN_ORD_CL_DLV
ONEBN_ORD_CL_DLV_LOC_GOODS
ONEBN_ORD_CL_INFO
ONEBN_ORD_CL_PAY
ONEBN_SHOP_ORDER_ADMIN
ONEBN_SHOP_ORDER_DETAIL

*/

-- C ã��
select * from (
select table_name, column_id, column_name from no_vw_mems_columns@dbl_sales -- �� 2445��.
MINUS
select table_name, column_id, column_name from user_tab_columns
) a
 where 1=1
   and table_name <> 'TB_ONLINE_ORDER_20210401'
   and table_name <> 'TB_ONLINE_ORDER_20210405'
 order by 1,2,3
;

/*
-- TOBE��� �ִ��� üũ. -> ��� ������� ����. @okay
-- TOBE���߿� TB_MILEAGE_MOD_REQ_IF �� ������ �ٲ� ����. -> ���� �ٲٱ�.( ���̺� drop �� ����� ). QC����. @okay
-- TOBE���߿� TB_MILEAGE_MOD_RES_IF -> ���� �ٲٱ�.( ���̺� drop �� ����� ). QC����. @okay

TB_MILEAGE_MOD_REQ_IF	23	DIV_CD
TB_MILEAGE_MOD_REQ_IF	24	ORD_NO
TB_MILEAGE_MOD_RES_IF	22	CH_TP_CD
TB_MILEAGE_MOD_RES_IF	23	SHOP_CD
*/

-- D ã��.
select * from (
select table_name, column_id, column_name from user_tab_columns
MINUS
select table_name, column_id, column_name from no_vw_mems_columns@dbl_sales
)
 where table_name not like 'BK_%'
   and table_name <> 'LEGERP_TB_CICS'
   and table_name not like 'ONEBN%'
 order by 1,2,3
;
/*
-- tb_erp_batch_log.if_msgid �� ��� �߰��ؾ� �ϰ���. ���̱׷��̼ǰ� �������.
-- tb_prom_mst.erp_* Į������ ��� �߰��ؾ� �ϰ���. ���̱׷��̼ǰ� ������� (����� ���� ���ǿ���). 
TB_ERP_BATCH_LOG	9	IF_MSGID
TB_PROM_MST	50	ERP_PROM_CD
TB_PROM_MST	51	ERP_OFFR_CD

----------------------------------------------------------------
-- � ���� SQL

ALTER TABLE TB_ERP_BATCH_LOG ADD ( IF_MSGID VARCHAR2(30 BYTE) );

COMMENT ON COLUMN MEMSNX.TB_ERP_BATCH_LOG.IF_MSGID IS '�������̽� ó��ID';

ALTER TABLE TB_PROM_MST ADD ( ERP_PROM_CD VARCHAR2(10 BYTE) );
ALTER TABLE TB_PROM_MST ADD ( ERP_OFFR_CD VARCHAR2(20 BYTE) );

COMMENT ON COLUMN MEMSNX.TB_PROM_MST.ERP_PROM_CD IS 'ERP���θ���ڵ�';
COMMENT ON COLUMN MEMSNX.TB_PROM_MST.ERP_OFFR_CD IS 'ERP OFFER�ڵ�';

----------------------------------------------------------------

*/