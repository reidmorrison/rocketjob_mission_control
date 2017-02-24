$(document).ready(() => toggleCanvas());

var toggleCanvas = () =>
  $('[data-toggle=offcanvas]').click(function () {
    $(this).toggleClass('visible-xs text-center');
    $(this).find('i').toggleClass('fa-chevron-right fa-chevron-left');
    $('.row-offcanvas').toggleClass('active');
    $('#lg-menu').toggleClass('hidden-xs').toggleClass('visible-xs');
    $('#xs-menu').toggleClass('visible-xs').toggleClass('hidden-xs');
    return $('#btnShow').toggle();
  })
;
