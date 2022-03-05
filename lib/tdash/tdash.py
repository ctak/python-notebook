# tdash.py
# v0.1

import numpy as np
import pandas as pd
import xlrd
import csv

def is_same_columns(*dfs):
  if len(dfs) < 2:
    raise Exception('args is greater then 1')

  yn = True
  s = None
  for idx, df in enumerate(dfs):
    # print(str(idx) + ': ')
    print('{}: '.format(idx))
    if s is None:
      s = __trans_list_to_str(df.columns.tolist())
      continue
    if s != __trans_list_to_str(df.columns.tolist()):
      print('idx: ' + str(idx) + '. is not same')
      print(df.columns.tolist())
      yn = False
      break
    
  return yn

def xls_to_csv(src, shidx, dest):
  with xlrd.open_workbook(src) as wb:
    sh = wb.sheet_by_index(shidx)
    with open(dest, 'w', newline='', encoding='euc-kr') as f:
      c = csv.writer(f)
      for r in range(sh.nrows):
        c.writerow(sh.row_values(r))

################################################################
# private
################################################################

def __trans_list_to_str(list):
  return ','.join(list)
