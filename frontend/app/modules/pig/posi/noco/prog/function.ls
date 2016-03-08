{promise,ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index,find} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'
prog = posi.module "noco/prog/-module"
expr-handler = posi.module "noco/prog/expr"
ui = require '/ui'

module.exports = h =
  select-as-target: ({parent, $el}) -> promise (d) ->
    d.resolve node-type: n.function

  keyCommands: ->
    return
      defaults:
        group: 'function'
      commands:
        * key: 'S-m'
          name: 'Implementation mode'
          label: 'mode'
          cmd: ->
            node = posi.cursor.node
            ui.choose do
              title: 'Select implementation mode...'
              options:
                * key: 'r'
                  name: 'regular'
                  action: ->
                    node.cSetAttr(n.implemented-natively-a, false)
                * key: 'n'
                  name: 'native'
                  action: ->
                    node.cSetAttr(n.implemented-natively-a, true)
        * key: 'S-e' # Edit native code
          name: 'Edit native code'
          label: 'native'
          cmd: ->
            node = posi.cursor.node
            method = h.find-native-implementation-method(node, create: true)
            value = method.a(n.native-code-a)
            ui.editValue value, (new-value) ->
              method.cSetAttr(n.native-code-a, new-value)

        * key: 'S-a'
          name: 'Async mode'
          label: 'async'
          cmd: ->
            node = posi.cursor.node
            ui.choose do
              title: 'Async function?'
              options:
                * key: 'r'
                  name: 'regular'
                  action: ->
                    node.cSetAttr(n.async-a, false)
                * key: 'a'
                  name: 'asynchronous return'
                  action: ->
                    node.cSetAttr(n.async-a, true)

        * key: 'S-t'
          name: 'Jump to test'
          label: 'test'
          cmd: ->
            # Jump to test (create if doesn't exist)
            if node = posi.cursor.node
              test = node.rn(n.te-test-r) || node.cAddComponent(n.te-test-r, n.te-test)
              posi.navigateToNode test

  find-native-implementation-method: (node, options = {}) ->
    h.find-with-link do
      node
      n.node-method-r
      n.native-method
      n.method-type-r
      n.native-implementation-m
      options

  # Find a component that has a certain link;
  # If the `create` flag is true, it creates one if not found.
  #
  # Desired setup:
  #   node --refType--@ <node-type> --tRefType--> tTarget
  #
  # E.g. find or create native implementation:
  #   node --nodeMethod--@ <native-method> --methodType--> native-implementation
  #
  find-with-link: (node, ref-type, node-type, t-ref-type, t-target, {create} = {}) ->
    needle = node.rns(ref-type) |> find (candidate) ->
      ctarget = candidate.rn(t-ref-type)
      ctarget && ctarget == t-target && candidate.type! == node-type

    if ! needle && create
      needle = node.cAddComponent(ref-type, node-type)
      needle.cAddLink(t-ref-type, t-target)

    needle

  create-in-closest-scope: (node, name, surch-deferred) ->
    scope = prog.find-closest-scope(node)
    func = scope.cAddComponent n.declaration-r, n.function, name

    # complete function then call surch-deferred (create fcall)
    posi.complete-node-p(posi.$node(func))
      .done ->
        surch-deferred.resolve do
          keywords: [func.name!]
          kind: 'function'
          name: func.name!
          ni: func.ni
          node: func
          handler-node: n.fcall




