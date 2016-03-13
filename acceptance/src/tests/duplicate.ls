u = require '../common'

u.test 'duplicate', 'Duplicate', ->
  # application exampleApplication
  #   var i
  #   step i from 1 to 5
  #     log(i)
  u.open 'http://app.whilelse.local/posi/experiments/acTeO2ouW4Mg?sync=sandbox&gen=1', 'application'


  u.step "Select loop"

  casper.then -> casper.evaluate -> posi.cursor.set $('#posi-node-acf1iNiSBTDB') # step loop

  u.then-press 'C-d'



  u.step "Run code"
  u.then-press 'S-j', 'r'
  u.assert-textarea-popup null, 'run output is correct',
    """
    1
    2
    3
    4
    5
    1
    2
    3
    4
    5

    """

