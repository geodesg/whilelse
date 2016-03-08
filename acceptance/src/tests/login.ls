u = require '../common'

u.test 'login', 'Login / Logout', ->
  u.open-homepage-unsandboxed!
  u.eval -> localStorage.clear!
  u.press 'C-A-l' # logout just in case localstorage was not cleared

  u.enter 'testchuck'

  u.wait 200
  u.wait-for-toplevel-node-with-type 'container'
  u.expect-current-node-name 'testchuck-workspace'

  u.press 'C-A-l'
  u.enter 'testbob'

  u.wait 200
  u.wait-for-toplevel-node-with-type 'container'
  u.expect-current-node-name 'testbob-workspace'

