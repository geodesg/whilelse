# Recentor
#
# Response for storing the last created/modified/accessed
# node ids.
#

{ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude

module.exports = recentor =

  add: (category, id) ->
    t = (new Date!).getTime!
    console.log t, category, id
    record = { t: t, id: id }
    lsKey = "recentor.#{category}"
    currentValue = window.localStorage.getItem(lsKey)
    if currentValue
      try
        currentList = JSON.parse currentValue
      catch
        currentList = []
    else
      currentList = []

    newList = [record]

    for item in currentList
      if newList.length < 10 && item.id != id
        newList.push item

    window.localStorage.setItem(lsKey, JSON.stringify(newList))
