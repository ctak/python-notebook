import unittest
import numpy as np
import pandas as pd

import tdash as td

def foo(data):
  print('=' * 64)
  print('type: ' + str(type(data)))
  print(data)
  print('연도: {}'.format(data['연도']))
  print('월: ' + str(data['월']))
  data['extra'] = 'hello'
  print(data)
  return 'world'

def foo2(data):
  data['extra'] = 'hello'
  return data

class TestTdash(unittest.TestCase):
  def test_is_same_columns(self):
    print('#'*64)
    # 두 개의 파일을 읽는다.
    df1 = pd.read_csv('./resources/주택도시보증공사_전국 신규 민간아파트 분양가격 동향_20211130.csv')
    self.assertRaises(Exception, lambda:td.is_same_columns(df1))

    # df2 = pd.read_csv('./resources/지역별 규모별 ㎡당 평균 분양가격(천원)_21.10월.csv', encoding='euc-kr')
    df2 = pd.read_csv('./resources/지역별 규모별 ㎡당 평균 분양가격(천원)_21.10월_2.csv') # 끝의 칼럼 이름에 ' ' 더함.
    # df2 = pd.read_csv('./resources/주택도시보증공사_전국 신규 민간아파트 분양가격 동향_20211130_2.csv')
    self.assertTrue(not td.is_same_columns(df1, df2))

  # 일반적으로 lambda row: 에서는 return 값을 받아서 scalar 값 세팅을 하는 것이다.
  # 특수하게, axis=1 방향으로 한 다음 return 을 row 로 하면 새로운 DataFrame 을 만들 수 있다.
  # https://stackoverflow.com/questions/16476924/how-to-iterate-over-rows-in-a-dataframe-in-pandas
  def test_apply_lambda(self):
    print('#'*64)
    df = pd.read_csv('./resources/주택도시보증공사_전국 신규 민간아파트 분양가격 동향_20211130.csv')
    df2 = df.head(2).copy() # 원천데이터 프레임과 파생 데이터프레임.
    # df2['extra'] = np.nan # A value is trying to be set on a copy of a slice from a DataFrame.
    df2.loc[:,'extra'] = np.nan
    # df2['extra'] = df2.apply(lambda row: foo(row), axis=1) # axis=1 이 중요.
    
    df2.apply(lambda row: foo(row), axis=1)
    print('#'*64 + ' Final df2')
    print(df2)
    
    df3 = df2.apply(lambda row: foo2(row), axis=1)
    print('#'*64 + ' Final df3')
    print(df3)