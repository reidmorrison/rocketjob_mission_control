$(document).on 'ready', ->
  $('.filter .state-toggle').on 'change', ->
    active_states = $('.filter :checked')
    param_string = "?"
    active_states.each (_, state) ->
      param_string += "states[]=" + $(state).attr('id') + "&"
    window.location.href = window.location.href.replace( /[\?#].*|$/, param_string );

  if $('#properties').length
    $('#properties').on 'click', ->
      job_class_name  = $('#rocket_job_dirmon_entry_job_class_name').val()
      perform_method  = $('#rocket_job_dirmon_entry_perform_method').val()
      new_dirmon_path = $('#properties').data('url') + "?job_class_name=#{job_class_name}&perform_method=#{perform_method}"
      window.location = new_dirmon_path

