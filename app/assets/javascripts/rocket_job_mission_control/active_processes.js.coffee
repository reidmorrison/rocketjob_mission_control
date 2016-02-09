$(document).on 'ready', ->
  column_num = $('.active-processes-datatable').data('column-num')
  table = $('.active-processes-datatable').DataTable
    pagingType: 'full_numbers'
    responsive: true
    ajax: $('.active-processes-datatable').data('source')
    ordering: false
    searching: false
    processing: true
    serverSide: true
    columns: { data: "#{column}" } for column in [0...column_num]

  $('[data-behavior~=reload]').on 'click', ->
    icon = $(this).find('i')
    icon.addClass('fa-spin')
    table.ajax.reload ->
      icon.removeClass('fa-spin')
