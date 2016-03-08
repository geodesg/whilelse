{each,map,find,filter} = require 'prelude-ls'
module.exports = j = {}

j.prog = -> { type: 'Program', body: aa(arguments) }
j.var = (name, init) ->
  type: 'VariableDeclaration'
  declarations: [ j.decl(name, init) ]
  kind: 'var'
j.decl = (name, init) -> { type: 'VariableDeclarator', id: j.id(name), init: init }
j.id = (name) -> { type: 'Identifier', name }
j.call = (callee, ...args) -> { type: 'CallExpression', callee: callee, arguments: aa(args) }
j.callf = (func-name, ...args) -> j.call j.id(func-name), ...args
j.callm = (obj, prop, ...args) -> j.call j.prop(obj, prop), ...args
j.lit = (value) -> { type: 'Literal', value: value }
j.memb = (obj, prop) -> { type: 'MemberExpression', computed: false, object: obj, property: prop }
j.prop = (obj-name, prop-name) -> j.memb(j.id(obj-name), j.id(prop-name))
j.index = (obj, prop) -> { type: 'MemberExpression', computed: true, object: obj, property: prop }
j.for = (init, test, update, ...statements) -> { type: 'ForStatement', init, test, update, body: j.block(...statements) }
j.block = (...statements) -> { type: 'BlockStatement', body: aa(statements) }


j.req = (name) -> j.var(name, j.callf('require', j.lit(name)))
j.func = (name, param-names, defaults, ...statements) ->
  type: 'FunctionDeclaration'
  id: (if name then j.id(name) else null)
  params: (param-names |> map (param-name) -> j.id(param-name))
  defaults: defaults
  body:
    type: 'BlockStatement'
    body: aa(statements)
j.func-expr = (name, param-names, defaults, ...statements) ->
  type: 'FunctionExpression'
  id: (if name then j.id(name) else null)
  params: (param-names |> map (param-name) -> j.id(param-name))
  defaults: defaults
  body:
    type: 'BlockStatement'
    body: aa(statements)
j.return = (expr) -> { type: 'ReturnStatement', argument: expr }
j.obj = (obj) ->
  g-props = []
  for name, expr of obj
    g-props.push do
      type: 'Property'
      key: j.id(name)
      computed: false
      value: expr
  type: 'ObjectExpression'
  properties: g-props
j.bin = (operator, left, right) ->
  type: 'BinaryExpression'
  operator: operator
  left: left
  right: right
j.update = (operator, argument, prefix = false) -> { type: 'UpdateExpression', operator, argument, prefix }
j.binm = (operator, ...args) ->
  a = aa(args)
  #console.log "j.binm", operator, args, a, a.length
  if a.length == 1
    a[0]
  else if a.length == 2
    j.bin(operator, ...args)
  else if a.length > 2
    j.bin(operator, j.binm(operator, ...a.slice(0,-1)), a[a.length-1])
  else
    throw "#{a.length} arg given to j.binm"
j.concat = -> j.binm('+', ...arguments)
j.switch = (discriminant, ...cases) -> { type: 'SwitchStatement', discriminant: discriminant, cases: cases }
j.case = (test, ...consequent) -> { type: 'SwitchCase', test: test, consequent: consequent }
j.expr = (expr) -> { type: 'ExpressionStatement', expression: expr }
j.assign = (name, expr) -> { type: 'AssignmentExpression', operator: '=', left: j.id(name), right: expr }
j.op-assign = (operator, name, expr) -> { type: 'AssignmentExpression', operator, left: j.id(name), right: expr }


# Arguments to array
aa = (arg) ->
  Array.prototype.slice.call arg
