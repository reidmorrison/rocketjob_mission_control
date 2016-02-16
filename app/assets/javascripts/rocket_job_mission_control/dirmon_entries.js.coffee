$(document).on 'ready', ->
  $('.filter .state-toggle').on 'change', ->
    active_states = $('.filter :checked')
    param_string = "?"
    active_states.each (_, state) ->
      param_string += "states[]=" + $(state).attr('id') + "&"
    window.location.href = window.location.href.replace( /[\?#].*|$/, param_string );

  if $('#properties').length
    $('#properties').on 'click', ->
      params = $('#new_rocket_job_dirmon_entry').serialize()
      new_dirmon_path = $('#properties').data('url') + "?#{params}"
      window.location = new_dirmon_path
