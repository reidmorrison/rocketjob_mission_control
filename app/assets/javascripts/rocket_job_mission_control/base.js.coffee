$(document).ready ->
  toggleCanvas()

toggleCanvas = ->
  $('[data-toggle=offcanvas]').click ->
    $(this).toggleClass 'visible-xs text-center'
    $(this).find('i').toggleClass 'fa-chevron-right fa-chevron-left'
    $('.row-offcanvas').toggleClass 'active'
    $('#lg-menu').toggleClass('hidden-xs').toggleClass 'visible-xs'
    $('#xs-menu').toggleClass('visible-xs').toggleClass 'hidden-xs'
    $('#btnShow').toggle()
