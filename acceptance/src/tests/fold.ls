u = require '../common'

u.test 'fold', 'Fold / unfold', ->

  # Open class-test2
  u.open 'http://app.whilelse.local/posi/experiments/acsZiqeLgVNw?sync=sandbox', 'class'

  u.select-node 'acqP821HPMzb' # constructor

  u.expect-node-not-visible 'ac4JsnCotBGU' # this.x := x
  u.then-press 'f' # unfold
  u.expect-node-visible 'ac4JsnCotBGU' # this.x := x
  u.then-press 'f'
  u.expect-node-not-visible 'ac4JsnCotBGU' # this.x := x
