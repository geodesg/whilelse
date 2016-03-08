# SELECT-AS-TARGET

  prog:
    expr:
      select-as-target: ({$el,parent}) -> promise 'expr.select-as-target', $el, (d) ->
        prog.surch({$el,parent}) |> c d,
          done: (m) -> expr-handler.resolve-with-match(d, m)

    block:
      select-as-target: ({$el,parent}) -> promise 'block.select-as-target', $el, (d) ->
        d.resolve do
          node-type: n.block

    property:
      # Enter something then create, allows to skip
      select-as-target: ({$el,parent}) -> promise "property.select-as-target", $el, (d) ->
        ui.input({title: 'key', $anchor: $el}) |> c d,
          done: ({value} = {}) ->
            value = null if value == ''
            if value
              d.resolve do
                node-type: n.property
                apply-cb: (node) ->
                  node.cSetAttr n.identifier-a, value

    symbol:
      select-as-target: ({$el,parent}) -> promise "symbol.select-as-target", $el, (d) ->
        ui.input({title: 'symbol name', $anchor: $el}) |> c d,
          done: ({value} = {}) ->
            value = null if value == ''
            if value
              d.resolve do
                node-type: n.symbol
                apply-cb: (node) ->
                  node.cSetName value

  templating:
    attribute:
      select-as-target: ({$el,parent}) -> promise "attribute.select-as-target", $el, (d) ->
        ui.input({title: 'attribute name', $anchor: $el}) |> c d,
          done: ({value} = {}) ->
            value = null if value == ''
            d.resolve do
              node-type: n.t-attribute
              apply-cb: (node) ->
                node.cSetAttr n.t-attribute-name-a, value



# APPLY-SURCH-RESULT

  assign:
    apply-surch-result: (node, result) ->
      node.cAddLink n.operator-r, result.node
