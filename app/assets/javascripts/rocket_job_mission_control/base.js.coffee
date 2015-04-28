readyMenuToggle = ->
  $('#menu-toggle').click (e) ->
    e.preventDefault()
    $('#wrapper').toggleClass 'toggled'

  $('#menu-close').click (e) ->
    e.preventDefault()
    $('#wrapper').toggleClass 'toggled'


$(document).load ->
  readyMenuToggle()

$(document).on 'ready page:change', ->
  readyMenuToggle()
