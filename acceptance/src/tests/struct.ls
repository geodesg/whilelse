u = require '../common'

u.test 'struct', 'Struct', ->
  # Builds:
  #     struct point < x :: float, y :: float >
  #     var p :: point
  #     p := point(10, 3)
  #     log(p.x)
  #     log(p.y)
  #     p.x := 12
  #     log(p.x)
  #     log(p.y)
  #
  u.open-test-application!

  u.add-declaration 's' # struct
  u.enter 'point'

  u.enter 'x'
  u.then-type 'f'
  u.enter 'y'
  u.then-type 'f'
  u.wait-for-input!
  u.then-press 'Tab'

  u.wait-for-chooser 'Target type'
  u.then-press 'v' # variable
  u.enter 'p'

  u.then-press 'o'
  u.wait-for-input!

  u.step "Search for point"
  u.then-type 'po' # point
  casper.wait 200 # FIXME: bug when the delay is too small
  u.then-press 'Enter'
  casper.wait 1000
  u.then-press 'Esc'
  u.then-press 'y'

  # TODO: shortcut to go to implementation or first/last command
  u.then-press 'c', '3' # select blank implementation
  u.then-press 'l'

  u.wait-for-input!
  u.surch null, 'p', 'variable', 'p'
  u.surch ':', null, 'command', 'assign'

  u.surch null, 'po', 'struct', 'point'
  u.wait-for-input!
  u.surch null, '10', 'literal', '10'
  u.then-press 'Tab'
  u.wait-for-input!
  u.surch null, '3', 'literal', '3'

  u.then-press 'Tab'
  u.then-press 'Tab'

  u.surch-function 'log'
  u.surch-variable 'p'
  u.surch '.', null, 'field', 'x'
  u.tab!
  u.surch-function 'log'
  u.surch-variable 'p'
  u.surch '.', 'y', 'field', 'y'
  u.tab!

  u.step "Assign"
  u.surch-variable 'p'
  u.surch '.', null, 'field', 'x'
  u.surch ':', null, 'command', 'assign'
  u.surch-literal '12'
  u.tab!

  u.surch-function 'log'
  u.surch-variable 'p'
  u.surch '.', null, 'field', 'x'
  u.tab!
  u.surch-function 'log'
  u.surch-variable 'p'
  u.surch '.', 'y', 'field', 'y'

  u.step "Run code"
  u.then-press 'S-j', 'r'
  u.assert-textarea-popup null, 'run output is correct',
    """
    10
    3
    12
    3

    """
