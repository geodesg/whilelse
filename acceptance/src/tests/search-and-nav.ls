u = require '../common'

u.test '', 'Search and Navigate', ->
  u.open!

  u.step "Search"
  u.then-press 's'
  u.wait-for-input!
  u.then-type 'whileExample'
  casper.wait 200
  u.then-press 'Enter'
  u.wait-for-toplevel-node-with-type 'function'


  u.step "Go to parent"
  u.then-press 'g'
  u.then-press 'p'
  u.wait-for-toplevel-node-with-type 'container'


  u.step "Back"
  u.then-press 'b'
  u.wait-for-toplevel-node-with-type 'function'
  u.then-press 'C-left'
  u.wait-for-toplevel-node-with-type 'container'


  u.step "Forward"
  u.then-press 'S-b'
  u.wait-for-toplevel-node-with-type 'function'
  u.then-press 'C-right'
  u.wait-for-toplevel-node-with-type 'container'

  u.assert true, '- no errors'



