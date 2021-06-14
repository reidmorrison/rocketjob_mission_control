$(document).on("turbolinks:load", function () {
  var $el = $("#jobs_datatable")

  if ($el.length) {
    $el.DataTable({
      pagingType: 'full_numbers',
      pageLength: 10,
      responsive: true,
      ajax:       $el.data('source'),
      processing: true,
      serverSide: true,
      columns:    $el.data('columns'),
      ordering:   true,
      searching:  true,
      order:      []
    })
  }
});
