{ifnn,each-with-index} = u = require 'lib/utils'
{map,each,find,concat,filter,join,fold1,elem-index,any,compact} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
j = require 'modules/pig/posi/javascript-generator'


modify-last-item = (list, cb) ->
  item = list[list.length - 1]
  new-item = cb(item)
  list.slice(0, list.length - 1) ++ [new-item]

collected-els = []
included-declarations = {}

genjs-top = (node, {is-module} = {}) ->
  collected-els := []
  included-declarations := {}
  el = genjs(node, {is-module})
  els = u.to-array(el)
  if is-module && node.type! in [n.function, n.class]
    x = els.pop!
    x = j.expr j.assign-prop 'module', 'exports', x
    els.push x
  type: 'Program'
  body: collected-els ++ u.to-array(el)


member-expression = (object-node, property-identifier) ->
  j.memb do
    genjs object-node
    j.id property-identifier

bracket-member-expression = (object-node, property) ->
  j.index do
    genjs object-node
    genjs property

options = {}
with-option = (name, value, cb) ->
  orig = options[name]
  options[name] = value
  ret = cb!
  options[name] = orig
  ret

genjs = (node, opts = {}) ->
  {as,is-method} = opts
  if ! node
    throw "missing node"

  switch node.type!

  when n.function
    sig  = node.rn(n.function-signature-r)
    params = sig.rns(n.parameter-r)

    g-func-body = function-body(node, {is-method})
    g-params = params |> map (param) ->
        j.id declared-name param

    if node.a(n.async-a) || opts.async
      #g-func-body = j.block j.expr j.callf '__ASYNC', g-func-body
      g-params.push j.id '__ASYNC'

    name =
      if opts.function-name
        j.id(opts.function-name)
      else if as != 'expression' || node.name!
        j.id(declared-name(node))
      else
        null

    type: (as == 'expression' && 'FunctionExpression' || 'FunctionDeclaration')
    id: name
    params: g-params
    defaults: []
    body: g-func-body

  when n.jsmodule
    g-func-body = function-body(node)

    j.expr j.assign-prop 'module', 'exports', j.call j.func-expr null, [], [], ...g-func-body.body

  when n.sequence
    items = node.rns(n.item-r)

    j.call do
      j.func-expr null, [], [],
        items |> map (p) ->
          j.expr genjs(p)
        |> modify-last-item _, (el) ->
          type: 'ReturnStatement'
          argument: el['expression']

  when n.op
    args = node.rns(n.op-arg-r)
    operator = node.rn(n.operator-r) || u.err "missing operator for #{node.inspect!}"
    #console.log "ARGS", args
    elements = args |> map (arg) -> genjs(arg)

    switch operator

    when n.map-o
      include-declaration n.map-f
      j.callf 'map', elements[0], elements[1]

    when n.range-o
      include-declaration n.range-f
      j.callf 'range', elements[0], elements[1]

    else

      keyword = operator.rn(n.keyword-r)
      if keyword
        op-symbol = keyword.a(n.value-a) || u.err "no keyword value for #{keyword.inspect!}"
      else
        op-symbol = '+' || u.err "no keyword or name for operator #{operator.inspect!}"

      required-argnum =
        if operator.a(n.is-unary-a)
          1
        else
          2
      if args.length == required-argnum
        if operator.a(n.is-unary-a)
          type: 'UnaryExpression'
          operator: op-symbol
          argument: elements[0]
        else
          type: 'BinaryExpression'
          operator: op-symbol
          left: elements[0]
          right: elements[1]
      else
        u.err "op should have #{required-argnum} arguments, but has #{args.length}"


  when n.literal
    v = node.a(n.literal-value-a)
    v = null if v == undefined
    if u.is-number(v) && v < 0
      type: 'UnaryExpression'
      operator: '-'
      argument: j.lit -v
      prefix: true
    else
      j.lit v

  when n.expr
    u.err('incomplete')

  when n.varref
    if va = node.rn(n.variable-r)
      if va == n.it-variable && options.it
        options.it
      else if options.react
        # prepend this.state or this.props
        ref = va.parentRef!
        base-obj =
          switch ref.type!
          when n.react-prop-var-r then j.prop 'this', 'props'
          when n.react-state-var-r then j.prop 'this', 'state'
        if base-obj
          j.memb base-obj, j.id declared-name(va)
        else
          j.id declared-name(va)
      else
        j.id declared-name(va)
    else
      u.err "varref #{node.inspect!} doesn't reference a variable"

  when n.closure
    genjs node.rn(n.closure-function-r), as: 'expression'

  when n.assign
    lval = node.rn(n.lvalue-r)
    rval = node.rn(n.rvalue-r)
    operator = node.rn(n.operator-r)
    rval-el = genjs rval
    lval-el = genjs lval
    switch operator
    when undefined, null, n.assign
      # Set reactive box value
      if lval.type! == n.select &&
          (data-type-nt = (field = lval.rn(n.field-r))?.rn(n.data-type-r)?.type!) &&
          (data-type-nt == n.box || data-type-nt == n.computed-box)
        subject = lval.rn(n.subject-r)
        j.call j.memb(genjs(subject), j.id("#{field.name!}$set")), rval-el
      else
        type: 'AssignmentExpression'
        operator: '='
        left: lval-el
        right: rval-el
    when n.append-o
      j.call j.memb(lval-el, j.id('push')), rval-el
    else
      type: 'AssignmentExpression'
      operator:
        if operator
          keyword = operator.rn(n.keyword-r) || u.err "no keyword for operator #{operator.inspect!}"
          op-symbol = keyword.a(n.value-a) || u.err "no keyword value for #{keyword.inspect!}"
          op-symbol
        else
          '='
      left: lval-el
      right: rval-el

  when n.update
    lval = node.rn(n.lvalue-r)
    operator = node.rn(n.operator-r) || u.err "no operator for update expression #{node.inspect!}"
    lval-el = genjs lval
    type: 'UpdateExpression'
    operator:
      if operator
        keyword = operator.rn(n.keyword-r) || u.err "no keyword for operator #{operator.inspect!}"
        op-symbol = keyword.a(n.value-a) || u.err "no keyword value for #{keyword.inspect!}"
        op-symbol
    argument: lval-el


  when n.if
    cond = node.rn(n.condition-r) || u.err "condition missing"
    b-then = node.rn(n.then-r) || u.err "then branch missing"
    b-else = node.rn(n.else-r) #|| u.err "else branch missing"
    type: 'IfStatement'
    test: genjs(cond)
    consequent: genjs(b-then)
    alternate:
      if b-else
        genjs(b-else)
      else
        j.lit null

  when n.while
    cond = node.rn(n.condition-r) || u.err "condition missing"
    body = node.rn(n.body-r) || u.err "body missing"
    type: 'WhileStatement'
    test: genjs(cond)
    body: genjs(body)

  when n.fcall
    callee = node.rn(n.callee-r) || u.err "callee missing"
    subject = node.rn(n.subject-r)

    ensure-function-present callee

    args = node.rns(n.func-arg-r)
    g-args = args |> map (arg) -> if expr = arg.rn(n.arg-expr-r) then genjs expr
                  |> compact

    g-normal-call =
      j.call do
        if subject
          # Call method on an object
          j.memb genjs(subject), j.id declared-name callee
        else
          # Plain function call
          j.id declared-name callee
        ...g-args

    if callee.a(n.async-a)
      j.call do
        j.id '__AWAIT'
        g-normal-call
    else
      g-normal-call

  when n.new
    klass = node.rn(n.data-type-r) || u.err "class missing"
    include-declaration klass

    # Find constructor and args
    args = node.rns(n.func-arg-r)
    g-args = args |> map (arg) ->
                      expr = arg.rn(n.arg-expr-r) || u.err "arg-expr missing"
                      genjs expr

    g-normal-call =
      j.new do
        j.id declared-name klass
        ...g-args

    g-normal-call

  when n.class
    name = declared-name node

    body = []
    body.push j.expr j.assign-prop name, 'displayName', j.lit name
    body.push j.var 'prototype', j.prop(name, 'prototype')

    #build-constructor-statements = ->
      #body = []
      #for field in node.rns(n.field-r)
        #body.push j.expr j.assign-this field.name!, j.lit(null) # TODO: use arg value
      #body

    # Constructor with Properties
    #body.push j.func name, [], [], ...build-constructor-statements!
    if construc = node.rn(n.constructor-r)
      gconstruc = genjs(construc, function-name: name, is-method: true)
    else
      gconstruc = j.func name, [], [], j.var('this$', j.this!)

    box-func     = repo.node('acpfOJVTN1mX')
    compute-func = repo.node('acHxOR4lo299')


    # Add box & compubox to constructor
    construc-init = []

    generateObjectId-func = construc.rns(n.declaration-r) |> find (d) -> d.type! == n.function && d.name! == 'generateObjectId'
    if generateObjectId-func
      construc-init.push do
        j.assign-prop 'this$', 'objectId',
          j.callf 'generateObjectId' # FIXME isn't always defined

    for field in node.rns(n.field-r)
      field-name = declared-name(field)
      if (data-type = field.rn(n.data-type-r)) && (data-type.type! == n.box || data-type.type! == n.computed-box)
        include-declaration box-func
        include-declaration compute-func if data-type.type! == n.computed-box
        construc-init.push do
          j.expr j.assign-prop 'this$', "#{field-name}$box",
            j.callf declared-name(box-func),
              j.bin('+', j.prop('this$', 'objectId'), j.lit("-#{field.ni}-#{field-name}")),
              j.id('undefined')
    gconstruc.body.body.splice(1, 0, ...construc-init)

    body.push gconstruc

    # Methods: prototype.f = function (...) { ... }
    for func in node.rns(n.method-r)
      body.push j.expr j.assign-prop 'prototype', declared-name(func), genjs(func, is-method: true)

    # Add getters/setters for box/computed-box
    for field in node.rns(n.field-r)
      field-name = declared-name(field)
      if (data-type = field.rn(n.data-type-r)) && (data-type.type! == n.box || data-type.type! == n.computed-box)
        box-name    = "#{field-name}$box"
        getter-name = "#{field-name}"
        setter-name = "#{field-name}$set"

        # Getter
        if data-type.type! == n.box
          # Getter for box
          body.push j.expr j.assign-prop 'prototype', getter-name,
            j.func-expr null, [], [],
              j.var 'this$', j.this!
              j.return j.call j.memb(j.prop('this$', box-name), j.id('get'))
        else
          # Getter for computed-box
          body.push j.expr j.assign-prop 'prototype', getter-name,
            j.func-expr null, [], [],
              j.var 'this$', j.this!
              j.if j.not(j.prop('this$', "#{box-name}Inited")),
                j.block do
                  j.expr j.assign-prop 'this$', "#{box-name}Inited", j.lit(true)
                  j.expr j.callf declared-name(compute-func),
                    j.bin('+', j.prop('this$', 'objectId'), j.lit("-#{field.ni}")),
                    j.func-expr null, [], [],
                      j.expr j.call j.memb(j.prop('this$', box-name), j.id('set')),
                        j.call j.func-expr null, [], [],
                          ...function-body(field.rn(n.data-type-r)).body

              j.return j.call j.memb(j.prop('this$', box-name), j.id('get'))

        #if data-type.type! == n.box # computed-box doesn't need a setter (it's computed)
        #FIXME: temporarily adding setter to computed-box until lazy-box is implemented

        # Setter
        body.push j.expr j.assign-prop 'prototype', setter-name,
          j.func-expr null, ['value'], [],
            j.expr j.assign 'this$', j.this!
            j.expr j.call j.memb(j.prop('this$', box-name), j.id('set')), j.id('value')

    body.push j.return j.id(name)
    if opts.is-module
      [
      j.var name, j.call j.func-expr(null, [], [], ...body)
      j.id name
      ]
    else
      j.var name, j.call j.func-expr(null, [], [], ...body)

  when n.compute
    compute-func = repo.node('acHxOR4lo299')

    j.expr j.callf declared-name(compute-func),
      j.bin('+', j.prop('this$', 'objectId'), j.lit("-#{field.ni}")),
      j.func-expr null, [], [],
        ...genjs(node.rn(n.implementation-r)).body

  when n.this
    j.id 'this$'
    #type: 'ThisExpression'


  when n.natfcall
    subject = node.rn(n.subject-r)
    callee = node.name!
    args = node.rns(n.func-arg-r)

    j.call do
      if subject
        member-expression subject, callee
      else
        j.id callee
      ...args |> map (expr) ->
        genjs expr

  when n.natprop
    subject = node.rn(n.subject-r)
    name = node.name!

    member-expression subject, name

  when n.dynfcall
    callee = node.rn(n.callee-r)
    args = node.rns(n.func-arg-r)

    j.call do
      genjs callee
      ...args |> map (expr) ->
        genjs expr

  when n.natexpr
    value = node.a(n.value-a)
    #console.log "Parsing expression: ", value
    g-expr = parse-expression "(#{value})"
    #console.log "Parsed expression:"
    #console.log JSON.stringify g-expr, null, 2
    g-expr

  when n.select
    subject = node.rn(n.subject-r)
    field   = node.rn(n.field-r)
    data-type-nt = field.rn(n.data-type-r)?.type!
    if data-type-nt == n.box || data-type-nt == n.computed-box
      # Call getter
      j.call j.memb(genjs(subject), j.id(declared-name(field)))
    else
      member-expression subject, declared-name(field)

  when n.make-array
    items = node.rns(n.item-r)
    type: 'ArrayExpression'
    elements: items |> map (item) -> genjs(item)

  when n.make-struct
    type: 'ObjectExpression'
    properties:
      [
        type: 'Property'
        key: j.id '_data_type'
        computed: false
        value: j.lit node.rn(n.subject-r).source-name!
      ] ++ (
        node.rns(n.make-struct-arg-r) |> map (arg) ->
          type: 'Property'
          key: j.id declared-name arg.rn(n.field-r)
          computed: false
          value: genjs arg.rn(n.op-arg-r)
      )

  when n.index
    subject = node.rn(n.subject-r)
    index = node.rn(n.index-r)
    bracket-member-expression subject, index

  when n.make-hash
    items = node.rns(n.item-r)
    type: 'ObjectExpression'
    properties: items |> map (item) -> genjs(item)

  when n.property
    ident = node.a(n.identifier-a)
    rvalue = node.rn(n.rvalue-r)
    type: 'Property'
    key:
      type: 'Literal'
      value: ident
    computed: false
    value: genjs(rvalue)

  when n.member
    subject = node.rn(n.subject-r)
    ident = node.a(n.identifier-a)
    member-expression subject, ident

  when n.for
    init = node.rn(n.init-r)
    cond = node.rn(n.condition-r)
    update = node.rn(n.update-r)
    body = node.rn(n.body-r)
    type: 'ForStatement'
    init: genjs init
    test: genjs cond
    update: genjs update
    body: genjs body

  when n.step
    v     = node.rn(n.loop-var-r)
    start = node.rn(n.start-r)
    end   = node.rn(n.end-r)
    step  = node.rn(n.step-by-r)
    body  = node.rn(n.body-r)
    type: 'ForStatement'
    init:
      type: 'AssignmentExpression'
      operator: '='
      left: genjs v
      right: genjs start
    test:
      j.bin '<=', genjs(v), genjs(end)
    update:
      if step
        j.op-assign '+=', genjs(v), genjs(step)
      else
        j.update '++', genjs(v)
    body: genjs body

  when n.application
    block = node.rn(n.implementation-r)
    genjs block, as: 'statements'
    #j.expr j.call genjs(func, as: 'expression')

  when n.block
    with-statements statements = [], ->
      node.rns(n.item-r) |> each (item) ->
        g-item = genjs item
        if is-js-expr(g-item.type)
          statements.push j.expr g-item
        else
          statements.push g-item
    if as == 'statements'
      statements
    else
      j.block ...statements

  when n.chain
    expr = genjs(node.rn(n.subject-r))
    for item in node.rns(n.item-r)
      expr = with-option 'it', expr, -> genjs(item)
    expr

  when n.function-expr
    genjs node.rn(n.function-r), as: 'expression'

  when n.function-value
    func = node.rn(n.function-r)
    ensure-function-present func
    j.id func.name!

  when n.return
    type: 'ReturnStatement'
    argument: genjs node.rn(n.arg-expr-r)

  when n['throw']
    type: 'ThrowStatement'
    argument: genjs node.rn(n.arg-expr-r)

  when n.object-expr
    type: 'ObjectExpression'
    properties: node.rns(n.property-r) |> map (prop) ->
      val = prop.a(n.key-a)
      type: 'Property'
      key: if val.match /^[a-zA-Z_][a-zA-Z0-9_]*$/ then j.id val else j.lit val
      computed: false
      value: genjs(prop.rn(n.rvalue-r))

  when n.switch
    cases = []
    var last-case
    for cas in node.rns(n.case-r)
      conds = cas.rns(n.condition-r)
      # Convert multiple conditions to separate cases, the last of which will have the statements
      #
      #    case a,b       -->   case a:
      #      statement          case b:
      #                           statement
      #                           break
      #
      for cond in conds #
        last-case =
          type: 'SwitchCase'
          test: genjs(cond)
          consequent: []
        cases.push last-case

      if conds.length == 0 # default statement
        last-case =
          type: 'SwitchCase'
          test: null
          consequent: []
        cases.push last-case

      last-case.consequent = genjs(cas.rn(n.then-r)).body
      last-case.consequent.push j.break!

    type: 'SwitchStatement'
    discriminant: genjs(node.rn(n.discriminant-r))
    cases: cases

  when n.break
    j.break!

  when n.continue
    j.continue!

  when n.disable
    type: 'EmptyStatement'

  when n.struct-type
    null

  when n.node-id-literal
    j.lit node.rn(n.refs)?.ni

  when n.node-literal
    # repo().nodes[X]
    include-declaration repo.node('ac9RKGGfhaQX') # repo function
    j.index do
      j.memb do
        j.callf 'repo'
        j.id 'nodes'
      j.lit node.rn(n.refs)?.ni

  when n.web-app
    endpoints = posi.handler-for(node.type!).collect-endpoints(node)

    type-spec = (t) ->
      switch t.type!
      case n.struct-type
        {
          type: 'hash'
          fields: t.rns(n.field-r) |> map (field) ->
            name: field.name!
            subtype: type-spec(field.rn(n.data-type-r))
        }
      case n.data-type
        {
          type: t.name!
        }
      else
        {
          type: t.name! || t.type!.name!
          error: 'unhandled'
        }

    g-coercion-spec = (func-node) ->
      sig-node = func-node.rn(n.function-signature-r) or u.err "no signature for #{func-node.inspect!}"
      param-nodes = sig-node.rns(n.parameter-r)

      spec = { type: 'hash', fields: [] }
      param-nodes |> map (param-node) ->
        data-type = param-node.rn(n.data-type-r) or u.err "no type for param #{param-node.inspect!}"
        spec.fields.push do
          name: param-node.name!
          subtype: type-spec(data-type)
      parse-expression "JSON.parse(#{JSON.stringify JSON.stringify(spec)})"


    ast = j.prog do
      j.req 'http'
      j.req 'url'
      parse-statement 'var GLOBALS = {};'
      parse-statement 'var port = parseInt(process.argv[2]);'
      j.func 'validateAndCoerceType', ['value', 'type'], [],
        j.return j.obj valid: j.lit(true), value: j.id('value')
      parse-statement '''
        function validateAndCoerce(value, spec, path) {
          switch (spec.type) {
            case 'string':
              return [true, value]

            case 'integer':
              v = parseInt(value);
              if ('' + v == value) {
                return [true, v]
              } else {
                return [false, [path + " should be an integer"]]
              }

            case 'hash':
              if (Object.prototype.toString(value) == "[object Object]") {
                var coerced = {};
                var n = spec.fields.length
                for (var i = 0; i < n; i++) {
                  var name = spec.fields[i].name;
                  var subspec = spec.fields[i].subtype;
                  if (path.length > 0) {
                    subpath = path + "[" + name + "]";
                  } else {
                    subpath = name;
                  }
                  r = validateAndCoerce(value[name], subspec, subpath);
                  if (r[0] === false) {
                    return r;
                  } else {
                    coerced[name] = r[1]
                  }
                }
                return [true, coerced];
              } else {
                return [false, [path + " should be a hash"]];
              }

            default:
              return [false, ["can't handle " + spec.type]];
          }
        }
      '''
      j.var 'server',
        j.callm('http', 'createServer',
          j.func-expr(null, ['request', 'response'], [],
            j.var 'parsedUrl', j.callm('url', 'parse', j.prop('request', 'url'), j.lit(true))
            j.var 'coercedRequest'
            j.var 'requestParams', j.prop('parsedUrl', 'query')
            j.var 'routeLine', j.concat(j.prop('request', 'method'), j.lit(' '), j.prop('parsedUrl', 'pathname'))
            parse-statement '''console.log(routeLine, requestParams);'''
            j.switch j.id('routeLine'),
              ...(
                endpoints |> map (endpoint) ->
                  j.case j.lit("#{endpoint.method} #{endpoint.path}"),
                    parse-statement '''coercedRequest = [];'''
                    j.var 'r', j.callf 'validateAndCoerce', j.id('requestParams'), g-coercion-spec(endpoint.func-node), j.lit('')
                    parse-statement '''
                      if (r[0]) {
                        for (name in r[1]) {
                          var value = r[1][name];
                          coercedRequest.push(value);
                        }
                      } else {
                        response.writeHead(403, { 'Content-Type': 'application/json' });
                        response.write(JSON.stringify({error:{messages:r[1]}}));
                        response.end("\\n");
                        return
                      }
                    '''
                    parse-statement '''console.log("Coerced Request:", coercedRequest);'''
                    j.var 'f', genjs(endpoint.func-node, as: 'expression', async: true)
                    j.var 'result', j.callf '__AWAIT', j.callf 'f', ...([0 to (endpoint.func-node.rn(n.function-signature-r).rns(n.parameter-r).length - 1)] |> map (i) -> j.index(j.id('coercedRequest'), j.lit(i)))
                    ...parse-statements '''
                      if (result._data_type == 'web/response-struct_type') {
                        response.writeHead(result.status, result.headers);
                        response.write(result.body);
                      } else {
                        content = JSON.stringify(result);
                        console.log("Response: ", content);
                        response.writeHead(200, { 'Content-Type': 'application/json' });
                        response.write(content);
                      }
                      response.end("\\n");
                      return
                    '''
              ),
              j.case null,
                ...parse-statements '''
                  response.writeHead(404, { 'Content-Type': 'application/json' });
                  response.write('{"error":{"message":"Not Found"}}');
                  response.end("\\n");
                  return
                '''
          )
        )
      parse-statement '''server.listen(port);'''
    ast

  when n.t-template # => function expression
    j.func-expr do
      declared-name node
      node.rns(n.t-param-r) |> map (.name!)
      []
      j.return genjs node.rn(n.t-block-r)

  when n.t-block # => string expression
    j.concat(
      ...(
        node.rns(n.t-element-r) |> map (template-element) -> genjs(template-element)
      )
    )

  when n.t-tag
    attr-list = node.rns(n.t-attribute-r) |> map (attribute) ->
      " #{htmlEscape attribute.a(n.t-attribute-name-a)}=\"#{htmlEscape attribute.a(n.t-attribute-value-a)}\""
    j.concat do
      j.lit "<#{node.a(n.t-tag-type-a)}#{attr-list.join!}>"
      genjs node.rn(n.t-block-r)
      j.lit "</" + node.a(n.t-tag-type-a) + ">" # syntax highlighting problems if interpolated

  when n.t-each
    arg-name = node.rn(n.t-arg-r).name!
    param-name = node.rn(n.t-param-r).name!
    j.call do
      j.func-expr do
        null
        []
        []
        j.var 's', j.lit ''
        j.var 'n', j.prop(arg-name, 'length')
        j.for do # for (var i=0; i<n; i++) { s += item[i] }
          j.var 'i', j.lit 0
          j.bin '<', j.id('i'), j.id('n')
          j.update '++', j.id 'i'
          j.var param-name, j.index(j.id(arg-name), j.id('i'))
          j.expr j.op-assign '+=', 's', genjs node.rn(n.t-block-r)
        j.return j.id 's'

  when n.t-param-slot
    j.id node.rn(n.t-param-r).name!

  when n.t-text
    j.lit node.a(n.t-text-value-a)

  when n.t-render # => expr (string value)
    callee = node.rn(n.t-template-r)
    include-declaration callee
    j.call do
      j.id declared-name(callee)
      ... node.rns(n.t-arg-r) |> map (arg) -> genjs arg.rn(n.arg-expr-r)

  when n.te-assert
    g-arg = genjs node.rn(n.arg-expr-r)
    js-arg = escodegen.generate j.prog j.expr g-arg
    #j.if j.not(g-arg),
      #j.callm 'console', 'log', j.lit "Assertion Failed: #{js-arg}"
      #j.callm 'console', 'log', j.lit "Assertion OK: #{js-arg}"
    j.if j.not(g-arg),
      j.callf 'testRecordResult', j.lit(false), j.lit(js-arg)
      j.callf 'testRecordResult', j.lit(true), j.lit(js-arg)

  when n.te-test
    init = parse-statements '''
      var testCurrentName;
      var testResults = { success: true, failures: [], passed: 0, failed: 0 };
      function testRecordResult(success, exprText, message) {
        if (success) {
          testResults.passed++;
        } else {
          testResults.failed++;
          testResults.success = false;
          testResults.failures.push({
            testName: testCurrentName,
            exprText: exprText,
            message: message
          });
        }
      }

    '''
    cases =
      node.rns(n.te-test-case-r) |> map (test-case) -> genjs test-case
      |> prelude.flatten
    finish = parse-statements '''
      console.log(JSON.stringify(testResults, null, 2));
    '''
    j.prog ...(init ++ cases ++ finish)

  when n.te-test-case
    init = [
      j.expr j.assign 'testCurrentName', j.lit node.a(n.desc)
    ]
    items = function-body(node).body
    init ++ items


  when n.react-app
    main-component = node.rn(n.react-main-r)
    declarations = [main-component] ++ node.rns(n.declaration-r)
    body = []
    for declaration in declarations
      body.push j.var declaration.name!, genjs declaration
    j.prog do
      j.var 'React', j.callf('require', j.lit('react'))
      ...body
      j.expr j.assign-prop 'module', 'exports', j.id main-component.name!

  when n.react-component
    state-vars = node.rns(n.react-state-var-r)
    prop-vars  = node.rns(n.react-prop-var-r)
    obj = {}
    if state-vars.length > 0
      initial-state = {}
      for v in state-vars
        if default-expr = v.rn(n.default-r)
          initial-state[javascriptize-name(v.name!)] = genjs(default-expr)
      obj.getInitialState = j.func-expr null, [], [],
        j.return j.obj initial-state
    obj.render = j.func-expr null, [], [],
      with-option 'react', true, ->
        genjs(node.rn(n.react-render-r)).body[0]
    j.callm 'React', 'createClass',
      j.obj(obj)

  when n.react-html-elem
    g-props = {}
    for prop in node.rns(n.react-prop-r)
      g-props[prop.a(n.react-name-a)] = genjs(prop.rn(n.react-value-r))
    g-children = []
    for child in node.rns(n.react-child-r)
      g-children.push genjs child

    j.callm 'React', 'createElement',
      j.lit node.a(n.react-name-a)
      j.obj g-props
      ...g-children

  when n.react-react-elem
    g-props = {}
    for prop in node.rns(n.react-prop-r)
      g-props[prop.a(n.react-name-a)] = genjs(prop.rn(n.react-value-r))
    g-children = []
    for child in node.rns(n.react-child-r)
      g-children.push genjs child

    j.callm 'React', 'createElement',
      j.id node.rn(n.react-class-r).name!
      j.obj g-props
      ...g-children
  else
    u.err "No javascript generator defined for this node type: #{node.type!.name!}"


gen-var-init = (datatype) ->
  return null if ! datatype
  switch datatype.type!
  when n.data-type
    switch datatype
    when n.integer-t then j.lit 0
    when n.float-t then j.lit 0
    when n.string-t then j.lit ''
    when n.boolean-t then j.lit false
    when n.nil-t then j.lit null
    when n.hash-t
      type: 'ObjectExpression'
      properties: []

    else u.err "Unknown data type: #{datatype.inspect!}"
  when n.struct-type
    type: 'ObjectExpression'
    properties: datatype.rns(n.field-r) |> map (field) ->
      type: 'Property'
      key: j.id field.name!
      value: gen-var-init(field.rn(n.data-type-r))
      kind: 'init'
      method: false
      shorthand: false
  when n.array-type
    type: 'ArrayExpression'
    elements: []


include-declaration = (node) ->
  unless included-declarations[node.ni]
    included-declarations[node.ni] = true
    collected-els.push genjs(node)

declared-name = (node) ->
  name = node.name!
  if name
    javascriptize-name name
  else
    "#{node.type!.name!}_#{node.ni}"

javascriptize-name = (name) ->
  name
   .replace /(?:[\-])(\w)/g, (_, c) -> c && c.toUpperCase! || ''
   .replace /[^a-zA-Z0-9_\$]/g, '_'

get-native-implementation = (node) ->
  # Check for native implementation
  #console.log "get-native-implementation", node.inspect!
  native-method =
    node.rns(n.node-method-r) |> find (native-method-candidate) ->
      #console.log "native-method-candidate", native-method-candidate.inspect!
      m = native-method-candidate.rn(n.method-type-r)
      l = native-method-candidate.rn(n.lang-r)
      #console.log m, l
      #m && l && m == n.native-implementation-m && l == n.javascript-lang
      m && m == n.native-implementation-m # don't worry about the language now, everything is Javascript
  if native-method
    code = native-method.a(n.native-code-a)
    #console.log "Code for #{node.inspect!}:"
    #console.log code
    code

code-to-ast = (code, wrap = true) ->
  esprima = require('lib/esprima')
  code = "(function () {\n#{code}\n})()" if wrap
  #console.log code
  ast = esprima.parse(code)
  if wrap
    ast = ast.body[0] # Program.body[0]
             .expression  # ExpressionStatement.expression
             .callee # CallExpression.callee
             .body # FunctionExpression.body => BlockStatement
  #console.log('code-to-ast', JSON.stringify(ast, null, 4));
  ast

parse-statement = (code) ->
  parse-statements(code)[0]

parse-statements = (code) ->
  #console.log "parse-statements", code
  esprima = require('lib/esprima')
  #console.log code
  ast = esprima.parse(code, tolerant: true)
  #console.log(JSON.stringify(ast, null, 4));
  ast.body

parse-expression = (code) ->
  #console.log "parse-expression", code
  esprima = require('lib/esprima')
  #console.log code
  var ast
  try
    ast = esprima.parse(code, tolerant: true)
  catch e
    throw "Error while parsing: #{e.message}: #{code}"
  #console.log(JSON.stringify(ast, null, 4));
  ast.body[0].expression

function-body = (node, {is-method} = {}) ->
  svars = node.rns(n.variable-r)
  impl = node.rn(n.implementation-r)
  setup-els = []
  if is-method
    setup-els.push j.var 'this$', j.this!
  declaration-els = svars |> map (svar) ->
    type: 'VariableDeclaration'
    declarations: [
      type: 'VariableDeclarator'
      id: j.id declared-name(svar)
      init: gen-var-init(svar.rn(n.data-type-r))
    ]
    kind: 'var'
  node.rns(n.declaration-r) |> each (declaration) ->
    switch declaration.type!
    case n.variable
      declaration-els.push do
        type: 'VariableDeclaration'
        declarations: [
          type: 'VariableDeclarator'
          id: j.id declared-name(declaration)
          init: gen-var-init(declaration.rn(n.data-type-r))
        ]
        kind: 'var'
    case n.function
      declaration-els.push genjs declaration
    else
      throw "Can't handle declaration type: #{declaration.type!}"

  [is-native, method] = function-is-native(node)
  if is-native
    native-code = get-native-implementation(node)
    code-to-ast(native-code) # => BlockStatement
  else if impl
    gimpl = genjs(impl)
    impl-els =
      if gimpl.type == 'BlockStatement'
        gimpl.body
      else
        [gimpl]
    type: 'BlockStatement'
    body: setup-els ++ declaration-els ++ impl-els
  else
    u.warn msg = "function #{node.inspect!} not implemented"
    type: 'BlockStatement'
    body: [
      j.throw j.lit msg
    ]

function-is-native = (node) ->
  is-native = node.a(n.implemented-natively-a)
  if is-native == undefined || is-native == true
    function-handler = posi.handler-for(n.function)
    method = function-handler.find-native-implementation-method(node)
    if is-native == undefined && method?
      is-native = true
    else if is-native == true && ! method?
      method = function-handler.find-native-implementation-method(node, create: false) # `true` causes infinite boxlib recursion
  [is-native, method]


ensure-function-present = (func) ->
  # Automatically include declaration for the function unless:
  #   - it's a method => it will be included with the class
  #   NO- it's a local/scoped function => it will be included with the parent function
  if func.parent!.type! != n.class #&& func.parent-ref!.type! != n.declaration-r
    include-declaration func

htmlEscape = (str) ->
  String(str)
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

is-js-expr = (js-type) ->
  js-type.indexOf('Expression') != -1

module.exports = genjs-top

statements-stack = []
with-statements = (statements, cb) ->
  statements-stack.push(statements)
  cb!
  statements-stack.pop!

add-statement = (statement) ->
  current-statements = statements-stack[0]
  throw "no current-statements" if ! current-statements
  current-statements.push(statement)


