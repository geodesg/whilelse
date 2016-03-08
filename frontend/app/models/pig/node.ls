{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'
{box,compute,bcg} = boxlib = require 'lib/box'

Schema = require './schema'
{n, repo} = require './common'

module.exports = include-generated 'models/pig/node', -> class Node
  (repo, @ni, nti, name, attrs) ->
    @repo = -> repo
    pName   = box "#{@ni}-n", name  ; @name  = ~> pName.get!
    pAttrs  = box "#{@ni}-a", attrs || {} ; @attrs = ~> pAttrs.get!
    pRefs   = box("#{@ni}-r", [])   ; @refs   = ~> pRefs.get!
    pInrefs = box("#{@ni}-i", [])   ; @inrefs = ~> pInrefs.get!
    repo.nodes[@ni] = this
    pType = box "#{@ni}-t", repo.node(nti) ; @type = ~> pType.get!

    pParentRef = box "#{@ni}-pr", null ; @parentRef = ~> pParentRef.get!
    pParent    = box "#{@ni}-p", null ; @parent    = ~> pParent.get!
    pCrumbs    = box "#{@ni}-cr", null ; @crumbs    = ~> pCrumbs.get!


    pAttrList = box "#{@ni}-al", null; @attrList = ~> pAttrList.get!

    compute "#{@ni}-attrlist", ~>
      list = []
      @attrs! |> u.each-pair (ati, val) ->
        list.push(ati: ati, type: (-> repo.node(ati)), value: (-> val))
      pAttrList.set list

    compute "#{@ni}-parentRef", ~>
      #console.log "computing parentRef for", @ni
      #console.log "@inrefs!", @inrefs!
      #console.log "|> find (.dep!)", (@inrefs! |> find (.dep!))
      pParentRef.set(parentRef = (@inrefs! |> find (.dep!)))

      if parentRef
        compute "#{@ni}-parent" ~>
          source = parentRef.pSource.get!
          pParent.set(source if parent)
      else
        pParent.set(undefined)


    var pAncestors
    @ancestors = ~> pAncestors ?:= bcg "#{@ni}-ancestors", ~>
      #u.debugCall \error, "compute #{@ni}-ancestors", ~>
        if parent = @parent!
          parent.ancestors! ++ [parent]
        else
          []

    var pSourceName
    @source-name = ~> pSourceName ?:= bcg "#{@ni}-srcname", ~>
      if @name!
        s = ''
        @ancestors! |> each (node) ->
          unless node == n.root || node == n.core
            s := s + "#{node.name!}/"
        typeSuffix = switch (type = @type!).ni
                     case '1' then ''
                     case '2' then '-a'
                     case '3' then '-r'
                     case '7' then ''
                     else "-#{type.name!}"
        "#{s}#{@name!}#{typeSuffix}"

    var pInspect
    @inspect = ~> pInspect ?:= bcg "#{@ni}-inspect", ~>
      "#{@ni}.#{@name! || ' '}-#{@type!.name!}"

    compute "#{@ni}-crumbs", ~>
      parent = @parent!
      parentCrumbs = (parent && parent.ni != '9' && parent.crumbs!) || ''
      name = @name!
      typeSuffix = switch (type = @type!).ni
                   case '1' then '-T'
                   case '2' then '-A'
                   case '3' then '-R'
                   case '7' then ''
                   else "-#{type.name!}"
      currentPart = "#{@ni}#{name && "-#{name}" || ''}#{typeSuffix}"
      @cr = "#{parentCrumbs}.#{currentPart}"
      pCrumbs.set @cr

    var pFq
    @fq = ~> pFq ?:= bcg "#{@ni}-fq", ~>
      if name = @name!
        parent = @parent!
        iter = parent
        containerFq = ""
        while iter && iter.ni != '9' # root
          if iName = iter.name!
            containerFq = iName + "." + containerFq
          iter = iter.parent!
        "#{containerFq}#{name}-#{@type!.name!}"

    @closest-ancestor-of-type = (type, include-self = false) ~>
      iter-node = @
      return iter-node if include-self && iter-node.type! == type
      while iter-node = iter-node.parent!
        if iter-node.type! == type
          return iter-node
      null

    pSchema = null
    @schema = ~>
      pSchema ?:=
        bcg "#{@ni}-schema", ~>
          type = @type!
          if type.ni == '1' # set schema only for node_type nodes
            schemas[ni] ?= new Schema(@) # ████████ (step-5)
          else
            throw "#{@inspect!} is not a node-type, it doesn't have a schema"

    p-super-type = null
    @super-type = ~> p-super-type ?:= bcg "#{@ni}-supertype", ~>
      if @type! == n.ntyp
        @rn(n.s-subtype-of)

    @is-subtype-of = (test-type) ~>
      if @type! == n.ntyp
        iter-type = @
        while iter-type
          if iter-type == test-type
            return true
          iter-type = iter-type.super-type!
        false

    @is-a = (test-type) ~> @type!.is-subtype-of(test-type)

    @compatible-types = ~> # itelf + subtypes
      if @type! == n.ntyp
        list = [@]
        expand-list = [@]
        while expand-list.length > 0
          expandee = expand-list.shift!

          # Subtypes through inref subtype-of
          direct-subtypes = (expandee.inrefsWithType(n.s-subtype-of) |> map (.source!))
          direct-subtypes |> each (subtype) ~>
            unless subtype in list
              list.push subtype
              expand-list.push subtype

          # Subtypes through subtype ref
          expandee.rns(n.s-subtype) |> each (subtype) ~>
            unless subtype in list
              list.push subtype
              expand-list.push subtype
        list
      else
        throw "compatible-types only available for node-type"

    #done
    @refWithType = (type) ~>
      @refs! |> find (ref) -> ref.type! == type

    #done
    @refsWithType = (type) ~>
      @refs! |> filter (ref) -> ref.type! == type

    #done
    @rn = @refNodeWithType = (type) ~>
      ref = @refWithType(type)
      ref.target! if ref

    #done
    @rns = @refNodesWithType = (type) ~>
      @refsWithType(type) |> map (ref) -> ref.target!

    #done
    @inrefsWithType = (type) ~>
      @inrefs! |> filter (ref) -> ref.type! == type

    #done
    @inrefNodesWithType = (type) ~>
      @inrefsWithType(type) |> map (ref) -> ref.source!

    @a = @attrByType = (type) ~>
      throw "no type given" if ! type
      if type == n.name
        @name!
      else
        @attrs![type.ni]


    @prev-sibling = ~> @nearby-sibling -1
    @next-sibling = ~> @nearby-sibling 1
    @nearby-sibling = (direction) ~>
      parent = @parent!
      reft = @parent-ref!.type!
      children = parent.rns(reft)
      index = children.index-of @
      if index == -1
        throw "Couldn't find node among the children of its parent: #{@inspect!} in #{parent.inspect!} (#{reft.inspect!}) "
      children[index + direction]


    @setName = (name) -> pName.set name
    @addRef = (ref, before-ref) -> addRef(pRefs, ref, before-ref)
    @addInref = (ref) -> addRef(pInrefs, ref)

    #=========================================================

    @setType = (type) -> pType.set type
    @setAttr = (type, value) ->
      a = pAttrs.get!
      if value?
        a[type.ni] = value
      else
        delete a[type.ni]
      pAttrs.set a

    @rmRef = (ref) -> rmRef(pRefs, ref)
    @rmInref = (ref) -> rmRef(pInrefs, ref)

    # c prefix := create a command && sync to backend (as opposed to just changing the model)

    pig = require 'models/pig'

    @cSetName = (name) ~>
      pig.push-undo "name", {ni: @ni, name: @name!}
      pig.command "name", {ni: @ni, name}
      pig.apply-pointy "name", {node: @, name}

    @cSetType = (node-type) ~>
      pig.push-undo "ntyp", {ni: @ni, nti: @type!.ni}
      pig.command "ntyp", {ni: @ni, nti: node-type.ni}
      pig.apply-pointy "ntyp", {node: @, node-type}

    @cSetAttr = (attr-type, value) ~>
      if attr-type == n.name
        @cSetName(value)
      else
        pig.push-undo "attr", {ni: @ni, ati: attr-type.ni, val: @a(attr-type)}
        pig.command "attr", {ni: @ni, ati: attr-type.ni, val: value}
        pig.apply-pointy "attr", {node: @, attr-type, value}

    @cAddComponent = (ref-type, node-type, name, {before-ref} = {}) ~>
      throw "ref-type missing" if ! ref-type
      throw "node-type missing" if ! node-type
      ni = pig.issue-new-id(repo)
      ri = pig.issue-new-id(repo)
      bri = before-ref && before-ref.ri
      pig.push-undo "del", {ni: ni}
      pig.command "comp", {ri, sni: @ni, rti: ref-type.ni, ni, nti: node-type.ni, name, bri: bri}
      pig.apply-pointy "comp", {ri, source: @, ref-type, ni, node-type, name, before-ref}


    @cAddLink = (ref-type, target) ~>
      throw "ref-type missing" if ! ref-type
      throw "target missing" if ! target
      ri = pig.issue-new-id(repo)
      pig.push-undo "ulnk", {ri: ri}
      pig.command "link", {ri, sni: @ni, rti: ref-type.ni, gni: target.ni}
      pig.apply-pointy "link", {ri, source: @, ref-type, target}

    @cDelete = ~>
      inlinksC = @inrefs!.length - 1 # substract parent
      refC = @refs!.length
      if inlinksC + refC > 0
        throw "Can't remove. There are #{refC} components & links and #{inlinksC} incoming links"
      else
        ref = @parent-ref!
        pig.push-undo "comp", {ri: ref.ri, sni: @parent!.ni, rti: ref.type!.ni, ni: @ni, name: @name!, nti: @type!.ni, bri: @next-sibling!?.parent-ref!?.ri, attrs: @attrs!}
        pig.apply-pointy "del", {node: @}
        pig.command "del", {ni: @ni}

    @cForceDelete = ~> pig.activity 'Forced Delete' ~>
      console.log @inspect!, "cForceDelete"
      refs = @refs! |> map (ref) -> ref # copy array
      while ref = refs.pop!
        if ref.dep!
          ref.target!.cForceDelete!
        else
          console.log "unlink"
          ref.cUnlink!
      refs = @inrefs! |> filter (ref) -> ! ref.dep!
      while ref = refs.pop!
        console.log @inspect!, "ref", ref
        unless ref.dep!
          ref.cUnlink!
      @cDelete!

    @cMove = ({source, ref-type, before-ref}) ~>
      throw "source missing" if ! source
      throw "ref-type missing" if ! ref-type
      bri = (if before-ref then before-ref.ri else null)
      pig.push-undo "move", {ni: @ni, sni: @parent!.ni, rti: @parent-ref!.type!.ni, bri: @next-sibling!?.parent-ref!?.ri}
      pig.command "move", {ni: @ni, sni: source.ni, rti: ref-type.ni, bri}
      pig.apply-pointy "move", {node: @, source, ref-type, before-ref}

    @deepCopy = ({new-parent, ref-type, before-ref} = {}) ~> pig.activity 'Copy', ~>
      new-parent := new-parent || @parent!
      ref-type := ref-type || @parent-ref!.type!
      #before-ref := before-ref || @next-sibling!?.parent-ref! if new-parent == @parent!

      new-node = new-parent.cAddComponent(ref-type, @type!, @name!, {before-ref})
      deep-copy-contents(@, new-node)
      new-node




addRef = (pRefList, ref, before-ref) ->
  #console.log "--- addRef", ref, pRefList
  a = pRefList.get!
  if before-ref
    index = a.index-of(before-ref)
    if index == -1
      console.error "pRefList.get!, ref, before-ref", a, ref, before-ref
      throw "before-ref not found in pRefList"
    a.splice(index, 0, ref)
  else
    a.push(ref)
  #console.log "pRefList.set", a
  pRefList.set(a)

rmRef = (pRefList, ref) ->
  a = pRefList.get!
  index = a.indexOf(ref)
  if index == -1
    throw "ref not found in reflist"
  else
    a.splice(index, 1)
  pRefList.set(a)


deep-copy-contents = (old, young) ->
  for ati, val of old.attrs!
    console.log ati, old.repo!.nodes[ati]
    young.cSetAttr old.repo!.nodes[ati], val

  for ref in old.refs!
    target = ref.target! or throw 'ref target not found'
    if ref.dep!
      new-child = young.cAddComponent(ref.type!, target.type!, target.name!)
      deep-copy-contents target, new-child
    else
      young.cAddLink(ref.type!, target)

