select * from all_tab_columns;
select * from all_col_comments;
select * from all_ind_columns;

-- 칼럼 코멘트 조회
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
   and a.owner = 'FORGE'
 order by a.table_name, a.column_id
;

-- 테이블 인덱스 조회
select 
    a.table_name,
    b.index_name,
    b.column_position as pos,
    a.column_name,
    b.descend,
    a.data_type ||
        (case
            when data_type like '%CHAR%' then '(' || data_length || ')'
            when data_type = 'NUMBER' and data_precision > 0 and data_scale > 0 then '(' || data_precision || ',' || data_scale || ')'
            when data_type = 'NUMBER' and data_precision > 0 then '(' || data_precision || ')'
        end) as data_type,
    decode(nullable, 'N', 'N') nullable,
    c.comments
  from all_tab_columns a,
    all_ind_columns b,
    all_col_comments c
 where a.table_name = b.table_name
   and a.column_name = b.column_name
   and a.table_name = c.table_name
   and a.column_name = c.column_name
   and a.owner = b.table_owner
   and a.owner = c.owner
   and a.owner = 'FORGE'
 order by a.table_name,
    b.index_name,
    b.column_position
;

-- BIN$vp... 휴지통 비우기
show recyclebin;

purge recyclebin;

-- 나의 테이블을 MegaBytes 로 조회하기
select
    segment_name, round(bytes/1024/1024, 2) as megabytes
  from user_segments
 where segment_type = 'TABLE'
 order by segment_name
;