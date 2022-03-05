=== TODOS

- @20220304 두 DataFrame 의 칼럼 비교
- @20220305
  * NASCA 때무에 pd.read_excel 이 안되니까, 일단 xls 라이브러리로 엑셀을 읽어, csv 로 바꿔놓자. |
    그런다음 결과값에 NASCA 가 없는지 확인한 후, pd.read_csv 로 읽자. |
    즉 NASCA 를 제거하자는 것.
  * 일단 tag_name..unit_code 까지 groupby 한 결과(먼저 id 추가) 를 count 하고 다음 csv로. |
    다음에 다시 groupby (tag와 aitype) 한 다음 cnt 하고 그게 2 이상이면 틀린 것이다.