u = require '../common'

u.test 'move-statements', 'Move statement up and down', ->
  # application exampleApplication
  #   var i
  #   step i from 1 to 5
  #     log(i)
  u.open 'http://app.whilelse.local/posi/experiments/acTeO2ouW4Mg?sync=sandbox&gen=1', 'application'


  u.step "Select log(i)"
  casper.then -> casper.evaluate -> posi.cursor.set $('#posi-node-ac3jnLnNO984') # log(i) statement within loop

  u.then-press 'S-A'

  u.surch null, 'log', 'function', 'log'

  casper.wait 200
  u.then-type "'hi"
  u.then-press 'Enter'
  casper.wait 100
  u.then-press 'y' # select statement

  u.then-press 'S-up'

  u.step "Run code"
  u.then-press 'y'
  u.then-press 'y'
  u.then-press 'S-j', 'r'

  u.assert-textarea-popup null, 'run output is correct',
    """
    hi
    1
    hi
    2
    hi
    3
    hi
    4
    hi
    5

    """

  u.then-press 'Esc' # dismiss popup

  u.step "Select log(i)"
  casper.then -> casper.evaluate -> posi.cursor.set $('#posi-node-ac3jnLnNO984') # log(i) statement within loop

  u.then-press 'up'

  u.then-press 'S-down'

  u.step "Run code"
  u.then-press 'y'
  u.then-press 'y'
  u.then-press 'S-j', 'r'

  u.assert-textarea-popup null, 'run output is correct',
    """
    1
    hi
    2
    hi
    3
    hi
    4
    hi
    5
    hi

    """
