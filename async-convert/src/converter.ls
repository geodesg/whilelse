{each,map,find,filter} = require 'prelude-ls'
j = require './js-ast-util'

module.exports = convert = (program) ->

  is-function-containing-await-or-marked-async = (tree) ->
    return false unless is-obj(tree)
    return false unless is-function-node(tree)
    return true if tree.params.length > 0 && tree.params[tree.params.length-1].name == '__ASYNC'
    #console.log "FUNCTION: ", dbg(tree)
    #console.log "contains-await => ", contains-await(tree)
    return true if contains-await(tree)
    return false

  for-functions-containing-await-or-marked-async = (tree, callback) ->
    for-objects-with-condition tree, is-function-containing-await-or-marked-async, callback

  for-functions-containing-await-or-marked-async program, (func) ->
    convert-function(func)

  if contains-await(program)
    convert-function(program, is-program: true)

#-- end of convert




contains-await = (node) ->
  #console.log JSON.stringify(node)
  found = false
  for-objects-with-condition2 node,
    condition: (node) ->
      return false unless is-obj(node)
      #console.log " -- obj", dbg(node)
      return false unless node.type == 'CallExpression'
      #console.log ' -- call', dbg(node)
      node.callee && node.callee.type == 'Identifier' && node.callee.name == '__AWAIT'
    stop-condition: is-function-node
    callback: -> found := true
  #console.log "CONTAINS-AWAIT", dbg(node), "=>", found, "\n"
  found

is-function-node = (node) ->
  is-obj(node) && node.type && (node.type == 'FunctionDeclaration' || node.type == 'FunctionExpression' || node.type == 'FunctionDefinition')

# If the node is an AWAIT call => returns the nested call
# otherwise return falsey
check-await-call = (node) ->
  if node && node.type == 'CallExpression' &&
    node.callee.type == 'Identifier' && node.callee.name == '__AWAIT'
    node.arguments[0]

convert-function = (func, {is-program} = {}) ->
  tmp-var-counter = 0
  issue-tmp-var-name = (name) ->
    tmp-var-counter := tmp-var-counter + 1
    "#{name || 'tmp'}#{tmp-var-counter}"

  add-callback-parameter-if-needed = (func, already-handles = false) ->
    func.params ?= []
    if func.params.length > 0
      last-index = func.params.length - 1
      if (last-param = func.params[last-index]) && last-param.type == 'Identifier' && last-param.name == '__ASYNC'
        if already-handles
          callback-name = "callback"
        else
          callback-name = issue-tmp-var-name 'callback'
        func.params[last-index] = { type: 'Identifier', name: callback-name }
        callback-name


  unless is-program
    # Add callback to the parameter list
    already-handles = function-already-handles-callback(func)
    callback-name = add-callback-parameter-if-needed(func, already-handles)

  # If the function is already written in async-style, then don't change it.
  return func if already-handles

  main-sequence = j.block!
  curr-sequence = main-sequence

  # Mode:
  #    * 'await' - keep await commands, for debugging
  #    * 'normal'
  mode = 'normal'

  get-curr-sequence = -> curr-sequence

  append-statement = (statement) ->
    #console.log "APPEND-STATEMENT --- ", dbg(statement), "\n"
    if mode == 'normal'
      if statement.type == 'VariableDeclaration' &&
          (declarator = statement.declarations[0]).type == 'VariableDeclarator' &&
          (call = check-await-call(declarator.init))

        func-expr = j.func-expr null, [declarator.id.name], []
        call.arguments.push(func-expr)

        curr-sequence.body.push j.expr call
        set-sequence func-expr.body

      else if statement.type == 'ExpressionStatement' && (call = check-await-call(statement.expression))
        func-expr = j.func-expr null, [], []
        call.arguments.push(func-expr)

        curr-sequence.body.push j.expr call
        set-sequence func-expr.body
      else
        curr-sequence.body.push statement
    else
      curr-sequence.body.push statement

  last-statement = ->
    last(curr-sequence.body)

  # Mark the end of a sequence, e.g. on return/break/etc, no further commands make sense after it's closed
  close-sequence = -> curr-sequence.x_closed := true
  sequence-closed = -> curr-sequence.x_closed

  set-sequence = (block) ->
    curr-sequence := block

  convert-properties = (node) ->
    new-obj = {}
    for key, item of node
      new-contents = convert-contents(item)
      #console.log "item ", item
      #console.log "---- new-obj[#{key}] = ", JSON.stringify(new-contents)
      #if JSON.stringify(new-contents) == '[null]'
        #throw "Woah!"
      new-obj[key] = new-contents
    new-obj

  convert-contents = (node) ->
    #if !contains-await(node)
      #if node.type && (node.type.index-of('Statement') != -1 || node.type == 'VariableDeclaration')
        #append-statement(node)
      #return node
    switch type(node)
    case 'Array'
      node := node |> map (item) -> convert-contents(item)
    case 'Object'
      switch node.type
      case 'CallExpression'
        node := convert-call(node)
        convert-properties(node)
        node
      case 'AssignmentExpression'
        convert-assignment(node)
      case 'BinaryExpression'
        node := convert-binary-expr(node)
        convert-properties(node)
        node
      case 'ReturnStatement'
        convert-return(node)
      case 'ExpressionStatement'
        convert-expr-statment(node)
      case 'IfStatement'
        convert-if-statement(node)
      case 'SwitchStatement'
        convert-switch-statement(node)
      case 'ForInStatement'
        # TODO convert-for-in-statement(node)
        #convert-properties(node)
        append-statement(node)
        null
      case 'WhileStatement'
        convert-while-statement(node)
      case 'BlockStatement'
        convert-block-statement(node)
      case 'VariableDeclaration'
        convert-declaration(node)
      case 'MemberExpression', 'ObjectExpression', 'Property'
        convert-properties(node)
      case 'Identifier', 'Literal'
        node
      case 'FunctionExpression'
        convert-function(node)
      case 'FunctionDeclaration'
        append-statement(node)
        null
      else
        throw "Can't convert #{node.type}"
        convert-properties(node)
    else
      node

  convert-call = (call) ->
    callee = call.callee

    #console.log "---convert-call", dbg(callee)
    if callee && callee.type == 'Identifier' && callee.name == '__AWAIT'
      inner-call = call.arguments[0] # argument must also be another call, the one that needs to be awaited
      inner-call = convert-call-simple(inner-call)
      call.arguments[0] = inner-call
      call
    else
      convert-call-simple(call)

  convert-assignment = (node) ->
    node.right = extract-as-assignment node.right
    node

  convert-call-simple = (call) ->
    #console.log "CONVERT CALL SIMPLE", call
    # Evaluate all arguments
    new-args = []
    for arg in call.arguments
      new-args.push(extract-as-assignment(arg))
    call.arguments = new-args
    # Expression nodes return the new expression; may also append to statements
    call

  convert-binary-expr = (expr) ->
    expr.left = extract-as-assignment(expr.left)
    expr.right = extract-as-assignment(expr.right)
    expr

  convert-return = (ret) ->
    if callback-name
      if ret.argument
        arg = extract-as-assignment ret.argument
        append-statement j.expr j.callf callback-name, arg
      else
        append-statement j.expr j.callf callback-name
      #append-statement j.return!
    close-sequence!
    # Statements don't return anything; they can only append to statments
    null

  convert-expr-statment = (node) ->
    node = convert-contents(node.expression)
    append-statement j.expr node
    null

  convert-declaration = (node) ->
    for item in node.declarations
      if item.init
        item.init = extract-as-assignment item.init
    append-statement node

  convert-if-statement = (node) ->
    # Define & declare function that will be called when
    # either branch of the if statement is finished.
    cont-func = j.func-expr null, [], []
    cont-func-name = issue-tmp-var-name('ifCont')
    append-statement j.var(cont-func-name, cont-func)

    # Append an empty if statement, we'll build it later
    new-node = type: 'IfStatement'
    new-node.test = extract-as-assignment(node.test)
    new-node.consequent = j.block!
    new-node.alternate = j.block!
    append-statement(new-node)

    # Build the THEN branch
    set-sequence new-node.consequent
    convert-contents node.consequent
    append-statement j.expr j.callf cont-func-name unless sequence-closed!

    # Built the ELSE branch - if there wasn't any, we still need to add one to call the cont-func
    set-sequence new-node.alternate
    convert-contents node.alternate if node.alternate
    append-statement j.expr j.callf cont-func-name unless sequence-closed!

    set-sequence cont-func.body

    # if (condition)
    #   x = await fcall
    # else
    #   y = await fcall
    # statement
    # return x
    #
    # var x, y
    # cb1 = ->
    #   statement
    #   callback(expr)
    # if (condition)
    #   fcall (tmp-x) ->
    #     x = tmp-x
    #     cb1()
    # else
    #   fcall (tmp-y)
    #     y = tmp-y
    #     cb1()

  convert-switch-statement = (node) ->
    orig-sequence = get-curr-sequence!
    # Define & declare function that will be called when
    # either branch of the switch statement is finished.
    switch-name = issue-tmp-var-name('switch')
    cont-func = j.func-expr null, [], []
    cont-func-name = "#{switch-name}Cont"
    append-statement j.var(cont-func-name, cont-func)

    discriminant = extract-as-assignment-unless-literal(node.discriminant)

    # A variable that keeps track whether a case has been invoked.
    # When it turns true, all the remaining cases are executed,
    # until a break is encountered.
    flag-var-name = "#{switch-name}Flag"
    append-statement j.var flag-var-name, j.lit false

    #new-node = type: 'SwitchStatement'
    #new-node.discriminant = extract-as-assignment(node.discriminant)
    #new-node.cases = []

    # - evaluate discriminant
    # - for each case
    #   - evaluate test
    #   - compare discriminant to test
    #   - if matches
    #     - execute branch
    #     - when break found
    #       - jump to the end of the switch statement
    #
    for case-index from 0 to node.cases.length - 1
      switch-case = node.cases[case-index]
      append-statement j.var "#{switch-name}Case#{case-index}", (case-func = j.func-expr null, [], [])
      set-sequence case-func.body

      convert-contents switch-case.consequent

      # CASE-END: - call next case statement unless break'd or return'd
      unless sequence-closed!
        if case-index == node.cases.length - 1
          # Final case => continue after the switch block
          append-statement j.expr j.callf cont-func-name
        else
          # Non-final case => continue with next case
          append-statement j.expr j.callf "#{switch-name}Case#{case-index + 1}"

      set-sequence orig-sequence
      # append-statement j.expr j.callf cont-func-name
      # TODO: handle break

    for case-index from 0 to node.cases.length - 1
      switch-case = node.cases[case-index]
      if switch-case.test
        case-expr = extract-as-assignment(switch-case.test)
        test = j.bin('===', discriminant, case-expr)

        new-node = type: 'IfStatement'
        new-node.test = test #j.bin('||', j.id(flag-var-name), test)
        new-node.consequent = j.block!
        new-node.alternate = j.block!

        append-statement(new-node)

        set-sequence new-node.consequent
        append-statement j.expr j.callf "#{switch-name}Case#{case-index}"

        set-sequence new-node.alternate
      else
        append-statement j.expr j.callf "#{switch-name}Case#{case-index}"

    set-sequence cont-func.body

  convert-while-statement = (node) ->
    orig-sequence = get-curr-sequence!
    # Define & declare function that will be called when
    # either branch of the while while loop has finished.
    cont-func = j.func-expr null, [], []
    cont-func-name = issue-tmp-var-name('whileCont')
    append-statement j.var(cont-func-name, cont-func)

    # Define & declare the iteration function that corresponds
    # to one iteration of the loop.
    # It contains the condition and the loop body.
    iter-func = j.func-expr null, [], []
    iter-func-name = issue-tmp-var-name('whileIter')
    append-statement j.var(iter-func-name, iter-func)

    set-sequence iter-func.body

    test = extract-as-assignment(node.test)

    if-stmt =
      type: 'IfStatement'
      test: test
      consequent: j.block!
      alternate: j.block!

    append-statement if-stmt

    set-sequence if-stmt.consequent

    for item in node.body.body
      convert-contents(item)

    append-statement j.expr j.callf iter-func-name

    # When the condition fails => continue with commands after the WHILE loop
    set-sequence if-stmt.alternate
    append-statement j.expr j.callf cont-func-name

    # After defining the while loop, call it to start the first iteration
    set-sequence orig-sequence
    append-statement j.expr j.callf iter-func-name

    set-sequence cont-func.body

    # while (condition) {
    #   statement1
    #   return ret-expr
    #   next
    #   break
    #   statement4
    # }

    # iter = ->
    #   if condition
    #     statement1
    #     callback(ret-expr) # return
    #     iter! # next
    #     return # break
    #     iter!
    # iter!


    return

  convert-block-statement = (node) ->
    new-body = []
    for item in node.body
      if new-item = convert-contents(item)
        new-body.push(new-item)
    node.body = new-body
    node

  # Introduce a new variable, and a new assignment, in order to have the original
  # value when it's actually needed after all the async operations have finished.
  extract-as-assignment = (expr) ->
    #console.log "EXTRACT-AS-ASSIGNMENT", expr
    if expr.type == 'Literal'
      expr
    else
      if contains-await(expr)
        temp-var-name = issue-tmp-var-name!
        new-expr = convert-contents(expr)
        #if temp-var-name == 'tmp5'
          #console.log "old-expr: ", expr
          #console.log "new-expr: ", new-expr
          #process.exit()
        append-statement j.var(temp-var-name, new-expr)
        j.id(temp-var-name)
      else
        expr

  extract-as-assignment-unless-literal = (expr) ->
    if expr.type == 'Literal'
      expr
    else
      temp-var-name = issue-tmp-var-name!
      append-statement j.var(temp-var-name, convert-contents(expr))
      j.id(temp-var-name)


  new-body = convert-contents func.body

  if ! is-program && callback-name && ! sequence-closed!
    append-statement j.expr j.callf callback-name
  if is-program
    #console.log "main-sequence", main-sequence
    func.body = main-sequence.body
  else
    func.body = main-sequence
  func

function-already-handles-callback = (func) ->
  condition = (node) ->
    return false unless is-obj(node)
    return false unless node.type == 'CallExpression'
    node.callee && node.callee.type == 'Identifier' && node.callee.name == 'callback'
  found = false
  for-objects-with-condition func, condition, ->
    found := true
  found





#            ██╗   ██╗████████╗██╗██╗
#            ██║   ██║╚══██╔══╝██║██║
#            ██║   ██║   ██║   ██║██║
#            ██║   ██║   ██║   ██║██║
#            ╚██████╔╝   ██║   ██║███████╗
#             ╚═════╝    ╚═╝   ╚═╝╚══════╝

is-arr = (x) -> Object.prototype.toString.call(x) == '[object Array]'
is-obj = (x) -> Object.prototype.toString.call(x) == '[object Object]'
is-num = (x) -> Object.prototype.toString.call(x) == '[object Number]'
is-bool = (x) -> Object.prototype.toString.call(x) == '[object Boolean]'
is-null = (x) -> Object.prototype.toString.call(x) == '[object Null]'
is-str = (x) -> Object.prototype.toString.call(x) == '[object String]'
is-undef = (x) -> Object.prototype.toString.call(x) == '[object Undefined]'

type = (x) -> Object.prototype.toString.call(x).match(/\[object (.*)\]/)[1]

for-objects-with-property = (tree, pname, pvalue, callback) ->
  switch type(tree)
  case 'Array'
    for item in tree
      for-objects-with-property(item, pname, pvalue, callback)
  case 'Object'
    if tree[pname] == pvalue
      callback tree
    for key, item of tree
      for-objects-with-property(item, pname, pvalue, callback)

for-objects-with-condition = (tree, condition, callback) ->
  switch type(tree)
  case 'Array'
    #console.log "Array(#{tree.length})"
    for item in tree
      for-objects-with-condition(item, condition, callback)
  case 'Object'
    #console.log "Object :: #{tree.type} - #{JSON.stringify(tree).substr(0, 100)}"
    if condition(tree)
      callback tree
    for key, item of tree
      for-objects-with-condition(item, condition, callback)

for-objects-with-condition2 = (tree, opts, level = 0) ->
  {condition, stop-condition, callback} = opts
  switch type(tree)
  case 'Array'
    #console.log "Array(#{tree.length})"
    for item in tree
      for-objects-with-condition2(item, opts, level + 1)
  case 'Object'
    #console.log "Object :: #{tree.type} - #{JSON.stringify(tree).substr(0, 100)}"
    unless level == 0
      if stop-condition && stop-condition(tree)
        return
    if condition(tree)
      callback tree
    for key, item of tree
      for-objects-with-condition2(item, opts, level + 1)

random-string = (length = 10) -> # length 10 fits on <64 bits
  chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  n = chars.length
  s = ''
  for i from 1 to length
    s += chars[Math.floor(Math.random! * n)]
  s


dbg = -> JSON.stringify(...arguments).substr(0,140)

last = (a) -> a[a.length-1]

