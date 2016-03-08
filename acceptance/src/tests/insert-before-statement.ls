u = require '../common'

u.test 'insert-before', 'Insert before statement', ->
  # application exampleApplication
  #   var i
  #   step i from 1 to 5
  #     log(i)
  u.open 'http://app.whilelse.local/posi/experiments/acTeO2ouW4Mg?sync=sandbox&gen=1', 'application'


  u.select-node 'ac3jnLnNO984' # log(i)

  u.then-press 'i'

  u.step "Add a `log` call"

  u.wait-for-input!
  u.surch null, 'log', 'function', 'log'
  u.surch null, "'hi", 'literal', 'hi'

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


