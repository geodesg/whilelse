{promise,promise-short,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude

{box,compute,bcg,cbox} = boxlib = require 'lib/box'
cursor = require 'modules/pig/posi/cursor'

pig = require 'models/pig'
{n, repo} = common = require 'models/pig/common'
actions = require 'modules/pig/node/actions'

{tag,div,span,text,compute-el} = th = require 'modules/pig/posi/template-helpers'
br = require 'modules/pig/posi/bridges'


module.exports = posi = window.posi =
  cursor: cursor
  br: br

  #------------------------------------------------------------

  complete: (q) ->
    window.q = q
    posi.complete-p q .done (r) ->
      console.log "resolved", r
      posi.select-node(r.new-node, 'complete finished') if r
      cursor.set q.$el if posi.element-present(q.$el)
      posi.resume!

  complete-p: (q) -> promise "complete-p", q.$el, (d) ->
    # - find all props > find node & blanks inside
    if q.$el.is('.blank')
      posi.complete-blank-p(q.$el) |> c d, location: 'complete-p blank'
    else
      #if q.$el.is('.posi-node') # REFACTOR: consider extracting a Node class
      posi.complete-all-blanks(q.$el) |> c d, location: 'complete-p non-blank'

  # Iterates through all blanks
  # calls complete-blank-p for each
  # converts failure/skip to success/skip
  complete-all-blanks: ($el) -> promise "complete-all-blanks", $el, (d) ->
    steps =
      $el.find('.blank').toArray! |> map (blank) ->
        $blank = $ blank
        -> promise "complete-all-blanks-item", $blank, (d) ->
            $blank := posi.reload-by-id $blank
            if $blank && $blank.length > 0 && $blank.is('.blank')
              posi.complete-blank-p($blank, iteration: true) |> c d,
                fail: (r) ->
                  if r && r.skip
                    d.resolve skip: true
                  else
                    d.reject r
            else
              d.resolve!
    u.iterateFL steps |> c d

  # opts.iteration - it is part of an iteration, meaning the user did not specifically request
  #                  to complete this blank, so skip it if it has a .posi-skip class
  #
  complete-blank-p: ($el, opts = {}) -> promise "complete-blank-p", $el, (d) ->
    #console.log "➜ complete-blank-p", $el.get(0)
    # types of blanks:
    # - existing placeholder node => action: change node type
    # - nonexistent ref => action: append new ref
    # - nonexistent attr => action: set attribute
    # - blank name => action: set name
    #
    cursor.set $el
    $pEl = $el.closest('.posi-propt, .posi-node')
    #console.log "$pEl", $pEl.get(0)
    if $pEl.hasClass 'posi-node'
      # Node consists only of a blank, as it doesn't have any propts
      bNode = new br.BNode $pEl
      posi.complete-blank-node({bNode}) |> c d
    else
      if opts.iteration && $pEl.hasClass('posi-skip')
        d.resolve skip: true
      else
        posi.add-to-propt($pEl, $el) |> c d

  # Complete a node which consists of a blank, e.g <expr>.
  # - shows blanks if hidden
  # - asks user to select a subtype of the current node
  # - changes the type of the node
  complete-blank-node: ({bNode}) -> promise "complete-blank-node", bNode.el, (d) ->
    console.log "➜ complete-blank-node"
    node = bNode.node!
    posi.with-bloating d, bNode.el, (d) ->
      target-type = bNode.parent-reft!.gnt!
      if target-type && (target-h = posi.handler-for(target-type)) && (f = target-h.select-as-target)?
        target-h.select-as-target({$el:bNode.el,parent: node.parent!}) |> c d,
          done: ({node-type, apply-cb, target}) ->
            if target
              throw "Not prepared to create link"
            else
              pig.activity 'Set Type', ->
                node.cSetType(node-type)
                apply-cb(node) if apply-cb
              posi.complete-new-node(d, new-node: node)


  #------------------------------------------------------------


  # $pEl .posi-node (blank node), .posi-reft, .posi-namet, .posi-attrt
  # $el - blank element, used for bloating
  add-to-propt: ($pEl, $el) -> promise "add-to-propt", $pEl, (d) ->
    if $pEl.hasClass 'posi-reft'
      bReft = new br.BReft $pEl
      posi.add-to-reft({bReft}) |> c d,
        location: 'add-to-propt add-to-reft'

    else if $pEl.hasClass 'posi-namet'
      $node = $pEl.closest('.posi-node')
      ni = $node.data('ni') || throw 'ni missing'
      node = repo.node(ni) || throw 'node not found'

      posi.with-bloating d, $el, (d) ->
        actions.getName({$anchor: $el}) |> c d,
          done: (name) ->
            node.cSetName name
            d.resolve!

    else if $pEl.hasClass 'posi-attrt'
      $node = $pEl.closest('.posi-node')
      ni = $node.data('ni') || throw 'ni missing'
      node = repo.node(ni) || throw 'node not found'
      ati = $pEl.data('ati') || throw 'ati missing'
      attr-type = repo.node(ati) || throw 'attr-type node found'

      posi.with-bloating d, $el, (d) ->
        ui.input({title: attr-type.name!, $anchor: ($el || $pEl)}) |> c d,
          done: ({value} = {}) ->
            value = null if value == ''
            value = posi.guess-and-convert-type(value)
            node.cSetAttr(attr-type, value)
            d.resolve!

    else
      console.warn "Can't handle #{$pEl.attr('class')}"
      d.resolve!


  add-to-reft: ({bReft}) -> promise "add-to-reft", bReft.el, (d) ->
    bReft || throw "no bReft given"
    rep = bReft.rep!
    iterate = ->
      bReft.reload!
      $el = bReft.find-append-blank!
      if $el
        posi.add-ref-and-complete({bReft, $el}) |> c d,
          done: (r) ->
            if (r && r.skip) || ! rep
              d.resolve(r)
            else
              console.log "add-to-reft: next iteration"
              iterate!
      else
        d.resolve!
    iterate!

  add-ref-and-complete: ({bReft, $el}) -> promise "add-ref-and-complete", bReft.el, (d) ->
    posi.add-ref-p({bReft, $el}) |> c d,
      done: (r) ->
        posi.complete-new-node(d, r)

  # Offer creating a Ref
  add-ref-p: ({bReft,$el}) -> promise "add-ref-p", bReft.el, (d) ->
    console.log '➜ add-ref-p', $el.get(0)
    posi.with-bloating d, $el, (d) ->
      if ($blank = $el.find('.blank')).length == 1
        $el := $blank
      cursor.set $el
      target-type = bReft.gnt!

      invoke-select-as-target = ({target-type,$el,parent,ref-type,dep,d}) ->
        #u.info "invoke-select-as-target #{target-type.inspect!}"
        if (target-h = posi.handler-for(target-type)) && (f = target-h.select-as-target)?
          console.log 'add-ref-p - select-as-target'
          target-h.select-as-target({$el,parent,dep}) |> c d,
            done: ({node-type, apply-cb, target}) ->
              # REFACTOR idea: Tell, don't ask - let the custom handler do what it wants, instead passing shit back-and-forth
              if target
                pig.activity 'Link', ->
                  parent.cAddLink ref-type, target
                  apply-cb! if apply-cb
                d.resolve!
              else
                var node
                pig.activity 'Component', ->
                  node := parent.cAddComponent ref-type, node-type
                  throw "cAddComponent didn't return a node" if ! node
                  apply-cb(node) if apply-cb
                d.resolve(new-node: node)
          true

      parent   = bReft.source!.node!
      ref-type = bReft.rt!
      dep      = bReft.sref!?.dep

      if target-type
        invoked = invoke-select-as-target({target-type,$el,parent,ref-type,dep,d})
        return if invoked

      # If target-type missing or select-as-target not found
      # => use generic node-type selector
      posi.select-target-type target-type, {$anchor: $el} |> c d,
        done: ({target-type}) ->
          cursor.set $el

          invoked = invoke-select-as-target({target-type,$el,parent,ref-type,dep,d})
          return if invoked

          u.showMe $el, "el", ->
            console.log "target-type", target-type
            actions.sAddRefWithType(parent, ref-type, bReft.sref!, $el, target-type) |> c d,
              location: 'add-ref-p sAddRefWithType'



  #------------------------------------------------------------

  complete-new-node: (d, r) ->
    if r && (new-node = r.new-node)
      posi.unfold new-node.parent-ref!
      $new-node = posi.$node(new-node)

      # If the node is a unit (can't edit details on this page),
      # then navigate to it first
      if $new-node.closest('.posi-unit').length > 0
        posi.navigateToNode(new-node)
        d.reject abort: true

      # If the node-type says we shouldn't complete a new node, then don't
      else if posi.handler-property r.new-node.type!, 'stop-on-new-node'
        posi.select-node(new-node, 'complete-new-node')
        d.reject abort: true
      else
        posi.select-node(new-node, 'complete-new-node')
        if $new-node.find('.blank').length
          posi.complete-node-p($new-node) |> c d,
            location: 'complete-new-node posi.complete-node-p'
            done: (r) -> d.resolve {new-node}
        else
          posi.pause-on-node(new-node) .done ->
            posi.select-node(new-node, 'pause-on-node/resumed')
            d.resolve!# {new-node}
    else
      console.warn "resolve", r, "(complete-new-node else)"
      d.resolve(r)


  #------------------------------------------------------------

  complete-node-p: ($node) -> promise "complete-node-p", $node, (d) ->
    # Iterates through all propts
    node = repo.node($node.data('ni'))
    posi.complete-all-propts-p($node) |> c d,
      location: "complete-node-p #{node.inspect!}"


  complete-all-propts-p: ($el) -> promise "complete-all-propts-p", $el, (d) ->
    steps =
      posi.propt-list($el) |> map ($propt) ->
        ->
          if $propt.has-class 'posi-skip'
            promise (d) -> d.resolve!
          else
            posi.complete-propt-p posi.reload-by-id $propt
    u.iterateFL steps |> c d, location: 'complete-all-propts-p'

  complete-propt-p: ($propt) -> promise "complete-propt-p", $propt, (d) ->
    # Find blanks and nodes
    # - for blanks => complete
    # - for nodes => complete node
    $items = posi.find-elements-within $propt, '.blank, .posi-node'
    steps =
      $items |> map ($el) ->
        ->
          promise "complete-propt-p-item", $el, (d) ->
            $el := posi.reload-by-id $el, ignore-removed: true
            if $el
              if $el.is('.blank')
                posi.complete-blank-p($el) |> c d,
                  location: 'complete-propt-p blank'
                  fail: (r) ->
                    if r && r.skip
                      d.resolve skip: true
                    else
                      d.reject r
              else
                posi.complete-node-p($el) |> c d, location: 'complete-propt-p non-blank'
            else
              d.reject skip: true
    u.iterateFL steps |> c d,
      location: 'complete-propt-p iterateFL',
      done: (r) ->
        d.resolve r

  #------------------------------------------------------------

  pause-stack: []
  pause-on-node: (node) -> promise "pause-on-node #{node.inspect!}", (d) ->
    posi.select-node(node, 'pause-on-node')
    posi.pause-stack.push d

  resume: ->
    console.log "posi.resume", posi.pause-stack.length
    if posi.pause-stack.length > 0
      d = posi.pause-stack.pop!
      d.resolve!
      true
    else
      false

  select-target-type: (target-type, {$anchor} = {}) -> promise (d) ->
    console.log "select-target-type", $anchor
    if target-type
      candidates = target-type.compatible-types!
      switch candidates.length
      case 0 then throw "no candidate found; it should at least include the original"
      case 1 then d.resolve(target-type: candidates[0])
      else
        unikey = new (require('lib/unikey'))
        i = 0
        ui.choose do
          $anchor: $anchor
          title: 'Target type'
          options: candidates |> map (candidate) ->
            i := i + 1
            name = candidate.name!
            key: unikey.issue(name, i)
            name: name
            action: ->
              console.log "SELECTED", candidate.inspect!
              d.resolve(target-type: candidate)
        |> c d
    else
      actions.search-select do
        title: "Select target node type"
        type: n.ntyp
        $anchor: $anchor
      .done (node-type) ->
        d.resolve(target-type: node-type)



  # $el - typically a blank
  with-bloating: (d, $el, cb) ->
    if ! $el || $el.length == 0
      cb(d)
      return
    $prop = $el.closest('.posi-prop')
    $prop.length or throw "$prop not found"

    if ($prev = $prop.prev!).hasClass('delim')
      $delim = $prev # E.g. comma between function arguments

    $propt = $prop.closest('.posi-propt')
    $propt.length or throw "$propt not found"

    #console.log "BLOAT", $prop.data('inspect')
    $prop.addClass 'bloated'
    $delim.addClass 'bloated' if $delim
    $propt.addClass 'bloated'
    u.ensure-after cb, d, ->
      #console.log "UN-BLOAT", $prop.data('inspect')
      $prop.removeClass 'bloated'
      $delim.removeClass 'bloated' if $delim
      $propt.removeClass 'bloated'

  propt-list: ($el) ->
    posi.find-elements-within $el, '.posi-propt', '.posi-node'

  find-reft-el: ($el, reft) ->
    posi.find-element-within $el, ".posi-propt-#{reft.name!}", ".posi-propt"

  find-elements-within: ($el, selector, stop-selector = null, results = []) ->
    $el.children!.each (i, child) ->
      $child = $ child
      if $child.is selector
        results.push $child
      else
        if stop-selector && $child.is(stop-selector)
          # don't go deeper
          ;
        else
          posi.find-elements-within($child, selector, stop-selector, results)
      true
    results

  find-element-within: ($el, selector, stop-selector = null) ->
    posi.find-elements-within($el, selector)[0]

  reload-by-id: ($el, {ignore-removed} = {}) ->
    $el || throw "no $el given"
    if $el.closest('body').length
      $el
    else
      $el || throw "$el missing"
      $el.length > 0 || throw "$el does not refer to any element"
      id = $el.attr('id')
      if !id
        console.error "No id for el", $el, $el.html!
        throw "no id for el"
      $el = $("##{id}")
      if $el.length > 0
        $el
      else
        if ignore-removed
          null
        else
          throw "$el not found by id"

  handler-for: (type) ->
    type || throw "no type given to handler-for"
    posi.optional-module "noco/#{type.source-name!}"

  module-handler-for: (type) ->
    type || throw "no type given to handler-for"
    posi.optional-module "noco/#{type.parent!.source-name!}/-module"

  optional-handler-property: (type, property) ->
    if h = posi.handler-for(type)
      h[u.camelize(property)]

  handler-property: -> posi.optional-handler-property ...

  module: (m) -> require "modules/pig/posi/#{m}"
  noco: (m) -> require "modules/pig/posi/noco/#{m}"
  optional-module: (m) -> u.optional-module "modules/pig/posi/#{m}"

  surch: -> posi.module "surch"

  $node: (node) ->
    $node = $("\#posi-node-#{node.ni}")
    if $node.length == 0
      throw "node #{node.inspect!} not found in DOM"
    $node

  node: ($node) ->
    throw 'not a node' unless $node.hasClass('posi-node')
    throw 'no data-ni' unless ni = $node.data('ni')
    throw 'node not found' unless node = repo.node(ni)
    node


  select-node: (node, dbg-source) ->
    if node
      console.log "select-node", node.inspect!, "(source:", dbg-source, ")"
      $node = posi.$node(node)
      cursor.set $node

  element-present: ($el) ->
    $el.closest('body').length > 0

  export-to-frontend: (node) ->
    find-jsmodule = (node) ->
      iter-node = node
      while iter-node
        if iter-node.type! == n.jsmodule
          return iter-node
        iter-node = iter-node.parent!

    node = find-jsmodule(node)
    posi.export-to-javascript(node, export-method: 'frontend')

  export-to-javascript: (node, {export-method} = {}) ->
    if export-method
      posi.export-with-method node, {export-method}
    else
      ui.select 'Export mode',
        'run', 'deploy', 'display-code', 'display-ast', 'frontend', 'experiment', 'test'
      .done (export-method) ->
        #u.info export-method
        posi.export-with-method node, {export-method}

  export-with-method: (node, {export-method}) ->
    genjs = require './noco/prog/-genjs'

    jsconv = (code) ->
      $.ajax do
        type: 'post'
        url: '/jsconv'
        data: code
        contentType: 'text/javascript'

    switch export-method
    case \run
      ast = genjs(node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        $.ajax do
          type: 'post'
          url: '/ploy'
          data:
            mode: "run"
            user_token: u.sticky-id('user_token')
            contents: code
        .done (r) ->
          console.log "Code sent for deployment. Response:", r
          ui.popupTextarea r.output, select: false
        .fail (r) ->
          console.log "Run failed", r
          u.err "Run failed."

    case \deploy
      ast = genjs(node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        #console.log 'CODE:'
        #console.log code
        $.ajax do
          type: 'post'
          url: '/ploy'
          data:
            mode: 'service'
            user_token: u.sticky-id('user_token'),
            contents: code
        .done (r) ->
          console.log "Code sent for deployment. Response:", r
          if r.url
            u.show-message 'success', 'App exported, opening in a new window...'
            setTimeout (-> window.open r.url, "_blank"), 1000
          else
            u.err "Deployment failed."
        .fail (r) ->
          console.log "Deployment failed", r
          u.err "Deployment failed."

    case \display-code
      ast = genjs(node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        ui.popupTextarea code, select: true

    case \display-ast
      ast = genjs(node)
      ui.popupTextarea JSON.stringify(ast, null, 4), select: true

    case \frontend
      jsmodule = node.closest-ancestor-of-type(n.jsmodule, true)
      if ! jsmodule
        u.ierr "No jsmodule found."
        return
      file-name = "#{jsmodule.name!}.js"
      u.info "Generating #{file-name}"
      ast = genjs(jsmodule, is-module: true)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        #console.log 'CODE:'
        #console.log code
        $.ajax do
          type: 'post'
          url: '/ploy'
          data:
            mode: 'frontend'
            name: file-name
            user_token: u.sticky-id('user_token'),
            contents: code
        .done (r) ->
          console.log "Code sent for deployment. Response:", r
          if r.success
            u.show-message 'success', "Written to #{file-name}"
          else
            u.err "Deployment failed."
        .fail (r) ->
          console.log "Deployment failed", r
          u.err "Deployment failed."

    case \experiment
      file-name = "#{node.name!}.js"
      ast = genjs(node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        #console.log 'CODE:'
        #console.log code
        $.ajax do
          type: 'post'
          url: '/ploy'
          data:
            mode: 'experiment'
            name: file-name
            user_token: u.sticky-id('user_token'),
            contents: code
        .done (r) ->
          console.log "Code sent for deployment. Response:", r
          if r.success
            u.show-message 'success', "Written to #{file-name}"
          else
            u.err "Deployment failed."
        .fail (r) ->
          console.log "Deployment failed", r
          u.err "Deployment failed."

    case \test
      test-node =
        node.closest-ancestor-of-type(n.te-test, true) ||
        node.closest-ancestor-of-type(n.function, true)?.rn(n.te-test-r)
      if ! test-node
        u.ierr "No test found."
        return
      ast = genjs(test-node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        $.ajax do
          type: 'post'
          url: '/ploy'
          data:
            mode: "run"
            user_token: u.sticky-id('user_token')
            contents: code
        .fail (r) ->
          console.log "Run failed", r
          u.err "Run failed."
        .done (r) ->
          console.log "Code run response:", r
          test-results = JSON.parse r.output
          console.log 'test-results:', test-results
          if test-results.success
            u.success "Test passed (#{test-results.passed})"
          else
            msg =
              test-results.failures
              |> map (f) -> "#{f.testName}: #{f.exprText}"
              |> join '\n'
            u.ierr "Test failed (#{test-results.failed})\n#{msg}"



  find-appendable-blank: ($reft) ->
    posi.find-elements-within($reft, '.posi-prop-append', '.posi-prop')[0]

  guess-and-convert-type: (v) ->
    if JSON.stringify(i = parseInt(v)) == v
      i
    else if JSON.stringify(f = parseFloat(v)) == v
      f
    else if v == 'true' || v == 'yes'
      true
    else if v == 'false' || v == 'no'
      false
    else if v == 'null' || v == 'nil'
      null
    else if v[0] == '"' && v[v.length - 1] == '"'
      v.substring(1, v.length - 1)
    else if v[0] == "'"
      v.substring(1, v.length)
    else
      v

  is-clipboard-present: ->
    localStorage['clipboard-mode']?
  is-moving: ->
    localStorage['clipboard-mode'] == 'cut'

  finish-move: ({new-parent,ref-type,$el,before-ref}) ->
    ni = localStorage['clipboard'] or "clipboard empty"
    mode = localStorage['clipboard-mode'] or "clipboard-mode empty"
    if mode == 'cut'
      localStorage.removeItem 'clipboard'
      localStorage.removeItem 'clipboard-mode'
    node = repo.node(ni) or throw "node not found: #{ni}"
    if mode == 'cut'
      node.cMove({source: new-parent, ref-type, before-ref})
      posi.select-node node
    else
      new-node = node.deepCopy({new-parent, ref-type, before-ref})
      posi.select-node new-node


  swap-item: (node, direction) ->
    ref = node.parent-ref!
    parent = ref.source!
    refs = parent.refsWithType(ref.type!)
    index = refs.indexOf(ref)
    if direction == 1
      before-ref = refs[index + 2]
    else
      before-ref = refs[index - 1]

    node.cMove({source: parent, ref-type: ref.type!, before-ref})
    posi.select-node node


  handle-end-result: (r) ->
    posi.select-node(r.new-node) if r


  navigateToNode: (node, opts) ->
    cursor.remove!
    actions.navigateToNode(node, "posi/#{pig.workspace!}", opts)

  navigateToNodeId: (id, opts) ->
    cursor.remove!
    actions.navigateToNodeId(id, "posi/#{pig.workspace!}", opts)

  motion: (direction, deep) ->
    $el = cursor.$currentElem
    return if ! $el || ! $el.length
    if deep
      if direction == 1
        $child = posi.children($el)[0]
        if $child
          $new-el = $child
        else
          # Uncle = parent's sibling, or parent's parent's (...) sibling
          $new-el = posi.nearby-sibling-or-uncle($el, direction)
      else
        if ($sibling = posi.nearby-sibling($el, direction)) && $sibling.length
          $new-el = $sibling.find('.posi-elem:last')
          $new-el = $sibling if $new-el.length == 0
        else
          # Select parent
          $new-el = $el.parent!.closest('.posi-elem')
    else
      $sibling = posi.nearby-sibling($el, direction)
      if $sibling
        $new-el = $sibling
      else
        # No sibling found in that direction
        if direction == 1
          # Select parent's sibling
          $new-el = posi.parents-next-sibling($el)
        else
          # Select parent
          $new-el = $el.parent!.closest('.posi-elem')
    if $new-el && $new-el.length
      cursor.set($new-el)

  # Idea: extract .posi-nav-line related code to a different place
  line-motion: (direction) ->
    $el = cursor.$currentElem

    # find current posi-nav-line
    $current-line = $el.find('.posi-nav-line:first')
    return if $current-line.length == 0
    $current-line.css('border-color', '#3c3')

    $found = posi.find-next-prev-in-tree(direction, $current-line, '.posi-nav-line')
    console.log "NEXT: ", $found
    if $found
      # TODO: take into account .posi-unit's
      $node = $found.closest('.posi-node')
      cursor.set($node)

  find-next-prev-in-tree: (direction, $el, selector) ->
    # try following/previous siblings, find first/last .posi-nav-line
    # if none find => try the same for the parent
    next-prev-all = if direction == 1 then 'nextAll' else 'prevAll'
    first-last    = if direction == 1 then 'first' else 'last'
    loop
      for sibling in $el[next-prev-all]!.toArray!
        $sibling = $ sibling
        if $sibling.is(selector)
          return $sibling
        $found = $sibling.find("#{selector}:#{first-last}")
        if $found.length > 0
          return $found
      $el = $el.parent!
      return null if !$el? || $el.length == 0

  nearby-sibling-or-uncle: ($el, direction) ->
    posi.nearby-sibling($el, direction) || posi.nearby-uncle($el, direction)


  nearby-uncle: ($el, direction) ->
    if ($parent = $el.parent!.closest('.posi-elem')).length
      $new-el = posi.nearby-sibling($parent, direction)
      if ! $new-el || $new-el.length == 0
        $new-el = posi.nearby-uncle($parent, direction)
      $new-el


  parents-next-sibling: ($el) ->
    if ($parent = $el.parent!.closest('.posi-elem')).length
      $new-el = posi.nearby-sibling($parent, 1)
      if ! $new-el
        $new-el = posi.parents-next-sibling($parent)
      $new-el


  nearby-sibling: ($el, direction) ->
    if $parent = $el.parent!.closest('.posi-node')
      items = posi.children $parent
      index = items |> prelude.find-index (item) ->
        item[0] == $el[0]
      new-index = index + direction
      if new-index >= 0 && new-index < items.length
        items[new-index]

  children: ($parent) ->
    posi.find-elements-within $parent, '.posi-elem', '.posi-elem'

  next-sibling: ($el) -> posi.nearby-sibling($el, 1)
  prev-sibling: ($el) -> posi.nearby-sibling($el, -1)

  select-nearby-sibling: (direction) ->
    $el = cursor.$currentElem
    if $new-el = posi.nearby-sibling($el, direction)
      cursor.set($new-el)


  #------------------ Folding
  is-unfolded: (ref) ->
    posi.unfolded ?= {}
    posi.unfolded[ref.ri] ?= box "#{ref.ri}-fold", false
    posi.unfolded[ref.ri].get!

  unfold: (ref) ->
    if ! posi.is-unfolded(ref)
      posi.unfolded[ref.ri].set(true)

  fold: (ref) ->
    if posi.is-unfolded(ref)
      posi.unfolded[ref.ri].set(false)

  toggle-fold: (ref) ->
    new-value = !posi.is-unfolded(ref)
    posi.unfolded[ref.ri].set new-value
