{promise,c} = u = require 'lib/utils'
{map,each,filter,any,concat,join,elem-index,sort-by,maximum} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
cursor = require 'modules/pig/posi/cursor'
surch-utils = require 'modules/pig/posi/surch-utils'

op-symbols = "./!%^&*-+=/<>[\\:\("

module.exports = h = prog =
  keyCommands: ->
    return
      defaults:
        group: 'prog'
      commands: [
        * key: 'i'
          label: 'insert'
          name: 'Insert before statement'
          desc: 'Create a new statement before the current one.'
          cmd: ->
            node = posi.cursor.node
            parent = node.parent!
            console.log "parent.type", parent.type!.inspect!
            if (parent.type! == n.sequence) || (parent.type! == n.block)
              sequence = parent
              # a) [CHOSEN] INSERT a BLANK node
              #   - simpler to implement
              # b) create blank DOM element & when completed => INSERT; when cancelled => REMOVE
              blank = sequence.cAddComponent(n.item-r, n.blank, null, before-ref: node.parent-ref!)
              $blank = posi.$node(blank).find('.blank')
              posi.complete-blank-p($blank)
      ]

  onKey: (keycode, ev) ->
    char = keycode
    if char && char.length == 1 && op-symbols.indexOf(char) != -1
      prog.surch-on-current-elem char
    else
      false

  surch-on-current-elem: (char) ->
    cursor = posi.cursor
    node = cursor.node or throw "no current node"
    parent = cursor.parent or throw "no parent"

    if char == '.' && (expr-type = get-expr-type(node)) && ((expr-type-type = expr-type.type!) == n.struct-type || expr-type-type == n.class || expr-type-type == n.this)
      handle-dot {node, parent, expr-type, expr-type-type}

    else if char == '['
      create-index {node, parent}

    else if char == '('
      create-dynfcall {node, parent}

    else
      prog.surch do
        title: 'expression'
        help: 'Search for an operator, statement, function to wrap the current expression with. ' +
              'E.g. if the current expression is "x" and you select "return", it will make "return x"; ' +
              'if you select "+", it will make "x + _"'
        initialChars: (if char == '\\' then '' else char)
        $el: cursor.$currentElem
        parent: parent
        node: node
      .done (m) ->
        wrap-with-surch-result(node, m, {parent})

  surch-with-remaining-chars: (remaining-chars) ->
    if posi.cursor?.node?
      prog.surch-on-current-elem(remaining-chars)


  # opts:
  #   - parent - parent node to check for variables in scope
  #   see posi.surch for other options
  surch: (opts) -> promise (d) ->
    take-remaining-chars = ->
      if c = prog.surch-remaining-chars
        prog.surch-remaining-chars = undefined
        c

    posi.surch!.start do
      u.merge opts,
        initialChars: opts.initialChars || take-remaining-chars!
        search: (q) ->
          surch-literals q,
            fallback: ~>
              prepare-index!
              search(q) ++ surch-in-scope(q, opts.parent)
        keyCommands: [
          * key: 'C-v'
            name: 'Create variable'
            cmd: (q, deferred) ->
              posi.handler-for(n.variable).create-in-closest-scope(opts.parent, q, deferred)
          * key: 'C-f'
            name: 'Create function'
            cmd: (q, deferred) ->
              posi.handler-for(n.function).create-in-closest-scope(opts.parent, q, deferred)
          * key: 'C-n'
            name: 'Native function call'
            cmd: (q, deferred) ->
              if opts.parent
                if opts.node
                  # Wrap
                  wrap-node-and-select opts.node, opts.parent, n.natfcall, n.subject-r, (new-node) ->
                    name = q.trim!.match(/($|^[\.])(.*)/)[2]
                    new-node.cSetName(name)
                else
                  deferred.resolve do
                    node-type: n.natfcall
                    apply-cb: (new-node) ->
                      name = q.trim!
                      new-node.cSetName(name)
              else
                console.warn "Native function call cannot be executed as node or parent is missing", q, opts
          * key: 'C-e'
            name: 'Native expression'
            cmd: (q, deferred) ->
              deferred.resolve do
                node-type: n.natexpr
                apply-cb: (new-node) ->
                  new-node.cSetAttr(n.value-a, q)
          * key: 'C-p'
            name: 'Native property'
            cmd: (q, deferred) ->
              deferred.resolve do
                node-type: n.natprop
                apply-cb: (new-node) ->
                  name = q.trim!.match(/($|^[\.])(.*)/)[2]
                  new-node.cSetName(name)
        ]
    |> c d,
      done: (m) ->
        if m.remainingChars
          prog.surch-remaining-chars = m.remainingChars
          remaining-chars = m.remainingChars
          delete m.remainingChars
          u.next-tick ->
            delete prog.surch-remaining-chars
            prog.surch-with-remaining-chars remaining-chars
        d.resolve m

  surch-literal: (opts) ->
    posi.surch!.start do
      u.merge opts,
        search: (q) ->
          surch-literals q

  wrap-node: -> wrap-node(...arguments)

  unwrap: ($el, node) ->
    if node.is-a(n.expr)
      # find nearest expr ancestor
      iter-node = node
      loop
        iter-node = iter-node.parent!
        break if !iter-node
        break if iter-node.is-a(n.expr)
      if iter-node
        delee = iter-node
        new-parent = delee.parent!

        # Move node under the new-parent with tmp ref (clipboard)
        #parent-ref = node.parentRef!
        #parent-ref.cSetType(n.tmp-r)
        node.cMove do
          source: new-parent
          ref-type: delee.parent-ref!.type!
          before-ref: delee.parent-ref!

        # Delete
        delee.cForceDelete!

        posi.cursor.update!

  find-closest-scope: (node) ->
    iter-node = node
    while iter-node
      console.log "iter: ", iter-node.inspect!
      switch iter-node.type!
      case n.function    then return iter-node
      case n.jsmodule    then return iter-node
      case n.computed-box then return iter-node
      case n.compute then return iter-node
      case n.application then return iter-node
      iter-node = iter-node.parent!
    throw "no scope found for creating a variable"

index-status =
  ready: false

search-index = []

prepare-index = ->
  prepare-once index-status, ->
    repo.instanciate-all-nodes-with-types [n.function, n.operator, n.struct-type, n.symbol, n.class, n.data-type]
    search-index := []
    #n.expr.compatible-types! |> each (node) ->
      #add node, 'command', node
    n.statement.compatible-types! |> each (node) ->
      add node, 'command', node
    #n.prog.rns(n.ctns) |> each (node) ->
      #switch node.type!
      #case n.ntyp
        #if node.is-subtype-of(n.expr) || node.is-subtype-of(n.statement)
          #add node, 'command', node

    repo.nodes |> prelude.Obj.each (node) ->
      switch node.type!
      case n.operator    then
        if node.a(n.is-assign-a)
          add node, 'operator', n.assign
        else if node.a(n.is-update-a)
          add node, 'operator', n.update
        else
          add node, 'operator', n.op
      case n.function    then
        if is-unscoped node
          add node, 'function', n.fcall
        add node, 'function value', n.function-value
      case n.struct-type then add node, 'struct',   n.make-struct
      case n.symbol      then add node, 'symbol',   n.symref

    if n.react
      react = require '../react/-module'
      react.populateSearchIndex(search-index)


is-unscoped = (node) ->
  node.parent-ref!.type! != n.declaration-r

prepare-once = (status, f) ->
  unless status.ready
    f!
    status.ready = true

literal-stop-condition-func = (type) ->
  (chars) ->
    char = chars[0]
    if type != 'string'
      op-symbols.indexOf(char) >= 0

surch-literals = (q, opts = {}) ->
  fallback = ->
    if opts.fallback
      opts.fallback!
    else
      # No fallback mean, we need a literal
      mkLiteral 'string', q
  mkLiteral = (type, value) ~>
    [{
      keywords: ['' + value]
      kind: "literal"
      data_type: type
      value: value
      mowner_id: '814' # literal<node_type>
      nti: '814' # literal<node_type>
      node: n.literal
      handler-node: n.literal
      #stop-condition: literal-stop-condition-func(type)
    }]
  if (q == "T" || "true".indexOf(q) == 0 || "yes".indexOf(q) == 0)
    mkLiteral('boolean', true) ++ fallback!
  else if (q == "F" || "false".indexOf(q) == 0 || "no".indexOf(q) == 0)
    mkLiteral('boolean', false) ++ fallback!
  else if (q == "N" || "null".indexOf(q) == 0 || "nil".indexOf(q) == 0)
    mkLiteral('null', null) ++ fallback!
  else if (v = parseInt(q)) + '' == q
    mkLiteral 'integer', v
  else if (v = parseFloat(q)) + '' == q
    mkLiteral 'float', v
  else if q.substr(0, 1) == "'"
    mkLiteral 'string', q.substr(1)
  else
    fallback!

surch-in-scope = (q, node) ->
  throw "node missing" if !node
  collection = []

  add-variable = (variable) ->
    collection.push do
      # === VARIABLE match-record ===
      keywords: [variable.name!]
      kind: 'variable'
      name: variable.name!
      ni: variable.ni
      node: variable
      handler-node: n.varref

  add-variable-and-fields = (variable) ->
    add-variable(variable)
    # FIELDS OF VARIABLES
    if dt = variable.rn(n.data-type-r)
      switch dt.type!
      case n.struct-type
        for field in dt.rns(n.field-r)
          collection.push do
            keywords: [field.name!, "#{variable.name!}.#{field.name!}"]
            kind: 'field'
            name: ["#{variable.name!}.#{field.name!}"]
            node: field,
            node-type: n.select
            handler-node: n.varref
            subject: variable
      case n.class
        for meth in dt.rns(n.method-r)
          collection.push do
            keywords: [meth.name!, "#{variable.name!}.#{meth.name!}"]
            kind: 'method'
            name: ["#{variable.name!}.#{meth.name!}"]
            node: meth,
            node-type: n.fcall
            handler-node: n.fcall
            subject: variable
        for field in dt.rns(n.field-r)
          collection.push do
            keywords: [field.name!, "#{variable.name!}.#{field.name!}"]
            kind: 'field'
            name: ["#{variable.name!}.#{field.name!}"]
            node: field,
            node-type: n.select
            handler-node: n.varref
            subject: variable

  add-class-field = (field) ->
    collection.push do
      # === CLASS FIELD match-record ===
      keywords: [field.name!, "this.#{field.name!}"]
      kind: 'field'
      name: "this.#{field.name!}"
      ni: field.ni
      node: field
      handler-node: n.varref
      node-type: n.select
      subject: 'this'

  add-function = (node) ->
    collection.push record-for node, 'function', n.fcall

  add-declarations = (node) ->
    node.rns(n.declaration-r) |> each (declaration) ->
      switch declaration.type!
      case n.function
        # TODO: don't find scoped function outside the scope
        # scoped function = a function declared within another function
        # static function = a function declared within an application/library/module
        # function expression = a function declared within an expression
        add-function declaration
      case n.variable
        add-variable-and-fields(declaration)

  add-variable(n.it-variable)

  iter-node = node
  loop
    switch iter-node.type!
    case n.function, n.cmethod, n.computed-box, n.compute, n.application
      func = iter-node

      # VARIABLES
      func.rns(n.variable-r) |> each (variable) ->
        add-variable-and-fields(variable)

      # PARAMETERS
      sig = func.rn(n.function-signature-r)
      if sig
        sig.rns(n.parameter-r) |> each (variable) ->
          add-variable-and-fields(variable)

      # DECLARATIONS
      add-declarations func

    case n.jsmodule
      add-declarations iter-node

    case n.class
      klass = iter-node
      klass.rns(n.field-r) |> each (field) ->
        add-class-field(field)
      klass.rns(n.method-r) |> each (meth) ->
        # this.METHOD
        if meth.name!
          collection.push do
            keywords: [meth.name!, "this.#{meth.name!}"]
            kind: 'method'
            name: ["this.#{meth.name!}"]
            node: meth,
            type: n.fcall
            handler-node: n.fcall
            subject: 'this'

    # Don't go higher than application
    break if iter-node.type! ==  n.application

    iter-node = iter-node.parent!
    break if ! iter-node

  collection |> filter (entry) ->
    match-keywords(q, entry.keywords)

record-for = (node, kind, handler-node) ->
  # === GENERIC match-record ===
  keywords: surch-utils.keywords-for-node(node)
  kind: kind
  name: node.name!
  ni: node.ni
  node: node
  handler-node: handler-node
  #stop-condition: stop-condition-for(node, kind, handler-node)

stop-condition-for = (node, kind, handler-node) ->
  (chars) ->
    char = chars[0]
    if kind == 'operator'
      /^[a-zA-Z0-9_]$/.test(char)

add = (node, kind, handler-node) ->
  search-index.push record-for node, kind, handler-node

search = (q) ->
  search-index |> filter (entry) ->
    match-keywords(q, entry.keywords)

match-keywords = (q, keywords) ->
  match-found = false
  keywords |> each (keyword) ->
    if keyword.index-of(q) == 0
      match-found := true
      return false
  match-found

# Before:
#     parent---r1---node
# After:
#     parent---r1---<node-type>---rfirst---node
#     (rfirst: new-ref-type || first reftype found in the dom)
#
wrap-node = ({node, parent, node-type, apply-cb, new-ref-type}) -> pig.activity 'Wrap', ->

  parent-ref = node.parentRef!
  ref-type = parent-ref.type!

  #console.log "parent-ref", parent-ref, parent-ref.ri, parent-ref.sni, parent-ref.gni
  #console.log "siblings", (parent-ref.source!.refsWithType(parent-ref.type!) |> map (r) -> r.ri)
  before-ref = parent-ref.next-sibling!
  #console.log "before-ref", before-ref, before-ref.ri, before-ref.sni, before-ref.gni

  # 1. cut current node (move to clipboard)
  #console.log "1. cut current node - set ri", parent-ref.ri, "type to tmp"
  parent-ref.cSetType(n.tmp-r)

  # 2. create node
  #console.log "2. create node from search result"

  new-node = parent.cAddComponent ref-type, node-type, null, {before-ref}
  apply-cb(new-node) if apply-cb

  # 3. paste in the first blank
  #    - get first blank ref
  $new-node = posi.$node(new-node)
  $new-node.length > 0 or throw "$new-node not found"

  unless new-ref-type
    new-ref-type := posi.optional-handler-property(node-type, 'wrap-ref-type')

  unless new-ref-type
    $blank = posi.find-elements-within($new-node, '.posi-prop .blank', '.posi-node')[0]
    ($blank && $blank.length > 0) or throw "$blank not found"
    $reft = $blank.closest('.posi-reft')
    $reft.length > 0 or throw "$reft not found"
    rti = $reft.data('rti') or throw "rti missing on $reft"
    new-ref-type := repo.node(rti) or throw "node with rti #{rti} not found"

  #sref = new-node.type!.schema!.refs![0]
  #new-ref-type = sref.rt
  #console.log "paste into the first blank"
  node.cMove({source: new-node, ref-type: new-ref-type})
  $new-node = posi.$node(new-node)
  {new-node,$new-node}


wrap-with-surch-result = (node, m, {parent}) ->
  return if m.skip
  expr-handler = require 'modules/pig/posi/noco/prog/expr'
  node-type = expr-handler.type-from-match(m)
  apply-cb = expr-handler.apply-cb-from-match(m)

  {$new-node,new-node} = wrap-node({node, parent, node-type, apply-cb})

  posi.cursor.set $new-node
  posi.complete-node-p($new-node)
    .done ->
      posi.resume!

get-expr-type = (node) ->
  posi.handler-for(n.expr).get-expr-type(node)

handle-dot = ({node, parent, expr-type, expr-type-type}) ->
  switch expr-type-type
  case n.struct-type
    posi.handler-for(n.field).select-field(expr-type)
      .done (selected-field) ->
        wrap-node-and-select node, parent, n.select, n.subject-r, (new-node) ->
          new-node.cAddLink(n.field-r, selected-field)
  case n.class
    posi.handler-for(n.class).select-property(expr-type)
      .done (selected) ->
        switch selected.type!
        when n.field
          wrap-node-and-select node, parent, n.select, n.subject-r, (new-node) ->
            new-node.cAddLink(n.field-r, selected)
        when n.function # method call
          wrap-node-then-complete-reft do
            node: node
            parent: parent
            node-type: n.fcall
            new-ref-type: n.subject-r
            ref-type-to-complete: n.func-arg-r
            apply-cb: (new-node) ->
              new-node.cAddLink(n.callee-r, selected)
              fcall-h = posi.module 'noco/prog/fcall'
              fcall-h.populate-args-from-func-params({fcall: new-node, func: selected})
        else ...
  else ...

create-dynfcall = ({node, parent}) ->
  wrap-node-then-add-to-reft do
    node: node
    parent: parent
    node-type: n.dynfcall
    new-ref-type: n.callee-r
    ref-type-to-add-to: n.func-arg-r

create-index = ({node, parent}) ->
  wrap-node-then-add-to-reft do
    node: node
    parent: parent
    node-type: n.index
    new-ref-type: n.subject-r
    ref-type-to-add-to: n.index-r

wrap-node-and-select = (node, parent, node-type, new-ref-type, apply-cb) ->
  {new-node,$new-node} = wrap-node({node, parent, node-type, new-ref-type, apply-cb})
  posi.select-node(new-node)

add-to-reft-then-select = ($new-node, new-node, reft) ->
  bNode = new posi.br.BNode($new-node)
  bNode.add-to-reft({reft})
    .done (r) ->
      posi.cursor.set(posi.$node(new-node))

wrap-node-then-add-to-reft = ({node, parent, node-type, new-ref-type, ref-type-to-add-to, apply-cb}) ->
  {new-node,$new-node} = wrap-node({node, parent, node-type, new-ref-type, apply-cb})
  add-to-reft-then-select $new-node, new-node, ref-type-to-add-to

wrap-node-then-complete-reft = ({node, parent, node-type, new-ref-type, ref-type-to-complete, apply-cb}) ->
  {new-node,$new-node} = wrap-node({node, parent, node-type, new-ref-type, apply-cb})
  complete-reft-then-select $new-node, new-node, ref-type-to-complete

complete-reft-then-select = ($new-node, new-node, ref-type-to-complete) ->
  $reft = posi.find-reft-el $new-node, ref-type-to-complete
  posi.complete-all-blanks $reft
    .done (r) ->
      posi.cursor.set(posi.$node(new-node))

