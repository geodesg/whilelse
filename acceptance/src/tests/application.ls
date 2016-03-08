u = require '../common'

u.test 'create-application', 'Can create a simple application', ->
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
  u.enter app-name

  u.wait-for-toplevel-node-with-type 'application'

  u.then-press 'l'

  u.surch-function 'log'
  u.enter "'hello"

  casper.wait 200

  u.then-press 'y', 'y'

  u.then-press 'S-j', 'r'

  u.assert-textarea-popup null, 'run output is correct',
    """
    hello

    """

