// datatables.net relies on the jquery global variable to work.
// import-loader helps us to add the necessary require('jquery') so the
// jquery variable is available when any datatables.net packages are loaded.
// refer to https://webpack.js.org/loaders/imports-loader/

module.exports = {
  test: /datatables\.net.*/,
  loader: "imports-loader",
  options: {
    // Disables AMD plugin as DataTables.net
    // checks for AMD before CommonJS.
    additionalCode: "var define = false;",
  },
};
