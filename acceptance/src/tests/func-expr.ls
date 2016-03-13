u = require '../common'

u.test 'func-expr', 'Func expr', ->
  u.open-test-application!

  u.then-press 'l'

  u.surch-function 'log'

  u.wait-for-input!
  u.then-type 'mod'
  u.then-press 'down' # function expression 'mod'
  u.enter!

  u.wait 200

  u.then-press '('
  u.surch-literal '10'
  u.tab!
  u.surch-literal '7'

  u.then-press 'S-j', 'r'
  u.assert-textarea-popup null, 'run output is correct',
    """
    3

    """
