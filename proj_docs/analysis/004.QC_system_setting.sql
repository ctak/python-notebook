-- TO-BE 운영에서 QC 로 데이터를 넣는다.
-- QC 는 운영과 맞추는 게 원칙.

set serveroutput on;
-- 1 user
begin
    NO_PKG_MIG.COPY_TABLE_2 ('tb_sys_user', 'tb_sys_user@syn_sales');
end;
/

-- 2 user-passwd
begin
    NO_PKG_MIG.COPY_TABLE_2 ('tb_sys_user_passwd', 'tb_sys_user_passwd@syn_sales');
end;
/

select * from tb_sys_user;

-- 3. TB_SYS_% 복사
-- LOG 는 무시.
-- COMM_CD 는 개발에서.
-- 다른 것은 운영에서.
-- 개발에 추가된 것은 업데이트 해야 함.

-- 개발에서 exa_asm 으로 데이터를 뽑음.
select a.table_name, a.tablespace_name, a.status, a.num_rows, -- num_rows, blocks, last_analyzed 는 통계정보가 만들어진 다음에 값이 만들어짐.
    a.blocks, -- 테이블에서 사용된 블록 수 (블록은 오라클에서 데이터의 최소 저장단위임)
    a.last_analyzed,
    b.comments
  from all_tables@exa_asm a,
    all_tab_comments@exa_asm b
 where a.owner = b.owner
   and a.table_name = b.table_name
   and a.owner = 'ASM'
   and a.table_name not like 'BK_%'
   and a.table_name not like 'TMP_%'
   and a.table_name not like 'MIG_%'
   and a.table_name not like 'TB_CARD_MILEAGE_2%'
   and a.table_name not like 'TB_MEM_GRADE_2%'
   and a.table_name like 'TB_SYS%'
 order by a.table_name;
 
 /*
 -- 운영에서 우선 가져올 것임
 TB_SYS_AUGP
TB_SYS_AUGP_MENU
TB_SYS_AUGP_MENU_FN
TB_SYS_BOOK_MENU
TB_SYS_CAL
TB_SYS_CARD_PREFIX
TB_SYS_CONFIG
TB_SYS_DEPT
TB_SYS_DOMAIN
TB_SYS_DOMAIN_LANG
TB_SYS_INTR_NETWORK
TB_SYS_MENU
TB_SYS_MENU_CLS
TB_SYS_MENU_FN
TB_SYS_MODULE
TB_SYS_MSG
TB_SYS_PROG
TB_SYS_PROG_FN
TB_SYS_USER_AUGP
TB_SYS_USER_AUGP_HIST
TB_SYS_USER_AUTH_SHOP
TB_SYS_USER_MENU
TB_SYS_USER_MENU_FN
*/

select count(1) from TB_SYS_AUGP_MENU@leg_asm;

insert into TB_SYS_AUGP_MENU values(AUGP_CD, MENU_CD, REMARK, USE_YN, REG_DTM, REGR_ID, MOD_DTM, MODR_ID)
select AUGP_CD, MENU_CD, REMARK, USE_YN, REG_DTM, REGR_ID, MOD_DTM, MODR_ID from TB_SYS_AUGP_MENU@LEG_ASM where use_yn is not null;

truncate table TB_SYS_AUGP_MENU;

select * from tb_sys_augp_menu;


select * from TB_SYS_USER_AUGP@leg_asm
where use_yn not in ('Y', 'N')
;

begin

--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_AUGP@LEG_ASM', 'TB_SYS_AUGP');
NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_AUGP_MENU@LEG_ASM', 'TB_SYS_AUGP_MENU');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_AUGP_MENU_FN@LEG_ASM', 'TB_SYS_AUGP_MENU_FN');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_BOOK_MENU@LEG_ASM', 'TB_SYS_BOOK_MENU');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_CAL@LEG_ASM', 'TB_SYS_CAL');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_CARD_PREFIX@LEG_ASM', 'TB_SYS_CARD_PREFIX');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_CONFIG@LEG_ASM', 'TB_SYS_CONFIG');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_DEPT@LEG_ASM', 'TB_SYS_DEPT');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_DOMAIN@LEG_ASM', 'TB_SYS_DOMAIN');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_DOMAIN_LANG@LEG_ASM', 'TB_SYS_DOMAIN_LANG');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_INTR_NETWORK@LEG_ASM', 'TB_SYS_INTR_NETWORK');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_MENU@LEG_ASM', 'TB_SYS_MENU');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_MENU_CLS@LEG_ASM', 'TB_SYS_MENU_CLS');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_MENU_FN@LEG_ASM', 'TB_SYS_MENU_FN');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_MODULE@LEG_ASM', 'TB_SYS_MODULE');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_MSG@LEG_ASM', 'TB_SYS_MSG');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_PROG@LEG_ASM', 'TB_SYS_PROG');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_PROG_FN@LEG_ASM', 'TB_SYS_PROG_FN');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_USER_AUGP@LEG_ASM', 'TB_SYS_USER_AUGP');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_USER_AUGP_HIST@LEG_ASM', 'TB_SYS_USER_AUGP_HIST');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_USER_AUTH_SHOP@LEG_ASM', 'TB_SYS_USER_AUTH_SHOP');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_USER_MENU@LEG_ASM', 'TB_SYS_USER_MENU');
--NO_PKG_MIG.COPY_TABLE_2 ('ASM.TB_SYS_USER_MENU_FN@LEG_ASM', 'TB_SYS_USER_MENU_FN');

/*
vs_params: ps_from_table_name => ASM.TB_SYS_AUGP@LEG_ASM, ps_to_table_name => TB_SYS_AUGP
vs_params: ps_from_table_name => ASM.TB_SYS_AUGP_MENU@LEG_ASM, ps_to_table_name => TB_SYS_AUGP_MENU
ORA-01400: NULL을 ("ASMNX"."TB_SYS_AUGP_MENU"."USE_YN") 안에 삽입할 수 없습니다
vs_params: ps_from_table_name => ASM.TB_SYS_AUGP_MENU_FN@LEG_ASM, ps_to_table_name => TB_SYS_AUGP_MENU_FN
vs_params: ps_from_table_name => ASM.TB_SYS_BOOK_MENU@LEG_ASM, ps_to_table_name => TB_SYS_BOOK_MENU
vs_params: ps_from_table_name => ASM.TB_SYS_CAL@LEG_ASM, ps_to_table_name => TB_SYS_CAL
vs_params: ps_from_table_name => ASM.TB_SYS_CARD_PREFIX@LEG_ASM, ps_to_table_name => TB_SYS_CARD_PREFIX
ORA-12899: "ASMNX"."TB_SYS_CARD_PREFIX"."USE_YN" 열에 대한 값이 너무 큼(실제: 14, 최대값: 4)
vs_params: ps_from_table_name => ASM.TB_SYS_CONFIG@LEG_ASM, ps_to_table_name => TB_SYS_CONFIG
vs_params: ps_from_table_name => ASM.TB_SYS_DEPT@LEG_ASM, ps_to_table_name => TB_SYS_DEPT
ORA-00001: 무결성 제약 조건(ASMNX.PK_TB_SYS_DEPT)에 위배됩니다
vs_params: ps_from_table_name => ASM.TB_SYS_DOMAIN@LEG_ASM, ps_to_table_name => TB_SYS_DOMAIN
vs_params: ps_from_table_name => ASM.TB_SYS_DOMAIN_LANG@LEG_ASM, ps_to_table_name => TB_SYS_DOMAIN_LANG
vs_params: ps_from_table_name => ASM.TB_SYS_INTR_NETWORK@LEG_ASM, ps_to_table_name => TB_SYS_INTR_NETWORK
vs_params: ps_from_table_name => ASM.TB_SYS_MENU@LEG_ASM, ps_to_table_name => TB_SYS_MENU
vs_params: ps_from_table_name => ASM.TB_SYS_MENU_CLS@LEG_ASM, ps_to_table_name => TB_SYS_MENU_CLS
vs_params: ps_from_table_name => ASM.TB_SYS_MENU_FN@LEG_ASM, ps_to_table_name => TB_SYS_MENU_FN
vs_params: ps_from_table_name => ASM.TB_SYS_MODULE@LEG_ASM, ps_to_table_name => TB_SYS_MODULE
vs_params: ps_from_table_name => ASM.TB_SYS_MSG@LEG_ASM, ps_to_table_name => TB_SYS_MSG
vs_params: ps_from_table_name => ASM.TB_SYS_PROG@LEG_ASM, ps_to_table_name => TB_SYS_PROG
vs_params: ps_from_table_name => ASM.TB_SYS_PROG_FN@LEG_ASM, ps_to_table_name => TB_SYS_PROG_FN
vs_params: ps_from_table_name => ASM.TB_SYS_USER_AUGP@LEG_ASM, ps_to_table_name => TB_SYS_USER_AUGP
ORA-12899: "ASMNX"."TB_SYS_USER_AUGP"."USE_YN" 열에 대한 값이 너무 큼(실제: 14, 최대값: 1)
vs_params: ps_from_table_name => ASM.TB_SYS_USER_AUGP_HIST@LEG_ASM, ps_to_table_name => TB_SYS_USER_AUGP_HIST
ORA-00942: 테이블 또는 뷰가 존재하지 않습니다
vs_params: ps_from_table_name => ASM.TB_SYS_USER_AUTH_SHOP@LEG_ASM, ps_to_table_name => TB_SYS_USER_AUTH_SHOP
vs_params: ps_from_table_name => ASM.TB_SYS_USER_MENU@LEG_ASM, ps_to_table_name => TB_SYS_USER_MENU
vs_params: ps_from_table_name => ASM.TB_SYS_USER_MENU_FN@LEG_ASM, ps_to_table_name => TB_SYS_USER_MENU_FN
*/

end;
/

insert into TB_SYS_CARD_PREFIX
select CARD_PREFIX_CD, CARD_NM, CARDCO_CD, BANK_CD, MAX_INSMT_MM_CNT, COUP_APPLY_YN, USE_YN, REG_DTM, REGR_ID, MOD_DTM, MODR_ID
from ASM.TB_SYS_CARD_PREFIX@LEG_ASM;

insert into tb_sys_user_augp
select USER_ID, AUGP_CD, APPLY_STT_DT, APPLY_END_DT, REMARK, E_REQ_NO, USE_YN, REG_DTM, REGR_ID, MOD_DTM, MODR_ID
from ASM.TB_SYS_USER_AUGP@LEG_ASM;

-- !!!! comm_cd_dtl 을 넣다가 TB_IFM_COMM_CD_DIST_LOG. 칼럼 조정이 필요했음.
-- 운영에서, QC에서.
alter table tb_ifm_comm_cd_dist_log modify(comm_cd varchar2(30));
alter table tb_ifm_comm_cd_dist_log modify(comm_dtl_cd varchar2(30));

-- 이제 QC 에 붓기.

select * from TB_SYS_AUGP@syn_sales;

begin
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_AUGP', 'TB_SYS_AUGP@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_AUGP_MENU', 'TB_SYS_AUGP_MENU@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_AUGP_MENU_FN', 'TB_SYS_AUGP_MENU_FN@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_BOOK_MENU', 'TB_SYS_BOOK_MENU@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_CAL', 'TB_SYS_CAL@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_CARD_PREFIX', 'TB_SYS_CARD_PREFIX@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_CONFIG', 'TB_SYS_CONFIG@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_DEPT', 'TB_SYS_DEPT@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_DOMAIN', 'TB_SYS_DOMAIN@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_DOMAIN_LANG', 'TB_SYS_DOMAIN_LANG@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_INTR_NETWORK', 'TB_SYS_INTR_NETWORK@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MENU', 'TB_SYS_MENU@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MENU_CLS', 'TB_SYS_MENU_CLS@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MENU_FN', 'TB_SYS_MENU_FN@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MODULE', 'TB_SYS_MODULE@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MSG', 'TB_SYS_MSG@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_PROG', 'TB_SYS_PROG@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_PROG_FN', 'TB_SYS_PROG_FN@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_AUGP', 'TB_SYS_USER_AUGP@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_AUGP_HIST', 'TB_SYS_USER_AUGP_HIST@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_AUTH_SHOP', 'TB_SYS_USER_AUTH_SHOP@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_MENU', 'TB_SYS_USER_MENU@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_MENU_FN', 'TB_SYS_USER_MENU_FN@syn_sales');
end;
/

begin
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_AUGP', 'TB_SYS_AUGP@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_AUGP_MENU', 'TB_SYS_AUGP_MENU@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_AUGP_MENU_FN', 'TB_SYS_AUGP_MENU_FN@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_BOOK_MENU', 'TB_SYS_BOOK_MENU@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_CAL', 'TB_SYS_CAL@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_CARD_PREFIX', 'TB_SYS_CARD_PREFIX@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_CONFIG', 'TB_SYS_CONFIG@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_DEPT', 'TB_SYS_DEPT@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_DOMAIN', 'TB_SYS_DOMAIN@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_DOMAIN_LANG', 'TB_SYS_DOMAIN_LANG@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_INTR_NETWORK', 'TB_SYS_INTR_NETWORK@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MENU', 'TB_SYS_MENU@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MENU_CLS', 'TB_SYS_MENU_CLS@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MENU_FN', 'TB_SYS_MENU_FN@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MODULE', 'TB_SYS_MODULE@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_MSG', 'TB_SYS_MSG@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_PROG', 'TB_SYS_PROG@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_PROG_FN', 'TB_SYS_PROG_FN@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_AUGP', 'TB_SYS_USER_AUGP@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_AUGP_HIST', 'TB_SYS_USER_AUGP_HIST@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_AUTH_SHOP', 'TB_SYS_USER_AUTH_SHOP@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_MENU', 'TB_SYS_USER_MENU@syn_sales');
NO_PKG_MIG.COPY_TABLE_2 ('TB_SYS_USER_MENU_FN', 'TB_SYS_USER_MENU_FN@syn_sales');
end;
/

select * from tb_sys_comm_cd;
select * from tb_sys_comm_cd_dtl;

select * from tb_bas_shop where shop_nm like '%종로%';
begin
NO_PKG_MIG.COPY_TABLE_2 ('tb_sys_comm_cd@syn_sales', 'tb_sys_comm_cd');
NO_PKG_MIG.COPY_TABLE_2 ('tb_sys_comm_cd_dtl@syn_sales', 'tb_sys_comm_cd_dtl');
end;
/

select * from tb_bas_shop;

--update tb_bas_shop set mng_dept_cd = '000394'
--where shop_cd = '700163';

select * from tb_sys_user_auth_shop -- 여기에 브랜드가 맞아야 함.
;

-- 700305, 700163
select * from tb_bas_shop
where shop_nm like '%대구서남점%';
select * from tb_sys_dept where dept_nm like '%종로%';

-- 이 부분이 WAS 의 Exception 을 확인하는 것임.
select * from tb_sys_excp_log;