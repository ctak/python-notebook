/*

- -
----------------------------------------------------------------

/*

4개매장

 미샤 교육      [ 직영, 가맹]  8000001,8000011
 눙크 교육      [ 직영 ]         8000002
 웅녀신전 교육[ 직영 ]         8000003
 어퓨 교육      [ 직영 ]         8000004
*/

select * from tb_bas_shop@exa_asm where mng_dept_cd = '000394';

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
   and a.owner = 'ASMNX'
   and a.table_name = 'TB_BAS_SHOP'
--   and a.column_name like '%SHOP_CD' -- 70개
 order by a.table_name, a.column_id
;


-- 가져올 테이블 조회
select
SHOP_CD,
SHOP_NM,
VENDOR_CD,
BRAND_CD,
'10' CHAIN_LCLS_CD,
CHAIN_MCLS_CD,
POSI_LCLS_CD,
AREA_LCLS_CD,
'' DELV_GRP_CD,
CRM_CMMRC_TP_CD,
MNG_EMP_NO,
REGS_NO,
BOSS_NM,
CORP_NO,
INDUSTRY_NM,
SECTOR_NM,
TEL_NO,
MOBILE_NO,
ZIP_NO,
ADDR,
DTL_ADDR,
OPEN_DT,
CLOSE_DT,
MART_CD,
LAST_SHOP_CD,
CDIV_CD,
DSTBSHOPTYPE_CD,
USE_YN,
MNG_DEPT_CD,
SHOP_STAT_CD,
'20' SHOP_TYPE,
'' CONS_TYPE,
'' SETTLE_TP_CD,
null DELV_TO_CD,
'' OLD_SHOP_CD,
TERM_ID,
CASH_MILG_ACC_RATE,
SPRM_MILG_ACC_RATE,
'10' ORD_UNIT_CD,
'' TAX_POS_YN,
REG_DTM,
REGR_ID,
MOD_DTM,
MODR_ID
from tb_bas_shop@leg_asm
where mng_dept_cd = '000394'
;

select shop_cd, shop_nm
, ord_unit_cd -- 20
, DELV_GRP_CD -- 17
, DELV_TO_CD -- null
, SETTLE_TP_CD -- 21
, CONS_TYPE -- 15
--, SHOP_TYPE -- 20
--, chain_lcls_cd -- 10
, chain_mcls_cd -- 12
from tb_bas_shop
where shop_cd = '700454'
;

update no_tmp_tb_bas_shop set ord_unit_cd = '20', DELV_GRP_CD = '17', delv_to_cd = null, settle_tp_cd = '21', cons_type = '15', chain_mcls_cd = '12' where shop_cd = '9903';

select shop_cd, shop_nm
, ord_unit_cd -- 10
, DELV_GRP_CD -- null
, DELV_TO_CD -- null
, SETTLE_TP_CD -- 11
, CONS_TYPE -- 13
--, SHOP_TYPE -- 20
--, chain_lcls_cd -- 10
, chain_mcls_cd -- 11
from tb_bas_shop 
where shop_cd = '700011'
;

update no_tmp_tb_bas_shop set ord_unit_cd = '10', DELV_GRP_CD = null, delv_to_cd = null, settle_tp_cd = '11', cons_type = '13', chain_mcls_cd = '11' where shop_cd = '직영점';

----------------------------------------------------------------
-- tmp 테이블 생성.
----------------------------------------------------------------
create table no_tmp_tb_bas_shop as select * from tb_bas_shop where 1=2;

select * from no_tmp_tb_bas_shop;

select * from tb_bas_shop
where mng_dept_cd = '000394';

delete no_tmp_tb_bas_shop where shop_cd = '9901';

/*
insert into no_tmp_tb_bas_shop
select
SHOP_CD,
SHOP_NM,
VENDOR_CD,
BRAND_CD,
'10' CHAIN_LCLS_CD,
CHAIN_MCLS_CD,
POSI_LCLS_CD,
AREA_LCLS_CD,
'' DELV_GRP_CD,
CRM_CMMRC_TP_CD,
MNG_EMP_NO,
REGS_NO,
BOSS_NM,
CORP_NO,
INDUSTRY_NM,
SECTOR_NM,
TEL_NO,
MOBILE_NO,
ZIP_NO,
ADDR,
DTL_ADDR,
OPEN_DT,
CLOSE_DT,
MART_CD,
LAST_SHOP_CD,
CDIV_CD,
DSTBSHOPTYPE_CD,
USE_YN,
MNG_DEPT_CD,
SHOP_STAT_CD,
'20' SHOP_TYPE,
'' CONS_TYPE,
'' SETTLE_TP_CD,
null DELV_TO_CD,
'' OLD_SHOP_CD,
TERM_ID,
CASH_MILG_ACC_RATE,
SPRM_MILG_ACC_RATE,
'10' ORD_UNIT_CD,
'' TAX_POS_YN,
REG_DTM,
REGR_ID,
MOD_DTM,
MODR_ID
from tb_bas_shop@leg_asm
where mng_dept_cd = '000394'
;
*/

-- tb_bas_shop 에 밀어넣기.
insert into tb_bas_shop
select * from no_tmp_tb_bas_shop;


-- 마지막으로 재고 밀어 넣기.

select * from tb_inv_mmio where shop_cd = '700011' and io_ym = '202104';

create table no_tmp_tb_inv_mmio as
select * from no_tmp_tb_inv_mmio@syn_sales;

-- 최종.
insert into tb_inv_mmio select * from no_tmp_tb_inv_mmio;

select count(1) from tb_inv_mmio; -- 139949

select distinct shop_cd from tb_inv_mmio;
/*
800002
800011
800004
800003
800001
*/


select
IO_YM, '800011' SHOP_CD,ITEM_CD,BAS_STOCK_QTY,BAD_BAS_STOCK_QTY,ORD_IN_QTY,ORD_RTN_QTY,BAD_RTN_QTY,MV_OUT_QTY,MV_IN_QTY,CUST_SALE_QTY,CUST_RTN_QTY,BAD_CUST_RTN_QTY,PROM_PRESENT_QTY,NON_SALES_PRESENT_QTY,NON_SALES_DONATE_QTY,NON_SALES_TESTER_QTY,NON_SALES_ETC_OUT_QTY,STOCK_DIFF_IN_QTY,STOCK_DIFF_OUT_QTY,BAD_STOCK_DIFF_IN_QTY,BAD_STOCK_DIFF_OUT_QTY,NOR_ADJ_IN_QTY,NOR_ADJ_OUT_QTY,BAD_ADJ_IN_QTY,BAD_ADJ_OUT_QTY,FINAL_STOCK_QTY,BAD_FINAL_STOCK_QTY,ERP_IN_QTY,ERP_OUT_QTY,REG_DTM,REGR_ID,MOD_DTM,MODR_ID
from tb_inv_mmio where shop_cd = '700454' and io_ym = '202104';

