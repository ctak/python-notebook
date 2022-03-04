import unittest
import numpy as np
import pandas as pd

import tdash as td

class TestTdash(unittest.TestCase):
  def test_is_same_columns(self):
    # 두 개의 파일을 읽는다.
    df1 = pd.read_csv('./resources/주택도시보증공사_전국 신규 민간아파트 분양가격 동향_20211130.csv')
    self.assertRaises(Exception, lambda:td.is_same_columns(df1))

    # df2 = pd.read_csv('./resources/지역별 규모별 ㎡당 평균 분양가격(천원)_21.10월.csv', encoding='euc-kr')
    df2 = pd.read_csv('./resources/지역별 규모별 ㎡당 평균 분양가격(천원)_21.10월_2.csv') # 끝의 칼럼 이름에 ' ' 더함.
    # df2 = pd.read_csv('./resources/주택도시보증공사_전국 신규 민간아파트 분양가격 동향_20211130_2.csv')
    self.assertTrue(not td.is_same_columns(df1, df2))