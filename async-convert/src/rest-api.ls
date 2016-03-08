require! 'fs'
require! 'express'
require! 'body-parser'
app = express!
app.use body-parser.text type: 'text/javascript'

convert = require './converter'

require! 'escodegen'
require! 'esprima'

app.post '/jsconv', (req, res) ->
  original-code = req.body.toString!
  tree = esprima.parse(original-code)
  convert(tree)
  res.send escodegen.generate tree

server = app.listen 3024, ->
  host = server.address!.address
  port = server.address!.port
  console.log 'Listening on http://%s:%s', host, port


