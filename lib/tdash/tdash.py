# tdash.py
# v0.1

import numpy as np
import pandas as pd

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


################################################################
# private
################################################################

def __trans_list_to_str(list):
  return ','.join(list)
