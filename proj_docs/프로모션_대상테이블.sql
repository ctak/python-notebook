-- ���θ�Ǹ� = ���θ�� OFFER �� = OFFER RULE �� �� ���� �ϴ���...

-- PROM_SEQ max+1
--ȫ���Ⱓ  ��������, ��������     , ���θ�� �����ڵ� ( ����, ���� ), ���θ�� ����, �������뱸���ڵ�(ALL , SEL)
-- ���θ�ǽ������� �����Ϻ��� �̷��ų� �Ǵ� �������� ���θ�ǱⰣ����  ��� Ȯ�����¸� ������·� �����Ѵ�.
-- �ִ����αݾ� - ����?
SELECT * FROM TB_SAL_PROM;

-- ���θ�����ܱⰣ ( �������� )
SELECT * FROM TB_SAL_PROM_EXCP_PERIOD;

-- ���θ�����ܸ��� ( �������� )
SELECT * FROM TB_SAL_PROM_SHOP;

-- �������ܱⰣ ( �������� )
SELECT * FROM TB_SAL_PROM_SHOP_EXCP_PERIOD;

-- ���θ�� OFFER GROUP
-- ������ر��� = ���θ�� ���� ���� ��������?
-- ȸ����󱸺��ڵ� ?
-- TRG_ITEM_SALE_AMT_NOT_INCLS_YN  �����ߺ����� ?
-- ǰ�񱸺��ڵ� ITEM_DIV_CD 10  ���ǰ�� ǰ���� ������ ���ǰ������....
--          ITEM_DIV_CD	20	����ǰ��
-- POS ���� ����
SELECT * FROM TB_SAL_PROM_OFFER_GRP;

-- ���θ�� Offer Group ǰ��
-- TRG_ITEM_YN	VARCHAR2(1)	'Y'		���ǰ�񿩺�(Y:���ǰ��, N:����ǰ��)
SELECT * FROM TB_SAL_PROM_OFFER_GRP_ITEM;

-- ���θ�� RULE
-- �����ݾױ����ڵ� = ��ȭ�ڵ� ?
-- ���αݾ� = �ִ� ���αݾ� ?
-- QTY_AMT_DIV_CD	10	����
-- QTY_AMT_DIV_CD	20	�ݾ�
SELECT * FROM TB_SAL_PROM_RULE;

-- ���θ�� ����
SELECT * FROM TB_SAL_PROM_BNFT;

-- ���θ�� ���� ǰ��
SELECT * FROM TB_SAL_PROM_BNFT_ITEM;


--SELECT *
--FROM USER_SOURCE
--WHERE TEXT LIKE '%INTO TB_SAL_PROM%';

--SELECT * FROM TB_SAL_PROM_COND;
--