$(document).on 'ready', ->
  $('.workers-datatable').DataTable
    pagingType: 'full_numbers'
    responsive: true
    # ajax: $('.jobs-datatable').data('source')
    # pagingType: 'full_numbers'
    # responsive: true
    # processing: true
    # serverSide: true
