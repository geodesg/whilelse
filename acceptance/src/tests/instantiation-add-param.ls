u = require '../common'

u.test 'instantiation-add-param', 'Instantiation - Add param', ->
  # TODO: also handle removing parameters

  u.open-test-application!

  u.surch 'l', 'new', 'command', 'new'
  u.then-type 'Poi'
  u.wait 200
  u.enter!

  u.surch-literal 10
  u.tab!
  u.surch-literal 20
  u.esc! # func-arg
  u.esc! # new (instantiation)


  u.step "Open class definition"
  u.then-press 'S-o' # navigate to definition
  u.wait-for-toplevel-node-with-type 'class'

  u.step "Add new param"
  u.find 'x', 2
  u.then-press 'S-a' # add new param
  u.enter 'z'
  u.select-type 'i'
  u.wait 200 # TODO: error message if I don't wait ("node z-variable not found in DOM")

  u.step "Back"
  u.then-press 'b'
  u.wait-for-toplevel-node-with-type 'application'

  u.step "Add new argument to new Point"
  u.find 'Point' # finds class
  u.esc! # instantiation
  u.then-press 'S-p'
  u.choose 'Select parameter', 'z'

  u.wait 200
  u.then-press 'l'
  u.surch-literal 30

  # we're not actually using the z parameter,
  # just wanted to test the process of adding it
  u.assert true


