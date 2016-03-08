{map,each,concat,join,elem-index} = prelude
module.exports = class UniKey
  -> @used = {}

  internal-index: 0

  issue: (text, index) ->
    throw "text is empty" if ! text
    for c in @candidates(text)
      unless @used[c]
        @used[c] = true
        return c
    "#{index || (@internal-index += 1)}"

  candidates: (s) ->
    heads = []
    tails = []
    s.split(/[^a-zA-Z0-9]+/) |> each (part) ->
      heads.push(part[0])
      part.substr(1).split('') |> each (c) ->
        tails.push c
    a = heads.concat(tails)
    #console.log "candidates", a
    a


