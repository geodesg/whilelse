u = require 'lib/utils'
{map,each,filter,any,concat,join,elem-index,sort-by,maximum} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
cursor = require 'modules/pig/posi/cursor'

module.exports = h = templating =
  surch: (opts) ->
    console.log "Templating surch opts", opts
    posi.surch!.start do
      u.merge opts,
        search: (q) ->
          results = []
          add = (kind, type, value, {node} = {}) ->
            results.push do
              keywords: []
              value: value
              kind: kind
              ni: type.ni
              node: node || type
              type: type
              handler-node: type
          switch q[0]
          case '<'
            add 'tag', n.t-tag, q.slice(1)
          case '=', '-'
            add 'slot', n.t-slot, q.slice(1)
          else
            # Match the beginning of tag type
            matching-tag-types = tag-types |> filter (t) -> t.indexOf(q) == 0
            matching-tag-types |> each (t) ->
              add 'tag', n.t-tag, t

            # Match the beginning of EACH command
            add 'each', n.t-each, 'each' if 'each'.indexOf(q) == 0

          # Collect paramters from template
          find-params-in-scope(opts.parent) |> each (param) ->
            console.log "PARAM: ", param
            name = param.name!
            if name.indexOf(q) == 0
              add 'param', n.t-param-slot, name, node: param

          add 'text', n.t-text, q
          console.log "results", results
          results

find-template = (node) ->
  iter-node = node
  while iter-node
    if iter-node.type! == n.t-template
      return iter-node
    iter-node = iter-node.parent!

  throw "no template found for #{node.inspect!}"

find-params-in-scope = (node) ->
  params = []
  iter-node = node
  while iter-node
    params = params ++ iter-node.rns(n.t-param-r)
    if iter-node.type! == n.t-template
      return params
    iter-node = iter-node.parent!

  throw "no template found for #{node.inspect!}"

tag-types = <[
html
base
head
body
style
title
address
article
h1
h2
h3
h4
h5
h6
hgroup
nav
section
dd
div
dl
figcaption
hr
li
main
ol
p
pre
ul
abbr
b
bdi
bdo
br
cite
data
dfn
em
i
kbd
mark
q
rp
rt
rtc
ruby
s
samp
small
span
strong
sub
sup
time
u
var
wbr
area
audio
map
track
video
embed
object
param
source
canvas
noscript
script
del
ins
caption
col
colgroup
table
tbody
td
tfoot
th
thead
tr
button
datalist
fieldset
form
input
keygen
label
legend
meter
optgroup
option
output
progress
select
details
dialog
menu
menuitem
summary
content
decorator
element
shadow
template
acronym
applet
basefont
big
blink
center
dir
frame
frameset
isindex
listing
noembed
plaintext
spacer
strike
tt
xmp
]>


