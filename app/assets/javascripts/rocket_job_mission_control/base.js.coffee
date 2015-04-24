$(document).on "ready page:change", ->
  $('#menu-toggle').click (e) ->
    e.preventDefault()
    $('#wrapper').toggleClass 'toggled'

  $('#menu-close').click (e) ->
    e.preventDefault()
    $('#wrapper').toggleClass 'toggled'

$(document).on 'ready page:change', ->
  Prism.highlightAll()
