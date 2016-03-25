u = require 'lib/utils'
{map,each,concat,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,line,lines,blank,space} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'
prog = posi.module "noco/prog/-module"

# posi-unit:
#   Nothing under this node can be selected.
#   If a new node is created and has the posi-unit class,
#   it will automatically open that node so the user can edit it.
#

handle = (node) ->
  cl = if node then node.type!.name! else 'generic'
  span "posi-handle posi-handle-#{cl}", span 'inner'

module.exports = templates =
  _common:
    full: (node,o) -> join do
                        o.part 'head', node, o
                        o.part 'body', node, o
    link: (node,o) -> o.part 'head', node, o
    name: (node,o) -> text node.name!
    head: (node,o) -> join do
                        handle node
                        #span 'id', text(node.ni)
                        span 'name', text(node.name!)
                        span 'type', text(node.type!.name!)
    body: (node,o) -> join do
                        if desc = node.a(n.desc) then div 'desc', text(node.a(n.desc))
                        o.part 'rig', node, o

    rig: (node,o) ->
      unless o.brief
        join do
          build-attrs-from-schema node,o
          build-refs-from-schema node,o
    # end of _common

  blank:
    full: (node, o) ->
      blank!


  node_type:
    full: (node, o) ->
      subtype-refs = node.inrefNodesWithType(n.s-subtype-of)
      div 'card',
        line do
          handle node
          div null,
            name node, o
            attr node, n.desc, o
            ref node, n.s-subtype-of, o,
              prefix: keyword 'subtype-of: '
            ref node, n.s-subtype, o,
              prefix: keyword 'subtypes: '
            ref node, n.ctns, o
            #ref node, n.node-method-r, o,
              #prefix: keyword 'method: '
            if subtype-refs.length
              join do
                keyword "subtypes:"
                indent do
                  subtype-refs |> map (ref-node) ->
                    line link ref-node, o
            ref node, n.keyword-r, o

  schema:
    schema_attr:
      full: (node, o) ->
        line do
          keyword 'attr'
          space!
          ref node, n.s-at, o, mode: 'name'
          space!
          keyword templates.schema._numericality(node)
          space!
          ref node, n.s-avt, o, mode: 'name'


    schema_ref:
      full: (node, o) ->
        line do
          keyword do
            switch node.a(n.s-dep)
            when true then 'comp'
            when false then 'link'
            else 'ref'
          space!
          ref node, n.s-rt, o, mode: 'name'
          space!
          keyword templates.schema._numericality(node)
          space!
          ref node, n.s-gnt, o, mode: 'name'

    _numericality: (node) ->
      if node.a(n.s-req) then (if node.a(n.s-rep) then '1..N' else '1')
                         else (if node.a(n.s-rep) then '0..N' else '0..1')

  container:
    rig: (node, o) ->
      expand = node.a(n.expand-children-a)
      ref node, n.ctns, o, {unit: !expand, mode: ('link' unless expand)}

  prog:
    _common:
      head: (node,o) -> line do
                          keyword node.type!.name!
                          space!
                          name node, o
      name: (node,o) -> text node.name!
      brief: (node, o) ->
        o.part 'reference', node, o
      reference: (node, o) ->
        o.part 'link', node, o

    # end of prog._common

    application:
      rig: (node,o) -> join do
                          div 'posi-major' do
                            join do
                              ref node, n.ctns, o, skip: true
                              ref node, n.declaration-r, o, skip: true
                              ref node, n.implementation-r, o

    array_type:
      full: (node, o) ->
        join do
          desc node, o
          line do
            keyword 'type'
            space!
            name node, o
            space!
            keyword "::"
            space!
            keyword "array<"
            ref node, n.component-data-type-r, o
            keyword ">"

      reference: (node, o) ->
        line do
          keyword "array<"
          ref node, n.component-data-type-r, o, component-mode: 'reference'
          keyword ">"


    assign:
      full: (node,o) ->
        join do
          desc node, o
          line do
            ref node, n.lvalue-r, o
            space!
            if operator = node.rn(n.operator-r)
              keyword operator-keyword(operator)
            else
              keyword ':='
            space!
            ref node, n.rvalue-r, o

    update:
      full: (node,o) ->
        join do
          desc node, o
          if operator = node.rn(n.operator-r)
            line do
              ref node, n.lvalue-r, o
              keyword operator-keyword(operator)
          else
            blank!

    closure:
      full: (node,o) ->
        join do
          desc node, o
          ref node, n.closure-function-r, o

    data_type:
      full: (node,o) ->
        join do
          desc node, o
          if composer = node.rn(n.data-type-composer-r)
            line do
              text composer.name!.replace(/_type$/, '')
              keyword "<"
               node, n.component-data-type-r, o
              keyword ">"
          else
            o.part 'reference', node, o

      link: (node, o) ->
        o.part 'reference', node, o

      reference: (node, o) ->
        span 'prog-data-type', name node, o

    expr:
      full: (node,o) ->
        join do
          desc node, o
          blank!

    fcall:
      full: (node,o) ->
        join do
          desc node, o
          if func = node.rn(n.callee-r)
            line do
              if subject = node.rn(n.subject-r)
                line do
                  ref node, n.subject-r, o
                  keyword '.'
              span 'prog-function', text func.name!
              paren do
                ref node, n.func-arg-r, o,
                  layout: 'line'
                  noblank: true
                  order: (farg-refs) ->
                    parameters = node.rn(n.callee-r)?.rn(n.function-signature-r)?.rns(n.parameter-r)
                    return farg-refs if !parameters
                    hash = {}
                    farg-refs |> each (farg-ref) ->
                      farg = farg-ref.target!
                      if param = farg.rn(n.arg-param-r)
                        hash[param.ni] = farg-ref
                    new-refs = []
                    parameters |> each (param) ->
                      if farg-ref = hash[param.ni]
                        new-refs.push farg-ref
                    new-refs

          else
            blank!

    new:
      full: (node,o) ->
        join do
          desc node, o
          line do
            keyword 'new'
            space!
            ref node, n.data-type-r, o, mode: 'name'
            paren do
              ref node, n.func-arg-r, o,
                layout: 'line'
                noblank: true
                # order: (farg-refs) ->
                #   parameters = node.rn(n.callee-r).rn(n.function-signature-r).rns(n.parameter-r)
                #   hash = {}
                #   farg-refs |> each (farg-ref) ->
                #     farg = farg-ref.target!
                #     if param = farg.rn(n.arg-param-r)
                #       hash[param.ni] = farg-ref
                #   new-refs = []
                #   parameters |> each (param) ->
                #     if farg-ref = hash[param.ni]
                #       new-refs.push farg-ref
                #   new-refs

    dynfcall:
      full: (node,o) ->
        join do
          desc node, o
          line do
            ref node, n.callee-r, o
            paren do
              ref node, n.func-arg-r, o, layout: 'line'

    natfcall:
      full: (node,o) ->
        join do
          desc node, o
          line do
            ref node, n.subject-r, o, suffix: keyword "."
            span 'prog-function', name node, o
            paren do
              #space!
              ref node, n.func-arg-r, o, layout: 'line'

    natexpr:
      full: (node,o) ->
        join do
          desc node, o
          line do
            span 'prog-function',
              attr node, n.value-a, o

    natprop:
      full: (node,o) ->
        join do
          desc node, o
          line do
            ref node, n.subject-r, o, suffix: keyword "."
            span 'prog-member', name node, o


    field:
      full: (node,o) ->
        join do
          desc node, o
          line do
            span 'prog-field', name node, o
            space!
            keyword "::"
            space!
            ref node, n.data-type-r, o, fold: true

      brief: (node,o) ->
        join do
          desc node, o
          line do
            span 'prog-field', name node, o
            space!
            keyword "::"
            space!
            ref node, n.data-type-r, o, fold: true#component-mode: 'reference'

      link: (node, o) ->
        span 'prog-field', name node, o

    select:
      full: (node, o) ->
        join do
          desc node, o
          line do
            ref node, n.subject-r, o
            keyword "."
            ref node, n.field-r, o


    func_arg:
      full: (node,o) ->
        join do
          desc node, o
          line do
            # IDEA: query params from function and display only those
            #ref node, n.arg-param-r, o, mode: 'name'
            #keyword ": "
            ref node, n.arg-expr-r, o

    function:
      full: (node,o) ->
        join do
          desc node, o
          div 'posi-major' do
            # if function-is-simple(node)
            #   expr-node = node.rn(n.implementation-r).rns(n.item-r)[0].rn(n.arg-expr-r)
            #   if expr-node
            #     o.node 'full', expr-node, o
            #   else
            #     blank!
            # else
            line do
              o.part 'head', node, o
              space!
              o.part 'rig', node, o

      brief: (node,o) ->
        div 'posi-major' do
          o.part 'head', node, o

      head: (node,o) ->
        if parent = node.parent! # if parent is missing => we're still in the middle of creating a node
          join do
            desc node, o
            line do
              if node.parent!.type! == n.class
                # Method
                line do
                  span 'prog-function', name node, o
                  space!
                  keyword ':'
                  space!
              else
                # Normal Function
                line do
                  #keyword node.type!.name!
                  #space!
                  span 'prog-function', name node, o
                  space!
              ref node, n.function-signature-r, o
              if node.a(n.async-a)
                join do
                  space!
                    keyword "async"
              space!
              symbol '→', 'x150'

      rig: (node,o) ->
        [is-native, method] = function-is-native(node)

        if is-native
          join do
            keyword "native"
            indent do
              text(if method then method.a(n.native-code-a) else '')
        else
          join do
            #join do
              #ref node, n.variable-r, o, layout: 'block'
            ref node, n.declaration-r, o, skip: true
            ref node, n.implementation-r, o

      name: (node,o) ->
        span 'prog-function', name node, o

    class:
      full: (node,o) ->
        join do
          desc node, o
          line do
            keyword 'class'
            space!
            name node, o
          indent do
            join do
              ref node, n.field-r, o, fold: true
              ref node, n.constructor-r, o, prefix: line(keyword('constructor'), space!), fold: true
              ref node, n.method-r, o, context: 'method', fold: true

      brief: (node, o) ->
        line do
          keyword 'class'
          space!
          name node, o

      link: (node, o) ->
        span 'prog-data-type', name node, o

    this:
      full: (node,o) ->
        join do
          desc node, o
          keyword 'this'

    function_signature:
      full: (node,o) ->
        join do
          desc node, o
          line do
            paren do
              ref node, n.parameter-r, o,
                layout: 'line'
                mode: 'nokw'
            ref node, n.data-type-r, o,
              component-mode: 'reference',
              prefix: keyword('::')
              layout: 'line'

      link: (node, o) ->
        o.part 'full', node, o

    function_type:
      full: (node,o) ->
        join do
          desc node, o
          line do
            keyword 'functype'
            ref node, n.function-signature-r, o

      reference: (node,o) ->
        o.part 'full', node, o


    if: (node, o) ->
      join do
        desc node, o
        line do
          keyword 'if'
          space!
          ref node, n.condition-r, o
        indent do
          ref node, n.then-r, o,
            prefix: join(keyword('then'), space!)
            layout: 'line'

          ref node, n.else-r, o,
            prefix: join(keyword('else'), space!)
            layout: 'line'

    literal:
      full: (node,o) ->
        v = node.a(n.literal-value-a)
        v = null if v == undefined
        join do
          desc node, o
          span 'prog-literal',
            text JSON.stringify(v)

    module:
      rig: (node,o) ->
        expand = false
        div 'posi-major' do
          ref node, n.ctns, o, {unit: !expand, mode: ('brief' unless expand)}

    jsmodule:
      rig: (node,o) ->
        div 'posi-major',
          ref node, n.declaration-r, o, skip: true
          ref node, n.implementation-r, o

    op:
      full: (node,o) ->
        join do
          desc node, o
          if operator = node.rn(n.operator-r)
            if operator.a(n.is-unary-a)
              line do
                keyword operator-keyword operator
                ref node, n.op-arg-r, o,
                  layout: 'line'
                  minimum: 1
                  maximum: 1
            else
              paren do
                ref node, n.op-arg-r, o,
                  layout: 'line'
                  delim: -> keyword operator-keyword operator
                  minimum: 2
                  maximum: 2
          else
            blank!

    sequence:
      full: (node,o) ->
        join do
          desc node, o
          ref node, n.item-r, o

    block:
      full: (node, o) ->
        join do
          desc node, o
          ref node, n.item-r, o, major: true

    chain:
      full: (node, o) ->
        join do
          desc node, o
          line do
            ref node, n.subject-r, o
            space!
            keyword '▷'
            space!
            ref node, n.item-r, o

    struct_type:
      full: (node,o) ->
        join do
          desc node, o
          line do
            keyword 'type'
            space!
            span 'prog-struct', name node, o
            space!
            keyword "::"
            space!
            keyword "struct"
            space!
            ref node, n.field-r, o

      reference: (node, o) ->
        line do
          keyword 'struct'
          space!
          span 'prog-struct', name node, o

      link: (node, o) ->
        span 'prog-data-type', name node, o

    hash_type:
      full: (node,o) ->
        join do
          desc node, o
          line do
            keyword 'type'
            space!
            span 'prog-struct', name node, o
            space!
            keyword "::"
            space!
            keyword "hash"
            space!
            ref node, n.key-type-r, o
            keyword ','
            space!
            ref node, n.data-type-r, o

      reference: (node, o) ->
        line do
          keyword "hash<"
          ref node, n.key-type-r, o
          keyword ','
          space!
          ref node, n.data-type-r, o
          keyword ">"

      link: (node, o) ->
        span 'prog-struct', name node, o

    variable:
      full: (node,o) ->
        join do
          desc node, o
          line do
            keyword '⩒'
            span 'prog-variable', name node, o
            ref node, n.data-type-r, o, component-mode: 'reference', prefix: line(space!, keyword('::'), space!)
            attr node, n.s-req, o, boolean: ['required', 'optional'], prefix: space!
            ref node, n.default-r, o, prefix: line(space!, keyword('='), space!)

      nokw: (node,o) ->
        line do
          o.part 'reference', node, o
          ref node, n.data-type-r, o, component-mode: 'reference', prefix: keyword '::'

      reference: (node, o) ->
        span 'prog-variable', name node, o

    varref:
      full: (node,o) ->
        join do
          desc node, o
          line do
            div 'posi-unit', # select varref when hovering over a variable inside a varref
              ref node, n.variable-r, o, mode: 'reference'

    while:
      head: (node,o) ->
        line do
          keyword 'while'
          space!
          ref node, n.condition-r, o

      rig: (node,o) ->
        ref node, n.body-r, o

    make_struct:
      full: (node, o) ->
        join do
          desc node, o
          line do
            ref node, n.subject-r, o
            paren do
              ref node, n.make-struct-arg-r, o, layout: 'rows'

    make_struct_arg:
      full: (node, o) ->
        join do
          desc node, o
          line do
            ref node, n.field-r, o
            keyword ":"
            space!
            ref node, n.op-arg-r, o

    enum_type:
      full: (node,o) ->
        join do
          desc node, o
          line do
            keyword 'type'
            space!
            name node, o
            space!
            keyword "::"
            space!
            keyword "enum"
            space!
            ref node, n.item-r, o, layout: 'line', component-mode: 'reference'

      reference: (node, o) ->
        line do
          keyword "enum<"
          ref node, n.item-r, o, layout: 'line', component-mode: 'reference'
          keyword ">"

      link: (node, o) ->
        o.part 'name', node, o

    symbol:
      symbol: '⍵'

      full: (node, o) ->
        join do
          desc node, o
          line do
            keyword 'symbol'
            space!
            o.part 'reference', node, o
      reference: (node, o) ->
        div 'prog-symbol',
          name node, o
      link: (node, o) ->
        o.part 'reference', node, o

    symref:
      full: (node, o) ->
        join do
          desc node, o
          ref node, n.refs, o
      link: (node, o) ->
        ref node, n.refs, o

    make_array:
      full: (node, o) ->
        join do
          desc node, o
          line do
            keyword '[]'
            ref node, n.item-r, o#, layout: 'line'
            #keyword ']'

    index:
      full: (node, o) ->
        join do
          desc node, o
          line do
            ref node, n.subject-r, o
            keyword '['
            ref node, n.index-r, o
            keyword ']'

    make_hash:
      full: (node, o) ->
        # if short:
        join do
          desc node, o
          line do
            keyword '{'
            ref node, n.item-r, o, layout: 'line'
            keyword '}'
        # TODO: if long:
        # join do
        #   keyword '{'
        #   indent ref node, n.item-r, o
        #   keyword '}'

    property:
      full: (node, o) ->
        join do
          desc node, o
          line do
            attr node, n.identifier-a, o
            keyword ':'
            space!
            ref node, n.rvalue-r, o

    member:
      full: (node, o) ->
        join do
          desc node, o
          line do
            ref node, n.subject-r, o
            keyword "."
            attr node, n.identifier-a, o

    'for':
      head: (node,o) ->
        join do
          desc node, o
          line do
            keyword 'for'
            space!
            paren do
              line do
                ref node, n.init-r, o
                keyword ';'
                space!
                ref node, n.condition-r, o
                keyword ';'
                space!
                ref node, n.update-r, o

      rig: (node,o) ->
        ref node, n.body-r, o

    step:
      head: (node,o) ->
        line do
          keyword 'step'
          space!
          ref node, n.loop-var-r, o
          space!
          keyword 'from'
          space!
          ref node, n.start-r, o
          space!
          keyword 'to'
          space!
          ref node, n.end-r, o

      rig: (node,o) ->
        ref node, n.body-r, o

    function_expr:
      full: (node, o) ->
        join do
          desc node, o
          ref node, n.function-r, o

    function_value:
      full: (node, o) ->
        join do
          desc node, o
          div 'posi-unit',
            ref node, n.function-r, o, mode: 'name'

    'return':
      full: (node, o) ->
        join do
          desc node, o
          line do
            keyword 'return'
            space!
            ref node, n.arg-expr-r, o

    'throw':
      full: (node, o) ->
        join do
          desc node, o
          line do
            keyword 'throw'
            space!
            ref node, n.arg-expr-r, o

    object_expr:
      full: (node, o) ->
        join do
          desc node, o
          line do
            keyword '◇'
            join do
              #keyword "{"
              #indent do
              ref node, n.property-r, o
              #keyword "}"

    object_property:
      full: (node, o) ->
        join do
          desc node, o
          line do
            keyword '▪'
            attr node, n.key-a, o
            keyword ':'
            space!
            ref node, n.rvalue-r, o

    switch:
      full: (node, o) ->
        join do
          desc node, o
          join do
            line do
              keyword 'switch'
              space!
              ref node, n.discriminant-r, o
            indent do
              ref node, n.case-r, o

    case:
      full: (node, o) ->
        join do
          desc node, o
          join do
            if node.a(n.is-default-a)
              keyword 'default'
            else
              line do
                keyword 'case'
                space!
                ref node, n.condition-r, o, layout: 'line'
            indent do
              ref node, n.then-r, o

    break:
      full: (node, o) ->
        join do
          desc node, o
          keyword 'break'

    continue:
      full: (node, o) ->
        join do
          desc node, o
          keyword 'continue'

    disable:
      full: (node, o) ->
        join do
          desc node, o
          line do
            keyword "//"
            space!
            ref node, n.item-r, o

    node_id_literal:
      full: (node, o) ->
        line do
          keyword "node-id"
          space!
          ref node, n.refs, o

    node_literal:
      full: (node, o) ->
        line do
          keyword "node"
          space!
          ref node, n.refs, o

    box: (node, o) ->
      join do
        desc node, o
        line do
          keyword 'box<'
          ref node, n.component-data-type-r, o, component-mode: 'reference'
          keyword '>'

    compute: (node, o) ->
      eager = node.a(n.eager-a)
      join do
        desc node, o
        keyword 'compute'
        indent do
          ref node, n.declaration-r, o, skip: true
          ref node, n.implementation-r, o

    computed_box: (node, o) ->
        eager = node.a(n.eager-a)
        join do
          desc node, o
          line do
            keyword 'compubox<'
            ref node, n.component-data-type-r, o, component-mode: 'reference'
            keyword '>'
            space! if eager
            keyword 'eager' if eager
          unless o.mode == 'brief'
            indent do
              ref node, n.declaration-r, o, skip: true
              ref node, n.implementation-r, o

    # end of prog

  testing:
    assert:
      full: (node, o) ->
        join do
          desc node, o
          line do
            keyword "assert"
            space!
            ref node, n.arg-expr-r, o

    test:
      full: (node, o) ->
        div 'posi-major',
          keyword "test"
          space!
          if subject = node.inrefNodesWithType(n.te-test-r)[0]
            o.node 'name', subject, o, unit: true
          indent do
            ref node, n.te-test-case-r, o

    test_case:
      full: (node, o) ->
        join do
          attr node, n.desc, o
          indent do
            ref node, n.declaration-r, o, skip: true
            ref node, n.implementation-r, o



  templating:

    template:
      full: (node, o) ->
        join do
          header node, o
          line do
            keyword 'params'
            space!
            ref node, n.t-param-r, o, layout: 'line'
          ref node, n.t-block-r, o
      link: (node, o) ->
        name node, o

    param:
      full: (node, o) ->
        span 'prog-variable', name node, o
      link: (node, o) ->
        span 'prog-variable', name node, o

    tag:
      head: (node, o) ->
        line do
          attr node, n.t-tag-type-a, o
          ref node, n.t-attribute-r, o, layout: 'line', delim: space
      rig: (node, o) ->
        ref node, n.t-block-r, o

    attribute:
      full: (node, o) ->
        line do
          space!
          attr node, n.t-attribute-name-a, o
          keyword '='
          attr node, n.t-attribute-value-a, o

    block:
      full: (node, o) ->
        ref node, n.t-element-r, o

    text:
      full: (node, o) ->
        attr node, n.t-text-value-a, o

    include:
      full: (node, o) ->
        line do
          keyword "include"
          ref node, n.t-template-r, o, mode: 'link'

    slot:
      head: (node, o) ->
        line do
          keyword "="
          ref node, n.t-expression-r, o
      rig: (node, o) ->
        ref node, n.t-block-r, o

    tvariable:
      full: (node, o) ->
        attr node, n.t-variable-name-a, o


    helper:
      full: (node, o) ->
        line do
          attr node, n.t-helper-name-a, o
          paren do
            ref node, n.t-argument-r, o

    argument:
      full: (node, o) ->
        ref node, n.t-expression-r, o

    each:
      full: (node, o) ->
        join do
          line do
            keyword 'each'
            space!
            ref node, n.t-arg-r, o
            space!
            keyword ':'
            space!
            ref node, n.t-param-r, o
          indent do
            ref node, n.t-block-r, o

    param_slot:
      full: (node, o) ->
        line do
          keyword "="
          space!
          ref node, n.t-param-r, o

    render:
      full: (node, o) ->
        line do
          keyword 'render'
          space!
          ref node, n.t-template-r, o
          paren do
            ref node, n.t-arg-r, o

    arg:
      full: (node, o) ->
        line do
          ref node, n.t-param-r, o
          symbol ":"
          space!
          ref node, n.arg-expr-r, o

  react:
    html_elem: (node, o) ->
      join do
        # opening tag
        line do
          keyword "<"
          attr node, n.react-name-a, o
          space!
          ref node, n.react-prop-r, o, layout: 'line', delim: -> space!
          keyword ">"
        # children
        indent do
          ref node, n.react-child-r, o
        ## closing tag
        #line do
          #keyword "</"
          #text node.a(n.react-name-a)
          #keyword ">"

    react_elem: (node, o) ->
      join do
        # opening tag
        line do
          keyword "<"
          ref node, n.react-class-r, o
          space!
          ref node, n.react-prop-r, o, layout: 'line', delim: -> space!
          keyword ">"
        # children
        indent do
          ref node, n.react-child-r, o
        ## closing tag
        #line do
          #keyword "</"
          #text node.rn(n.react-class-a)?.name!
          #keyword ">"

    prop: (node, o) ->
      line do
        attr node, n.react-name-a, o
        keyword '='
        ref node, n.react-value-r, o

    app: (node, o) ->
      join do
        line do
          keyword 'react app'
          space!
          name node, o
        indent do
          ref node, n.declaration-r, o
          ref node, n.react-main-r, o, prefix: line(keyword('main'), space!)

    component: (node, o) ->
      if o.mode == 'link'
        text node.name!
      else
        join do
          line do
            keyword 'component'
            space!
            name node, o
          indent do
            keyword 'props'
            indent do
              ref node, n.react-prop-var-r, o
            keyword 'state'
            indent do
              ref node, n.react-state-var-r, o
            keyword 'render'
            indent do
              ref node, n.react-render-r, o

  web:
    app:
      full: (node, o) ->
        join do
          header node, o, type-name: 'web app', html-class: "web-app-header"
          line do
            div 'web-subpath',
              text '/'
            space!
            ref node, n.web-route-r, o
    route:
      full: (node, o) ->
        line do
          div 'web-route', space!
          join do
            ref node, n.web-endpoint-r, o
            ref node, n.web-subpath-r, o

    endpoint:
      full: (node, o) ->
        line do
          div 'web-endpoint-method' do
            attr node, n.web-request-method-a, o
          space!
          div 'web-endpoint-content' do
            ref node, n.main-function-r, o

    subpath:
      full: (node, o) ->
        line do
          div 'web-subpath',
            text '/'
            attr node, n.value-a, o
          space!
          ref node, n.web-route-r, o

  tasks:
    project:
      full: (node, o) ->
        join do
          div 'posi-nav-line' do
            name node, o
          project-estimate(node)
          ref node, n.ctns, o

    task:
      full: (node, o) ->
        div "task-status-#{node.a(n.ta-status-a)}",
          div 'posi-nav-line' do
            line do
              div 'task-marks',
                unless node.a(n.ta-status-a) == 'done'
                  line do
                    if importance = node.a(n.ta-importance-a)
                      div "task-importance task-importance-#{importance}", text importance
                    task-estimate(node)
              div "task-icon task-status-#{node.a(n.ta-status-a)}"
              attr node, n.desc, o, elem: false
          div "indent task-indent-#{(if node.rns(n.ta-note-r).length + node.rns(n.ta-subtask-r).length > 0 then 'present' else 'empty')}" do
            join do
              ref node, n.ta-note-r, o
              ref node, n.ta-subtask-r, o

    note:
      full: (node, o) ->
        join do
          div 'posi-nav-line' do
            line do
              div 'task-marks'
              div "note-icon"
              attr node, n.desc, o, elem: false

# Private

keyword = (c) -> span 'keyword', text c
symbol = (c, classes) -> span "keyword #{classes}", text c
paren = -> div 'paren', ...arguments

header = (node, o, oo = {}) ->
  div "header #{oo.html-class || "#{node.type!.name!}-header"}",
    line do
      name node, o
      space!
      keyword (oo.type-name || node.type!.name!)
join-non-blanks = u.join-non-blanks

div-propt = (pkind, name, {layout,is-bloat,inspect,unit,skip}, ...args) ->
  classes-str = join-non-blanks ' ',
    "posi-#{pkind}t"
    #"posi-elem"
    "posi-propt"
    "posi-propt-#{name}"
    "posi-#{layout}" if layout
    "posi-propt-bloat" if is-bloat
    "posi-unit" if unit
    "posi-skip" if skip
  el = div classes-str, ...args
  el.setAttribute 'data-inspect', inspect if inspect
  el.setAttribute 'data-name', name
  el

div-prop = (pkind, {layout,is-bloat,append,inspect,dep,elem}, ...args) ->
  classes-str = join-non-blanks ' ',
    "posi-#{pkind}"
    "posi-elem" if elem
    "posi-prop"
    "posi-prop-bloat" if is-bloat
    "posi-#{layout}-item" if layout
    "posi-prop-append" if append
    "posi-dep" if dep
  el = div classes-str, ...args
  el.setAttribute 'data-inspect', inspect if inspect
  el

name = (node, o = {}) ->
  value = node.name!
  req = false
  is-blank = ! (value && value != '')
  is-bloat = is-blank
  layout = "line"
  append = false
  inspect="#{node.inspect!}/name"
  el = div-propt 'name', 'name', {layout,is-bloat,inspect},
    if is-blank
      div-prop 'name', {layout,inspect, is-bloat: !req},
        blank({req, id: "posi-name-blank-#{node.ni}"})
    else
      name-el = div-prop 'name', {layout,inspect},
        text value
      name-el.setAttribute 'id', "posi-name-blank-#{node.ni}"
      name-el
  el.setAttribute 'id', "posi-name-#{node.ni}" unless o.unit
  el

attr = (node, attr-type, o, oo = {}) ->
  value = node.a(attr-type)
  req = false
  is-blank = value == undefined
  is-bloat = is-blank
  layout = "line"
  append = false
  inspect="#{node.inspect!}/#{attr-type.name!}"
  el = div-propt 'attr', attr-type.name!, {layout,is-bloat,inspect},
    line do
      oo.prefix if oo.prefix
      if is-blank
        div-prop 'attr', {layout,inspect, is-bloat: !req},
          blank({req, id: "posi-attr-#{node.ni}-#{attr-type.ni}"})
      else
        attr-el = div-prop 'attr', {layout,inspect,elem:(if oo.elem == false then false else true)},
          #div 'posi-elem' do
            if oo.boolean
              keyword(if value then oo.boolean[0] else oo.boolean[1])
            else
              if value && value.indexOf && value.indexOf("\n") > -1
                div 'preformatted', do
                  text '' + value
              else
                text '' + value
        attr-el.setAttribute 'id', "posi-attr-#{node.ni}-#{attr-type.ni}"
        attr-el
  el.setAttribute 'data-ati', attr-type.ni
  el.setAttribute 'id', "posi-attrt-#{node.ni}-#{attr-type.ni}" unless o.unit
  el


ref =  (node, ref-type, o = {}, oo = {}) ->
  throw "node missing" if ! node
  throw "ref-type missing" if ! ref-type
  o = u.merge(o, unit: true) if oo.unit
  unit = o.unit
  layout = oo.layout || 'block'
  delim  = oo.delim || (layout == 'line' && (-> line(keyword(','), space!)) || null)
  build-delim = ({is-bloat} = {}) ->
    if delim
      classes-str = join-non-blanks ' ',
        "posi-#{layout}-item"
        "delim"
        "posi-prop-bloat" if is-bloat
      el = div classes-str, delim!
      el

  sref = node.type!.schema!.ref-with-type(ref-type)
  if ! sref
    console.warn "Couldn't find sref for #{node.inspect!} #{ref-type.inspect!}"
  refs = node.refsWithType(ref-type)
  refs = oo.order(refs) if oo.order
  items = refs |> map (ref) -> {ref}
  children = node.rns(ref-type)
  is-blank = items.length == 0
  rep = (if sref then sref.rep else true)
  req = (if sref then sref.req else false)
  is-bloat = is-blank && !req
  skip = oo.skip

  u.pad items, oo.minimum, {req: true}
  u.add-if-empty items, {req: req}

  #console.log "node.ni", node.ni, ref-type.name!, items[items.length-1].ref, oo
  if rep && items[items.length-1].ref
    unless oo.noblank
      unless oo.maximum && items.length >= oo.maximum
        items.push {req: false, append: true}
  inspect = "#{node.inspect!}/#{ref-type.name!}/rep:#{rep}"

  infix =
    if items.length
      items |> u.map-with-index ({ref,req,append}, index) ->
        is-bloat = !ref && !req
        ref-el = div-prop 'ref', {layout, is-bloat, append, dep: (ref.dep! if ref)},
          if ref
            mode   = oo.mode || (
              if ref.dep!
                then oo.component-mode || (oo.fold && ! posi.is-unfolded(ref) && 'brief' || 'full')
                else oo.link-mode || 'link'
            )
            o.node mode, ref.target!, o,
              unit: (if ref.dep! == false then true else o.unit)
              component: ref.dep!
              major: oo.major
          else
            blank({req, id: "posi-ref-#{node.ni}-#{ref-type.ni}-#{index}-blank"})
        if ref
          ref-el.setAttribute 'data-ri', ref.ri
          ref-el.setAttribute 'data-inspect', ref.inspect!
        ref-el.setAttribute 'id', "posi-ref-#{node.ni}-#{ref-type.ni}-#{index}"

        join do
          build-delim({is-bloat})  unless index == 0
          ref-el

  el =
    div-propt 'ref', ref-type.name!, {layout,is-bloat,inspect,skip},
      if oo.prefix || oo.suffix
        line do
          oo.prefix if oo.prefix
          infix if infix
          oo.suffix if oo.suffix
      else
        infix
  el.setAttribute 'data-rti', ref-type.ni
  el.setAttribute 'id', "posi-propt-#{node.ni}-#{ref-type.ni}" unless o.unit
  el
# end of ref

desc = (node, o) ->
  v = node.a(n.desc)
  if v
    div 'prog-description', text "// #{v}"

virt = (node, virt-type, o = {}, oo = {}) ->
  throw "node missing" if ! node
  row "ref-type missing" if ! ref-type
  #div-propt 'virt', virt-type, {},



build-attrs-from-schema = (node,o) ->
  #console.log "build-attrs-from-schema", node.inspect
  for sattr in node.type!.schema!.attrs!
    if sattr.at && sattr.at != n.name && sattr.at != n.desc
      attr node, sattr.at, o,
        prefix: join keyword("#{sattr.at.name!}:"), space!

build-refs-from-schema = (node,o) ->
  #console.log "build-refs-from-schema", node.inspect!
  for sref in node.type!.schema!.refs!
    if sref.rt && sref.rt != n.type
      ref node, sref.rt, o,
        prefix: join keyword("#{sref.rt.name!}:"), space!
      #div 'reft propt',
        #div 'label',
          #text (sref.rt && sref.rt.name!)
          #text ": "
        #div 'values',
          #for ref in node.refsWithType sref.rt
            #target = ref.target!
            #div 'ref prop',
              #o.node 'link', target, o

panes = ->
  items = Array.prototype.slice.call arguments
  panes = items |> map (item) -> div 'pane', item
  div 'panes', ...panes

link = (node, o) ->
  o.node 'link', node, o, unit: true

indent = ->
  div 'indent', ...arguments

# *** PROG-specific ****
operator-keyword = (operator) ->
  k = operator.name!
  if keyword-node = operator.rn(n.keyword-r)
    k = keyword-node.a(n.value-a)
  k

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

function-is-simple = (node) ->
  return false if node.rns(n.variable-r).length > 0
  return false if function-is-native(node)[0]
  return false if !(impl = node.rn(n.implementation-r))
  statements = impl.rns(n.item-r)
  return false if statements.length != 1
  statements[0].type! == n.return

window.tasks-calc-total-estimate = (node) ->
  task-estimate-friendly tasks-calc-total-estimate-raw node

tasks-calc-total-estimate-raw = (node) ->
  explicit-estimate = task-estimate-raw node.a(n.ta-estimate-a)
  subtasks = node.rns(if node.type! == n.ta-project then n.ctns else  n.ta-subtask-r)
  estimates = subtasks |> map (subtask) ->
    if subtask.a(n.ta-status-a) == 'done'
      0
    else
      tasks-calc-total-estimate-raw(subtask)
  Math.max do
    prelude.sum(estimates) || 0
    explicit-estimate || 0

task-unit-table =
  y: 6*20*11 # 11 months, leave room for holidays
  m: 6*20    # 20 days a month, leave room for 1-2 bank holidays
  w: 6*5     # 5 days a week
  d: 6       # 6 productive hours per day
  h: 1

window.task-estimate-raw = (friendly) ->
  return 0 if ! friendly
  quant = parseFloat friendly.substring(0, friendly.length-1)
  unit = friendly[*-1]
  multiplier = task-unit-table[unit] or throw "couldn't find unit '#{unit}' in table"
  quant * multiplier

window.task-estimate-friendly = (raw) ->
  return null if ! raw? || raw == 0
  x = raw
  ret = ""
  last = false
  for unit, multiplier of task-unit-table
    times = x / multiplier
    if times < 1
      break if last
      continue
    if times < 1.5 && times > 1 && unit != 'h'
      # display 1.5y as 18m
      continue

    quant = Math.ceil(times)
    ret ++= "#{quant}#{unit}"
    break #if last
    last = true # next iteration will be the last
    x = x % multiplier
  ret

project-estimate = (node) ->
  estimate = tasks-calc-total-estimate(node)
  if estimate
    line do
      div "task-estimate task-estimate-#{estimate[*-1]}", text estimate

task-estimate = (node) ->
  estimate = node.a(n.ta-estimate-a)
  total = tasks-calc-total-estimate(node)
  if estimate == 0 || (total != 0 && total != estimate)
    estimate = total
  if estimate
    div "task-estimate task-estimate-#{estimate[*-1]}", text estimate




