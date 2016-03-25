{map,each,concat,join} = prelude

debugNestLevel = 0

module.exports = u = window.u =
  ifnn: (obj, method, ...args) ->
    if obj && obj[method]
      console.log "obj.#{method}", obj[method]
      obj[method](...args)

  ifnnp: (obj, property, ...args) ->
    if obj
      obj[property]

  setHash: (hash) ->
    if history.replaceState?
      history.replaceState null, null, "##{hash}"
    else
      location.hash = "##{hash}"

  find-index: (collection, condition) ->
    i = 0
    foundIndex = null
    for item in collection
      foundIndex = i if condition(item)
      i++
    foundIndex

  find: (collection, condition) ->
    i = 0
    foundItem = null
    for item in collection
      if condition(item)
        foundItem = item
        break
      i++
    foundItem

  find-all: (collection, condition) ->
    i = 0
    result = []
    for item in collection
      result.push item if condition(item)
      i++
    result

  any: (collection, condition) ->
    for item in collection
      if condition(item)
        return true
    false

  round-robin-by-value: (collection, value) -->
    index = u.find-index collection, (item) -> item == value
    index = (index + 1) % collection.length
    collection[index]

  # Applies function to the text() of a jQuery element
  apply-fn-to-jq-text: (fn, $el) ->
    $el.text(fn($el.text!))


  scrollTo: ($el, $scrollee = null)->
    $scrollee ?= $('body')
    elTop = $el.offset().top
    elHeight = $el.height()
    scrollTop = $scrollee.scrollTop()
    topEdge = 20
    bottomEdge = 20
    winHeight = $(window).height()

    elTopMin = scrollTop + topEdge
    elTopMax = scrollTop + winHeight - elHeight - bottomEdge

    if elTop > elTopMax
      @scrollToOffset elTop - winHeight + elHeight + bottomEdge, $scrollee
    else if elTop < elTopMin
      @scrollToOffset elTop - topEdge, $scrollee

  scrollToTop: ($el, $scrollee = null)->
    elTop = $el.offset().top
    scrollTop = $scrollee.scrollTop()
    @scrollToOffset scrollTop + elTop, $scrollee

  scrollToOffset: (top, $scrollee = null)->
    $scrollee ?= $('body')
    $scrollee.scrollTop(top)

  contains: (haystack, needle) ->
    if @is-array(haystack)
      for x in haystack
        return true if x == needle
      false
    else
      haystack == needle


  to-array: (x) ->
    if @is-array(x)
      x
    else
      [x]

  is-array   : (x) -> @_prt(x) === '[object Array]'
  is-function: (x) -> @_prt(x) === '[object Function]'
  is-number  : (x) -> @_prt(x) === '[object Number]'
  is-boolean : (x) -> @_prt(x) === '[object Boolean]'
  is-string  : (x) -> @_prt(x) === '[object String]'
  is-object  : (x) -> @_prt(x) === '[object Object]'
  is-scalar  : (x) -> @is-number(x) || @is-boolean(x) || @is-string(x) || @is-null(x)

  first-key: (obj) ->
    for k, v of obj
      return k

  _prt: (x) -> Object.prototype.toString.call(x)


  call-if-func: (x) ->
    if @is-function(x)
      x()
    else
      x



  # Source:
  # http://stackoverflow.com/questions/4810841/how-can-i-pretty-print-json-using-javascript
  syntaxHighlight: (json) ->
    if (typeof json != 'string')
      json = JSON.stringify(json, undefined, 2)
    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

    regex = /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g

    json.replace regex, (mtch) ->
      cls = 'number'

      if (/^"/.test(mtch))
        if (/:$/.test(mtch))
          cls = 'key'
        else
          cls = 'string'
      else if (/true|false/.test(mtch))
        cls = 'boolean'
      else if (/null/.test(mtch))
        cls = 'null'
      '<span class="' + cls + '">' + mtch + '</span>'

  nextTick: (cb) ->
    setTimeout cb, 0

  delay: (milliseconds, cb) ->
    setTimeout cb, milliseconds

  promise-counter: 0
  promise: (...args) ->
    switch args.length
    when 1 then cb = args[0]
    when 2 then [title, cb] = args
    when 3 then [title, el, cb] = args
    else throw "Invalid number of arguments for promise()"
    promise-id = (u.promise-counter += 1)
    #debug = (!! title)
    debug = false
    if debug
      title = title + " (#{el.attr('id') || ''}) [#{el.data('inspect') || ''}]" if el
      title = "p-#{promise-id}#{(if title then " - #{title}" else "")}"

      $vis = $('<div>').addClass('promise-vis').text(title).data('time', (new Date()).getTime())
      if el
        $c = u.ensure-element('debug-cursor')
        $c.css 'top', el.offset!.top
        $c.css 'left', el.offset!.left
        $c.css 'width', el.width!
        $c.css 'height', el.height!
        $c.show!
        $c.fadeOut 1000
      $pane = u.ensure-element('promise-pane')
      if ($last = $pane.find('.promise-vis:last'))
        last-time = $last.data('time')
        elapsed = (new Date()).getTime() - parseInt(last-time)
        if elapsed >= 1000
          $vis.css('margin-top', "#{Math.round(Math.log(elapsed / 200))}px")
      $pane.append $vis
      console.log "Promise #{title}"
    d = $.Deferred!
     # u.delay 100, ->
    cb(d)
    if debug
      finish = (type, r) ->
        finish
        if $vis
          $result = $('<div>').text(JSON.stringify(r))
          $vis.append($result)
          $vis.addClass(type)
          setTimeout do
            -> $vis.hide!
            10000
        console.log "#{type} #{title}"

      d.done (r) -> finish('resolved', r)
      d.fail (r) -> finish('rejected', r)
    d.promise!

  promise-short: (...args) ->
    switch args.length
    when 1 then cb = args[0]
    when 2 then [title, cb] = args
    when 3 then [title, el, cb] = args
    else throw "Invalid number of arguments for promise()"
    promise-id = (u.promise-counter += 1)
    debug = (!! title)
    if debug
      if el
        title = title + " (#{el.attr('id')})"
      title = "p-#{promise-id}#{(if title then " - #{title}" else "")}"
      console.log "Promise[S] #{title}"
    d = $.Deferred!
    if debug
      d.done -> console.log "Resolved[S] #{title}"
      d.fail -> console.log "Failed[S] #{title}"
    setTimeout (-> d.resolve!), 1000
    d.promise!

  iterate: (arr, cb, i = 0) ->
    u.promise 'iterate', (d) ->
      if arr.length && i < arr.length
        iterPromise = u.promise 'iterate-elem', (iterD) ->
          #console.log "cb arr[#{i}]"
          cb arr[i], iterD
        iterPromise
          .done (iterR) ->
            #console.log "iterPromise.done"
            u.iterate(arr, cb, i+1) .done     (recurR) -> d.resolve([iterR] ++ recurR)
                                    .progress (recurR) -> d.notify(recurR)
                                    .fail     (recurR) -> d.reject(recurR)
          .progress (iterR) -> d.notify(iterR)
          .fail     (iterR) -> d.reject(iterR)
      else
        d.resolve!

  iterateF: (cbs, i = 0) ->
    u.promise 'iterateF' (d) ->
      if cbs.length && i < cbs.length
        #console.log "cbs[#{i}]"
        iterPromise = cbs[i]()
        iterPromise
          .done (iterR) ->
            #console.log "iterPromise.done"
            u.iterateF(cbs, i+1) .done (recurR) -> d.resolve([iterR] ++ recurR)
                                 .progress (recurR) -> d.notify(recurR)
                                 .fail     (recurR) -> d.reject(recurR)
          .progress (iterR) -> d.notify(iterR)
          .fail     (iterR) -> d.reject(iterR)
      else
        d.resolve!

  iterateFL: (cbs, i = 0) -> u.promise 'iterateFL', (d) ->
    u.iterateF(cbs, i) |> u.c d,
      location: 'iterateFL',
      done: (r) ->
        if r && u.is-array(r)
          d.resolve r[r.length - 1]
        else
          d.resolve r



  nextInElements: ($elements, $current) ->
    @neighbourInElements($elements, $current, 1)

  prevInElements: ($elements, $current) ->
    @neighbourInElements($elements, $current, -1)

  neighbourInElements: ($elements, $current, dir) ->
    currentIndex = null
    $elements.each (index) ->
      if this == $current[0]
        currentIndex := index
        return false
    if currentIndex != null
      newIndex = currentIndex + dir
      if newEl = $elements[newIndex]
        $(newEl)

  keyEventToChar: (ev) ->
    if ev.type == 'keydown'
      String.fromCharCode(ev.keyCode)

  debug: (mode, ...args) ->
    print = (...args) ->
      if mode
        indent = "  " * debugNestLevel
        loggerF =
          switch mode
          case \error then -> console.error ...arguments
          case \warn  then -> console.warn ...arguments
          else             -> console.log ...arguments
        loggerF indent, ...args
    print ...args


  debugCall: (mode,s,f) ->
    print = (msg) ->
      if mode
        indent = "  " * debugNestLevel
        loggerF =
          switch mode
          case \error then -> console.error it
          case \warn  then -> console.warn it
          else             -> console.log it
        loggerF "#{indent}#{msg}"

    print "-> #{s}"
    debugNestLevel += 1
    ret = f!
    debugNestLevel -= 1
    print "<- #{s}"
    ret

  camelize: (s) -> s.replace /(?:[-_])(\w)/g, (_, c) -> c && c.toUpperCase! || ''
  dromedarize: (s) -> s.replace /(?:^|[-_])(\w)/g, (_, c) -> c && c.toUpperCase! || ''

  optional-module: (s) ->
    try
      require(s)
    catch e
      if e.message.indexOf("Cannot find module \"#{s}\"") == 0
        #console.warn e.message
        null
      else
        throw e

  merge: (a,b) ->
    c = {}
    for k,v of a
      c[k] = v
    for k,v of b
      c[k] = v
    c

  array-delim: (a, d) ->
    if d
      b = []
      l = a.length
      for i from 0 to a.length - 2
        b.push a[i]
        d2 = (u.is-function(d) && d! || d)
        b.push d2
      b.push a[l-1]
      b
    else
      a

  # chain promise into deferred
  c: (deferred, opts = {}) ->
    (promise) ->

      promise.done     (r) ->
        console.log "promise.done (#{opts.location})", r
        if opts.done
          opts.done(r)
        else
          deferred.resolve(r)

      promise.progress (r) ->
        console.log "promise.progress (#{opts.location})", r
        if opts.progress
          opts.progress(r)
        else
          deferred.notify(r)

      promise.fail     (r) ->
        if opts.location
          console.log "promise.fail (#{opts.location})", r
        else
          console.log "promise.fail (#{opts.location})", r
        if opts.fail
          opts.fail(r)
        else
          deferred.reject(r)

  showMe: (el, label, cb) ->
    enabled = window.showMe
    timeout = 500
    if enabled
      $el = $(el)
      if $el.length == 0
        console.error "Can't show nothing (showEl)", el, label, cb
        throw "Can't show nothing"
      tmp = $el.css('border')
      $el.css('border', 'solid 2px yellow')
      o = $el.offset!
      console.log 'offset', o

      $label = $('#show-me-label')
      if $label.length == 0
        $('body').append('<div id="show-me-label"></div>')
        $label = $('#show-me-label')
      $label.css('left', "#{o.left}px")
      $label.css('top', "#{o.top - 20}px")
      $label.text(label)
      $label.show!

      backF = ->
        $label.hide!
        $el.css('border', tmp)
        cb!
      setTimeout backF, timeout
    else
      cb!

  each-with-index: (cb, collection) -->
    index = 0
    for item in collection
      cb(item, index)
      index := index + 1

  map-with-index: (cb, collection) -->
    a = []
    index = 0
    for item in collection
      a.push cb(item, index)
      index := index + 1
    a

  each-pair: (cb, hash) -->
    for key, value of hash
      cb(key, value)

  # Run a function when a deferred is resolved or rejected.
  #
  # cb - function accepting a deferred object; this utility creates a deferred object and exectues the ensurable when it's finished
  # d - the deferred to resolve when everything including the ensurable is executed
  # ensurable - function to be called when the cb resolves the deferred object passed to it
  ensure-after: (cb, d, ensurable) ->
    p2 = u.promise (d2) -> cb(d2)
    p2 |> u.c d,
      done: (r) -> ensurable!; d.resolve(r)
      fail: (r) -> ensurable!; d.reject(r)


  pad: (list, min-length, pad-item) ->
    if min-length
      while list.length < min-length
        list.push pad-item
    list

  add-if-empty: (list, item) ->
    if list.length == 0
      list.push item
    list

  find-in-tree-after: ($el, selector) ->
    $iter = $el
    while true
      $successors = $iter.nextAll!
      for item in $successors.toArray!
        $x = $ item
        if $x.is(selector)
          return $x
        $match = $x.find(selector)
        if $match.length > 0
          return $match.first!
      $iter = $iter.parent!
      return null if ! $iter
      return null if $iter.length == 0
      return null if $iter.is('body')

  ensure-element: (id) ->
    $el = $("##{id}")
    if $el.length == 0
      $el = $('<div>').attr('id', id)
      $('body').append($el)
    $el

  err: (s, opts = {}) ->
    u.show-message 'error', s
    throw new ProgramError(s) unless opts.raise == false

  uerr: (s) ->
    u.show-message 'error', s
    throw new UserError(s)

  ierr: (s) -> # informational error / does not raise exception
    u.show-message 'error', s

  warn: (s) ->
    u.show-message 'warning', s

  info: (s) ->
    u.show-message 'info', s

  success: (s) ->
    u.show-message 'success', s

  newlines-to-br-html: (s) ->
    esc = document.createTextNode(s)
    div = document.createElement('div')
    div.appendChild(esc)
    div.innerHTML.replace /\n/g, '<br/>'

  show-message: (kind, s) ->
    console.log "#{kind}: #{s}"
    $ctnr = u.ensure-element("messages")
    $el = $('<div>')
    u._show-message-count ?= 0
    current-num = u._show-message-count += 1
    $el.stop!

    $el.html u.newlines-to-br-html(s)

    $el.attr('class', "message #{kind}")
    $el.css('opacity', '1')
    $el.css('top', u._show-message-count * 40 + 'px')
    $ctnr.append($el)
    $ctnr.show!
    setTimeout do
      ->
        $el.fadeOut!
        if u._show-message-count == current-num
          # This is the last message, new message will be displayed at the top
          u._show-message-count = 0
          $ctnr.text ''
      3000

  lget: (name) -> local-storage.get-item name
  lset: (name, value) -> local-storage.set-item name, value
  lrem: (name) -> local-storage.remove-item name

  sticky-id: (name) ->
    unless (value = u.lget name)?
      u.lset name, (value = (Math.random! * 256^16).to-string(36))
    value

  # nextInDOM: (_selector, _subject) ->
  #
  #   getNext = (_subject) ->
  #     return _subject.next() if _subject.next().length > 0
  #     getNext(_subject.parent())
  #
  #   searchFor = (_selector, _subject) ->
  #     if(_subject.is(_selector))
  #       return _subject
  #     else
  #       found = null
  #       _subject.children().each ->
  #         found = searchFor(_selector, $(this))
  #         return false if found != null
  #       return found
  #     null
  #
  #   next = getNext(_subject)
  #   while (next.length != 0)
  #     found = searchFor(_selector, next)
  #     return found if found != nullle #     next = getNext(next)
  #   null

  random-string: include-generated 'random-string', -> (length = 10) -> # length 10 fits on <64 bits
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    n = chars.length
    s = ''
    for i from 1 to length
      s += chars[Math.floor(Math.random! * n)]
    s

  sort-by: (a, ranker) ->
    a.sort (a, b) ->
      ra = ranker(a)
      rb = ranker(b)
      if (ra < rb) then -1
                   else if (ra > rb) then 1
                                     else 0
    a

  join-non-blanks: (glue, ...list) ->
    result = ''
    for item in list
      if item? && item != ''
        result += " " unless result == ''
        result += item
    result

  is-visible: ($el) ->
    $el.css('display') != 'none' &&
    $el.css('visibility') != 'hidden' &&
    $el.width! > 0 &&
    $el.height! > 0

  debounce: (wait, func) ->
    var timeout
    ->
      args = arguments

      delayed-func = ->
        timeout := null
        func(...args)

      clearTimeout(timeout)
      timeout := setTimeout delayed-func, wait

  h: (s) ->
    if unsafe
      unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;")

  select-leaves: (els) ->
    els = els.to-array!
    leaves = []
    for el in els
      is-leaf = true
      for i-el in els
        if $.contains(el, i-el)
          console.log "CONTAINS"
          console.log el
          console.log i-el
          #console.log $(el).html().substr(0, 30), "CONTAINS",
                    #$(i-el).html().substr(0, 30)
          is-leaf = false
          break
      if is-leaf
        leaves.push $ el
    leaves





ProgramError = (message) ->
  @message = message

UserError = (message) ->
  @message = message

