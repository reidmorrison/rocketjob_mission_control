$(document).on "page:change", ->
  $('#menu-toggle').click (e) ->
    e.preventDefault()
    $('#wrapper').toggleClass 'toggled'

  $('#menu-close').click (e) ->
    e.preventDefault()
    $('#wrapper').toggleClass 'toggled'

  $('.touchspin').TouchSpin
    min: 0,
    max: 100

  $('.spinner button.up').on 'click', ->
    $(this).closest('.spinner').find('input').val parseInt($(this).closest('.spinner').find('input').val(), 10) + 1

  $('.spinner button.down').on 'click', ->
    $(this).closest('.spinner').find('input').val parseInt($(this).closest('.spinner').find('input').val(), 10) - 1

$(document).on 'ready page:change', ->
  Prism.highlightAll()
