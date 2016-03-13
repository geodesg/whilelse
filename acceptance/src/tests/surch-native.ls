u = require '../common'

u.test 'surch-native', 'Surch - Create native call, property, expression', ->
  u.open-example-application!
  u.find 'log'

  u.step "Native call"
  u.then-press 'S-a'
  u.wait 200
  u.then-type 'console.log'
  u.wait 200
  u.then-press 'C-n'
  u.wait 400
  u.tab!
  u.wait 400
  u.surch-variable 'i'
  u.wait 200

  u.step "Native call on object"
  u.then-type '.'
  u.wait 200
  u.then-type 'toString'
  u.then-press 'C-n'
  u.wait 200

  u.step "Native prop on object"
  u.then-type '.'
  u.wait 200
  u.then-type 'length'
  u.then-press 'C-p'
  u.wait 200
  u.tab!

  u.step "Native expression"
  u.wait-for-input!
  u.then-type "i + 10"
  u.then-press 'C-e'
  u.wait 200

  u.then-press 'S-j', 'r'
  u.assert-textarea-popup null, 'run output is correct',
    """
    1
    1 11
    2
    1 12
    3
    1 13
    4
    1 14
    5
    1 15

    """
