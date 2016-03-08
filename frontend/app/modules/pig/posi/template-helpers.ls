u = require 'lib/utils'
{map,each,concat,elem-index,filter} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'

tag = (tagName, hClass, ...elements) ->
  #console.log tagName, hClass, ...elements
  el = document.createElement tagName
  if hClass
    el.setAttribute \class, hClass
  elements = Array.prototype.slice.call elements
  add-children el, elements
  el

div = (hClass, ...elements) ->
  tag \div, hClass, ...elements

span = (hClass, ...elements) ->
  tag \span, hClass, ...elements

text = (s) ->
  document.createTextNode s || ''

add-children = (el, children) ->
  if u.is-array children
    if children.length > 0
      for child in children
        if child
          if u.is-array child
            add-children(el, child)
          else
            #console.log 'append-child', child, Object.prototype.toString.call(child)
            el.appendChild child
  else
    if children
      #console.log "appendChild", children
      el.appendChild children

ch = (el, children) ->
  el.innerHTML = ''
  add-children(el, children)


join = ->
  Array.prototype.slice.call arguments

compute-el = (el, name, f) ->
  compute name, ->
    el.innerHTML = ''
    add-children el, f!
  el

node-link = (node, label) ->
  el = document.createElement 'a'
  el.setAttribute 'href', "/posi/#{node.ni}"
  ch(el, label)
  el

blank = ({req,id} = {}) ->
  el = span "blank posi-elem blank-#{req && "required" || "optional"}",
    span "blank-box"
  if id
    el.setAttribute('id', id)
  el

line = ->
  args = Array.prototype.slice.call arguments
  children = args |> filter ((arg) -> arg)
  div 'posi-line', ...children

space = -> text '\u00A0' # &nbsp; to avoid inline-blocks collapsing to 0 width

lines = ->
  args = Array.prototype.slice.call arguments
  args |> map (arg) -> line arg

module.exports = th = {
  tag,div,span,text,
  join,compute-el,add-children,ch,node-link,blank,
  line,space,lines
}

