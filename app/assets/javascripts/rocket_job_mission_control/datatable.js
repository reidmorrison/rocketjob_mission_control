'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var RjmcDatatable = function () {
  function RjmcDatatable(table, columns, opts) {
    _classCallCheck(this, RjmcDatatable);

    this.reloadTable = this.reloadTable.bind(this);
    if (opts == null) {
      opts = {};
    }
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

  _createClass(RjmcDatatable, [{
    key: 'initializeTable',
    value: function initializeTable() {
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
  }, {
    key: 'setEvents',
    value: function setEvents() {
      return this.reload.on('click', this.reloadTable);
    }
  }, {
    key: 'reloadTable',
    value: function reloadTable() {
      var icon = this.reload.find('i');
      icon.addClass('fa-spin');
      return this.data.ajax.reload(function () {
        return icon.removeClass('fa-spin');
      });
    }
  }]);

  return RjmcDatatable;
}();
