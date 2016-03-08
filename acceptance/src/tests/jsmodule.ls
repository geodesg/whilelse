u = require '../common'

u.test 'jsmodule', 'Can create a simple jsmodule', ->
  u.open!

  u.then-press 'a'

  u.step 'Create jsmodule'
  u.wait-for-input!
  u.then-type 'jsmo'
  casper.wait 200
  u.then-press 'Enter'

  u.step 'Enter jsmodule name'
  u.wait-for-input!
  u.then-type 'jsmod' + u.unixtime!
  u.then-press 'Enter'

  u.wait-for-toplevel-node-with-type 'jsmodule'

  u.then-press 'l'

  u.wait-for-input!
  u.surch null, 'ret', 'command', 'return'
  u.wait-for-input!
  u.then-type "4"
  u.then-press 'Enter'

  casper.wait 200

  u.then-press 'y', 'y'

  u.then-press 'S-j', 'c'

  u.assert-textarea-popup null, 'generated JS is correct',
    """
    module.exports = function () {
        return 4;
    }();
    """


