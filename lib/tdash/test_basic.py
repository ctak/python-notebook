# test_basic.py
# 기본적인 list 의 concat 등을 테스트 해보기 위하여
#
# 특정 파일만 테스트 해 보려면 파일이름을 써주면 된다. > python -m unittest test_basic
#

from os import sep
import unittest

def name_to_keywords(nm, separator='_'):
  if nm is None:
    raise Exception('name is None')
  # strip name
  nm = nm.strip()
  if nm == '':
    raise Exception('name is Empty String')
  # returned list
  rtn = []
  tokens = nm.split(separator)
  for i in range(len(tokens)):
    rtn.append( separator.join(tokens[0+i:len(tokens)]) )
  return rtn 

class TestBasic(unittest.TestCase):

  def test_list_concat(self):
    list =  ['hello', 'world', 'good', 'bye']
    list2 = list[0:1] + ['good', 'to'] + list[1:] + ['see', 'you'] # 이렇게 연결하면 되네.
    print(list2)
    pass

  def test_list_contains(self):
    list =  ['hello', 'world', 'good', 'bye']
    idx = list.index("good")
    self.assertEqual(2, idx)

  def test_split_and_loop_inverse(self):
    # join 관련
    list =  ['hello', 'world', 'good', 'bye']
    name = '_'.join(list)
    self.assertEqual('hello_world_good_bye', name)

    tokens = name.split('_')
    self.assertEqual(4, len(tokens))

    print('#' * 32)
    for i in range(len(tokens)):
      print(i)
      # print(tokens[0:len(tokens)-i])
      print(tokens[0:i+1])

  def test_name_to_keywords(self):
    print('#'*64 + ' test_name_to_keywords')
    self.assertRaises(Exception, lambda: name_to_keywords(None))
    # 하나의 문자 테스트
    list1 = name_to_keywords('hello')
    self.assertEqual(1, len(list1))
    self.assertEqual('hello', list1[0])
    # empty like 문자 테스트
    self.assertRaises(Exception, lambda: name_to_keywords('  '))
    self.assertRaises(Exception, lambda: name_to_keywords(''))
    # 여러개 문자 테스트
    list2 = name_to_keywords('hello_world_good_bye')
    self.assertEqual(4, len(list2))
    self.assertEqual('hello_world_good_bye', list2[0])
    self.assertEqual('world_good_bye', list2[1])
    self.assertEqual('good_bye', list2[2])
    self.assertEqual('bye', list2[3])