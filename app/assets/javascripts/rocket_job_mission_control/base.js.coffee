$(document).load ->
  registerJobPriority()

$(document).on 'ready page:change', ->
  registerJobPriority()

registerJobPriority = ->
  $('#increase_priority').on 'click', ->
    $('#job_priority').val(parseInt($('#job_priority').val(), 10) + 1)

  $('#decrease_priority').on 'click', ->
    $('#job_priority').val(parseInt($('#job_priority').val(), 10) - 1)

$(document).ready ->
  $('[data-toggle=offcanvas]').click ->
    $(this).toggleClass 'visible-xs text-center'
    $(this).find('i').toggleClass 'fa-chevron-right fa-chevron-left'
    $('.row-offcanvas').toggleClass 'active'
    $('#lg-menu').toggleClass('hidden-xs').toggleClass 'visible-xs'
    $('#xs-menu').toggleClass('visible-xs').toggleClass 'hidden-xs'
    $('#btnShow').toggle()
