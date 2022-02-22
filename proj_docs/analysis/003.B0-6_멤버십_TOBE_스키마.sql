/*

- B0-6. 멤버십 TO-BE 스키마.
  * A. 테이블이 AS-IS.운영에 있는데 TO-BE.개발에 없다면 => 테이블을 생성하고 데이터 마이그레이션을 확인해야 한다.
      -> 2개 테이블 생성하였고, 2개 테이블은 동기화 없음.
  * B. 테이블이 TO-BE.개발에 있는데 AS-IS.운영에 없다면 => 테이블을 생성한다.
      -> @TODO 멤버십 승급, 소멸을 위해 8개 테이블 생성하고 데이터 넣어야 함. by 권주원
  * C. 칼럼이 AS-IS.운영에 있는데 TO-BE.개발에 없다면 => 개발도중에 운영에서 만들어진 것이고 칼럼을 생성한다.
      -> 개발에 2개 테이블을 재생성 했음. 마이그레이션과 상관 없는 테이블임.
  * D. 칼럼이 TO-BE.개발에 있는데 AS-IS.운영에 없다면 => 개발도중에 개발에서 만들어진 것이고 TOBE운영 에 칼럼을 생성해야 하고, AS-IS.운영 마이그레이션 시 insert table (COLUMNS) 가 필요하다.
      -> 운영에 2개 테이블에 3개 칼럼 추가함. 마이그레이션과 상관 없는 테이블임.
  * E. C의 경우라면 TOBE개발에 일단 칼럼 스키마를 추가한 다음 계속해서 마이그레이션 작업을 하면 된다.
      -> 마이그레이션 작업 필요없음.
  * F. D의 경우이고 업데이트가 필요하지 않다면 미리 칼럼을 생성해도 된다.
      -> 마이그레이션 작업 필요없음.
  * G. SEQUENCE 스키마 확인.
  
- 상세 작업 시나리오.
  1. TO-BE.개발.MEMSNX 에서 ASIS운영 VIEW 를 참조하여 대상을 구한다.

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