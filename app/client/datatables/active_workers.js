$(document).on("turbolinks:load", function () {
  var $el = $("#active_workers_datatable")

  if ($el.length) {
    $el.DataTable({
      pagingType: 'full_numbers',
      pageLength: 10,
      responsive: true,
      ajax:       $el.data('source'),
      processing: true,
      serverSide: true,
      columns:    [{data: '0'}, {data: '1'}, {data: '2'}, {data: '3'}],
      ordering:   false,
      searching:  false,
      order:      []
    })
  }
});
