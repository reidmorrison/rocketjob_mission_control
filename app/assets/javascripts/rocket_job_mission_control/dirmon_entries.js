$(document).on('ready', function() {
  $('.filter .state-toggle').on('change', function() {
    let active_states = $('.filter :checked');
    let param_string = "?";
    active_states.each((_, state) => param_string += `states[]=${$(state).attr('id')}&`);
    return window.location.href = window.location.href.replace( /[\?#].*|$/, param_string );
  });

  if ($('#properties').length) {
    return $('#properties').on('click', function() {
      let params = $('#new_rocket_job_dirmon_entry').serialize();
      let new_dirmon_path = $('#properties').data('url') + `?${params}`;
      return window.location = new_dirmon_path;
    });
  }
});
