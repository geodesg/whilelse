u = require '../common'

u.test 'set-func-param', 'Set function parameter', ->
  # When I add a parameter to a function signature, I should be able to add the parameter to function calls.
  # TODO: also handle removing parameters

  u.open-test-application!

  u.step "Create function with no parameters"
  u.add-declaration 'f' # function
  u.enter 'plusOne'
  u.tab! # no param
  u.select-type 'i' # return type: integer
  u.surch-command 'return'
  u.surch-literal '1'
  u.then-press 'y', 'y', 'y'

  u.step "Call function"
  # TODO: a way to deterministicly select the implementation of a function
  u.then-press 'c'
  u.then-press '2'
  u.then-press 'l'
  u.surch-function 'log'

  # Test: can select function that was just added
  # Test: function is higher that function-value

  u.surch-function 'plusOne'
  u.wait-for-input!
  u.esc!

  u.step "Add parameter to function"
  # Test: search on page
  u.find 'plusOne'

  # TODO: find a more intuitive way to add a parameter
  u.then-press 'A-down' # select function-signature
  u.then-press 'a'
  u.choose 'Select property to add', 'p'
  u.enter 'a' # parameter name
  u.select-type 'i'
  u.wait-for-input!
  u.esc! # no more parameters, invisible blank will be selected
  u.esc! # function-signature selected
  u.then-press 'down' # declarations
  u.then-press 'down' # implementation (block)
  u.then-press 'A-down' # first statement (return 1)
  u.then-press 'A-down' # literal 1
  u.surch '+', null, 'operator', 'add'
  u.surch-variable 'a'


  u.step "Set parameter in function call"
  u.find 'plusOne', 2 # select fcall (2nd match)

  u.then-press 'S-p'
  u.choose 'Select parameter', 'a'
  u.wait 200
  u.then-press 'l'
  u.surch-literal '333'

  u.then-press 'y', 'y'
  u.then-press 'S-j', 'r'

  u.assert-textarea-popup null, 'run output is correct',
    """
    334

    """
