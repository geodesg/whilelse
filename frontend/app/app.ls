window.show-time = (title) ->
  console.log 'TIME', title, (new Date()).getTime! - window.appStartTime
show-time 'app.ls'

window.prelude = require './prelude-ls'

try-require = (m) ->
  try
    require m
  catch e
    if e.message.indexOf("Cannot find module \"#{m}\"") == 0
      return null
    else
      throw e

window.include-generated = (name, fallback-func) ->
  # Include:
  # - generated-stable version, if exists
  # - generated version if gen=1
  # - fallback version
  if gen
    require "generated/#{name}"
  else
    try-require("generated-stable/#{name}") ||
      (if fallback-func then fallback-func!) ||
      try-require("generated/#{name}") ||
      throw "Couldn't find module #{name}"

get-query-params = ->
  query = window.location.search.substr 1
  vars = query.split '&'
  params = {}
  for v in vars
    pair = v.split '='
    key = decodeURIComponent pair[0]
    val = decodeURIComponent pair[1]
    params[key] = val
  params

window.params = get-query-params!
console.log "QUERY PARAMS", window.params
window.gen = window.location.href.indexOf('gen=1') != -1
window.sync-mode = window.params.sync || 'remote-write'

window.generateObjectId = -> undefined # FIXME: don't generate generateObjectId call when not defined


require! {
  '/ui'
  '/modules/home/view': HomeView
  '/modules/pig/node/view': PigNodeView
  '/modules/pig/posi/view': PosiView
  '/ui/global-handler': GlobalHandler
  '/lib/utils': u
}
{map, each} = prelude

WorkspaceRouter = Backbone.Router.extend(
  routes:
    "": "home"
    "health": "health"
    "login": "login"
    "x/:name": "experiment"
    "pig": "pig"
    "pn/:id": "pigNode"
    "posi/:workspace/:id": "posi"
    "posi/:workspace/": "posi"
    "posi/:workspace": "posi"
    "posi-gen/:workspace/:id": "posi"
    "posi-gen/:workspace/": "posi"
    "posi-gen/:workspace": "posi"
    "*notFound": 'notFound'

  notFound: ->
    $('#main').html('<div class="error">Path Not Found</div> <a href="/">Home</a>')

  home: ->
    #view = new HomeView()
    #ui.setMainView view
    username = u.lget 'username'
    if username && username.length > 0
      window.router.navigate "/posi/#{username}", trigger: true
    else
      window.router.navigate "/login", trigger: true


  experiment: (name) ->
    console.log "experiment: ", name
    ExperimentView = require "/modules/experiments/#{name}"
    view = new ExperimentView()
    console.log 'view', view
    ui.setMainView view

  health: ->

  login: ->
    LoginView = require "/modules/login/view"
    view = new LoginView()
    ui.setMainView view

  pig: ->
    ui.setMainView new (require '/modules/pig/view')()

  pigNode: (id) ->
    console.log "pig-node", id
    view = new PigNodeView model: id
    ui.setMainView view

  posi: (workspace, id) ->
    console.log "posi", id
    document.title = workspace + " – Whilelse"
    view = new PosiView model: {workspace, id}
    ui.setMainView view

)
router = new WorkspaceRouter
window.router = router


module.exports = class App
    ~>

    init: ->
      $('body').addClass('option-generated') if gen

      $('body').data('loaded', 'ok')

      window.onerror = (msg, url, lineno) ->
        console.log "error", arguments
        unless msg == 'Uncaught [object Object]'
          u.err msg, raise: false

      window.ui = ui

      ui.global-handler = new GlobalHandler
      ui.start!

      Backbone.history.start({pushState: true})

      $('a').live 'click', ->
        router.navigate $(this).attr('href'), trigger: true
        false


