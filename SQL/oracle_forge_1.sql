set serveroutput on;

-- HR 에 권한이 없기에 읽을 수가 없음.
select * from all_tables where owner = 'HR';

select * from hr.jobs;

--update hr.jobs set min_salary = 100 where job_id = 'HR_REP';
--set serveroutput off;
set serveroutput on;
declare
--    dbms_output.enable;
    message varchar2(20) := 'Hello, World!';
begin
    /* pl/sql 의 최소는 begin null; end; 이구만 */
    dbms_output.put_line(message);
end;
/

-- PL/SQL Delimeters
/*
  % Attribute indicator
  : Host variable indicator
  = 같다면, 즉 assign 이 아니다.
  @ Remote access indicator 뭐지?
  := 이게 assign
  => Association Operator 뭐지?
  || 확실하게 이것은 Concatenation
  ** 제곱 operator
  <<,>> Label Delimiter (begin and end) 뭐지? 이름을 쓴다는 것인가?
  .. Range Operators 도 있네.
*/

declare
    num1 integer;
    num2 real;
    num3 DOUBLE PRECISION;
begin
    null;
end;
/

/* user-defined subtype */
DECLARE
    subtype name is char(20); -- 고정 20
    subtype message is varchar2(100);
    salutation name;
    greetings message;
BEGIN
    salutation := 'Reader ';
    greetings := 'Welcome to the World of PL/SQL';
    dbms_output.put_line('Hello ' || salutation || greetings);
end;
/

-- null 은 null 과도 동일하지 않다. 그래서 is null 을 쓰는 것이지.

declare
    sales number(10, 2);
    pi CONSTANT double PRECISION := 3.1415;
    name varchar2(25);
    name2 integer;
    address varchar2(100);
begin
    dbms_output.put_line('sales: ' || sales || ', pi: ' || pi);
    
end;
/

set serveroutput on;
declare
    a integer := 10;
    b integer := 20;
    c integer;
    f real not null := 0;
begin
    c := a + b;
    dbms_output.put_line('Value of c: ' || c);
    f := 70/3;
    dbms_output.put_line('Value of f: ' || f);
end;
/

declare
    num1 number := 95;
    num2 number := 85;
begin
    declare
        num1 number := 195;
        num2 number := 185;
    begin
        dbms_output.put_line('inner num1: ' || num1);
        dbms_output.put_line('inner num2: ' || num2);
    end;
    
    dbms_output.put_line('outer num1: ' || num1);
    dbms_output.put_line('outer num2: ' || num2);
end;
/

/*
create table customers (
    id int not null,
    name varchar2(20) not null,
    age int not null,
    address char(25),
    salary decimal(18, 2),
    primary key (id)
);

insert into customers (id, name, age, address, salary)
values (1, 'Ramesh', 32, 'Ahmedabed', 2000.00);

INSERT INTO CUSTOMERS (ID,NAME,AGE,ADDRESS,SALARY) 
VALUES (2, 'Khilan', 25, 'Delhi', 1500.00 );  

INSERT INTO CUSTOMERS (ID,NAME,AGE,ADDRESS,SALARY) 
VALUES (3, 'kaushik', 23, 'Kota', 2000.00 );
  
INSERT INTO CUSTOMERS (ID,NAME,AGE,ADDRESS,SALARY) 
VALUES (4, 'Chaitali', 25, 'Mumbai', 6500.00 ); 
 
INSERT INTO CUSTOMERS (ID,NAME,AGE,ADDRESS,SALARY) 
VALUES (5, 'Hardik', 27, 'Bhopal', 8500.00 );  

INSERT INTO CUSTOMERS (ID,NAME,AGE,ADDRESS,SALARY) 
VALUES (6, 'Komal', 22, 'MP', 4500.00 ); 

select * from customers;
*/

declare
    c_id customers.id%type := 1;
    c_name customers.name%type;
    c_addr customers.address%type;
    c_sal customers.salary%type;
begin
    select name, address, salary into c_name, c_addr, c_sal
    from customers
    where id = c_id;
    
    dbms_output.put_line
    ('Customer ' || c_name || ' from ' || c_addr || ' earns ' || c_sal);
end;
/

PI CONSTANT NUMBER := 3.141592654; -- 이 명령은 pl/sql 블록이 아니다. 그래서 PI 라는 명령이 실행되므로 실패한다. 그래도 블록이 있다면 계속 진행한다.
declare
    -- constant declartion
    pi constant number := 3.141592654;
    -- other declarations
    radius number(5, 2);
    dia number(5, 2);
    circumference number(7, 2);
    area number(10, 2);
begin
--    pi := 3.14;
    radius := 9.5;
    dia := radius * 2;
    circumference := 2.0 * pi * radius;
    area := pi * radius * radius;
    -- output
    dbms_output.put_line('R: ' || radius);
    dbms_output.put_line('D: ' || dia);
    dbms_output.put_line('C: ' || circumference);
    dbms_output.put_line('A: ' || area);
end;
/

declare
    message varchar2(30) := 'That''s tutorialspoint.com!';
begin
    dbms_output.put_line(message);
end;
/

declare
    c_id customers.id%type := 1;
    c_sal customers.salary%type;
begin
    select salary
    into c_sal
    from customers
    where id = c_id;
    
    dbms_output.put_line('salary: ' || c_sal);
    if (c_sal <= 2000) then
        update customers
        set salary = salary + 1000
        where id = c_id;
        dbms_output.put_line('Salary updated');
    end if;
end;
/

----------------------------------------------------------------
-- LOOP
----------------------------------------------------------------
set serveroutput on;
declare
    x number := 10;
begin
    loop
        dbms_output.put_line(x);
        x := x + 10;
--        if (x > 50) then
--            exit;
--        end if;
        exit when x > 50;
    end loop;

    -- after exitm, control resumes here
    dbms_output.put_line('After Exit x is: ' || x);
end;
/

declare
    a number(2);
begin
    for a in 10..20 loop
        dbms_output.put_line('value of a: ' || a);
    end loop;
end;
/

begin
    dbms_output.put_line(mod(2, 2));
end;
/

-- prime 이 소수인가봐.
declare 
    i number(3);
    j number(3);
begin
    i := 2;
    << outer_loop >>
    loop
        j := 2;
        << inner_loop >>
        loop
            -- 여기서는 i 의 값을 2부터 나누어서 떨어진다면 i 는 소수가 아닌데, i 와 j 가 같아진다면 소수인 것임( 1 이외에 자기로밖에 나누어지지 않기 때문에 )
            exit when ((mod(i, j) = 0) or (j = i));
            j := j + 1;
        end loop inner_loop;
        
        if (j = i) then
            dbms_output.put_line(i || ' is prime');
        end if;
        
        i := i + 1;
        exit when i = 50;
    end loop outer_loop;
end;
/

/* declare string variables */
set serveroutput on;
declare
    name varchar2(20);
    company varchar2(30);
    introduction clob;
    choice char(1);
    b boolean;
    greetings varchar2(11) := 'hello world';
begin
    name := 'John Smith';
    company := 'Infotech Hello';
    introduction := ' Hello! I''m John Smith 아니 탁창범 from INfotech, 아니 티대시';
    choice := 'y';
    introduction := introduction || ' 여기에 더할 수 있나';
    
    dbms_output.put_line('hello => ' || choice);
    
    if choice = 'y' then
        dbms_output.put_line(name);
        dbms_output.put_line(company);
        dbms_output.put_line(introduction);
    end if;
    
    dbms_output.put_line(ascii('a')); -- 97
    dbms_output.put_line(chr(97)); -- a
    dbms_output.put_line(concat('hello', 'world')); -- helloworld
    introduction := concat(introduction, ' ');
    introduction := concat(introduction, introduction);
    dbms_output.put_line(introduction);
    b := concat('a','b') = 'ab';
    dbms_output.put_line(sys.diutil.bool_to_int(b)); -- 사용자정의 boolean_to_char 를 만들든지, sys.diutil.bool_to_int 를 쓰든지.
    dbms_output.put_line(initcap('hello'));
    
    -- 인덱스의 시작은 어디지?
    dbms_output.put_line( instr(greetings, 'h') );  -- 1 임. 결국 position 은 1부터 시작하는 구만.
    dbms_output.put_line( instrb(greetings, 'h') );
    dbms_output.put_line( length('안녕하세요') ); -- 5
    dbms_output.put_line( lengthb('안녕하세요') ); -- 15
    dbms_output.put_line( lpad('10', 5) ); -- [   10]
    dbms_output.put_line( lpad('10', 5, '0') ); -- [00010]
--    dbms_output.put_line( nanvl(10/0, 0) ); -- 이럴 때 [divisor is equal to zero 로 나오는 군. 만들기가 쉽지 않네.
--    dbms_output.put_line( nvl2(1, 100, 0) ); -- nvl2 는 아직 없나?
    dbms_output.put_line( initcap(greetings) ); -- 놀랍게도 [Hello World] 이네. 모든 단어가 Init 되니까 제목 만들기에 좋겠군.
    dbms_output.put_line( substr(greetings, 1, 1) ); -- [h]
    dbms_output.put_line( substr(greetings, -1, 1) ); -- [d]
end;
/

declare
    greetings varchar2(30) := '......Hello World......';
begin
    dbms_output.put_line(rtrim(greetings, '.')); -- [......Hello World]
    dbms_output.put_line(trim(greetings));
    dbms_output.put_line(trim('.' from greetings));
end;
/

create or replace type namearray as varray(3) of varchar2(10);
/

declare
    type namesarray is varray(5) of varchar2(10);
    type grades is varray(5) of integer;
    names namesarray;
    marks grades;
    total integer;
begin
    names := namesarray('Kavita', 'Pritam', 'Ayan', 'Roshav', 'Aziz');
    marks := grades(98, 97,78, 87, 92);
    total := names.count;
    dbms_output.put_line('Total ' || total || ' Students');
    for i in 1..total loop
        dbms_output.put_line('Student: ' || names(i) || ' Marks: ' || marks(i)); -- pl/sql 은 다 1부터 인덱스가 시작됨.
    end loop;
end;
/

-- select * from customers;

declare
    cursor c_customers is
    select name from customers; -- cursor 를 선언하는데 우선 [declare] 안에서 선언하네.
    type c_list is varray(6) of customers.name%type;
    name_list c_list := c_list(); -- 우선 초기화 시킴. 초기화 시키지 않으면 에러가 발생한다고 하니.
    counter integer := 0;
begin
    for n in c_customers loop
        counter := counter + 1;
         name_list.extend; -- 상당히 독창적이네. 함수도 아닌데... size 를 늘리는 것도 아니네.
        name_list(counter) := n.name;
        dbms_output.put_line( 'Customer(' || counter || '): ' || name_list(counter));
    end loop;
    dbms_output.put_line('');
    dbms_output.put_line('name_list.count: ' || name_list.count);
end;
/
    
----------------------------------------------------------------
-- PROCEDURE
----------------------------------------------------------------
create or replace PROCEDURE greetings
AS
BEGIN
    dbms_output.put_line('Hello World!');
END;
/

-- PARAMETER 가 없으니까 함수처럼 콜하지 않네. 이게 값이 될 수도 함수가 될 수 도 있네.
EXECUTE greetings;

EXEC greetings;

BEGIN greetings; END;
/

DROP PROCEDURE greetings;

begin null; end;
/

declare
    a number;
    b number;
    c number;

PROCEDURE findMin(x IN number, y IN number, z OUT number) IS
BEGIN
    if x < y THEN
        z := x;
    else
        z := y;
    end if;
END;
BEGIN
    a := 23;
    b := 45;
--    findMin(a, b, c);
    findMin( z => c, x => a, y => b );
    dbms_output.put_line(' Minimum of (23, 45) : ' || c);
end;
/

declare 
    a number;
PROCEDURE squareNum(x IN OUT number) IS
BEGIN
    x := x * x;
END;
BEGIN
    a := 23;
    squareNum(a);
    dbms_output.put_line(' Square of (23) : ' || a);
END;
/

select * from customers;

create or replace FUNCTION customers_count
RETURN number IS
    total number(2) := 0;
BEGIN
    select count(*) into total from customers;
    return total;
END;
/

declare
    c number(2);
begin
    c := customers_count();
    dbms_output.put_line('Total no. of Customers: ' || c);
end;
/

declare
    a number;
    b number;
    c number;
FUNCTION findMax(x IN number, y IN number)
RETURN number
IS
    z number;
BEGIN
    if x > y then
        z := x;
    else
        z := y;
    end if;
    return z;
END;

BEGIN
    a := 23;
    b := 45;
    c := findMax(a, b);
    dbms_output.put_line(' Maximum of (23, 45): ' || c);
end;
/

declare
    num number;
    factorial number;
function fact(x number)
return number 
IS
    f number;
BEGIN
    if x = 0 then
        f := 1;
    else
        f := x * fact(x-1);
    end if;
return f;
end;

begin
    num := 6;
    factorial := fact(num);
    dbms_output.put_line(' Factorial ' || num || ' is ' || factorial);
end;
/

declare
    total_rows number(2);
begin
    update customers
    set salary = salary + 500;
    if sql%notfound then
        dbms_output.put_line('no customers selected');
    elsif sql%found then
        total_rows := sql%rowcount;
        dbms_output.put_line( total_rows || 'customers selected');
    end if;
end;
/

SET serveroutput on;
declare
    c_id customers.id%type;
    c_name customers.name%type;
    c_addr customers.address%type;
    
    cursor c_customers is
        select id, name, address from customers;
begin
    OPEN c_customers;
    LOOP -- 그냥 loop 라는 것이지. for 도 아니고, while 도 아니고.
        FETCH c_customers into c_id, c_name, c_addr;
            EXIT WHEN c_customers%notfound;
            dbms_output.put_line(c_id || ' ' || c_name || ' ' || c_addr);
    END LOOP;
    CLOSE c_customers;
end;
/

select * from customers;

declare
    e_id hr.employees.employee_id%type;
    e_phone hr.employees.phone_number%type;
    
    cursor c_employees is
        select employee_id, phone_number from hr.employees;
begin
    open c_employees;
    loop
    fetch c_employees into e_id, e_phone;
        exit when c_employees%notfound;
        dbms_output.put_line(e_id || ' ' || e_phone);
    end loop;
    close c_employees;
end;
/

declare
    customer_rec customers%rowtype;
begin
    select * into customer_rec
    from customers
    where id = 5
    ;
    dbms_output.put_line('Customer ID: ' || customer_rec.id);
    dbms_output.put_line('Customer Name: ' || customer_rec.name);
end;
/

declare
    cursor customer_cur is
        select id, name, address
        from customers;
    customer_rec customer_cur%rowtype;
begin
    open customer_cur;
    loop
        fetch customer_cur into customer_rec;
        exit when customer_cur%notfound;
        dbms_output.put_line(customer_rec.id || ' ' || customer_rec.name || ' ' || customer_rec.address);
    end loop;
end;
/

declare
    TYPE books is RECORD
    ( title varchar(50)
    , author varchar(50)
    , subject varchar(100)
    , book_id number);
    book1 books;
    book2 books;
begin
    -- Book 1 specification
    book1.title := 'C Programming';
    book1.author := 'Nuha Ali ';
    book1.subject := 'C Programming Tutorial';
    book1.book_id := 6495407;
    -- Book 2 specification
    book2.title := 'Telecom Billing';
    book2.author := 'Zara Ali';
    book2.subject := 'Telecom Billing Tutorial';
    book2.book_id := 6495700;
    
    -- Print book 1 record
    dbms_output.put_line('Book 1 title: ' || book1.title);
    dbms_output.put_line('Book 1 author: ' || book1.author);
    
    -- Print book 2 record
    dbms_output.put_line('Book 2 title: ' || book2.title);
    dbms_output.put_line('Book 2 author: ' || book2.author);
end;
/

declare
    type books is record
      ( title varchar(50)
      , author varchar(50)
      , subject varchar(100)
      , book_id number );
    
    book1 books;
    book2 books;
PROCEDURE printbook (book books) IS -- book IN books 로 안써도 되니 IN 이 default 이고 생략해도 된다는 말이네.
BEGIN
    dbms_output.put_line('Book title: ' || book.title);
    dbms_output.put_line('Book author: ' || book.author);
    dbms_output.put_line('Book subject: ' || book.subject);
    dbms_output.put_line('Book book_id: ' || book.book_id);
END;

begin
    -- Book 1
    book1.title := 'C Programming';
    book1.author := 'Nuha Ali';
    
    -- Book 2
    book2.title := 'Telecom Billing';
    book2.author := 'Zara Ali';
    
    --
    printbook(book1);
    printbook(book2);
end;
/

declare
    c_id customers.id%type := 8;
    c_name customers.name%type;
    c_addr customers.address%type;
begin
    select name, address into c_name, c_addr
    from customers
    where id = c_id
    ;
    dbms_output.put_line('Name: ' || c_name);
    dbms_output.put_line('Address: ' || c_addr);
    
exception
    when no_data_found then -- ora-xxxxx: no data found 였기에 no_data_found 로 [언더] 로 바꾸면 될 것 같음.
        dbms_output.put_line('No such customer!'); -- 이것은 dbms_output 이잖아. 이것을 실행 시 알 수 없잖아.
    when too_many_rows then
        dbms_output.put_line('Too Many Rows');
    when others then
        dbms_output.put_line('Error!');
end;
/

-- 이런 EXCEPTION 을 서버에서 굳이 잡아야 하나. 왜 잡아야 할까? 프로그램이 박살나서. 잡을 때는 숨겨지는 것이 아닐까?

select * from customers;

create or replace TRIGGER display_salary_changes
BEFORE DELETE or INSERT or UPDATE on customers
FOR EACH ROW
WHEN (NEW.ID > 0)
DECLARE
    sal_diff number;
begin
    sal_diff := :NEW.salary - :OLD.salary; -- :OLD 와 :NEW 는 레코드레벨에만 사용가능함.(FOR EACH ROW)
    
    dbms_output.put_line('Old salary: ' || :OLD.salary);
    dbms_output.put_line('New salary: ' || :NEW.salary);
    dbms_output.put_line('Salary difference: ' || sal_diff);
end;
/

select * from user_triggers;

INSERT INTO CUSTOMERS (id, name, age, address, salary)
values (7, 'Kriti', 22, 'HP', 7500.00);

update customers
set salary = salary + 500
--where id = 2
;

CREATE PACKAGE cust_sal AS
    PROCEDURE find_sal(c_id customers.id%type);
END cust_sal;
/

CREATE OR REPLACE PACKAGE BODY cust_sal AS

    PROCEDURE find_sal(c_id customers.id%type) IS
    c_sal customers.salary%type;
    BEGIN
        select salary into c_sal
        from customers
        where id = c_id;
        dbms_output.put_line('Salary: ' || c_sal);
    END find_sal;
END cust_sal;
/

declare
    code customers.id%type := :cc_id; -- [&] 와 [:] 의 차이. [:] 으로 하면 값이 잘 못 입력되도 실행이 되는 문제가 있군. [&] 로 했을 때는 값이 잘못 들어가면 에러가 발생하게 되니까
    name customers.name%type := :c_name; -- [&] 가 정확한 방법이고, [:] 은 비정확한 방법임.
begin
    cust_sal.find_sal(code);
end;
/

CREATE OR REPLACE PACKAGE c_package AS
    -- Adds a customer
    PROCEDURE addCustomer (
        c_id customers.id%type
      , c_name customers.name%type
      , c_age customers.age%type
      , c_addr customers.address%type
      , c_sal customers.salary%type );
      
    -- Removes a customer
    PROCEDURE delCustomer (
        c_id customers.id%type );
        
    -- Lists all customers
    PROCEDURE listCustomer; -- 파라미터가 없을 때는 가로없이 쓰면 됨.
    
END c_package;
/

CREATE OR REPLACE PACKAGE BODY c_package AS

    PROCEDURE addCustomer (
        c_id customers.id%type
      , c_name customers.name%type
      , c_age customers.age%type
      , c_addr customers.address%type
      , c_sal customers.salary%type )
    IS
    BEGIN
        insert into customers (id, name, age, address, salary)
            values (c_id, c_name, c_age, c_addr, c_sal);
    END addCustomer;
    
    PROCEDURE delCustomer (
        c_id customers.id%type )
    IS
    BEGIN
        delete from customers
        where id = c_id;
    END delCustomer;
    
    PROCEDURE listCustomer
    IS
        CURSOR c_customers IS
            select name from customers;
        TYPE c_list is TABLE OF customers.name%type;
        name_list c_list := c_list();
        counter integer := 0;
    BEGIN
        FOR n IN c_customers LOOP
            counter := counter + 1;
            name_list.extend; -- type 이 TABLE 이네.
            name_list(counter) := n.name;
            
            dbms_output.put_line('Customer(' || counter || ')' || name_list(counter) );
        END LOOP;
    END listCustomer;

END c_package;
/

declare
    code customers.id%type := 8;
begin
--    c_package.addcustomer(7, 'Rajnish', 25, 'Chennai', 3500);
    c_package.addCustomer(8, 'Subham', 32, 'Delhi', 7500);
    c_package.listcustomer;
    c_package.delcustomer(code);
    c_package.listCustomer;
end;
/

-- Index-By Table 은 Map (Hashtable) 이네.

declare
    type salary is table of number index by varchar2(20); -- salary['tak'] => 1000000000
    salary_list salary;
    name varchar2(20);
begin
    -- adding elements to the table
    salary_list('Rajnish') := 62000;
    salary_list('Minakshi') := 75000;
    salary_list('Martin') := 100000;
    salary_list('James') := 78000;
    
    -- printing the table
    name := salary_list.FIRST; -- salary_list.first and then salary_list.next(name).. 음.. 특이하지만 그럴 수 밖에 없었겠지.
    while name is not null loop -- 이름 순으로 돌고 있네. 
        dbms_output.put_line('Saslary of ' || name || ' is ' || to_char(salary_list(name)));
        name := salary_list.next(name);
    end loop;
end;
/

declare
    cursor c_customers is
        select name from customers order by name;
    type c_list is table of customers.name%type index by binary_integer; -- cannot be stored in the database. 그럼 이것이 저장될 수 도 있다는 것인가.
    name_list c_list;
    counter integer := 0;
begin
    for n in c_customers loop
        counter := counter + 1;
        name_list(counter) := n.name;
        dbms_output.put_line('Customer(' || counter || '): ' || name_list(counter));
    end loop;
end;
/

declare
    type names_table is table of varchar2(10); -- 근데 이런 걸 왜 써야 하지?
    type grades is table of integer;
    
    names names_table;
    marks grades;
    total integer;
begin
    names := names_table('Kavita', 'Pritam', 'Ayan', 'Rishav', 'Aziz');
    marks := grades(98, 97, 78, 87, 92);
    total := names.count;
    dbms_output.put_line('Total ' || total || ' Students');
    for i in 1..total loop
        dbms_output.put_line('Student:' || names(i) || ', Marks: ' || marks(i));
    end loop;
end;
/

declare
    cursor c_customers is
        select name from customers;
    type c_list is table of customers.name%type;
    name_list c_list := c_list(); -- 이게 초기화. c_list();
    counter integer := 0;
begin
    for n in c_customers loop
        counter := counter + 1;
        name_list.extend; -- 이렇게 table (즉 list) 인지는 .extend 를 써서 함. : Appends one null element to a collection.
        name_list(counter) := n.name;
        dbms_output.put_line('Customer('||counter||'): ' || name_list(counter));
    end loop;
end;
/

select sysdate from dual;
select to_char(current_date,'YYYY-MM-DD HH24:MI:SS') from dual;
select to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') from dual;
select add_months(sysdate, 5) from dual;
select localtimestamp from dual;

begin
dbms_output.disable;
end;
/

select * from all_tables where owner = 'HR'
/

begin
    dbms_output.put_line( user || ' Tables in the database:');
    for t in (select table_name from all_tables where owner = 'HR')
    loop
        dbms_output.put_line(t.table_name);
    end loop;
end;
/

declare
    lines dbms_output.chararr;
    num_lines number;
begin
    -- enable the buffer with default size 20000
    dbms_output.enable;
    
    dbms_output.put_line('Hello Reader!');
    dbms_output.put_line('Hope you have enjoyed the tutorials');
    dbms_output.put_line('Have a great time exploring pl/sql!');
    
    num_lines := 3;
    
    dbms_output.get_lines(lines, num_lines);
    
    for i in 1..num_lines loop
        dbms_output.put_line('hello:' || lines(i));
    end loop;
end;
/

create or replace type address as object (
    house_no varchar2(10)
  , street varchar2(30)
  , city varchar2(20)
  , state varchar2(10)
  , pincode varchar2(10) );
/

create or replace type customer as object (
    code number(5)
  , name varchar2(30)
  , contact_no varchar2(12)
  , addr address
  , member procedure display
);
/

declare
    residence address;
begin
    residence := address('103A', 'M.G.Road', 'Jaipur', 'Rajasthan', '201301');
    dbms_output.put_line('House No: ' || residence.house_no);
    dbms_output.put_line('Street: ' || residence.street);
    dbms_output.put_line('City: ' || residence.city);
    dbms_output.put_line('State: ' || residence.state);
    dbms_output.put_line('Pincode: ' || residence.pincode);
end;
/

create or replace type rectangle as object (
    length number
  , width number
  , member function enlarge(inc number) return rectangle
  , member procedure display
  , map member function measure return number ); -- rectangle > ractange 을 비교할 수 있다.
/

create or replace type body rectangle as
    member function enlarge(inc number) return rectangle
    is
    begin
        return rectangle(self.length + inc, self.width + inc);
    end enlarge;
    
    member procedure display
    is
    begin
        dbms_output.put_line('Length: ' || length);
        dbms_output.put_line('Width: ' || width);
    end display;
    map member function measure return number
    is
    begin
        return (sqrt(length*length + width*width));
    end measure;
end;
/

begin
    dbms_output.put_line('sqrt(9): ' || sqrt(9));
end;
/

declare
    r1 rectangle;
    r2 rectangle;
    r3 rectangle;
    inc_factor number := 5;
begin
    r1 := rectangle(3, 4);
    r2 := rectangle(5, 7);
    r3 := r1.enlarge(inc_factor);
    r3.display;
    if (r1 > r2) then -- calling measure function
        r1.display;
    else
        r2.display;
    end if;

end;
/

/* map function 은 parameter 가 없고, order function 은 parameter 가 있는데( 즉 대상객체가 있는데)
    실제로 쓰는 영역에서 차이가 없다면 왜 쓰지 
*/

create or replace type rectangle as object (
    length number
  , width number
  , member procedure display
  , order member function measure(r rectangle) return number
);
/

create or replace type body rectangle as
    member procedure display
    is
    begin
        dbms_output.put_line('Length: ' || length);
        dbms_output.put_line('Width: ' || width);
    end display;
    
    order member function measure(r rectangle) return number
    is
    begin
        if (sqrt(self.length*self.length + self.width*self.width) >
            sqrt(r.length*r.length + r.width*r.width)) then
            return 1;
        else
            return -1;
        end if;
    end measure;
end;
/

declare
    r1 rectangle;
    r2 rectangle;
begin
    r1 := rectangle(23, 44);
    r2 := rectangle(15, 17);
    r1.display;
    r2.display;
    dbms_output.put_line(' ');
    dbms_output.put_line('');
    if (r1 > r2) then --calling measure function
        r1.display;
    else
        r2.display;
    end if;
end;
/

/*
    hr.employees 와 hr.departments 를 cursor 를 이용해 출력해 보자
*/

select 
    e.employee_id
    , e.first_name
    , d.department_id
    , d.department_name
from
    hr.employees e, hr.departments d
where
    e.department_id = d.department_id
order by
    e.employee_id;
/

declare
--    type cursor_employee is ref cursor;
--    c_emp cursor_employee;
    c_emp sys_refcursor;
    
    e_id hr.employees.employee_id%type;
    e_first_name hr.employees.first_name%type;
    e_department_id hr.employees.department_id%type;
    d_name HR.departments.department_name%type;
begin
    open c_emp for
        select employee_id, first_name, department_id
        from hr.employees order by employee_id;
--    for n in c_emp loop
--        dbms_output.put_line('hello');
--    end loop;
    loop
        fetch c_emp into e_id, e_first_name, e_department_id;
        exit when c_emp%notfound;
        
        dbms_output.put_line('id: ' || e_id || ', name: ' || e_first_name);
        dbms_output.put_line('  department_id: ' || e_department_id);
        
        if e_department_id is not null then
            select department_name into d_name from hr.departments where department_id = e_department_id;
            dbms_output.put_line( d_name );
        else
            dbms_output.put_line('!!!!!!!! department_id is null.');
        end if;
        
        dbms_output.put_line('');
        
    end loop;
    
end;
/

-- 이 구문은 실행되지 않는다.
create or replace type rc_employee as ref cursor;
/

create or replace procedure print_employee( rc_emp IN OUT sys_refcursor )
AS
begin
    open rc_emp for
        select employee_id, first_name from hr.employees order by employee_id;
end;
/

-- 이렇게 sys_refcursor 를 variable 로 선언할 수 있다는 것이 멋지네.
variable rc refcursor;
exec print_employee( :rc );
print rc;

-- 그럼 package 에 ref_cursor 를 선언하여 out message 를 잡고, 실행하는 것을 한 번 해보자.
-- 그것을 어떻게 실행하고 어떻게 컴파일된 결과값을 보여야 할 지 해보자.

create or replace package test_pkg as
    TYPE t_cursor IS ref cursor;
    PROCEDURE open_one_cursor (
        p_n_empid in number
      , p_c_emp in out t_cursor );
--    PROCEDURE open_two_cursor (
--        p_c_emp out t_cursor
--      , p_c_dep out t_cursor );
end test_pkg;
/

create or replace package body test_pkg as
    procedure open_one_cursor (
        p_n_empid in number
      , p_c_emp in out t_cursor )
    is
        v_cursor t_cursor;
    begin
        if p_n_empid <> 0 then
            open v_cursor for
                select *
                from hr.employees emp, HR.departments dept
                where emp.department_id = dept.department_id
                    and emp.employee_id = p_n_empid;
        end if;
        
        p_c_emp := v_cursor;
    end open_one_cursor;
end;
/

variable rc refcursor;
exec test_pkg.open_one_cursor(172, :rc);
print rc;

-- begin/end 블록에서는 loop fetch 방법이 있을 뿐임.
-- 돌려쳐야 함.

-- 이 실행방법은 아래를 한번에 감싸서 실행해야 함.
-- 왜냐면 begin/end 방법에서는 :rc2 로 써 놓으면 물어보기 때문이지. 물론 [&] 로 써도 물어보지만.
-- 결론은 sys_refcursor 등을 외부에서 확인할려면, [variable rc refcursor;] 로 선언한 다음
-- 실행시킨 후 
-- print rc; 로 pl/sql 문이 아닌 곳에서 확인할 수 있다는 것이다.
/*
사용법: VAR[IABLE] [ <variable> [ NUMBER | CHAR | CHAR (n [CHAR|BYTE]) |
    VARCHAR2 (n [CHAR|BYTE]) | NCHAR | NCHAR (n) |
    NVARCHAR2 (n) | CLOB | NCLOB | BLOB | BFILE
    REFCURSOR | BINARY_FLOAT | BINARY_DOUBLE ] ] 
*/
variable rc2 refcursor;
variable emp_id number;
begin
    :emp_id := 176;
    test_pkg.open_one_cursor(:emp_id, :rc2);
end;
/

print rc2;
