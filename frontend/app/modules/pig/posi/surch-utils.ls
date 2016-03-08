u = require 'lib/utils'
{map,each,filter,any,concat,join,elem-index,sort-by,maximum,compact} = prelude
{n,repo} = require 'models/pig/common'

module.exports = surch-utils =

  keywords-for-node: (node) ->
    keywords = node.rns(n.keyword-r) |> map (keyword-node) -> keyword-node.a(n.value-a)
    keywords.push(node.name!) if node.name!
    keywords

  # matches: Array of match
  # match: {keywords}
  #
  prioritise-matches: (matches, {q}) ->
    #console.log JSON.stringify matches
    matches |> sort-by (m) -> - match-score(q, m)

match-score = (q, m) ->
  full-match-multiplier =
    maximum do
      (m.keywords ++ [m.display]) |> compact |> map (keyword) ->

        x =
          if keyword == q
            1000 # complete match
          else
            maximum [
              substring-score(q, keyword)
              word-start-score(q, keyword)
            ]
        #console.log keyword, ' => ', x
        x

  kind-multiplier =
    switch m.kind
    case 'variable' then 2 # scoped variables have higher priority than commands/functions/etc"
    case 'function value' then 0.5 # function should be higher than function-value
    else 1

  v = full-match-multiplier * kind-multiplier
  #console.log "rank: ", v, JSON.stringify(m)
  v

substring-score = (q, keyword) ->
  qi = keyword.index-of(q)
  #console.log "qi: #{qi}", -keyword.length
  if qi == 0
    100 - keyword.length
  else if qi > 0
    10 - keyword.length
  else
    1 - keyword.length

word-start-score = (q, keyword) ->
  # Regexp: - start matching at ._- or the beginning
  #         - should match the first character from the string
  #         - then it should match either - the next character,
  #                                       - or anything then ._- then the next character
  # E.g.        core.node_type-node_type
  #       ntnt       n    t    n    t
  #       noty       no   ty
  r = new RegExp "[$\._\-]#{(q.split('') |> map (x) -> regexp-escape(x)).join('(.*[\._\-])?')}"
  x =
    if r.test(keyword)
      80 - keyword.length
    else
      -1000
  #console.log "word-start-score", x
  x

regexp-escape-regexp = /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/
regexp-escape = (s) ->
  s.replace(regexp-escape-regexp, '\\$&')


