set serveroutput on;

-- HR �� ������ ���⿡ ���� ���� ����.
select * from all_tables where owner = 'HR';

select * from hr.jobs;

--update hr.jobs set min_salary = 100 where job_id = 'HR_REP';
--set serveroutput off;
set serveroutput on;
declare
--    dbms_output.enable;
    message varchar2(20) := 'Hello, World!';
begin
    /* pl/sql �� �ּҴ� begin null; end; �̱��� */
    dbms_output.put_line(message);
end;
/

-- PL/SQL Delimeters
/*
  % Attribute indicator
  : Host variable indicator
  = ���ٸ�, �� assign �� �ƴϴ�.
  @ Remote access indicator ����?
  := �̰� assign
  => Association Operator ����?
  || Ȯ���ϰ� �̰��� Concatenation
  ** ���� operator
  <<,>> Label Delimiter (begin and end) ����? �̸��� ���ٴ� ���ΰ�?
  .. Range Operators �� �ֳ�.
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
    subtype name is char(20); -- ���� 20
    subtype message is varchar2(100);
    salutation name;
    greetings message;
BEGIN
    salutation := 'Reader ';
    greetings := 'Welcome to the World of PL/SQL';
    dbms_output.put_line('Hello ' || salutation || greetings);
end;
/

-- null �� null ���� �������� �ʴ�. �׷��� is null �� ���� ������.

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

PI CONSTANT NUMBER := 3.141592654; -- �� ����� pl/sql ����� �ƴϴ�. �׷��� PI ��� ����� ����ǹǷ� �����Ѵ�. �׷��� ����� �ִٸ� ��� �����Ѵ�.
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

-- prime �� �Ҽ��ΰ���.
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
            -- ���⼭�� i �� ���� 2���� ����� �������ٸ� i �� �Ҽ��� �ƴѵ�, i �� j �� �������ٸ� �Ҽ��� ����( 1 �̿ܿ� �ڱ�ιۿ� ���������� �ʱ� ������ )
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
    introduction := ' Hello! I''m John Smith �ƴ� Źâ�� from INfotech, �ƴ� Ƽ���';
    choice := 'y';
    introduction := introduction || ' ���⿡ ���� �� �ֳ�';
    
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
    dbms_output.put_line(sys.diutil.bool_to_int(b)); -- ��������� boolean_to_char �� �������, sys.diutil.bool_to_int �� ������.
    dbms_output.put_line(initcap('hello'));
    
    -- �ε����� ������ �����?
    dbms_output.put_line( instr(greetings, 'h') );  -- 1 ��. �ᱹ position �� 1���� �����ϴ� ����.
    dbms_output.put_line( instrb(greetings, 'h') );
    dbms_output.put_line( length('�ȳ��ϼ���') ); -- 5
    dbms_output.put_line( lengthb('�ȳ��ϼ���') ); -- 15
    dbms_output.put_line( lpad('10', 5) ); -- [   10]
    dbms_output.put_line( lpad('10', 5, '0') ); -- [00010]
--    dbms_output.put_line( nanvl(10/0, 0) ); -- �̷� �� [divisor is equal to zero �� ������ ��. ����Ⱑ ���� �ʳ�.
--    dbms_output.put_line( nvl2(1, 100, 0) ); -- nvl2 �� ���� ����?
    dbms_output.put_line( initcap(greetings) ); -- ����Ե� [Hello World] �̳�. ��� �ܾ Init �Ǵϱ� ���� ����⿡ ���ڱ�.
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
        dbms_output.put_line('Student: ' || names(i) || ' Marks: ' || marks(i)); -- pl/sql �� �� 1���� �ε����� ���۵�.
    end loop;
end;
/

-- select * from customers;

declare
    cursor c_customers is
    select name from customers; -- cursor �� �����ϴµ� �켱 [declare] �ȿ��� �����ϳ�.
    type c_list is varray(6) of customers.name%type;
    name_list c_list := c_list(); -- �켱 �ʱ�ȭ ��Ŵ. �ʱ�ȭ ��Ű�� ������ ������ �߻��Ѵٰ� �ϴ�.
    counter integer := 0;
begin
    for n in c_customers loop
        counter := counter + 1;
         name_list.extend; -- ����� ��â���̳�. �Լ��� �ƴѵ�... size �� �ø��� �͵� �ƴϳ�.
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

-- PARAMETER �� �����ϱ� �Լ�ó�� ������ �ʳ�. �̰� ���� �� ���� �Լ��� �� �� �� �ֳ�.
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
    LOOP -- �׳� loop ��� ������. for �� �ƴϰ�, while �� �ƴϰ�.
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
PROCEDURE printbook (book books) IS -- book IN books �� �Ƚᵵ �Ǵ� IN �� default �̰� �����ص� �ȴٴ� ���̳�.
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
    when no_data_found then -- ora-xxxxx: no data found ���⿡ no_data_found �� [���] �� �ٲٸ� �� �� ����.
        dbms_output.put_line('No such customer!'); -- �̰��� dbms_output ���ݾ�. �̰��� ���� �� �� �� ���ݾ�.
    when too_many_rows then
        dbms_output.put_line('Too Many Rows');
    when others then
        dbms_output.put_line('Error!');
end;
/

-- �̷� EXCEPTION �� �������� ���� ��ƾ� �ϳ�. �� ��ƾ� �ұ�? ���α׷��� �ڻ쳪��. ���� ���� �������� ���� �ƴұ�?

select * from customers;

create or replace TRIGGER display_salary_changes
BEFORE DELETE or INSERT or UPDATE on customers
FOR EACH ROW
WHEN (NEW.ID > 0)
DECLARE
    sal_diff number;
begin
    sal_diff := :NEW.salary - :OLD.salary; -- :OLD �� :NEW �� ���ڵ巹������ ��밡����.(FOR EACH ROW)
    
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
    code customers.id%type := :cc_id; -- [&] �� [:] �� ����. [:] ���� �ϸ� ���� �� �� �Էµǵ� ������ �Ǵ� ������ �ֱ�. [&] �� ���� ���� ���� �߸� ���� ������ �߻��ϰ� �Ǵϱ�
    name customers.name%type := :c_name; -- [&] �� ��Ȯ�� ����̰�, [:] �� ����Ȯ�� �����.
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
    PROCEDURE listCustomer; -- �Ķ���Ͱ� ���� ���� ���ξ��� ���� ��.
    
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
            name_list.extend; -- type �� TABLE �̳�.
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

-- Index-By Table �� Map (Hashtable) �̳�.

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
    name := salary_list.FIRST; -- salary_list.first and then salary_list.next(name).. ��.. Ư�������� �׷� �� �ۿ� ��������.
    while name is not null loop -- �̸� ������ ���� �ֳ�. 
        dbms_output.put_line('Saslary of ' || name || ' is ' || to_char(salary_list(name)));
        name := salary_list.next(name);
    end loop;
end;
/

declare
    cursor c_customers is
        select name from customers order by name;
    type c_list is table of customers.name%type index by binary_integer; -- cannot be stored in the database. �׷� �̰��� ����� �� �� �ִٴ� ���ΰ�.
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
    type names_table is table of varchar2(10); -- �ٵ� �̷� �� �� ��� ����?
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
    name_list c_list := c_list(); -- �̰� �ʱ�ȭ. c_list();
    counter integer := 0;
begin
    for n in c_customers loop
        counter := counter + 1;
        name_list.extend; -- �̷��� table (�� list) ������ .extend �� �Ἥ ��. : Appends one null element to a collection.
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
  , map member function measure return number ); -- rectangle > ractange �� ���� �� �ִ�.
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

/* map function �� parameter �� ����, order function �� parameter �� �ִµ�( �� ���ü�� �ִµ�)
    ������ ���� �������� ���̰� ���ٸ� �� ���� 
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
    hr.employees �� hr.departments �� cursor �� �̿��� ����� ����
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

-- �� ������ ������� �ʴ´�.
create or replace type rc_employee as ref cursor;
/

create or replace procedure print_employee( rc_emp IN OUT sys_refcursor )
AS
begin
    open rc_emp for
        select employee_id, first_name from hr.employees order by employee_id;
end;
/

-- �̷��� sys_refcursor �� variable �� ������ �� �ִٴ� ���� ������.
variable rc refcursor;
exec print_employee( :rc );
print rc;

-- �׷� package �� ref_cursor �� �����Ͽ� out message �� ���, �����ϴ� ���� �� �� �غ���.
-- �װ��� ��� �����ϰ� ��� �����ϵ� ������� ������ �� �� �غ���.

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

-- begin/end ��Ͽ����� loop fetch ����� ���� ����.
-- �����ľ� ��.

-- �� �������� �Ʒ��� �ѹ��� ���μ� �����ؾ� ��.
-- �ֳĸ� begin/end ��������� :rc2 �� �� ������ ����� ��������. ���� [&] �� �ᵵ �������.
-- ����� sys_refcursor ���� �ܺο��� Ȯ���ҷ���, [variable rc refcursor;] �� ������ ����
-- �����Ų �� 
-- print rc; �� pl/sql ���� �ƴ� ������ Ȯ���� �� �ִٴ� ���̴�.
/*
����: VAR[IABLE] [ <variable> [ NUMBER | CHAR | CHAR (n [CHAR|BYTE]) |
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
