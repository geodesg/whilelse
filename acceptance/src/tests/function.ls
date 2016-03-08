u = require '../common'

u.test 'create-function', 'Create a function', ->
  u.open!

  u.then-press 'a'

  u.step 'Create function'
  u.wait-for-input!
  u.then-type 'func'
  casper.wait 200
  u.then-press 'Enter'
  u.wait-for-toplevel-node-with-type 'function'
  u.then-press 'l'
  u.wait-for-input!

  u.step 'Enter function name'
  func-name = 'test' + u.unixtime!
  u.then-type func-name
  u.then-press 'Enter'

  u.enter-param 'a', 'i'

  u.enter-param 'b', 'i'

  u.step "No more params"
  u.wait-for-input!
  u.then-press 'Tab'

  u.step "Return type"
  u.wait-for-chooser 'Select Type'
  u.then-press 'i'

  u.surch-variable 'a'

  u.wrap-with-operator '-', 'substract'

  u.surch-variable 'b'

  u.then-press 'Esc'
  u.surch '\\', 'ret', 'command', 'return'

  u.then-press 'Esc'
  u.then-press 'y', 'y'

  u.then-press 'S-j', 'c'

  u.assert-textarea-popup null, 'generated JS function is correct',
    """
    function #{func-name}(a, b) {
        return a - b;
    }
    """

