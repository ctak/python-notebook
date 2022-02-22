/*

- B0-3 멤버십 4/8 이후 데이터 마이그레이션
  * P. 운영에서 TMP_ 로 필요한 것은 삭제할 수 있는지 확인한다.
  * A. LEG_멤버십에서 검증 데이터를 만든다.
  * B. TOBE_멤버십에서 검증 데이터를 만든다.
  * C. 둘의 차이를 비교한다.
  * D. 4/25 일까지의 업데이트 된 데이터를 temp 테이블에 넣는다.
  * E. 하루의 기간으로 업데이트 한다.
  * F. TOBE_멤버십에서 검증한다.
  * Z. 작업이 끝나면 B0-5 작업을 한다.

- 결론:
  1. 

*/

----------------------------------------------------------------
-- 1. TO-BE.개발.MEMSNX 에서 ASIS운영 VIEW 를 참조하여 대상을 구한다.
--    이 때, TO-BE.운영.MEMSNX 는 4/8 일자로 동기화 되어 있음을 생각해야 한다.
--    그리고 tablespace 명이 다르다는 것을 기억해. 개발: MEMS_DAT, QC: MEMS_DAT, 운영: TBS_MEMS
--
----------------------------------------------------------------

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

----------------------------------------------------------------
-- SHOP_CD 작업
----------------------------------------------------------------

-- 어떤 memsnx.테이블 을 만들고 서버들을 이동하면서 복사하기 위해선.

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
   and b.update_yn = 'Y'
 order by a.segment_name
;

-- * [4/27] TB_CARD_MILEAGE 는 MMIO 로써 2104 와 2105 를 MERGE 하면 되어서 대상에서 제외
select * from no_tb_mig_tables where table_name = 'TB_CARD_MILEAGE_MMIO'
--update no_tb_mig_tables set update_yn = null where table_name = 'TB_CARD_MILEAGE_MMIO'
;
select * from no_tb_mig_tables where table_name = 'MBR_AGRM_AGR_BRKDWN'
--update no_tb_mig_tables set update_yn = null where table_name = 'MBR_AGRM_AGR_BRKDWN'
;
select * from no_tb_mig_tables where table_name = 'TB_ERP_BATCH_LOG'
--update no_tb_mig_tables set update_yn = null where table_name = 'TB_ERP_BATCH_LOG'
;
select * from no_tb_mig_tables where table_name = 'TB_MEM_REST_REQ'
--update no_tb_mig_tables set update_yn = null where table_name = 'TB_MEM_REST_REQ'
;
select * from no_tb_mig_tables where table_name = 'TB_MEM_SMS_RECV_DISAGR_LOG'
--update no_tb_mig_tables set update_yn = null where table_name = 'TB_MEM_SMS_RECV_DISAGR_LOG'
;

----------------------------------------------------------------
-- bk_dummy_log 에 업데이트해야 할 row 남기기.
----------------------------------------------------------------
select * from tb_bas_shop@leg_asm;
select * from mems.tb_card_mileage@leg_mems;
select * from mems.MBR_AGRM_AGR_BRKDWN@leg_mems;
select 1 from mems.AGRM@leg_mems;
--select * from mems.AGRM@leg_mems; -- LOB 칼럼 있음.

select count(1) from mems.tb_card_mileage@leg_mems where mod_dtm >= to_date('20210408', 'yyyymmdd');

set serveroutput on;

declare
    vn_task_seq number;
    vs_log_dt varchar2(20);
    vs_task_nm varchar2(100) := 'B0-3.1 update 해야 할 테이블의 4/8일 이후 업데이트 카운트.';
    
--    vs_task_on varchar2(20) := '[AS-IS ]';
--    vs_task_on varchar2(20) := '[TO-BE ]';
    vs_task_on varchar2(20) := '[LEG] ';
    
    vn_total_time number := 0; -- 총 소요 시간
    vn_segment_time number := 0;
    vs_query varchar2(2000);
    
    vn_select_count number := 0;
    vs_mod_dtm_nm varchar2(100);
begin
    vn_total_time := DBMS_UTILITY.GET_TIME;
    
    select NO_PRG_LOG_SEQ.nextval into vn_task_seq from dual;
    select to_char(sysdate, 'yyyymmdd hh24miss') into vs_log_dt from dual;
    
    no_pkg_mig.log_debug('----------------------------------------------------------------', vs_task_nm);
    no_pkg_mig.log_debug('vn_task_seq: ' || vn_task_seq || ', vs_log_dt: ' || vs_log_dt || ', vs_task_on: ' || vs_task_on || ', vs_task_nm: ' || vs_task_nm);
    
    for c1 IN ( select
                    a.table_name
                  from all_tables a,
                    no_tb_mig_tables c
                 where 1=1
                   and a.table_name = c.table_name
                   and a.owner = 'MEMSNX'
                   and c.update_yn = 'Y'
                 order by a.table_name
                )
    loop
        vn_segment_time := DBMS_UTILITY.GET_TIME;
        
        no_pkg_mig.log_debug('----------------------------------------------------------------');
        no_pkg_mig.log_debug('table => ' || c1.table_name);
        
        -- mod_dtm 이 없는 테이블도 있네.
        case c1.table_name
            when 'AGRM' then vs_mod_dtm_nm := 'sys_mod_date';
            when 'TB_MEM_REST' then vs_mod_dtm_nm := 'reg_dtm';
            when 'TB_MILEAGE_PROC' then vs_mod_dtm_nm := 'reg_dtm';
            
            else vs_mod_dtm_nm := 'mod_dtm';
        end case;
        
        -- query: select count(1) from mems.tb_card_mileage@leg_mems where mod_dtm >= to_date('20210408', 'yyyymmdd');
        
        vn_select_count := 0;
        
        -- 쿼리 생성.
        vs_query :=             'select count(1) from ' || chr(13);
        vs_query := vs_query || ' mems.' || c1.table_name || '@leg_mems ' || chr(13);
        vs_query := vs_query || ' where ' || vs_mod_dtm_nm || ' >= to_date(''20210408'', ''yyyymmdd'') ' || chr(13);
        
        no_pkg_mig.log_debug(vs_query);
        EXECUTE IMMEDIATE vs_query INTO vn_select_count;
        
        vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
        no_pkg_mig.log_debug('select 건수: ' || vn_select_count || ', 소요 시간: ' || vn_segment_time || ', table: ' || c1.table_name || chr(13));
        
--        commit;
        
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

----------------------------------------------------------------
-- 20210427 이 보다 전에 업데이트 된 옮기기. 왜냐하면 그 이후에 업데이트 된 것은 또 옮겨서 실행하면 되니까. 
-- 하루에 몇 번 업데이트가 되어도 최종만 반영하면 됨.
----------------------------------------------------------------
--INSERT /*+ APPEND */ INTO TMP_ADJ_CUR SELECT * FROM MEMS.TMP_ADJ_CUR@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_ADJ_CUR_TEMP SELECT * FROM MEMS.TMP_ADJ_CUR_TEMP@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_ADJ_END_DT SELECT * FROM MEMS.TMP_ADJ_END_DT@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_BATCH_PROC SELECT * FROM MEMS.TMP_BATCH_PROC@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_CARD_MILEAGE SELECT * FROM MEMS.TMP_CARD_MILEAGE@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_CHANGE_REMARK SELECT * FROM MEMS.TMP_CHANGE_REMARK@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_DEBUG_PROC SELECT * FROM MEMS.TMP_DEBUG_PROC@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_KAKAO_CAMP_202103 SELECT * FROM MEMS.TMP_KAKAO_CAMP_202103@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_KISA_REQ SELECT * FROM MEMS.TMP_KISA_REQ@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_KISA_REQ_LOG SELECT * FROM MEMS.TMP_KISA_REQ_LOG@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_MEM_GITICON_CU SELECT * FROM MEMS.TMP_MEM_GITICON_CU@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_MEM_GITICON_HOLLYS SELECT * FROM MEMS.TMP_MEM_GITICON_HOLLYS@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_MEM_GRADE SELECT * FROM MEMS.TMP_MEM_GRADE@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_MEM_RECV_AGR SELECT * FROM MEMS.TMP_MEM_RECV_AGR@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_MEM_RECV_AGR_CHGED SELECT * FROM MEMS.TMP_MEM_RECV_AGR_CHGED@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_MEM_RECV_AGR_LOG_CHGED SELECT * FROM MEMS.TMP_MEM_RECV_AGR_LOG_CHGED@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_MEM_RECV_AGR_NUCHGED SELECT * FROM MEMS.TMP_MEM_RECV_AGR_NUCHGED@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_MOBILE_NO SELECT * FROM MEMS.TMP_MOBILE_NO@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_ONLINE_ORDER SELECT * FROM MEMS.TMP_ONLINE_ORDER@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_ORFFER_TARGET SELECT * FROM MEMS.TMP_ORFFER_TARGET@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_RCPT_DATA SELECT * FROM MEMS.TMP_RCPT_DATA@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_RM_MILEAGE SELECT * FROM MEMS.TMP_RM_MILEAGE@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_SLEEP_MEMBER SELECT * FROM MEMS.TMP_SLEEP_MEMBER@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_SPC_MILEAGE SELECT * FROM MEMS.TMP_SPC_MILEAGE@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_SPC_MILEAGE_ADD SELECT * FROM MEMS.TMP_SPC_MILEAGE_ADD@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_SPC_MILEAGE_ADD_LOG SELECT * FROM MEMS.TMP_SPC_MILEAGE_ADD_LOG@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_SUBMIT_LOG SELECT * FROM MEMS.TMP_SUBMIT_LOG@LEG_MEMS;
--
--INSERT /*+ APPEND */ INTO TMP_TB_CARD_MILEAGE SELECT * FROM MEMS.TMP_TB_CARD_MILEAGE@LEG_MEMS;
--
----INSERT /*+ APPEND */ INTO TMP_TB_MILEAGE_HIST SELECT * FROM MEMS.TMP_TB_MILEAGE_HIST@LEG_MEMS;
--INSERT /*+ APPEND */ INTO TMP_TRANS_ADJ_CUR SELECT * FROM MEMS.TMP_TRANS_ADJ_CUR@LEG_MEMS;
----INSERT /*+ APPEND */ INTO TMP_TRANS_ADJ_CUR_BK SELECT * FROM MEMS.TMP_TRANS_ADJ_CUR_BK@LEG_MEMS;
--INSERT /*+ APPEND */ INTO TMP_TRANS_SMS_RECV_PROM SELECT * FROM MEMS.TMP_TRANS_SMS_RECV_PROM@LEG_MEMS;


/*
TRUNCATE TABLE TMP_ADJ_CUR;
TRUNCATE TABLE TMP_ADJ_CUR_TEMP;
TRUNCATE TABLE TMP_ADJ_END_DT;
TRUNCATE TABLE TMP_BATCH_PROC;
TRUNCATE TABLE TMP_CARD_MILEAGE;
TRUNCATE TABLE TMP_CHANGE_REMARK;
TRUNCATE TABLE TMP_DEBUG_PROC;
TRUNCATE TABLE TMP_KAKAO_CAMP_202103;
TRUNCATE TABLE TMP_KISA_REQ;
TRUNCATE TABLE TMP_KISA_REQ_LOG;
TRUNCATE TABLE TMP_MEM_GITICON_CU;
TRUNCATE TABLE TMP_MEM_GITICON_HOLLYS;
TRUNCATE TABLE TMP_MEM_GRADE;
TRUNCATE TABLE TMP_MEM_RECV_AGR;
TRUNCATE TABLE TMP_MEM_RECV_AGR_CHGED;
TRUNCATE TABLE TMP_MEM_RECV_AGR_LOG_CHGED;
TRUNCATE TABLE TMP_MEM_RECV_AGR_NUCHGED;
TRUNCATE TABLE TMP_MOBILE_NO;
TRUNCATE TABLE TMP_ONLINE_ORDER;
TRUNCATE TABLE TMP_ORFFER_TARGET;
TRUNCATE TABLE TMP_RCPT_DATA;
TRUNCATE TABLE TMP_RM_MILEAGE;
TRUNCATE TABLE TMP_SLEEP_MEMBER;
TRUNCATE TABLE TMP_SPC_MILEAGE;
TRUNCATE TABLE TMP_SPC_MILEAGE_ADD;
TRUNCATE TABLE TMP_SPC_MILEAGE_ADD_LOG;
TRUNCATE TABLE TMP_SUBMIT_LOG;
TRUNCATE TABLE TMP_TB_CARD_MILEAGE;
TRUNCATE TABLE TMP_TB_MILEAGE_HIST;
TRUNCATE TABLE TMP_TRANS_ADJ_CUR;
TRUNCATE TABLE TMP_TRANS_ADJ_CUR_BK;
TRUNCATE TABLE TMP_TRANS_SMS_RECV_PROM;
*/

----------------------------------------------------------------
-- temp table 만들기.

/*
TRUNCATE TABLE NO_TMP_AGRM;
TRUNCATE TABLE NO_TMP_TB_BATCH_GRADE_ADJ_AMT;
TRUNCATE TABLE NO_TMP_TB_BNFT_MST;
TRUNCATE TABLE NO_TMP_TB_CARD_MILEAGE;
TRUNCATE TABLE NO_TMP_TB_CARD_MST;
TRUNCATE TABLE NO_TMP_TB_CARD_MST_LOG;
TRUNCATE TABLE NO_TMP_TB_CD_MST;
TRUNCATE TABLE NO_TMP_TB_COUP_HIST;
TRUNCATE TABLE NO_TMP_TB_COUP_HIST_LOG;
TRUNCATE TABLE NO_TMP_TB_COUP_MST;
TRUNCATE TABLE NO_TMP_TB_GRADE_MST;
TRUNCATE TABLE NO_TMP_TB_MEM_ADDINFO;
TRUNCATE TABLE NO_TMP_TB_MEM_ADDINFO_LOG;
TRUNCATE TABLE NO_TMP_TB_MEM_BNFT_HIST;
TRUNCATE TABLE NO_TMP_TB_MEM_CALC_RULE;
TRUNCATE TABLE NO_TMP_TB_MEM_GIFTICON_HIST;
TRUNCATE TABLE NO_TMP_TB_MEM_GRADE;
TRUNCATE TABLE NO_TMP_TB_MEM_GRADE_ADJ_HIST;
TRUNCATE TABLE NO_TMP_TB_MEM_GRADE_TRANS;
TRUNCATE TABLE NO_TMP_TB_MEM_JOININFO;
TRUNCATE TABLE NO_TMP_TB_MEM_JOININFO_LOG;
TRUNCATE TABLE NO_TMP_TB_MEM_MOD_RES_IF;
TRUNCATE TABLE NO_TMP_TB_MEM_MST;
TRUNCATE TABLE NO_TMP_TB_MEM_MST_LOG;
TRUNCATE TABLE NO_TMP_TB_MEM_RECV_AGR;
TRUNCATE TABLE NO_TMP_TB_MEM_RECV_AGR_LOG;
TRUNCATE TABLE NO_TMP_TB_MEM_REST;
TRUNCATE TABLE NO_TMP_TB_MEM_REST_MST;
TRUNCATE TABLE NO_TMP_TB_MEM_TEMS_AGR;
TRUNCATE TABLE NO_TMP_TB_MEM_TRANS;
TRUNCATE TABLE NO_TMP_TB_MILEAGE_DTL;
TRUNCATE TABLE NO_TMP_TB_MILEAGE_HIST;
TRUNCATE TABLE NO_TMP_TB_MILEAGE_PROC;
TRUNCATE TABLE NO_TMP_TB_MILEAGE_TRANS;
TRUNCATE TABLE NO_TMP_TB_ONLINE_ORDER;
TRUNCATE TABLE NO_TMP_TB_SMS_MST;
TRUNCATE TABLE NO_TMP_TB_TRANS_SHOP_HIST;
*/

select count(1) from mems.tb_mileage_proc@leg_mems;

--insert /*+ APPEND */ into tb_mileage_proc select * from mems.tb_mileage_proc@leg_mems;

select * from tb_mileage_proc;

--insert /*+ APPEND */ into TB_MILEAGE_TRANS select * from mems.TB_MILEAGE_TRANS@leg_mems;

select * from tb_mileage_trans;

--insert /*+ APPEND */ into tb_online_order select * from mems.tb_online_order@leg_mems;

select * from tb_online_order;

--insert /*+ APPEND */ into tb_sms_mst select * from mems.tb_sms_mst@leg_mems;

select * from tb_sms_mst;

--insert /*+ APPEND */ into TB_TRANS_SHOP_HIST select * from mems.TB_TRANS_SHOP_HIST@leg_mems;

select * from TB_TRANS_SHOP_HIST;

-- LOB 가 있는 테이블은 CTAS 는 될 테지만, insert select 는 되지 않을 것이다. 우선 CTAS 로 가져온 다음, insert select 해야 할 듯.
declare
    vn_task_seq number;
    vs_log_dt varchar2(20);
    vs_task_nm varchar2(100) := 'B0-3.2 update 해야 할 테이블의 NO_TMP_ 테이블 만들기.';
    
--    vs_task_on varchar2(20) := '[AS-IS ]';
    vs_task_on varchar2(20) := '[TO-BE ]';
--    vs_task_on varchar2(20) := '[LEG] ';
    
    vn_total_time number := 0; -- 총 소요 시간
    vn_segment_time number := 0;
    vs_query varchar2(2000);
    
    vs_mod_dtm_nm varchar2(100);
begin
    vn_total_time := DBMS_UTILITY.GET_TIME;
    
    select NO_PRG_LOG_SEQ.nextval into vn_task_seq from dual;
    select to_char(sysdate, 'yyyymmdd hh24miss') into vs_log_dt from dual;
    
    no_pkg_mig.log_debug('----------------------------------------------------------------', vs_task_nm);
    no_pkg_mig.log_debug('vn_task_seq: ' || vn_task_seq || ', vs_log_dt: ' || vs_log_dt || ', vs_task_on: ' || vs_task_on || ', vs_task_nm: ' || vs_task_nm);
    
    for c1 IN ( select
                    a.table_name
                  from all_tables a,
                    no_tb_mig_tables c
                 where 1=1
                   and a.table_name = c.table_name
                   and a.owner = 'MEMSNX'
                   and c.update_yn = 'Y'
                 order by a.table_name
                )
    loop
        vn_segment_time := DBMS_UTILITY.GET_TIME;
        
        no_pkg_mig.log_debug('----------------------------------------------------------------');
        no_pkg_mig.log_debug('table => ' || c1.table_name);
           
        -- query: create table NO_TMP_TB_CARD_MILEAGE as select * from mems.tb_card_mileage@leg_mems where 1=2;
        
        -- 쿼리 생성.
        vs_query :=             'create table ' || chr(13);
        vs_query := vs_query || ' NO_TMP_' || c1.table_name || ' as select * from  ' || chr(13);
        vs_query := vs_query || ' mems.' || c1.table_name || '@leg_mems where 1=2 ' || chr(13);
        
        no_pkg_mig.log_debug(vs_query);
        EXECUTE IMMEDIATE vs_query;
        
        vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
        no_pkg_mig.log_debug('CTAS, 소요 시간: ' || vn_segment_time || ', table: ' || c1.table_name || chr(13));
        
--        commit;
        
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

-- 총 37개가 만들어져야 함.
select * from user_tables where table_name like 'NO_TMP%'; -- 37개. @okay

----------------------------------------------------------------
-- DATA 가져오기.
-- 1. 우선 가벼운 날짜로 업데이트 하기. LOB 칼럼을 찾기 위해서임.


declare
    vn_task_seq number;
    vs_log_dt varchar2(20);
    vs_task_nm varchar2(100) := 'B0-3.3 tmp 테이블에 AS-IS 운영에서 data 가져오기.';
    
--    vs_task_on varchar2(20) := '[AS-IS ]';
--    vs_task_on varchar2(20) := '[TO-BE ]';
    vs_task_on varchar2(20) := '[LEG] ';
    
    vn_total_time number := 0; -- 총 소요 시간
    vn_segment_time number := 0;
    vs_query varchar2(2000);
    
    vn_insert_count number := 0;
    vs_mod_dtm_nm varchar2(100);
    
    vs_from_date varchar2(8) := '20210427';
    vs_to_date varchar2(8) := '20210429'; -- 미만까지
begin
    vn_total_time := DBMS_UTILITY.GET_TIME;
    
    select NO_PRG_LOG_SEQ.nextval into vn_task_seq from dual;
    select to_char(sysdate, 'yyyymmdd hh24miss') into vs_log_dt from dual;
    
    no_pkg_mig.log_debug('----------------------------------------------------------------', vs_task_nm);
    no_pkg_mig.log_debug('vn_task_seq: ' || vn_task_seq || ', vs_log_dt: ' || vs_log_dt || ', vs_task_on: ' || vs_task_on || ', vs_task_nm: ' || vs_task_nm);
    
    for c1 IN ( select
                    a.table_name
                  from all_tables a,
                    no_tb_mig_tables c
                 where 1=1
                   and a.table_name = c.table_name
                   and a.owner = 'MEMSNX'
                   and c.update_yn = 'Y'
                 order by a.table_name
                )
    loop
        vn_segment_time := DBMS_UTILITY.GET_TIME;
        
        no_pkg_mig.log_debug('----------------------------------------------------------------');
        no_pkg_mig.log_debug('table => ' || c1.table_name);
        
        -- mod_dtm 이 없는 테이블도 있네.
        case c1.table_name
            when 'AGRM' then vs_mod_dtm_nm := 'sys_mod_date';
            when 'TB_MEM_REST' then vs_mod_dtm_nm := 'reg_dtm';
            when 'TB_MILEAGE_PROC' then vs_mod_dtm_nm := 'reg_dtm';
            
            else vs_mod_dtm_nm := 'mod_dtm';
        end case;
        
        -- query: insert into NO_TMP_tb_card_mileage select * from mems.tb_card_mileage@leg_mems where mod_dtm >= to_date('20210408', 'yyyymmdd') and mod_dtm < to_date('20210427', 'yyyymmdd');
        
        -- 쿼리 생성.
        vs_query :=             'insert into NO_TMP_' || c1.table_name || ' select * from ' || chr(13);
        vs_query := vs_query || ' mems.' || c1.table_name || '@leg_mems ' || chr(13);
        vs_query := vs_query || ' where ' || vs_mod_dtm_nm || ' >= to_date(''' || vs_from_date || ''', ''yyyymmdd'') ' || chr(13);
        vs_query := vs_query || ' and ' || vs_mod_dtm_nm || ' < to_date(''' || vs_to_date || ''', ''yyyymmdd'') ' || chr(13);
   
        no_pkg_mig.log_debug(vs_query);
        EXECUTE IMMEDIATE vs_query;
        
        vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
        no_pkg_mig.log_debug('insert 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || c1.table_name || chr(13));
        
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


----------------------------------------------------------------
-- 블록으로 실행하고 완성되면 운영으로 옮긴다.
----------------------------------------------------------------

select * from bk_dummy_log order by log_id desc;
;

----------------------------------------------------------------
-- 4/8 이후 UPDATE 작업
----------------------------------------------------------------

declare
    vn_task_seq number;
    vs_log_dt varchar2(20);
    vs_task_nm varchar2(100) := 'B0-3.3 4/8일 이후 데이터 업데이트.';
    
--    vs_task_on varchar2(20) := '[AS-IS ]';
    vs_task_on varchar2(20) := '[TO-BE ]';
--    vs_task_on varchar2(20) := '[LEG] ';
    
    vn_total_time number := 0; -- 총 소요 시간
    vn_segment_time number := 0;
    vs_query varchar2(2000);
    
    vn_insert_count number := 0;
    vs_mod_dtm_nm varchar2(100);
    
--    vs_from_date varchar2(8) := '20210408';
--    vs_to_date varchar2(8) := '20210427';
    
    vs_target_date varchar2(8) := '20210428';
    
    vs_table_name varchar2(50);
begin
    vn_total_time := DBMS_UTILITY.GET_TIME;
    
    select NO_PRG_LOG_SEQ.nextval into vn_task_seq from dual;
    select to_char(sysdate, 'yyyymmdd hh24miss') into vs_log_dt from dual;
    
    no_pkg_mig.log_debug('----------------------------------------------------------------', vs_task_nm);
    no_pkg_mig.log_debug('vn_task_seq: ' || vn_task_seq || ', vs_log_dt: ' || vs_log_dt || ', vs_task_on: ' || vs_task_on || ', vs_task_nm: ' || vs_task_nm);
    no_pkg_mig.log_debug('vs_target_date: ' || vs_target_date);
    
    /*
    -- mod_dtm 이 없는 테이블도 있네.
    case c1.table_name
        when 'AGRM' then vs_mod_dtm_nm := 'sys_mod_date';
        when 'TB_MEM_REST' then vs_mod_dtm_nm := 'reg_dtm';
        when 'TB_MILEAGE_PROC' then vs_mod_dtm_nm := 'reg_dtm';
        
        else vs_mod_dtm_nm := 'mod_dtm';
    end case;
    */

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

-------- AGRM

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'AGRM';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into AGRM a
using (
select 
*
from no_tmp_AGRM
where sys_mod_date >= to_date(vs_target_date, 'yyyymmdd') and  sys_mod_date < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.AGRM_NO = T.AGRM_NO

)
when matched then
update set

A.MGMT_UNIT = T.MGMT_UNIT,
A.AGRM_TP = T.AGRM_TP,
A.STORE_NO = T.STORE_NO,
A.SITE_NO = T.SITE_NO,
A.CH_NO = T.CH_NO,
A.AGRM_NM = T.AGRM_NM,
A.AGRM_DESCR = T.AGRM_DESCR,
A.AGRM_VER = T.AGRM_VER,
A.AGRM_CONT = T.AGRM_CONT,
A.USE_YN = T.USE_YN,
A.SYS_REG_MBR_NO = T.SYS_REG_MBR_NO,
A.SYS_REG_DATE = T.SYS_REG_DATE,
A.SYS_MOD_MBR_NO = T.SYS_MOD_MBR_NO,
A.SYS_MOD_DATE = T.SYS_MOD_DATE


when not matched then
insert (

A.AGRM_NO,
A.MGMT_UNIT,
A.AGRM_TP,
A.STORE_NO,
A.SITE_NO,
A.CH_NO,
A.AGRM_NM,
A.AGRM_DESCR,
A.AGRM_VER,
A.AGRM_CONT,
A.USE_YN,
A.SYS_REG_MBR_NO,
A.SYS_REG_DATE,
A.SYS_MOD_MBR_NO,
A.SYS_MOD_DATE


)
values (

T.AGRM_NO,
T.MGMT_UNIT,
T.AGRM_TP,
T.STORE_NO,
T.SITE_NO,
T.CH_NO,
T.AGRM_NM,
T.AGRM_DESCR,
T.AGRM_VER,
T.AGRM_CONT,
T.USE_YN,
T.SYS_REG_MBR_NO,
T.SYS_REG_DATE,
T.SYS_MOD_MBR_NO,
T.SYS_MOD_DATE


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_BATCH_GRADE_ADJ_AMT

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_BATCH_GRADE_ADJ_AMT';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_BATCH_GRADE_ADJ_AMT a
using (
select 
*
from no_tmp_TB_BATCH_GRADE_ADJ_AMT
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO AND
A.YYYYMM = T.YYYYMM AND
A.ORDER_CD = T.ORDER_CD

)
when matched then
update set

A.AMT = T.AMT,
A.BTNT_ID = T.BTNT_ID,
A.GRADE = T.GRADE,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP

when not matched then
insert (

A.MEM_NO,
A.YYYYMM,
A.AMT,
A.BTNT_ID,
A.ORDER_CD,
A.GRADE,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP


)
values (

T.MEM_NO,
T.YYYYMM,
T.AMT,
T.BTNT_ID,
T.ORDER_CD,
T.GRADE,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_BNFT_MST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_BNFT_MST';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_BNFT_MST a
using (
select 
*
from no_tmp_TB_BNFT_MST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.BNFT_TP_CD = T.BNFT_TP_CD

)
when matched then
update set

A.BNFT_NM = T.BNFT_NM,
A.BNFT_OFFER_TP_CD = T.BNFT_OFFER_TP_CD,
A.BNFT_OFFER_NM = T.BNFT_OFFER_NM,
A.BNFT_OFFER_EXPLANATION = T.BNFT_OFFER_EXPLANATION,
A.BNFT_OFFER_PAY_STD = T.BNFT_OFFER_PAY_STD,
A.BNFT_OFFER_PAY_DT = T.BNFT_OFFER_PAY_DT,
A.APPLY_STT_DT = T.APPLY_STT_DT,
A.APPLY_END_DT = T.APPLY_END_DT,
A.VALID_PERIOD_TP = T.VALID_PERIOD_TP,
A.VALID_PERIOD = T.VALID_PERIOD,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP

when not matched then
insert (

A.BNFT_TP_CD,
A.BNFT_NM,
A.BNFT_OFFER_TP_CD,
A.BNFT_OFFER_NM,
A.BNFT_OFFER_EXPLANATION,
A.BNFT_OFFER_PAY_STD,
A.BNFT_OFFER_PAY_DT,
A.APPLY_STT_DT,
A.APPLY_END_DT,
A.VALID_PERIOD_TP,
A.VALID_PERIOD,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP

)
values (

T.BNFT_TP_CD,
T.BNFT_NM,
T.BNFT_OFFER_TP_CD,
T.BNFT_OFFER_NM,
T.BNFT_OFFER_EXPLANATION,
T.BNFT_OFFER_PAY_STD,
T.BNFT_OFFER_PAY_DT,
T.APPLY_STT_DT,
T.APPLY_END_DT,
T.VALID_PERIOD_TP,
T.VALID_PERIOD,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_CARD_MILEAGE

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_CARD_MILEAGE';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_CARD_MILEAGE a
using (
select 
*
from no_tmp_TB_CARD_MILEAGE
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.CARD_NO = T.CARD_NO

)
when matched then
update set

A.NOR_MILEAGE = T.NOR_MILEAGE,
A.ALLI_MILEAGE = T.ALLI_MILEAGE,
A.SPEC_MILEAGE = T.SPEC_MILEAGE,
A.TOT_ACC_NOR_MILEAGE = T.TOT_ACC_NOR_MILEAGE,
A.TOT_ACC_ALLI_MILEAGE = T.TOT_ACC_ALLI_MILEAGE,
A.TOT_ACC_SPEC_MILEAGE = T.TOT_ACC_SPEC_MILEAGE,
A.TOT_USE_NOR_MILEAGE = T.TOT_USE_NOR_MILEAGE,
A.TOT_USE_ALLI_MILEAGE = T.TOT_USE_ALLI_MILEAGE,
A.TOT_USE_SPEC_MILEAGE = T.TOT_USE_SPEC_MILEAGE,
A.TOT_ACC_APPR_AMT = T.TOT_ACC_APPR_AMT,
A.TOT_USE_APPR_AMT = T.TOT_USE_APPR_AMT,
A.FIRST_TRADE_DT = T.FIRST_TRADE_DT,
A.FIRST_TRADE_SHOP_CD = T.FIRST_TRADE_SHOP_CD,
A.LAST_TRADE_DT = T.LAST_TRADE_DT,
A.LAST_TRADE_SHOP_CD = T.LAST_TRADE_SHOP_CD,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.TOT_EX_NOR_MILEAGE = T.TOT_EX_NOR_MILEAGE,
A.TOT_EX_ALLI_MILEAGE = T.TOT_EX_ALLI_MILEAGE,
A.TOT_EX_SPEC_MILEAGE = T.TOT_EX_SPEC_MILEAGE

when not matched then
insert (

A.CARD_NO,
A.NOR_MILEAGE,
A.ALLI_MILEAGE,
A.SPEC_MILEAGE,
A.TOT_ACC_NOR_MILEAGE,
A.TOT_ACC_ALLI_MILEAGE,
A.TOT_ACC_SPEC_MILEAGE,
A.TOT_USE_NOR_MILEAGE,
A.TOT_USE_ALLI_MILEAGE,
A.TOT_USE_SPEC_MILEAGE,
A.TOT_ACC_APPR_AMT,
A.TOT_USE_APPR_AMT,
A.FIRST_TRADE_DT,
A.FIRST_TRADE_SHOP_CD,
A.LAST_TRADE_DT,
A.LAST_TRADE_SHOP_CD,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.TOT_EX_NOR_MILEAGE,
A.TOT_EX_ALLI_MILEAGE,
A.TOT_EX_SPEC_MILEAGE

)
values (

T.CARD_NO,
T.NOR_MILEAGE,
T.ALLI_MILEAGE,
T.SPEC_MILEAGE,
T.TOT_ACC_NOR_MILEAGE,
T.TOT_ACC_ALLI_MILEAGE,
T.TOT_ACC_SPEC_MILEAGE,
T.TOT_USE_NOR_MILEAGE,
T.TOT_USE_ALLI_MILEAGE,
T.TOT_USE_SPEC_MILEAGE,
T.TOT_ACC_APPR_AMT,
T.TOT_USE_APPR_AMT,
T.FIRST_TRADE_DT,
T.FIRST_TRADE_SHOP_CD,
T.LAST_TRADE_DT,
T.LAST_TRADE_SHOP_CD,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.TOT_EX_NOR_MILEAGE,
T.TOT_EX_ALLI_MILEAGE,
T.TOT_EX_SPEC_MILEAGE

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_CARD_MST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_CARD_MST';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_CARD_MST a
using (
select 
*
from no_tmp_TB_CARD_MST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.CARD_NO = T.CARD_NO AND
A.MEM_NO = T.MEM_NO

)
when matched then
update set

A.CARD_TP_CD = T.CARD_TP_CD,
A.CARD_STAT_CD = T.CARD_STAT_CD,
A.REPRE_CARD_YN = T.REPRE_CARD_YN,
A.ALLI_STAT_CD = T.ALLI_STAT_CD,
A.BAD_STAT_CD = T.BAD_STAT_CD,
A.STOP_REASON_CD = T.STOP_REASON_CD,
A.ISSUE_CH_CD = T.ISSUE_CH_CD,
A.CHG_CH_CD = T.CHG_CH_CD,
A.ISSUE_SHOP_CD = T.ISSUE_SHOP_CD,
A.REG_SHOP_CD = T.REG_SHOP_CD,
A.VALID_YM = T.VALID_YM,
A.CVC_NO = T.CVC_NO,
A.TRAC2_VALUE = T.TRAC2_VALUE,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.CARD_PUB_CD = T.CARD_PUB_CD,
A.OLD_ISSUE_SHOP_CD = T.OLD_ISSUE_SHOP_CD


when not matched then
insert (

A.CARD_NO,
A.MEM_NO,
A.CARD_TP_CD,
A.CARD_STAT_CD,
A.REPRE_CARD_YN,
A.ALLI_STAT_CD,
A.BAD_STAT_CD,
A.STOP_REASON_CD,
A.ISSUE_CH_CD,
A.CHG_CH_CD,
A.ISSUE_SHOP_CD,
A.REG_SHOP_CD,
A.VALID_YM,
A.CVC_NO,
A.TRAC2_VALUE,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.CARD_PUB_CD,
A.OLD_ISSUE_SHOP_CD


)
values (

T.CARD_NO,
T.MEM_NO,
T.CARD_TP_CD,
T.CARD_STAT_CD,
T.REPRE_CARD_YN,
T.ALLI_STAT_CD,
T.BAD_STAT_CD,
T.STOP_REASON_CD,
T.ISSUE_CH_CD,
T.CHG_CH_CD,
T.ISSUE_SHOP_CD,
T.REG_SHOP_CD,
T.VALID_YM,
T.CVC_NO,
T.TRAC2_VALUE,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.CARD_PUB_CD,
T.OLD_ISSUE_SHOP_CD

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

/*
-------- TB_CARD_MST_LOG

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'aaaa';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into aaaa a
using (
select 
*
from no_tmp_aaaa
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (



)
when matched then
update set



when not matched then
insert (



)
values (



)
;


vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

*/

-------- TB_CD_MST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_CD_MST';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_CD_MST a
using (
select 
*
from no_tmp_TB_CD_MST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.CD_GRP_CD = T.CD_GRP_CD AND
A.CD = T.CD

)
when matched then
update set

A.CD_NM = T.CD_NM,
A.PARENT_CD = T.PARENT_CD,
A.DISP_SEQ = T.DISP_SEQ,
A.USE_YN = T.USE_YN,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP

when not matched then
insert (

A.CD_GRP_CD,
A.CD,
A.CD_NM,
A.PARENT_CD,
A.DISP_SEQ,
A.USE_YN,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP


)
values (

T.CD_GRP_CD,
T.CD,
T.CD_NM,
T.PARENT_CD,
T.DISP_SEQ,
T.USE_YN,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_COUP_HIST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_COUP_HIST';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_COUP_HIST a
using (
select 
*
from no_tmp_TB_COUP_HIST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.COUP_NO = T.COUP_NO AND
A.REG_DTM = T.REG_DTM

)
when matched then
update set

A.COUP_CD = T.COUP_CD,
A.ISSUE_MEM_NO = T.ISSUE_MEM_NO,
A.USE_MEM_NO = T.USE_MEM_NO,
A.ISSUE_CH = T.ISSUE_CH,
A.ISSUE_DT = T.ISSUE_DT,
A.ISSUE_SHOP_CD = T.ISSUE_SHOP_CD,
A.APPR_DT = T.APPR_DT,
A.APPR_TM = T.APPR_TM,
A.APPR_SEQ = T.APPR_SEQ,
A.TRADE_DT = T.TRADE_DT,
A.TRADE_TM = T.TRADE_TM,
A.TRACE_NO = T.TRACE_NO,
A.USE_CH = T.USE_CH,
A.USE_DT = T.USE_DT,
A.USE_SHOP_CD = T.USE_SHOP_CD,
A.VALID_STT_DT = T.VALID_STT_DT,
A.VALID_END_DT = T.VALID_END_DT,
A.COUP_APPLY_TRG_AMT = T.COUP_APPLY_TRG_AMT,
A.COUP_APPLY_AMT = T.COUP_APPLY_AMT,
A.APPLY_OFF_PROM_CD = T.APPLY_OFF_PROM_CD,
A.APPLY_ON_PROM_CD = T.APPLY_ON_PROM_CD,
A.USE_YN = T.USE_YN,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.ISSUE_TRACE_NO = T.ISSUE_TRACE_NO

when not matched then
insert (

A.COUP_NO,
A.COUP_CD,
A.ISSUE_MEM_NO,
A.USE_MEM_NO,
A.ISSUE_CH,
A.ISSUE_DT,
A.ISSUE_SHOP_CD,
A.APPR_DT,
A.APPR_TM,
A.APPR_SEQ,
A.TRADE_DT,
A.TRADE_TM,
A.TRACE_NO,
A.USE_CH,
A.USE_DT,
A.USE_SHOP_CD,
A.VALID_STT_DT,
A.VALID_END_DT,
A.COUP_APPLY_TRG_AMT,
A.COUP_APPLY_AMT,
A.APPLY_OFF_PROM_CD,
A.APPLY_ON_PROM_CD,
A.USE_YN,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.ISSUE_TRACE_NO


)
values (

T.COUP_NO,
T.COUP_CD,
T.ISSUE_MEM_NO,
T.USE_MEM_NO,
T.ISSUE_CH,
T.ISSUE_DT,
T.ISSUE_SHOP_CD,
T.APPR_DT,
T.APPR_TM,
T.APPR_SEQ,
T.TRADE_DT,
T.TRADE_TM,
T.TRACE_NO,
T.USE_CH,
T.USE_DT,
T.USE_SHOP_CD,
T.VALID_STT_DT,
T.VALID_END_DT,
T.COUP_APPLY_TRG_AMT,
T.COUP_APPLY_AMT,
T.APPLY_OFF_PROM_CD,
T.APPLY_ON_PROM_CD,
T.USE_YN,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.ISSUE_TRACE_NO

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

/*
-------- TB_COUP_HIST_LOG

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'aaaa';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into aaaa a
using (
select 
*
from no_tmp_aaaa
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.COUP_NO = T.COUP_NO AND
A.MOD_DTM = T.MOD_DTM

)
when matched then
update set

A.COUP_CD = T.COUP_CD,
A.ISSUE_MEM_NO = T.ISSUE_MEM_NO,
A.USE_MEM_NO = T.USE_MEM_NO,
A.ISSUE_CH = T.ISSUE_CH,
A.ISSUE_DT = T.ISSUE_DT,
A.ISSUE_SHOP_CD = T.ISSUE_SHOP_CD,
A.APPR_DT = T.APPR_DT,
A.APPR_TM = T.APPR_TM,
A.APPR_SEQ = T.APPR_SEQ,
A.TRADE_DT = T.TRADE_DT,
A.TRADE_TM = T.TRADE_TM,
A.TRACE_NO = T.TRACE_NO,
A.USE_CH = T.USE_CH,
A.USE_DT = T.USE_DT,
A.USE_SHOP_CD = T.USE_SHOP_CD,
A.VALID_STT_DT = T.VALID_STT_DT,
A.VALID_END_DT = T.VALID_END_DT,
A.COUP_APPLY_TRG_AMT = T.COUP_APPLY_TRG_AMT,
A.COUP_APPLY_AMT = T.COUP_APPLY_AMT,
A.APPLY_OFF_PROM_CD = T.APPLY_OFF_PROM_CD,
A.APPLY_ON_PROM_CD = T.APPLY_ON_PROM_CD,
A.USE_YN = T.USE_YN,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.ISSUE_TRACE_NO = T.ISSUE_TRACE_NO


when not matched then
insert (

A.COUP_NO,
A.COUP_CD,
A.ISSUE_MEM_NO,
A.USE_MEM_NO,
A.ISSUE_CH,
A.ISSUE_DT,
A.ISSUE_SHOP_CD,
A.APPR_DT,
A.APPR_TM,
A.APPR_SEQ,
A.TRADE_DT,
A.TRADE_TM,
A.TRACE_NO,
A.USE_CH,
A.USE_DT,
A.USE_SHOP_CD,
A.VALID_STT_DT,
A.VALID_END_DT,
A.COUP_APPLY_TRG_AMT,
A.COUP_APPLY_AMT,
A.APPLY_OFF_PROM_CD,
A.APPLY_ON_PROM_CD,
A.USE_YN,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.ISSUE_TRACE_NO

)
values (

T.COUP_NO,
T.COUP_CD,
T.ISSUE_MEM_NO,
T.USE_MEM_NO,
T.ISSUE_CH,
T.ISSUE_DT,
T.ISSUE_SHOP_CD,
T.APPR_DT,
T.APPR_TM,
T.APPR_SEQ,
T.TRADE_DT,
T.TRADE_TM,
T.TRACE_NO,
T.USE_CH,
T.USE_DT,
T.USE_SHOP_CD,
T.VALID_STT_DT,
T.VALID_END_DT,
T.COUP_APPLY_TRG_AMT,
T.COUP_APPLY_AMT,
T.APPLY_OFF_PROM_CD,
T.APPLY_ON_PROM_CD,
T.USE_YN,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.ISSUE_TRACE_NO

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

*/

-------- TB_COUP_MST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_COUP_MST';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_COUP_MST a
using (
select 
*
from no_tmp_TB_COUP_MST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.COUP_CD = T.COUP_CD AND
A.CH_DIV_CD = T.CH_DIV_CD AND
A.BRAND_CD = T.BRAND_CD AND
A.SUB_BRAND_CD = T.SUB_BRAND_CD AND
A.GRADE_CD = T.GRADE_CD AND
A.ITEM_LCLS_CD = T.ITEM_LCLS_CD AND
A.ITEM_MCLS_CD = T.ITEM_MCLS_CD AND
A.ITEM_SCLS_CD = T.ITEM_SCLS_CD AND
A.APPLY_STT_DT = T.APPLY_STT_DT

)
when matched then
update set

A.COUP_NM = T.COUP_NM,
A.SHOP_CD = T.SHOP_CD,
A.ISSUE_LIMIT_DIV = T.ISSUE_LIMIT_DIV,
A.USE_LIMIT_DIV = T.USE_LIMIT_DIV,
A.COUP_DIV = T.COUP_DIV,
A.COUP_LEN = T.COUP_LEN,
A.REPRE_COUP_NO = T.REPRE_COUP_NO,
A.APPLY_DIV = T.APPLY_DIV,
A.MIN_SALE_AMT = T.MIN_SALE_AMT,
A.MAX_APPLY_AMT = T.MAX_APPLY_AMT,
A.DC_AMT = T.DC_AMT,
A.DC_RATE = T.DC_RATE,
A.ACC_MILEAGE = T.ACC_MILEAGE,
A.ACC_RATE = T.ACC_RATE,
A.ITEM_CD = T.ITEM_CD,
A.ON_PROM_CD = T.ON_PROM_CD,
A.OFF_PROM_CD = T.OFF_PROM_CD,
A.APPLY_END_DT = T.APPLY_END_DT,
A.VALID_PERIOD_DIV = T.VALID_PERIOD_DIV,
A.FIX_VALID_PERIOD = T.FIX_VALID_PERIOD,
A.VALID_PERIOD = T.VALID_PERIOD,
A.CALC_RULE_CD = T.CALC_RULE_CD,
A.USE_YN = T.USE_YN,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.COUP_NO_FIX_YN = T.COUP_NO_FIX_YN,
A.SEND_MSG_YN = T.SEND_MSG_YN,
A.SEND_MSG = T.SEND_MSG,
A.SEND_DT = T.SEND_DT

when not matched then
insert (

A.COUP_CD,
A.CH_DIV_CD,
A.BRAND_CD,
A.SUB_BRAND_CD,
A.GRADE_CD,
A.ITEM_LCLS_CD,
A.ITEM_MCLS_CD,
A.ITEM_SCLS_CD,
A.APPLY_STT_DT,
A.COUP_NM,
A.SHOP_CD,
A.ISSUE_LIMIT_DIV,
A.USE_LIMIT_DIV,
A.COUP_DIV,
A.COUP_LEN,
A.REPRE_COUP_NO,
A.APPLY_DIV,
A.MIN_SALE_AMT,
A.MAX_APPLY_AMT,
A.DC_AMT,
A.DC_RATE,
A.ACC_MILEAGE,
A.ACC_RATE,
A.ITEM_CD,
A.ON_PROM_CD,
A.OFF_PROM_CD,
A.APPLY_END_DT,
A.VALID_PERIOD_DIV,
A.FIX_VALID_PERIOD,
A.VALID_PERIOD,
A.CALC_RULE_CD,
A.USE_YN,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.COUP_NO_FIX_YN,
A.SEND_MSG_YN,
A.SEND_MSG,
A.SEND_DT

)
values (

T.COUP_CD,
T.CH_DIV_CD,
T.BRAND_CD,
T.SUB_BRAND_CD,
T.GRADE_CD,
T.ITEM_LCLS_CD,
T.ITEM_MCLS_CD,
T.ITEM_SCLS_CD,
T.APPLY_STT_DT,
T.COUP_NM,
T.SHOP_CD,
T.ISSUE_LIMIT_DIV,
T.USE_LIMIT_DIV,
T.COUP_DIV,
T.COUP_LEN,
T.REPRE_COUP_NO,
T.APPLY_DIV,
T.MIN_SALE_AMT,
T.MAX_APPLY_AMT,
T.DC_AMT,
T.DC_RATE,
T.ACC_MILEAGE,
T.ACC_RATE,
T.ITEM_CD,
T.ON_PROM_CD,
T.OFF_PROM_CD,
T.APPLY_END_DT,
T.VALID_PERIOD_DIV,
T.FIX_VALID_PERIOD,
T.VALID_PERIOD,
T.CALC_RULE_CD,
T.USE_YN,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.COUP_NO_FIX_YN,
T.SEND_MSG_YN,
T.SEND_MSG,
T.SEND_DT

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_GRADE_MST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_GRADE_MST';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_GRADE_MST a
using (
select 
*
from no_tmp_TB_GRADE_MST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.GRADE_CD = T.GRADE_CD

)
when matched then
update set

A.GRADE_NM = T.GRADE_NM,
A.GRADE_GRP_CD = T.GRADE_GRP_CD,
A.UP_GRADE_GRP_CD = T.UP_GRADE_GRP_CD,
A.BRAND_TP = T.BRAND_TP,
A.APPLY_STT_DT = T.APPLY_STT_DT,
A.APPLY_END_DT = T.APPLY_END_DT,
A.RULE_CD = T.RULE_CD,
A.STD_SALE_AMT = T.STD_SALE_AMT,
A.GRADE_KEEP_PERIOD = T.GRADE_KEEP_PERIOD,
A.USE_YN = T.USE_YN,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.NEW_OLD_CD = T.NEW_OLD_CD


when not matched then
insert (

A.GRADE_CD,
A.GRADE_NM,
A.GRADE_GRP_CD,
A.UP_GRADE_GRP_CD,
A.BRAND_TP,
A.APPLY_STT_DT,
A.APPLY_END_DT,
A.RULE_CD,
A.STD_SALE_AMT,
A.GRADE_KEEP_PERIOD,
A.USE_YN,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.NEW_OLD_CD


)
values (

T.GRADE_CD,
T.GRADE_NM,
T.GRADE_GRP_CD,
T.UP_GRADE_GRP_CD,
T.BRAND_TP,
T.APPLY_STT_DT,
T.APPLY_END_DT,
T.RULE_CD,
T.STD_SALE_AMT,
T.GRADE_KEEP_PERIOD,
T.USE_YN,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.NEW_OLD_CD


)
;


vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_ADDINFO

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_ADDINFO';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_MEM_ADDINFO a
using (
select 
*
from no_tmp_TB_MEM_ADDINFO
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO

)
when matched then
update set

A.MAIN_CH_CD = T.MAIN_CH_CD,
A.MAIN_SHOP_CD = T.MAIN_SHOP_CD,
A.BRAND_CD = T.BRAND_CD,
A.REAL_BIRTH_SOL_DIV_CD = T.REAL_BIRTH_SOL_DIV_CD,
A.REAL_BIRTH_DT = T.REAL_BIRTH_DT,
A.WEDD_YN = T.WEDD_YN,
A.WEDD_SOL_DIV_CD = T.WEDD_SOL_DIV_CD,
A.WEDD_DT = T.WEDD_DT,
A.HOMEPAGE_URL = T.HOMEPAGE_URL,
A.SNS_URL = T.SNS_URL,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.OLD_MAIN_SHOP_CD = T.OLD_MAIN_SHOP_CD

when not matched then
insert (

A.MEM_NO,
A.MAIN_CH_CD,
A.MAIN_SHOP_CD,
A.BRAND_CD,
A.REAL_BIRTH_SOL_DIV_CD,
A.REAL_BIRTH_DT,
A.WEDD_YN,
A.WEDD_SOL_DIV_CD,
A.WEDD_DT,
A.HOMEPAGE_URL,
A.SNS_URL,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.OLD_MAIN_SHOP_CD


)
values (

T.MEM_NO,
T.MAIN_CH_CD,
T.MAIN_SHOP_CD,
T.BRAND_CD,
T.REAL_BIRTH_SOL_DIV_CD,
T.REAL_BIRTH_DT,
T.WEDD_YN,
T.WEDD_SOL_DIV_CD,
T.WEDD_DT,
T.HOMEPAGE_URL,
T.SNS_URL,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.OLD_MAIN_SHOP_CD


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_ADDINFO_LOG

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_ADDINFO_LOG';
no_pkg_mig.log_debug('table => ' || vs_table_name);


insert into TB_MEM_ADDINFO_LOG
select 
*
from no_tmp_TB_MEM_ADDINFO_LOG
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;


-------- TB_MEM_BNFT_HIST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_BNFT_HIST';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_MEM_BNFT_HIST a
using (
select 
*
from no_tmp_TB_MEM_BNFT_HIST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO AND
A.BNFT_TP_CD = T.BNFT_TP_CD AND
A.SEQ_NO = T.SEQ_NO

)
when matched then
update set

A.BNFT_ARISE_DT = T.BNFT_ARISE_DT,
A.BNFT_PAY_DT = T.BNFT_PAY_DT,
A.BNFT_RECV_DT = T.BNFT_RECV_DT,
A.BNFT_VALID_PERIOD = T.BNFT_VALID_PERIOD,
A.BENEFIT_MST_CD = T.BENEFIT_MST_CD,
A.BENEFIT_DTA_CD = T.BENEFIT_DTA_CD,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.DEL_YN = T.DEL_YN,
A.GRADE_CD = T.GRADE_CD,
A.PROM_CD = T.PROM_CD


when not matched then
insert (

A.MEM_NO,
A.BNFT_TP_CD,
A.SEQ_NO,
A.BNFT_ARISE_DT,
A.BNFT_PAY_DT,
A.BNFT_RECV_DT,
A.BNFT_VALID_PERIOD,
A.BENEFIT_MST_CD,
A.BENEFIT_DTA_CD,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.DEL_YN,
A.GRADE_CD,
A.PROM_CD


)
values (

T.MEM_NO,
T.BNFT_TP_CD,
T.SEQ_NO,
T.BNFT_ARISE_DT,
T.BNFT_PAY_DT,
T.BNFT_RECV_DT,
T.BNFT_VALID_PERIOD,
T.BENEFIT_MST_CD,
T.BENEFIT_DTA_CD,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.DEL_YN,
T.GRADE_CD,
T.PROM_CD


)
;


vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_CALC_RULE

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_CALC_RULE';
no_pkg_mig.log_debug('table => ' || vs_table_name);


merge into TB_MEM_CALC_RULE a
using (
select 
*
from no_tmp_TB_MEM_CALC_RULE
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.CALC_RULE_CD = T.CALC_RULE_CD

)
when matched then
update set

A.CALC_RULE_NM = T.CALC_RULE_NM,
A.CALC_TP_CD = T.CALC_TP_CD,
A.BURDEN_RATE = T.BURDEN_RATE,
A.SHOP_BURDEN_RATE = T.SHOP_BURDEN_RATE,
A.APPLY_STT_DT = T.APPLY_STT_DT,
A.APPLY_END_DT = T.APPLY_END_DT,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.USE_YN = T.USE_YN


when not matched then
insert (

A.CALC_RULE_CD,
A.CALC_RULE_NM,
A.CALC_TP_CD,
A.BURDEN_RATE,
A.SHOP_BURDEN_RATE,
A.APPLY_STT_DT,
A.APPLY_END_DT,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.USE_YN


)
values (

T.CALC_RULE_CD,
T.CALC_RULE_NM,
T.CALC_TP_CD,
T.BURDEN_RATE,
T.SHOP_BURDEN_RATE,
T.APPLY_STT_DT,
T.APPLY_END_DT,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.USE_YN


)
;


vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_GIFTICON_HIST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_GIFTICON_HIST';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_GIFTICON_HIST a
using (
select 
*
from no_tmp_TB_MEM_GIFTICON_HIST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.IO_DT = T.IO_DT AND
A.MEM_NO = T.MEM_NO AND
A.TR_ID = T.TR_ID

)
when matched then
update set

A.SID = T.SID,
A.GOODS_ID = T.GOODS_ID,
A.SEND_NO = T.SEND_NO,
A.RECV_NO = T.RECV_NO,
A.REAL_SEND = T.REAL_SEND,
A.MSG = T.MSG,
A.PIN_NO = T.PIN_NO,
A.PERIOD = T.PERIOD,
A.PERIOD_DATE = T.PERIOD_DATE,
A.STATUS_CODE = T.STATUS_CODE,
A.RESULT_CODE = T.RESULT_CODE,
A.RESULT_REASON = T.RESULT_REASON,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP


when not matched then
insert (

A.IO_DT,
A.MEM_NO,
A.TR_ID,
A.SID,
A.GOODS_ID,
A.SEND_NO,
A.RECV_NO,
A.REAL_SEND,
A.MSG,
A.PIN_NO,
A.PERIOD,
A.PERIOD_DATE,
A.STATUS_CODE,
A.RESULT_CODE,
A.RESULT_REASON,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP


)
values (

T.IO_DT,
T.MEM_NO,
T.TR_ID,
T.SID,
T.GOODS_ID,
T.SEND_NO,
T.RECV_NO,
T.REAL_SEND,
T.MSG,
T.PIN_NO,
T.PERIOD,
T.PERIOD_DATE,
T.STATUS_CODE,
T.RESULT_CODE,
T.RESULT_REASON,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_GRADE

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_GRADE';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_GRADE a
using (
select 
*
from no_tmp_TB_MEM_GRADE
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO


)
when matched then
update set

A.GRADE_CD = T.GRADE_CD,
A.APPLY_STT_DT = T.APPLY_STT_DT,
A.APPLY_END_DT = T.APPLY_END_DT,
A.GRADE_APPLY_TP = T.GRADE_APPLY_TP,
A.REMARK = T.REMARK,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP


when not matched then
insert (

A.MEM_NO,
A.GRADE_CD,
A.APPLY_STT_DT,
A.APPLY_END_DT,
A.GRADE_APPLY_TP,
A.REMARK,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP


)
values (

T.MEM_NO,
T.GRADE_CD,
T.APPLY_STT_DT,
T.APPLY_END_DT,
T.GRADE_APPLY_TP,
T.REMARK,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_GRADE_ADJ_HIST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_GRADE_ADJ_HIST';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_GRADE_ADJ_HIST a
using (
select 
*
from no_tmp_TB_MEM_GRADE_ADJ_HIST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO AND
A.ADJ_DT = T.ADJ_DT AND
A.SEQ = T.SEQ


)
when matched then
update set

A.OLD_GRADE = T.OLD_GRADE,
A.ADJ_GRADE = T.ADJ_GRADE,
A.GRADE_APPLY_SDT = T.GRADE_APPLY_SDT,
A.GRADE_APPLY_EDT = T.GRADE_APPLY_EDT,
A.REMARK = T.REMARK,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.FLAG_CD = T.FLAG_CD

when not matched then
insert (

A.MEM_NO,
A.ADJ_DT,
A.SEQ,
A.OLD_GRADE,
A.ADJ_GRADE,
A.GRADE_APPLY_SDT,
A.GRADE_APPLY_EDT,
A.REMARK,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.FLAG_CD


)
values (

T.MEM_NO,
T.ADJ_DT,
T.SEQ,
T.OLD_GRADE,
T.ADJ_GRADE,
T.GRADE_APPLY_SDT,
T.GRADE_APPLY_EDT,
T.REMARK,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.FLAG_CD

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_GRADE_TRANS

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_GRADE_TRANS';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_GRADE_TRANS a
using (
select 
*
from no_tmp_TB_MEM_GRADE_TRANS
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO


)
when matched then
update set

A.REG_DT = T.REG_DT,
A.CH_TP_CD = T.CH_TP_CD,
A.TRANS_YN = T.TRANS_YN,
A.OLD_GRADE = T.OLD_GRADE,
A.NEW_GRADE = T.NEW_GRADE,
A.REG_SHOP = T.REG_SHOP,
A.AGR_YN = T.AGR_YN,
A.REG_TM = T.REG_TM,
A.APPR_DT = T.APPR_DT,
A.APPR_TM = T.APPR_TM,
A.APPR_SEQ = T.APPR_SEQ,
A.TRNS_PROG_STS = T.TRNS_PROG_STS,
A.TRNS_GRADE = T.TRNS_GRADE,
A.TRNS_DATE = T.TRNS_DATE,
A.TRNS_AMT = T.TRNS_AMT,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.REMARK = T.REMARK


when not matched then
insert (

A.MEM_NO,
A.REG_DT,
A.CH_TP_CD,
A.TRANS_YN,
A.OLD_GRADE,
A.NEW_GRADE,
A.REG_SHOP,
A.AGR_YN,
A.REG_TM,
A.APPR_DT,
A.APPR_TM,
A.APPR_SEQ,
A.TRNS_PROG_STS,
A.TRNS_GRADE,
A.TRNS_DATE,
A.TRNS_AMT,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.REMARK


)
values (

T.MEM_NO,
T.REG_DT,
T.CH_TP_CD,
T.TRANS_YN,
T.OLD_GRADE,
T.NEW_GRADE,
T.REG_SHOP,
T.AGR_YN,
T.REG_TM,
T.APPR_DT,
T.APPR_TM,
T.APPR_SEQ,
T.TRNS_PROG_STS,
T.TRNS_GRADE,
T.TRNS_DATE,
T.TRNS_AMT,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.REMARK


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_JOININFO

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_JOININFO';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_JOININFO a
using (
select 
*
from no_tmp_TB_MEM_JOININFO
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO


)
when matched then
update set

A.JOIN_CH_CD = T.JOIN_CH_CD,
A.JOIN_BRAND_CD = T.JOIN_BRAND_CD,
A.JOIN_DT = T.JOIN_DT,
A.JOIN_SHOP_CD = T.JOIN_SHOP_CD,
A.NOR_MEM_JOIN_SHOP_CD = T.NOR_MEM_JOIN_SHOP_CD,
A.FOREIGN_JOIN_SHOP_CD = T.FOREIGN_JOIN_SHOP_CD,
A.FOREIGN_APPR_YN = T.FOREIGN_APPR_YN,
A.PASSPORT_NO = T.PASSPORT_NO,
A.NM_APPR_YN = T.NM_APPR_YN,
A.NM_APPR_DTM = T.NM_APPR_DTM,
A.CERT_YN = T.CERT_YN,
A.CERT_DTM = T.CERT_DTM,
A.CERT_TP = T.CERT_TP,
A.CERT_NO = T.CERT_NO,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.MEM_TP = T.MEM_TP,
A.OLD_JOIN_SHOP_CD = T.OLD_JOIN_SHOP_CD

when not matched then
insert (

A.MEM_NO,
A.JOIN_CH_CD,
A.JOIN_BRAND_CD,
A.JOIN_DT,
A.JOIN_SHOP_CD,
A.NOR_MEM_JOIN_SHOP_CD,
A.FOREIGN_JOIN_SHOP_CD,
A.FOREIGN_APPR_YN,
A.PASSPORT_NO,
A.NM_APPR_YN,
A.NM_APPR_DTM,
A.CERT_YN,
A.CERT_DTM,
A.CERT_TP,
A.CERT_NO,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.MEM_TP,
A.OLD_JOIN_SHOP_CD

)
values (

T.MEM_NO,
T.JOIN_CH_CD,
T.JOIN_BRAND_CD,
T.JOIN_DT,
T.JOIN_SHOP_CD,
T.NOR_MEM_JOIN_SHOP_CD,
T.FOREIGN_JOIN_SHOP_CD,
T.FOREIGN_APPR_YN,
T.PASSPORT_NO,
T.NM_APPR_YN,
T.NM_APPR_DTM,
T.CERT_YN,
T.CERT_DTM,
T.CERT_TP,
T.CERT_NO,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.MEM_TP,
T.OLD_JOIN_SHOP_CD


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_JOININFO_LOG

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_JOININFO_LOG';
no_pkg_mig.log_debug('table => ' || vs_table_name);


insert into TB_MEM_JOININFO_LOG
select 
*
from no_tmp_TB_MEM_JOININFO_LOG
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_MOD_RES_IF

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_MOD_RES_IF';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_MOD_RES_IF a
using (
select 
*
from no_tmp_TB_MEM_MOD_RES_IF
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.REQ_NO = T.REQ_NO AND
A.REASON_CD = T.REASON_CD

)
when matched then
update set

A.MEM_NO = T.MEM_NO,
A.CARD_NO = T.CARD_NO,
A.BTNT_ID = T.BTNT_ID,
A.TEL_NO = T.TEL_NO,
A.MOBILE_NO = T.MOBILE_NO,
A.ZIP_NO = T.ZIP_NO,
A.ADDR = T.ADDR,
A.DTL_ADDR = T.DTL_ADDR,
A.EMAIL_ADDR = T.EMAIL_ADDR,
A.REAL_BIRTH_SOL_DIV_CD = T.REAL_BIRTH_SOL_DIV_CD,
A.REAL_BIRTH_DT = T.REAL_BIRTH_DT,
A.WEDD_YN = T.WEDD_YN,
A.WEDD_SOL_DIV_CD = T.WEDD_SOL_DIV_CD,
A.WEDD_DT = T.WEDD_DT,
A.HOMEPAGE_URL = T.HOMEPAGE_URL,
A.SNS_URL = T.SNS_URL,
A.SMS_RECV_YN = T.SMS_RECV_YN,
A.DM_RECV_YN = T.DM_RECV_YN,
A.EM_RECV_YN = T.EM_RECV_YN,
A.TM_RECV_YN = T.TM_RECV_YN,
A.MARK_AGR_YN = T.MARK_AGR_YN,
A.PERS_AGR_YN = T.PERS_AGR_YN,
A.PERS3_AGR_YN = T.PERS3_AGR_YN,
A.NM_APPR_YN = T.NM_APPR_YN,
A.NM_APPR_DTM = T.NM_APPR_DTM,
A.CERT_YN = T.CERT_YN,
A.CERT_DTM = T.CERT_DTM,
A.CERT_TP = T.CERT_TP,
A.CERT_NO = T.CERT_NO,
A.STAT_CD = T.STAT_CD,
A.GRADE_CD = T.GRADE_CD,
A.GRADE_NM = T.GRADE_NM,
A.APPLY_STT_DT = T.APPLY_STT_DT,
A.APPLY_END_DT = T.APPLY_END_DT,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MODR_IP = T.MODR_IP,
A.MEM_NM = T.MEM_NM,
A.SEX_CD = T.SEX_CD,
A.BIRTH_DT = T.BIRTH_DT,
A.CH_TP_CD = T.CH_TP_CD


when not matched then
insert (

A.REQ_NO,
A.REASON_CD,
A.MEM_NO,
A.CARD_NO,
A.BTNT_ID,
A.TEL_NO,
A.MOBILE_NO,
A.ZIP_NO,
A.ADDR,
A.DTL_ADDR,
A.EMAIL_ADDR,
A.REAL_BIRTH_SOL_DIV_CD,
A.REAL_BIRTH_DT,
A.WEDD_YN,
A.WEDD_SOL_DIV_CD,
A.WEDD_DT,
A.HOMEPAGE_URL,
A.SNS_URL,
A.SMS_RECV_YN,
A.DM_RECV_YN,
A.EM_RECV_YN,
A.TM_RECV_YN,
A.MARK_AGR_YN,
A.PERS_AGR_YN,
A.PERS3_AGR_YN,
A.NM_APPR_YN,
A.NM_APPR_DTM,
A.CERT_YN,
A.CERT_DTM,
A.CERT_TP,
A.CERT_NO,
A.STAT_CD,
A.GRADE_CD,
A.GRADE_NM,
A.APPLY_STT_DT,
A.APPLY_END_DT,
A.MOD_DTM,
A.MODR_ID,
A.MODR_IP,
A.MEM_NM,
A.SEX_CD,
A.BIRTH_DT,
A.CH_TP_CD


)
values (

T.REQ_NO,
T.REASON_CD,
T.MEM_NO,
T.CARD_NO,
T.BTNT_ID,
T.TEL_NO,
T.MOBILE_NO,
T.ZIP_NO,
T.ADDR,
T.DTL_ADDR,
T.EMAIL_ADDR,
T.REAL_BIRTH_SOL_DIV_CD,
T.REAL_BIRTH_DT,
T.WEDD_YN,
T.WEDD_SOL_DIV_CD,
T.WEDD_DT,
T.HOMEPAGE_URL,
T.SNS_URL,
T.SMS_RECV_YN,
T.DM_RECV_YN,
T.EM_RECV_YN,
T.TM_RECV_YN,
T.MARK_AGR_YN,
T.PERS_AGR_YN,
T.PERS3_AGR_YN,
T.NM_APPR_YN,
T.NM_APPR_DTM,
T.CERT_YN,
T.CERT_DTM,
T.CERT_TP,
T.CERT_NO,
T.STAT_CD,
T.GRADE_CD,
T.GRADE_NM,
T.APPLY_STT_DT,
T.APPLY_END_DT,
T.MOD_DTM,
T.MODR_ID,
T.MODR_IP,
T.MEM_NM,
T.SEX_CD,
T.BIRTH_DT,
T.CH_TP_CD

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_MST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_MST';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_MST a
using (
select 
*
from no_tmp_TB_MEM_MST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO


)
when matched then
update set

A.MEM_NM = T.MEM_NM,
A.FOREIGN_YN = T.FOREIGN_YN,
A.AGE_14YEARS_YN = T.AGE_14YEARS_YN,
A.BIRTH_DT = T.BIRTH_DT,
A.SEX_CD = T.SEX_CD,
A.NICKNAME = T.NICKNAME,
A.BTNT_ID = T.BTNT_ID,
A.TEL_NO = T.TEL_NO,
A.MOBILE_NO = T.MOBILE_NO,
A.POST_TP = T.POST_TP,
A.ZIP_NO = T.ZIP_NO,
A.ADDR = T.ADDR,
A.DTL_ADDR = T.DTL_ADDR,
A.EMAIL_ADDR = T.EMAIL_ADDR,
A.EMAIL_ERROR_YN = T.EMAIL_ERROR_YN,
A.STAT_CD = T.STAT_CD,
A.WITHDRAWAL_CD = T.WITHDRAWAL_CD,
A.WITHDRAWAL_REMARK = T.WITHDRAWAL_REMARK,
A.USE_PASSWD = T.USE_PASSWD,
A.BLACKCONSUMER_CD = T.BLACKCONSUMER_CD,
A.BAD_STAT_CD = T.BAD_STAT_CD,
A.BAD_REASON_CD = T.BAD_REASON_CD,
A.BAD_REG_DTM = T.BAD_REG_DTM,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.CICS_SEQ = T.CICS_SEQ,
A.CI_BTNT_ID = T.CI_BTNT_ID,
A.CI_MSSH_ID = T.CI_MSSH_ID,
A.MOBILE_NO2 = T.MOBILE_NO2,
A.MOBILE_NO3 = T.MOBILE_NO3,
A.WITHDRAWAL_DT = T.WITHDRAWAL_DT


when not matched then
insert (

A.MEM_NO,
A.MEM_NM,
A.FOREIGN_YN,
A.AGE_14YEARS_YN,
A.BIRTH_DT,
A.SEX_CD,
A.NICKNAME,
A.BTNT_ID,
A.TEL_NO,
A.MOBILE_NO,
A.POST_TP,
A.ZIP_NO,
A.ADDR,
A.DTL_ADDR,
A.EMAIL_ADDR,
A.EMAIL_ERROR_YN,
A.STAT_CD,
A.WITHDRAWAL_CD,
A.WITHDRAWAL_REMARK,
A.USE_PASSWD,
A.BLACKCONSUMER_CD,
A.BAD_STAT_CD,
A.BAD_REASON_CD,
A.BAD_REG_DTM,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.CICS_SEQ,
A.CI_BTNT_ID,
A.CI_MSSH_ID,
A.MOBILE_NO2,
A.MOBILE_NO3,
A.WITHDRAWAL_DT


)
values (

T.MEM_NO,
T.MEM_NM,
T.FOREIGN_YN,
T.AGE_14YEARS_YN,
T.BIRTH_DT,
T.SEX_CD,
T.NICKNAME,
T.BTNT_ID,
T.TEL_NO,
T.MOBILE_NO,
T.POST_TP,
T.ZIP_NO,
T.ADDR,
T.DTL_ADDR,
T.EMAIL_ADDR,
T.EMAIL_ERROR_YN,
T.STAT_CD,
T.WITHDRAWAL_CD,
T.WITHDRAWAL_REMARK,
T.USE_PASSWD,
T.BLACKCONSUMER_CD,
T.BAD_STAT_CD,
T.BAD_REASON_CD,
T.BAD_REG_DTM,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.CICS_SEQ,
T.CI_BTNT_ID,
T.CI_MSSH_ID,
T.MOBILE_NO2,
T.MOBILE_NO3,
T.WITHDRAWAL_DT


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

/*

-------- TB_MEM_MST_LOG

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'aaaa';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into aaaa a
using (
select 
*
from no_tmp_aaaa
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (



)
when matched then
update set



when not matched then
insert (



)
values (



)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

*/

-------- TB_MEM_RECV_AGR

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_RECV_AGR';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_RECV_AGR a
using (
select 
*
from no_tmp_TB_MEM_RECV_AGR
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO

)
when matched then
update set

A.SMS_RECV_YN = T.SMS_RECV_YN,
A.SMS_AGR_CHG_DT = T.SMS_AGR_CHG_DT,
A.SMS_AGR_CHG_CH = T.SMS_AGR_CHG_CH,
A.DM_RECV_YN = T.DM_RECV_YN,
A.DM_AGR_CHG_DT = T.DM_AGR_CHG_DT,
A.DM_AGR_CHG_CH = T.DM_AGR_CHG_CH,
A.EM_RECV_YN = T.EM_RECV_YN,
A.EM_AGR_CHG_DT = T.EM_AGR_CHG_DT,
A.EM_AGR_CHG_CH = T.EM_AGR_CHG_CH,
A.TM_RECV_YN = T.TM_RECV_YN,
A.TM_AGR_CHG_DT = T.TM_AGR_CHG_DT,
A.TM_AGR_CHG_CH = T.TM_AGR_CHG_CH,
A.MARK_AGR_YN = T.MARK_AGR_YN,
A.MARK_AGR_CHG_DT = T.MARK_AGR_CHG_DT,
A.MARK_AGR_CHG_CH = T.MARK_AGR_CHG_CH,
A.PERS_AGR_YN = T.PERS_AGR_YN,
A.PERS_AGR_CHG_DT = T.PERS_AGR_CHG_DT,
A.PERS_AGR_CHG_CH = T.PERS_AGR_CHG_CH,
A.PERS3_AGR_YN = T.PERS3_AGR_YN,
A.PERS3_AGR_CHG_DT = T.PERS3_AGR_CHG_DT,
A.PERS3_AGR_CHG_CH = T.PERS3_AGR_CHG_CH,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP

when not matched then
insert (
A.MEM_NO,
A.SMS_RECV_YN,
A.SMS_AGR_CHG_DT,
A.SMS_AGR_CHG_CH,
A.DM_RECV_YN,
A.DM_AGR_CHG_DT,
A.DM_AGR_CHG_CH,
A.EM_RECV_YN,
A.EM_AGR_CHG_DT,
A.EM_AGR_CHG_CH,
A.TM_RECV_YN,
A.TM_AGR_CHG_DT,
A.TM_AGR_CHG_CH,
A.MARK_AGR_YN,
A.MARK_AGR_CHG_DT,
A.MARK_AGR_CHG_CH,
A.PERS_AGR_YN,
A.PERS_AGR_CHG_DT,
A.PERS_AGR_CHG_CH,
A.PERS3_AGR_YN,
A.PERS3_AGR_CHG_DT,
A.PERS3_AGR_CHG_CH,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP

)
values (

T.MEM_NO,
T.SMS_RECV_YN,
T.SMS_AGR_CHG_DT,
T.SMS_AGR_CHG_CH,
T.DM_RECV_YN,
T.DM_AGR_CHG_DT,
T.DM_AGR_CHG_CH,
T.EM_RECV_YN,
T.EM_AGR_CHG_DT,
T.EM_AGR_CHG_CH,
T.TM_RECV_YN,
T.TM_AGR_CHG_DT,
T.TM_AGR_CHG_CH,
T.MARK_AGR_YN,
T.MARK_AGR_CHG_DT,
T.MARK_AGR_CHG_CH,
T.PERS_AGR_YN,
T.PERS_AGR_CHG_DT,
T.PERS_AGR_CHG_CH,
T.PERS3_AGR_YN,
T.PERS3_AGR_CHG_DT,
T.PERS3_AGR_CHG_CH,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

/*
-------- TB_MEM_RECV_AGR_LOG

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'aaaa';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into aaaa a
using (
select 
*
from no_tmp_aaaa
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (



)
when matched then
update set



when not matched then
insert (



)
values (



)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

*/

-------- TB_MEM_REST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_REST';
no_pkg_mig.log_debug('table => ' || vs_table_name);

insert into TB_MEM_REST
select 
*
from no_tmp_TB_MEM_REST
where reg_dtm >= to_date(vs_target_date, 'yyyymmdd') and  reg_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_REST_MST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_REST_MST';
no_pkg_mig.log_debug('table => ' || vs_table_name);

insert into TB_MEM_REST_MST
select 
*
from no_tmp_TB_MEM_REST_MST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_TEMS_AGR


vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_TEMS_AGR';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_TEMS_AGR a
using (
select 
*
from no_tmp_TB_MEM_TEMS_AGR
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO AND
A.TERMS_CD = T.TERMS_CD

)
when matched then
update set

A.TERMS_AGR_YN = T.TERMS_AGR_YN,
A.TERMS_AGR_DT = T.TERMS_AGR_DT,
A.TERMS_AGR_CH = T.TERMS_AGR_CH,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP

when not matched then
insert (

A.MEM_NO,
A.TERMS_CD,
A.TERMS_AGR_YN,
A.TERMS_AGR_DT,
A.TERMS_AGR_CH,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP


)
values (

T.MEM_NO,
T.TERMS_CD,
T.TERMS_AGR_YN,
T.TERMS_AGR_DT,
T.TERMS_AGR_CH,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MEM_TRANS

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MEM_TRANS';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MEM_TRANS a
using (
select 
*
from no_tmp_TB_MEM_TRANS
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.MEM_NO = T.MEM_NO AND
A.TRANS_MEM_NO = T.TRANS_MEM_NO


)
when matched then
update set

A.TRANS_DT = T.TRANS_DT,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP


when not matched then
insert (

A.MEM_NO,
A.TRANS_MEM_NO,
A.TRANS_DT,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP


)
values (

T.MEM_NO,
T.TRANS_MEM_NO,
T.TRANS_DT,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MILEAGE_DTL

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MILEAGE_DTL';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MILEAGE_DTL a
using (
select 
*
from no_tmp_TB_MILEAGE_DTL
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.CARD_NO = T.CARD_NO AND
A.APPR_DT = T.APPR_DT AND
A.APPR_TM = T.APPR_TM AND
A.APPR_SEQ = T.APPR_SEQ AND
A.SEQ_NO = T.SEQ_NO


)
when matched then
update set

A.CH_TP_CD = T.CH_TP_CD,
A.ACC_USE_TP_CD = T.ACC_USE_TP_CD,
A.TELEX_TP_CD = T.TELEX_TP_CD,
A.TELEX_AGENCY_CD = T.TELEX_AGENCY_CD,
A.SHOP_CD = T.SHOP_CD,
A.TRADE_DT = T.TRADE_DT,
A.TRADE_TM = T.TRADE_TM,
A.TRACE_NO = T.TRACE_NO,
A.PAY_TP_CD = T.PAY_TP_CD,
A.SUB_BRAND_CD = T.SUB_BRAND_CD,
A.ITEM_CD = T.ITEM_CD,
A.MEM_NO = T.MEM_NO,
A.PAY_AMT = T.PAY_AMT,
A.APPR_AMT = T.APPR_AMT,
A.APPLY_RULE_CD = T.APPLY_RULE_CD,
A.NOR_MILEAGE = T.NOR_MILEAGE,
A.ALLI_MILEAGE = T.ALLI_MILEAGE,
A.SPEC_MILEAGE = T.SPEC_MILEAGE,
A.NOR_MILE_DEL_EX_DT = T.NOR_MILE_DEL_EX_DT,
A.ALI_MILE_DEL_EX_DT = T.ALI_MILE_DEL_EX_DT,
A.SPC_MILE_DEL_EX_DT = T.SPC_MILE_DEL_EX_DT,
A.CARD_REMAIN_MILEAGE = T.CARD_REMAIN_MILEAGE,
A.MEM_REMAIN_MILEAGE = T.MEM_REMAIN_MILEAGE,
A.TRADE_ARISE_REASON_CD = T.TRADE_ARISE_REASON_CD,
A.REG_TELEX_SALES_DT = T.REG_TELEX_SALES_DT,
A.REG_TELEX_SALES_TM = T.REG_TELEX_SALES_TM,
A.ORI_TRADE_APPR_DT = T.ORI_TRADE_APPR_DT,
A.ORI_TRADE_APPR_NO = T.ORI_TRADE_APPR_NO,
A.TRADE_ARISE_TP = T.TRADE_ARISE_TP,
A.SEARCH_YN = T.SEARCH_YN,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP


when not matched then
insert (

A.CARD_NO,
A.APPR_DT,
A.APPR_TM,
A.APPR_SEQ,
A.SEQ_NO,
A.CH_TP_CD,
A.ACC_USE_TP_CD,
A.TELEX_TP_CD,
A.TELEX_AGENCY_CD,
A.SHOP_CD,
A.TRADE_DT,
A.TRADE_TM,
A.TRACE_NO,
A.PAY_TP_CD,
A.SUB_BRAND_CD,
A.ITEM_CD,
A.MEM_NO,
A.PAY_AMT,
A.APPR_AMT,
A.APPLY_RULE_CD,
A.NOR_MILEAGE,
A.ALLI_MILEAGE,
A.SPEC_MILEAGE,
A.NOR_MILE_DEL_EX_DT,
A.ALI_MILE_DEL_EX_DT,
A.SPC_MILE_DEL_EX_DT,
A.CARD_REMAIN_MILEAGE,
A.MEM_REMAIN_MILEAGE,
A.TRADE_ARISE_REASON_CD,
A.REG_TELEX_SALES_DT,
A.REG_TELEX_SALES_TM,
A.ORI_TRADE_APPR_DT,
A.ORI_TRADE_APPR_NO,
A.TRADE_ARISE_TP,
A.SEARCH_YN,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP


)
values (

T.CARD_NO,
T.APPR_DT,
T.APPR_TM,
T.APPR_SEQ,
T.SEQ_NO,
T.CH_TP_CD,
T.ACC_USE_TP_CD,
T.TELEX_TP_CD,
T.TELEX_AGENCY_CD,
T.SHOP_CD,
T.TRADE_DT,
T.TRADE_TM,
T.TRACE_NO,
T.PAY_TP_CD,
T.SUB_BRAND_CD,
T.ITEM_CD,
T.MEM_NO,
T.PAY_AMT,
T.APPR_AMT,
T.APPLY_RULE_CD,
T.NOR_MILEAGE,
T.ALLI_MILEAGE,
T.SPEC_MILEAGE,
T.NOR_MILE_DEL_EX_DT,
T.ALI_MILE_DEL_EX_DT,
T.SPC_MILE_DEL_EX_DT,
T.CARD_REMAIN_MILEAGE,
T.MEM_REMAIN_MILEAGE,
T.TRADE_ARISE_REASON_CD,
T.REG_TELEX_SALES_DT,
T.REG_TELEX_SALES_TM,
T.ORI_TRADE_APPR_DT,
T.ORI_TRADE_APPR_NO,
T.TRADE_ARISE_TP,
T.SEARCH_YN,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MILEAGE_HIST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MILEAGE_HIST';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MILEAGE_HIST a
using (
select 
*
from no_tmp_TB_MILEAGE_HIST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.CARD_NO = T.CARD_NO AND
A.APPR_DT = T.APPR_DT AND
A.APPR_TM = T.APPR_TM AND
A.APPR_SEQ = T.APPR_SEQ


)
when matched then
update set

A.CH_TP_CD = T.CH_TP_CD,
A.ACC_USE_TP_CD = T.ACC_USE_TP_CD,
A.TELEX_TP_CD = T.TELEX_TP_CD,
A.TELEX_AGENCY_CD = T.TELEX_AGENCY_CD,
A.SHOP_CD = T.SHOP_CD,
A.TRADE_DT = T.TRADE_DT,
A.TRADE_TM = T.TRADE_TM,
A.TRACE_NO = T.TRACE_NO,
A.PAY_TP_CD = T.PAY_TP_CD,
A.ITEM_CD = T.ITEM_CD,
A.MEM_NO = T.MEM_NO,
A.PAY_AMT = T.PAY_AMT,
A.APPR_AMT = T.APPR_AMT,
A.APPLY_RULE_CD = T.APPLY_RULE_CD,
A.NOR_MILEAGE = T.NOR_MILEAGE,
A.ALLI_MILEAGE = T.ALLI_MILEAGE,
A.SPEC_MILEAGE = T.SPEC_MILEAGE,
A.NOR_MILE_DEL_EX_DT = T.NOR_MILE_DEL_EX_DT,
A.ALI_MILE_DEL_EX_DT = T.ALI_MILE_DEL_EX_DT,
A.SPC_MILE_DEL_EX_DT = T.SPC_MILE_DEL_EX_DT,
A.CARD_REMAIN_MILEAGE = T.CARD_REMAIN_MILEAGE,
A.MEM_REMAIN_MILEAGE = T.MEM_REMAIN_MILEAGE,
A.ARISE_REASON_CD = T.ARISE_REASON_CD,
A.REG_TELEX_SALES_DT = T.REG_TELEX_SALES_DT,
A.REG_TELEX_SALES_TM = T.REG_TELEX_SALES_TM,
A.ORI_TRADE_APPR_DT = T.ORI_TRADE_APPR_DT,
A.ORI_TRADE_APPR_NO = T.ORI_TRADE_APPR_NO,
A.TRADE_ARISE_TP = T.TRADE_ARISE_TP,
A.SEARCH_YN = T.SEARCH_YN,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.MOD_DTM = T.MOD_DTM,
A.MODR_ID = T.MODR_ID,
A.MOD_IP = T.MOD_IP,
A.REMARK = T.REMARK,
A.ORD_NO = T.ORD_NO,
A.REMAIN_MILEAGE = T.REMAIN_MILEAGE


when not matched then
insert (

A.CARD_NO,
A.APPR_DT,
A.APPR_TM,
A.APPR_SEQ,
A.CH_TP_CD,
A.ACC_USE_TP_CD,
A.TELEX_TP_CD,
A.TELEX_AGENCY_CD,
A.SHOP_CD,
A.TRADE_DT,
A.TRADE_TM,
A.TRACE_NO,
A.PAY_TP_CD,
A.ITEM_CD,
A.MEM_NO,
A.PAY_AMT,
A.APPR_AMT,
A.APPLY_RULE_CD,
A.NOR_MILEAGE,
A.ALLI_MILEAGE,
A.SPEC_MILEAGE,
A.NOR_MILE_DEL_EX_DT,
A.ALI_MILE_DEL_EX_DT,
A.SPC_MILE_DEL_EX_DT,
A.CARD_REMAIN_MILEAGE,
A.MEM_REMAIN_MILEAGE,
A.ARISE_REASON_CD,
A.REG_TELEX_SALES_DT,
A.REG_TELEX_SALES_TM,
A.ORI_TRADE_APPR_DT,
A.ORI_TRADE_APPR_NO,
A.TRADE_ARISE_TP,
A.SEARCH_YN,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.MOD_DTM,
A.MODR_ID,
A.MOD_IP,
A.REMARK,
A.ORD_NO,
A.REMAIN_MILEAGE


)
values (

T.CARD_NO,
T.APPR_DT,
T.APPR_TM,
T.APPR_SEQ,
T.CH_TP_CD,
T.ACC_USE_TP_CD,
T.TELEX_TP_CD,
T.TELEX_AGENCY_CD,
T.SHOP_CD,
T.TRADE_DT,
T.TRADE_TM,
T.TRACE_NO,
T.PAY_TP_CD,
T.ITEM_CD,
T.MEM_NO,
T.PAY_AMT,
T.APPR_AMT,
T.APPLY_RULE_CD,
T.NOR_MILEAGE,
T.ALLI_MILEAGE,
T.SPEC_MILEAGE,
T.NOR_MILE_DEL_EX_DT,
T.ALI_MILE_DEL_EX_DT,
T.SPC_MILE_DEL_EX_DT,
T.CARD_REMAIN_MILEAGE,
T.MEM_REMAIN_MILEAGE,
T.ARISE_REASON_CD,
T.REG_TELEX_SALES_DT,
T.REG_TELEX_SALES_TM,
T.ORI_TRADE_APPR_DT,
T.ORI_TRADE_APPR_NO,
T.TRADE_ARISE_TP,
T.SEARCH_YN,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.MOD_DTM,
T.MODR_ID,
T.MOD_IP,
T.REMARK,
T.ORD_NO,
T.REMAIN_MILEAGE

)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;


-------- TB_MILEAGE_PROC

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MILEAGE_PROC';
no_pkg_mig.log_debug('table => ' || vs_table_name);

merge into TB_MILEAGE_PROC a
using (
select 
*
from no_tmp_TB_MILEAGE_PROC
where reg_dtm >= to_date(vs_target_date, 'yyyymmdd') and  reg_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
) t
on (

A.CARD_NO = T.CARD_NO AND
A.APPR_DT = T.APPR_DT AND
A.APPR_TM = T.APPR_TM AND
A.APPR_SEQ = T.APPR_SEQ AND
A.ACC_USE_TP_CD = T.ACC_USE_TP_CD AND
A.PROC_CARD_NO = T.PROC_CARD_NO AND
A.PROC_APPR_DT = T.PROC_APPR_DT AND
A.PROC_APPR_TM = T.PROC_APPR_TM AND
A.PROC_APPR_SEQ = T.PROC_APPR_SEQ AND
A.SEQ_NO = T.SEQ_NO

)
when matched then
update set

A.PROC_MILEAGE = T.PROC_MILEAGE,
A.REG_DTM = T.REG_DTM,
A.REGR_ID = T.REGR_ID,
A.REG_IP = T.REG_IP,
A.ARISE_REASON_CD = T.ARISE_REASON_CD


when not matched then
insert (

A.CARD_NO,
A.APPR_DT,
A.APPR_TM,
A.APPR_SEQ,
A.ACC_USE_TP_CD,
A.PROC_CARD_NO,
A.PROC_APPR_DT,
A.PROC_APPR_TM,
A.PROC_APPR_SEQ,
A.SEQ_NO,
A.PROC_MILEAGE,
A.REG_DTM,
A.REGR_ID,
A.REG_IP,
A.ARISE_REASON_CD


)
values (

T.CARD_NO,
T.APPR_DT,
T.APPR_TM,
T.APPR_SEQ,
T.ACC_USE_TP_CD,
T.PROC_CARD_NO,
T.PROC_APPR_DT,
T.PROC_APPR_TM,
T.PROC_APPR_SEQ,
T.SEQ_NO,
T.PROC_MILEAGE,
T.REG_DTM,
T.REGR_ID,
T.REG_IP,
T.ARISE_REASON_CD


)
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_MILEAGE_TRANS

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_MILEAGE_TRANS';
no_pkg_mig.log_debug('table => ' || vs_table_name);

insert into TB_MILEAGE_TRANS
select 
*
from no_tmp_TB_MILEAGE_TRANS
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_ONLINE_ORDER

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_ONLINE_ORDER';
no_pkg_mig.log_debug('table => ' || vs_table_name);

insert into TB_ONLINE_ORDER
select 
*
from no_tmp_TB_ONLINE_ORDER
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_SMS_MST

vn_segment_time := DBMS_UTILITY.GET_TIME;

vs_table_name := 'TB_SMS_MST';
no_pkg_mig.log_debug('table => ' || vs_table_name);

insert into TB_SMS_MST
select 
*
from no_tmp_TB_SMS_MST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

-------- TB_TRANS_SHOP_HIST

vn_segment_time := DBMS_UTILITY.GET_TIME;


vs_table_name := 'TB_TRANS_SHOP_HIST';
no_pkg_mig.log_debug('table => ' || vs_table_name);

insert into TB_TRANS_SHOP_HIST
select 
*
from no_tmp_TB_TRANS_SHOP_HIST
where mod_dtm >= to_date(vs_target_date, 'yyyymmdd') and  mod_dtm < to_date(vs_target_date, 'yyyymmdd') + 1
;

vn_segment_time := (DBMS_UTILITY.GET_TIME - vn_segment_time) / 100;
no_pkg_mig.log_debug('merged 건수: ' || SQL%ROWCOUNT || ', 소요 시간: ' || vn_segment_time || ', table: ' || vs_table_name || chr(13));

commit;

--------

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------


    
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('SUCCESS. 총 소요 시간(s): ' || vn_total_time || chr(13));
    
exception when others then
    rollback;
    no_pkg_mig.log_error(SQLERRM);
    vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
    no_pkg_mig.log_debug('ERROR. 총 소요 시간(s): ' || vn_total_time || chr(13));
    
end;
/

----------------------------------------------------------------
