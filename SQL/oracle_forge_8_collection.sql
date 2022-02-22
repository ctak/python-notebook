set serveroutput on;
declare
    -- 숫자-문자 쌍의 연관배열 선언
    type av_type is TABLE OF varchar2(40)
                    INDEX BY pls_integer;
                    
    -- 연관배열 변수 선언
    vav_test av_type;
begin
    vav_test(10) := '10에 대한 값';
    vav_test(20) := '20에 대한 값';
    
    dbms_output.put_line(vav_test(10));
    dbms_output.put_line(vav_test(20));
    
end;
/

declare
    -- 5개의 문자형 값(크기는 5) 로 이루어진 varray 선언.
    type va_type is varray(5) of varchar2(20);
    
    -- varray 변수 선언
    vva_test va_type;
    
    vn_cnt number := 0;
begin
    -- 생성자를 사용해 값 할당 (총 5개지만 최초 3개만 값 할당)
    vva_test := va_type('FIRST', 'SECOND', 'THIRD', '', '');
    
    loop
        vn_cnt := vn_cnt + 1;
        if vn_cnt > 5 then
            exit;
        end if;
        
        -- varray 값 출력
        dbms_output.put_line(vva_test(vn_cnt));
    end loop;
    
    -- 값 변경
    vva_test(2) := 'TEST';
    vva_test(4) := 'FOURTH';
    
    vn_cnt := 0;
    loop
        vn_cnt := vn_cnt + 1;
        if (vn_cnt > 5) then
            exit;
        end if;
        
        dbms_output.put_line(vva_test(vn_cnt));
    end loop;
end;
/

-- 중첩 테이블. 말이 거창할 뿐이네. 이게 자바의 list 정도.
declare
    -- 중첩 테이블 선언
    type nt_typ is table of varchar2(10);
    
    -- 변수 선언
    vnt_test nt_typ;
begin
    vnt_test := nt_typ('FIRST', 'SECOND', 'THIRD');
    
    dbms_output.put_line(vnt_test(1));
    dbms_output.put_line(vnt_test(2));
    dbms_output.put_line(vnt_test(3));
end;
/