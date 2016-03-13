u = require '../common'

u.test 'undo', 'Undo', ->
  u.open!

  u.then-press 'a'

  u.step 'Create application'
  u.wait-for-input!
  u.then-type 'appl'
  casper.wait 200
  u.then-press 'Enter'

  u.step 'Enter application name'
  u.wait-for-input!
  app-name = 'app' + u.unixtime!
  u.then-type app-name
  u.then-press 'Enter'

  u.wait-for-toplevel-node-with-type 'application'

  u.then-press 'l'

  u.wait-for-input!
  u.surch null, 'log', 'function', 'log'
  u.wait-for-input!
  u.then-type "'hello"
  u.then-press 'Enter'

  casper.wait 200

  u.step 'Undo'
  u.then-press 'u'

  u.then-press 'l'
  u.wait-for-input!
  u.then-type "'hi"
  u.then-press 'Enter'

  u.then-press 'S-j', 'r'

  u.assert-textarea-popup null, 'run output is correct',
    """
    hi

    """

