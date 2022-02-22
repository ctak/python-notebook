/*

- B0-5. 멤버십 매장/브랜드 마이그레이션
  * brand_cd 가 있는 테이블을 확인한다. 기존에는 shop_cd 로만 검색했었다.
  * 테이블 size 를 잰다음. 대상 오리지날을 백업해 두는 게 좋겠음. 다시 가져올 수 없다고 하니. 그럼 테이블스페이스 size 는 어떻게 되지?
  * 일단 TO-BE.*.MEMSNX 에 VW_BAS_SHOP 을 만든다.(운영적용 이후에도 계속 남겨둔다.)
  
- 결론:
  1. tb_card_mileage_mmio 는 4월과 5월의 data 만 insert 하는 것이 맞다.
  2. T0-BE 개발에서는 tb_mem_addinfo 와 tb_card_mst 를 검증해 주는 것이 좋겠다.

*/

----------------------------------------------------------------
-- 1. TO-BE.개발.MEMSNX 에서 ASIS운영 VIEW 를 참조하여 대상을 구한다.
--    이 때, TO-BE.운영.MEMSNX 는 4/8 일자로 동기화 되어 있음을 생각해야 한다.
--    그리고 tablespace 명이 다르다는 것을 기억해. 개발: MEMS_DAT, QC: MEMS_DAT, 운영: TBS_MEMS
--
----------------------------------------------------------------

select * from no_vw_mems_tables@dbl_sales;
select * from no_vw_mems_columns@dbl_sales;
select * from no_vw_mems_indexes@dbl_sales;

-- A 브랜드 칼럼 찾기

select * from no_vw_mems_columns@dbl_sales
 where column_name like '%BRAND%'
 order by table_name
;

select * from no_vw_mems_columns@dbl_sales
 where comments like '%브랜드%'
 order by table_name
;

select * from (
select * from no_vw_mems_columns@dbl_sales
 where column_name like '%BRAND%'
UNION
select * from no_vw_mems_columns@dbl_sales
 where comments like '%브랜드%'
)
order by table_name, column_id
;

-- 결국 업데이트가 필요한 테이블은 총: 5개. 그 중에 3개는 단독수행.NO-UPDATE 임.
-- 결국 TB_COUP_MST 와 TB_MEM_JOININFO 는 SHOP 과 BRAND 를 업데이트 하며, 4/8일 이후도 업데이트 해야 함.

select distinct DIV_CD from TB_CARD_PBL; -- Y -- 단독수행. NO-UPDATE
select distinct BRAND_CD from TB_CARD_TP; -- Y -- 단독수행. NO-UPDATE
select distinct BRAND_CD from TB_COUP_MST; -- Y

select distinct BRAND_CD from TB_FREQ_HIST; -- N

select distinct JOIN_BRAND_CD from TB_MEM_JOININFO; -- Y

select distinct BRAND_CD from TB_TERMS_MST; -- Y -- 단독 수행. NO-UPDATE

----------------------------------------------------------------
-- 테이블 사이즈 조회
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
이 쯤 되어서 궁금해 진다.
mod_dtm 과 reg_dtm 의 관계가 항상 같지 않을까? 아니 초까지는 같지 않을까.
*/

show autocommit;

select count(1)
  from tb_card_mileage_mmio
 where 1=1
   and mod_dtm >= to_date('20210201', 'yyyymmdd') and mod_dtm < to_date('20210401', 'yyyymmdd') -- 0개. -> 이게 말이여 방구여.
--   and mod_dtm > to_date('20210331', 'yyyymmdd') -- 313942924개 -> 이날밤 3억 1400만 개의 카드를 업데이트 한다.
--   and mod_dtm > to_date('20210401', 'yyyymmdd') -- 313942924개
--   and mod_dtm > to_date('20210402', 'yyyymmdd') -- 10140개
--   and mod_dtm > to_date('20210403', 'yyyymmdd') -- 8757개
--   and mod_dtm > to_date('20210404', 'yyyymmdd') -- 7335개
--   and mod_dtm > to_date('20210405', 'yyyymmdd') -- 5631개
--   and mod_dtm > to_date('20210406', 'yyyymmdd') -- 3492개
--   and mod_dtm > to_date('20210407', 'yyyymmdd') -- 1874개
--   and mod_dtm > to_date('20210408', 'yyyymmdd') -- 331개
--   and mod_dtm > to_date('20210409', 'yyyymmdd') -- 0개
;

-- 오. 놀라워라. 지금 멤버십의 MMIO 즉 기말재고 는 3억 1400만 개가 쓸 데 없이 돌아가고 있다는 것이다.
-- 약 1억 개의 해당 IO_YM 가 새로 복사되면 되는데 말이야. 
select count(1) from tb_card_mileage_mmio; -- 313942924개.

select count(1)
  from tb_card_mileage_mmio
 where 1=1
--   and io_ym = '202101' -- 17428407개
--   and io_ym = '202102' -- 17465161개
--   and io_ym = '202103' -- 17516204개
   and io_ym = '202104' -- 17528297개
--   and io_ym = '202105' -- 0개
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

/* 10분별로
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
바로 계산한다는 말이네.
20210101 00:00	0	17398007
*/

-- 그럼 결국 update 시간이 잘못되어 있다는 말이네.

-- 칼럼 코멘트 조회 2886개.
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
--   and a.column_name like '%SHOP%' -- 101개
   and a.column_name like '%SHOP_CD' -- 70개
 order by a.table_name, a.column_id
;

----------------------------------------------------------------
-- SHOP_CD 작업
----------------------------------------------------------------

-- 작업 대상 테이블 생성 MEMSNX.NO_TB_MIG_TABLES
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

-- QC 로 복사를 하기 위하여 일단 asmnx 에 해야 하는 게 발생함.
-- 1. 개발.asmnx 에서.
create table no_tb_mig_tables AS
select * from no_tb_mig_tables@dbl_mbr;
-- 2. QC.asmnx 에서.
create table no_tb_mig_tables AS
select * from no_tb_mig_tables@syn_sales;
-- 3. 운영.asmnx 에서.
create table no_tb_mig_tables AS
select * from no_tb_mig_tables@syn_sales;

-- 4.5.6 각각.memsnx 에서.
create table no_tb_mig_tables AS
select * from no_tb_mig_tables@dbl_sales;

update no_tb_mig_tables set shop_yn = 'N' where table_name = 'TB_TRANS_SHOP_LOG';

-- 해당 테이블과 칼럼을 맵핑하여 어떠한 것을 업데이트 해야 하는지 확인.
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
--   and a.column_name like '%SHOP%' -- 101개
   and a.column_name like '%SHOP_CD%' -- 70개
   and c.shop_yn = 'Y'
 order by a.table_name, a.column_id
;

-- 총 16개 테이블의 29개 칼럼을 업데이트 해야 하며, 이중에 2개 테이블은 브랜드도 업데이트 해야 한다.

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
   and a.column_name like '%SHOP_CD%' -- 70개
   and c.shop_yn = 'Y'
 order by a.table_name, a.column_id
;

----------------------------------------------------------------
-- 업데이트 해야할 것이 어는 정도 size 이고 업데이트에 걸리는 시간은 어느 정도일까?
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
-- AS-IS 작업 전 카운트 기록하기.
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

-- 이 것을 script 로 돌려서,

select
    1 as task_seq,
    '20210425 220000' as log_dt,
    'SHOP_CD 별로 COUNT 구하기' as task_nm,
    'AS-IS' as task_on,
    'TB_CARD_MILEAGE' as table_name,
    'FIRST_TRADE_SHOP_CD' as column_name,
    first_trade_shop_cd as grp1,
    '' as grp2,
    count(1) as cnt,
    null as comments
  from TB_CARD_MILEAGE
-- where first_trade_shop_cd is not null -- 통계를 잡을 때는 이렇게 있어야 하겠군.
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
-- where first_trade_shop_cd is not null -- 통계를 잡을 때는 이렇게 있어야 하겠군.
 group by first_trade_shop_cd
 order by first_trade_shop_cd;

set serveroutput on;

----------------------------------------------------------------
-- 1. AS-IS 작업 전 카운트 기록하기. 실행 블록
----------------------------------------------------------------

declare
    vn_task_seq number;
    vs_log_dt varchar2(20);
    vs_task_nm varchar2(100) := 'B0-5. shop_cd 별로 count 구하기.';
    
    vs_task_on varchar2(20) := 'AS-IS 4/28';
--    vs_task_on varchar2(20) := 'TO-BE 4/28';
--    vs_task_on varchar2(20) := 'LEG';
    
    vn_total_time number := 0; -- 총 소요 시간
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
                   and a.column_name like '%SHOP_CD%' -- 70개
                   and c.shop_yn = 'Y'
                   and a.column_name not like 'OLD_%'
                 order by a.table_name, a.column_id
                )
    loop
        vn_segment_time := DBMS_UTILITY.GET_TIME;
        
        no_pkg_mig.log_debug('----------------------------------------------------------------');
        no_pkg_mig.log_debug(c1.table_name || ', ' || c1.column_name);
        
        -- 쿼리 생성.
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
        no_pkg_mig.log_debug('INSERT 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || chr(13));
        
        commit;
        
    end loop;
    
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('SUCCESS. 총 소요 시간(s): ' || vn_total_time || chr(13));
    
exception when others then
    rollback;
    no_pkg_mig.log_error(SQLERRM);
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('ERROR. 총 소요 시간(s): ' || vn_total_time || chr(13));
    
end;
/

-- 개발 백업 tb_card_mst tb_mem_addinfo
-- 테이블 공간 문제로 ASMNX. 에 테이블을 copy 한다.

create table bk_tb_card_mst as select * from tb_card_mst@dbl_mbr where 1=2;
create table bk_tb_mem_addinfo as select * from tb_mem_addinfo@dbl_mbr where 1=2;
begin
    no_pkg_mig.copy_table_2('tb_card_mst@dbl_mbr', 'bk_tb_card_mst');
    no_pkg_mig.copy_table_2('tb_mem_addinfo@dbl_mbr', 'bk_tb_mem_addinfo');
end;
/

----------------------------------------------------------------
-- 2. PRE CHECK.
-- a. shop_cd 검증. old_shop_cd 는 반드시 하나의 shop_cd 로 매치되어야 한다.
--    운영에서 4/25일 현재 NOT IN ('5562', '69217', '69370'); 조건이 더해져야 한다.
----------------------------------------------------------------

-- 20210427 속도를 위해서 index 를 만듦.

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
   and old_shop_cd is not null -- 개발: 1838개, 운영: 2381개.
;

select
    old_shop_cd,
    count(shop_cd)
  from tb_bas_shop@dbl_sales
 where 1=1
   and old_shop_cd is not null
 group by old_shop_cd
--having count(shop_cd) > 0 -- 개발: 1838개. 운영: 2293개.
having count(shop_cd) > 1 -- 개발: 1838개. 운영: 2293개. -- 운영에서 중복이 발생함.
;
/*
-- 7자리가 없다는 전제가 있어야 하겠음.
-- 업데이트 영역에서 
NOT IN ('5562', '69217', '69370') 조건 추가해야 함.

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
-- 3. SHOP_CD 업데이트 작업.
----------------------------------------------------------------

declare
    vn_task_seq number;
    vs_log_dt varchar2(20);
    vs_task_nm varchar2(100) := 'B0-5. old_shop_cd -> shop_cd 로.';
    
--    vs_task_on varchar2(20) := 'AS-IS 4/28';
    vs_task_on varchar2(20) := 'TO-BE 4/29';
--    vs_task_on varchar2(20) := 'LEG';
    
    vn_total_time number := 0; -- 총 소요 시간
    vn_segment_time number := 0;
    vs_query varchar2(2000);
    
    vs_new_shop_cd varchar2(30);
    
    c2 SYS_REFCURSOR;
    type ShopCdTP is table of varchar2(20); -- 상세 ShopCd 컬렉션 타입 선언.
    
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
                   and a.column_name like '%SHOP_CD%' -- 70개
                   and c.shop_yn = 'Y'
                   and a.column_name not like 'OLD_%'
--                   and a.table_name = 'TB_COUP_HIST' -- 개발 작업 대상.
                 order by a.table_name, a.column_id
                )
    loop
        vn_segment_time := DBMS_UTILITY.GET_TIME;
        
        no_pkg_mig.log_debug('##----------------------------------------------------------------');
        no_pkg_mig.log_debug(c1.table_name || ', ' || c1.column_name);
        
        -- 현재의 테이블 현재의 칼럼을 업데이트 해야 한다.
        declare
            vst_OldShopCd ShopCdTP;
            vs_sql varchar2(2000);
        begin
            -- 여기서 잘못했으면 사라진 매장이 다 null 로 바뀔 뻔 했다.
            vs_sql := 'select distinct a.' || c1.column_name || ' from ' || c1.table_name || ' a, tb_bas_shop@dbl_sales b where a.' || c1.column_name || ' = b.old_shop_cd and a.' || c1.column_name || ' is not null';
            open c2 for vs_sql; -- OPEN 커서. [c2] 커서는 각가의 shop_cd 를 담고있다.
            
            fetch c2 BULK COLLECT INTO vst_OldShopCd;
            no_pkg_mig.log_debug('OldShopCd''s count: ' || vst_OldShopCd.count);
            
            /*update TB_COUP_HIST a
               set ( a.use_SHOP_CD ) = (
                select b.shop_cd from tb_bas_shop@dbl_sales b where b.old_shop_cd = '7229' )
             where a.use_SHOP_CD = '7229' -- 700184	롯데마트인천터미널점
            ;*/
            
            for i in 1..vst_OldShopCd.count
            loop
            
                -- 새코드는?
                select b.shop_cd into vs_new_shop_cd from tb_bas_shop@dbl_sales b where b.old_shop_cd = vst_OldShopCd(i);
                
                -- 쿼리 생성.
                vs_query :=             'update ' || c1.table_name || ' a ' || chr(13);
                vs_query := vs_query || ' set ( a.' || c1.column_name || ' ) = ( ' || chr(13);
                vs_query := vs_query || ' select b.shop_cd from tb_bas_shop@dbl_sales b where b.old_shop_cd = ''' || vst_OldShopCd(i) || ''' ) ' || chr(13);
                vs_query := vs_query || ' where a.' || c1.column_name || ' = ''' || vst_OldShopCd(i) || ''' ' || chr(13);
            
--                no_pkg_mig.log_debug(vs_query);
                EXECUTE IMMEDIATE vs_query;
                
                
                
                no_pkg_mig.log_debug('old_cd<' || vst_OldShopCd(i) || '> => new_cd<' || vs_new_shop_cd || '> on ' || c1.table_name || '.' || c1.column_name || ', UPDATE 건수: ' || SQL%ROWCOUNT || chr(13), c1.table_name);
                
                commit; -- 한번씩 update 를 할 때마다 commit. 다 하고 나서 commit 이 아닌.
                rollback; -- 운영에서는 이렇게 우선 rollback 으로 체크해 보는 것도 괜찮음.
                
            end loop;
            
            close c2; -- CLOSE 커서
            
        exception when others then
            rollback;
            no_pkg_mig.log_error(SQLERRM);
        end;
        
        
        vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
        no_pkg_mig.log_debug('Segment 소요 시간: ' || vn_segment_time || chr(13));
        
    end loop;
    
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('SUCCESS. 총 소요 시간(s): ' || vn_total_time || chr(13));
    
exception when others then
    rollback;
    no_pkg_mig.log_error(SQLERRM);
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('ERROR. 총 소요 시간(s): ' || vn_total_time || chr(13));
    
end;
/