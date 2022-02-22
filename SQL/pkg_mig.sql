set serveroutput on;

/*
--
-- ���̱׷��̼��� ���� �α� ���̺��� �����.
-- 

CREATE TABLE BK_PROGRAM_LOG
(
    LOG_ID NUMBER, -- �α׾��̵�
    PROGRAM_NAME VARCHAR2(100), -- ���α׷���
    PARAMETERS VARCHAR2(500), -- ���α׷��Ű�����
    STATE VARCHAR2(10), -- ����( 'RUNNING', 'COMPLETED', 'ERROR' )
    START_TIME TIMESTAMP, -- ���۽ð�
    END_TIME TIMESTAMP, -- ����ð�
    LOG_DESC VARCHAR2(3000) -- �α׳���
);

CREATE SEQUENCE NO_PRG_LOG_SEQ
INCREMENT BY 1
START WITH 1
MINVALUE 1
MAXVALUE 10000000
NOCYCLE
NOCACHE;

CREATE TABLE BK_DUMMY_LOG
(
    LOG_ID NUMBER, -- �α׾��̵�
    PROGRAM_NAME VARCHAR2(100), -- ���α׷���
    LOG_TIME TIMESTAMP, -- �α׽ð�
    LOG_LEVEL VARCHAR2(10), -- �α׷���('D', 'E' ) Debug, Error
    LOG_DESC VARCHAR2(3000) -- �α׳���
);

CREATE SEQUENCE NO_DUMMY_LOG_SEQ
INCREMENT BY 1
START WITH 1;

*/

create or replace package no_pkg_mig is
    vs_pkg_name varchar2(30) := 'NO_PKG_MIG';
    
    ----------------------------------------------------------------
    -- log ����
    
    procedure prg_start (
        pn_log_id IN number,
        ps_prg_name IN bk_program_log.program_name%type,
        ps_params IN bk_program_log.parameters%type default ''
    );
    
    procedure prg_end (
        pn_log_id IN number,
        ps_log_desc IN bk_program_log.log_desc%type default ''
    );
    
    procedure prg_error (
        pn_log_id IN number,
        ps_log_desc IN bk_program_log.log_desc%type default ''
    );
    
    /*
        no_pkg_mig.log_debug('hello');
        no_pkg_mig.log_debug('world', 'my program');
        no_pkg_mig.log_error('good');
        no_pkg_mig.log_error('bye', 'my program');
    */
    procedure log_debug (
        ps_log IN varchar2,
        ps_prg_name IN bk_dummy_log.program_name%type default ''
    );
    
    procedure log_error (
        ps_log IN varchar2,
        ps_prg_name IN bk_dummy_log.program_name%type default ''
    );
    
    ----------------------------------------------------------------
    
    -- LEGERP �� ONEBN �� ���� �ӵ� �׽�Ʈ.
    procedure copy_table (
        ps_from_table_name IN varchar2,
        ps_to_table_name IN varchar2
    );
    
    -- INSERT /*+ APPEND */ ���� SELECT ����
    procedure copy_table_2 (
        ps_from_table_name IN varchar2,
        ps_to_table_name IN varchar2
    );
    
    -- PARALLEL DML
    -- ���߿����� 4core �̰� APPEND �� ���� �� ���� ����.
    procedure copy_table_3 (
        ps_from_table_name IN varchar2,
        ps_to_table_name IN varchar2
    );
    
    ----------------------------------------------------------------
    -- CTAS
    procedure ctas_table (
        ps_from_table_name IN varchar2,
        ps_to_table_name IN varchar2
    );

end no_pkg_mig;
/

create or replace package body no_pkg_mig is

    ----------------------------------------------------------------
    -- log ����

    procedure prg_start (
        pn_log_id IN number,
        ps_prg_name IN bk_program_log.program_name%type,
        ps_params IN bk_program_log.parameters%type default ''
    )
    IS
    begin
        INSERT INTO bk_program_log (
            log_id,
            program_name,
            parameters,
            state,
            start_time )
        values (
            pn_log_id,
            ps_prg_name,
            ps_params,
            'Running',
            systimestamp );
            
        commit;
    end prg_start;
    
    procedure prg_end (
        pn_log_id IN number,
        ps_log_desc IN bk_program_log.log_desc%type default ''
    )
    IS
    begin
        UPDATE bk_program_log
           set state = 'Completed',
           end_time = systimestamp,
           log_desc = ps_log_desc || '�۾�����!'
         where log_id = pn_log_id;

        commit;
    end prg_end;
    
    procedure prg_error (
        pn_log_id IN number,
        ps_log_desc IN bk_program_log.log_desc%type default ''
    )
    IS
    begin
        UPDATE bk_program_log
           set state = 'Error',
           end_time = systimestamp,
           log_desc = ps_log_desc
         where log_id = pn_log_id;

        commit;
    end prg_error;
    
    procedure log_debug (
        ps_log IN varchar2,
        ps_prg_name IN bk_dummy_log.program_name%type default ''
    )
    IS
    begin
        INSERT INTO bk_dummy_log (
            log_id,
            program_name,
            log_time,
            log_level,
            log_desc
        )
        values (
            NO_DUMMY_LOG_SEQ.nextval,
            ps_prg_name,
            systimestamp,
            'D',
            ps_log
        );
        
        commit;
    end log_debug;
    
    procedure log_error (
        ps_log IN varchar2,
        ps_prg_name IN bk_dummy_log.program_name%type default ''
    )
    IS
    begin
        INSERT INTO bk_dummy_log (
            log_id,
            program_name,
            log_time,
            log_level,
            log_desc
        )
        values (
            NO_DUMMY_LOG_SEQ.nextval,
            ps_prg_name,
            systimestamp,
            'E',
            ps_log
        );
        
        commit;
    end log_error;
    
    ----------------------------------------------------------------
    
    procedure copy_table (
        ps_from_table_name IN varchar2,
        ps_to_table_name IN varchar2
    )
    is
        vs_prg_name varchar2(100) := 'copy_table';
        vn_log_id number; -- �α׾��̵�
        vs_params varchar2(500); -- �Ű�����
        vs_prg_log varchar2(2000); -- �α׳���
        vn_total_time number := 0; -- �ҿ�ð� ���� ����
        
        vs_query varchar2(2000);
    begin
--        set autocommit off;
        
        -- �Ű������� �� ���� �����´�.
        vs_params := 'ps_from_table_name => ' || ps_from_table_name || ', ps_to_table_name => ' || ps_to_table_name;
        dbms_output.put_line('vs_params: ' || vs_params);
        
        -- �α� ���̵� �� ����
        vn_log_id := no_prg_log_seq.NEXTVAL;
        begin
            no_pkg_mig.prg_start(
                vn_log_id,
                vs_prg_name,
                vs_params);
        end;
        
        -- ���� �ð�.
        vn_total_time := DBMS_UTILITY.GET_TIME;
        
        -- ���� ����.
        vs_query :=             'INSERT ' || chr(13); -- ��Ʈ�� �ֱ� ���Ͽ�
        vs_query := vs_query || ' INTO ' || ps_to_table_name || chr(13);
        vs_query := vs_query || ' select * from ' || ps_from_table_name || chr(13);
        
        EXECUTE IMMEDIATE vs_query;

        -- �ҿ� �ð�
        vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
        vs_prg_log := 'INSERT �Ǽ�: ' || SQL%ROWCOUNT || ', �ҿ� �ð�: ' || vn_total_time || chr(13);
        
        commit;
        
        begin
            no_pkg_mig.prg_end(
                vn_log_id,
                vs_prg_log);
        end;
        
        
    exception when others then
        rollback;
        dbms_output.put_line(SQLERRM);
        
        begin
            vs_prg_log := SQLERRM;
            no_pkg_mig.prg_error(
                vn_log_id,
                vs_prg_log);
        end;
        
    end copy_table;
    
    procedure copy_table_2 (
        ps_from_table_name IN varchar2,
        ps_to_table_name IN varchar2
    )
    is
        vs_prg_name varchar2(100) := 'copy_table_2';
        vn_log_id number; -- �α׾��̵�
        vs_params varchar2(500); -- �Ű�����
        vs_prg_log varchar2(2000); -- �α׳���
        vn_total_time number := 0; -- �ҿ�ð� ���� ����
        
        vs_query varchar2(2000);
    begin
--        set autocommit off;
        
        -- �Ű������� �� ���� �����´�.
        vs_params := 'ps_from_table_name => ' || ps_from_table_name || ', ps_to_table_name => ' || ps_to_table_name;
        dbms_output.put_line('vs_params: ' || vs_params);
        
        -- �α� ���̵� �� ����
        vn_log_id := no_prg_log_seq.NEXTVAL;
        begin
            no_pkg_mig.prg_start(
                vn_log_id,
                vs_prg_name,
                vs_params);
        end;
        
        -- ���� �ð�.
        vn_total_time := DBMS_UTILITY.GET_TIME;
        
        -- ���� ����.
        vs_query :=             'INSERT /*+ APPEND */ ' || chr(13); -- ��Ʈ�� �ֱ� ���Ͽ�
        vs_query := vs_query || ' INTO ' || ps_to_table_name || chr(13);
        vs_query := vs_query || ' select * from ' || ps_from_table_name || chr(13);
        
        EXECUTE IMMEDIATE vs_query;

        -- �ҿ� �ð�
        vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
        vs_prg_log := 'INSERT �Ǽ�: ' || SQL%ROWCOUNT || ', �ҿ� �ð�: ' || vn_total_time || chr(13);
        
        commit;
        
        begin
            no_pkg_mig.prg_end(
                vn_log_id,
                vs_prg_log);
        end;
        
        
    exception when others then
        rollback;
        dbms_output.put_line(SQLERRM);
        
        begin
            vs_prg_log := SQLERRM;
            no_pkg_mig.prg_error(
                vn_log_id,
                vs_prg_log);
        end;
        
    end copy_table_2;
    
    -- parallel
    procedure copy_table_3 (
        ps_from_table_name IN varchar2,
        ps_to_table_name IN varchar2
    )
    is
        vs_prg_name varchar2(100) := 'copy_table_3';
        vn_log_id number; -- �α׾��̵�
        vs_params varchar2(500); -- �Ű�����
        vs_prg_log varchar2(2000); -- �α׳���
        vn_total_time number := 0; -- �ҿ�ð� ���� ����
        
        vs_query varchar2(2000);
    begin
--        set autocommit off;
        
        
        -- �Ű������� �� ���� �����´�.
        vs_params := 'ps_from_table_name => ' || ps_from_table_name || ', ps_to_table_name => ' || ps_to_table_name;
        dbms_output.put_line('vs_params: ' || vs_params);
        
        -- �α� ���̵� �� ����
        vn_log_id := no_prg_log_seq.NEXTVAL;
        begin
            no_pkg_mig.prg_start(
                vn_log_id,
                vs_prg_name,
                vs_params);
        end;
        
        -- ���� �ð�.
        vn_total_time := DBMS_UTILITY.GET_TIME;
        
        -- ���� ����.
--        vs_query :=             'INSERT /*+ APPEND */ ' || chr(13); -- ��Ʈ�� �ֱ� ���Ͽ�
        vs_query :=             'INSERT ' || chr(13); -- ��Ʈ�� �ֱ� ���Ͽ�
        vs_query := vs_query || ' INTO ' || ps_to_table_name || chr(13);
        vs_query := vs_query || ' select * from ' || ps_from_table_name || chr(13);
        
        -- -- 1500�� ��. APPEND hint( 4core => 74��. 8core => 81��. 2core => 46��. )
        EXECUTE IMMEDIATE 'ALTER SESSION FORCE PARALLEL DML PARALLEL 4';
        EXECUTE IMMEDIATE 'ALTER SESSION FORCE PARALLEL QUERY PARALLEL 4';
        
        EXECUTE IMMEDIATE vs_query;
        commit;
        
        EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';

        -- �ҿ� �ð�
        vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
        vs_prg_log := 'INSERT �Ǽ�: ' || SQL%ROWCOUNT || ', �ҿ� �ð�: ' || vn_total_time || chr(13);
        
        commit;
        
        begin
            no_pkg_mig.prg_end(
                vn_log_id,
                vs_prg_log);
        end;
        
        
        
    exception when others then
        rollback;
        dbms_output.put_line(SQLERRM);
        
        EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
        
        begin
            vs_prg_log := SQLERRM;
            no_pkg_mig.prg_error(
                vn_log_id,
                vs_prg_log);
        end;
        
    end copy_table_3;
    
    ----------------------------------------------------------------
    -- CTAS
    procedure ctas_table (
        ps_from_table_name IN varchar2,
        ps_to_table_name IN varchar2
    )
    is
        vs_prg_name varchar2(100) := 'ctas_table';
        vn_log_id number; -- �α׾��̵�
        vs_params varchar2(500); -- �Ű�����
        vs_prg_log varchar2(2000); -- �α׳���
        vn_total_time number := 0; -- �ҿ�ð� ���� ����
        
        vs_query varchar2(2000);
    begin
--        set autocommit off;
        
        -- �Ű������� �� ���� �����´�.
        vs_params := 'ps_from_table_name => ' || ps_from_table_name || ', ps_to_table_name => ' || ps_to_table_name;
        dbms_output.put_line('vs_params: ' || vs_params);
        
        -- �α� ���̵� �� ����
        vn_log_id := no_prg_log_seq.NEXTVAL;
        begin
            no_pkg_mig.prg_start(
                vn_log_id,
                vs_prg_name,
                vs_params);
        end;
        
        -- ���� �ð�.
        vn_total_time := DBMS_UTILITY.GET_TIME;
        
        -- ���� ����.
        vs_query :=             'create table ' || ps_to_table_name || ' as ' || chr(13); -- 
        vs_query := vs_query || ' select * from ' || ps_from_table_name || chr(13);
        
        EXECUTE IMMEDIATE vs_query;

        -- �ҿ� �ð�
        vn_total_time := (DBMS_UTILITY.GET_TIME - vn_total_time) / 100;
        vs_prg_log := 'INSERT �Ǽ�: ' || SQL%ROWCOUNT || ', �ҿ� �ð�: ' || vn_total_time || chr(13);
        
        commit;
        
        begin
            no_pkg_mig.prg_end(
                vn_log_id,
                vs_prg_log);
        end;
        
        
    exception when others then
        rollback;
        dbms_output.put_line(SQLERRM);
        
        begin
            vs_prg_log := SQLERRM;
            no_pkg_mig.prg_error(
                vn_log_id,
                vs_prg_log);
        end;
        
    end ctas_table;
    
end no_pkg_mig;
/
