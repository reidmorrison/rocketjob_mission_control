// Toggle the job exception backtrace between its abbreviated view (application
// frames only) and the full view (including gem and Ruby frames).
//
// The abbreviated view is rendered server-side by hiding rows marked
// `.backtrace-noise` (see exception.html.erb / JobsHelper#backtrace_noise?).
// Clicking the button adds `show-full` to the table, which reveals those rows
// via CSS, and swaps the button label.
(function($) {
  $(function() {
    $(document).on('click', '[data-backtrace-toggle]', function() {
      var button      = $(this);
      var table       = button.closest('.job-status').find('table.backtrace');
      var showingFull = table.toggleClass('show-full').hasClass('show-full');
      button.text(showingFull ? button.attr('data-label-abbreviated') : button.attr('data-label-full'));
    });
  });
})(jQuery);
