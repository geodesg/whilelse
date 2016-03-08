ui = require 'ui'
{map,each,concat,join,elem-index} = prelude
SearchView = require 'modules/search/view'
api = require 'api'


# Handles global events, that are independent from the current page.
#
module.exports = class GlobalHandler
  uiName: 'Common'

  keyCommands: ->
    return
      commands:

        * key: ['b', 'C-left']
          cmd: -> window.history.back!
          name: 'Back'
          desc: 'Navigate backwards in the history'
          group: 'nav'

        * key: ['S-b', 'C-right']
          cmd: -> window.history.forward!
          name: 'Forward'
          desc: 'Navigate forwards in the history'
          group: 'nav'

        #* key: 's'
          #cmd: ~> @search!
          #name: 'Search'
          #desc: 'Search node'
          #group: 'nav'

        * key: 'S-g'
          cmd: ~> @handleGlobalCommands!
          name: 'Global'
          desc: 'Global commands'
          group: 'nav'

        * key: 'C-h'
          name: 'Help'
          group: 'nav'
          cmd: ->
            sidebar = window.sidebar124 ?=
              $el: $('#sidebar')
              visible: true
              replace-contents: ($c) ->
                @$el.text('')
                @$el.append $c
              show: ->
                @visible = true
                @$el.show!
                $('#layout').add-class('left-sidebar-open')
              hide: ->
                @visible = false
                @$el.hide!
                $('#layout').remove-class('left-sidebar-open')
              toggle: ->
                if @visible
                  @hide!
                else
                  @show!

            if (($c = $('#guide')).length == 0)
              $c = $('<div id="guide">')
              console.log $c
              GuideView = require '/modules/guide/view'
              $c.append (new GuideView()).render!
              sidebar.replace-contents $c
              sidebar.show!
            else
              sidebar.toggle!

        * key: 'C-A-l'
          name: "Log out"
          group: 'nav'
          cmd: ->
            u.lrem 'username'
            #ui.navigate "/" # this would pushState

            # We need a crude navigation to restart the application
            # otherwise things will linger in the memory causing
            # all sorts of problems.
            # TODO: Better memory cleanup
            window.location.href = '/'

        * key: 'S-r'
          name: 'Refresh keys'
          group: 'debug'
          cmd: -> ui.refreshKeyCommands!

  handleGlobalCommands: ->
    ui.choose do
      title: 'Global Command'
      options:
        * key: 'f'
          name: "Favorites"
          action: ~> @selectFavorite!
        * key: 's'
          name: 'Search'
          action: ~> @search!
        * key: 'r'
          name: 'Root node'
          action: -> window.router.navigate '/n/9', trigger: true
        * key: 'x'
          name: 'Experiments'
          action: -> window.router.navigate '/gosi/120', trigger: true
        * key: 'a'
          name: 'Applications'
          action: -> {}
        * key: 'n'
          name: 'New window'
          action: -> window.open window.location.href, '_blank'
        # * key: 'a',
        #   name: 'API-overview',
        #   action: ~>
        #     api.ajax do
        #       url: '/meta/api-overview'
        #       success: (html) ->
        #         ui.htmlPopup(html)

  search: ->
    searchView = new SearchView
    console.log "searchView", searchView
    ui.showDialog searchView

  selectFavorite: ->
    makeOption = (key, name, path) ~>
      {
        key,
        name,
        action: ~> window.router.navigate path, trigger: true
      }

    ui.choose do
      title: 'Change view...'
      options:
        * makeOption(\p, \prog, '/n/116')
        * makeOption(\c, \core, '/n/112')
        * makeOption(\x, \experiments, '/n/120')
        * makeOption(\t, \templating, '/n/189')
        * makeOption(\n, \notes, '/n/304')


