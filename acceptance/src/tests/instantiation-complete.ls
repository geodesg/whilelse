u = require '../common'

u.test 'instantiation-complete', 'Instantiation - Complete params', ->

  u.open-test-application!

  u.surch 'l', 'new', 'command', 'new'
  u.then-type 'Poi'
  u.wait 200
  u.enter!

  u.surch-literal 10

  u.step "Delete func-arg node"
  u.tab!
  u.esc!
  u.esc!
  u.then-press 'd' # delete func-arg

  u.step "Select instantiation"
  u.find "new"
  u.then-press 'S-l'
  # unimplemented :(
