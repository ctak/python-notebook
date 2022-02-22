select * from user_tables;

select * from jobs;

-- 모든 테이블 권한을 [FORGE] 에게 주기.

GRANT SELECT ANY TABLE TO FORGE; -- 여기서 권한으로 막혀버림.
-- 그래서 system 유저에서 GRANT CONNECT, DBA, RESOURCE TO hr; 로 DBA 권한을 준다음 다시 위의 명령을 실행하니 forge 에서 select 가 되었음.

GRANT ALL ANY TABLE TO FORGE; -- 이건 안됨.

grant select, insert, update, delete, alter, index, references any table to forge; -- 이 명령도 한번에 안됨.

grant insert any table to forge;
grant update any table to forge;
grant delete any table to forge;