require! 'fs'
require! 'escodegen'
require! 'esprima'

{each,map,find,filter} = _ = require 'prelude-ls'

test-files = <[ add add2 if if2 switch while fizzbuzz redis redisapp program ]>
#test-files = <[ program ]>

show-successful-results = false
write-expected-output = false

test-files |> each (name) ->
  fs.read-file "fixtures/#{name}.in.js", (err, data) ->
    throw err if err
    original-code = data.toString!
    tree = esprima.parse(original-code)

  #----------------------------------------------------------------------------

    #console.log "\n" * 20
    #console.log "\n---------- BEFORE ----------\n"
    #original-code = escodegen.generate tree
    #console.log code
    #fs.write-file "fixtures/#{name}.in.js", code
    #console.log JSON.stringify tree, null, 2
    #process.exit!

    convert-program(tree)

    #console.log "TREE"
    #console.log JSON.stringify(tree, null, 2)

    #console.log "\n---------- AFTER ----------\n"
    code = escodegen.generate tree
    #console.log code

    if write-expected-output
      fs.write-file "fixtures/#{name}.out.js", code
      console.log "WRITTEN: #{name}"
    else
      fs.read-file "fixtures/#{name}.out.js", (err, data) ->
        expected-code = data.toString!
        #fs.write-file "fixtures/#{name}.out.js", code

        if code != expected-code || show-successful-results
          console.log "Test: #{name}\n"
          console.log side-by-side ["Original:\n\n#{original-code}", "Expected:\n\n#{expected-code}", "Actual:\n\n#{code}"]
          #console.log JSON.stringify(expected-code)
          #console.log JSON.stringify(code)

        if code != expected-code
          console.log "FAILED: #{name}"
          process.exit!
        else
          console.log "SUCCESS: #{name}"


    #fs.write-file "fixtures/#{name}.out.json", JSON.stringify(tree, null, 2)
    code

convert-program = require './converter'


side-by-side = (a) ->
  cols = a.length

  lines-s = a |> map (content) -> content.split("\n")
  widths = lines-s |> map (lines) -> lines |> map ((line) -> line.length) |> _.maximum

  rows = lines-s |> (map (.length)) |> _.maximum

  (
    [0 to rows - 1] |> map (row) ->
      (
        [0 to cols - 1].map (col) ->
          pad(lines-s[col][row], widths[col])
      ).join('  |  ')
  ).join("\n")



pad = (s, len) ->
  s ?= ''
  if (pad-len = len - s.length) > 0
    s + " " * pad-len
  else
    s
