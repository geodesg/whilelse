{promise,c} = u = require 'lib/utils'
{map,each,filter,any,concat,join,elem-index,sort-by,maximum} = prelude
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'

module.exports = h = react =

  #-------------------------------------------------------------------------------
  # Tag and attribute names taken from the React documetation - 2016-03-14
  # https://facebook.github.io/react/docs/tags-and-attributes.html
  # © 2013–2016 Facebook Inc.
  # Documentation licensed under CC BY 4.0. (https://creativecommons.org/licenses/by/4.0/)

  supportedElements: <[
    a abbr address area article aside audio b base bdi bdo big blockquote body br
    button canvas caption cite code col colgroup data datalist dd del details dfn
    dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5
    h6 head header hgroup hr html i iframe img input ins kbd keygen label legend li
    link main map mark menu menuitem meta meter nav noscript object ol optgroup
    option output p param picture pre progress q rp rt ruby s samp script section
    select small source span strong style sub summary sup table tbody td textarea
    tfoot th thead time title tr track u ul var video wbr

    circle clipPath defs ellipse g image line linearGradient mask path pattern
    polygon polyline radialGradient rect stop svg text tspan
  ]>

  supportedAttributes: <[
    accept acceptCharset accessKey action allowFullScreen allowTransparency alt
    async autoComplete autoFocus autoPlay capture cellPadding cellSpacing challenge
    charSet checked classID className colSpan cols content contentEditable
    contextMenu controls coords crossOrigin data dateTime default defer dir
    disabled download draggable encType form formAction formEncType formMethod
    formNoValidate formTarget frameBorder headers height hidden high href hrefLang
    htmlFor httpEquiv icon id inputMode integrity is keyParams keyType kind label
    lang list loop low manifest marginHeight marginWidth max maxLength media
    mediaGroup method min minLength multiple muted name noValidate nonce open
    optimum pattern placeholder poster preload radioGroup readOnly rel required
    reversed role rowSpan rows sandbox scope scoped scrolling seamless selected
    shape size sizes span spellCheck src srcDoc srcLang srcSet start step style
    summary tabIndex target title type useMap value width wmode wrap

    about datatype inlist prefix property resource typeof vocab

    clipPath cx cy d dx dy fill fillOpacity fontFamily
    fontSize fx fy gradientTransform gradientUnits markerEnd
    markerMid markerStart offset opacity patternContentUnits
    patternUnits points preserveAspectRatio r rx ry spreadMethod
    stopColor stopOpacity stroke  strokeDasharray strokeLinecap
    strokeOpacity strokeWidth textAnchor transform version
    viewBox x1 x2 x xlinkActuate xlinkArcrole xlinkHref xlinkRole
    xlinkShow xlinkTitle xlinkType xmlBase xmlLang xmlSpace y1 y2 y
  ]>

  #-------------------------------------------------------------------------------

  populateSearchIndex: (add-to-search-index) ->

    for htmlTagName in react.supportedElements
      add-to-search-index ->
        keywords: [htmlTagName, "<#{htmlTagName}>"]
        kind: 'react tag'
        name: htmlTagName
        type: n.react-html-elem
        handler-node: n.react-html-elem

