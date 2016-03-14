{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'

module.exports = constants =
  build: (n, repo) ->
    n.ntyp          = repo.node-ifx('1')
    n.atyp          = repo.node-ifx('2')
    n.rtyp          = repo.node-ifx('3')
    n.type          = repo.node-ifx('4')
    n.name          = repo.node-ifx('5')
    n.desc          = repo.node-ifx('6')
    n.ctnr          = repo.node-ifx('7')
    n.ctns          = repo.node-ifx('8')
    n.root          = repo.node-ifx('9')
    n.refs          = repo.node-ifx('10')
    n.core          = repo.node-ifx('112')
    n.node          = repo.node-ifx('522')
    n.value-a       = repo.node-ifx('254')
    n.tmp-r         = repo.node-ifx('2505')
    n.blank         = repo.node-ifx('12')
    n.expand-children-a = repo.node-ifx('acdQI60vTSkt')
    n.key-a         = repo.node-ifx('252')
    n.keyword       = repo.node-ifx('7961')
    n.keyword-r     = repo.node-ifx('7963')

    # schema
    n.s-attr        = repo.node-ifx('207')
    n.s-ref         = repo.node-ifx('209')
    n.s-req         = repo.node-ifx('215')
    n.s-rep         = repo.node-ifx('213')
    n.s-dep         = repo.node-ifx('393')
    n.s-at          = repo.node-ifx('262')
    n.s-avt         = repo.node-ifx('269')
    n.s-rt          = repo.node-ifx('282')
    n.s-gnt         = repo.node-ifx('265')
    n.s-subtype-of  = repo.node-ifx('386')
    n.s-subtype     = repo.node-ifx('ac1YxsKHnFEL')
    n.s-plname      = repo.node-ifx('500')
    n.s-invname     = repo.node-ifx('427')
    n.s-invplname   = repo.node-ifx('429')
    n.s-str         = repo.node-ifx('223')
    n.s-int         = repo.node-ifx('225')
    n.s-bool        = repo.node-ifx('227')
    n.s-flt         = repo.node-ifx('229')
    n.s-twoway      = repo.node-ifx('443')

    #prog
    n.prog          = repo.node-ifx('116')
    n.mtypR         = repo.node-ifx('602')
    n.mtyp          = repo.node-ifx('159')

    #native-coding
    n.native-coding = repo.node-ifx('145')

    #templating
    n.templating    = repo.node-ifx('189')

    add = (node, prefix = '') ->
      name = node.name!
      name = u.camelize("#{prefix}#{name}")
      switch node.type!
      case n.ntyp      then # nothing
      case n.ctnr      then # nothing
      case n.atyp      then name += "A"
      case n.rtyp      then name += "R"
      case n.mtyp      then name += "M"
      case n.operator  then name += "O"  # (***)
      case n.data-type then name += "T"  # (***)
      case n.function  then name += "F"  # (***)
      else name += u.dromedarize(node.type!.name!)
      # (***) WARNING: these depend on a specific order

      unless n[name]
        #console.log "- #{name}"
        n[name] = node
      else
        console.error "- #{name} already taken"

    if n.prog
      n.prog.rns(n.ctns) |> each (node) -> add(node)
    if n.native-coding
      n.native-coding.rns(n.ctns) |> each (node) -> add(node)
    if n.templating
      n.templating.rns(n.ctns) |> each (node) -> add(node, 't-')

    #web
    n.web = repo.node-ifx('964161')
    if n.web
      n.web.rns(n.ctns) |> each (node) -> add(node, 'web-')

    n.db = repo.node-ifx('acoR5HYwqCue')
    if n.db
      n.db.rns(n.ctns) |> each (node) -> add(node, 'db-')

    n.tasks = repo.node-ifx('acSrFztDxG5D')
    if n.tasks
      n.tasks.rns(n.ctns) |> each (node) -> add(node, 'ta-')

    n.testing = repo.node-ifx('acCGU2Dy84is')
    if n.testing
      n.testing.rns(n.ctns) |> each (node) -> add(node, 'te-')

    n.react = repo.node-ifx('acchLGUrvbag')
    if n.react
      n.react.rns(n.ctns) |> each (node) -> add(node, 'react-')


