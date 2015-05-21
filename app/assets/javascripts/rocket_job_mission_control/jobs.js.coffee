$(document).on 'ready', ->
  $('.filter .state-toggle').on 'change', ->
    active_states = $('.filter :checked')
    param_string = "?"
    active_states.each (_, state) ->
      param_string += "states[]=" + $(state).attr('id') + "&"
    window.location.href = window.location.href.replace( /[\?#].*|$/, param_string );

  $('.panel a').on 'click', ->
    $('i', this).toggleClass('fa-plus-square-o')
    $('i', this).toggleClass('fa-minus-square-o')
