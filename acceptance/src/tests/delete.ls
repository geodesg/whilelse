u = require '../common'

u.test 'delete', 'Delete', ->
  # application exampleApplication
  #   var i
  #   step i from 1 to 5
  #     log(i)
  u.open 'http://app.whilelse.local/posi/experiments/acTeO2ouW4Mg?sync=sandbox&gen=1', 'application'


  u.step "Delete literal 5"

  casper.then -> casper.evaluate -> posi.cursor.set $('#posi-node-acbyky0y54vG') # literal 5

  casper.wait 50
  u.then-press 'd'


  u.step "Fill in blank with 3"

  u.then-press 'l'
  u.surch null, '3', 'literal', '3'

  u.step "Run code"

  u.then-press 'S-j', 'r'

  u.assert-textarea-popup null, 'run output is correct',
    """
    1
    2
    3

    """

