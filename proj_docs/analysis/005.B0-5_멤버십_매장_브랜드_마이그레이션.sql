/*

- B0-5. ����� ����/�귣�� ���̱׷��̼�
  * brand_cd �� �ִ� ���̺��� Ȯ���Ѵ�. �������� shop_cd �θ� �˻��߾���.
  * ���̺� size �� �����. ��� ���������� ����� �δ� �� ������. �ٽ� ������ �� ���ٰ� �ϴ�. �׷� ���̺����̽� size �� ��� ����?
  * �ϴ� TO-BE.*.MEMSNX �� VW_BAS_SHOP �� �����.(����� ���Ŀ��� ��� ���ܵд�.)
  
- ���:
  1. tb_card_mileage_mmio �� 4���� 5���� data �� insert �ϴ� ���� �´�.
  2. T0-BE ���߿����� tb_mem_addinfo �� tb_card_mst �� ������ �ִ� ���� ���ڴ�.

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

-- A �귣�� Į�� ã��

select * from no_vw_mems_columns@dbl_sales
 where column_name like '%BRAND%'
 order by table_name
;

select * from no_vw_mems_columns@dbl_sales
 where comments like '%�귣��%'
 order by table_name
;

select * from (
select * from no_vw_mems_columns@dbl_sales
 where column_name like '%BRAND%'
UNION
select * from no_vw_mems_columns@dbl_sales
 where comments like '%�귣��%'
)
order by table_name, column_id
;

-- �ᱹ ������Ʈ�� �ʿ��� ���̺��� ��: 5��. �� �߿� 3���� �ܵ�����.NO-UPDATE ��.
-- �ᱹ TB_COUP_MST �� TB_MEM_JOININFO �� SHOP �� BRAND �� ������Ʈ �ϸ�, 4/8�� ���ĵ� ������Ʈ �ؾ� ��.

select distinct DIV_CD from TB_CARD_PBL; -- Y -- �ܵ�����. NO-UPDATE
select distinct BRAND_CD from TB_CARD_TP; -- Y -- �ܵ�����. NO-UPDATE
select distinct BRAND_CD from TB_COUP_MST; -- Y

select distinct BRAND_CD from TB_FREQ_HIST; -- N

select distinct JOIN_BRAND_CD from TB_MEM_JOININFO; -- Y

select distinct BRAND_CD from TB_TERMS_MST; -- Y -- �ܵ� ����. NO-UPDATE

----------------------------------------------------------------
-- ���̺� ������ ��ȸ
----------------------------------------------------------------
select
    segment_name, round(bytes/1024/1024, 2) as megabytes
  from user_segments
 where segment_type = 'TABLE'
   and segment_name not like 'BK_%'
   and segment_name not like 'MIG_%'
   and segment_name not like 'TB_CARD_MILEAGE_2019%'
   and segment_name not like 'TMP_%'
 order by segment_name
;

select
    segment_name, round(bytes/1024/1024, 2) as megabytes
  from user_segments
 where segment_type = 'TABLE'
   and segment_name not like 'BK_%'
   and segment_name not like 'MIG_%'
   and segment_name not like 'TB_CARD_MILEAGE_2019%'
   and segment_name not like 'TMP_%'
 order by megabytes desc
;

/*
TB_CARD_MILEAGE_MMIO	67648
TB_MEM_GRADE_LOG	36112
TB_MILEAGE_HIST	35328
TB_MEM_GRADE_ADJ_HIST	17024
TB_CARD_MILEAGE_MMIO_BACK	3719
TB_MEM_MST	3269
TB_MEM_GRADE	3005
TB_COUP_HIST	3001
TB_CARD_MILEAGE	2564
TB_MEM_JOININFO	2432
TB_MEM_RECV_AGR	2368
TB_CARD_MST	2368
TB_MEM_GRADE_20200121	2240
TB_CARD_MILEAGE_MIG_20191121	2240
TB_MEM_JOININFO_20191220	2240
TB_MEM_GRADE_20191107_T	2176
TB_MEM_MILEAGE	2112
TB_MEM_ADDINFO	1984
*/

/*
�� �� �Ǿ �ñ��� ����.
mod_dtm �� reg_dtm �� ���谡 �׻� ���� ������? �ƴ� �ʱ����� ���� ������.
*/

show autocommit;

select count(1)
  from tb_card_mileage_mmio
 where 1=1
   and mod_dtm >= to_date('20210201', 'yyyymmdd') and mod_dtm < to_date('20210401', 'yyyymmdd') -- 0��. -> �̰� ���̿� �汸��.
--   and mod_dtm > to_date('20210331', 'yyyymmdd') -- 313942924�� -> �̳��� 3�� 1400�� ���� ī�带 ������Ʈ �Ѵ�.
--   and mod_dtm > to_date('20210401', 'yyyymmdd') -- 313942924��
--   and mod_dtm > to_date('20210402', 'yyyymmdd') -- 10140��
--   and mod_dtm > to_date('20210403', 'yyyymmdd') -- 8757��
--   and mod_dtm > to_date('20210404', 'yyyymmdd') -- 7335��
--   and mod_dtm > to_date('20210405', 'yyyymmdd') -- 5631��
--   and mod_dtm > to_date('20210406', 'yyyymmdd') -- 3492��
--   and mod_dtm > to_date('20210407', 'yyyymmdd') -- 1874��
--   and mod_dtm > to_date('20210408', 'yyyymmdd') -- 331��
--   and mod_dtm > to_date('20210409', 'yyyymmdd') -- 0��
;

-- ��. ������. ���� ������� MMIO �� �⸻��� �� 3�� 1400�� ���� �� �� ���� ���ư��� �ִٴ� ���̴�.
-- �� 1�� ���� �ش� IO_YM �� ���� ����Ǹ� �Ǵµ� ���̾�. 
select count(1) from tb_card_mileage_mmio; -- 313942924��.

select count(1)
  from tb_card_mileage_mmio
 where 1=1
--   and io_ym = '202101' -- 17428407��
--   and io_ym = '202102' -- 17465161��
--   and io_ym = '202103' -- 17516204��
   and io_ym = '202104' -- 17528297��
--   and io_ym = '202105' -- 0��
;

select * from tb_card_mileage_mmio
 where card_no = '200090006107100005'
;

select --count(1), min(reg_dtm), max(reg_dtm)
    card_no,
    reg_dtm
  from tb_card_mileage_mmio
 where reg_dtm >= to_date('20210101 00', 'yyyymmdd hh24')
   and reg_dtm < to_date('20210101 01', 'yyyymmdd hh24')
 order by reg_dtm asc
;

/* 10�к���
2021010100	0	17398008
2021010100	1	6
2021010100	2	6
2021010100	3	1
2021010100	4	3
2021010100	5	10
*/

select 
    TO_CHAR(reg_dtm, 'yyyymmdd hh24:mi'), 
    FLOOR(TO_CHAR(reg_dtm, 'ss') / 10),
    count(1)
  from tb_card_mileage_mmio
 where reg_dtm >= to_date('20210101 0000', 'yyyymmdd hh24mi')
   and reg_dtm < to_date('20210101 0001', 'yyyymmdd hh24mi')
 GROUP BY TO_CHAR(reg_dtm, 'yyyymmdd hh24:mi'), FLOOR(TO_CHAR(reg_dtm, 'ss') / 10)
 order by 1,2
;

/*
�ٷ� ����Ѵٴ� ���̳�.
20210101 00:00	0	17398007
*/

-- �׷� �ᱹ update �ð��� �߸��Ǿ� �ִٴ� ���̳�.

-- Į�� �ڸ�Ʈ ��ȸ 2886��.
select
    a.table_name,
    a.column_id as cid,
    a.column_name,
    b.comments,
    a.data_type ||
        (case
            when data_type like '%CHAR%' then '(' || data_length || ')'
            when data_type = 'NUMBER' and data_precision > 0 and data_scale > 0 then '(' || data_precision || ',' || data_scale || ')'
            when data_type = 'NUMBER' and data_precision > 0 then '(' || data_precision || ')'
        end) as data_type,
    decode(nullable, 'N', 'N') nullable
  from all_tab_columns a,
    all_col_comments b
 where a.owner = b.owner
   and a.table_name = b.table_name
   and a.column_name = b.column_name
   and a.owner = 'MEMSNX'
   and a.table_name not like 'BK_%'
   and a.table_name not like 'TMP_%'
   and a.table_name not like 'MIG_%'
   and a.table_name not like 'TB_CARD_MILEAGE_2%'
   and a.table_name not like 'TB_MEM_GRADE_2%'
--   and a.column_name like '%SHOP%' -- 101��
   and a.column_name like '%SHOP_CD' -- 70��
 order by a.table_name, a.column_id
;

----------------------------------------------------------------
-- SHOP_CD �۾�
----------------------------------------------------------------

-- �۾� ��� ���̺� ���� MEMSNX.NO_TB_MIG_TABLES
create table MEMSNX.no_tb_mig_tables (
       table_name varchar2(100) not null,
       num_rows number,
       blocks number,
       shop_yn char(1),
       brand_yn char(1),
       update_yn char(1),
       commments varchar2(3000),
       my_comment varchar2(3000),
       mod_dtm date
);

-- QC �� ���縦 �ϱ� ���Ͽ� �ϴ� asmnx �� �ؾ� �ϴ� �� �߻���.
-- 1. ����.asmnx ����.
create table no_tb_mig_tables AS
select * from no_tb_mig_tables@dbl_mbr;
-- 2. QC.asmnx ����.
create table no_tb_mig_tables AS
select * from no_tb_mig_tables@syn_sales;
-- 3. �.asmnx ����.
create table no_tb_mig_tables AS
select * from no_tb_mig_tables@syn_sales;

-- 4.5.6 ����.memsnx ����.
create table no_tb_mig_tables AS
select * from no_tb_mig_tables@dbl_sales;

update no_tb_mig_tables set shop_yn = 'N' where table_name = 'TB_TRANS_SHOP_LOG';

-- �ش� ���̺�� Į���� �����Ͽ� ��� ���� ������Ʈ �ؾ� �ϴ��� Ȯ��.
select
    a.table_name,
    a.column_id as cid,
    a.column_name,
    b.comments,
    a.data_type ||
        (case
            when data_type like '%CHAR%' then '(' || data_length || ')'
            when data_type = 'NUMBER' and data_precision > 0 and data_scale > 0 then '(' || data_precision || ',' || data_scale || ')'
            when data_type = 'NUMBER' and data_precision > 0 then '(' || data_precision || ')'
        end) as data_type,
    decode(nullable, 'N', 'N') nullable
  from all_tab_columns a,
    all_col_comments b,
    no_tb_mig_tables c
 where a.owner = b.owner
   and a.table_name = b.table_name
   and a.column_name = b.column_name
   and a.table_name = c.table_name
   and a.owner = 'MEMSNX'
   and a.table_name not like 'BK_%'
   and a.table_name not like 'TMP_%'
   and a.table_name not like 'MIG_%'
   and a.table_name not like 'TB_CARD_MILEAGE_2%'
   and a.table_name not like 'TB_MEM_GRADE_2%'
--   and a.column_name like '%SHOP%' -- 101��
   and a.column_name like '%SHOP_CD%' -- 70��
   and c.shop_yn = 'Y'
 order by a.table_name, a.column_id
;

-- �� 16�� ���̺��� 29�� Į���� ������Ʈ �ؾ� �ϸ�, ���߿� 2�� ���̺��� �귣�嵵 ������Ʈ �ؾ� �Ѵ�.

select
    a.table_name,
    a.column_id as cid,
    a.column_name
  from all_tab_columns a,
    no_tb_mig_tables c
 where 1=1
   and a.table_name = c.table_name
   and a.owner = 'MEMSNX'
   and a.table_name not like 'BK_%'
   and a.table_name not like 'TMP_%'
   and a.table_name not like 'MIG_%'
   and a.table_name not like 'TB_CARD_MILEAGE_2%'
   and a.table_name not like 'TB_MEM_GRADE_2%'
   and a.column_name like '%SHOP_CD%' -- 70��
   and c.shop_yn = 'Y'
 order by a.table_name, a.column_id
;

----------------------------------------------------------------
-- ������Ʈ �ؾ��� ���� ��� ���� size �̰� ������Ʈ�� �ɸ��� �ð��� ��� �����ϱ�?
----------------------------------------------------------------

select
    a.segment_name, round(a.bytes/1024/1024, 2) as megabytes
  from user_segments a, no_tb_mig_tables b
 where a.segment_name = b.table_name
   and a.segment_type = 'TABLE'
   and b.shop_yn = 'Y'
 order by a.segment_name
;

----------------------------------------------------------------
-- AS-IS �۾� �� ī��Ʈ ����ϱ�.
----------------------------------------------------------------

create table MEMSNX.no_tb_mig_task_log (
    task_seq number not null,
    log_dt varchar2(20) not null,
    task_nm varchar2(100) not null,
    task_on varchar2(20) not null,
    table_name varchar2(100),
    column_name varchar2(100),
    grp1 varchar2(100),
    grp2 varchar2(100),
    cnt number,
    comments varchar2(2000)
);

select * from MEMSNX.no_tb_mig_task_log;

--drop table MEMSNX.no_tb_mig_task_log purge;

-- �� ���� script �� ������,

select
    1 as task_seq,
    '20210425 220000' as log_dt,
    'SHOP_CD ���� COUNT ���ϱ�' as task_nm,
    'AS-IS' as task_on,
    'TB_CARD_MILEAGE' as table_name,
    'FIRST_TRADE_SHOP_CD' as column_name,
    first_trade_shop_cd as grp1,
    '' as grp2,
    count(1) as cnt,
    null as comments
  from TB_CARD_MILEAGE
-- where first_trade_shop_cd is not null -- ��踦 ���� ���� �̷��� �־�� �ϰڱ�.
 group by first_trade_shop_cd
 order by first_trade_shop_cd;
 
insert into memsnx.no_tb_mig_task_log
select
    1,
    '20210425 220000',
    'B0-5',
    'AS-IS',
    'TB_CARD_MILEAGE',
    'FIRST_TRADE_SHOP_CD',
    first_trade_shop_cd,
    null,
    count(1) as cnt,
    null
  from TB_CARD_MILEAGE
-- where first_trade_shop_cd is not null -- ��踦 ���� ���� �̷��� �־�� �ϰڱ�.
 group by first_trade_shop_cd
 order by first_trade_shop_cd;

set serveroutput on;

----------------------------------------------------------------
-- 1. AS-IS �۾� �� ī��Ʈ ����ϱ�. ���� ���
----------------------------------------------------------------

declare
    vn_task_seq number;
    vs_log_dt varchar2(20);
    vs_task_nm varchar2(100) := 'B0-5. shop_cd ���� count ���ϱ�.';
    
    vs_task_on varchar2(20) := 'AS-IS 4/28';
--    vs_task_on varchar2(20) := 'TO-BE 4/28';
--    vs_task_on varchar2(20) := 'LEG';
    
    vn_total_time number := 0; -- �� �ҿ� �ð�
    vn_segment_time number := 0;
    vs_query varchar2(2000);
    
begin
    vn_total_time := DBMS_UTILITY.GET_TIME;
    
    select NO_PRG_LOG_SEQ.nextval into vn_task_seq from dual;
    select to_char(sysdate, 'yyyymmdd hh24miss') into vs_log_dt from dual;
    
    no_pkg_mig.log_debug('----------------------------------------------------------------');
    no_pkg_mig.log_debug('vn_task_seq: ' || vn_task_seq || ', vs_log_dt: ' || vs_log_dt || ', vs_task_on: ' || vs_task_on || ', vs_task_nm: ' || vs_task_nm);
    
    for c1 IN ( select
                    a.table_name,
                    a.column_id as cid,
                    a.column_name
                  from all_tab_columns a,
                    no_tb_mig_tables c
                 where 1=1
                   and a.table_name = c.table_name
                   and a.owner = 'MEMSNX'
                   and a.table_name not like 'BK_%'
                   and a.table_name not like 'TMP_%'
                   and a.table_name not like 'MIG_%'
                   and a.table_name not like 'TB_CARD_MILEAGE_2%'
                   and a.table_name not like 'TB_MEM_GRADE_2%'
                   and a.column_name like '%SHOP_CD%' -- 70��
                   and c.shop_yn = 'Y'
                   and a.column_name not like 'OLD_%'
                 order by a.table_name, a.column_id
                )
    loop
        vn_segment_time := DBMS_UTILITY.GET_TIME;
        
        no_pkg_mig.log_debug('----------------------------------------------------------------');
        no_pkg_mig.log_debug(c1.table_name || ', ' || c1.column_name);
        
        -- ���� ����.
        vs_query :=             'insert into memsnx.no_tb_mig_task_log ' || chr(13);
        vs_query := vs_query || ' select ' || chr(13);
        vs_query := vs_query || ' ' || vn_task_seq || ',' || chr(13);
        vs_query := vs_query || ' ''' || vs_log_dt || ''', ' || chr(13);
        vs_query := vs_query || ' ''' || vs_task_nm || ''', ' || chr(13);
        vs_query := vs_query || ' ''' || vs_task_on || ''', ' || chr(13);
        vs_query := vs_query || ' ''' || c1.table_name || ''', ' || chr(13);
        vs_query := vs_query || ' ''' || c1.column_name || ''', ' || chr(13);
        vs_query := vs_query || ' ' || c1.column_name || ', ' || chr(13);
        vs_query := vs_query || ' null, ' || chr(13);
        vs_query := vs_query || ' count(1) as cnt, ' || chr(13);
        vs_query := vs_query || ' null ' || chr(13);
        vs_query := vs_query || ' from ' || c1.table_name || chr(13);
        vs_query := vs_query || ' group by ' || c1.column_name || chr(13);
        vs_query := vs_query || ' order by ' || c1.column_name || chr(13);
        
        no_pkg_mig.log_debug(vs_query);
        EXECUTE IMMEDIATE vs_query;
        
        vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
        no_pkg_mig.log_debug('INSERT �Ǽ�: ' || SQL%ROWCOUNT || ', �ҿ� �ð�: ' || vn_segment_time || chr(13));
        
        commit;
        
    end loop;
    
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('SUCCESS. �� �ҿ� �ð�(s): ' || vn_total_time || chr(13));
    
exception when others then
    rollback;
    no_pkg_mig.log_error(SQLERRM);
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('ERROR. �� �ҿ� �ð�(s): ' || vn_total_time || chr(13));
    
end;
/

-- ���� ��� tb_card_mst tb_mem_addinfo
-- ���̺� ���� ������ ASMNX. �� ���̺��� copy �Ѵ�.

create table bk_tb_card_mst as select * from tb_card_mst@dbl_mbr where 1=2;
create table bk_tb_mem_addinfo as select * from tb_mem_addinfo@dbl_mbr where 1=2;
begin
    no_pkg_mig.copy_table_2('tb_card_mst@dbl_mbr', 'bk_tb_card_mst');
    no_pkg_mig.copy_table_2('tb_mem_addinfo@dbl_mbr', 'bk_tb_mem_addinfo');
end;
/

----------------------------------------------------------------
-- 2. PRE CHECK.
-- a. shop_cd ����. old_shop_cd �� �ݵ�� �ϳ��� shop_cd �� ��ġ�Ǿ�� �Ѵ�.
--    ����� 4/25�� ���� NOT IN ('5562', '69217', '69370'); ������ �������� �Ѵ�.
----------------------------------------------------------------

-- 20210427 �ӵ��� ���ؼ� index �� ����.

create index NO_IX_101_201 ON TB_CARD_MILEAGE (FIRST_TRADE_SHOP_CD);
create index NO_IX_102_202 ON TB_CARD_MILEAGE (LAST_TRADE_SHOP_CD);
create index NO_IX_103_203 ON TB_CARD_MST (ISSUE_SHOP_CD);
create index NO_IX_104_204 ON TB_CARD_MST (REG_SHOP_CD);
create index NO_IX_105_205 ON TB_CARD_MST_LOG (ISSUE_SHOP_CD);
create index NO_IX_106_206 ON TB_CARD_MST_LOG (REG_SHOP_CD);
create index NO_IX_107_207 ON TB_COUP_HIST (ISSUE_SHOP_CD);
create index NO_IX_108_208 ON TB_COUP_HIST (USE_SHOP_CD);
create index NO_IX_109_209 ON TB_COUP_HIST_LOG (ISSUE_SHOP_CD);
create index NO_IX_110_210 ON TB_COUP_HIST_LOG (USE_SHOP_CD);
create index NO_IX_111_211 ON TB_COUP_MST (SHOP_CD);
create index NO_IX_112_212 ON TB_GIFT_CARD_ACC_HIST (SHOP_CD);
create index NO_IX_113_213 ON TB_GIFT_CARD_MST (ISSUE_SHOP_CD);
create index NO_IX_114_214 ON TB_GIFT_CARD_MST (REG_SHOP_CD);
create index NO_IX_115_215 ON TB_MEM_ADDINFO (MAIN_SHOP_CD);
create index NO_IX_116_216 ON TB_MEM_ADDINFO_LOG (MAIN_SHOP_CD);
create index NO_IX_117_217 ON TB_MEM_JOININFO (JOIN_SHOP_CD);
create index NO_IX_118_218 ON TB_MEM_JOININFO (NOR_MEM_JOIN_SHOP_CD);
create index NO_IX_119_219 ON TB_MEM_JOININFO (FOREIGN_JOIN_SHOP_CD);
create index NO_IX_120_220 ON TB_MILEAGE_DTL (SHOP_CD);
create index NO_IX_121_221 ON TB_MILEAGE_HIST (SHOP_CD);
create index NO_IX_122_222 ON TB_MILEAGE_HIST_USE_CHK (SHOP_CD);
create index NO_IX_123_223 ON TB_MILEAGE_USE_CHK (FIRST_TRADE_SHOP_CD);
create index NO_IX_124_224 ON TB_MILEAGE_USE_CHK (LAST_TRADE_SHOP_CD);
create index NO_IX_125_225 ON TB_TRANS_SHOP_HIST (CLOSE_SHOP_CD);
create index NO_IX_126_226 ON TB_TRANS_SHOP_HIST (TRANS_SHOP_CD);

EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_CARD_MILEAGE');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_CARD_MST');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_CARD_MST_LOG');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_COUP_HIST');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_COUP_HIST_LOG');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_COUP_MST');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_GIFT_CARD_ACC_HIST');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_GIFT_CARD_MST');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_MEM_ADDINFO');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_MEM_ADDINFO_LOG');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_MEM_JOININFO');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_MILEAGE_DTL');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_MILEAGE_HIST');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_MILEAGE_HIST_USE_CHK');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_MILEAGE_USE_CHK');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS('MEMSNX', 'TB_TRANS_SHOP_HIST');

/*

DROP INDEX NO_IX_101__FIRST_TRADE_SHOP_CD;
DROP INDEX NO_IX_102__LAST_TRADE_SHOP_CD;
DROP INDEX NO_IX_105__ISSUE_SHOP_CD;
DROP INDEX NO_IX_106__REG_SHOP_CD;
DROP INDEX NO_IX_107__ISSUE_SHOP_CD;
DROP INDEX NO_IX_108__USE_SHOP_CD;
DROP INDEX NO_IX_109__ISSUE_SHOP_CD;
DROP INDEX NO_IX_110__USE_SHOP_CD;
DROP INDEX NO_IX_111__SHOP_CD;
DROP INDEX NO_IX_112__SHOP_CD;
DROP INDEX NO_IX_113__ISSUE_SHOP_CD;
DROP INDEX NO_IX_114__REG_SHOP_CD;
DROP INDEX NO_IX_116__MAIN_SHOP_CD;
DROP INDEX NO_IX_120__SHOP_CD;
DROP INDEX NO_IX_121__SHOP_CD;
DROP INDEX NO_IX_122__SHOP_CD;
DROP INDEX NO_IX_123__FIRST_TRADE_SHOP_CD;
DROP INDEX NO_IX_124__LAST_TRADE_SHOP_CD;
DROP INDEX NO_IX_126__TRANS_SHOP_CD;
DROP INDEX NO_IX_TB_CARD_MST__REG_SHOP_CD;

*/
----

select * 
  from tb_bas_shop@dbl_sales
 where 1=1
   and old_shop_cd is not null -- ����: 1838��, �: 2381��.
;

select
    old_shop_cd,
    count(shop_cd)
  from tb_bas_shop@dbl_sales
 where 1=1
   and old_shop_cd is not null
 group by old_shop_cd
--having count(shop_cd) > 0 -- ����: 1838��. �: 2293��.
having count(shop_cd) > 1 -- ����: 1838��. �: 2293��. -- ����� �ߺ��� �߻���.
;
/*
-- 7�ڸ��� ���ٴ� ������ �־�� �ϰ���.
-- ������Ʈ �������� 
NOT IN ('5562', '69217', '69370') ���� �߰��ؾ� ��.

001774	2
001782	2
002291	2
002548	2
010355	2
011012	2
014268	2
015440	2
018158	2
018533	2
020279	2
025140	2
027382	2
027570	2
027807	2
033642	2
034681	2
034839	2
036076	2
036999	2
037040	2
037275	2
038387	2
038504	2
041121	2
041949	2
041959	2
043140	2
043154	2
046254	2
047743	2
048341	2
048620	2
051522	2
052297	2
053278	2
053371	2
053514	2
054526	2
057358	2
058282	2
058519	2
059483	2
059512	2
059739	2
061504	2
062308	2
062986	2
063018	2
063028	2
063073	2
063189	2
063268	2
063387	2
063901	2
064029	2
064147	2
064930	2
065719	2
065770	2
065792	2
066912	2
067129	2
067547	2
067764	2
067966	2
068104	2
068790	2
068822	2
069189	2
069220	2
069300	2
069369	2
069698	2
069699	2
070336	2
070340	2
070451	2
070557	2
070714	2
070869	2
070916	2
071325	2
071386	2
071489	2
5562	2
69217	2
69370	2
*/

----------------------------------------------------------------
-- 3. SHOP_CD ������Ʈ �۾�.
----------------------------------------------------------------

declare
    vn_task_seq number;
    vs_log_dt varchar2(20);
    vs_task_nm varchar2(100) := 'B0-5. old_shop_cd -> shop_cd ��.';
    
--    vs_task_on varchar2(20) := 'AS-IS 4/28';
    vs_task_on varchar2(20) := 'TO-BE 4/29';
--    vs_task_on varchar2(20) := 'LEG';
    
    vn_total_time number := 0; -- �� �ҿ� �ð�
    vn_segment_time number := 0;
    vs_query varchar2(2000);
    
    vs_new_shop_cd varchar2(30);
    
    c2 SYS_REFCURSOR;
    type ShopCdTP is table of varchar2(20); -- �� ShopCd �÷��� Ÿ�� ����.
    
begin
    vn_total_time := DBMS_UTILITY.GET_TIME;
    
    select NO_PRG_LOG_SEQ.nextval into vn_task_seq from dual;
    select to_char(sysdate, 'yyyymmdd hh24miss') into vs_log_dt from dual;
    
    no_pkg_mig.log_debug('#----------------------------------------------------------------');
    no_pkg_mig.log_debug('vn_task_seq: ' || vn_task_seq || ', vs_log_dt: ' || vs_log_dt || ', vs_task_on: ' || vs_task_on || ', vs_task_nm: ' || vs_task_nm);
    
    for c1 IN ( select
                    a.table_name,
                    a.column_id as cid,
                    a.column_name
                  from all_tab_columns a,
                    no_tb_mig_tables c
                 where 1=1
                   and a.table_name = c.table_name
                   and a.owner = 'MEMSNX'
                   and a.table_name not like 'BK_%'
                   and a.table_name not like 'TMP_%'
                   and a.table_name not like 'MIG_%'
                   and a.table_name not like 'TB_CARD_MILEAGE_2%'
                   and a.table_name not like 'TB_MEM_GRADE_2%'
                   and a.column_name like '%SHOP_CD%' -- 70��
                   and c.shop_yn = 'Y'
                   and a.column_name not like 'OLD_%'
--                   and a.table_name = 'TB_COUP_HIST' -- ���� �۾� ���.
                 order by a.table_name, a.column_id
                )
    loop
        vn_segment_time := DBMS_UTILITY.GET_TIME;
        
        no_pkg_mig.log_debug('##----------------------------------------------------------------');
        no_pkg_mig.log_debug(c1.table_name || ', ' || c1.column_name);
        
        -- ������ ���̺� ������ Į���� ������Ʈ �ؾ� �Ѵ�.
        declare
            vst_OldShopCd ShopCdTP;
            vs_sql varchar2(2000);
        begin
            -- ���⼭ �߸������� ����� ������ �� null �� �ٲ� �� �ߴ�.
            vs_sql := 'select distinct a.' || c1.column_name || ' from ' || c1.table_name || ' a, tb_bas_shop@dbl_sales b where a.' || c1.column_name || ' = b.old_shop_cd and a.' || c1.column_name || ' is not null';
            open c2 for vs_sql; -- OPEN Ŀ��. [c2] Ŀ���� ������ shop_cd �� ����ִ�.
            
            fetch c2 BULK COLLECT INTO vst_OldShopCd;
            no_pkg_mig.log_debug('OldShopCd''s count: ' || vst_OldShopCd.count);
            
            /*update TB_COUP_HIST a
               set ( a.use_SHOP_CD ) = (
                select b.shop_cd from tb_bas_shop@dbl_sales b where b.old_shop_cd = '7229' )
             where a.use_SHOP_CD = '7229' -- 700184	�Ե���Ʈ��õ�͹̳���
            ;*/
            
            for i in 1..vst_OldShopCd.count
            loop
            
                -- ���ڵ��?
                select b.shop_cd into vs_new_shop_cd from tb_bas_shop@dbl_sales b where b.old_shop_cd = vst_OldShopCd(i);
                
                -- ���� ����.
                vs_query :=             'update ' || c1.table_name || ' a ' || chr(13);
                vs_query := vs_query || ' set ( a.' || c1.column_name || ' ) = ( ' || chr(13);
                vs_query := vs_query || ' select b.shop_cd from tb_bas_shop@dbl_sales b where b.old_shop_cd = ''' || vst_OldShopCd(i) || ''' ) ' || chr(13);
                vs_query := vs_query || ' where a.' || c1.column_name || ' = ''' || vst_OldShopCd(i) || ''' ' || chr(13);
            
--                no_pkg_mig.log_debug(vs_query);
                EXECUTE IMMEDIATE vs_query;
                
                
                
                no_pkg_mig.log_debug('old_cd<' || vst_OldShopCd(i) || '> => new_cd<' || vs_new_shop_cd || '> on ' || c1.table_name || '.' || c1.column_name || ', UPDATE �Ǽ�: ' || SQL%ROWCOUNT || chr(13), c1.table_name);
                
                commit; -- �ѹ��� update �� �� ������ commit. �� �ϰ� ���� commit �� �ƴ�.
                rollback; -- ������� �̷��� �켱 rollback ���� üũ�� ���� �͵� ������.
                
            end loop;
            
            close c2; -- CLOSE Ŀ��
            
        exception when others then
            rollback;
            no_pkg_mig.log_error(SQLERRM);
        end;
        
        
        vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
        no_pkg_mig.log_debug('Segment �ҿ� �ð�: ' || vn_segment_time || chr(13));
        
    end loop;
    
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('SUCCESS. �� �ҿ� �ð�(s): ' || vn_total_time || chr(13));
    
exception when others then
    rollback;
    no_pkg_mig.log_error(SQLERRM);
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('ERROR. �� �ҿ� �ð�(s): ' || vn_total_time || chr(13));
    
end;
/