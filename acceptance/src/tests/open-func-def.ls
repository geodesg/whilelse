u = require '../common'

u.test 'open-func-def', 'Open function definition', ->
  u.open-example-application!

  u.select-node 'ac3jnLnNO984' # log(i)

  u.then-press 'S-o'

  u.step "wait for function"
  u.wait-for-toplevel-node-with-type 'function'
  u.step "expect"
  u.expect-top-level-node 'acJhgKsrinVi' # log function

