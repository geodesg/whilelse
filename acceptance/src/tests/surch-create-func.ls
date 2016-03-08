u = require '../common'

u.test 'surch-create-func', 'Surch - Create function', ->
  u.open-example-application!
  u.find 'log'
  u.then-press 'S-a'

  u.surch-function 'log'
  u.wait-for-input!

  u.step "Create function"
  u.then-type 'addTen'
  u.then-press 'C-f'

  u.step "Define function"
  u.enter 'x'
  u.select-type 'i'
  u.wait-for-input!
  u.tab!
  u.tab!
  u.surch-command 'return'
  u.surch-variable 'x'
  u.plus!
  u.surch-literal 10
  u.tab!

  u.step "Back to the function call"
  u.tab!
  u.surch-variable 'i'

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



