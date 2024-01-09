'use strict';

$(document).on('turbo:load', function () {
  $('.filter .state-toggle').on('change', function () {
    var active_states = $('.filter :checked');
    var param_string  = "?";
    active_states.each(function (_, state) {
      return param_string += 'states[]=' + $(state).attr('id') + '&';
    });
    return window.location.href = window.location.href.replace(/[\?#].*|$/, param_string);
  });

  if ($('#properties').length) {
    return $('#properties').on('click', function () {
      var params          = $('#new_rocket_job_dirmon_entry').serialize();
      var new_dirmon_path = $('#properties').data('url') + ('?' + params);
      return window.location = new_dirmon_path;
    });
  }
});
