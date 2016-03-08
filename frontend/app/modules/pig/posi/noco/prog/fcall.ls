u = require 'lib/utils'
{map,each,concat,join,elem-index,filter,find} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'

module.exports = h = fcall-h =

  keyCommands: ->
    return
      defaults:
        group: 'function-call'
      commands: [
        * key: 'S-o'
          name: "Open function definition"
          cmd: ->
            if node = posi.cursor.node
              posi.navigateToNode(node.rn(n.callee-r))
        * key: 'S-p'
          name: "Set/edit parameter"
          cmd: ->
            fcall = posi.cursor.node
            fcall-h.choose-and-set-or-edit-parameter fcall
      ]

  apply-surch-result: (fcall, result) ->
    func = result.node
    if result.subject == 'this'
      fcall.cAddComponent n.subject-r, n.this
    else if result.subject && result.subject.type! == n.variable
      varref = fcall.cAddComponent n.subject-r, n.varref
      varref.cAddLink n.variable-r, result.subject
    fcall.cAddLink n.callee-r, func
    fcall-h.populate-args-from-func-params({fcall, func})

  populate-args-from-func-params: ({fcall, func}) ->
    get-formal-parameters({func}) |> each (parameter) ->
      console.log 'param: ', parameter.inspect!
      farg = fcall.cAddComponent n.func-arg-r, n.func-arg
      farg.cAddLink n.arg-param-r, parameter
      dt = parameter.rn(n.data-type-r)
      if dt && dt.type! == n.function-type
        if fsig = dt.rn(n.function-signature-r)
          func = farg.cAddComponent n.arg-expr-r, n.function, null
          func.cAddLink n.function-signature-r, fsig

  choose-and-set-or-edit-parameter: (fcall, func) ->
    unikey = new (require('lib/unikey'))
    ui.choose do
      title: "Select parameter"
      options: get-formal-parameters({fcall, func}) |> map (parameter) ->
        key: unikey.issue(parameter.name!)
        name: parameter.name!
        action: ->
          # Find func-arg
          func-arg = fcall.rns(n.func-arg-r) |> find (iter-func-arg) -> iter-func-arg.rn(n.arg-param-r) == parameter
          if func-arg
            posi.select-node(func-arg)
          else
            func-arg = fcall.cAddComponent n.func-arg-r, n.func-arg
            func-arg.cAddLink n.arg-param-r, parameter
            posi.select-node(func-arg)

  get-expr-type: (node) ->
    # Find signature's return type
    node.rn(n.callee-r)?.rn(n.function-signature-r)?.rn(n.data-type-r)




get-formal-parameters = ({func, fcall}) ->
  func ?= fcall.rn(n.callee-r)
  sig = func.rn(n.function-signature-r) || throw "no signature for function: #{func.inspect!}"
  sig.rns(n.parameter-r)

