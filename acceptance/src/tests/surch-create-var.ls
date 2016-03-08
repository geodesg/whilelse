u = require '../common'

u.test 'surch-create-var', 'Surch - Create variable', ->
  u.open-example-application!
  u.find 'log'
  u.then-press 'S-a'
  u.wait-for-input!
  u.then-type 'j'
  u.then-press 'C-v'
  u.surch ':', '=', 'command', 'assign'
  u.surch-variable 'i'
  u.plus!
  u.surch-literal 10
  u.then-press 'y'
  u.then-press 'S-a'
  u.surch-function 'log'
  u.surch-variable 'j'

  u.then-press 'y', 'y'
  u.then-press 'S-j', 'r'
  u.assert-textarea-popup null, 'run output is correct',
    """
    1
    11
    2
    12
    3
    13
    4
    14
    5
    15

    """


