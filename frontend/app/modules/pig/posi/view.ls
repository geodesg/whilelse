{promise,c} = u = require 'lib/utils'
{map,each,filter,concat,join,elem-index,compact,unique-by} = prelude

{box,compute,bcg,cbox} = boxlib = require 'lib/box'
cursor = require 'modules/pig/posi/cursor'

pig = require 'models/pig'
{n, repo} = common = require 'models/pig/common'
actions = require 'modules/pig/node/actions'
window.repo = repo
window.n = n

{tag,div,span,text,join,compute-el} = th = require 'modules/pig/posi/template-helpers'

currentRenderNestLevel = 0

posi = require 'modules/pig/posi/main'
br = require 'modules/pig/posi/bridges'

PosiInfoView = require './info/view'

human-info = include-generated 'utils/human-info'

class PosiView extends Backbone.View
  id: "posi-container"

  initialize: ->
    {@workspace, @id} = @model
    window.workspace = @workspace
    cursor.start do
      onChange: (node, reft, parent) ->
        $status = $('#status')
        if $status.length == 0
          $status = $('<div>').attr('id', 'status')
          $('#main > .posi').append($status)
        $status.text human-info(cursor.$currentElem)

  build: ->
    { id: @model }

  template: (data) -> require("./template") data

  generate: ->
    $e = $('<div>').html(@template!)
    $e

  handlerForOwn: (node) ->
    throw "node missing in handlerForOwn" if ! node
    u.optional-module "modules/pig/posi/noco/#{node.source-name!}"

  handlerFor: (node) ->
    throw "node missing in handlerFor" if ! node
    @handlerForOwn(node.type!) ||
      @handlerForOwn(n.node) ||
        throw "No handler for #{node.ni} #{node.name!}"

  templateForOwn: (node, mode) ->
    h = @handlerForOwn(node)
    h && (h[mode] || h['generic'])

  templateFor: (node, mode) ->
    # templates =
    #   _common: # fallback for all nodes
    #     full: (node,o)->
    #     link: (node,o)->
    #     ...
    #   prog:
    #     _common: # fallback for nodes under prog
    #       full: (node,o)->
    #       ...
    #     function:
    #       full: (node,o)->
    #       ...

    templates = require 'modules/pig/posi/noco/-templates'
    #console.log "source-name:", node.type!.source-name!
    components = node.type!.source-name!.split('/') # E.g.: prog/function
    #console.log "components", components
    ts = [templates._common]
    iter = templates
    #console.log iter
    for c in components # c in ['prog','function']
      #console.log "c", c
      nested = iter[c] # templates['prog']
      break if ! nested
      ts.unshift(nested._common || nested)
      iter = nested # iter = templates['prog']
    #console.log 'ts', ts

    # ts: [templates.prog.function, templates.prog, templates._common]
    if ts[0] && u.is-function(ts[0])
      return ts[0]
    for t in ts
      #console.log "t", t
      if t[mode]
        return t[mode]

    throw "No template for #{node.inspect!} mode:#{mode}"

  render: ->
    @$el.html('<div id="posi"></div><div id="status"></div>')
    $posi = @$el.find('#posi')
    console.log "RENDER"
    ni = @id

    loaded = false
    setTimeout((~> $posi.html('Loading...') unless loaded), 200)

    pig.load! .done ~> u.delay 1, ~> # delay to let @$el be inserted to the document first (when pig.load! resolves instantly)
      console.log "loaded"
      loaded := true
      #boxlib.startDebug!

      if !ni
        navigateToNodeId pig.document-root-ni || repo.raw?.root || '9', replace: true
      else
        @node = node = repo.node(ni) || throw "node not found: #{ni}"

        if @$el.closest('body').length == 0
          throw '@$el is not attached'
        el = $posi.get(0)
        el.innerHTML = ''
        #console.log "renderedNode", @renderNode node
        th.add-children el, @renderNode node
        u.delay 1, ~> cursor.set posi.$node(node)

        posi.info = new PosiInfoView()
        posi.info.hide!
        $posi.append(posi.info.render!)

        #     # TEMP
        #     setTimeout do
        #       ~> posi.export-to-javascript @node
        #       100
        #
        #     #r = escodegen.generate do
        #     #  type: 'BinaryExpression'
        #     #  operator: '+'
        #     #  left: { type: 'Literal', value: 40 }
        #     #  right: { type: 'Literal', value: 2 }
        #     #console.log r
        #
        #     # /TEMP

    @$el

  renderNode: (node, mode = 'full', o = {}) ->
    #console.log "renderNode", mode, node.inspect!, o
    throw "node missing in renderNode" if ! node
    classes-str = u.join-non-blanks ' ',
      "posi-node"
      "posi-elem"
      "posi-node-#{mode}#{o.linked && " posi-linked" || ''}"
      "posi-unit" if o.unit
      "posi-#{node.type!.name!}-node"
      "posi-major" if o.major
    el = div classes-str
    el.setAttribute 'data-ni', node.ni
    el.setAttribute 'data-inspect', node.inspect!
    el.setAttribute 'id', "posi-node-#{node.ni}"
    delete o.major
    compute "posi-node-#{node.ni}-#{mode}", async: true, ~>
      th.ch el, @renderPart(node, mode, o)
    el

  renderPart: (node, mode = 'full', o = {}) ->
    throw "node missing in renderPart" if ! node
    el = div mode
    compute "posi-node-#{node.ni}-part-#{mode}", async: true, ~>
      currentRenderNestLevel := currentRenderNestLevel + 1
      try
        template = @templateFor(node, mode)
        #console.log "T", node.inspect!, mode, template
        builtEl = template node, u.merge o,
          mode: mode
          level: currentRenderNestLevel
          part: (mode, node, o, oo) ~>
            @renderPart node, mode, u.merge(o,oo)
          node: (mode, node, o, oo) ~>
            #console.log mode, node.inspect!, o, oo
            @renderNode node, mode, u.merge(o,oo)
        #console.log "T", node.inspect!, mode, " => ", builtEl

        #console.log "updating element in posi:#{node.ni}-#{mode}"
        el.innerHTML = ''
        #console.error node.crumbs!, mode, builtEl
        th.add-children el, builtEl
        #console.warn node.crumbs!, mode, el
      #catch e
        #console.error "Error while rendering", node, mode
        #console.error e
        #"ERROR"
      finally
        currentRenderNestLevel := currentRenderNestLevel - 1
    #console.warn node.crumbs!, mode, el
    el

  keyCommands: ->
    return
      before:
        * ~>
            if cursor.node
              posi.handler-for(cursor.node.type!)
        * ~>
            if cursor.node
              posi.module-handler-for(cursor.node.type!)
      commands:

        * key: 's'
          name: 'Search'
          group: 'nav'
          desc: 'Search nodes and navigate to selected node.'
          cmd: ->
            actions.search-and-goto "posi/#{pig.workspace!}"

        * key: 'S-a'
          name: 'Append sibling...'
          group: 'edit'
          desc: 'Append a new sibling to the end.'
          cmd: ~> @append-sibling!

        * key: 'a'
          name: 'Add child...'
          group: 'edit'
          desc: 'Add a new child node.'
          cmd: ~> @add-child!

        * key: 'e'
          name: 'Edit'
          group: 'edit'
          cmd: ~> @edit!

        * key: 'A-e'
          name: 'Special Edit'
          group: 'special edit'
          desc: 'Special edit.'
          cmd: ~> @edit-special!

        * key: 'd'
          name: 'Delete'
          group: 'edit'
          desc: 'Delete element with all its components.'
          cmd: ~> @delete!

        * key: 'g'
          name: 'Go to...'
          group: 'nav'
          desc: 'Navigate to a related page, e.g. parent. Select specifics on the next menu.'
          cmd: ~> @goSomewhere!

        * key: 'v'
          name: 'View...'
          group: 'nav'
          desc: 'Change to a different representation of the top-level node.'
          cmd: ~>
            cursor.remove!
            actions.change-view @id

        * key: 'o'
          name: 'Open'
          group: 'nav'
          desc: 'Open selected node in a new view.'
          cmd: ~>
            node = cursor.node
            if node
              navigateToNode cursor.node
            else
              console.warn "No current node."

        * key: 'l'
          name: 'Complete'
          group: 'edit'
          desc: 'Complete / fill in a blank or all the blanks within the element.'
          cmd: ~> @complete!

        * key: 'S-j'
          name: 'Export to Javascript'
          label: 'export js'
          desc: 'Generate Javascript code. Details on next menu.'
          group: 'file'
          cmd: ~> posi.export-to-javascript cursor.node

        * key: 'C-j'
          name: 'Export to Frontend'
          label: 'export to FE'
          desc: 'Export code to front-end. Development-only.'
          group: 'file'
          cmd: ~> posi.export-to-frontend cursor.node

        * key: 'b'
          name: 'Back'
          group: 'nav'
          desc: 'Go back to the previous page / view.'
          cmd: ~> window.history.back!

        * key: 'esc'
          name: 'Select parent'
          group: 'cursor'
          desc: 'Move cursor to parent node.'
          cmd: ~>
            if cursor.$parent && cursor.$parent.length
              cursor.set cursor.$parent

        * key: 'tab'
          name: 'Next blank'
          group: 'edit'
          desc: 'Find next blank and complete it.'
          cmd: ~>
            r = posi.resume!
            unless r
              complete-next-blank = ->
                $iter = cursor.$currentElem
                $blank = $iter.find('.blank:first')
                if $blank.length == 0
                  $blank = u.find-in-tree-after $iter, '.blank'
                if $blank && $blank.length > 0
                  posi.complete-blank-p $blank .fail (r) ->
                    if r && r.skip
                      complete-next-blank!
              complete-next-blank!

        # * key: "S-s"
        #   name: "Toggle sync"
        #   group: 'debug'
        #   cmd: ->
        #     throw "Removed" # workspace is now a document name
        #     #if pig.workspace! != 'central-write'
        #       #url = location.href.replace pig.workspace!, 'central-write'
        #       #window.open url, "_blank"

        * key: 'x'
          name: "Cut"
          group: 'edit'
          desc: "Cut element to be pasted somewhere else. ISSUE: if you remove its parent the cut element is destroyed so you can't paste it."
          cmd: ~>
            if node = cursor.node
              ancestor-id = cursor.$currentElem.parent!.closest('.posi-prop, .posi-node').attr('id')
              parent-ref = node.parentRef!
              localStorage['clipboard'] = node.ni
              localStorage['clipboard-mode'] = 'cut'
              parent-ref.cSetType(n.tmp-r)
              cursor.remove!
              cursor.set $("##{ancestor-id}").find('.blank:first')

        * key: 'p'
          name: "Paste"
          group: 'edit'
          desc: "Paste copied or cut element into blank."
          cmd: ~>
            if ($el = cursor.$currentElem) && cursor.$currentElem.hasClass('blank')
              if posi.is-clipboard-present!
                $pEl = $el.closest('.posi-propt, .posi-node')
                if $pEl.hasClass 'posi-reft'
                  new-parent = posi.node $pEl.closest('.posi-node')
                  ref-type = repo.node($pEl.data('rti'))
                  posi.finish-move({new-parent, ref-type, $el})
                else if $pEl.hasClass 'posi-node'
                  # Paste in place of a blank node
                  node = posi.node $pEl
                  new-parent = node.parent! or throw 'no parent'
                  ref-type = node.parent-ref!.type! or throw 'no ref-type'
                  before-ref = node.next-sibling!.parent-ref!
                  if before-ref.source! != new-parent
                    console.error "before-ref doesn't belong to new parent. before-ref.source!:",  before-ref.source!.inspect!, "new-parent:", new-parent.inspect!
                    throw "before-ref doesn't belong to new parent"
                  node.cDelete!
                  posi.finish-move({new-parent, ref-type, $el, before-ref})


        * key: 'S-up'
          name: "Move up"
          group: 'edit'
          desc: "Swap element with previous sibling."
          cmd: ~> posi.swap-item(cursor.node, -1) if cursor.node

        * key: 'S-down'
          name: "Move down"
          group: 'edit'
          desc: "Swap element with next sibling."
          cmd: ~> posi.swap-item(cursor.node, 1) if cursor.node

        * key: 'S-i'
          name: 'Show info'
          group: 'debug'
          cmd: ~> posi.info.inspect-element(cursor.$currentElem)

        * key: 'A-S-i'
          name: 'Hide info'
          group: 'debug'
          cmd: ~> posi.info.hide!

        #* key: 'A-S-d'
          #name: 'Clear local storage'
          #group: 'debug'
          #cmd: ->
            #local-storage.clear!
            #location.href = '/'

        * key: 'j'
          name: 'Next sibling'
          group: 'cursor'
          cmd: -> posi.select-nearby-sibling(1)

        * key: 'k'
          name: 'Previous sibling'
          group: 'cursor'
          cmd: -> posi.select-nearby-sibling(-1)

        * key: 'down',
          name: 'Next',
          group: 'cursor',
          desc: 'Move cursor to the next sibling or an closest ancestor\'s next sibling where it exists.'
          cmd: -> posi.motion( 1, false)

        * key: 'up',
          name: 'Prev',
          group: 'cursor',
          desc: 'Move cursor to the previous sibling or the parent.'
          cmd: -> posi.motion(-1, false)

        * key: 'A-down',
          name: 'Next deep',
          group: 'cursor',
          desc: "Deep next – Move cursor to first child or next sibling or ancestor's next sibling – next node in the pre-order traversal."
          cmd: -> posi.motion( 1, true)

        * key: 'A-up',
          name: 'Prev deep',
          group: 'cursor',
          desc: "Deep previous – Move cursor to previous sibling's or ancestor's previous sibling's last descendant - previous node in the pre-order traverasal."
          cmd: -> posi.motion(-1, true)

        * key: 'C-d'
          name: 'Duplicate'
          group: 'edit'
          desc: 'Copy element and add as a sibling.'
          cmd: ~>
            if node = cursor.node
              new-node = node.deepCopy(before-ref: node.next-sibling!?.parent-ref!)
              posi.select-node new-node

        * key: 'C-c'
          name: 'Copy'
          group: 'edit'
          desc: 'Mark element for copying. Can be pasted into a blank element.'
          cmd: ~>
            if node = cursor.node
              localStorage['clipboard'] = node.ni
              localStorage['clipboard-mode'] = 'copy'

        * key: 'y'
          name: 'Major ancestor'
          label: 'ancestor'
          desc: 'Select the nearest containing statement, function, application or other major element.'
          group: 'cursor'
          cmd: ->
            if ($el = cursor.$currentElem) &&
              ($major = $el.parent!.closest('.posi-major')).length &&
              ($new-el = $major.closest('.posi-elem')).length
              cursor.set $new-el

        * key: 'h'
          name: 'Child'
          group: 'cursor'
          desc: 'Select first child'
          cmd: ->
            if ($el = cursor.$currentElem)
              if $child = posi.children($el)[0]
                cursor.set $child

        * key: 'c'
          name: 'Move cursor...'
          group: 'cursor'
          cmd: ->
            if ($el = cursor.$currentElem)
              $children = posi.children($el)
              console.log $children.length, $children
              i = 0
              $container = u.ensure-element('marker-container')
              $container.text ''
              table = {}
              for $child in $children
                if u.is-visible $child
                  i += 1
                  $marker = $('<div>').addClass('marker').text('' + i)
                  offset = $child.offset!
                  $marker.css('top', '' + (offset.top) + 'px')
                  $marker.css('left', '' + (offset.left) + 'px')
                  console.log 'marker', $marker.html!
                  $container.append $marker
                  table['' + i] = $child
              if i > 0
                ui.activateInvisibleControl do
                  onKey: (keycode, ev) ->
                    if $el = table[keycode]
                      cursor.set $el
                      @close!
                      $container.text ''
                    else if keycode == 'esc'
                      @close!
                      $container.text ''
                    true

        * key: 'S-w'
          name: 'Unwrap'
          desc: "Replace the parent expression with the selected expression. E.g. unwrap i from log(i) or unwrap a from a + 1."
          group: 'edit'
          cmd: ->
            if ($el = cursor.$currentElem) && $el.hasClass('posi-node')
              node = posi.node($el)
              if ((h = posi.handler-for(node.type!)) && (f = h.unwrap)) ||
                ((h = posi.module-handler-for(node.type!)) && (f = h.unwrap))
                f($el, node)

        * key: 'u'
          name: 'Undo'
          group: 'edit'
          desc: 'Undo last action.'
          cmd: ->
            pig.undo!
            cursor.update!

        * key: 'C-A-t'
          name: 'Show expression type'
          group: 'view'
          label: 'type'
          desc: 'Show the inferred data type of the selected expression.'
          cmd: ->
            if node = cursor.node
              type = posi.handler-for(n.expr).get-expr-type(node)
              if type
                u.info type.inspect!
              else
                u.info 'unknown'

        * key: 'f'
          name: 'Fold/Unfold'
          label: 'fold'
          group: 'view'
          desc: 'Fold/unfold selected element. Fold to hide details, unfold to view details.'
          cmd: ->
            if ($el = cursor.$currentElem)
              if ($ref = $el.closest('.posi-ref')).length == 1
                ri = $ref.data('ri') or throw "ri missing"
                ref = repo.ref(ri) or throw "ref #{ri} not found"
                posi.toggle-fold ref
                cursor.update!

        * key: 'A-f'
          label: 'find'
          name: 'Find text on page'
          group: 'cursor'
          desc: 'Search for an item on the current page by text.'
          cmd: ->
            ui.input(title: 'Find text on page').done ({value}) ->
              query = value
              lowercase-query = value.toLowerCase!

              # Find all text nodes within .posi-node
              xpath-result = document.evaluate('//*[contains(@class, \'posi-node\')]//text()', document, null, XPathResult.ANY_TYPE, null)
              els = []
              while text-node = xpath-result.iterateNext!
                # case-insensitive match
                if text-node.textContent.toLowerCase!.indexOf(lowercase-query) != -1
                  els.push text-node

              $els = els
                |> map (el) ->
                  $el = $(el.parentElement).closest '.posi-elem'
                  cursor.get-closest-unit $el
                |> filter ($el) -> $el.length > 0
                |> unique-by ($el) -> $el.get(0)

              if $els.length > 0
                posi.matches = $els
                posi.match-index = 0
                cursor.set posi.matches[posi.match-index]
              else
                posi.matches = null

        * key: 'A-n'
          label: 'next match'
          name: 'Select next match'
          group: 'cursor'
          desc: 'Select next match in of the last Find'
          cmd: ->
            if posi.matches
              posi.match-index = (posi.match-index + 1) % posi.matches.length
              cursor.set posi.matches[posi.match-index]

  goSomewhere: ->
    ui.choose(
      title: 'Go...'
      options: [
        { key: 'p',   name: 'to parent',  action: ~> @goToParent! }
      ]
    )

  goToParent: ->
    navigateToNode @node.parent!

  append-sibling: ->
    $reft = cursor.$reft
    unless $reft && $reft.length
      console.warn "Can't append sibling because no containing $reft was probably. Probably this is the top-level node."
      return

    rti = $reft.data('rti')
    $node = $reft.closest('.posi-node')
    $node.length || throw 'closest node not found'
    ni = $node.data('ni') || throw 'ni missing'
    node = repo.node(ni) || throw 'node not found'
    reft = repo.node(rti) || throw 'reft not found'
    sref = node.type!.schema!.ref-with-type(reft)

    $ref = posi.find-appendable-blank($reft)
    $ref.length ||
      throw "appendable blank not found"
    $el = $ref

    bReft = new br.BReft $reft
    #if posi.is-moving!
      #posi.finish-move({bReft, $el})
    #else
    posi.add-ref-and-complete({bReft, parent: node, sref, $el, reft}) .done posi.handle-end-result

  add-child: ->
    # Get a list of refs, display menu
    $node = cursor.$node
    return if ! $node || $node.length == 0
    $propts = posi.find-elements-within $node, '.posi-propt', '.posi-propt'

    if $propts.length == 0
      return
    else if $propts.length == 1
      posi.add-to-propt $propts[0] .done posi.handle-end-result
    else
      unikey = new (require('lib/unikey'))
      i = 1
      ui.choose do
        $anchor: $node
        title: "Select property to add"
        options: $propts |> map ($propt-el) ->
          name = $propt-el.data('name') || throw "no name for propt"
          key: unikey.issue(name, i)
          name: name
          action: ->
            posi.add-to-propt $propt-el .done posi.handle-end-result
      .then posi.handle-end-result

    # a) find props in DOM => need to get the name
    # b) find srefs & sattrs => might not be displayed in the view

    #


  edit: ->
    $el = cursor.$currentElem
    if $el.is('.posi-name')
      bName = new br.BName $el
      bName.edit!
    else if $el.is('.posi-attr')
      bAttr = new br.BAttr $el
      bAttr.edit!
    else if node = cursor.node
      if (h = posi.handler-for(node.type!)) && (f = h.edit)
        h.edit({node,$el}) .done ->
          cursor.update!

  edit-special: ->
    node = posi.cursor.node
    ui.choose do
      title: 'Edit special attribute...'
      options:
        [
          [ 'n', 'name', n.name ],
          [ 'd', 'description', n.desc ]
        ] |> map (spec) ->
          [key, name, attr-type] = spec
          key: key
          name: name
          action: ->
            orig-value = node.a(attr-type)
            ui.input({title: "Edit #{name}", $anchor: posi.cursor.currentElem, value: orig-value})
              .done ({value} = {}) ->
                node.cSetAttr(attr-type, value)
                posi.cursor.update!

  delete: ->
    node = cursor.node
    if ! node
      console.warn "No current node"
      return

    $ref = cursor.$el.closest('.posi-ref')
    ref-id = $ref.attr('id')
    select-element-after-removed = ->
      if ref-id
        if ($ref = $("##{ref-id}")).length > 0
          cursor.set($ref)
        else
          console.warn "ref #{ref-id} not found"
      else
        console.warn "ref-id blank"

    ref = repo.ref($ref.data('ri')) or throw "ref not found"
    if ! ref.dep!
      ref.cUnlink!
      select-element-after-removed!
    else
      #ui.confirm "Delete #{node.inspect!}?" .done -> # can Undo
      node.cForceDelete!
      select-element-after-removed!

  complete: ->
    posi.complete cursor.q

  toggle-bloat: ->
    $el = cursor.$currentElem
    $el.toggleClass('bloated')

  on-navigating-away: ->
    cursor.remove!

navigateToNode = posi.navigateToNode
navigateToNodeId = posi.navigateToNodeId

module.exports = PosiView



