$(document).load ->
  readyMenuToggle()
  registerJobPriority()

$(document).on 'ready page:change', ->
  readyMenuToggle()
  registerJobPriority()

readyMenuToggle = ->
  $('#menu-toggle').click (e) ->
    e.preventDefault()
    $('#wrapper').toggleClass 'toggled'

  $('#menu-close').click (e) ->
    e.preventDefault()
    $('#wrapper').toggleClass 'toggled'


registerJobPriority = ->
  $('#increase_priority').on 'click', ->
    $('#job_priority').val(parseInt($('#job_priority').val(), 10) + 1)

  $('#decrease_priority').on 'click', ->
    console.log 'decreasing'
    $('#job_priority').val(parseInt($('#job_priority').val(), 10) - 1)
