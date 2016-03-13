# Exporter
#   Sends the code to the Ploy app via AJAX for running or deployment.

{promise,promise-short,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude

module.exports = e =

  export-with-method: (node, {export-method}) ->
    genjs = require './noco/prog/-genjs'

    switch export-method
    case \run
      # Run and display output
      ast = genjs(node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        ploy code, 'run' .done (r) ->
          ui.popupTextarea r.output, select: false

    case \deploy
      # Deploy web service and open it in a new window
      ast = genjs(node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        ploy code, 'service'
          .done (r) ->
            u.show-message 'success', 'App exported, opening in a new window...'
            setTimeout (-> window.open r.url, "_blank"), 1000

    case \display-code
      # Display generated code
      ast = genjs(node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        ui.popupTextarea code, select: true

    case \display-ast
      # Display generated AST (Abstract Syntax Tree)
      ast = genjs(node)
      ui.popupTextarea JSON.stringify(ast, null, 4), select: true

    case \frontend
      # Place code into the generated/ directory of the frontend code of Whilelse
      jsmodule = node.closest-ancestor-of-type(n.jsmodule, true)
      if ! jsmodule
        u.ierr "No jsmodule found."
        return
      file-name = "#{jsmodule.name!}.js"
      u.info "Generating #{file-name}"
      ast = genjs(jsmodule, is-module: true)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        ploy code, 'frontend', data: { name: file-name }
          .done (r) ->
            u.show-message 'success', "Written to #{file-name}"

    case \experiment
      # Place code in a file in the experiments directory
      file-name = "#{node.name!}.js"
      ast = genjs(node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        ploy code, 'experiment', data: { name: file-name }
        .done (r) ->
          u.show-message 'success', "Written to #{file-name}"

    case \test
      # Run test and display results
      # - works from within a test or from a function that has an associated test
      test-node =
        node.closest-ancestor-of-type(n.te-test, true) ||
        node.closest-ancestor-of-type(n.function, true)?.rn(n.te-test-r)
      if ! test-node
        u.ierr "No test found."
        return
      ast = genjs(test-node)
      code = escodegen.generate ast
      jsconv(code).done (code) ->
        ploy code, 'run'
        .done (r) ->
          test-results = JSON.parse r.output
          if test-results.success
            u.success "Test passed (#{test-results.passed})"
          else
            msg =
              test-results.failures
              |> map (f) -> "#{f.testName}: #{f.exprText}"
              |> join '\n'
            u.ierr "Test failed (#{test-results.failed})\n#{msg}"


jsconv = (code) ->
  $.ajax do
    type: 'post'
    url: '/jsconv'
    data: code
    contentType: 'text/javascript'

ploy = (code, mode, opts = {}) -> promise (d) ->
  $.ajax do
    type: 'post'
    url: '/ploy'
    data: u.merge({
      mode: mode
      user_token: u.sticky-id('user_token')
      contents: code
    }, (opts.data || {}))
  .done (r) ->
    console.log "Code sent for deployment. Response:", r
    if r.success
      d.resolve r
    else
      d.reject r
  .fail (r) ->
    console.log "Run failed", r
    u.err "Export failed."
    d.reject r

