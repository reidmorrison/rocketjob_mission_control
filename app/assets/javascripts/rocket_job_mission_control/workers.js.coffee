$(document).on 'ready', ->
  table = $('.workers-datatable').DataTable
    pagingType: 'full_numbers'
    responsive: true
    ajax: $('.workers-datatable').data('source')
    processing: true
    serverSide: true
    columns: [
      { data: '0' }
      { data: '1' }
      { data: '2' }
      { data: '3' }
      { data: '4' }
    ]

  $('[data-behavior~=reload]').on 'click', ->
    icon = $(this).find('i')
    icon.addClass('fa-spin')
    table.ajax.reload ->
      icon.removeClass('fa-spin')
