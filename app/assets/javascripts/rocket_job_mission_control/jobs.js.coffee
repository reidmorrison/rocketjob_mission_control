$(document).on 'ready', ->
  column_num = $('.jobs-datatable').data('column-num')
  table = $('.jobs-datatable').DataTable
    pagingType: 'full_numbers'
    responsive: true
    ajax: $('.jobs-datatable').data('source')
    processing: true
    serverSide: true
    columns: { data: "#{column}" } for column in [0...column_num]

  $('[data-behavior~=reload]').on 'click', ->
    icon = $(this).find('i')
    icon.addClass('fa-spin')
    table.ajax.reload ->
      icon.removeClass('fa-spin')
