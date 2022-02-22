/*

- TB_SYS_USER_AUTH_SHOP_�귣��_���̱׷��̼�
  * A. ��� ������ Ȯ��.
  
- �� �۾� �ó�����.
  1. TO-BE.����.MEMSNX ���� ASIS� VIEW �� �����Ͽ� ����� ���Ѵ�.

*/

----------------------------------------------------------------
-- 1. tb_sys_comm_cd �� tb_sys_comm_cd_dtl ���� ã��. �׸��� �� ���� NO_VW_BRAND_CD �����.
----------------------------------------------------------------
select * from tb_sys_comm_cd
 where comm_nm like '%�귣��%'
;

select * from tb_sys_comm_cd_dtl;

select b.*
  from tb_sys_comm_cd a,
       tb_sys_comm_cd_dtl b
 where a.comm_cd = b.comm_cd
   and a.comm_nm like '%�귣��%'
 order by 1,2
;

-- �ᱹ comm_cd: BRAND_CD �´�.
select b.*
  from tb_sys_comm_cd a,
       tb_sys_comm_cd_dtl b
 where a.comm_cd = b.comm_cd
   and a.comm_nm like '%�귣��%'
   and a.comm_cd <> 'ITEM_BRAND_CD'
   and a.comm_cd <> 'SBRAND_DIV_CD'
   and a.comm_cd <> 'BRAND_TP_CD'
 order by b.comm_cd, b.sort_no
;

-- old_cd �� tb_sys_comm_cd_dtl.ref_1_val �� �ִ´�.

update tb_sys_comm_cd_dtl set ref_1_val = 'FA140010',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '11';
update tb_sys_comm_cd_dtl set ref_1_val = 'FA140050',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '12';
update tb_sys_comm_cd_dtl set ref_1_val = 'FA140170',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '13';

update tb_sys_comm_cd_dtl set ref_1_val = 'FA140070',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '14';
update tb_sys_comm_cd_dtl set ref_1_val = 'FA140020',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '15';
commit;

-- ���� �並 ������. NO_VW_BRAND_CD
select comm_cd, comm_dtl_cd, comm_dtl_nm,
    ref_1_val as old_cd,
    sort_no, use_yn
  from tb_sys_comm_cd_dtl
 where comm_cd = 'BRAND_CD'
 order by sort_no;
 
create or replace view NO_VW_BRAND_CD as
select comm_cd, comm_dtl_cd, comm_dtl_nm,
    ref_1_val as old_cd,
    sort_no, use_yn
  from tb_sys_comm_cd_dtl
 where comm_cd = 'BRAND_CD'
 order by sort_no;
 
 
select * from NO_VW_BRAND_CD;

----------------------------------------------------------------
-- 2. TB_SYS_USER_AUTH_SHOP �� CTAS �� ����ϰ�

----------------------------------------------------------------

select * from TB_SYS_USER_AUTH_SHOP;
select distinct auth_trg_id from TB_SYS_USER_AUTH_SHOP;

-- ���̺� ������ ��ȸ, ����: 2M, QC: 2M, �: 2M
select
    segment_name, round(bytes/1024/1024, 2) as megabytes
  from user_segments
 where segment_type = 'TABLE'
   and segment_name not like 'BK_%'
   and segment_name not like 'MIG_%'
   and segment_name not like 'TB_CARD_MILEAGE_2019%'
   and segment_name not like 'TMP_%'
   and segment_name = 'TB_SYS_USER_AUTH_SHOP'
 order by segment_name
;

----------------------------------------------------------------
-- 3. AS-IS ���� ������ ���� �� ����� �����

----------------------------------------------------------------

/*
begin
    -- �� ������ sysdba �� �� �� �� ������ �־�� ������.
    no_pkg_mig.ctas_table('TB_SYS_USER_AUTH_SHOP', 'NO_BK_TB_SYS_USER_AUTH_SHOP');
end;
/
*/

select * from bk_program_log order by log_id desc;

create table NO_BK_TB_SYS_USER_AUTH_SHOP as select * from TB_SYS_USER_AUTH_SHOP;

select auth_trg_id, count(1) as cnt
  from NO_BK_TB_SYS_USER_AUTH_SHOP
 where 1=1
 group by auth_trg_id
 order by auth_trg_id
;

/*
-- ���. �� cnt �� ����.
11	2772
12	2771
13	2771
14	2771
*/

/*
-- �
11	3501
FA140050	3501
FA140070	3500
FA140170	3501
*/

/*
-- �ϴ� ������ �̹� ������Ʈ�� �� �������� �׽�Ʈ ��Ƽ� �������� ���� ����.
update TB_SYS_USER_AUTH_SHOP a
   set ( a.auth_trg_id ) = (
    select b.old_cd
      from no_vw_brand_cd b
     where b.comm_dtl_cd = '14' )
 where a.auth_trg_id = '14'
;
*/

select count(1) from TB_SYS_USER_AUTH_SHOP; -- ����: 11085, QC: 14003, �: 14003
----------------------------------------------------------------
-- 4. ������Ʈ �ϰ�

----------------------------------------------------------------

set serveroutput on;

declare
    -- Ŀ�� ����
    CURSOR c1 is
    select distinct auth_trg_id
      from TB_SYS_USER_AUTH_SHOP a, no_vw_brand_cd b
     where a.auth_trg_id = b.old_cd;
      
    -- �÷��� Ÿ�� ����
    type BrandCdTP is table of varchar2(100);
    
    -- ���� ����
    vst_BrandCd BrandCdTP; -- StringTable
    vs_brand_cd varchar2(100);
    
    vn_total_time number := 0;
    vs_prg_log varchar2(2000); -- �α׳���
begin
--    RAISE_APPLICATION_ERROR(-20000, '������ �Ƴ�!');

    vn_total_time := dbms_utility.get_time;
    
    open c1; -- OPEN Ŀ��
    
    -- BULK COLLECT
    fetch c1 BULK COLLECT INTO vst_BrandCd;
    
    dbms_output.put_line('brand_cd count: ' || vst_BrandCd.count);
    
    for i in 1..vst_BrandCd.count
    loop
        dbms_output.put_line('brand_cd: ' || vst_BrandCd(i));

        update TB_SYS_USER_AUTH_SHOP a
           set ( a.auth_trg_id ) = (
            select b.comm_dtl_cd
              from no_vw_brand_cd b
             where b.old_cd = vst_BrandCd(i) )
         where a.auth_trg_id = vst_BrandCd(i)
        ;
        
        dbms_output.put_line('rows: ' || sql%rowcount);
        
    end loop;
    
    commit;
    
    close c1; -- CLOSE Ŀ��
    
    vn_total_time := (dbms_utility.get_time - vn_total_time) / 100;
    vs_prg_log := '�ҿ� �ð�: ' || vn_total_time || chr(13);

    dbms_output.put_line(vs_prg_log);
exception when others then
    dbms_output.put_line(SQLERRM);
    rollback;

end;
/

/*
-- QC
brand_cd count: 4
brand_cd: FA140170
rows: 3501
brand_cd: FA140050
rows: 3501
brand_cd: FA140010
rows: 3501
brand_cd: FA140070
rows: 3500
�ҿ� �ð�: .28
*/

/*
-- �.
brand_cd count: 3
brand_cd: FA140170
rows: 3501
brand_cd: FA140050
rows: 3501
brand_cd: FA140070
rows: 3500
�ҿ� �ð�: .24
*/
----------------------------------------------------------------
-- 5. TO-BE ������ �Ѵ�.

----------------------------------------------------------------

select auth_trg_id, count(1) as cnt
  from TB_SYS_USER_AUTH_SHOP
 where 1=1
 group by auth_trg_id
 order by auth_trg_id
;

/*
-- �
11	3501
12	3501
13	3501
14	3500
*/

----------------------------------------------------------------
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