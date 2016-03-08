u = require '../common'

u.test 'unwrap-expr', 'Unwrap expression', ->
  # application exampleApplication
  #   var i
  #   step i from 1 to 5
  #     log(i)
  u.open 'http://app.whilelse.local/posi/experiments/acTeO2ouW4Mg?sync=sandbox', 'application'


  u.step "Select i within log(i)"
  casper.then -> casper.evaluate -> posi.cursor.set $('#posi-node-aceVxNOyQit3') # varref i within log(i)

  u.surch '+', null, 'operator', 'add'
  u.surch null, '1', 'literal', '1'

  u.step "Run code"
  u.then-press 'y'
  u.then-press 'y'
  u.then-press 'S-j', 'r'

  u.assert-textarea-popup null, 'run output is correct',
    """
    2
    3
    4
    5
    6

    """
  u.then-press 'Esc' # dismiss popup

  u.step "Select i within log(i) - again"
  casper.then -> casper.evaluate -> posi.cursor.set $('#posi-node-aceVxNOyQit3') # varref i within log(i)

  u.step "Unwrap"
  u.then-press 'S-w'

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

    """
