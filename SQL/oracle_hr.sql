select * from user_tables;

select * from jobs;

-- ��� ���̺� ������ [FORGE] ���� �ֱ�.

GRANT SELECT ANY TABLE TO FORGE; -- ���⼭ �������� ��������.
-- �׷��� system �������� GRANT CONNECT, DBA, RESOURCE TO hr; �� DBA ������ �ش��� �ٽ� ���� ����� �����ϴ� forge ���� select �� �Ǿ���.

GRANT ALL ANY TABLE TO FORGE; -- �̰� �ȵ�.

grant select, insert, update, delete, alter, index, references any table to forge; -- �� ��ɵ� �ѹ��� �ȵ�.

grant insert any table to forge;
grant update any table to forge;
grant delete any table to forge;