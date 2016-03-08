{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'
{box,compute,bcg} = boxlib = require 'lib/box'

#module.exports = class Ref
module.exports = include-generated 'models/pig/ref', -> class Ref
  (repo, ri, sni, rti, gni, dep) ->
    @ri = ri
    repo.refs[@ri] = this
    @pSource = box "r#{ri}-s", repo.node(sni) or throw 'm'; @source = ~> @pSource.get!
    @pType   = box "r#{ri}-t", repo.node(rti) or throw 'm'; @type   = ~> @pType.get!
    @pTarget = box "r#{ri}-g", repo.node(gni) or throw 'm'; @target = ~> @pTarget.get!
    @pDep    = box "r#{ri}-d", dep       ; @dep    = ~> @pDep.get!

    pig = require 'models/pig'

    var pInspect
    @inspect = ~> pInspect ?:= bcg "#{@ri}-inspect", ~>
      "#{@ri}-#{@type!.name!}-dep:#{@dep!}"

    @next-sibling = ->
      refs = @source!.refsWithType(@type!)
      index = refs.indexOf(@)
      if index != -1
        refs[index+1]

    @setType = (ref-type) ~>
      @pType.set ref-type

    @setSource = (source) ~>
      @pSource.set source

    @cSetType = (ref-type) ~>
      pig.push-undo 'rtyp', {ri: @ri, rti: @type!.ni}
      pig.apply-pointy 'rtyp', {ref: @, ref-type}
      pig.command 'rtyp', {ri: @ri, rti: ref-type.ni}

    @cUnlink = ~>
      if @dep!
        console.error "Tried to unlink component ref:", @
        throw "Can't unlink component ref"
      else
        pig.push-undo 'link', {ri: @ri, rti: @type!.ni, sni: @source!.ni, gni: @target!.ni}
        pig.apply-pointy 'ulnk', {ref: @}
        pig.command 'ulnk', {ri: @ri}
