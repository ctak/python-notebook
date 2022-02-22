/*

- TB_SYS_USER_AUTH_SHOP_브랜드_마이그레이션
  * A. 대상 데이터 확인.
  
- 상세 작업 시나리오.
  1. TO-BE.개발.MEMSNX 에서 ASIS운영 VIEW 를 참조하여 대상을 구한다.

*/

----------------------------------------------------------------
-- 1. tb_sys_comm_cd 와 tb_sys_comm_cd_dtl 에서 찾기. 그리고 난 다음 NO_VW_BRAND_CD 만들기.
----------------------------------------------------------------
select * from tb_sys_comm_cd
 where comm_nm like '%브랜드%'
;

select * from tb_sys_comm_cd_dtl;

select b.*
  from tb_sys_comm_cd a,
       tb_sys_comm_cd_dtl b
 where a.comm_cd = b.comm_cd
   and a.comm_nm like '%브랜드%'
 order by 1,2
;

-- 결국 comm_cd: BRAND_CD 온니.
select b.*
  from tb_sys_comm_cd a,
       tb_sys_comm_cd_dtl b
 where a.comm_cd = b.comm_cd
   and a.comm_nm like '%브랜드%'
   and a.comm_cd <> 'ITEM_BRAND_CD'
   and a.comm_cd <> 'SBRAND_DIV_CD'
   and a.comm_cd <> 'BRAND_TP_CD'
 order by b.comm_cd, b.sort_no
;

-- old_cd 를 tb_sys_comm_cd_dtl.ref_1_val 에 넣는다.

update tb_sys_comm_cd_dtl set ref_1_val = 'FA140010',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '11';
update tb_sys_comm_cd_dtl set ref_1_val = 'FA140050',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '12';
update tb_sys_comm_cd_dtl set ref_1_val = 'FA140170',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '13';

update tb_sys_comm_cd_dtl set ref_1_val = 'FA140070',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '14';
update tb_sys_comm_cd_dtl set ref_1_val = 'FA140020',  mod_dtm = to_char(sysdate, 'yyyymmddhh24miss'), modr_id = 'zin' where comm_cd = 'BRAND_CD' and comm_dtl_cd = '15';
commit;

-- 이제 뷰를 만들자. NO_VW_BRAND_CD
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
-- 2. TB_SYS_USER_AUTH_SHOP 을 CTAS 로 백업하고

----------------------------------------------------------------

select * from TB_SYS_USER_AUTH_SHOP;
select distinct auth_trg_id from TB_SYS_USER_AUTH_SHOP;

-- 테이블 사이즈 조회, 개발: 2M, QC: 2M, 운영: 2M
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
-- 3. AS-IS 검증 쿼리를 돌린 후 결과를 남기고

----------------------------------------------------------------

/*
begin
    -- 이 실행은 sysdba 가 한 번 더 권한을 주어야 가능함.
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
-- 어라. 총 cnt 는 뭐지.
11	2772
12	2771
13	2771
14	2771
*/

/*
-- 운영
11	3501
FA140050	3501
FA140070	3500
FA140170	3501
*/

/*
-- 일단 개발은 이미 업데이트를 해 놓았으니 테스트 삼아서 기존으로 돌려 본다.
update TB_SYS_USER_AUTH_SHOP a
   set ( a.auth_trg_id ) = (
    select b.old_cd
      from no_vw_brand_cd b
     where b.comm_dtl_cd = '14' )
 where a.auth_trg_id = '14'
;
*/

select count(1) from TB_SYS_USER_AUTH_SHOP; -- 개발: 11085, QC: 14003, 운영: 14003
----------------------------------------------------------------
-- 4. 업데이트 하고

----------------------------------------------------------------

set serveroutput on;

declare
    -- 커서 선언
    CURSOR c1 is
    select distinct auth_trg_id
      from TB_SYS_USER_AUTH_SHOP a, no_vw_brand_cd b
     where a.auth_trg_id = b.old_cd;
      
    -- 컬렉션 타입 선언
    type BrandCdTP is table of varchar2(100);
    
    -- 변수 선언
    vst_BrandCd BrandCdTP; -- StringTable
    vs_brand_cd varchar2(100);
    
    vn_total_time number := 0;
    vs_prg_log varchar2(2000); -- 로그내용
begin
--    RAISE_APPLICATION_ERROR(-20000, '아직은 아냐!');

    vn_total_time := dbms_utility.get_time;
    
    open c1; -- OPEN 커서
    
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
    
    close c1; -- CLOSE 커서
    
    vn_total_time := (dbms_utility.get_time - vn_total_time) / 100;
    vs_prg_log := '소요 시간: ' || vn_total_time || chr(13);

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
소요 시간: .28
*/

/*
-- 운영.
brand_cd count: 3
brand_cd: FA140170
rows: 3501
brand_cd: FA140050
rows: 3501
brand_cd: FA140070
rows: 3500
소요 시간: .24
*/
----------------------------------------------------------------
-- 5. TO-BE 검증을 한다.

----------------------------------------------------------------

select auth_trg_id, count(1) as cnt
  from TB_SYS_USER_AUTH_SHOP
 where 1=1
 group by auth_trg_id
 order by auth_trg_id
;

/*
-- 운영
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

-- A 찾기
select distinct table_name from no_vw_mems_tables@dbl_sales
MINUS
select distinct table_name from user_tables
;
/*
TB_MEM_ACTION_LOG -> TOBE.운영 에 있어서 DDL 을 만들고 개발, QC 에 생성함. @okay
TB_MEM_SEARCH_LOG -> TOBE.운영 에 있어서 DDL 을 만들고 개발, QC 에 생성함. @okay
TB_ONLINE_ORDER_20210401 -> 무시. @okay
TB_ONLINE_ORDER_20210405 -> 무시. @okay
*/

-- B찾기.

select distinct table_name from user_tables 
 where table_name not like 'BK_%'
MINUS
select distinct table_name from no_vw_mems_tables@dbl_sales
;

/*

-- 이 테이블은 기존 멤버십 승급과 소멸을 위해 필요한 테이블로 운영에서 만들어지고 데이터 넣어져야 함. by 권주원k.

LEGERP_TB_CICS
ONEBN_MBR_INFO
ONEBN_ORD_CL_DLV
ONEBN_ORD_CL_DLV_LOC_GOODS
ONEBN_ORD_CL_INFO
ONEBN_ORD_CL_PAY
ONEBN_SHOP_ORDER_ADMIN
ONEBN_SHOP_ORDER_DETAIL

*/

-- C 찾기
select * from (
select table_name, column_id, column_name from no_vw_mems_columns@dbl_sales -- 총 2445개.
MINUS
select table_name, column_id, column_name from user_tab_columns
) a
 where 1=1
   and table_name <> 'TB_ONLINE_ORDER_20210401'
   and table_name <> 'TB_ONLINE_ORDER_20210405'
 order by 1,2,3
;

/*
-- TOBE운영에 있는지 체크. -> 모두 순서대로 있음. @okay
-- TOBE개발에 TB_MILEAGE_MOD_REQ_IF 는 순서가 바껴 있음. -> 순서 바꾸기.( 테이블 drop 후 재생성 ). QC까지. @okay
-- TOBE개발에 TB_MILEAGE_MOD_RES_IF -> 순서 바꾸기.( 테이블 drop 후 재생성 ). QC까지. @okay

TB_MILEAGE_MOD_REQ_IF	23	DIV_CD
TB_MILEAGE_MOD_REQ_IF	24	ORD_NO
TB_MILEAGE_MOD_RES_IF	22	CH_TP_CD
TB_MILEAGE_MOD_RES_IF	23	SHOP_CD
*/

-- D 찾기.
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
-- tb_erp_batch_log.if_msgid 는 운영에 추가해야 하겠음. 마이그레이션과 상관없음.
-- tb_prom_mst.erp_* 칼럼들은 운영에 추가해야 하겠음. 마이그레이션과 상관없음 (사람이 쓰는 조건에서). 
TB_ERP_BATCH_LOG	9	IF_MSGID
TB_PROM_MST	50	ERP_PROM_CD
TB_PROM_MST	51	ERP_OFFR_CD

----------------------------------------------------------------
-- 운영 실행 SQL

ALTER TABLE TB_ERP_BATCH_LOG ADD ( IF_MSGID VARCHAR2(30 BYTE) );

COMMENT ON COLUMN MEMSNX.TB_ERP_BATCH_LOG.IF_MSGID IS '인터페이스 처리ID';

ALTER TABLE TB_PROM_MST ADD ( ERP_PROM_CD VARCHAR2(10 BYTE) );
ALTER TABLE TB_PROM_MST ADD ( ERP_OFFR_CD VARCHAR2(20 BYTE) );

COMMENT ON COLUMN MEMSNX.TB_PROM_MST.ERP_PROM_CD IS 'ERP프로모션코드';
COMMENT ON COLUMN MEMSNX.TB_PROM_MST.ERP_OFFR_CD IS 'ERP OFFER코드';

----------------------------------------------------------------

*/