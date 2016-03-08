{map,each,concat,join,elem-index,find} = prelude

# Observer library

stack = []
dependencies = [] # dependecies in the current stack frame { id => true }

# From http://stackoverflow.com/questions/2020670/javascript-object-id
globalBoxId = 0
nextId = -> globalBoxId += 1
#Object.prototype.boxId = ->
  #newId = nextId!
  #@boxId = -> newId
  #newId


window.gBoxes = gBoxes = {}        # boxId => box
window.gFuncs = gFuncs = {}    # functionId => function
window.gDependantFuncIds = gDependantFuncIds = {}   # boxId => Array of functionIds
window.gDependencyBoxIds = gDependencyBoxIds = {} # functionId => Array of boxIds

debug = false

workStack = []

removeFrom = (a, x) ->
  if (index = a.indexOf(x)) != -1
    a.splice(index, 1)

arrayUnique = (a) ->
  a.reduce ((p, c) ->
    if p.indexOf(c) < 0
      p.push c
    p
  ), []

boxCache = {}

tran = false
collected-hooks = []


module.exports = window.boxlib = boxlib =
  box: ->
    var name, v
    switch arguments.length
    #case 0 then ;
    #case 1 then [v] = arguments
    case 2 then [name, v] = arguments
    else throw "Invalid number of arguments: #{arguments}"

    b = new Box(v, name)
    gBoxes[b.id] = b
    #console.log "returning box", b
    b

  compute: ->
    opts = {}
    switch arguments.length
    when 2 then [name, f] = arguments
    when 3 then [name, opts, f] = arguments
    else ...

    throw "no name" if ! name
    throw "no f" if ! f
    name = uniqify(name)
    #console.log "compute", name

    f._boxFuncId ?= nextId!
    funcId = name

    # This function is called:
    # - initially
    # - whenever any dependencies change

    fWithDepCalc = ->
      withStack "compute:#{name}", ->
        stack.push dependencies
        dependencies := []
        #console.log "+ compute #{name} start" if debug

        # COMPUTATION
        returnValue = f! # ████████ (step-4) (step-7)

        #console.log "+ compute #{name} end" if debug
        #console.log "Collected dependencies:", dependencies
        dependencyBoxIds = arrayUnique dependencies
        #console.log "Collected dependencyBoxIds", dependencyBoxIds

        if previousDependencyBoxIds = gDependencyBoxIds[funcId]
          for boxId in previousDependencyBoxIds
            removeFrom(gDependantFuncIds[boxId], funcId)

        u.debug debug, "compute:#{name} depends on #{dependencyBoxIds}"
        gDependencyBoxIds[funcId] = dependencyBoxIds

        for boxId in dependencyBoxIds
          gDependantFuncIds[boxId] ?= []
          gDependantFuncIds[boxId].push(funcId)

        dependencies := stack.pop!

        returnValue

    #if opts.async
      #gFuncs[funcId] = ->
        #setTimeout fWithDepCalc, 0
    #else
    gFuncs[funcId] = fWithDepCalc
    fWithDepCalc! # ████████ (step-3)

  printState: ->
    console.log "Box state:"
    console.log gBoxes
    console.log gFuncs
    console.log gDependencyBoxIds
    console.log gDependantFuncIds
    console.log stack
    console.log dependencies

  # box-compute-get
  bcg: (name, f) ->
    throw "no name" if ! name
    throw "no f" if ! f
    u.debugCall debug, "bcg:#{name}", ->
      newBox = boxlib.box(name, null)
      boxlib.compute name, ->
        newBox.set f!
      newBox.get!

  # Cached box
  cbox: (name, f) ->
    throw "no name" if ! name
    throw "no f" if ! f
    b = box-cache[name]
    if ! b
      b = boxlib.box(name, null)
      box-cache[name] = b
      boxlib.compute name, ->
        f! # f is expected to set
    b.get!

  transaction: (cb) ->
    # Execute hooks only after the transaction is closed
    tran := true
    cb!
    tran := false

    hooks = collected-hooks
    collected-hooks := []
    hooks |> each (f) ->
      f!


  startDebug: -> debug := true
  stopDebug: -> debug := false

withStack = (name, f) ->
  u.debugCall debug, name, ->
    if workStack.indexOf(name) != -1
      console.error "Recursion detected", workStack, name
      throw "Recursion detected" #if workStack.length >= 20
    workStack.push(name)
    returnValue = f!
    poppedName = workStack.pop!
    if poppedName != name
      throw "popped name #{poppedName} does not match #{name}"
    returnValue


Box = (initialValue, name) ->
  innerValue = initialValue

  throw "Name not specified" if ! name
  throw "Name contains undefined" if name.indexOf('undefined') != -1

  @id = name
  @name = name

  @get = ~>
    #withStack "get:#{name}", ~>
      #console.log "get => #{innerValue}"
      dependencies.push(@id)
      #console.log "dependencies:", dependencies
      innerValue

  @set = (newValue) ~>
    u.debug debug, "set:#{name} = ", newValue
    withStack "set:#{name}", ~>
      #console.log "SET #{@id} =", newValue
      innerValue := newValue
      #console.log "gDependantFuncIds", gDependantFuncIds
      if a = gDependantFuncIds[@id]
        #console.log "gDependantFuncIds[@id]", a
        items = []
        for funcId in a
          items.push(funcId)
        u.debug debug, "set:#{name} notifies", items
        #notifyDependants = ->
        for funcId in items
          u.debug debug, "set:#{name} calling #{funcId}"
          if tran
            collected-hooks.push gFuncs[funcId]
          else
            gFuncs[funcId]() # ████████ (step-6)
        #setTimeout notifyDependants, 1

  @set-ifdiff = (newValue) ~>
    if newValue != innerValue
      @set(newValue)
  @

taken = {}
uniqify = (name) ->
  index = 0
  while taken[candidate = "#{name}-#{index}"]
    index += 1
  taken[candidate] = true
  candidate




# IDEA: similar to the backend
#
# Wrap values in boxes.
# Every time a computation requires data from a box, a box will remember that it is invoked.
# When I start or finish a computation, I tell the framework, and it will add the collected boxes
# as dependencies for that computation.
# When a dependency changes, the framework re-executes all computations that depend on it.
#


if false # draft

# Computation:

  boxA = box(1)
  boxB = box(2)
  boxC = box!.subscribe (c) -> console.log "c:", c

  compute ->
    boxC.set boxA.get! + boxB.get!


