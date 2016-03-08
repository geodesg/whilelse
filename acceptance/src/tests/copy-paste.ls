u = require '../common'

u.test 'copy-paste', 'Copy & Paste', ->
  # application exampleApplication
  #   var i
  #   step i from 1 to 5
  #     log(i)
  u.open 'http://app.whilelse.local/posi/experiments/acTeO2ouW4Mg?sync=sandbox&gen=1', 'application'


  u.step "Cut literal 5"

  casper.then -> casper.evaluate -> posi.cursor.set $('#posi-node-acbyky0y54vG') # literal 5

  casper.wait 50
  u.then-press 'C-c'


  u.step "Add a `log` call after the loop"

  casper.then -> casper.evaluate -> posi.cursor.set $('#posi-node-acf1iNiSBTDB') # step loop

  u.then-press 'S-a'
  u.wait-for-input!
  u.surch null, 'log', 'function', 'log'

  u.step "Paste literal 5 into the argument slot of `log`"

  u.then-press 'Esc' # dismiss arg expr search dialog
  u.then-press 'p' # paste

  u.step "Run code"

  u.then-press 'y'
  u.then-press 'y'


  u.then-press 'S-j', 'r'

  u.assert-textarea-popup null, 'run output is correct',
    """
    1
    2
    3
    4
    5
    5

    """
