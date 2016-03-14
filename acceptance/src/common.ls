webroot = 'http://localhost:8888/'
casper.options.viewport-size = width: 1000, height: 800

test = null

module.exports = u =
  verbose: false
  guide: true

  make-verbose: -> casper.then -> u.verbose = true

  test: (test-name, test-title, body-cb) ->
    casper.test.begin test-title, (_test) ->
      u.init _test, test-name, test-title
      body-cb!
      u.done test-name, test-title

  init: (_test, test-name, test-title) ->
    g.init test-name, test-title
    test := _test

  debug: (s) ->
    if u.verbose
      console.log s

  on-console-message: (msg, line, source) ->
    if u.verbose
      console.log "console> ", msg

  open: (url, type) ->
    if url
      casper.start url, -> u.report-err ~>
        @page.on-console-message = u.on-console-message
      u.wait-for-toplevel-node-with-type type if type
    else
      u.open-experiments!

  open-experiments: ->
    u.open webroot + 'posi/experiments/acJbSfPVJsJo?sync=sandbox&gen=1', 'container'

  open-example-application: ->
    u.open webroot + 'posi/experiments/acTeO2ouW4Mg?sync=sandbox&gen=1', 'application'

  open-test-application: ->
    u.open webroot + 'posi/experiments/acKcHE6vIhts?sync=sandbox&gen=1', 'application'

  open-homepage-unsandboxed: ->
    u.open webroot + 'gen=1'


  report-err: (f) ->
    ret = null
    try ret = f! catch e
      casper.echo "ERROR: " + e
      casper.exit!
    ret

  unixtime: -> Math.floor(Date.now() / 1000)

  then: -> casper.then ...arguments
  eval: (...args) -> casper.then -> casper.evaluate ...args

  wait-for-input: ->
    casper.then -> u.debug "wait-for-input"
    casper.wait-for -> u.report-err ~> @page.evaluate -> (el = document.activeElement) && el?.tagName == 'INPUT'
  then-type: (s) -> casper.then ->
    u.debug "then-type #{s}"
    u.report-err ~>
      g.type s
      u.press-keys s.split('')
  type: -> u.then-type ...arguments
  then-press: (...list) -> casper.then ->
    u.debug "then-press #{list}"
    u.report-err ~>
      g.press-keys list
      u.press-keys(list)
  press: -> u.then-press ...arguments
  wait-for-chooser: (titl) -> casper.wait-for -> u.report-err ~> @page.evaluate do
    (titl) -> $('.chooser-view > .title').text() == titl
    titl

  wait-for-surch-selection: (kind, name) -> u.report-err ~>
    casper.then ->
      u.debug "wait-for-surch-selection <#{kind},#{name}>"
      g.comment "\"#{kind} #{name}\" should appear"
    casper.wait-for -> casper.evaluate do
      (kind, name) ->
        r-kind = $('#surch > .results > .match.current > .kind').text!
        r-name = $('#surch > .results > .match.current > .name').text!
        r-value = $('#surch > .results > .match.current > .value').text!
        console.log r-kind, r-name, r-value
        r-kind == kind && (r-name == name || r-value == name)
      kind, name

  wait-for-element: (selector) -> u.report-err ~>
    casper.wait-for -> casper.evaluate do
      (selector) -> $(selector).length
      selector

  step: (name) ->
    casper.then ->
      g.step name
      if u.verbose
        casper.echo "\nStep: #{name}\n"

  wrap-with-operator: (symbol, name) ->
    u.step "Operator #{symbol}"
    u.surch symbol, null, 'operator', name

  surch: (trigger-key, search-string, exp-kind, exp-name) ->
    u.then-type trigger-key if trigger-key
    u.wait-for-input!
    u.then-type search-string if search-string
    u.wait-for-surch-selection exp-kind, exp-name
    u.then-press 'Enter'

  screenshot: -> casper.wait 100, ->
    casper.echo "--- SCREENSHOT ---"
    homeDir = require('system').env.HOME
    screenshotsDir = homeDir + '/tmp/screenshots'
    @capture "#{screenshotsDir}/casper.png"

  press-keys: (list, cont-cb) ->
    u.press-keys-recurs(list, cont-cb)

  press-keys-recurs: (list, cont-cb) ->
    page = casper.page
    if elem = list.shift!
      if elem[0] == '…'
        ms = 10 * Math.pow(10, (1+elem.length)/2) # 1=>100, 2=>316, 3=>1000, 4=>3162
        wait ms, -> u.press-keys-recurs(list, cont-cb)
      else
        u.debug "KEY #{elem}"
        if /^[SCAM]\-/.test(elem)
          parts = elem.split('-')
        else
          parts = [elem]
        elem = parts.pop!
        modifier = 0
        for p in parts
          modifier +=
            switch p
            when 'S' then 0x02000000
            when 'C' then 0x04000000
            when 'A' then 0x08000000
            when 'M' then 0x10000000


        elem = 'Escape' if elem == 'Esc'
        # https://github.com/ariya/phantomjs/commit/cab2635e66d74b7e665c44400b8b20a8f225153a
        key = find-key(page, elem)
        throw "key not found: #{elem}" if ! key
        # Uppercase if it's a letter and shift is pressed
        key = key.toUpperCase! if key.toUppeerCase && modifier .&. 0x02000000
        page.send-event 'keypress', key, null, null, modifier
        u.press-keys-recurs(list, cont-cb)
    else
      cont-cb! if cont-cb


  enter-param: (name, type-key) ->
    u.step "Param #{name}"
    u.wait-for-input!
    u.then-press name, 'Enter'
    u.wait-for-chooser 'Select Type'
    u.then-press type-key

  assert-textarea-popup: (_test, expectation-message, expected-content) ->
    _test ?= test
    u.wait-for-element '#textarea-popup'
    casper.then ->
      _test.assert-equal do
        casper.evaluate -> $('#textarea-popup textarea').val!
        expected-content
        "- #{expectation-message}"

  wait-for-toplevel-node-with-type: (expected-type) ->
    casper.wait-for ->
      casper.evaluate do
        (expected-type) -> $('#main>.posi>.posi-node').data('inspect').indexOf("-#{expected-type}") != -1
        expected-type

  expect-current-node-name: (expected-name) ->
    casper.then ->
      test.assert-equal do
        casper.evaluate -> posi.cursor.node.name()
        expected-name

  select-node: (ni) ->
    casper.then ->
      casper.evaluate do
        (ni) -> posi.select-node pig.repo.node(ni)
        ni

  expect-node-visible: (ni) ->
    casper.then ->
      test.assert do
        casper.evaluate do
          (ni) -> $('#posi-node-' + ni).length > 0
          ni
        "- node #{ni} visible"

  expect-node-not-visible: (ni) ->
    casper.then ->
      test.assert do
        casper.evaluate do
          (ni) -> $('#posi-node-' + ni).length == 0
          ni
        "- node #{ni} not visible"

  expect-top-level-node: (ni) ->
    casper.then ->
      test.assert-equal do
        casper.evaluate -> $('#main>.posi>.posi-node').data('ni')
        ni
        "- toplevel node is #{ni}"

  surch-function: (s) -> u.surch null, s, 'function', s
  surch-literal: (s) ->
    s = '' + s
    u.surch null, s, 'literal', s
  surch-string: (s) -> u.surch null, "'#{s}", 'literal', s
  surch-variable: (s) -> u.surch null, s, 'variable', s
  surch-field: (s) -> u.surch null, s, 'field', s
  surch-command: (s) -> u.surch null, s, 'command', s
  tab: -> u.then-press 'Tab'
  esc: -> u.then-press 'Esc'
  enter: (s) ->
    if s
      u.wait-for-input!
      u.then-type s
    u.then-press 'Enter'
  enter-with-wait: (s, w = 200) ->
    if s
      u.wait-for-input!
      u.then-type s
    u.wait w
    u.then-press 'Enter'

  choose: (title, key) ->
    u.wait-for-chooser title
    u.then-press key

  select-type: (key, query) ->
    u.choose 'Select Type', key
    if key == '\\' # Other
      u.wait-for-input!
      u.then-type query
      u.wait 200
      u.enter!

  wait: (x) -> casper.wait x
  assign: -> u.surch ':', null, 'command', 'assign'

  add-declaration: (key) ->
    u.then-press 'a'
    u.choose 'Select property to add', 'd'
    u.choose 'Target type', key

  done: (test-name, test-title) ->
    casper.run ->
      g.done test-name, test-title
      test.done!

  assert: ->
    args = arguments
    casper.then -> test.assert ...args

  find: (q, num = 1) ->
    u.then-press 'A-f' # find on page
    u.wait-for-input!
    u.enter q
    # first match will be selected
    # press A-n (num-1) times
    for til num - 1
      u.then-press 'A-n' # select next match

  plus: ->
    u.surch '+', null, 'operator', 'add'



find-key = (page, elem) ->
  throw "no elem" if ! elem
  throw "elem is blank" if elem.length == 0
  if elem.length > 1
    k = page.event.key[elem]
    k ?= page.event.key[capitalize-first(elem)]
    key = k || elem
  else
    elem

capitalize-first = (s) ->
  s[0].toUpperCase! + s.slice(1)



g =
  init: (test-name, test-title) ->
    g.out = "#{test-title}\n\n"
    g.html = "<html><head>\n"
    g.html += "<title>#{h test-title}</title>\n"
    g.html += "<link rel='stylesheet' type='text/css' href='./style.css'>"
    g.html += "</head><body>\n"
    g.html += "<h1>#{h test-title}</h1>\n"

  done: (test-name, test-title) ->
    return if ! u.guide
    g.html += "</body></html>"
    fs = require 'fs'
    fs.write "guides/#{test-name}.html", g.html, 'w'
    #casper.echo g.out
    g.out = ""

  type: (s) ->
    g.out += "type: #{s}\n"
    g.html += "<p>Type <span class='type'>#{h s}</span></p>\n"
  press-keys: (list) ->
    g.out += 'press:'
    g.html += "<p>Press\n"
    for item in list
      g.out += " [#{item}]"
      g.html += "<span class='key'>#{h item}</span>\n"
    g.out += '\n'
    g.html += "</p>\n"

  step: (name) ->
    g.out += "\n=== #{name} ===\n"
    g.html += "<h2>#{h name}</h2>\n"

  comment: (s) ->
    g.out += "#{s}\n"
    g.html += "<p>#{h s}</p>"


h = (unsafe) ->
  if unsafe
    ('' + unsafe)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")
