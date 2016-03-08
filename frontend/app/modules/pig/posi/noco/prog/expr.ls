{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'
prog = posi.module "noco/prog/-module"

module.exports = h = expr-handler =

  # Caller want to create/convert a node to expr.
  # Ask for user info then return the actual subtype to the caller.
  # Caller creates/converts node to this type, then calls the callback we provide (apply-cb).
  # In the callback we apply any custom behaviour defined in the handler based on the match.
  #
  select-as-target: ({$el,parent}) -> promise 'expr.select-as-target', $el, (d) ->
    prog.surch({$el,parent,title:'expression'}) |> c d,
      done: (m) -> expr-handler.resolve-with-match(d, m)

  resolve-with-match: (d, m) ->
    # Resolve with:
    #
    # - type:  caller will create a node with this type or
    #          convert a blank to this type
    #
    # - apply-cb:  caller will call this with a node, so we
    #              can execute the custom behaviour based on
    #              the match
    d.resolve do
      node-type: (node-type = expr-handler.type-from-match(m))
      apply-cb: expr-handler.apply-cb-from-match(m)

  apply-cb-from-match: (m) ->
    return m.apply-cb if m.apply-cb
    (node) ->
      match-h = posi.handler-for(m.handler-node)
      if match-h && (f = match-h.apply-surch-result)
        f(node, m)

  type-from-match: (m) ->
    node-type =
      m.node-type ||
      m.type ||
      (m.node if m.node.type! == n.ntyp) ||
      (m.handler-node if m.handler-node.type! == n.ntyp)
    if ! node-type
      console.log "match:", m
      throw "Couldn't find node type in match"
    node-type


  # Returns the type of the expression as a node
  get-expr-type: (node) ->
    console.log 'get-expr-type', node.inspect!
    handler = posi.handler-for(node.type!)
    if handler && (get-expr-type = handler.get-expr-type)
      if nominal-type = get-expr-type(node)
        type-handler = composer-type-handler(nominal-type)
        if get-effective-type = type-handler?.get-effective-type
          # Effective type: the one the variable will hold from the POV of user,
          # and on which the UI will base autocompletion
          # e.g. box<Node> => Node
          return get-effective-type(nominal-type)
        else
          return nominal-type


composer-type-handler = (type-node) ->
  if is-composed-type type-node
    handler = posi.handler-for(type-node.type!)


is-composed-type = (type-node) ->
  type-node.type! != n.data-type-r


