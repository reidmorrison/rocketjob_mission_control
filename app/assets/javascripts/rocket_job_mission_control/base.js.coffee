$(document).load ->
  registerJobPriority()

$(document).on 'ready page:change', ->
  registerJobPriority()

registerJobPriority = ->
  $('#increase_priority').on 'click', ->
    $('#job_priority').val(parseInt($('#job_priority').val(), 10) + 1)

  $('#decrease_priority').on 'click', ->
    $('#job_priority').val(parseInt($('#job_priority').val(), 10) - 1)
