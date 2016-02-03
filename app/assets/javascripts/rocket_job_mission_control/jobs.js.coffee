$(document).on 'ready', ->
  $('.jobs-datatable').DataTable
    pagingType: 'full_numbers'
    responsive: true
    ajax: $('.jobs-datatable').data('source')
    processing: true
    serverSide: true
