var RjmcDatatable = class RjmcDatatable {
  constructor(table, columns, opts) {
    this.reloadTable = this.reloadTable.bind(this);
    if (opts == null) { opts = {}; }
    this.table = $(table);
    this.columns = columns;
    this.ordering = opts.ordering != null ? opts.ordering : true;
    this.searching = opts.searching != null ? opts.searching : true;
    this.pageLength = opts.pageLength != null ? opts.pageLength : 100;
    this.order = opts.order != null ? opts.order : [];
    this.reload = $("[data-behavior='reload']");
    this.initializeTable();
    this.setEvents();
  }

  initializeTable() {
    return this.data = this.table.DataTable({
      pagingType: 'full_numbers',
      pageLength: this.pageLength,
      responsive: true,
      ajax: this.table.data('source'),
      processing: true,
      serverSide: true,
      columns: this.columns,
      ordering: this.ordering,
      searching: this.searching,
      order: this.order
    });
  }

  setEvents() {
    return this.reload.on('click', this.reloadTable);
  }

  reloadTable() {
    let icon = this.reload.find('i');
    icon.addClass('fa-spin');
    return this.data.ajax.reload(() => icon.removeClass('fa-spin'));
  }
};
