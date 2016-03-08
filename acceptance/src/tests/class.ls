u = require '../common'

u.test 'class', 'Class', ->
  # Builds:
  #   class Dog
  #     name :: string
  #     construction (name) -> this.name = name
  #     talk: -> log('Woof')
  #     getName: -> return this.name
  #   max = new Dog('Max')
  #   max.talk()
  #   max.name = 'Maxy'
  #   log(max.getName())
  #
  u.open-test-application!

  u.add-declaration 'c' # class

  u.enter 'Dog'
  u.enter 'name'

  u.select-type 's' # string

  u.wait-for-input!; u.tab!

  u.step "Constructor"
  u.tab! # TODO: don't ask for name

  u.enter 'name'
  u.select-type 's'
  u.wait-for-input!; u.tab!
  u.tab! # skip return type

  u.surch null, 'this.n', 'field', 'this.name'
  u.assign!
  u.surch-variable 'name'
  u.tab!; u.tab!

  u.step "talk method"
  u.enter 'talk'
  u.tab! # skip params
  u.tab! # skip return type
  u.surch-function 'log'
  u.surch-string "Woof"
  u.tab!; u.tab!

  u.step "getName method"
  u.enter 'getName'
  u.tab! # skip params
  u.tab! # skip return type
  u.surch-command 'return'
  u.surch-field 'this.name'
  u.then-type 'yyyy' # select application # TODO: better way of selecting the application

  # TODO: improve speed by declaring variable inline and inferring type from assignment
  u.add-declaration 'v' # variable
  u.enter 'max'
  u.select-type 'o', 'Dog'
  u.esc!

  u.then-type 'yyyy' # select application
  u.then-type 'c3l' # select implementation

  u.surch-variable 'max'
  u.assign!
  u.surch-command 'new'
  u.enter-with-wait 'Dog'
  u.surch-string 'Max'
  u.tab! # TODO: shortcut to go to the next statment

  u.surch-variable 'max'
  u.surch '.', 't', 'field', 'talk' # TODO: actually that's a method
  u.tab!

  u.surch-variable 'max'
  u.surch '.', 'n', 'field', 'name'
  u.assign!
  u.surch-string 'Maxy'
  u.tab!

  u.surch-function 'log'
  u.surch-variable 'max'
  u.surch '.', 'g', 'field', 'getName'

  u.then-type 'yyyy' # select application
  u.then-press 'S-j', 'r'
  u.assert-textarea-popup null, 'run output is correct',
    """
    Woof
    Maxy

    """
