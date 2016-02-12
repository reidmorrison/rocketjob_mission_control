class @RjmcDatatable
  constructor: (table, columns, opts={}) ->
    @table = $(table)
    @columns = columns
    @ordering = opts.ordering ? true
    @searching = opts.searching ? true
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

  setEvents: ->
    @reload.on 'click', @reloadTable

  reloadTable: =>
    icon = @reload.find('i')
    icon.addClass('fa-spin')
    @data.ajax.reload ->
      icon.removeClass('fa-spin')
