{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{n,repo} = require 'models/pig/common'

module.exports = h =
  collect-endpoints: (app) ->
    route = app.rn(n.web-route-r)
    collect-route-endpoints(route, '')
    # Returns: Array of {method,path,func-node}


collect-route-endpoints = (route, path) ->
  ret = []
  endpoints = route.rns(n.web-endpoint-r)
  endpoints |> each (endpoint) ->
    ret.push do
      method: (endpoint.a(n.web-request-method-a) or throw "no request method for #{endpoint.inspect!}")
      path: (if path == '' then '/' else path)
      func-node: (endpoint.rn(n.main-function-r) or throw "no main function for #{endpoint.inspect!}")

  subpaths = route.rns(n.web-subpath-r)
  subpaths |> each (subpath) ->
    value = subpath.a(n.value-a) or throw "no path value found for #{subpath.inspect!}"
    iter-route = subpath.rn(n.web-route-r) or throw "no route found for #{subpath.inspect!}"
    iter-path = "#{path}/#{value}"
    ret := ret.concat collect-route-endpoints(iter-route, iter-path)

  ret
