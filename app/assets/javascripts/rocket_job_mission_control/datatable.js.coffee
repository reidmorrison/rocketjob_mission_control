class @RjmcDatatable
  constructor: (table, columns, opts={}) ->
    @table = $(table)
    @columns = columns
    @ordering = opts.ordering ? true
    @searching = opts.searching ? true
    @order = opts.order ? []
    @reload = $("[data-behavior='reload']")
    @initializeTable()
    @setEvents()

  initializeTable: ->
    @data = @table.DataTable
      pagingType: 'full_numbers'
      responsive: true
      ajax: @table.data('source')
      processing: true
      serverSide: true
      columns: @columns
      ordering: @ordering
      searching: @searching
      order: @order

  setEvents: ->
    @reload.on 'click', @reloadTable

  reloadTable: =>
    icon = @reload.find('i')
    icon.addClass('fa-spin')
    @data.ajax.reload ->
      icon.removeClass('fa-spin')
