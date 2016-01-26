$(document).on 'ready', ->
  $('.jobs-datatable').DataTable
    ajax: $('.jobs-datatable').data('source')
    pagingType: 'full_numbers'
    scrollCollapse: true
    responsive: true
    processing: true
    serverSide: true
