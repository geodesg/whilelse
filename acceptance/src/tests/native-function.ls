u = require '../common'

u.test 'native-func', 'Native function', ->
  u.open-test-application!

  u.add-declaration 'f' # function

  u.enter 'nativefunc'
  u.enter 'a'
  u.select-type 'i'
  u.wait-for-input!
  u.tab!
  u.tab!
  u.esc!
  u.then-press 'y'

  # TODO: replace S-m & S-e with a single command & remove S-down
  u.step "Set implementation mode"
  u.then-press 'S-m' # set implementation mode
  u.choose 'Select implementation mode...', 'n'
  u.wait 100

  u.step "Edit native code"
  u.then-press 'S-e' # edit native code
  u.then-press 'S-down', 'S-down', 'S-down', 'S-down'
  u.enter 'return a + 1;'

  u.step "Generate"
  u.then-press 'S-j', 'c'
  u.assert-textarea-popup null, 'run output is correct',
    """
    function nativefunc(a) {
        return a + 1;
    }
    """
