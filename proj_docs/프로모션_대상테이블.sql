-- 프로모션명 = 프로모션 OFFER 명 = OFFER RULE 명 다 같게 하는지...

-- PROM_SEQ max+1
--홍보기간  시작일자, 종료일자     , 프로모션 상태코드 ( 진행, 종료 ), 프로모션 순위, 매장적용구분코드(ALL , SEL)
-- 프로모션시작일이 현재일보다 미래거나 또는 현재일이 프로모션기간내일  경우 확정상태를 진행상태로 변경한다.
-- 최대할인금액 - 수동?
SELECT * FROM TB_SAL_PROM;

-- 프로모션제외기간 ( 정보없음 )
SELECT * FROM TB_SAL_PROM_EXCP_PERIOD;

-- 프로모션제외매장 ( 정보없음 )
SELECT * FROM TB_SAL_PROM_SHOP;

-- 매장제외기간 ( 정보없음 )
SELECT * FROM TB_SAL_PROM_SHOP_EXCP_PERIOD;

-- 프로모션 OFFER GROUP
-- 적용기준구분 = 프로모션 적용 구분 같은건지?
-- 회원대상구분코드 ?
-- TRG_ITEM_SALE_AMT_NOT_INCLS_YN  조건중복여부 ?
-- 품목구분코드 ITEM_DIV_CD 10  대상품목 품목은 무조건 대상품목인지....
--          ITEM_DIV_CD	20	제외품목
-- POS 선택 순위
SELECT * FROM TB_SAL_PROM_OFFER_GRP;

-- 프로모션 Offer Group 품목
-- TRG_ITEM_YN	VARCHAR2(1)	'Y'		대상품목여부(Y:대상품목, N:제외품목)
SELECT * FROM TB_SAL_PROM_OFFER_GRP_ITEM;

-- 프로모션 RULE
-- 수량금액구분코드 = 통화코드 ?
-- 할인금액 = 최대 할인금액 ?
-- QTY_AMT_DIV_CD	10	수량
-- QTY_AMT_DIV_CD	20	금액
SELECT * FROM TB_SAL_PROM_RULE;

-- 프로모션 혜택
SELECT * FROM TB_SAL_PROM_BNFT;

-- 프로모션 혜택 품목
SELECT * FROM TB_SAL_PROM_BNFT_ITEM;


--SELECT *
--FROM USER_SOURCE
--WHERE TEXT LIKE '%INTO TB_SAL_PROM%';

--SELECT * FROM TB_SAL_PROM_COND;
--