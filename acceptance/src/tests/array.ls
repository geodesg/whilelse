u = require '../common'

u.test 'array', 'Array', ->
  # Builds:
  #     var a: array<integer>
  #     a := [1, 2]
  #     push(a, 3)
  #     a[3] := 4
  #     each(a, (item) -> log(item))
  #
  u.open-test-application!

  u.step 'var a: array<integer>'

  u.then-press 'a' # add
  u.wait-for-chooser 'Select property to add'
  u.then-press 'd' # declaration
  u.wait-for-chooser 'Target type'
  u.then-press 'v' # variable
  # TODO: improve adding a variable: e.g. [a]-[v] or [A-v]
  u.wait-for-input!
  u.then-press 'a', 'Enter' # variable name
  u.wait-for-chooser 'Select Type'
  u.then-press 'r' # array
  u.wait-for-chooser 'Select Type'
  u.then-press 'i' # int

  u.wait-for-chooser 'Target type'
  u.then-press 'Esc'

  u.then-press 'down' # select block

  u.step 'a := [1, 2]'
  u.then-press 'l' # complete block
  u.surch null, 'a', 'variable', 'a'
  u.surch ':', '=', 'command', 'assign'
  u.surch null, 'make_arr', 'command', 'make_array' # TODO: improve UX: use "[" to create array
  u.surch null, '1', 'literal', '1'
  u.then-press 'tab' # next parameter
  u.surch null, '2', 'literal', '2'
  u.then-press 'tab' # next parameter
  u.then-press 'tab' # finish make_array, new statement

  u.step 'push(a, 3)'
  u.surch null, 'push', 'function', 'push'
  u.surch null, 'a', 'variable', 'a'
  u.then-press 'tab' # next argument
  u.surch null, '3', 'literal', '3'
  u.then-press 'tab' # finish

  u.step 'a[3] := 4'
  u.surch null, 'a', 'variable', 'a'
  u.then-press '['
  u.surch null, '3', 'literal', '3'
  u.then-press 'tab' # continue: select a[3]

  u.surch ':', '=', 'command', 'assign'
  u.surch null, '4', 'literal', '4'
  u.then-press 'tab' # continue: new statement

  u.step 'each(a, (item) -> log(item))'
  u.surch null, 'each', 'function', 'each'
  u.surch null, 'a', 'variable', 'a'
  u.then-press 'tab'

  u.then-press 'tab' # skip function name - TODO don't ask for function name
  u.then-press 'tab' # skip new arg - TODO don't ask for new arg
  u.then-press 'tab' # skip return type - TODO don't ask for return type

  u.surch null, 'log', 'function', 'log'
  u.surch null, 'item', 'variable', 'item'

  u.step "Run code"
  u.then-press 'S-j', 'r'

  u.assert-textarea-popup null, 'run output is correct',
    """
    1
    2
    3
    4

    """

